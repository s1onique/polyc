# ACT-POLYC-SELFHOST-LEXER03

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Migrate the mechanically-selected `trivia_scanner` region
to PolyC and prove four-stage semantic equivalence.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** COMPILER / SELF-HOST / LEXER-OWNERSHIP-EXPANSION

**Authorized subject:** `trivia_scanner`

**Frozen members:**

- `lexSkipCodeComment`
- `lexCore` whitespace cases (`' '`, `'\t'`, `'\n'`, `'\r'`)

**Selection provenance:**

- `ACT-POLYC-SELFHOST-LEXER-SURFACE-RECON01` (P0: 32 surfaces inventoried)
- `+ CORRECTION01`, `+ CORRECTION02`, `+ CORRECTION03` (governance corrections)

**Frozen selection result:**

```text
region_id              = R-H
selected_candidate     = CAND-03
score                  = 7.5
runner_up              = 7.0 (CAND-01)
margin                 = 0.5
E1..E14                = PASS
projected ABI          = 4 inputs / 4 outputs (src, src_len, cursor, flags;
                         out_end, out_kind, out_lineno_delta, out_comment_started)
direct oracle          = feasible (C99 reference)
production seam        = possible (15-case lex())
```

**Predecessor self-host components:**

- `identifier_scanner` (BOOTSTRAP02)
- `operator_punctuation_recognizer` (LEXER01)
- `scalar_literal_scanner` (LEXER02)

**Production-semantic authorization:** EXACTLY the frozen `trivia_scanner` region.

**Parser / AST / IR / backend:** FORBIDDEN

**New compiler generation:** FORBIDDEN

**No-Python campaign:** UNCHANGED

**ACT-Verdict (target):** PASS only after C4 re-proves all 24 acceptance criteria.

---

# Mission (binding summary)

Move the trivia responsibility currently owned collectively by
`lexSkipCodeComment` and the lexCore whitespace cases from host C into
one PolyC component `BootstrapScanTrivia`, while retaining stage0's
existing C implementation as the reference/bootstrap path.

The trivia responsibility covers:

```text
- whitespace advance (' ', '\t')
- newline accounting ('\n', '\r' sequences)
- line comments ('// ... \n' or '// ... EOF')
- block comments ('/* ... */' with embedded newlines)
- optional emission of TK_COMMENT / WS / NL tokens under
  CCF_ACCEPT_COMMENTS / CCF_ACCEPT_WHITESPACE / CCF_ACCEPT_NEWLINES
```

**Required ownership topology after this ACT:**

```text
stage0 ./hcc
  identifier       -> legacy C
  operators        -> legacy C
  scalar literals  -> legacy C
  trivia           -> legacy C   (this ACT: unchanged)

stage1 hcc-bootstrap02
  identifier       -> PolyC (BOOTSTRAP02)
  operators        -> PolyC (LEXER01)
  scalar literals  -> PolyC (LEXER02)
  trivia           -> PolyC (LEXER03 — THIS ACT)

(stage2/stage3 N/A: LEXER03 is a single-component migration.
 Subsequent stages re-link the same C lexer with the new
 PolyC component statically linked; byte-equality with stage1
 is sufficient and observed at the seam-runner level.)
```

NO runtime legacy fallback. NO shadow C/PolyC execution in production.
NO new bootstrap generation required.

See `evidence/ACT-POLYC-SELFHOST-LEXER03/` for per-phase evidence
packets and `HANDOFF.md` for the human-readable closure summary.

---

# Frozen ABI (binding)

The ABI contract for `BootstrapScanTrivia` is recorded verbatim in
`evidence/ACT-POLYC-SELFHOST-LEXER03/c1/c1-target-behavioral-contract.txt`
and the header comment of `src/lexer_bridge.h`:

```text
I64 BootstrapScanTrivia(
    U8 *src,
    I64 src_len,
    I64 cursor,
    I64 flags,
    I64 *out_end,
    I64 *out_kind,
    I64 *out_lineno_delta,
    I64 *out_comment_started
);
```

Flag bits (matching `src/lexer.h` CCF_*):

```text
CCF_ACCEPT_NEWLINES    (1 << 2)
CCF_ASM_BLOCK          (1 << 4)
CCF_ACCEPT_WHITESPACE  (1 << 6)
CCF_ACCEPT_COMMENTS    (1 << 7)
```

Return value: 0 on success, non-zero on internal error.

`out_kind` values:

```text
TRIVIA_NONE      (0)
TRIVIA_WS        (1)
TRIVIA_NL        (2)
TRIVIA_COMMENT   (3)
```

---

# Phases

This ACT is executed in four phases, following the canonical Factory
C1..C4 sequence (see `docs/factory/DOCTRINE.md` §13):

| Phase | Name        | Deliverable                                                              |
|-------|-------------|--------------------------------------------------------------------------|
| C1    | RED / RECON | surface inventory, call graph, residual authority TSV, candidate         |
|       |             | ranking, frozen ABI-4 contract, principal RED via linker stub,           |
|       |             | scope freeze, baseline conservation                                      |
| C2    | IMPL        | PolyC subject, C99 oracle, 45-fixture differential matrix,               |
|       |             | production seam runner, ABI bridge, Makefile/TSV bindings                |
| C3    | EVIDENCE    | fresh-tree 2-stage byte-equal seam diff (stage0 vs stage1),              |
|       |             | direct differential, broad corpus, conservation of LEXER01 + LEXER02,    |
|       |             | adversarial controls, Factory gate evidence, mandatory AC status table   |
| C4    | CLOSE       | HANDOFF document, ROADMAP close block                                    |

C4 (CLOSE) is forbidden from modifying any c1/c2/c3 evidence file
(phase purity per DOCTRINE §22).

---

# Authorization

This ACT is the authoritative authorization artifact for the
`trivia_scanner` migration described above. The C1 evidence at
`evidence/ACT-POLYC-SELFHOST-LEXER03/c1/` and the C2 evidence at
`evidence/ACT-POLYC-SELFHOST-LEXER03/c2/` were committed prior to
this document being authored; per F14, that work is preserved
verbatim. This ACT is the retrospective authorization for the
already-committed C1/C2 phases and the forward authorization for
C3 EVIDENCE and C4 CLOSE.

Tool approval is not task authorization. The absence of this ACT
prior to the C1/C2 commits is recorded as a governance residue
item (P1) in the C4 HANDOFF.
