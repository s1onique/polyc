ACT-POLYC-AOT-PIC-EXTERNAL-REFS01

VERDICT=PASS  (with P1 gep01 cap-verifier residue; documented)

IDENTITY
ENTRY_HEAD=718b3d7 (C1 RED ACT-POLYC-AOT-PIC-EXTERNAL-REFS01)
FINAL_HEAD=b31edca (evidence: drop empty nc2-missing-external.txt placeholder)
            production-tree HEAD = 9f1bb63 (after the F9 evidence refresh)
WORKTREE_STATUS=clean

RED
  (see c1/ — ACT C1 commit 718b3d7)
  - ext-provider.c          : C source defining `_PolycExtAdd1`.
  - ext-consumer.HC         : HolyC source declaring
                              `public _extern _PolycExtAdd1 ...`
                              and consuming it.
  - local-control.HC        : same-image control.
  - red-link.txt            : reproduces
                              `ld: invalid use of ADRP in '_main'
                               to '_PolycExtAdd1'`.
  - red-relocations.txt     : pre-C2 ARM64_RELOC_PAGE21 /
                              ARM64_RELOC_PAGEOFF12 records for
                              `_PolycExtAdd1`.
  - seam-map.txt            : F2 evidence — the seam is
                              aarch64GlobalAddr() in src/aarch64.c.

IMPLEMENTATION
  src/aarch64.c (single-file production change)
  +136 / -28 cumulative from C2 (83474d6) and C2.1 (2c8a456).

  C2 (83474d6) first cut:
    - aarch64ExternalFuncAddr() helper
      Apple-Darwin path emits
        adrp Xd, _sym@GOTPAGE
        ldr  Xd, [Xd, _sym@GOTPAGEOFF]
      Non-Apple falls back to aarch64GlobalAddr (unchanged).
    - IR_LEA arm classifies via cc->global_env +
      IR_VAL_FLAG_FUNC + AST_EXTERN_FUNC -> GOTPAGE path.

  C2.1 (2c8a456) extension:
    - aarch64ExternalFuncAddr renamed to
      aarch64ExternalSymbolAddr (now applies to data globals too).
    - aarch64IsExternalGlobalSymbol(cc, AoStr *name) classifier
      inspects AST kind in cc->global_env, cc->asm_funcs,
      cc->asm_functions; with slow-path iteration of cc->asm_funcs
      to bridge asm-fname `_FREE` -> C-name `Free` AST_ASM_FUNC_BIND.
    - Routes IR_LEA, IR_LOAD_DEREF, IR_STORE_DEREF through the
      classifier. IR_CALL (`bl _sym` / BRANCH26) is unchanged —
      F2: already Mach-O-valid for both local and dylib targets.

GATES
BUILD=PASS
TARGETED=PASS  (grepable relocations match expected @GOTPAGE for
                both AST_ASM_FUNC_BIND function and AST_GVAR
                AST_FLAG_EXTERN data shape)
UNIT=PASS  (make unit-test, 90/90, c3/unit-test.txt)
JIT=PASS   (make jit-unit-test, 90/90, c3/jit-unit-test.txt)
LSP=PASS   (make lsp-test, 43/43, c3/lsp-test.txt)
DIFF_CHECK=PASS  (make gate-fast, c3/gate-fast.txt)

  Not in active conservation graph for this ACT but noted for
  traceability:
  gate-push.sh HEAD             FAIL on gep01 (pre-existing cap-
                                verifier infrastructure gap; identical
                                to predecessor ACT evidence)
  llvm-gep01-test               FAIL  GEP01_PASS=26 GEP01_FAIL=4

SCOPE
FILES_CHANGED=1  (src/aarch64.c)
                + the bounded evidence packet under
                evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/**
                + ROADMAP.md status section
DIFF_CHECK=PASS  (gate-fast runs shell-syntax / diff-check)
PRODUCTION_SEMANTICS_CHANGED=YES  (AArch64 AOT external-reference
                                   materialisation now uses GOT-loaded
                                   ARM64_RELOC_GOT_LOAD_PAGE21 /
                                   ARM64_RELOC_GOT_LOAD_PAGEOFF12
                                   for extern-declared symbols on
                                   Apple Darwin)
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO  (no symbol rename; no install-dance change;
                        no archive/dylib consumer toggle)

RESIDUE
P0=none  (no P0 blocks this ACT's closure)
P1=llvm-gep01-test cap-verifier (scripts/quality/
   llvm-cap-table-verifier.py). Pre-existing gap; identical
   GEP01_PASS=26 GEP01_FAIL=4 was already captured in
   evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/
   c3/gate-push-correction01.log. Out of scope for this ACT
   (the cap-verifier is not touched by src/aarch64.c). Blocks
   gate-push only.
P2=NC1 byte-exact pre/post diff deferred.
   Linux PIC path intentionally untouched (ACT §6).
   x86_64 shared abstraction not introduced (F2: not needed;
                                              F8: no speculative
                                              abstraction).

NEXT_ACT=Either (a) a small bounded infrastructure ACT to fix the
       cap-verifier, then push b31edca to origin/main and open
       ACT-POLYC-BOOTSTRAP01; or (b) a CORRECTIONnn amendment to
       ACT-POLYC-BOOTSTRAP01's scope, re-authorising it to open
       against gate-push minus gep01. See
       evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c4/roadmap-
       transition.txt for the full recommendation.
