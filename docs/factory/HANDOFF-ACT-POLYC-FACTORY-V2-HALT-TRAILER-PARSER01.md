# HANDOFF: ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01

VERDICT

PASS_TRUE_GREEN

  The Factory-v2 commit metadata validation defect is repaired. A
  conforming HALT_* CLOSE commit is accepted by BOTH Factory-v2
  validators, and an ACT-like commit that cannot be parsed can never be
  classified as an ordinary NON_ACT commit.

  Measured:
    factory-v2-test           53 PASS / 0 FAIL  (rc=0)
    factory-append-only-test  11 PASS / 0 FAIL  (rc=0)
    gate-fast                 STATUS=PASS        (rc=0)

  No production compiler file was modified. No historical commit was
  rewritten. The historical bootstrap topology and its
  HALT_GATE_PUSH_NOT_GREEN remain exactly as they were.

This document is DESCRIPTIVE ONLY. The authoritative verdict for this ACT
lives in the `ACT-Verdict` trailer of its CLOSE commit, per
`docs/factory/GIT-METADATA.md` section 1.

```text
ACT:     ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01
CLASS:   FACTORY / QUALITY-TOOLING / SYSTEMIC-REPAIR
PRIORITY: P0
```

---

## 1. What was wrong

The Factory-v2 trailer grammar binds these keys on a `HALT_*` CLOSE:

```text
ACT: ACT-POLYC-...
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
ACT-Verdict: PASS|PASS_*|HALT_*
HALT_CLASS: GOVERNANCE|PRODUCTION|SAFETY|AUTHORIZATION|DEPENDENCY
BLOCKS_NEXT: YES|NO
```

`HALT_CLASS` and `BLOCKS_NEXT` contain underscores. Git's standard
trailer parser does not merely skip an underscore-bearing trailer: it
**rejects the whole trailer block**. Measured on git 2.54.0:

```text
$ printf 'x\n\nACT: A\nACT-Phase: CLOSE\n' | git interpret-trailers --parse
ACT: A
ACT-Phase: CLOSE

$ printf 'x\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' \
    | git interpret-trailers --parse
(empty)
```

Because those two keys are mandatory on every conforming `HALT_*` CLOSE,
**every conforming HALT commit lost its `ACT:`, `ACT-Phase:` and
`ACT-Verdict:` trailers as well.** Two validators then disagreed:

```text
scripts/quality/factory-v2-commit-msg-check.sh
    -> MODE=NON_ACT / STATUS=PASS   (FAIL-OPEN)

scripts/quality/factory-v2-range-check.sh
    -> STATUS=FAIL / count=0 ACT
```

The commit-message validator's fail-open rule was:

```sh
if no ACT trailer is present in parsed output:
    MODE=NON_ACT
    STATUS=PASS
```

That rule is only sound if the parser is faithful. Here it was not, so an
invalid ACT commit could be silently accepted as an ordinary commit, and
a valid HALT commit could be silently accepted as an ordinary commit
too.

The consequence was a repeated closure-correction cycle: a legitimate
HALT closure could never validate, so it had to be "corrected" again.

---

## 2. What was changed

### 2.1 One shared interpretation

`scripts/quality/factory-v2-trailer-compat.inc` is a **sourced library**
(not an executable tool) that carries the single canonical trailer
interpretation used by BOTH validators:

1. read the raw commit message; never mutate it;
2. produce a TEMPORARY copy in which ONLY the two known underscore
   keys are rewritten:

   ```text
   HALT_CLASS:  -> HALT-CLASS:
   BLOCKS_NEXT: -> BLOCKS-NEXT:
   ```

3. parse the temporary copy with `git interpret-trailers --parse`;
4. map the temporary keys back to their canonical names.

Values, ordering, duplicate detection, cardinalities and trailer-block
boundaries are preserved. No other key is normalized. A malformed
lookalike (for example `HALT CLASS:`) is **rejected, not silently
corrected**.

The raw commit message bytes are never changed.

### 2.2 Fail closed

`NON_ACT` is now returned only when the raw message carries **no**
ACT-like trailer key at all. If the raw message does carry ACT-like
metadata but no ACT trailer can be parsed from it, the validator
returns `MODE=ACT / STATUS=FAIL` with a nonzero status.

A literal `ACT:` in ordinary message prose is not ACT metadata and still
classifies as `NON_ACT / PASS`.

A footer whose ACT metadata is split across more than one trailer
region is malformed and is rejected.

### 2.3 HALT classification enforced

The commit-message validator now enforces the `docs/factory/GIT-METADATA.md`
section 2.4 rules:

```text
HALT_CLASS      | BLOCKS_NEXT
----------------|--------------
GOVERNANCE      | NO
PRODUCTION      | YES
SAFETY          | YES
AUTHORIZATION   | YES
DEPENDENCY      | YES or NO
```

A `HALT_*` verdict requires exactly one `HALT_CLASS` and exactly one
`BLOCKS_NEXT`. A `PASS(_...)*` verdict forbids both.

### 2.4 One range interpretation

The range check no longer reads git's `%(trailers)` formatter. It
consumes the same shared normalized interpretation.

### 2.5 Post-CLOSE continuation detector repaired

The rule "no commit after CLOSE may carry `ACT:<id>`" was implemented by
inspecting only the **direct children** of CLOSE. A same-ACT
continuation therefore **escaped** whenever an ordinary commit sat
between CLOSE and it:

```text
CLOSE -> ordinary commit -> same-ACT IMPL     was ACCEPTED (rc=0)
```

The check now walks the whole descendant path of CLOSE and rejects the
continuation in both shapes.

---

## 3. Measured result

The repair is demonstrable on the **real historical artifact**. The
predecessor's HALT CLOSE at `290d917` carries:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01
ACT-Phase: CLOSE
ACT-Verdict: HALT_GATE_PUSH_NOT_GREEN
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

```text
git %(trailers)        -> (empty)      <- the defect
shared normalized parse -> all five     <- the repair
```

Gates:

```text
factory-v2-test           53 PASS / 0 FAIL   (rc=0)
factory-append-only-test  11 PASS / 0 FAIL   (rc=0)
gate-fast                 STATUS=PASS         (rc=0)
```

The regression matrix grew from 35 to 53 cases (T35-T52). Every negative
case asserts the nonzero return code **and** the `MODE=ACT / STATUS=FAIL`
classification, so an intentionally malformed fixture cannot pass
because of an unrelated setup error.

The HALT classifier and both shell validators agree on all 15
comparisons.

---

## 4. What was deliberately NOT changed

```text
PRODUCTION_COMPILER_DELTA=0
PYTHON_DELTA=0
CLASSIFIER_SOURCE_DELTA=0
HISTORICAL_POST_CLOSE_VIOLATION=PRESERVED
HISTORICAL_HALT_GATE_PUSH_NOT_GREEN=PRESERVED
GEP01_PREEXISTING_FAILURE=UNRESOLVED
FULL_PUSH_GATE=NOT_CLAIMED_GREEN
```

The PolyC classifier `tools/factory/factory-halt-classification.HC` is
**unchanged**. It already parsed the underscore keys correctly; the two
shell validators were the broken ones. It is the authoritative reference
the shell validators are checked against.

The historical topology is untouched. The predecessor's post-CLOSE
continuation is still rejected, and its `HALT_GATE_PUSH_NOT_GREEN`
remains a HALT. A newly working parser does not make an invalid
historical topology valid.

The LLVM GEP01 cap-verifier failure keeps its own owner. This ACT
neither disables GEP01 nor changes the full push gate nor claims it is
green.

---

## 5. F14 restoration

The closed predecessor's HANDOFF had been mutated by a later commit
(`caf5cf9`), which appended a CORRECTION NOTICE to a closed artifact.
This ACT restored it to its original C4 bytes in a **forward-only**
commit:

```text
original C4 blob  b79ba057d09607e635c6ef1894b54ee2bc93aa4c
restored blob     b79ba057d09607e635c6ef1894b54ee2bc93aa4c
sha256            753f21b91e7664d1ba857f03746b5ec8698f0aab490007c77135c4aaf1264d53
```

The mutated version is preserved as additive evidence under this ACT's
`c3/` tree. No correction notice was appended to the restored file. The
predecessor's closed evidence tree was not modified.

---

## 6. Residue

**1. `src/asm/asm.c` does not support `@@N` local labels.**
`src/holyc-lib/memory.HC` uses them, so no `.HC` file that includes it
can be compiled on this host. Isolated to the construct:

```text
asm { LDP X29, X30, [SP], 16   // restore FP/LR
      RET }                      -> COMPILES

asm { CBZ X0, @@1
      SUB X0, X0, 8
@@1:  RET }                     -> ERROR: asm: unexpected token at start of line
```

PRE-EXISTING (reproduced in an isolated worktree at the C0 commit),
owner is `src/asm/asm.c`, which is OUT OF SCOPE here.
CLASSIFICATION=`UNRELATED_BASELINE_FAILURE`. It does not block this
ACT: the classifier source is unchanged and its existing binary
(sha256-verified against that source) served as the oracle.

**2. `scripts/quality/shell-loc-gate.sh` now reports 3 GROW entries**
for the three grandfathered legacy validators this ACT was authorized to
repair. That gate already failed at entry with 2 pre-existing
violations and is **not** wired into `gate-fast` or `gate-push`. The
frozen baseline is a closed ACT's evidence artifact and was not
modified (F14). CLASSIFICATION=`NON_BLOCKING_GOVERNANCE_RESIDUE`.
Migrating the Factory-v2 validators to PolyC is downstream work.

**3. LLVM GEP01 cap-verifier failure** remains FAIL and retains its own
owner.

---

## 7. Disposition

```text
FACTORY_V2_HALT_TRAILER_PARSER=QUALIFIED
FACTORY_V2_FAIL_OPEN=ELIMINATED
FACTORY_V2_POST_CLOSE_CONTINUATION_DETECTOR=REPAIRED

BOOTSTRAP_BUILD_ENGINEERING=GREEN
BOOTSTRAP_FULL_GATE_PUSH=FAIL_UNRELATED_GEP01
BOOTSTRAP_HISTORICAL_TOPOLOGY=IMMUTABLE_RESIDUE

PARSER_PADDING_AUTHORITY=POLYC

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
```

`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02` must conduct a **fresh**
selection of the next parser semantic slice. It must not automatically
retry the failed `parseCompoundStatementInternal` whole-function
migration. It reuses the R0 state-boundary ranking model from
`PARSER-SLICE-RECON01`, excludes the already-migrated `CalcPadding`,
selects the next genuinely bridgeable legacy-C semantic authority, and
authorizes its production migration as a **separate** engineering ACT.

The bootstrap lineage is closed for this board. Work returns to actual
PolyC compiler self-hosting.
