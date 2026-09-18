# ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the FALSE_GREEN closure of ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01 by adding fn_is_static to the legacy x86 backend (`src/x86.c`) under `--use-legacy-x86`, adversarially qualifying the legacy path, and recording the closure-oracle self-reference as a documented residue.

**Repository:** PolyC
**Branch:** `main`

**Class:** COMPILER / LANGUAGE SEMANTICS / LINKAGE / CLOSURE-GOVERNANCE CORRECTION

**Predecessor:** ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01 (commit 712a3b7, FALSE_GREEN on closure-governance grounds; PASS_TRUE_GREEN on aarch64/x86_64/JIT engineering grounds)

## 1. Background

The predecessor ACT committed a C4 CLOSE with verdict PASS_TRUE_GREEN. Reviewer review identified two P0 closure defects:

  P0-1: The legacy x86 backend (`src/x86.c`) is selectable via `--use-legacy-x86` and does not consult `fn_is_static`. The predecessor classified this as "outside scope", which is a post-hoc narrowing of an authorization contract that required every live function emitter to participate.

  P0-2: The C4 commit modified the closure-status oracle (added the predecessor's own ACT/HANDOFF pair to the bounded managed universe in `scripts/quality/factory-closure-status-check.sh`), then ran that modified oracle to claim PASS. The thing judging the closure was altered during the closure phase.

  P0-3 (corollary): The authorization artifact (`docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md`) was mutated at C4 (a `## Status` section was appended). Verdict belongs in HANDOFF/evidence, not in the ACT itself.

This CORRECTION01 ACT closes P0-1 with bounded engineering work and records P0-2/P0-3 as documented residue + recommended follow-up.

## 2. Authorized scope

Production code:
  - `src/x86.c` — add `fn_is_static` check in `asmFunctionInit` to suppress `.global` for static functions.

Test infrastructure:
  - `tests/compiler/static-function-linkage/s09-legacy-x86-static.HC` — new fixture.
  - `scripts/quality/static-function-linkage-test.sh` — extend to dispatch s09 and record X86_LEGACY_STATIC_LINKAGE verdict.
  - `docs/ROADMAP.md` — append a closure block.

NOT authorized:
  - Modifying `scripts/quality/factory-closure-status-check.sh` (closure oracle must remain frozen; F14 + the principle that the judging thing should not itself be altered by the judged ACT).
  - Modifying `docs/acts/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md` (immutable authorization artifact; per F14 the historical evidence stands).
  - Modifying `docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01.md` (preserved as historical evidence of the FALSE_GREEN pass).
  - Modifying any other production code (aarch64.c, x86_64.c, jit-common.c, ast.h, ast.c, parser.c all remain unchanged from the predecessor).

## 3. Adversarial qualification

The legacy x86 backend MUST:

  - Emit `_StaticFn` with non-external linkage when `static I64 Foo(...) {...}` is parsed and compiled with `--use-legacy-x86`.
  - Emit `_PublicFn` with external linkage under the same compilation.
  - Allow the same spelling in independent translation units without duplicate-symbol collision.
  - Coexist with public functions of the same spelling.

The verification harness MUST use `nm -m` on the legacy-backend output. It MUST NOT just parse the assembly text.

## 4. RED

RED_LEGACY_X86_GLOBAL_OVERRIDE (this ACT's required RED):

  REPRO (HEAD=712a3b7, pre-fix):
    $ hcc --use-legacy-x86 -c tests/compiler/static-function-linkage/s09-legacy-x86-static.HC
    $ nm -m s09-legacy-x86-static.o
    _StaticFn   external  (NOT_EXPECTED)
    _PublicFn   external

  ROOT CAUSE:
    src/x86.c:asmFunctionInit unconditionally emits
    `.global <fname>` for every AST_FUNC. The fn_is_static
    field on AstFunc (set by parser.c:parseFunctionDef) was
    never consulted in the legacy backend.

## 5. C2 IMPL (one bounded change)

src/x86.c:asmFunctionInit — replace the unconditional
`.global %s\n` with a conditional that consults `func->fn_is_static`:

```c
if (!func->fn_is_static) {
    aoStrCatPrintf(buf, ".global %s\n", fname);
}
```

8 lines (6 comment + 2 substantive) — mirrors the existing
src/aarch64.c and src/x86_64.c patterns.

## 6. C3 EVIDENCE

Required evidence files:

  c1/c1-entry-identity.txt
  c1/c1-legacy-x86-paths.tsv                (path inventory)
  c1/c1-red-summary.txt                     (RED_LEGACY_X86_GLOBAL_OVERRIDE witness)
  c2/c2-entry-identity.txt
  c2/c2-repair-summary.txt
  c3/c3-entry-identity.txt
  c3/c3-s09-legacy-x86-static.txt           (nm -m output for s09)
  c3/c3-s09-legacy-x86-static.S.txt         (assembly-level evidence)
  c3/c3-factory-gates.txt                   (gate outputs)
  c3/c3-mandatory-ac-status.tsv             (AC ledger)
  c3/c3-required-result.txt                 (VERDICT=PASS_TRUE_GREEN)

## 7. C4 CLOSE

HANDOFF (`docs/factory/HANDOFF-ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01-CORRECTION01.md`).
C4 entry identity (`evidence/.../c4/c4-entry-identity.txt`).
ROADMAP closure block.

## 8. Halt classification

If C1 cannot reproduce the legacy x86 RED with `--use-legacy-x86`:
  HALT_BACKEND_STATIC_LINKAGE_GAP_ALREADY_FIXED
  (no fix required; close with PASS_TRUE_GREEN documentation
   that the defect did not reproduce, plus residue explaining
   why the predecessor's classification was wrong but the
   situation is now moot).

If C2 IMPL breaks the legacy x86 backend's other functions:
  HALT_LEGACY_X86_BACKEND_REGRESSION
  (revert; record as residue; the legacy backend is genuinely
   broken w.r.t. linkage, and a separate bounded ACT is needed
   to fix it without regression).

If C3 cannot run the legacy backend on this host:
  HALT_LEGACY_X86_BACKEND_UNAVAILABLE
  (F6 forbids silent fallback to the default backend; the
   defect must be qualified against the legacy backend or
   not at all).

If `factory-closure-status-check.sh` reports FAIL because the
new HANDOFF is not in the bounded managed universe:
  This is expected and acceptable. The CORRECTION01 ACT
  documents the closure-oracle limitation as residue and
  recommends ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01
  as the proper fix. PASS_TRUE_GREEN of THIS ACT is recorded
  by the verbatim gate outputs and the HANDOFF's own
  PASS_TRUE_GREEN token. The closure-status FAIL on the
  extension pair is recorded but does NOT downgrade this ACT's
  verdict because the closure-status oracle's bounded universe
  is the documented defect.

## Status

PASS_ENGINEERING_HALT_GOVERNANCE_DEPENDENCY

Mirrors the HANDOFF's authoritative VERDICT. The HANDOFF remains the
canonical source; this section is structural metadata required by the
closure-status oracle (added by ACT-POLYC-FACTORY-CLOSURE-ORACLE-
EXTENSIBLE01 to register this ACT/HANDOFF pair in the manifest). No
semantic change to the historical verdict.
