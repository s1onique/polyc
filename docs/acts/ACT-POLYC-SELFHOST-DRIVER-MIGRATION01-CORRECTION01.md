# `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01`

**Title:** Correct the C1-frozen M3 mutation target of
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` to the status-propagation
construct that is actually on the causal path, and record the C2
production change that makes the action dispatch load-bearing.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / CONTRACT-CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01`

**Factory-Version:** 2

**Production semantic changes:** AUTHORIZED, and SCOPED to the two
files named in section 2. The correction is NOT a new feature: it
makes an ALREADY-AUTHORIZED site load-bearing, which the parent
ACT's C2 section REQUIRES ("The three site types -- arg
interpretation, action dispatch, status mapping -- must be
load-bearing") and which the parent ACT's C3 section 5.2 VERIFIES by
mutation.

**Re-mutation of the predecessor's evidence directories:**
**FORBIDDEN** (F14). The parent ACT's committed C1 evidence directory
is NOT edited by this ACT. This correction's own evidence lives only
in `evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01/**`.

---

## 0. Mission

This ACT corrects ONE row of the parent ACT's committed C1 contract
and records ONE production change that the parent ACT already
required but that the parent's C2 implementation had left
incomplete.

The single mechanical claim this ACT must establish:

```text
parent_C1_M3_contract_construct = NOT_ON_THE_CAUSAL_PATH
corrected_M3_construct          = ON_THE_CAUSAL_PATH
M1_M2_M3_distinctly_observable = YES
parent_C2_action_dispatch_load_bearing = NO
corrected_C2_action_dispatch_load_bearing = YES
```

and only that.

---

## 1. Why this ACT exists

The parent ACT's C1 phase committed
`evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c1/decision-authority-and-mutation-contract.tsv`,
whose Part 2 freezes three distinct PolyC mutation targets. The M3
row names this source construct as the status-propagation target:

```text
the status mapping `if (action == WP_ACTION_NONE) { if
(WpDriverUnknownArgCount() > 0) return WP_STATUS_USAGE; return
WP_STATUS_NO_INPUT; }`
```

The M3 row's stated MUTATION INTENT is correct: "force the NO_INPUT
status for an argv that holds an UNKNOWN argument". The row's named
CONSTRUCT is not.

The reason is a source fact. In the parent's C2 implementation, the
unknown-argument failure is produced by the check that runs BEFORE
the action mapping:

```text
if (WpDriverHasUnknownArgument() == 1) return WP_STATUS_USAGE;
```

so the `WP_ACTION_NONE` branch is never reached for an argv that
holds an unknown argument. Mutating the construct named by the C1
row therefore produced NO observable change over the frozen
fourteen-case corpus. That is a DECORATIVE mutation target, and the
parent ACT forbids a decorative site: "A PolyC driver that merely
returns a fixed exit status cannot PASS."

This was DISCOVERED BY EXECUTION at the parent's C3 phase, not
inferred. The mutation was applied to a copy of the driver source,
the driver subject was recompiled by the real production compiler, a
fresh production compiler was linked against the mutated subject,
the frozen corpus was re-executed, and the corpus was unchanged.

The parent ACT's C1 evidence is COMMITTED and must not be rewritten
(F14). The correction therefore lives here.

The SAME execution finding showed a SECOND defect. The M2 mutation
target -- the action mapping for the emit-object options -- was also
not observable, because the parent's C2 implementation mapped those
options to the emit-object CliArgs field DIRECTLY, without going
through the action. The action was computed but never consulted, so
site (b) was decorative as well. The parent ACT explicitly requires
the three sites to be load-bearing, so this is an INCOMPLETE
IMPLEMENTATION of the parent ACT, not a new feature.

---

## 2. Scope

### allowed

- `tools/bootstrap/selfhost-driver-wp001.HC` -- the PolyC driver
  subject. The emit-object field is DERIVED FROM THE ACTION, so that
  the action dispatch is on the causal path.
- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01.md`
  -- this document.
- `evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01/**`
  -- this ACT's evidence.

### forbidden

- Any modification of the parent ACT's committed evidence directories.
- Any modification of `src/cli.c`, `src/cli.h`, `src/main.c`,
  `src/CMakeLists.txt` or the Makefile. The parent ACT's production
  wiring is NOT touched by this correction.
- Any modification of any other compiler subsystem.
- Any change to the parent ACT's frozen comparator, the frozen
  corpus, the frozen G0 oracle, or the frozen ABI.

---

## 3. The correction

### 3.1 The corrected M3 target

The corrected status-propagation construct is:

```text
if (WpDriverHasUnknownArgument() == 1) return WP_STATUS_USAGE;
```

in `WpDriverMapStatus`. Mutating it to return `WP_STATUS_NO_INPUT`
replaces the unknown-option failure with the no-input failure, so the
message changes from "Unknown commandline options: ..." to "no input
files" while the exit status stays 1. This is the SAME mutation
INTENT the parent ACT's C1 row stated, applied to the construct that
is actually on the causal path.

The corrected M3 row is recorded in this ACT's evidence at
`c1/corrected-mutation-contract.tsv`. It is a CORRECTION OF THE
PARENT'S C1 ROW, not a replacement of it: the parent's row remains
the historical record of what was frozen at C1, and this ACT
records the correction and its measured justification.

### 3.2 The C2 production change

`WpDriverOptionField` no longer names the emit-object field
directly for the compile-object options. It DERIVES the field from
the action:

```text
if (optIdx ==  6) return WpDriverFieldForAction(WpDriverOptionAction(optIdx));
if (optIdx ==  7) return WpDriverFieldForAction(WpDriverOptionAction(optIdx));
```

with

```text
I64 WpDriverFieldForAction(I64 action) {
  if (action == WP_ACTION_COMPILE_OBJECT) return WP_FIELD_EMIT_OBJECT;
  return WP_FIELD_NONE;
}
```

This is a CAUSAL indirection, not a refactor: the field is what the
retained C compilation engine reads, so a mutation of the action
mapping now changes the field, and therefore the engine's behaviour.

The change is confined to the driver subject. The C side is NOT
touched: it still contains no option table, no option name, no arity
rule and no action choice.

---

## 4. Exit gate

This ACT closes when, MEASURED BY EXECUTION:

1. the three mutations M1, M2 and M3 are each applied to a COPY of
   the driver source, each is confined to its own decision region,
   each changes the driver subject's digest, each is linked into a
   FRESH production compiler, and each produces a DISTINCT observable
   change over the frozen fourteen-case corpus;
2. the three observable changes are distinguishable from each other;
3. the parent's frozen corpus differential against the G0 oracle
   remains GREEN under the one predeclared normalization;
4. the parent ACT's conservation baseline remains CONSERVED.

The parent's C3 phase then continues with the CORRECTED contract.

---

## 5. Non-goals

This ACT does NOT:

- re-run the parent's C0, C1 or C2 phases;
- change the parent's frozen corpus, comparator, G0 oracle or ABI;
- claim that the parent ACT's C1 evidence was wrong in its INTENT --
  it was wrong only in the source construct it named for M3, and the
  correction is recorded with its measured justification;
- discharge AC50, which remains deferred until after the parent's
  CLOSE.
