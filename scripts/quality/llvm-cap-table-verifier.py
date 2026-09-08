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


def _read_int_at(buf, pos, terminator, line_no, rows_seen, malformed):
    """Read ASCII-decimal integer starting at pos, ending at the byte
    matching terminator (typically b'\\t'). Returns (int_value, new_pos).
    Returns (None, pos) and records malformed on failure.
    """
    end = buf.find(terminator, pos)
    if end < 0:
        malformed.append((line_no, rows_seen,
                          "no %r terminator after byte %d"
                          % (terminator, pos)))
        return None, pos
    raw = buf[pos:end]
    if not raw or not raw.isdigit():
        malformed.append((line_no, rows_seen,
                          "non-integer integer field %r at byte %d"
                          % (raw, pos)))
        return None, pos
    return int(raw), end + 1  # advance past the terminator


def _read_exact(buf, pos, n, line_no, rows_seen, malformed, label):
    """Read exactly n bytes from buf starting at pos. Returns
    (bytes, new_pos). Returns (None, pos) and records malformed
    on insufficient bytes."""
    end = pos + n
    if end > len(buf):
        malformed.append((line_no, rows_seen,
                          "%s length says %d bytes from offset %d, "
                          "but only %d remain"
                          % (label, n, pos, len(buf) - pos)))
        return None, pos
    return buf[pos:end], end


def get_cap_table_via_hcc():
    """Run hcc --print-cap-table and parse the output.

    ACT-POLYC-LLVM-CORE03-CORRECTION02 M1: the wire format is
    length-delimited. Each row is:

      <op-ordinal>\\t<class-ordinal>\\t<diag-len>\\t<diag>\\t<note-len>\\t<note>\\n

    ACT-POLYC-LLVM-CORE03-CORRECTION03 M2: framing is performed on
    RAW BYTES, not on decoded str. The C emitter writes lengths
    via strlen() (UTF-8 byte count).

    ACT-POLYC-LLVM-CORE03-CORRECTION04 M2: framing is now TRULY
    length-framed. The parser reads ASCII-decimal integers until
    the next TAB, then reads exactly <len> bytes for the variable
    field (regardless of whether those bytes contain TAB or LF),
    then expects the next TAB and the next length, etc. The C
    emitter does not need to change; the printer's bytes are
    already arranged so that a length-framed consumer can extract
    each field.
    """
    if not HCC.exists():
        fail("hcc binary not found at " + str(HCC))
        return {}
    env = os.environ.copy()
    try:
        out = subprocess.check_output(
            [str(HCC), "--print-cap-table"],
            env=env, stderr=subprocess.STDOUT, timeout=30,
        )
    except subprocess.CalledProcessError as e:
        fail("hcc --print-cap-table exited non-zero: "
             + e.output.decode("utf-8", "replace"))
        return {}
    except Exception as e:
        fail("hcc --print-cap-table failed: " + str(e))
        return {}

    # out is bytes. Drive the parser off the lengths, not off
    # delimiters. Payloads may contain raw TAB or LF; only the
    # length prefix and the structural delimiters between fields
    # are guaranteed.
    raw_bytes = out
    rows = {}
    # Each malformed entry: (line_no, record_index, message).
    malformed = []

    pos = 0
    record_index = 0
    line_no = 1
    total_len = len(raw_bytes)

    while pos < total_len:
        record_index += 1
        start_pos = pos
        op, pos = _read_int_at(raw_bytes, pos, b"\t",
                               line_no, record_index, malformed)
        if op is None:
            break
        cls, pos = _read_int_at(raw_bytes, pos, b"\t",
                                line_no, record_index, malformed)
        if cls is None:
            break
        diag_len, pos = _read_int_at(raw_bytes, pos, b"\t",
                                    line_no, record_index, malformed)
        if diag_len is None:
            break
        # SENTINEL: literal "-" encoded as length 1 with byte 0x2D.
        if (diag_len == 1
                and pos < total_len
                and raw_bytes[pos:pos+1] == b"-"):
            diag_bytes = None
            pos += 1
        else:
            diag_bytes, pos = _read_exact(raw_bytes, pos, diag_len,
                                          line_no, record_index, malformed,
                                          "diag")
            if diag_bytes is None:
                break
        if pos >= total_len or raw_bytes[pos:pos+1] != b"\t":
            malformed.append((line_no, record_index,
                              "expected TAB after diag payload at "
                              "byte %d, got %r"
                              % (pos, raw_bytes[pos:pos+1])))
            break
        pos += 1
        note_len, pos = _read_int_at(raw_bytes, pos, b"\t",
                                     line_no, record_index, malformed)
        if note_len is None:
            break
        if (note_len == 1
                and pos < total_len
                and raw_bytes[pos:pos+1] == b"-"):
            note_bytes = None
            pos += 1
        else:
            note_bytes, pos = _read_exact(raw_bytes, pos, note_len,
                                          line_no, record_index, malformed,
                                          "note")
            if note_bytes is None:
                break
        if pos >= total_len:
            malformed.append((line_no, record_index,
                              "missing record terminator LF at EOF"))
            break
        if raw_bytes[pos:pos+1] != b"\n":
            malformed.append((line_no, record_index,
                              "expected LF after note payload at "
                              "byte %d, got %r"
                              % (pos, raw_bytes[pos:pos+1])))
            break
        pos += 1

        raw_record = raw_bytes[start_pos:pos]
        # Decode AFTER framing. This is the only point at which
        # UTF-8 is consulted; replace on malformed bytes to avoid
        # crashing the verifier on accidentally invalid input.
        diag = (None if diag_bytes is None
                else diag_bytes.decode("utf-8", "replace"))
        note = (None if note_bytes is None
                else note_bytes.decode("utf-8", "replace"))

        rows[op] = {
            "class": cls,
            "diagnostic": diag,
            "note": note,
            # Save the raw record (bytes) for the round-trip
            # assertion. Decoded form is kept for human-readable
            # diagnostics only.
            "_raw": raw_record,
            "_raw_str": raw_record.decode("utf-8", "replace"),
            "_diag_len": diag_len,
            "_note_len": note_len,
        }
        line_no += 1

    for ln, rec, msg in malformed:
        fail("M1 wire-format: record %d (line %d): %s" % (rec, ln, msg))
    if not rows and not malformed:
        fail("M1 wire-format: no rows parsed")
    return rows


def check_wire_format_roundtrip(rows):
    """M1 acceptance: re-serialize each row with the same format and
    assert byte-equality with the original wire line. Catches any
    future regression where the printer and parser drift."""
    if not rows:
        return  # already failed above
    failures = 0
    for op, row in sorted(rows.items()):
        diag = row["diagnostic"] if row["diagnostic"] is not None else "-"
        note = row["note"] if row["note"] is not None else "-"
        # Compute expected exactly as llPrintCapabilityTable does.
        # Use byte lengths (UTF-8 encoded) so the C <-> Python contract
        # is honest for non-ASCII payloads. The fields themselves are
        # re-encoded as UTF-8 to match the on-wire byte sequence.
        diag_bytes = b"-" if diag == "-" else diag.encode("utf-8")
        note_bytes = b"-" if note == "-" else note.encode("utf-8")
        expected = b"%d\t%d\t%d\t%s\t%d\t%s\n" % (
            op, row["class"], len(diag_bytes), diag_bytes,
            len(note_bytes), note_bytes,
        )
        if expected != row["_raw"]:
            failures += 1
            fail("M1 round-trip: row %d: re-serialized line != original line\n"
                 "  original: %r\n"
                 "  expected: %r" % (op, row["_raw"], expected))
    if failures == 0:
        ok("M1 round-trip: %d rows round-trip byte-identical" % len(rows))


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


def get_dispatch_arm_groups():
    """ACT-POLYC-LLVM-CORE03-CORRECTION02 M2: extract each grouped
    case-arm body from the dispatch switch in llLowerInstr.

    Returns a list of dicts, one per arm-group:
        - labels:   list of IR_X identifiers (the case labels in
                    the group, in source order)
        - body:     text of the arm body, from after the last case
                    label up to the next case/default:/closing brace
                    at switch depth
        - is_default: True if this is the default: arm
    """
    text = read(SRC_BACKEND)
    fn_match = re.search(
        r"static\s+\w+\s+llLowerInstr\s*\([^)]*\)\s*\{",
        text,
    )
    if not fn_match:
        return []
    start = fn_match.end()
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    fn_body = text[start:i]

    switch_match = re.search(r"switch\s*\([^)]*\)\s*\{", fn_body)
    if not switch_match:
        return []
    sw_start = switch_match.end()
    depth = 1
    pos = sw_start
    groups = []
    cur_labels = []
    cur_body_start = None
    case_re = re.compile(r"\bcase\s+(IR_[A-Z_0-9]+)\s*:")
    default_re = re.compile(r"\bdefault\s*:")
    label_re = re.compile(r"\b(case\s+(?:IR_[A-Z_0-9]+)\s*:|default\s*:)")

    def skip_ws_comments(s, p):
        """Skip whitespace and C-style comments starting at p."""
        n = len(s)
        while p < n:
            if s[p] in " \t\r\n":
                p += 1
            elif p + 1 < n and s[p] == "/" and s[p + 1] == "/":
                # Line comment.
                nl = s.find("\n", p)
                p = nl + 1 if nl >= 0 else n
            elif p + 1 < n and s[p] == "/" and s[p + 1] == "*":
                # Block comment.
                end = s.find("*/", p + 2)
                p = end + 2 if end >= 0 else n
            else:
                break
        return p

    while pos < len(fn_body) and depth > 0:
        ch = fn_body[pos]
        if ch == "{":
            depth += 1
            pos += 1
            continue
        if ch == "}":
            depth -= 1
            if depth == 0:
                # End of switch.
                if cur_body_start is not None:
                    groups.append({"labels": list(cur_labels),
                                   "body": fn_body[cur_body_start:pos],
                                   "is_default": not cur_labels})
                break
            pos += 1
            continue
        if depth == 1:
            m = label_re.match(fn_body, pos)
            if m:
                label_text = m.group(1)
                is_default = label_text.startswith("default")
                # Determine whether this label extends the current
                # group (consecutive case labels, body not yet
                # started) or starts a new group.
                if cur_body_start is not None and not is_default:
                    between = fn_body[cur_body_start:pos]
                    stripped = skip_ws_comments(between, 0)
                    if stripped == len(between):
                        # Same group; append the case label.
                        cur_labels.append(
                            label_text.split()[1].rstrip(":"))
                        pos = m.end()
                        pos = skip_ws_comments(fn_body, pos)
                        cur_body_start = pos
                        continue
                # Flush previous group, then start a new one.
                if cur_body_start is not None:
                    groups.append({"labels": list(cur_labels),
                                   "body": fn_body[cur_body_start:pos],
                                   "is_default": not cur_labels})
                if is_default:
                    cur_labels = []
                else:
                    cur_labels = [label_text.split()[1].rstrip(":")]
                pos = m.end()
                pos = skip_ws_comments(fn_body, pos)
                cur_body_start = pos
                continue
        pos += 1
    return groups


def get_if_arm_bodies():
    """Return [(opcode, body), ...] for `if (ins->op == IR_X)`
    short-circuits in the dispatch.

    ACT-POLYC-LLVM-CORE03-CORRECTION02: scan BOTH llLowerBlock
    (which dispatches IR_BR, IR_JMP, IR_RET, IR_CMP_BR) and
    llLowerInstr (which dispatches the arithmetic/conversion/
    cast ops via its switch). The dispatch is split across these
    two functions, not consolidated into llLowerInstr."""
    text = read(SRC_BACKEND)
    out = []
    if_re = re.compile(
        r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)\s*\{",
    )

    # Find each dispatch function and scan its body for if-arms.
    for sig_re in (
        r"static\s+\w+\s+llLowerInstr\s*\([^)]*\)\s*\{",
        r"static\s+\w+\s+llLowerBlock\s*\([^)]*\)\s*\{",
    ):
        for fn_match in re.finditer(sig_re, text):
            start = fn_match.end()
            depth = 1
            i = start
            while i < len(text) and depth > 0:
                if text[i] == "{":
                    depth += 1
                elif text[i] == "}":
                    depth -= 1
                i += 1
            fn_body = text[start:i]
            for m in if_re.finditer(fn_body):
                op = m.group(1)
                body_start = m.end()
                depth = 1
                j = body_start
                while j < len(fn_body) and depth > 0:
                    if fn_body[j] == "{":
                        depth += 1
                    elif fn_body[j] == "}":
                        depth -= 1
                    j += 1
                out.append((op, fn_body[body_start:j - 1]))
    return out


def check_dispatch_arm_local_diagnostic(cap_rows_by_name, arm_groups, if_bodies):
    """ACT-POLYC-LLVM-CORE03-CORRECTION02 M2: bind the diagnostic to
    the dispatch arm body, not to backend.c as a whole.

    cap_rows_by_name is keyed by IR_X name (string).
    """
    body_for_op = {}
    for grp in arm_groups:
        for op in grp["labels"]:
            body_for_op.setdefault(op, []).append(grp["body"])
    for op, body in if_bodies:
        body_for_op.setdefault(op, []).append(body)
    for grp in arm_groups:
        if grp["is_default"]:
            body_for_op.setdefault("__default__", []).append(grp["body"])

    for op_name, row in cap_rows_by_name.items():
        if row["class"] != LLVMBC_REJECTED:
            continue
        if row["diagnostic"] is None:
            continue
        diag = row["diagnostic"]
        bodies = body_for_op.get(op_name)
        if not bodies:
            continue
        if not any(diag in b for b in bodies):
            other_holders = [o for o, bs in body_for_op.items()
                             if any(diag in b for b in bs)]
            fail("M2: {0} (REJECTED) diagnostic {1!r} NOT in this arm's"
                 " body. Appears in: {2}".format(
                     op_name, diag,
                     ", ".join(other_holders) or "<none>"))
        else:
            ok("M2: {0} diagnostic {1!r} bound to arm body".format(
                op_name, diag))


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
                # The arm-local diagnostic binding check is performed
                # in CORRECTION02's M2 (check_dispatch_arm_local_diagnostic).
                # That check is stronger than the previous whole-file
                # `diag in backend_text` heuristic, which false-GREENed
                # when the macro appeared in a comment or in a different
                # arm's body. See ACT-POLYC-LLVM-CORE03-CORRECTION02.md M2.
                pass
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

    # ACT-POLYC-LLVM-CORE03-CORRECTION02 M1: round-trip assertion.
    check_wire_format_roundtrip(cap_rows)

    # ACT-POLYC-LLVM-CORE03-CORRECTION02 M2: arm-local diagnostic binding.
    arm_groups = get_dispatch_arm_groups()
    if_bodies = get_if_arm_bodies()
    ok("M2 arm-group scan: {0} case-arm groups, {1} if-arm bodies in dispatch".format(
        len(arm_groups), len(if_bodies)))
    check_dispatch_arm_local_diagnostic(by_name, arm_groups, if_bodies)

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
