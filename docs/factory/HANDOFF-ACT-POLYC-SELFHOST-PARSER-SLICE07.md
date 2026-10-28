# HANDOFF -- ACT-POLYC-SELFHOST-PARSER-SLICE07

**ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE07`
**Class:** SELFHOST / PARSER / STRUCTURAL-BOUNDARY / PRODUCTION-AUTHORITY-TRANSFER
**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05` (closed, `ACT-Verdict: PASS`)

Closure verdict is authoritative in the `ACT-Verdict` trailer of the
ACT's CLOSE commit.  This HANDOFF is a summary, not terminal verdict
authority.

---

## 1. What was migrated

The compound-block statement APPEND/SKIP routing -- the one legacy-C
semantic decision that decides whether a parsed statement becomes an
element of a compound block's statement list -- is now owned by a
qualified, compiled PolyC component in the REAL production compiler.

```text
COMPOUND_BLOCK_APPEND_AUTHORITY = POLYC
LEGACY_COMPOUND_BLOCK_C_AUTHORITY = RETIRED
SEVENTH_POLYC_PARSER_AUTHORITY = ESTABLISHED
```

### The selected subject

```text
SELECTED_CANDIDATE = SUB-003
SELECTED_CANDIDATE_CLASS = STRUCTURAL_BOUNDARY
SELECTED_ENCLOSING_FUNCTION = parseCompoundStatementInternal
ORIGINAL_SOURCE_RANGE = src/parser.c:2049..2049
ORIGINAL_SOURCE_SHA256 = 378a39d71eed7aaf673bde3857cc08df6f9c95c776723832e6e460553be361e8
POLYC_SYMBOL = BootstrapCompoundBlockAppendsStatement
POLYC_ABI = I64 BootstrapCompoundBlockAppendsStatement(I64 stmt_kind, I64 declvar_kind) -> I64
POLYC_SOURCE = tools/bootstrap/selfhost-parser-slice07.HC
PRODUCTION_SELECTOR = HCC_USE_SELFHOST_PARSER_COMPOUND_BLOCK_APPEND
```

The decision's SEMANTICS are unchanged:

```text
0 exactly for (stmt_kind == AST_DECL && declvar_kind == AST_GVAR)
1 otherwise
```

with `AST_DECL = 263` and `AST_GVAR = 256`, re-derived at C1 by
COMPILING the live `src/ast.h` and confirmed by the real G0 oracle's
observed skip pair.

### The line movement

The decision was FACTORED OUT of `parseCompoundStatementInternal` into
the small static function `parseCompoundBlockAppendsStatement(int
stmt_kind, int declvar_kind)`, so that the REAL legacy decision can
be reached by an object-level oracle without re-implementing it.  This
is exactly the SLICE06 precedent.  The line movement and the single
parameter substitution are recorded in
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c1/legacy-source-and-abi.txt`,
as ACT section 5 item 1 requires.

---

## 2. The delegation is load-bearing, and the legacy decision is retired

This is proven by the FUNCTION-SCOPED DISASSEMBLY of the REAL
production parser object, not by a symbol's mere existence.

In `_parseCompoundStatementInternal`:

```text
    3a48: cmp  w0, #263        ; the AUTHORIZED projection guard
    3a4c: b.ne  0x3a5c        ; the SHORT-CIRCUIT over the declvar load
    3a50: ldr  x8, [x22, #48] ; stmt->declvar
    3a54: ldr  w1, [x8]       ; stmt->declvar->kind
    3a5c: mov  w1, #0         ; the non-AST_DECL projection value
    3a68: bl   0x3a68         ; CALL BootstrapCompoundBlockAppendsStatement
    3a70: cbz  w0, 0x37fc     ; the PolyC result drives SKIP/APPEND
```

```text
LEGACY_AST_GVAR_COMPARISONS_IN_PRODUCTION_FUNCTION = 0
AUTHORIZED_AST_DECL_PROJECTION_COMPARISONS         = 1
PRODUCTION_CALL_RELOCATION                          = 0x3a68 ARM64_RELOC_BRANCH26
```

The C side no longer knows what "a global variable" is.  It knows only
what "a declaration" is, and only in order to PROTECT THE DEREFERENCE.
The C guard authorises ONE field read; it does NOT compute the
append/skip result.  The PolyC return value is the ONLY input to the
SKIP/APPEND action, and it is acted on exactly once.

### The C side keeps everything else

```text
the `continue` that implements the SKIP       UNCHANGED
the listAppend(body->stms, stmt)               UNCHANGED
the token cursor advance                       UNCHANGED
the AST graph, the recovery point, the
  diagnostics, the scope maps, every
  allocation, the parseStatement dispatch       UNCHANGED (C-owned)
```

---

## 3. The conditional host projection is preserved

The two-argument ABI does NOT make both host reads unconditional.  The
instrumented read-count harness observes:


---

## 4. The oracle is object-level, and the fixture is derived

The G0 reference is the ACTUAL production `src/parser.c` translation
unit compiled WITHOUT the delegation macro, with the production flags.
It carries NO reference to the proposed PolyC symbol, and the build
FAILS CLOSED if it ever does.  The oracle driver probed 1858 rows /
1733 distinct input pairs and observed EXACTLY ONE skip: (263, 256).

The fixture is 1753 rows over 10 partitions, derived from the live
`src/ast.h` enum, with the expected value computed from the FROZEN
RULE -- never from the new implementation and never from the oracle.
An INDEPENDENT PolyC witness re-derives `AST_DECL` and `AST_GVAR` by
PARSING the live source bytes and recomputes every row's expected
value.  It PASSES on the pristine fixture, and all five of its adverse
controls fire for their intended reasons.

---

## 5. The four generations are independent

```text
G0  /usr/bin/cc                  src/parser.c (delegation OFF)
G1  build/host-stage0/hcc        the PolyC component
G2  ./hcc                        the PolyC component
G3  build/hcc-bootstrap02        the PolyC component
```

The three PolyC producers have three DIFFERENT SHA-256 digests, so
they are three distinct executables and not one executable relabelled
three ways.  G1, G2 and G3 produced BYTE-IDENTICAL objects, which is
expected under deterministic compilation; the independence rests in
WHO COMPILED THE OBJECT, not in the object's bytes.

All four generations agree on all 1753 rows, and all TWELVE ordered
pairs are IDENTICAL when compared ROW BY ROW with the exact row IDs.

---

## 6. The causal link is proven on the REAL production compiler

In a disposable detached worktree, ONLY the PolyC source predicate
was changed.  The MUTANT production compiler BUILT SUCCESSFULLY and
then REJECTED the static witness the pristine compiler accepts.

```text
PRISTINE  build EXIT=0  witness compiles  WITNESS_OUTPUT=13 15 2  exit 0
MUTATED   build EXIT=0  witness REJECTED  ERROR: Mapping exists for 1 -> %l14 i64 local
RESTORED  build EXIT=0  witness compiles  WITNESS_OUTPUT=13 15 2  exit 0
```

The observation class is reported HONESTLY as
`COMPILER_ACCEPTANCE_CHANGED`.  It is NOT reported as a
compiled-program runtime output change, because no mutant executable
was produced for that witness.  This is the SAME channel and the SAME
diagnostic shape that the predecessor recorded for the same decision.

The mutated component also changes the fixture semantics on EXACTLY the
three (263, 256) rows, and the restoration is BYTE-IDENTICAL.

---

## 7. The negative controls

```text
INHERITED_CONTROL_COUNT = 10   (N-01..N-10, IDs unchanged)
INHERITED_CONTROL_PASS  = 10
NEW_CONTROL_COUNT       = 18   (the S7-* namespace, disjoint)
NEW_CONTROL_PASS        = 18
TOTAL_CONTROL_COUNT     = 28
NEGATIVE_CONTROLS_UNPROVEN = 0
```

---

## 8. The conservation and the historical failures

```text
PARSER_HOST_ARCH_ASSERTIONS   = 376/376 over 90 test files
PARSER_ASSERTION_SEQUENCE_MD5 = b6f117eb1386ca80f81bc06226e2a741
NEW_PARSER_FAILURE_IDENTITIES = 0

LEXER07_DIRECT_DIFFERENTIAL    = 89/89 PASS
LEXER08_DIRECT_DIFFERENTIAL    = 45/45 PASS
LEXER09_DIRECT_DIFFERENTIAL    = 23/23 PASS

LEXER07_BROAD_CORPUS_STATUS    = FAIL_KNOWN_BASELINE
LEXER07_BROAD_CORPUS_FAIL_S0  = 15
LEXER07_FAILURE_IDENTITY_MD5   = 7ee761440de83552e751e3c3976c1683
NEW_LEXER07_FAILURE_IDENTITIES = 0

CROSS_TARGET_STATUS            = FAIL_ENVIRONMENT_PREFIX (67 in BOTH trees)
NEW_CROSS_TARGET_FAILURE_IDS   = 0

F_NO_PYTHON                    = FAIL_KNOWN_BASELINE (exactly 12, zero new)
F_POLYC_TOOLS                  = UNAVAILABLE (its checker is not landed)

GATE_FAST = PASS
GATE_PUSH = PASS
APPEND_ONLY = PASS (11/11)
F14 = PASS
FACTORY_V2_RANGE_CHECK = PASS
PATCH_HYGIENE = PASS

MANDATORY_AC_TOTAL = 50
MANDATORY_AC_PASS = 50 (49 pre-CLOSE + AC50 discharged by the external check)
```

---

## 9. A bounded residue

The SLICE06 CMake producer branch in `src/CMakeLists.txt` is STALE: it
passes an ABSOLUTE `--install-dir` to a compiler that appends
`/include/tos.HH` to the prefix string, so the header path is
malformed.  It was OBSERVED at C3 while investigating this ACT's own
producer path.  It is a PRE-EXISTING defect in a closed predecessor's
wiring, it is NOT on this ACT's production path (the SLICE06 subject
is built by the Makefile rule and consumed as a verified PREBUILT
object), and it is NOT repaired here, because that would be a change
to a closed predecessor's wiring and therefore outside this ACT's
scope.

```text
RESIDUE_CLASS = P2
RESIDUE_LOCATION = src/CMakeLists.txt, the SLICE06 producer branch
RESIDUE_NOT_ON_THIS_ACT_PRODUCTION_PATH = YES
```

---

## 10. What remains blocked

`parseCompoundStatementInternal`, `parseStatement` and `parseExpr` as
whole functions, the recursive flow-analysis walks, and the
declaration-versus-statement routing decision.  The other structural
sub-slices and the eligible scalar candidates remain separately
unauthorized until a new evidence-backed selection exists.

**This ACT does NOT claim whole-parser self-hosting.**

---

## 11. The artifacts

```text
docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE07.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE07.md
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c0/   (the entry, the freeze, the baseline)
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c1/   (the oracle, the enums, the fixture)
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c2/   (the component, the delegation, the linkage)
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c3/   (the generations, the causality, the controls)
evidence/ACT-POLYC-SELFHOST-PARSER-SLICE07/c4/   (the terminality receipt)
```

---

## 12. The commit series

Five forward-only commits, no amend, no rebase, no reset, no
force-push.

VERDICT

PASS

Seven production-authoritative PolyC parser decisions, including the
second migrated bounded structural sub-slice; the legacy C decision
retired from the production path with zero AST_GVAR comparisons left
in the production function; the conditional host projection preserved
and adversarially proven; the object-level legacy oracle, the derived
fixture and the independent verifier all in force; four independent
generations agreeing row by row; a successfully rebuilt mutant
production compiler whose change is honestly classified in the
compiler-acceptance channel; twenty-eight negative controls all
sensitive with none unproven; no newly introduced failures; and the
frozen historical debt recorded honestly rather than relabelled green.


```text
CASE1_NONDECL_ABSENT_DECLVAR result=1 reads=0 trapped=0
CASE2_NONDECL_GLOBAL_DECLVAR result=1 reads=0 trapped=0
CASE3_DECL_GLOBAL result=0 reads=1 trapped=0
CASE4_DECL_LOCAL result=1 reads=1 trapped=0
```

A non-declaration causes ZERO `declvar` reads and NO trap; a
declaration causes EXACTLY ONE read.  The anti-control that removes
the guard moves the read count 0 -> 1 and the trap 0 -> 1, so the
detector is SENSITIVE.
