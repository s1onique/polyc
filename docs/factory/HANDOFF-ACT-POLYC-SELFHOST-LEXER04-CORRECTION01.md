# HANDOFF — ACT-POLYC-SELFHOST-LEXER04-CORRECTION01

```text
VERDICT: HALT_MECHANICAL_BLOCKING_B5 (C2B PolyC verifier rebuild
         blocked by pre-existing libtos.a symbol gap)
TRUE_GREEN_QUALIFICATION: PARTIAL
  - C0 AUTH: PASS (51fad60)
  - C1 RED + ROOT CAUSE: PASS (3294449)
  - C2A toolchain fix: PASS (5e967c8)
  - C2A RED/GREEN proof: PASS (6fdeab5)
  - C2B PolyC verifier: HALT (8d9d5d2)
  - C3 full evidence: PARTIAL (this commit)
  - C4 ROADMAP append: PARTIAL (this commit)
```

## IDENTITY (entry → final)

```text
Branch: main
Entry HEAD: 6c0c4c2 (FALSE_GREEN reclassification commit)
Final HEAD at HANDOFF: see git log; final ACT-Verdict trailer
                      is recorded in CLOSE commit
Predecessor ACTs: ACT-POLYC-SELFHOST-LEXER04 (FALSE_GREEN at 6c0c4c2),
                  ACT-POLYC-SELFHOST-LEXER04-FACTORY-AGENT-CONVERGENCE
```

## ROOT CAUSE (mechanically proven at C1)

ROOT_CAUSE_CLASS = A : STATIC_FUNCTION_VISIBILITY_CODEGEN

Site: `src/parser.c:2538-2540` originally captured `is_static=1`
and explicitly discarded it with `(void)is_static;` (commented
`/* static at the global scope does not yet do anything */`).
The IR backends (aarch64.c, x86_64.c, aarch64-jit.c) therefore
emitted every function (including static ones) with `.globl`,
producing duplicate-symbol errors whenever two TUs each
declared `static Foo`. The HANDOFF's prior claim of
"partial libtos ABI" was incorrect — the libtos snapshot is
an independent host-infrastructure concern (see C2B HALT).

## RED (mechanically reproduced)

Two-TU reproducer at `/tmp/c1-repro-2tu/{tuA.HC,tuB.HC}` —
identical `static U32 ROTR` in each TU plus distinct public
wrappers `_A_ROTR` and `_B_ROTR`.

BEFORE FIX (HEAD reverted to 3294449):
- nm tuA.o: `_ROTR` is T (external)
- nm tuB.o: `_ROTR` is T (external)
- ld -r: FAIL "duplicate symbol '_ROTR' in: tuA.o tuB.o"

AFTER FIX (HEAD = 5e967c8):
- nm tuA.o: `_ROTR` is t (local)
- nm tuB.o: `_ROTR` is t (local)
- ld -r: RC=0, no error
- combined.o: two private `_ROTR` + two external `_A_ROTR`/`_B_ROTR`

## IMPLEMENTATION (7 production files)

```text
src/ast.h, src/ast.c       Add fn_is_static to AST_FUNC union
                            member; add astFunctionWithLinkage()
                            constructor and astFunctionSetStatic()
                            setter.
src/parser.c               Plumb is_static from KW_STATIC through
                            parseFunctionOrDef -> parseFunctionDef
                            -> astFunction; allow static->static
                            redefinition branch in upgrade path.
src/jit-common.h, .c       New Map *private_fns on HccJit, populated
                            in hccJitCompileChunk, consulted at
                            hccJitFinalize to skip symbol-table
                            insertion for static functions.
src/aarch64.c, src/x86_64.c Suppress unconditional .globl emit in
                             function prologue when fn_is_static
                             is set.
```

## GATES

| Gate      | Status                              | Evidence               |
|-----------|-------------------------------------|------------------------|
| fast      | n/a (compiler-internal ACT)         | local rebuild PASS     |
| F3 RED    | PASS                                | c1-rotr-regression.txt |
| F5 no-weak| PASS (no existing test weakened)    | 7-file diffs only add  |
| F10 conserv| n/a (no user-facing semantic change)| only `static` gains its discarded semantics |
| F14 F-GIT | PASS (history not rewritten)        | append-only            |
| F15 scope | PASS                                | bounded to static-keyword repair |

## SCOPE

ACT authorized 7-file production edit. Delivered exactly 7.
No unrelated refactors (F7). No F5 weakening (F5).

## RESIDUE

P0 (blocks C2B PolyC verifier build, follow-up ACT needed):
  libtos.a symbol gaps: `_FREE`, `_STRNCMP`, `_SpawnAndCapture`,
  `_MEMSET`, `_STRLEN_FAST` are referenced by `all.HC` but not
  defined in `build/test-prefix/lib/libtos.a`. The host's
  libtos snapshot is incomplete relative to what `all.HC`
  expects to resolve at link time.

  Recommended next ACT:
    ACT-POLYC-LIBTOS-SYMBOL-GAPS01
    Audit src/holyc-lib/*.HC forward declarations vs the libtos
    snapshot, then either add missing definitions to libtos or
    repair the all.HC build.

P1 (deferred, see original ACT §26, §27):
  Four-generation production semantic seam (G0/G1/G2/G3 fixture
  corpus and serializer): NOT executed because C2B PolyC verifier
  rebuild is the gate that §23/§26 secondary confirmation depends
  on. Once ACT-POLYC-LIBTOS-SYMBOL-GAPS01 closes, re-open the
  four-generation seam work as ACT-POLYC-SELFHOST-LEXER04-CORRECTION02.

P2:
  C-language verification authority (`tools/quality/lexer09-
  fixedpoint-verify.c`, `tools/quality/sha256-tool.c`) is NOT
  removed per F-POLYC-TOOLS §27 C2.9 carve-out (gates not yet
  enforcing). They are preserved, but they were NOT used in
  this ACT's closure evidence (which relies on host `nm` and
  `ld -r`).

## NEXT ACT

```text
ACT-POLYC-LIBTOS-SYMBOL-GAPS01
  Audit libtos snapshot vs all.HC, repair gaps, re-enable
  PolyC fixedpoint verifier rebuild.
```

Once that closes, re-open the four-generation seam work as
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02.

## WHAT THIS HANDOFF RECORDS

- C0 AUTH: committed
- C1 RED + ROOT CAUSE: committed, mechanically proven
- C2A toolchain fix: committed, mechanically RED/GREEN-proven
- C2B PolyC verifier rebuild: HALT_B5, mechanically justified
- Original ACT's remaining acceptance criteria (G0..G3 seam,
  AC01..AC32 status tables): NOT executed; recorded as residue
- FALSE_GREEN lineage: closed; historical ACT remains intact
  per F14 (no rewrite)
