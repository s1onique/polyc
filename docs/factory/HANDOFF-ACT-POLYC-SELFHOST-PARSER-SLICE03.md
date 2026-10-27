# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE03

Factory-Version: 2

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This document is a human summary.

---

## 1. Entry identity and baseline

```text
ENTRY_HEAD       = 50cabc1141f66e6d43d2f65524f1fd4d9933a3bc
                  (the ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 CLOSE)
BRANCH           = main
WORKTREE_CLEAN   = YES
GIT_REPLACE_REFS = 0
PREDECESSOR      = ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
PREDECESSOR_REACHABLE = YES
```

The entry HEAD was read from the live tree when the ACT was opened, not
copied from a historical document.

---

## 2. The predecessor's disposition

RECON03's engineering findings stand and are inherited:

```text
SELECTED_CANDIDATE = CAND-017 parseGetPriority (src/prslib.c:1139..1207)
SELECTED_ABI        = I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence
```

RECON03's **closure** is treated as `HALT_ACKNOWLEDGED`: its own AC
ledger records AC47 (`gate-push` passes) as
`FAIL_PRE_EXISTING_HOST_ISSUE`, so it could not close with every
mandatory AC green.  Its `ACT-Verdict: PASS` trailer is the historical
record and is preserved verbatim.

RECON03's ACT document, evidence tree and HANDOFF are **not modified**
(F14).  The historical two-tool scope violation is recorded in this
ACT's own evidence.  A fresh `gate-push` on this host does not
retroactively change RECON03's AC47, and this ACT does not claim that
it does; it establishes that the current tree passes the gate **without
a harness repair**, which is why this ACT introduced none.

---

## 3. The contract requalification (C0--C1)

The successor contract was **not** usable as-is.  It was requalified
against the live source by a tool, not by prose.

### The precedence table was re-derived

```text
DERIVED_TABLE_ENTRIES=39
DERIVED_UNRESOLVED_LABELS=0
DERIVED_SENTINEL=-1        (read out of the live default arm)
LEXER_H_DEFINES_PARSED=117
```

The derived table agrees with the predecessor's prose table on every
precedence class (3,1,6,3,2,2,4,2,1,1,1,1,1,11 = 39).  The
requalification therefore **confirms** the predecessor's precedence
semantics; it corrects only the FIXTURE contract.

### The 91-versus-99 count contradiction was resolved

The predecessor declared `TOTAL_MIN_ROWS=91` while its own declared
rows sum to **99**.  The cause is mechanical: its `P18` row has 4
tab-separated fields where every other row has 5, so its declared
`min_rows` (8) sits in the `expected_output` position and is not
readable by field position.

```text
SUM_MIN_ROWS_WELLFORMED=91
SUM_MIN_ROWS_ALL_DECLARED=99
MALFORMED_PARTITIONS=1
DISCREPANCY=8
```

The **corrected** count is **98**, not 99: correcting the `TK_SHR`
defect removes one reject row from P15, so P15's `min_rows` falls from
10 to 9.

### The `TK_SHR` defect was confirmed

The predecessor's `P15_REJECTED_NOT_AN_OPERATOR` row listed `0x30B-1`
among the values that MUST return `-1`.  `0x30B - 1` **is** `0x30A`,
which is `TK_SHR`: a recognised operator with precedence 6.

```text
DEFECT value=778 (0x30A) table_precedence=6 partition_expects=-1
```

The defect is a defect of the **predecessor's contract**, not of the
legacy semantics.  The legacy table is correct and was not changed.

### The corrected contract

```text
CORRECTED_FIXTURE_COUNT=98
SUM_MIN_ROWS_WELLFORMED=98
SUM_MIN_ROWS_ALL_DECLARED=98
AUDIT_MALFORMED_PARTITIONS=0
AUDIT_INCONSISTENT_PARTITIONS=0
FIXTURE_MODEL_ROWS=98
```

### The historical two-tool scope violation was recorded

RECON03's scope section authorized "**one** bounded PolyC-native
quality tool"; its C1 commit added **two** (eligibility and ranking),
both in commit `3a0f792`.  Recorded with the commit identity; not
repaired in place.

### The fixture-integrity witness is executable and fires

`tools/quality/parser-slice03-fixture-integrity.HC` counts the executed
rows by a **whole-file byte scan** that shares no code and no decision
with the differential's contextual row-classification state machine.
It **rejects** an unknown or additional row rather than skipping it.

```text
FIXTURE_INTEGRITY_OBSERVED_ROWS=98
FIXTURE_INTEGRITY_DISTINCT_IDS=98
FIXTURE_INTEGRITY_UNKNOWN_IDS=0
FIXTURE_INTEGRITY_UNKNOWN_ROWS=0
STATUS=PASS
```

All four negative controls fire: an unknown id (`X001`), an additional
out-of-range id (`F099`), a dropped row (`F050` removed), and an
**indented** unknown row -- the exact bypass class RECON03 reproduced.

---

## 4. The implementation and the production transfer (C2)

```text
POLYC_SYMBOL  = BootstrapOperatorPrecedence
POLYC_ABI     = I64 BootstrapOperatorPrecedence(I64 punct_value) -> I64 precedence
SUBJECT       = tools/bootstrap/selfhost-parser-operator-precedence.HC
COMPILED_BY   = the stage-0 compiler
```

The subject is a transcription of the **derived** table, not of the
predecessor's prose.  It preserves the `-1` sentinel exactly, adds no
`tk_type` check, and does not distinguish the `TK_STR` /
`TK_SUPERSCRIPT` aliasing.

Checked against the derived table:

```text
TABLE_ROWS=39 MISMATCHES=0
```

### The production delegation

`src/prslib.c:1139..1243` now reads:

```c
static int parseGetPriority(Lexeme *tok) {
#ifdef HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE
    extern long long BootstrapOperatorPrecedence(long long punct_value);
    return (int)BootstrapOperatorPrecedence((long long)tok->i64);
#else
    <the VERBATIM legacy switch>
#endif
}
```

The legacy switch body was verified **byte identical** to the entry
commit's body.  The only additions to `src/prslib.c` are the guard, a
zero-logic adapter and the oracle entry point.

### The strong form of the production-authority evidence

```text
$ nm -u build/CMakeFiles/hcc.dir/prslib.c.o | grep -i bootstrap
_BootstrapOperatorPrecedence

$ nm build/CMakeFiles/hcc.dir/prslib.c.o | grep parseGetPriority
(nothing)
```

`parseGetPriority` is **not** in the production object: the legacy
algorithm body lives in the `#else` branch and is therefore not
compiled into the production binary.

The build wiring is **fail-closed**: a missing object, an
undefined-only symbol, a local symbol, a weak symbol and a duplicate
definition are all hard build errors.

```text
OPERATOR_PRECEDENCE_OBJECT_STATUS=PASS
EXPECTED_SYMBOL=BootstrapOperatorPrecedence
DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=1
```

### The real legacy-C oracle

The oracle object is `src/prslib.c` compiled **without** the
delegation macro, so the **real** legacy `parseGetPriority` body is the
one that executes.  The Makefile rule *asserts* that the object
carries no `_BootstrapOperatorPrecedence` symbol and fails the build if
it ever does.

```text
SLICE03_DIFF_TOTAL=98
SLICE03_DIFF_PASS=98
SLICE03_DIFF_FAIL=0
SLICE03_DIFF_ORACLE_VS_EXPECTED_MISMATCH=0
STATUS=PASS
```

The differential's negative control alters one fixture expectation and
the disagreement is **reported** (`STATUS=FAIL`, exit 1).

---

## 5. The qualification (C3)

### The four generations

Four **distinct builds**, each produced by a different compiler:

```text
gen  class              component_sha256  compiler_sha256
G0   LEGACY_REFERENCE   937a29dc...       (the legacy C reference)
G1   POLYC_STAGE1       1a932394...       833f0797...
G2   POLYC_STAGE2       1a932394...       051bf6b8...
G3   POLYC_STAGE3       1a932394...       0ebf9a11...

G1_G2_COMPILER_DISTINCT=YES
G1_G3_COMPILER_DISTINCT=YES
G2_G3_COMPILER_DISTINCT=YES
```

G0 is an **intentional legacy reference**: it is built from C, so
byte-identity with the PolyC generations is not expected.  The
permitted G0-versus-PolyC contract is **semantic**, and it is
exercised:

```text
G0_G1_SEMANTIC_COMPARISON_POINTS=457
G0_G1_SEMANTIC_MISMATCHES=0
```

### The six component-object pairs

```text
G0_G1  SEMANTIC       EQUIVALENT
G0_G2  SEMANTIC       EQUIVALENT
G0_G3  SEMANTIC       EQUIVALENT
G1_G2  BYTE_IDENTITY  IDENTICAL
G1_G3  BYTE_IDENTITY  IDENTICAL
G2_G3  BYTE_IDENTITY  IDENTICAL
```

### The six production semantic pairs

Four distinct production binaries, each linked with its own
generation's component object, compiled and ran the same
mixed-precedence observation program:

```text
SLICE03_PRODUCTION_SEMANTIC_PAIRS=6/6 EQUIVALENT
```

### The copy-forgery control

The control **measured** a weakness in the obvious provenance model:
G1, G2 and G3 are byte-identical by construction, so an
object-SHA-only check *accepts* a substitution of one of them for
another.  A generation's provenance is therefore the **pair** (object
SHA, producing compiler SHA).  All three substitutions are rejected:

```text
CASE-1  an object built by another generation's compiler  REJECTED
CASE-2  the legacy C object substituted for a PolyC one   REJECTED
CASE-3  a mutated object with the recorded size           REJECTED
```

### The production-causal mutation

```text
pristine  -> 62   sha256 606b7d08...
mutated   -> 162  sha256 fe8a828c...
restored  -> 62   sha256 606b7d08...   (identical to pristine)
```

The mutation is a **single line** (`'*'` moves from precedence 4 to 6),
it **builds and links**, and the tracked source was never mutated.  A
failed build is not semantic divergence; this one is not a failed
build.

### The conservation result

The baseline is a compiler built from the **entry tree** (50cabc1), not
the previous ACT's report, and the identical suite was run against
both:

```text
BASELINE_PASSED=87  BASELINE_FAILED=3
CURRENT_PASSED=87   CURRENT_FAILED=3
```

The failure identity sets are **byte identical**.  The three failures
are the pre-existing `/usr/local/include/tos.HH` host issue.

```text
NEW_PARSER_FAILURE_IDENTITIES=0
NEW_PARSER_SEMANTIC_REGRESSIONS=0
NEW_LEXER_FAILURES=0
NEW_LEXER07_FAILURE_IDENTITIES=0
```

The LEXER07 broad corpus reproduces every counter exactly
(`PASS_S0=166`, `PASS_S1..S3=175`, `REGRESSION=0`, `DIVERGED=0`).  Its
overall `STATUS=FAIL` is preserved as measured: it is a pre-existing
condition of the corpus.

### The gates

```text
GATE_FAST    = PASS
GATE_PUSH    = PASS   (fresh, hermetic, clean tree; CHECK=aot PASS)
FACTORY_V2   = PASS (53/0)
APPEND_ONLY  = PASS (11/0)
F14          = PASS
PATCH_HYGIENE= PASS
F_NO_PYTHON  = PRE-EXISTING (12 tracked Python sources; 0 new)
F_POLYC_TOOLS= PRE-EXISTING (5 shell scripts over budget; 0 new)
```

---

## 6. Residue

| Priority | Item | Disposition |
| --- | --- | --- |
| P1 | The test harness `src/tests/run.HC` compiles each test without `--install-dir`, so on a host with no `/usr/local/include` the tests fail to compile.  Three parser tests fail for that reason. | **Pre-existing**, and now measured against a baseline compiler built from the entry tree: the failure identity sets are byte identical.  Carried forward; NOT repaired by this ACT, because the repair is out of scope and the current tree passes `gate-push` without it. |
| P1 | The F-NO-PYTHON checker reports 12 tracked Python sources. | Pre-existing baseline violation; 0 new.  Recorded, not waived, not fixed. |
| P1 | The shell-LOC ratchet reports 5 over-budget scripts. | Pre-existing baseline violation; 0 new.  This ACT added no shell script at all: every new tool is PolyC, plus one 18-line C stub. |
| P2 | `tools/factory/factory-polyc-tools-check.HC` (the authoritative F-POLYC-TOOLS checker) is NOT YET LANDED. | The C2.9 residue recorded by AGENTS.md.  The nearest live enforcement (the shell-LOC ratchet) reports 0 new violations for this ACT. |
| P2 | The nine remaining eligible candidates (`CAND-018`, `CAND-019`, `CAND-020`, `CAND-021`, `CAND-022`, `CAND-023`, `CAND-025`, `CAND-026`, `CAND-030`) remain unmigrated. | Carry forward.  `CAND-019` / `CAND-020` are the natural companion migrations to the precedence table. |
| P2 | The fixture-contract requalification tool carries three toolchain-specific workarounds that are worth a separate bounded correction: a global with an explicit initializer makes the PolyC compiler auto-generate a `main`; a PolyC string literal is not reliably NUL-terminated for a byte-scan; and `?:` and user-defined variadic functions are not supported. | Recorded here rather than fixed in place, because each is a **toolchain** property and not a property of this ACT's contract.  A bounded correction ACT may address them. |

---

## 7. Verdict

VERDICT

---

PASS

### The result

```text
ACT=ACT-POLYC-SELFHOST-PARSER-SLICE03
VERDICT=PASS

RECON03_HISTORICAL_VERDICT=HALT_ACKNOWLEDGED
CONTRACT_REQUALIFICATION=PASS

OPERATOR_PRECEDENCE_AUTHORITY=POLYC
LEGACY_PRECEDENCE_AUTHORITY=RETIRED

REAL_C_ORACLE_DIFFERENTIAL=PASS
FIXTURE_INTEGRITY=PASS
G0_G1_G2_G3=QUALIFIED
PRODUCTION_CAUSAL_PROOF=PASS
NEW_SEMANTIC_REGRESSIONS=0

CORRECTED_FIXTURE_COUNT=98
MANDATORY_AC_ROWS=62
MANDATORY_AC_PASS=62
MANDATORY_AC_FAIL=0

GATE_FAST=PASS
GATE_PUSH=PASS
FACTORY_V2=PASS (53/0)
APPEND_ONLY=PASS (11/0)
F14=PASS
PATCH_HYGIENE=PASS

OPERATOR_PRECEDENCE_SEMANTIC_DELTA=0
PRODUCTION_SEMANTIC_DELTA=0
```

The AC ledger is in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c3/mandatory-ac-status.tsv`:
62 rows, 62 PASS, 0 FAIL, 0 DEFERRED, 0 UNPROVEN.

### The next milestone

The remaining parser authority is now:

```text
PARSER_PADDING_AUTHORITY            = POLYC
PARSER_CONTROL_FLOW_TOKEN_AUTHORITY  = POLYC
PARSER_OPERATOR_PRECEDENCE_AUTHORITY = POLYC
```

The nine remaining eligible candidates stay available as later
targets; `CAND-019` / `CAND-020` are the natural companions.
