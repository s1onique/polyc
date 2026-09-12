#!/usr/bin/env python3
"""scripts/quality/factory-halt-classification.py

ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01

Factory v2 trailer classifier for `HALT_CLASS` and `BLOCKS_NEXT`.
Codifies the trailer contract defined at
docs/acts/ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01.md §0 and at
docs/factory/GIT-METADATA.md §2.4.

CONTRACT (post-CLOSE of MECHANICAL-BLOCKING01, applied only to
the commit(s) explicitly named on the command line; this script
does NOT walk repository history):

  PASS verdict (effective PASS(_...)*):
      HALT_CLASS  : forbidden (count must be 0)
      BLOCKS_NEXT : forbidden (count must be 0)

  HALT_* verdict (effective HALT_<TOKEN>):
      HALT_CLASS  : required (count == 1), value in
                    { GOVERNANCE, PRODUCTION, SAFETY,
                      AUTHORIZATION, DEPENDENCY }
      BLOCKS_NEXT : required (count == 1), value in { YES, NO }
      class/boolean combination valid.

Combinations:
    GOVERNANCE     -> BLOCKS_NEXT = NO   (mandatory)
    PRODUCTION     -> BLOCKS_NEXT = YES  (mandatory)
    SAFETY         -> BLOCKS_NEXT = YES  (mandatory)
    AUTHORIZATION  -> BLOCKS_NEXT = YES  (mandatory)
    DEPENDENCY     -> BLOCKS_NEXT = YES|NO (either)

USAGE:

  factory-halt-classification.py <commit-message-file>

Inspects ONE commit message at a time. Does NOT walk history.
Activation boundary: the C2 IMPL commit of
ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01. Historical CLOSE commits
are NOT validated by this script.

Parsing note: we do NOT delegate to `git interpret-trailers --parse`
because Git's built-in trailer parser (as of 2.54.0) does NOT accept
underscores in trailer keys; HALT_CLASS and BLOCKS_NEXT are dropped
by that parser. We parse directly with a regex against the
documented `<KEY>:[[:space:]]+<VALUE>` shape and require an explicit
"Key: value" line. The same additive constraint applies to
`ACT-Verdict` etc., but the existing factory-v2-commit-msg-check.sh
already validates those.

Migration history:

  ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D3: moved the
  substantive classification logic out of
  factory-halt-classification-check.sh (187 LOC) into this Python
  module. The shell script is now a thin launcher (<=50 LOC) that
  invokes this module. The 12-case regression matrix in
  factory-halt-classification-test.sh is also a thin launcher.
  This preserves the existing prospective/grandfathering boundary;
  pre-boundary CLOSE commits are NOT retroactively rejected.
"""

import re
import sys

# Compile-once regex for trailer parsing.
# Shape: `^KEY:[[:space:]]+VALUE` where KEY is one of the trailer keys.
_TRAILER_RE = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*):[ \t]+(.*)$")

_VALID_HALT_CLASS = {
    "GOVERNANCE",
    "PRODUCTION",
    "SAFETY",
    "AUTHORIZATION",
    "DEPENDENCY",
}
_VALID_BLOCKS_NEXT = {"YES", "NO"}

# HALT_CLASS -> required BLOCKS_NEXT (or None if either allowed).
_REQUIRED_BLOCKS_NEXT = {
    "GOVERNANCE": "NO",
    "PRODUCTION": "YES",
    "SAFETY": "YES",
    "AUTHORIZATION": "YES",
    "DEPENDENCY": None,
}


class Verdict:
    """Accumulated result of the trailer classifier.

    Mirrors the line-oriented output format of the prior shell
    implementation byte-for-byte: the launcher that wraps this
    module relies on STATUS= / REASON= / MODE= / ACT= /
    PHASE= / VERDICT= / HALT_CLASS= / BLOCKS_NEXT= lines.
    """

    def __init__(self):
        self.mode = ""
        self.status = ""
        self.reason = ""
        self.act = ""
        self.phase = ""
        self.verdict = ""
        self.halt_class = ""
        self.blocks_next = ""


def _trailer_values(msg, key):
    """Return list of values for every line matching `^KEY:`."""
    out = []
    for line in msg.splitlines():
        m = _TRAILER_RE.match(line)
        if not m:
            continue
        if m.group(1) == key:
            out.append(m.group(2))
    return out


def _trailer_value_first(msg, key):
    vs = _trailer_values(msg, key)
    return vs[0] if vs else ""


def classify(msg):
    """Classify one commit message.

    Returns a Verdict whose `status` is one of PASS / FAIL and whose
    fields are populated as the prior shell script populated its
    stdout lines.
    """
    v = Verdict()

    if not _trailer_values(msg, "ACT"):
        v.mode = "NON_ACT"
        v.status = "PASS"
        return v

    v.mode = "ACT"
    v.act = _trailer_value_first(msg, "ACT")
    v.phase = _trailer_value_first(msg, "ACT-Phase")
    v.verdict = _trailer_value_first(msg, "ACT-Verdict")
    v.halt_class = _trailer_value_first(msg, "HALT_CLASS")
    v.blocks_next = _trailer_value_first(msg, "BLOCKS_NEXT")

    halt_class_count = len(_trailer_values(msg, "HALT_CLASS"))
    blocks_next_count = len(_trailer_values(msg, "BLOCKS_NEXT"))

    # Non-CLOSE commits are not bound by the new contract.
    if v.phase != "CLOSE":
        v.status = "PASS"
        return v

    # CLOSE phase. Branch on verdict shape.
    if re.match(r"^HALT_[A-Z0-9_]+$", v.verdict or ""):
        if halt_class_count != 1:
            v.status = "FAIL"
            v.reason = (
                "HALT_CLASS count=%d, expected 1 for HALT verdict"
                % halt_class_count
            )
            return v
        if blocks_next_count != 1:
            v.status = "FAIL"
            v.reason = (
                "BLOCKS_NEXT count=%d, expected 1 for HALT verdict"
                % blocks_next_count
            )
            return v
        if v.halt_class not in _VALID_HALT_CLASS:
            v.status = "FAIL"
            v.reason = "HALT_CLASS '%s' not in enum" % v.halt_class
            return v
        if v.blocks_next not in _VALID_BLOCKS_NEXT:
            v.status = "FAIL"
            v.reason = "BLOCKS_NEXT '%s' not in {YES, NO}" % v.blocks_next
            return v
        required = _REQUIRED_BLOCKS_NEXT.get(v.halt_class)
        if required is not None and v.blocks_next != required:
            v.status = "FAIL"
            v.reason = (
                "%s requires BLOCKS_NEXT=%s"
                % (v.halt_class, required)
            )
            return v
    elif re.match(r"^PASS(_[A-Z0-9_]+)*$", v.verdict or ""):
        if halt_class_count != 0:
            v.status = "FAIL"
            v.reason = (
                "PASS verdict forbids HALT_CLASS (count=%d)"
                % halt_class_count
            )
            return v
        if blocks_next_count != 0:
            v.status = "FAIL"
            v.reason = (
                "PASS verdict forbids BLOCKS_NEXT (count=%d)"
                % blocks_next_count
            )
            return v

    v.status = "PASS"
    return v


def _emit(v):
    """Emit verdict fields in the prior shell's line-oriented format."""
    sys.stdout.write("MODE=%s\n" % v.mode)
    sys.stdout.write("STATUS=%s\n" % v.status)
    if v.reason:
        sys.stdout.write("REASON=%s\n" % v.reason)
    sys.stdout.write("ACT=%s\n" % v.act)
    sys.stdout.write("PHASE=%s\n" % v.phase)
    sys.stdout.write("VERDICT=%s\n" % v.verdict)
    sys.stdout.write("HALT_CLASS=%s\n" % v.halt_class)
    sys.stdout.write("BLOCKS_NEXT=%s\n" % v.blocks_next)


def main(argv):
    # Subcommand dispatch:
    #   argv[1] == "--matrix"            -> run the 12-fixture regression matrix
    #   argv[1] == <path>                -> classify the commit message at <path>
    if len(argv) == 2 and argv[1] == "--matrix":
        return run_matrix()
    if len(argv) != 2:
        sys.stdout.write("STATUS=ERROR\n")
        sys.stdout.write(
            "REASON=usage: factory-halt-classification.py "
            "<commit-message>\n"
        )
        return 2
    path = argv[1]
    try:
        with open(path, "r", encoding="utf-8") as f:
            msg = f.read()
    except IOError as e:
        sys.stdout.write("STATUS=ERROR\n")
        sys.stdout.write(
            "REASON=commit message file not found: %s (%s)\n" % (path, e)
        )
        return 2
    v = classify(msg)
    _emit(v)
    return 0 if v.status == "PASS" else 1


# ---------------------------------------------------------------------------
# Regression matrix (R1..R12). Preserved verbatim from
# scripts/quality/factory-halt-classification-test.sh so the shell
# launcher can simply call run_matrix() and emit the same PASS/FAIL
# summary the previous version did. Each fixture records the expected
# exit code (0 == PASS, 1 == FAIL) and the message body.
# ---------------------------------------------------------------------------

_FIXTURES = [
    (
        "R1 governance halt, NO block",
        0,
        "subject\n\nbody\n\n"
        "ACT: ACT-POLYC-EXAMPLE01\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
        "HALT_CLASS: GOVERNANCE\n"
        "BLOCKS_NEXT: NO",
    ),
    (
        "R2 production halt, YES block",
        0,
        "subject\n\nbody\n\n"
        "ACT: ACT-POLYC-EXAMPLE02\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
        "HALT_CLASS: PRODUCTION\n"
        "BLOCKS_NEXT: YES",
    ),
    (
        "R3 halt missing HALT_CLASS",
        1,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE03\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_X\n"
        "BLOCKS_NEXT: YES",
    ),
    (
        "R4 halt missing BLOCKS_NEXT",
        1,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE04\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_X\n"
        "HALT_CLASS: PRODUCTION",
    ),
    (
        "R5 PASS verdict with BLOCKS_NEXT",
        1,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE05\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: PASS\n"
        "BLOCKS_NEXT: YES",
    ),
    (
        "R6 GOVERNANCE/YES rejected",
        1,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE06\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_GOVERNANCE_HALT\n"
        "HALT_CLASS: GOVERNANCE\n"
        "BLOCKS_NEXT: YES",
    ),
    (
        "R7 PRODUCTION/NO rejected",
        1,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE07\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_PRODUCTION_DEFECT\n"
        "HALT_CLASS: PRODUCTION\n"
        "BLOCKS_NEXT: NO",
    ),
    (
        "R8 historical-style PASS, no trailers",
        0,
        "subject\n\nbody\n\n"
        "ACT: ACT-POLYC-EXAMPLE08\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: PASS",
    ),
    (
        "R9 DEPENDENCY/YES allowed",
        0,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE09\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_DEPENDENCY_HALT\n"
        "HALT_CLASS: DEPENDENCY\n"
        "BLOCKS_NEXT: YES",
    ),
    (
        "R10 DEPENDENCY/NO allowed",
        0,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE10\n"
        "ACT-Phase: CLOSE\n"
        "ACT-Verdict: HALT_DEPENDENCY_HALT\n"
        "HALT_CLASS: DEPENDENCY\n"
        "BLOCKS_NEXT: NO",
    ),
    (
        "R11 non-ACT commit",
        0,
        "ordinary commit message\n\nno trailers here",
    ),
    (
        "R12 RED phase, halt verdict, no trailers",
        0,
        "subject\n\n"
        "ACT: ACT-POLYC-EXAMPLE12\n"
        "ACT-Phase: RED\n"
        "ACT-Verdict: HALT_DRAFT",
    ),
]


def run_matrix():
    """Execute the 12-fixture regression matrix in-process.

    Returns rc=0 if all 12 fixtures map to their expected rc,
    rc=1 otherwise. Mirrors the prior shell test runner's output.
    """
    import io
    import contextlib

    passed = 0
    failed = 0
    for name, want_rc, msg in _FIXTURES:
        # Capture the classifier's stdout line-by-line without
        # crossing process boundaries; the prior shell test fed a
        # temp file and parsed STATUS=. We do the same in-memory.
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            v = classify(msg)
            _emit(v)
        out = buf.getvalue()
        got_rc = 0 if v.status == "PASS" else 1
        # Parse STATUS= from captured output (mirrors shell's grep).
        status = ""
        for line in out.splitlines():
            if line.startswith("STATUS="):
                status = line[len("STATUS="):]
                break
        if got_rc == want_rc:
            passed += 1
            sys.stdout.write(
                "  PASS  %s  (rc=%d status=%s)\n"
                % (name, got_rc, status)
            )
        else:
            failed += 1
            sys.stdout.write(
                "  FAIL  %s  want rc=%d got rc=%d status=%s\n  %s\n"
                % (name, want_rc, got_rc, status, out)
            )

    sys.stdout.write("--- summary ---\n")
    sys.stdout.write("PASS=%d\n" % passed)
    sys.stdout.write("FAIL=%d\n" % failed)
    if failed == 0:
        sys.stdout.write("STATUS=PASS\n")
        return 0
    sys.stdout.write("STATUS=FAIL\n")
    return 1



if __name__ == "__main__":
    sys.exit(main(sys.argv))
