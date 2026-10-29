# ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01 — the FROZEN N-06 CONTRACT

**Phase:** C0 (RED, read-only)
**Frozen source:** `evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-negative-controls.md`
**Frozen SHA-256:** `f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325`
**Mutations performed to produce this file:** NONE.

---

## 0. How the frozen text was re-read

The frozen N-06 text was read DIRECTLY from the committed RECON05
artifact, at the entry tree, and its byte hash was re-derived.  It was
NOT copied from a predecessor's summary of it.

```text
COMMAND=shasum -a 256 evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-negative-controls.md
f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325

COMMAND=git log --all --oneline -- evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-negative-controls.md
062a68f ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 C2: the eligibility, the ranking, the executable causality and the frozen successor contract
```

The file has been modified by **exactly one** commit in the whole
repository history, and the measured hash **equals** the hash that
SLICE07 froze in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/selected-contract-hashes.tsv`
and that RECON06 re-verified.  The frozen obligation is therefore
UNCHANGED.

```text
FROZEN_N06_SOURCE=evidence/ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05/c2/selected-negative-controls.md
FROZEN_N06_SHA256=f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325
FROZEN_N06_SHA256_EXPECTED=f468a9e35d3e31fd0b325b7f44ca459443927da61d705dfed75000005680f325
FROZEN_N06_SHA256_MATCHES=YES
FROZEN_N06_MODIFICATION_COUNT=1
FROZEN_N06_LINES=66..76
FROZEN_N06_CONTRACT_UNCHANGED=YES
```

---

## 1. The frozen text, verbatim

Lines 66-76 of the frozen file, transcribed byte-for-byte:

```text
## N-06 — the causal direction is not observed

```text
MUTATION=Mutate ONLY the selected C decision in a disposable
          worktree, rebuild the real compiler, and run the witness.
DETECTOR=CAUSAL_DIRECTION_CHANGE
REASON=The EXECUTED experiment in this ACT observed exactly this
        direction; see c2/selected-causal-contract.md section 3.
```
```

---

## 2. The five binding semantic clauses, as frozen

The frozen obligation decomposes into FIVE independently checkable
clauses.  They are reproduced here so that C1/C2 can discharge each
one separately, and so that a partial discharge is visible.

| # | Frozen clause | Discharged by |
|---|---------------|--------------|
| K1 | the mutated subject is **the selected C decision** | C2.2 (source binding to `src/parser.c`) |
| K2 | the mutation happens in a **disposable worktree** | C2.1 (detached worktree) |
| K3 | the **real compiler** is rebuilt | C2.3 (mutated C-OFF production build) |
| K4 | **the witness** is run | C2.4 (witness/fixture against pristine and mutant) |
| K5 | the detector **CAUSAL_DIRECTION_CHANGE** fires | C2.4 (causal triple) |

---

## 3. The frozen semantics of the selected C decision

The frozen RECON05 `c2/selected-abi.md` section 3.1 states the
decision's exact semantics, and this ACT re-derives the numeric enum
constants from the LIVE `src/ast.h` rather than trusting the
historical observation.

```text
if (stmt_kind == AST_DECL && declvar_kind == AST_GVAR) return 0;  /* SKIP */
return 1;                                                        /* APPEND */
```

The frozen `selected-abi.md` also freezes the SHORT-CIRCUIT: the
`declvar_kind` input is consulted **only** when `stmt_kind` is already
`AST_DECL`.  A mutation that introduces an eager dereference would
violate the frozen ABI, and so would any mutation of the host
projection.  The admissible polarity flip is therefore exactly the
decision's boolean, with the short-circuit left intact.

The frozen `selected-production-seam.md` freezes the seam: ONE
condition, ONE delegation, the C side owning the `continue` (SKIP) and
the `listAppend` (APPEND), and the PolyC component only DECIDING.

The frozen `selected-red-contract.md` RED-05 requires, after the
migration, that *"the C decision is delegated and the behaviour is
unchanged"*.  That is the successor state of the PRODUCTION build.
It does NOT remove the legacy C source: the legacy branch survives
behind the dedicated selector `HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND`,
guarded by `#else`, which is what makes the literal N-06 experiment
reachable in the disposable C-OFF configuration this ACT builds.

---

## 4. What this ACT must NOT do to the frozen text

* It must NOT edit the frozen file.  F14 forbids it, and the
  `predecessor-freeze.tsv` manifest of this ACT would detect the edit.
* It must NOT relabel the historical SLICE07 experiment as a literal
  N-06 experiment.  The historical experiment's subject is the PolyC
  source, and that stays on the record.
* It must NOT delete or overwrite any predecessor data.
* It must NOT claim that the new experiment "ran during SLICE07".

```text
HISTORICAL_ARTIFACT_REWRITES=0
FROZEN_N06_CONTRACT_UNCHANGED=YES
THIS_ACT_PERFORMED_ANY_MUTATION_AT_C0=NO
