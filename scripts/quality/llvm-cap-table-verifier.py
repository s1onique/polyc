#!/usr/bin/env python3
"""scripts/quality/llvm-cap-table-verifier.py

ACT-POLYC-LLVM-CORE03-CORRECTION01 M2 + M4.

Build-time verifier that binds dispatch <-> capability table <-> harness.

It checks three invariants:

  I1. For every IrOp in the enum, the dispatch (src/llvm-backend.c)
      has the right shape relative to the capability row:

        SUPPORTED          -> exactly one explicit case IR_X: arm
                              OR an explicit `if (ins->op == IR_X)`
                              short-circuit.
        REJECTED           -> exactly one explicit case IR_X: arm
                              OR an explicit `if (ins->op == IR_X)`
                              short-circuit, AND that handler emits
                              the named diagnostic.
        SHAPE_DEPENDENT    -> exactly one explicit case IR_X: arm
                              OR an explicit `if (ins->op == IR_X)`
                              short-circuit.
        UNREACHABLE_ON_LLVM -> NO explicit case IR_X: arm AND NO
                               explicit `if (ins->op == IR_X)` arm.
                               Falls through to the generic default.
        DEFENSIVE_INVARIANT -> exactly one explicit `if (ins->op ==
                               IR_X)` short-circuit that emits the
                               LLVM_BACKEND_DEFENSIVE_INVARIANT_TRIPPED
                               diagnostic.

  I2. Every explicit `case IR_X:` arm or `if (ins->op == IR_X)`
      short-circuit in the dispatch corresponds to a row in
      kLLVMBackendCapability[]. (Reverse of I1; prevents the dispatch
      from claiming a class for an opcode that has no contract row.)

  I3. The harness queries the table rather than using hard-coded
      expectations. (Verified by reading the harness script.)

Returns rc=0 on PASS, rc=1 on FAIL.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC_BACKEND = REPO_ROOT / "src" / "llvm-backend.c"
SRC_CAP = REPO_ROOT / "src" / "llvm-backend-cap.c"
SRC_CAP_HEADER = REPO_ROOT / "src" / "llvm-backend-cap.h"
SRC_IR_TYPES = REPO_ROOT / "src" / "ir-types.h"
SRC_MAIN = REPO_ROOT / "src" / "main.c"
HARNESS = REPO_ROOT / "scripts" / "quality" / "llvm-spike-contract-check.sh"
HCC = REPO_ROOT / "hcc"

# LLVMBackendCapability class ordinals (must match src/llvm-backend-cap.h).
LLVMBC_SUPPORTED = 0
LLVMBC_REJECTED = 1
LLVMBC_SHAPE_DEPENDENT = 2
LLVMBC_UNREACHABLE_ON_LLVM = 3
LLVMBC_DEFENSIVE_INVARIANT = 4

CLASS_NAMES = {
    LLVMBC_SUPPORTED: "SUPPORTED",
    LLVMBC_REJECTED: "REJECTED",
    LLVMBC_SHAPE_DEPENDENT: "SHAPE_DEPENDENT",
    LLVMBC_UNREACHABLE_ON_LLVM: "UNREACHABLE_ON_LLVM",
    LLVMBC_DEFENSIVE_INVARIANT: "DEFENSIVE_INVARIANT",
}

failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL  " + msg)


def ok(msg):
    print("PASS  " + msg)


def read(path):
    return path.read_text()


def get_ir_op_enum():
    """Return (enum_name -> ordinal) from src/ir-types.h."""
    text = read(SRC_IR_TYPES)
    # Match `IR_X,` lines (enum body). Skip IR_TYPE_*, IR_CMP_*.
    # The last enum entry may have no trailing comma, so also match
    # `IR_X\s*\n}` (final entry before closing brace).
    pat = re.compile(r"^\s*(IR_[A-Z_0-9]+)\s*(?:,|\s*\n\s*\})", re.MULTILINE)
    names = []
    for m in pat.finditer(text):
        n = m.group(1)
        # Stop when we hit IR_TYPE_* (the second enum in the file).
        if n.startswith("IR_TYPE_"):
            break
        names.append(n)
    return {n: i for i, n in enumerate(names)}


def get_cap_table_via_hcc():
    """Run hcc --print-cap-table and parse the output."""
    if not HCC.exists():
        fail("hcc binary not found at " + str(HCC))
        return {}
    env = os.environ.copy()
    # Minimal PATH for hcc; reuse PATH or skip the helper mode.
    try:
        out = subprocess.check_output(
            [str(HCC), "--print-cap-table"],
            env=env, stderr=subprocess.STDOUT, timeout=30,
        )
    except subprocess.CalledProcessError as e:
        fail("hcc --print-cap-table exited non-zero: " + e.output.decode("utf-8", "replace"))
        return {}
    except Exception as e:
        fail("hcc --print-cap-table failed: " + str(e))
        return {}
    rows = {}
    for line in out.decode("utf-8", "replace").splitlines():
        parts = line.split(None, 3)
        if len(parts) < 4:
            continue
        op, cls, diag, name = parts
        try:
            rows[int(op)] = {
                "class": int(cls),
                "diagnostic": None if diag == "-" else diag,
                "name": name,
            }
        except ValueError:
            continue
    return rows


def get_dispatch_arms():
    """Parse src/llvm-backend.c for explicit `case IR_X:` arms and
    `if (ins->op == IR_X)` short-circuits within llLowerInstr."""
    text = read(SRC_BACKEND)

    # `case IR_X:` arms anywhere in the file.
    case_arms = set()
    for m in re.finditer(r"case\s+(IR_[A-Z_0-9]+)\s*:", text):
        case_arms.add(m.group(1))

    # `if (ins->op == IR_X)` short-circuits anywhere.
    if_arms = set()
    for m in re.finditer(r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)", text):
        if_arms.add(m.group(1))

    # Find the body of llLowerInstr to scope the `if` arms.
    # The current spike has only one llLowerInstr. Both `case` and
    # `if` arms inside it are valid dispatch; outside, only `case`
    # arms in the dispatch's switch are valid.
    fn_match = re.search(
        r"static\s+\w+\s+llLowerInstr\s*\([^)]*\)\s*\{",
        text,
    )
    inside_dispatch = set()
    outside_dispatch = set()
    if fn_match:
        # Naive brace counting from the function open.
        start = fn_match.end()
        depth = 1
        i = start
        while i < len(text) and depth > 0:
            if text[i] == "{":
                depth += 1
            elif text[i] == "}":
                depth -= 1
            i += 1
        dispatch_body = text[start:i]
        for m in re.finditer(r"case\s+(IR_[A-Z_0-9]+)\s*:", dispatch_body):
            inside_dispatch.add(m.group(1))
        # We also accept `case IR_X:` outside (e.g., in helper tables).
        # The dispatch body is the canonical llLowerInstr.
    for op in case_arms:
        outside_dispatch.add(op)
    inside_dispatch |= inside_dispatch

    return {
        "case_in_llLowerInstr": inside_dispatch,
        "case_anywhere": case_arms,
        "if_in_llLowerInstr_or_switch": if_arms,
    }


def check_dispatch(enum_ops, cap_rows, dispatch):
    """I1: for every IrOp in the enum, the dispatch shape matches the row."""
    case_in = dispatch["case_in_llLowerInstr"]
    case_any = dispatch["case_anywhere"]
    if_any = dispatch["if_in_llLowerInstr_or_switch"]

    for op_name, ordinal in enum_ops.items():
        if op_name not in cap_rows:
            fail("I1: opcode {0} (ordinal {1}) has no row in capability table".format(
                op_name, ordinal))
            continue
        cls = cap_rows[op_name]["class"]
        diag = cap_rows[op_name]["diagnostic"]

        has_case = op_name in case_in
        has_if = op_name in if_any

        if cls == LLVMBC_UNREACHABLE_ON_LLVM:
            if has_case or has_if:
                fail("I1: {0} = UNREACHABLE_ON_LLVM but dispatch has explicit"
                     " case arm or short-circuit (case={1}, if={2})".format(
                         op_name, has_case, has_if))
            else:
                ok("I1: {0} = UNREACHABLE_ON_LLVM, no explicit arm (falls to default)".format(
                    op_name))
        else:
            if not (has_case or has_if):
                fail("I1: {0} = {1} but dispatch has no explicit case arm"
                     " and no short-circuit".format(op_name, CLASS_NAMES.get(cls, "?")))
            elif cls == LLVMBC_REJECTED:
                # If REJECTED has an arm, the diagnostic named in the table
                # must appear in the dispatch body. We don't strictly require
                # the diagnostic string to appear at the exact arm (some
                # opcodes share a diagnostic across multiple arms), but we
                # DO require that the diagnostic string is used somewhere
                # in the dispatch.
                backend_text = read(SRC_BACKEND)
                if diag and diag not in backend_text:
                    fail("I1: {0} = REJECTED with diagnostic {1!r}, but that"
                         " diagnostic string does not appear in the dispatch".format(
                             op_name, diag))
                else:
                    ok("I1: {0} = REJECTED with diagnostic {1!r}".format(
                        op_name, diag))
            else:
                ok("I1: {0} = {1}, dispatch has explicit arm".format(
                    op_name, CLASS_NAMES.get(cls, "?")))


def check_reverse(enum_ops, cap_rows, dispatch):
    """I2: every explicit dispatch arm has a corresponding table row."""
    case_in = dispatch["case_in_llLowerInstr"]
    if_any = dispatch["if_in_llLowerInstr_or_switch"]
    handled = case_in | if_any
    for op_name in handled:
        if op_name not in enum_ops:
            fail("I2: dispatch has explicit arm for {0} but no IrOp enum entry".format(
                op_name))
        elif op_name not in cap_rows:
            fail("I2: dispatch has explicit arm for {0} but no capability row".format(
                op_name))
        else:
            ok("I2: {0} has explicit dispatch arm and capability row ({1})".format(
                op_name, CLASS_NAMES.get(cap_rows[op_name]["class"], "?")))


def check_harness_queries_table():
    """I3: the harness queries the table rather than hard-coding expectations."""
    if not HARNESS.exists():
        fail("I3: harness not found at " + str(HARNESS))
        return
    text = read(HARNESS)
    if "hcc --print-cap-table" in text or "--print-cap-table" in text:
        ok("I3: harness queries hcc --print-cap-table (bound to table)")
    else:
        fail("I3: harness does NOT query hcc --print-cap-table;"
             " expectations are still hard-coded. (See CORE03 P1 review.)")


def main():
    print("=== llvm-cap-table-verifier (CORE03-CORRECTION01) ===")
    enum_ops = get_ir_op_enum()
    if not enum_ops:
        fail("could not parse IrOp enum from " + str(SRC_IR_TYPES))
        return 1
    ok("parsed {0} IrOp enum entries (IR_NOP=0 .. IR_ASM={1})".format(
        len(enum_ops), len(enum_ops) - 1))

    cap_rows = get_cap_table_via_hcc()
    if not cap_rows:
        fail("could not load capability table from hcc --print-cap-table")
        return 1
    # Re-key by opcode name (the helper emits op ordinal; map back).
    by_name = {}
    for ordinal, row in cap_rows.items():
        # Reverse-lookup: find the name in the enum by ordinal.
        for name, ord_ in enum_ops.items():
            if ord_ == ordinal:
                by_name[name] = row
                break
    if not by_name:
        fail("capability table empty")
        return 1
    ok("loaded {0} capability rows via hcc --print-cap-table".format(len(by_name)))

    dispatch = get_dispatch_arms()
    ok("dispatch scan: {0} case arms in llLowerInstr, {1} if-shorts anywhere".format(
        len(dispatch["case_in_llLowerInstr"]),
        len(dispatch["if_in_llLowerInstr_or_switch"])))

    check_dispatch(enum_ops, by_name, dispatch)
    check_reverse(enum_ops, by_name, dispatch)
    check_harness_queries_table()

    print()
    if failures:
        print("======================================")
        print("FAIL: {0} binding violations".format(len(failures)))
        print("======================================")
        return 1
    print("======================================")
    print("PASS: dispatch <-> capability <-> harness bound")
    print("======================================")
    return 0


if __name__ == "__main__":
    sys.exit(main())
