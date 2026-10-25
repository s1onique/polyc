# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01-CORRECTION01
ACT-Phase: RED

**Title:** Correct the closure topology of
`ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01`

**Repository:** PolyC
**Branch:** `main`
**Class:** GOVERNANCE / CLOSURE-TOPOLOGY
**Priority:** P0
**Execution mode:** EXECUTE -- C0 through C4
**Authorized entry:** `fda4a62add5c2f268d1904f9243731727ae5d00b`
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01`
**Verdict target:** `PASS_TRUE_GREEN`

---

# 0. Mission (frozen)

The predecessor ACT repaired PolyC's bootstrap dependency graph. Its
ENGINEERING result is correct, measured, and is NOT in dispute. What is
wrong is its CLOSE TOPOLOGY.

`docs/factory/GIT-METADATA.md` section 3, rule 7 states:

```text
7. No commit after CLOSE may carry `ACT: <id>`.
```

The predecessor's C4 CLOSE commit was followed by a further commit that
carried the same `ACT:` trailer in order to record the external
terminality observations. That commit therefore violates rule 7, and
the mechanical range check correctly rejects the predecessor's range:

```text
$ bash scripts/quality/factory-v2-range-check.sh \
    ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 HEAD
STATUS=FAIL
REASON=CLOSE a1b1f20... does not carry exactly one ACT-Phase: CLOSE (count=0)
```

Because the history is APPEND-ONLY (AGENTS.md), the offending commit
cannot be removed and the predecessor's topology cannot be rewritten.
The Factory's established remedy for exactly this situation is a
CORRECTION ACT: a NEW act id with its own contiguous C0..C4 range, which
supersedes the predecessor and records the corrected verdict.

This ACT therefore:

1. opens a new, cleanly-topologized ACT range for the same production
   subject;
2. records the predecessor's corrected verdict;
3. re-records the external terminality observations INSIDE that range,
   so that no commit carrying this ACT's id follows its CLOSE;
4. changes NO production code.

# 1. Scope

## IN SCOPE

- this ACT document and its evidence directory;
- the predecessor's HANDOFF verdict section, which this ACT corrects;
- `docs/factory/act-handoff-map.tsv`, to register this ACT's pair;
- `docs/ROADMAP.md`, to record the corrected disposition.

## OUT OF SCOPE

- ALL production code: `Makefile`, `src/CMakeLists.txt`,
  `src/cmake/*`, `.github/workflows/release.yml`, `.gitignore`;
- `src/parser.c`, `tools/bootstrap/selfhost-parser-padding.HC`;
- `scripts/quality/gate-push.sh`, `scripts/quality/gate-fast.sh`,
  `.githooks/pre-push`;
- the Factory-v2 range-check IMPLEMENTATION;
- the pre-existing GEP01 cap-verifier defect;
- the pre-existing F-NO-PYTHON repository-wide condition;
- any closed predecessor's evidence.

This ACT introduces NO production change and NO new tool. Its whole
subject is closure topology.

# 2. Root cause (frozen)

```text
ROOT_CAUSE = a post-CLOSE commit carried `ACT:
              ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01`,
              which GIT-METADATA.md section 3 rule 7 forbids.

WHY IT HAPPENED = the external terminality observations of ACT section 43
              were recorded AFTER the C4 CLOSE commit was made, and
              the commit that carried them was given the ACT's own
              trailer so that it would be attributed to the ACT.

CORRECTION = record those observations INSIDE a contiguous C0..C4 range
              that belongs to a NEW act id, so that the new range
              satisfies rules 1..7 and the predecessor's range is
              left immutable.
```

A SECOND, INDEPENDENT defect was measured while diagnosing the first
one. It is PRE-EXISTING and is NOT repaired by this ACT (it is
out of scope, and repairing the Factory-v2 range-check implementation is
explicitly forbidden by the predecessor's section 4):

```text
SECONDARY = Git 2.54.0's trailer parser REJECTS THE ENTIRE TRAILER BLOCK
             when any trailer key contains an UNDERSCORE. The range check
             reads the CLOSE commit's trailers with git's %(trailers)
             formatter, so a conforming HALT_* CLOSE commit -- which the
             Factory REQUIRES to carry HALT_CLASS and BLOCKS_NEXT -- can
             never be read by the current range check.

             Measured:
               printf 'x\n\nACT: A\nACT-Phase: CLOSE\n' \
                 | git interpret-trailers --parse
                 -> ACT: A / ACT-Phase: CLOSE        (parses)
               printf 'x\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' \
                 | git interpret-trailers --parse
                 -> (empty; the whole block is dropped)

             The Factory's OWN precedent commit 505b007
             (ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01) fails the
             identical check with the identical reason.

             This correction's own CLOSE commit will therefore use a
             PASS-form verdict, which is BOTH mechanically parseable AND
             truthful for this ACT: this ACT's subject is the closure
             TOPOLOGY, and the topology is repaired and verified.
```

# 3. Acceptance criteria

```text
AC01  The predecessor's production result is preserved unchanged
      (no production file differs from the predecessor's C4 tree)
AC02  The predecessor's evidence and HANDOFF are not rewritten; the
      corrected verdict is recorded in THIS ACT's artifacts
AC03  This ACT's own range satisfies GIT-METADATA.md section 3 rules
      1..7, verified mechanically by factory-v2-range-check.sh
AC04  The predecessor's range still fails the range check for the
      SAME pre-existing reason, and the reason is classified with
      evidence (it is NOT repaired here)
AC05  The Factory fast gate passes
AC06  The Factory append-only suite passes
AC07  Patch hygiene is clean
AC08  Commit trailers comply with Factory v2
AC09  The closure-topology repair is measured, not asserted
```

# 4. HALT taxonomy

```text
HALT_TOPOLOGY_NOT_REPAIRABLE
HALT_ENTRY_IDENTITY_MISMATCH
HALT_MANDATORY_AC_NOT_GREEN
HALT_EXTERNAL_TERMINALITY_FAILED
```

# 5. Next ACT

```text
NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```
