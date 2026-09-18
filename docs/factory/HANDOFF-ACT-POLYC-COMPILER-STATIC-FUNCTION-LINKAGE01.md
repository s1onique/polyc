# HANDOFF -- ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01

VERDICT

PASS_TRUE_GREEN

---

C0..C4 ledger:

  C0 AUTH : PASS  (commit 4ac7810)
  C1 RED/ROOT CAUSE: PASS  (commit 1f24d6b)
  C2 IMPL/TESTS : PASS  (commit 5542c1c)
  C3 EVIDENCE   : PASS  (commit 97f421c)
  C4 CLOSE      : this document

  additional JIT-lifetime correction (RED_PRIVATE_FNS_STALE_STATE)
  bounded to src/jit-common.c.
```

## IDENTITY

```text
Branch:               main
Entry HEAD:           06c7951 (LEXER04-CORRECTION01 C4 HALT commit)
C0 commit:            4ac7810
C1 commit:            1f24d6b
C2 commit:            5542c1c
C3 commit:            97f421c
C4 commit:            <this commit>
Predecessor ACTs:     ACT-POLYC-SELFHOST-LEXER04-CORRECTION01
                      (HALT_MECHANICAL_BLOCKING_B5 at 06c7951;
                       not resumed; one useful repair requalified)
```

## DISCOVERY LINEAGE

The historical seven-file static-function-linkage repair at
commit 5e967c8 was discovered during LEXER04-CORRECTION01 C1
RED phase as a way to make the ROTR two-TU reproducer compile.
That ACT HALTED at C2B (independent libtos symbol gap),
leaving the seven-file repair on `main` without a dedicated
qualification.

This ACT does NOT retroactively authorize 5e967c8. It requalifies
the existing implementation as a first-class compiler feature,
applies one bounded JIT-lifetime correction found during C1
falsification, and installs a permanent regression gate.

## SEMANTIC CONTRACT

HolyC `static <return-type> Foo(...)` at global scope:

  - emits `Foo` with internal linkage (non-external object symbol);
  - is callable from within the same translation unit / JIT chunk;
  - does NOT publish `Foo` globally via hccJitLookup;
  - allows the same spelling in independent TUs / chunks without
    duplicate-symbol collision;
  - does NOT suppress external linkage for normal functions;
  - does NOT permit duplicate definitions within one TU.

External / public functions remain externally visible, eligible
for global JIT publication, and produce duplicate-symbol errors
when defined in two TUs (verifying the static fix does not
over-privatize).

## IMPLEMENTATION UNDER QUALIFICATION

Pre-existing (commit 5e967c8, seven files):

```text
src/ast.h, src/ast.c       Add fn_is_static field to AST_FUNC
                            union member; add
                            astFunctionWithLinkage() and
                            astFunctionSetStatic().
src/parser.c               Plumb is_static through KW_STATIC ->
                            parseFunctionOrDef -> parseFunctionDef.
                            Allow static->static redefinition.
src/jit-common.h, .c       New Map *private_fns on HccJit,
                            populated in hccJitCompileChunk,
                            consulted at hccJitFinalize.
src/aarch64.c, src/x86_64.c  Suppress unconditional .globl in
                              function prologue when fn_is_static.
```

Additional correction (this ACT, commit 5542c1c):

```text
src/jit-common.c            mapClear(jit->private_fns) at start of
                            hccJitCompileChunk alongside
                            mapClear(jit->chunk_fns).
src/jit-common.c            mapRelease(jit->private_fns) in
                            hccJitFree for memory hygiene.
```

The seven-file historical repair was ACCEPTED UNCHANGED for its
intended semantics. The additional correction is bounded to a
single Map's lifetime and does not change the language semantics.

## RED

C1 falsification found exactly one RED:

```text
RED_PRIVATE_FNS_STALE_STATE  (HALT_JIT_PRIVATE_STATE_LEAK)

  REPRO (HEAD=06c7951, pre-fix):
    $ echo 'static I64 Foo() { return 11; }
    public I64 Foo() { return 22; }
    "%d\n", Foo();' | hcc -repl --install-dir=<prefix>
    JIT: unresolved symbol '_Foo'

  ROOT CAUSE:
    src/jit-common.c:private_fns is populated by every chunk's
    static functions and consulted at finalize to skip the
    corresponding labels from symbols/host_symbols, but NEVER
    cleared between chunks. chunk_fns IS cleared per chunk
    (src/jit-common.c:575); private_fns is not. This violates
    the contract declared in src/jit-common.h:45-50
    ("Reset per chunk").

  Consequence:
    chunk1 compiles static Foo -> private_fns += "Foo"
    chunk2 compiles public Foo -> finalize skips registration
    chunk3's reference to Foo  -> JIT: unresolved symbol '_Foo'
```

## CORRECTIONS APPLIED

```text
src/jit-common.c (line ~576)  +mapClear(jit->private_fns)
src/jit-common.c (line ~908)  +if (jit->private_fns) mapRelease(...)
```

GREEN_AFTER (HEAD=5542c1c, post-fix):

```text
$ echo 'static I64 Foo() { return 11; }
public I64 Foo() { return 22; }
"%d\n", Foo();' | hcc -repl --install-dir=<prefix>
22
```

8 changed lines (6 of comment, 2 of substantive code). No other
production file touched.

## NATIVE BACKENDS

### AArch64 native (`src/aarch64.c`)

```text
hcc --target=aarch64-apple-darwin -c aarch64_static.HC
nm -m aarch64_static.o:
  _StaticFn   non-external (local)
  _PublicFn   external
```

Assembly evidence (`-S -o-`):
```text
_StaticFn:               <-- NO .globl directive
.globl _PublicFn
_PublicFn:
```

AARCH64_STATIC_EXPORT_SUPPRESSED = YES
AARCH64_PUBLIC_EXPORT_PRESERVED  = YES

### x86_64 native (`src/x86_64.c`)

Cross-target from aarch64 host:
```text
hcc --target=x86_64-apple-darwin -c aarch64_static.HC
nm -m x86_static.o:
  _StaticFn   non-external
  _PublicFn   external
```

X86_64_STATIC_EXPORT_SUPPRESSED = YES
X86_64_PUBLIC_EXPORT_PRESERVED  = YES

### Legacy x86 (`src/x86.c`)

OPT-IN via `--use-legacy-x86`. Not modified by 5e967c8 and not
the default codegen. Excluded from this ACT's scope (the ACT
qualifies the default codegen that was modified).

### LLVM backend (`src/llvm-backend.c`)

Excluded from this ACT's scope per ACT §1 (LLVM is an
independently-qualified experiment per ACT-POLYC-LLVM-SPIKE01
lineage). Not touched by 5e967c8.

## JIT

### AArch64 JIT and x86_64 JIT

Both backends share the same finalize path in src/jit-common.c
(private_fns filter on lines 729-731). The C2 correction is at
the shared finalize, so both JIT backends benefit identically.

### Native S01..S08 + REPL J01..J05

All evidence under `evidence/ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01/c3/`:

  c3-s01-single-static.txt     rc=1 (Foo non-external)
  c3-s02-two-tu-static.txt     rc=98 (1122%256); two private Foo coexist
  c3-s03-two-tu-external.txt   ld_rc=1 "duplicate symbol '_Foo'"
  c3-s04-static-plus-external.txt  rc=33 (11+22)
  c3-s05-same-tu-duplicate.txt   "symbol '_Foo' is already defined"
  c3-s06-forward-static.txt    static forward + def compiles
  c3-s07-forward-public.txt    public forward + def compiles
  c3-s08-mixed-linkage.txt     both upgrades pass
  c3-jit-linkage.txt           J01..J05 ledger

PRIVATE_FN_GLOBAL_LOOKUP = NOT_FOUND
PUBLIC_FUNCTION_JIT_LOOKUP = VISIBLE

## NEGATIVE CONTROLS

Three mutations (M01/M02/M03) all detected their injected defects
and the canonical sources were restored:

  M01: revert C2 fix (no mapClear(private_fns))
       -> J03 FAIL ("JIT: unresolved symbol '_Foo'")

  M02: force-if(1) in src/aarch64.c, src/x86_64.c
       -> PublicFn becomes non-external (over-privatized)

  M03: inject stale "_Foo" into private_fns at chunk start
       -> even an originally-public Foo is filtered

All three were detected by the regression infrastructure; no
false-negatives.

## CONSERVATION

### Compiler regression suite

```text
$ make gate-fast
VERDICT=PASS

$ make static-function-linkage-test
STATIC_FUNCTION_LINKAGE_TEST=PASS
```

### Prior self-host engineering

```text
LEXER01_CONSERVATION          = PASS (no lexical source touched)
LEXER02_CONSERVATION          = PASS
LEXER03_CONSERVATION          = PASS
LEXER04_PRESERVED_ENGINEERING = PASS (src/lexer.c not touched;
                                     BootstrapLinkDirective
                                     cannot regress by code
                                     locality)
```

### Bootstrap chain

No bootstrap source touched. The full unit-test/jit-unit-test
suite is not executable on this host due to the libtos symbol
gaps that ACT §1 explicitly excludes (subject of
ACT-POLYC-LIBTOS-SYMBOL-GAPS01).

### Append-only history

```text
$ git log --oneline 06c7951..HEAD
97f421c C3 EVIDENCE: ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01
5542c1c C2 IMPL: ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01
1f24d6b C1 CONTRACT/RED: ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01
4ac7810 C0 AUTH: ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01
```

Linear; no amend, no rebase, no force-push, no reset+recommit.

## FACTORY GATES

```text
gate-fast                  PASS (diff-check, shell-syntax,
                                doc-invariants, large-file-guard,
                                factory-closure-status)
factory-append-only-test   PASS (NC1..NC11 all green)
shell-loc-gate             PASS (≤50 LOC scripts cap)
shell-budget-gate          PASS for this ACT's scope
static-function-linkage-test (new)  PASS
```

## SCOPE

Pre-authorized files used: 1
  src/jit-common.c (8 lines; 6 comment, 2 substantive)

Conditionally-authorized files: 0
  (src/aarch64-jit.c, src/llvm-backend.c NOT touched; the C1
  falsification did not require changes there because the JIT
  linkage filter lives at the shared finalize path)

No other production file modified.

## RESIDUE

P2 (deferred, not blocking):
  - factory-no-python-check.HC and factory-polyc-tools-check.HC
    are not yet wired into gate-fast (per F-NO-PYTHON and
    F-POLYC-TOOLS C2.9 carve-out). Manual inspection in
    c3-f-no-python.txt and c3-f-polyc-tools.txt covers this ACT's
    scope.
  - Legacy x86 (`src/x86.c`) does not consult fn_is_static. This
    is OPT-IN via `--use-legacy-x86` and outside ACT scope;
    recorded as a separate language gap should anyone rely on the
    legacy backend.
  - LLVM backend (src/llvm-backend.c) does not consult fn_is_static.
    Excluded per ACT §1 (independent LLVM qualification lineage).
  - libtos symbol gaps continue to block the full unit-test
    suite. Out of ACT scope per §1.

## NEXT

```text
NEXT = ACT-POLYC-LIBTOS-SYMBOL-GAPS01

That ACT restores the PolyC-native verifier substrate blocked
by the missing libtos symbols (_FREE, _STRNCMP, _SpawnAndCapture,
_MEMSET, _STRLEN_FAST). After it closes, the canonical
PolyC-native verifier rebuild can resume and
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02 can run a true
G0/G1/G2/G3 production #link semantic seam.

After that:
  ACT-POLYC-SELFHOST-SURFACE-RECON03
```

## SUMMARY

HolyC global-scope `static` functions now have
translation-unit/internal linkage.

Their staticness survives parsing and AST construction.

Native object emission keeps them local (verified for both
aarch64 and x86_64 targets via nm and assembly-level inspection).

Independent translation units may use the same private function
spelling without collision or cross-binding (S02 runtime rc=1122
verified end-to-end).

Public functions remain externally visible (S03 external
duplicate-symbol rejection verified; S04 private+external
coexistence runtime rc=33 verified).

The JIT does not publish private functions globally and does
not leak private-name state across chunks (J03 stale-state
defect found at C1, fixed at C2; J04 public-then-private
preserves public visibility; J05 private not exposed).

All live native backends under the current default compiler
implement the same linkage distinction.

The behavior is guarded by `make static-function-linkage-test`
and 13 durable adversarial fixtures under
tests/compiler/static-function-linkage/.

This ACT does NOT authorize claims about static variables,
weak symbols, visibility attributes, inline linkage, or
shared-library visibility.
