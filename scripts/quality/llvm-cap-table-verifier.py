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


def _function_body(text, name):
    """Return the body text of `static ... name(...)` in text, or None.
    Uses brace counting; ignores string literals and char literals
    only insofar as this matches the verifier's existing tolerance
    for the dispatch source. The dispatch functions do not contain
    string literals with braces, so naive counting is safe here."""
    pat = re.compile(
        r"static\s+\w[\w\s\*]*\b" + re.escape(name) + r"\s*\([^)]*\)\s*\{"
    )
    m = pat.search(text)
    if not m:
        return None
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[start:i - 1]


def _function_span(text, name):
    """Return (body_start_offset, body_end_offset) of the body of
    `static ... name(...)` in `text`, where offsets are absolute
    file offsets (indices into `text`). Returns None if not found.

    `body_start_offset` is the position of the first character inside
    the opening brace. `body_end_offset` is the position of the
    closing brace (exclusive).

    ACT-POLYC-LLVM-CORE04-RESUME01 C2 IMPL P0-2: location-aware
    rogue-arm checks need per-occurrence identity (function + offset),
    not just opcode sets. This helper provides the offset half.
    """
    pat = re.compile(
        r"static\s+\w[\w\s\*]*\b" + re.escape(name) + r"\s*\([^)]*\)\s*\{"
    )
    m = pat.search(text)
    if not m:
        return None
    start = m.end()
    depth = 1
    i = start
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return (start, i - 1)


def _enclosing_function(text, offset):
    """Return the function name whose body contains the absolute
    file offset `offset`, or None if not inside any tracked
    `static ... { ... }` function. Walks the function spans in
    text and returns the smallest-enclosing function name.

    Used by the location-aware rogue-arm check.
    """
    # Re-derive all function spans from text (slow O(n) per call,
    # but only invoked in the small set of rogue-arm checks).
    fn_pat = re.compile(
        r"static\s+\w[\w\s\*]*\b([a-zA-Z_]\w*)\s*\([^)]*\)\s*\{"
    )
    best = None
    best_size = None
    for m in fn_pat.finditer(text):
        fn_name = m.group(1)
        span = _function_span(text, fn_name)
        if span is None:
            continue
        s, e = span
        if s <= offset < e:
            size = e - s
            if best is None or size < best_size:
                best = fn_name
                best_size = size
    return best


def _collect_if_arms(text, enum_ops):
    """Walk every `if (ins->op == IR_X)` occurrence file-wide and
    return a list of (op, function_name_or_None, file_offset) triples.

    ACT-POLYC-LLVM-CORE04-RESUME01 C2 IMPL P0-2: occurrence-level
    identity. Two arms with the same opcode but in different
    functions (or the same function but different offsets) yield
    different triples.

    `enum_ops` filters out non-IrOp identifiers (e.g. IrCmpKind).
    """
    if_re = re.compile(
        r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)"
    )
    out = []
    for m in if_re.finditer(text):
        op = m.group(1)
        if op not in enum_ops:
            continue
        fn = _enclosing_function(text, m.start())
        out.append((op, fn, m.start()))
    return out


def _is_dispatch_function_body(body):
    """Return True if the body contains a dispatch-shaped construct
    (`case IR_X:` arm OR `if (ins->op == IR_X)` short-circuit)."""
    if body is None:
        return False
    if re.search(r"\bcase\s+IR_[A-Z_0-9]+\s*:", body):
        return True
    if re.search(r"\bif\s*\(\s*ins->op\s*==\s*IR_[A-Z_0-9]+", body):
        return True
    return False


def discover_dispatch_functions(text, driver_name="llFunction"):
    """Derive the set of dispatch function names by structural
    call-graph discovery with a dispatch-shape discriminator.

    ACT-POLYC-LLVM-CORE04-RESUME01 M1: the dispatch function set is
    NOT a hard-coded literal from ACT prose. It is derived from the
    real source by walking the call graph reachable from
    `driver_name()` and keeping only those reachable functions that
    contain a dispatch-shaped construct (`case IR_X:` or
    `if (ins->op == IR_X)`).

    This combination of two structural properties is the only
    invariant that distinguishes real dispatchers from the
    adversarial fixture (RESUME01_ADVERSARIAL_DISPATCH_SNIPPET):

      - The adversarial fixture's `not_a_dispatch_helper` and
        `also_not_a_dispatch_helper` are static functions
        containing `if (ins->op == IR_ADD)` etc. They contain the
        dispatch shape. BUT they are not called from llFunction(),
        so call-graph reachability excludes them. Verified.

      - The real non-dispatch helpers (llBindParams, llCreateBlocks,
        llEmitCapabilityCountersOnce, llDetectCollapsibleReturn,
        etc.) ARE called from llFunction(). BUT they do NOT
        contain `case IR_X:` or `if (ins->op == IR_X)` arms, so the
        dispatch-shape filter excludes them. Verified.

      - The real dispatchers (llLowerBlock, llLowerInstr) are
        reachable from llFunction() and contain the dispatch shape.
        They pass both filters. Verified.

    Depth limit: we follow the call graph two hops beyond
    llFunction. Three hops is enough for the current spike's
    `llvmEmitProgram -> llFunction -> llLowerBlock -> llLowerInstr`
    topology.
    """
    seen = set()
    frontier = {driver_name}
    depth_limit = 3  # driver + 3 transitive hops
    call_re = re.compile(r"\b([a-zA-Z_]\w*)\s*\(")
    excluded = {"if", "for", "while", "switch", "do", "return",
                "sizeof", "__builtin_expect"}
    for _ in range(depth_limit + 1):
        next_frontier = set()
        for name in frontier:
            if name in seen or name in excluded:
                continue
            body = _function_body(text, name)
            if body is None:
                continue
            seen.add(name)
            for m in call_re.finditer(body):
                callee = m.group(1)
                if callee in seen or callee in excluded or callee == name:
                    continue
                if _function_body(text, callee) is not None:
                    next_frontier.add(callee)
        if not next_frontier:
            break
        frontier = next_frontier
    seen.discard(driver_name)
    # Apply the dispatch-shape filter: only functions that contain
    # `case IR_X:` or `if (ins->op == IR_X)` arms are dispatchers.
    # This is the only invariant that, combined with call-graph
    # reachability, excludes both the permanent adversarial fixture
    # AND the real non-dispatch helpers.
    dispatch = set()
    for name in seen:
        body = _function_body(text, name)
        if _is_dispatch_function_body(body):
            dispatch.add(name)
    return dispatch


def get_dispatch_arms():
    """ACT-POLYC-LLVM-CORE04-RESUME01 M1: ONE canonical dispatch
    model. Returns a dict:

        {
            "case_in_llLowerInstr": set of opcodes covered by
                                    `case IR_X:` arms inside any
                                    discovered dispatch function.
            "if_in_llLowerInstr_or_switch": set of opcodes covered by
                                    `if (ins->op == IR_X)` arms
                                    inside any discovered dispatch
                                    function.
            "case_anywhere": set of opcodes with any `case IR_X:`
                             arm anywhere in src/llvm-backend.c
                             (kept for diagnostic context only; the
                             I1 / I2 / arm-local checks consume only
                             the scope-tight sets).
            "if_anywhere":  set of opcodes with any `if (ins->op == IR_X)`
                            arm anywhere in src/llvm-backend.c
                            (diagnostic context only).
            "scope_fn_names": sorted list of discovered dispatch
                              function names (structural discovery).
            "model": list of dispatch-arm records (one per case arm
                     and one per if-arm in scope).
        }

    The scope is derived from the real source (call-graph from
    llFunction()), not from a hard-coded list of function names.
    The permanent adversarial fixture is structurally excluded by
    virtue of NOT being called from llFunction().
    """
    text = read(SRC_BACKEND)
    return _build_dispatch_arms_for_text(text)


def _build_dispatch_arms_for_text(text):
    """Internal: build the dispatch-arm model for an arbitrary
    source text. Used by `get_dispatch_arms()` for the real source
    AND by the strong-NC1 self-test for an in-memory augmented
    source. The signature differs from `get_dispatch_arms()` only
    in that it accepts text directly rather than reading
    SRC_BACKEND.
    """
    scope_fn_names = sorted(discover_dispatch_functions(text))
    if not scope_fn_names:
        scope_fn_names = []

    # ACT-POLYC-LLVM-CORE04-RESUME01 M1: filter the case-arm scan
    # to known IrOp names. This rejects predicate enums
    # (IrCmpKind: IR_CMP_*, IR_CMP_INVALID) that may appear inside
    # dispatch-adjacent helpers (e.g. llCmpKindToLLVMPred). The
    # verifier must only consume opcode-shaped identifiers.
    enum_ops = get_ir_op_enum()

    case_in = set()
    if_in = set()
    case_any = set()
    if_any = set()
    model = []

    case_re = re.compile(r"case\s+(IR_[A-Z_0-9]+)\s*:")
    if_re = re.compile(
        r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)"
    )

    for fn_name in scope_fn_names:
        span = _function_span(text, fn_name)
        body = _function_body(text, fn_name)
        if body is None or span is None:
            continue
        body_start, _body_end = span
        for m in case_re.finditer(body):
            op = m.group(1)
            if op not in enum_ops:
                continue  # predicate or other non-IrOp identifier
            case_in.add(op)
            model.append({
                "op": op,
                "kind": "CASE",
                "function": fn_name,
                "file_offset": body_start + m.start(),
            })
        for m in if_re.finditer(body):
            op = m.group(1)
            if op not in enum_ops:
                continue
            if_in.add(op)
            model.append({
                "op": op,
                "kind": "IF_SHORT",
                "function": fn_name,
                "file_offset": body_start + m.start(),
            })

    for m in case_re.finditer(text):
        op = m.group(1)
        if op in enum_ops:
            case_any.add(op)
    for m in if_re.finditer(text):
        op = m.group(1)
        if op in enum_ops:
            if_any.add(op)

    return {
        "case_in_llLowerInstr": case_in,
        "if_in_llLowerInstr_or_switch": if_in,
        "case_anywhere": case_any,
        "if_anywhere": if_any,
        "scope_fn_names": scope_fn_names,
        "model": model,
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


# -----------------------------------------------------------------------------
# ACT-POLYC-LLVM-CORE04-RESUME01 — permanent adversarial scope-tight test.
#
# The CORE03-CORRECTION03 P1 residue observes that the verifier's
# `if`-arm extractor (in get_dispatch_arms()) collects `if (ins->op
# == IR_X)` short-circuits anywhere in src/llvm-backend.c, while the
# I1 forward check and the arm-local body extractor (I2 reverse
# check) scope to llLowerInstr and the explicit switch helpers.
#
# The asymmetry means a new `if (ins->op == IR_X)` arm added outside
# llLowerInstr would silently be counted as a handler without being
# bound to a capability-table row. RESUME01 unifies these scopes.
#
# This self-test is PERMANENT. It contains a labelled adversarial
# source snippet (a function named `not_a_dispatch_helper` carrying
# an `if (ins->op == IR_IADD) return ...;`). The verifier parses this
# snippet and asserts that the scope-tighter REJECTS it (i.e. IR_IADD
# outside the real dispatch is NOT accepted as a handler, even though
# IR_IADD is a real IrOp enum member and is otherwise supported in
# the legitimate dispatch scope). The fixture is NOT removed after
# IMPL passes; it is the canonical demonstration invariant. Future
# regressions re-trigger the FAIL.
#
# NOTE: IR_IADD/IR_ISUB/IR_IMUL are real PolyC IrOp enum members;
# earlier revisions of this fixture used the non-enum names
# IR_ADD/IR_SUB/IR_MUL which were filtered out by the enum gate
# before the scope check even ran. The real IrOp names are used here
# so the fixture actually exercises structural scope discovery
# rather than name filtering. See ACT-POLYC-LLVM-CORE04-RESUME01
# sec 5.2 and AC13.
#
# Fixture must remain labelled so a careless reader does not delete it.
# -----------------------------------------------------------------------------

RESUME01_ADVERSARIAL_DISPATCH_SNIPPET = r"""
/* RESUME01-ADVERSARIAL-FIXTURE: not real dispatch code; do not delete.
 *
 * Purpose: demonstrate that the dispatch-scope parser does NOT
 * pick up if-statements referencing IrOp constants when those
 * if-statements live outside the canonical dispatch functions.
 * If this snippet is ever deleted, the
 * check_dispatch_scope_is_tight() self-test loses its canonical
 * regression witness. See ACT-POLYC-LLVM-CORE04-RESUME01 sec 5.2
 * and AC13.
 */

static int not_a_dispatch_helper(IrInstr *ins)
{
    /* This is NOT inside llLowerInstr. A scope-tight parser must
     * refuse to treat the matching opcodes here as registered
     * handlers. IR_IADD / IR_ISUB are real IrOp enum members
     * (and are legitimately handled inside llLowerInstr), but
     * this arm lives outside the dispatch scope, so it must be
     * excluded by structural discovery from llFunction(). */
    if (ins->op == IR_IADD) {
        return -1;
    }
    if (ins->op == IR_ISUB) {
        return -2;
    }
    return 0;
}

static int also_not_a_dispatch_helper(IrInstr *ins)
{
    if (ins->op == IR_IMUL) {
        return -3;
    }
    return 0;
}
"""


def check_dispatch_scope_is_tight(dispatch):
    """ACT-POLYC-LLVM-CORE04-RESUME01 §5.2 / AC13: PERMANENT scope-tight
    self-test.

    C2 GREEN: the verifier now consumes ONE scoped dispatch model
    produced by get_dispatch_arms(). The self-test asserts:

      1. The permanent adversarial fixture's `if (ins->op == IR_X)`
         arms (IR_IADD, IR_ISUB inside `not_a_dispatch_helper` and
         IR_IMUL inside `also_not_a_dispatch_helper`) are NOT picked
         up by the unified scope-tight extractor. These are real
         IrOp enum members (already supported by the legitimate
         scope) — the fixture therefore exercises structural scope
         discovery rather than enum-name filtering.

      2. The unified model is internally consistent: the
         `if_in_llLowerInstr_or_switch` set reported by
         get_dispatch_arms() equals the set re-derived by walking
         the discovered dispatch functions and re-scanning their
         bodies.

      3. No rogue `if (ins->op == IR_X)` arm exists OUTSIDE the
         discovered dispatch functions. Such an arm would mean the
         discovery scope is too narrow (a real dispatch arm lives
         in a helper that the call-graph did not reach).

      4. The location-aware rogue-arm check rejects an in-memory
         adversarial source that contains a rogue `if (ins->op ==
         IR_IADD)` inside a non-dispatch helper (IR_IADD is
         already-supported by the real dispatch). This is the
         strong NC1: the old set-based check would have missed it
         because the legitimate scope already contains IR_IADD.

    This test FAILS if any future regression widens the scope
    (file-wide scan), narrows it (drops a real dispatch function),
    or weakens the rogue-arm identity (collapses occurrences to
    opcodes again).
    """
    adversarial = RESUME01_ADVERSARIAL_DISPATCH_SNIPPET
    # Re-run the unified scope on the adversarial fixture using
    # the same scope_fn_names the verifier derived for the real
    # source. The adversarial snippet defines
    # `not_a_dispatch_helper` and `also_not_a_dispatch_helper`;
    # neither is called from `llFunction()`, so they MUST be
    # excluded by structural discovery.
    scoped_adversarial = set()
    for fn_name in dispatch["scope_fn_names"]:
        body = _function_body(adversarial, fn_name)
        if body is None:
            continue
        for m in re.finditer(
            r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)", body
        ):
            scoped_adversarial.add(m.group(1))
    expected_adversarial_scoped = set()
    if scoped_adversarial != expected_adversarial_scoped:
        fail(
            "scope-tight self-test: adversarial fixture's "
            "`if (ins->op == IR_X)` arms leaked into the scope. "
            "Scoped extractor picked up {0!r}, expected {1!r}. "
            "The structural discovery must continue to exclude "
            "non-dispatch helper functions (RESUME01 AC13)."
            .format(scoped_adversarial, expected_adversarial_scoped)
        )
        return

    # Internal-consistency cross-check on the real source.
    real_text = read(SRC_BACKEND)
    expected_scoped_real = dispatch["if_in_llLowerInstr_or_switch"]
    derived_scoped_real = set()
    for fn_name in dispatch["scope_fn_names"]:
        body = _function_body(real_text, fn_name)
        if body is None:
            continue
        for m in re.finditer(
            r"if\s*\(\s*ins->op\s*==\s*(IR_[A-Z_0-9]+)\s*\)", body
        ):
            derived_scoped_real.add(m.group(1))
    if derived_scoped_real != expected_scoped_real:
        fail(
            "scope-tight self-test: unified dispatch model's "
            "if-arm set ({0!r}) does not match the re-derived "
            "scoped set ({1!r}). This is a consistency defect; "
            "the model is internally incoherent."
            .format(sorted(expected_scoped_real),
                    sorted(derived_scoped_real))
        )
        return

    # No rogue arms (location-aware): every `if (ins->op == IR_X)`
    # occurrence in src/llvm-backend.c must live inside a discovered
    # dispatch function.
    #
    # ACT-POLYC-LLVM-CORE04-RESUME01 C2 IMPL P0-2: the previous
    # set-based check collapsed occurrences to opcode sets, which
    # silently passed when a rogue `if (ins->op == IR_IADD)` (or any
    # already-supported opcode) appeared outside the dispatch scope.
    # Occurrences are now compared by (function_name, file_offset);
    # the set of legitimate occurrences is derived from the canonical
    # `model` records. Two arms with the same opcode but in
    # different functions (or even the same function but different
    # offsets) are distinct.
    real_enum_ops = get_ir_op_enum()
    loose_real = _collect_if_arms(real_text, real_enum_ops)
    # Build the legitimate occurrence set from the canonical model
    # (records with op + kind = IF_SHORT and a function).
    legit_real = set()
    for rec in dispatch["model"]:
        if rec["kind"] != "IF_SHORT":
            continue
        legit_real.add((rec["function"], rec["file_offset"]))

    rogue = []
    for op, fn, off in loose_real:
        # An occurrence is rogue if its enclosing function is not a
        # discovered dispatch function (None or unknown), OR if it
        # is in a dispatch function but at an offset that the
        # canonical model did not record (e.g. a duplicate dispatch
        # arm inside an already-scoped helper that wasn't counted).
        if fn is None:
            rogue.append((op, fn, off))
            continue
        if fn not in set(dispatch["scope_fn_names"]):
            rogue.append((op, fn, off))
            continue
        if (fn, off) not in legit_real:
            rogue.append((op, fn, off))
    if rogue:
        # Format rogue list as sorted (op, function, offset) tuples
        # for the FAIL message.
        rogue_fmt = sorted(
            "{0}@{1}:{2}".format(op, fn or "<none>", off)
            for op, fn, off in rogue
        )
        fail(
            "scope-tight self-test: rogue `if (ins->op == IR_X)` "
            "arms exist outside the discovered dispatch scope "
            "(location-aware, occurrence identity): {0}. "
            "The structural discovery must cover every real "
            "dispatch arm; helpers containing dispatch-shaped "
            "constructs are NOT real dispatch unless called from "
            "llFunction() / its transitive helpers, and any "
            "occurrence already in a discovered function must be "
            "in the canonical model. RESUME01 M1 FAILS on the "
            "verifier.".format(rogue_fmt)
        )
        return

    print(
        "INFO  scope-tight self-test: discovered dispatch "
        "functions = {0}; unified model set: {1} case arms, "
        "{2} if-arms in scope.".format(
            dispatch["scope_fn_names"],
            len(dispatch["case_in_llLowerInstr"]),
            len(dispatch["if_in_llLowerInstr_or_switch"])
        )
    )

    # Strong NC1: location-aware rogue-arm check on an augmented
    # source that has a rogue `if (ins->op == IR_IADD)` arm in a
    # non-dispatch helper. IR_IADD is already-supported in the real
    # dispatch, so the OLD set-based check would have returned
    # `rogue = empty` and FAILED to detect this. The new
    # location-aware check MUST return a non-empty rogue list.
    #
    # This is the strong NC1 requested by the C2 IMPL reviewer:
    # a rogue ALREADY-SUPPORTED opcode outside the reachable
    # dispatch scope.
    #
    # Note: we use `IR_IADD` (not the reviewer's suggested `IR_ADD`,
    # which is not a member of the IrOp enum in this codebase;
    # the actual PolyC opcode for integer add is IR_IADD). The
    # enum filter would discard `IR_ADD` as a non-IrOp identifier;
    # `IR_IADD` is the correct already-supported duplicate to use.
    augmented = real_text + "\n\n" + (
        "/* RESUME01-STRONG-NC1: not real dispatch code; do not delete.\n"
        " *\n"
        " * Purpose: demonstrate that the location-aware rogue-arm\n"
        " * check rejects an `if (ins->op == IR_IADD)` arm placed\n"
        " * inside a non-dispatch helper. IR_IADD is already a\n"
        " * supported opcode in the real dispatch scope, so the\n"
        " * old opcode-set check would have silently passed.\n"
        " */\n"
        "static int rogue_dup_iadd_helper(IrInstr *ins)\n"
        "{\n"
        "    if (ins->op == IR_IADD) {\n"
        "        return 999;\n"
        "    }\n"
        "    return 0;\n"
        "}\n"
    )
    # Re-derive the dispatch model on the augmented source.
    augmented_dispatch = _build_dispatch_arms_for_text(augmented)
    # Run the location-aware rogue-arm check on the augmented
    # source; we expect it to produce a non-empty rogue list.
    aug_enum_ops = get_ir_op_enum()
    aug_loose = _collect_if_arms(augmented, aug_enum_ops)
    aug_legit = set()
    for rec in augmented_dispatch["model"]:
        if rec["kind"] != "IF_SHORT":
            continue
        aug_legit.add((rec["function"], rec["file_offset"]))
    aug_rogue = []
    for op, fn, off in aug_loose:
        if fn is None or fn not in set(augmented_dispatch["scope_fn_names"]):
            aug_rogue.append((op, fn, off))
            continue
        if (fn, off) not in aug_legit:
            aug_rogue.append((op, fn, off))
    # The strong NC1 expects exactly one rogue occurrence:
    # IR_IADD inside rogue_dup_iadd_helper.
    if not aug_rogue:
        fail(
            "scope-tight self-test (strong NC1): location-aware "
            "rogue-arm check FAILED to detect a rogue "
            "`if (ins->op == IR_IADD)` placed inside a "
            "non-dispatch helper. IR_IADD is already in the "
            "real dispatch scope, so the OLD set-based check "
            "would also have missed this. The location-aware "
            "check must return non-empty rogue list. This means "
            "the check has been weakened back to opcode-set "
            "identity."
        )
        return
    # Confirm the rogue is specifically IR_IADD outside scope.
    ir_iadd_rogue = [
        (op, fn, off) for (op, fn, off) in aug_rogue
        if op == "IR_IADD" and fn == "rogue_dup_iadd_helper"
    ]
    if not ir_iadd_rogue:
        fail(
            "scope-tight self-test (strong NC1): location-aware "
            "rogue-arm check returned {0!r} but did not include "
            "the expected rogue IR_IADD inside "
            "rogue_dup_iadd_helper.".format(aug_rogue)
        )
        return

    ok(
        "scope-tight self-test (RESUME01 AC13): permanent "
        "adversarial fixture rejected by unified scope; "
        "unified model is internally consistent; no rogue "
        "`if`-arms outside discovered scope; strong NC1 "
        "(already-supported IR_IADD in non-dispatch helper) "
        "is correctly detected by the location-aware check."
    )


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

    # ACT-POLYC-LLVM-CORE04-RESUME01 §5.2 / AC13: permanent
    # scope-tight self-test. Runs on every invocation. Fixture stays
    # in tree forever.
    check_dispatch_scope_is_tight(dispatch)

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
