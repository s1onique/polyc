# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the false-green closure of
`ACT-POLYC-SELFHOST-SURFACE01` (B1 shell-loc-gate failure on
the predecessor's own added file; B1+B3 Make recipe injection
via COMPONENT/STAGE). Optionally: establish the permanent
Factory invariants `F-NO-PYTHON` and `F-POLYC-TOOLS`, migrate
the self-host control plane and every remaining Python tool to
PolyC, harden the Make argument boundary, and re-prove S0/B3.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** CORRECTION / SELF-HOST / FACTORY-INVARIANT /
CLOSURE-CORRECTION

**Supersedes:** none directly; **corrects the verdict of**
`ACT-POLYC-SELFHOST-SURFACE01` (CLOSED PASS at
`defee14f1365a19a83e396a6814e15879d134503`).

**Predecessor historical result:**

```text
SELF_HOST_COMPONENT_MODEL = PASS
CLOSURE                    = FALSE_GREEN (per C1 evidence)
```

**Predecessor mechanical defects (C1-verified):**

* F1 (PRODUCTION, BLOCKS_NEXT=YES): predecessor C2 IMPL
  added `scripts/quality/selfhost-component-registry-test.sh`
  (197 LOC) without updating `shell-loc-gate` baseline.
* F2 (SAFETY, BLOCKS_NEXT=YES): predecessor C2 IMPL
  introduced Makefile recipes that interpolate
  `COMPONENT=$(COMPONENT)` and `STAGE=$(STAGE)` into
  recipe command text, allowing argument injection.
  Reproduced with sentinels.

See `evidence/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01/c1/`
for full mechanical evidence.

**Production compiler semantic changes:** NONE
**New compiler subsystem migration:** NONE
**Parser/AST/IR/backend changes:** NONE
**Language changes:** NONE
**LLVM authorization:** NONE
**Frozen compiler semantics:** `src/lexer.c`,
`src/lexer_bridge.h`, `tools/bootstrap/bootstrap02-ident.HC`,
all parser/AST/IR/runtime semantics (per C-1 boundary).

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

---

## Mission

Repair the false-green closure of `ACT-POLYC-SELFHOST-SURFACE01`
so that the S0 component framework ACT can be honestly
recorded as PASS, with the corrected-verdict metadata
declared by Factory v2 doctrine:

```text
ACT-Corrected-Verdict: HALT_SHELL_BUDGET_NOT_SATISFIED
HALT_CLASS:            PRODUCTION
BLOCKS_NEXT:           YES
```

The correction MUST also remove the B1+B3 Make recipe
injection vulnerability before any subsequent ACT
(`ACT-POLYC-SELFHOST-LEXER01`) opens.

---

## Explicit user scope expansion

The user's prompt authorized broader scope than the
narrow false-green correction:

1. **Ban Python from the repository** (`F-NO-PYTHON`).
2. **Require all future tool implementations to be PolyC**
   (`F-POLYC-TOOLS`).
3. **Migrate the self-host control plane and every remaining
   Python tool** to PolyC.
4. **Re-prove S0/B3** in the new world.
5. **Unlock `ACT-POLYC-SELFHOST-LEXER01`**.

The C1 evidence packet at
`evidence/ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01/c1/scope-decomposition-note.txt`
records three execution options (A, B, C) and recommends
Option B (narrow correction + separate bounded ACTs for
doctrine and migration). The user retains the right to
choose any option.

---

## Scope (subject to user authorization)

### Authorized in this ACT regardless of option choice

* Repair of F1 (B1 shell-loc-gate): either move the file
  into compliance (≤50 LOC + record in baseline) or
  migrate to PolyC.
* Repair of F2 (B1+B3 Make injection): remove unsanitised
  `COMPONENT=$(COMPONENT)` / `STAGE=$(STAGE)` interpolation
  from Makefile recipe command text.
* Update `shell-loc-gate` baseline.txt to reflect any
  net file additions/removals in this ACT.
* Update `evidence/ACT-POLYC-SELFHOST-SURFACE01/HANDOFF.md`
  post-CLOSE blank-line evidence mutation as
  `CLASS = GOVERNANCE / HISTORICAL_EVIDENCE_MUTATION`
  per Factory v2 doctrine §25.
* CLOSE this ACT exactly once with the
  `ACT-Corrected-Verdict` trailer.

### Authorized ONLY under Option A or Option C

* `F-NO-PYTHON` and `F-POLYC-TOOLS` doctrine additions
  to `docs/factory/DOCTRINE.md` and pointer in `AGENTS.md`.
* PolyC authoritative checker
  (`tools/factory/factory-polyc-tools-check.HC` or
  equivalent) wired into `gate-fast`.
* `docs/factory/LEGACY-NON-POLYC-TOOLS.tsv` baseline.

### Authorized ONLY under Option C

* Migration of every tracked Python tool to PolyC, with
  rewired callers and verified conservation of all
  S0/B3 evidence (175/175 corpus, 4/4 error, 6/6 cursor,
  15/15 component, 6/6 lexer-seam, 3/3 generic/historical).
* Removal of all tracked Python files.
* Full B3 re-proof on a fresh tree.

### NEVER authorized in this ACT (any option)

* Any change to `src/lexer.c`, `src/lexer_bridge.h`,
  `tools/bootstrap/bootstrap02-ident.HC`.
* Any change to parser, AST, IR, or backend semantics.
* Any new bootstrap stage.
* Any new compiler component migration beyond what
  the predecessor already preserves.
* Any retroactive re-validation of historical
  `ACT-Verdict` trailers (per Factory v2 doctrine
  §25 activation boundary).
  boundary).

---

## C1 HALTs declared by the proposed ACT

The proposed ACT §13 names three C1 HALTs:

* `HALT_PYTHON_INVENTORY_UNBOUNDED` — NOT FIRED
  (inventory complete, 9 rows).
* `HALT_POLYC_TOOLING_CAPABILITY_GAP` — NOT FIRED
  (capability gap bounded; PolyC primitives sufficient
  per `TOOLING-RUNTIME01` history).
* `HALT_SELFHOST_BASELINE_NOT_REPRODUCIBLE` — NOT FIRED
  (predecessor registry + tests reproduce identically).

C1 evidence records no C1 HALT. The C2 entry gate is
OPEN subject to user authorization of the decomposition
decision.

---

## Execution topology

Use:

```text
C1 RED       (this commit, no production mutation)
C2 IMPL      (one or more bounded commits, per option)
C3 EVIDENCE  (one commit, fresh-tree re-proof)
C4 CLOSE     (exactly one commit, with corrected-verdict trailers)
```

Multiple bounded C2 IMPL commits are acceptable under
Option C (one per Python tool migration, matching the
`MIGRATE-GEP01` precedent). Under Option B, C2 IMPL is
narrowly bounded to C-1 + Make injection hardening.

---

## Hard stop after CLOSE

Per the proposed ACT §66:

After CLOSE, **STOP**. Do not migrate the second compiler
component. Do not alter `src/lexer.c`. Do not introduce a
generalized semantic component selector. Do not open the
parser. The next ACT is `ACT-POLYC-SELFHOST-LEXER01`, and
its C1 job is to mechanically rank the next production-
lexer slice.

---

## Identity

Execution identity is stored in Git commit trailers.
No SHA-of-self claims in any committed artifact
(DOCTRINE.md §22 / F-GIT-IDENTITY).

```text
ACT: ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
ACT-Supersedes: ACT-POLYC-SELFHOST-SURFACE01  (correction relation only)
ACT-Corrected-Verdict: HALT_SHELL_BUDGET_NOT_SATISFIED  (on CLOSE only)
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS mutation. The CLOSE
commit's `ACT-Verdict` trailer is the authoritative
verdict. The correction relation is recorded in the
trailers, not by mutating the predecessor ACT doc.

---

## Residue (predeclared)

```text
P0 : NONE (defects mechanically demonstrated at C1)

P1 (carry forward from C1 findings):
   - F3 gate-fast does not invoke shell-loc-gate
     (carry-forward from SHELL-INVENTORY01, governance,
     BLOCKS_NEXT=NO)
   - llvm-gep01-test.HC subprocess-calls a Python
     verifier (CAP-TABLE-VERIFIER); if Option C is
     chosen and F-NO-PYTHON is enforced, this is
     PRODUCTION BLOCKS_NEXT=YES until the .HC migrates
     or the verifier is re-implemented in PolyC.

P2 (deferred, scope of future bounded ACTs):
   - Migration of the 9 tracked Python tools to PolyC
     (one bounded ACT per tool, per MIGRATE-GEP01
     precedent; Option B/A only)
   - Full F-NO-PYTHON / F-POLYC-TOOLS doctrine
     enforcement across CI (Option B only)
   - Comprehensive Makefile audit for unsanitised
     $(VAR) interpolations inherited from prior ACTs
     (out of scope for this ACT)
   - The unit/jit runner (AOT codegen adrp/add vs
     dylib nreloc=0 collision) carried forward from
     BOOTSTRAP0[1-4]
   - GEP01 push cap-verifier 26/4 residue carried
     forward from MIGRATE-GEP01
   - Historical whitespace / blank-at-EOF hygiene
     residue carried forward
```
