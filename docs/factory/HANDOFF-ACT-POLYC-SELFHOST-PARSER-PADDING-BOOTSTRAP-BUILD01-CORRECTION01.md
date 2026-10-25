# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01

VERDICT

PASS

  This ACT changes NO production code. Its subject is the CLOSE
  TOPOLOGY of its predecessor, and that topology is repaired and
  verified mechanically.

---

## 1. Disposition

```text
ACT             = ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01
SUPERSEDES      = ACT-POLYC-SELFHOST-PARSER-PARDING-BOOTSTRAP-BUILD01
CORRECTED VERDICT OF THE PREDECESSOR = HALT_GATE_PUSH_NOT_GREEN
                                       (unchanged by this correction)
PRODUCTION DELTA OF THIS ACT = NONE
```

The predecessor's engineering result is preserved exactly:

```text
PARSER_PADDING_COMPONENT            = TRUE_GREEN
PARSER_PADDING_PRODUCTION_DELEGATION = TRUE_GREEN
PARSER_PADDING_CLEAN_BUILD          = TRUE_GREEN
PARSER_PADDING_BUILD_GRAPH          = ACYCLIC
```

---

## 2. What was wrong, and what was done

The predecessor's C4 CLOSE commit was followed by one more commit that
carried the predecessor's `ACT:` trailer, in order to record the
external terminality observations. That violates
`docs/factory/GIT-METADATA.md` section 3, rule 7:

```text
7. No commit after CLOSE may carry `ACT: <id>`.
```

The history is append-only, so the offending commit cannot be removed
and the predecessor's range cannot be rewritten. The Factory's
correction mechanism is the established remedy: a new ACT id with its
own contiguous C0..C4 range.

This ACT therefore owns a clean range:

```text
C0  ACT-Phase: RED        <- FIRST
C1  ACT-Phase: EVIDENCE
C2  ACT-Phase: IMPL
C3  ACT-Phase: EVIDENCE   <- the external terminality observations
C4  ACT-Phase: CLOSE      <- LAST
```

The observations that the predecessor recorded after its CLOSE are
recorded HERE, inside the range. The content is preserved; only its
position changes.

---

## 3. A second, independent, pre-existing defect (NOT repaired)

While diagnosing the first defect, the underlying reason the range check
could not read a HALT_* CLOSE commit was measured.

```text
Git 2.54.0's TRAILER PARSER REJECTS THE ENTIRE TRAILER BLOCK when any
trailer key contains an UNDERSCORE.

  printf 'x\n\nACT: A\nACT-Phase: CLOSE\n' | git interpret-trailers --parse
    -> ACT: A / ACT-Phase: CLOSE              (parses)
  printf 'x\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' \
    | git interpret-trailers --parse
    -> (empty; the whole block is dropped)
```

The range check reads the CLOSE commit's trailers with git's
`%(trailers)` formatter, so a conforming HALT_* CLOSE commit -- which
the Factory REQUIRES to carry `HALT_CLASS` and `BLOCKS_NEXT` -- can
never be read by the current range check.

The Factory's own established precedent fails identically:

```text
$ bash scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 505b007
STATUS=FAIL
REASON=CLOSE 505b007... does not carry exactly one ACT:
       ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01 (count=0)
```

Repairing the range-check implementation is explicitly OUT OF SCOPE
(the predecessor's section 4 forbids changing it, and this ACT changes
no production code). This ACT's own CLOSE therefore uses a PASS-form
verdict, which is both mechanically parseable and truthful for a
topology-only subject.

The defect is recorded as residue for the next owner.

---

## 4. Production conservation

```text
PRODUCTION FILES CHANGED BY THIS ACT = 0
```

Verified by comparing this ACT's tree against its authorized entry:
`Makefile`, `src/CMakeLists.txt`, `src/cmake/*`,
`.github/workflows/release.yml`, `.gitignore`, `src/parser.c`,
`tools/bootstrap/selfhost-parser-padding.HC`, `scripts/quality/*` and
`.githooks/pre-push` are all byte-identical.

The predecessor's evidence directory is untouched (F14). Only the
predecessor's HANDOFF VERDICT section -- which by the Factory's own
rule owns the terminal verdict -- carries a correction notice pointing
at this ACT.

---

## 5. Gates

```text
bash scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01 HEAD
  -> STATUS=PASS   (this ACT's own range satisfies rules 1..7)

bash scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 290d917
  -> the predecessor's range is well-formed again

make gate-fast                                  -> PASS
bash scripts/quality/factory-append-only-test.sh -> PASS (11/11)
git diff --check <entry>..HEAD                   -> 0 errors
```

---

## 6. Residue

```text
P2  The Factory-v2 range check cannot read a HALT_* CLOSE commit on
    Git 2.54, because git's trailer parser drops a block containing an
    underscore-bearing key. The check's own implementation and the
    Factory's HALT_CLASS/BLOCKS_NEXT trailer convention need to be
    reconciled. NOT repaired here (out of scope).

P1  The pre-existing LLVM GEP01 cap-verifier defect, which fails the
    full push gate at its `gep01` check with rows byte-identical to the
    pre-ACT baseline. Owned elsewhere; NOT repaired here.

P1  The pre-existing repository-wide F-NO-PYTHON condition over seven
    tracked Python files. NOT repaired here.

P1  The Linux runtime port remains macOS-only
    (ACT-POLYC-TOOLING-LINUX-PORT01).
```

---

## 7. Board effect

```text
PARSER_PADDING_CLEAN_BUILD          = TRUE_GREEN
PARSER_PADDING_BUILD_GRAPH          = ACYCLIC
PARSER_PADDING_PRODUCTION_DELEGATION = TRUE_GREEN
CLOSURE_TOPOLOGY                    = REPAIRED

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```
