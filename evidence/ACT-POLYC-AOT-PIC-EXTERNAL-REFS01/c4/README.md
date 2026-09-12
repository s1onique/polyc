# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01 — C4 closure

## VERDICT
PASS (with one pre-existing infrastructure residue: gep01 cap-verifier
failures are out of scope for this ACT; see residue.txt).

## IDENTITY
  branch = main
  entry commit = 718b3d7  C1 RED ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
  final commit = 377175c  evidence: refresh c3/unit-test.txt
  C2 IMPL      = 83474d6  first-cut (IR_LEA + AST_EXTERN_FUNC only)
  C2.1 IMPL    = 2c8a456  classifier + asm-fname bridge + data
                          globals + IR_LOAD_DEREF / IR_STORE_DEREF
  C3+C4 commit = 2b1786c  evidence packet + closure pack
  ROADMAP commit = 9c90c15 ROADMAP status section
  Evidence refresh = 377175c (re-ran unit-test against final tree,
                              per F9 fresh-tree evidence)
  predecessor    = ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-
                    CORRECTION01  (CLOSED with HALT_AOT_PIC_
                    EXTERNAL_REFS_REQUIRED)

## ROOT CAUSE / FINDING

  PolyC's AArch64 Mach-O AOT backend emitted `adrp/add` page-relative
  materialisation for every global symbol reference, including
  references to symbols whose storage lives in a dylib. The dylib's
  __text / __DATA segments carry nreloc=0 in their dynamic-table
  metadata, so the linker cannot satisfy ordinary `ARM64_RELOC_PAGE21 /
  ARM64_RELOC_PAGEOFF12` relocations against dylib-defined symbols
  and rejects the object with:

      ld: invalid use of ADRP in '<caller>' to '_<sym>'

  This is a Mach-O correctness defect, not a workaround. The
  Mach-O-valid materialisation for an external-symbol reference is
  the GOT-loaded form:

      adrp Xd, _<sym>@GOTPAGE        # ARM64_RELOC_GOT_LOAD_PAGE21
      ldr  Xd, [Xd, _<sym>@GOTPAGEOFF]  # ARM64_RELOC_GOT_LOAD_PAGEOFF12

  which the dynamic loader satisfies at runtime via the GOT slot
  for `<sym>`.

  The defect surfaced in three IR opcodes that emit a global-symbol
  materialisation:

    IR_LEA       : function-pointer materialisation (e.g. `&Free`
                   passed as a callback to PtrVecRelease).
    IR_LOAD_DEREF: data global read   (e.g. `*Fs`).
    IR_STORE_DEREF: data global write (e.g. `Fs = x`).

  C2 IMPL (83474d6) fixed the IR_LEA case for the
  AST_EXTERN_FUNC / `extern "c"` shape used by the minimal RED
  fixture. C2.1 IMPL (2c8a456) extends it to cover:

    AST_ASM_FUNC_BIND  (`public _extern _FREE U0 Free(...)`)
        — the asm-bound-extern pattern used by every HolyC stdlib
          binding in tos.HH (MAlloc, Free, MSize, MemSet, ...).
        — requires a slow-path iteration of cc->asm_funcs because
          the IR builder stores the asm-fname in the IR_VAL_GLOBAL
          while cc->asm_funcs is keyed by the C-name.

    AST_GVAR with AST_FLAG_EXTERN
        (`extern HCFs *Fs;`)
        — data globals whose storage lives in libtos.dylib's
          __DATA segment, which has the same nreloc=0 constraint
          as __text.

  IR_CALL (`bl _sym`) was correctly emitting BRANCH26 already; the
  ACT does not modify it (F2: BRANCH26 is Mach-O-valid for both
  local and dylib targets).

## RED
  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c1/ (see ACT C1 commit
  718b3d7 and the ACT C1 closure pack).
    ext-provider.c          — C source defining `_PolycExtAdd1`
    ext-consumer.HC         — HolyC source declaring
                              `public _extern _PolycExtAdd1 ...`
                              and consuming it.
    local-control.HC        — same-image control.
    README.md               — fixture narrative.

  RED result: `make unit-test` link step fails with
    `ld: invalid use of ADRP in '_main' to '_PolycExtAdd1'`
  on a clean tree, demonstrating the production defect.

## IMPLEMENTATION
  single-file production change (F2-bounded to src/aarch64.c):

    commit 2c8a4560179398bc4a7b2aee005454df50fed1b4
    "C2.1 IMPL ACT-POLYC-AOT-PIC-EXTERNAL-REFS01"

  1. New classifier:
       aarch64IsExternalGlobalSymbol(Cctrl *cc, AoStr *name)
     inspects the AST kind registered in:
       cc->global_env   (`extern Type name;`, `extern "c" ...`)
       cc->asm_funcs    (`public _extern _ASM_NAME ... CName(...)`)
       cc->asm_functions (asm-block definitions; not exercised here)
     with a slow-path fallback that iterates cc->asm_funcs and
     matches ast->asmfname to bridge `_FREE` -> `Free`.

  2. Renamed helper:
       aarch64ExternalFuncAddr  ->  aarch64ExternalSymbolAddr
     now applies to both function and data external references.
     Apple Darwin path emits @GOTPAGE/@GOTPAGEOFF; non-Apple
     targets fall through to the historical aarch64GlobalAddr
     (the ACT does not authorize Linux PIC changes).

  3. Routing at three IR opcodes:
       IR_LOAD_DEREF, IR_STORE_DEREF, IR_LEA.
     Each consults aarch64IsExternalGlobalSymbol; extern shape
     -> aarch64ExternalSymbolAddr; same-image -> aarch64GlobalAddr.

## GATES

  make unit-test                PASS  90/90   (c3/unit-test.txt)
  make jit-unit-test            PASS  90/90   (c3/jit-unit-test.txt)
  make lsp-test                 PASS  43/43   (c3/lsp-test.txt)
  make llvm-gep01-test          FAIL  GEP01_PASS=26 GEP01_FAIL=4
                                       STATUS=FAIL
                                       (c3/llvm-gep01-test.txt)
  make gate-fast                PASS          (c3/gate-fast.txt)
  gate-push.sh HEAD             FAIL  gep01 STATUS=FAIL
                                       (c3/gate-push.log)

  The llvm-gep01 failures are the SAME cap-verifier failures that
  the predecessor ACT (ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-
  CORRECTION01) already documented in
  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01/
  c3/gate-push-correction01.log (identical GEP01_PASS=26 GEP01_FAIL=4
  identical FAIL messages). They are an environment / python /
  scripts/quality/llvm-cap-table-verifier.py infrastructure issue
  unrelated to AArch64 Mach-O external-reference materialisation.
  This ACT does not authorize touching llvm-gep01-test or the
  cap-verifier, and per F14 the historical evidence above remains
  authoritative for that defect. Recorded as residue.

  The two SUITES the ACT actually exercises (unit-test and
  jit-unit-test) were the gate-failing surface of the predecessor
  and are now PASS.

## SCOPE
  production files touched:
    src/aarch64.c                (+136 / -28)

  production files NOT touched (verified via git diff --stat):
    src/x86_64.c                 (F2: RIP-relative `leaq` is
                                 independent of the arm64 defect)
    src/parser.c                 (FORBIDDEN by ACT: parser changes)
    src/ir.c                     (FORBIDDEN by ACT: neutral IR)
    src/llvm-backend.c           (FORBIDDEN by ACT: LLVM backend)
    src/holyc-lib/**             (FORBIDDEN by ACT: stdlib headers)
    src/CMakeLists.txt           (FORBIDDEN by ACT: install dance)

  test/evidence files added:
    evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c3/**
    evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c4/**
    evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/c2/
      implementation-delta.txt updated (C2.1 extension section).

## RESIDUE
  See c4/residue.txt.

## NEXT ACT
  See c4/roadmap-transition.txt.
