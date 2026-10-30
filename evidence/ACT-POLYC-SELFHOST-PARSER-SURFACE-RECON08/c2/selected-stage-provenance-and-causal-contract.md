# The Selected Successor Contract — Stage Provenance and Causal Contract

**ACT:** ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON08
**Selected candidate:** `SUB-004`

---

## 1. The FOUR-GENERATION plan — a plan, not a claim

RECON08 executed **G0 and the pre-migration C mutant**. It did NOT
execute G1, G2 or G3, because the successor component does not exist
yet: this ACT selects a candidate and freezes its contract; it does
not implement it.

| Generation | What it is | Executed by RECON08? |
|---|---|---|
| **G0** | the genuine C oracle: the real production `src/parser.c` compiled with the candidate selector **OFF** | **NO** — RECON08 produced the *pre-migration* C mutant instead, which is a different experiment (see §2) |
| **G1** | the first PolyC-built compiler generation, with the selector ON | **NO** — SLICE09 |
| **G2** | a second, independently built PolyC generation | **NO** — SLICE09 |
| **G3** | a third, independently built PolyC generation | **NO** — SLICE09 |

**No claim is made that G1, G2 or G3 exist.** The three future
generations must be produced by three **distinct** compiler binary
provenance identities — three separately built compilers with three
distinct producer digests. A single compiler re-run is not three
generations.

SLICE09 must compare **all twelve ordered pairs** of the four
generations on the frozen fixture, plus the anti-self-reference and
provenance controls.

---

## 2. The TIME-SCOPED causal controls

These are **three different experiments**. None of them may be
relabelled as another.

### 2.1 `RECON08-SUB-004-PRE-C-MUTANT` — EXECUTED

| Field | Value |
|---|---|
| `CONTROL_ID` | `RECON08-SUB-004-PRE-C-MUTANT` |
| `PHASE` | `RECON08-C2-PRE-MIGRATION-C-MUTANT` |
| `SUBJECT_PATH` | `src/parser.c`, the legacy C decision, lines 1864..1877 |
| `SELECTOR_STATE` | the eight production selectors ON; **no** candidate-specific selector exists |
| `PRODUCER` | the real `hcc`, built in a disposable detached worktree at the entry commit |
| `OBJECT_IDENTITY` | pristine `13db2f18…`, mutant `0eeda678…`, restored `13db2f18…` |
| `EXECUTION_ID` | `RECON08-C2-MUTANT-01` |
| `OUTCOME_CHANNEL` | `W-DIAG` (the diagnostic text) and `W-OBJ` (the object digest) |
| `RESULT` | the pristine compiler says *"while parsing if body"*; the mutant says *"while parsing while loop body"*; the restored compiler says *"while parsing if body"* again |
| `RESTORATION` | source byte-identical to the entry digest; rebuilt compiler and object byte-identical to the pristine ones |
| `SHARING` | may be cited by SLICE09 as the **pre-migration** evidence only |

### 2.2 `RECON08-SUB-004-POST-POLYC-MUTANT` — NOT EXECUTED, MANDATORY FOR SLICE09

| Field | Value |
|---|---|
| `CONTROL_ID` | `RECON08-SUB-004-POST-POLYC-MUTANT` |
| `PHASE` | `RECON08-C2-FUTURE-POST-MIGRATION` — executed in SLICE09 |
| `SUBJECT_PATH` | the **compiled PolyC** component, NOT `src/parser.c` |
| `SELECTOR_STATE` | `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH` **ON** |
| `PRODUCER` | a PolyC-built compiler generation (G1, G2 or G3) |
| `EXECUTION_ID` | assigned by SLICE09; it MUST differ from every RECON08 execution ID |
| `OUTCOME_CHANNEL` | `W-DIAG` / `W-OBJ` / `W-RUN` |
| `RESTORATION` | the PolyC component's source is restored and the compiler rebuilt |

**The RECON08 pre-migration C mutant CANNOT discharge this control.**
The two experiments have different subjects (legacy C source vs
compiled PolyC component), different selector states, different
producers and different phases. Citing the RECON07/RECON08 pre-C
experiment as if it were a post-PolyC experiment is the exact
confusion this ACT forbids.

### 2.3 `RECON08-SUB-004-C-OFF-C-MUTANT` — NOT EXECUTED, CONDITIONAL

| Field | Value |
|---|---|
| `CONTROL_ID` | `RECON08-SUB-004-C-OFF-C-MUTANT` |
| `STATUS` | **OPTIONAL** — it is demanded only if the frozen successor contract requires a selector-OFF C mutation as well |
| `SUBJECT_PATH` | the legacy C decision, in a build with the candidate selector **OFF** |
| `SELECTOR_STATE` | `HCC_USE_SELFHOST_PARSER_STATEMENT_DISPATCH` **OFF** |
| `NOTE` | if it is not demanded, it is NOT executed and it is NOT claimed |

---

## 3. The four control rows, and their distinctness

| CONTROL_ID | PHASE | SUBJECT | SELECTOR | EXECUTED |
|---|---|---|---|---|
| `RECON08-SUB-004-PRE-C-MUTANT` | `RECON08-C2-PRE-MIGRATION-C-MUTANT` | legacy C source | no candidate selector | **YES** |
| `RECON08-SUB-004-POST-POLYC-MUTANT` | `RECON08-C2-FUTURE-POST-MIGRATION` | compiled PolyC component | candidate selector ON | no — SLICE09 |
| `RECON08-SUB-004-C-OFF-C-MUTANT` | `RECON08-C2-FUTURE-C-OFF` | legacy C source | candidate selector OFF | conditional |
| `RECON08-SUB-004-G0-ORACLE` | `RECON08-C2-PRE-MIGRATION-G0` | the real production TU, selector OFF | candidate selector OFF | no — SLICE09 |

No two of these share a subject, a selector state and a phase. They
are therefore **not** one experiment counted four times, and the C3
join must record their distinctness rather than assume it.

---

## 4. The producer identity requirement

Any producer binary cited anywhere in this programme must be bound by
its **sha256**, and the claim "this is generation G2" must be
dischargeable by comparing that digest with the recorded generation
table. The control `R8-PV-01` supplies a **relabelled** producer and
requires the detector `PRODUCER_DIGEST_OR_IDENTITY_MISMATCH` to
fire.

A producer digest is never a SHA-of-self claim: it is the digest of
the binary file on disk, which is inspectable by anyone.
