# ACT-POLYC-B0-SUBSTRATE-RECON01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-B0-SUBSTRATE-RECON01
ACT-Phase: RED

**Title:** Fresh B0 lexer/tokenizer substrate reconciliation after BYTE-MEMORY + LOCAL-MEM2REG + GEP01

**Repository:** `s1onique/polyc`

**Working copy:** `codium-polyc`

**Track:** A — language/compiler critical path

**Entry HEAD:** `456b71c0f2535c6175271d2107b67f985b4bc2c8` — contains
the GEP01 lineage (`8d04aae…936b146`) and `SHELL-INVENTORY01-CORRECTION01`
(`d0e7f4f…456b71c`).

**Predecessor substrate (all CLOSED PASS):**

* `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02` — I8/U8 byte load + byte pointer param
* `ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02` — Option-W mutable locals + mem2reg
* `ACT-POLYC-LLVM-GEP01` — bounded `U8 *base + I64 index` indexed byte load

**Primary question:**

> Can the first meaningful PolyC-written lexer/tokenizer be implemented
> **now**, using only the language/compiler substrate already present?

**Production semantic changes:** FORBIDDEN.

**New compiler feature:** FORBIDDEN.

**New LLVM capability:** FORBIDDEN.

**New Bash logic:** FORBIDDEN (no new `*.sh` files; evidence commands inline).

---

## 0. Mission

Mechanically derive the requirements of the first self-hosting lexer
and exercise those requirements through **real PolyC programs
compiled by the current compiler**.

The ACT has exactly two legitimate successful outcomes:

```text
OUTCOME A — SUBSTRATE_SUFFICIENT
  A meaningful B0 lexer can be written with the current substrate.
  NEXT:  ACT-POLYC-BOOTSTRAP01

OUTCOME B — SUBSTRATE_GAP_PROVEN
  The current substrate cannot implement B0.
  NEXT:  exactly ONE smallest missing-substrate ACT,
         mechanically named by this recon.
```

There is no outcome:

```text
"implement whatever we discover while reconning"
```

Any production change means HALT.

---

## 1. Predecessor state — frozen consumption contract

### LOCAL-MEM2REG (Option W)

```text
mutable I64 local
  entry alloca
  original-site stores
  original-site loads
  LLVM mem2reg
  LLVM-owned PHIs
```

### BYTE-MEMORY (current bounded surface)

```text
I8/U8 parameters
byte pointer parameter
load i8
ZEXT I8/U8 -> I64
SEXT I8 -> I64
bounded I64 -> I8 truncation
byte comparisons
multi-block mutable scalar state
byte store            = DEFERRED_NOT_B0_BLOCKING
```

### GEP01 (current bounded indexed byte access)

```text
U8 *src
I64 cursor
src[cursor]          ; via IR_IADD arm (dst=PTR, r1=PTR, r2=I64)
                       lowered to getelementptr i8 + load i8
inbounds             NOT asserted
non-I8 element       REJECTED
aggregate support    NONE
byte store           still DEFERRED
```

---

## 2. B0 mission freeze

B0 is NOT:

```text
full PolyC compiler
parser
AST
typechecker
IR generator
preprocessor
macro system
token array
heap-backed string library
full source-file loader
```

B0 IS:

> A PolyC-written, deterministic, token-at-a-time lexer that walks a
> caller-provided source byte buffer, maintains a cursor, recognizes a
> bounded but compiler-relevant lexical subset, and returns token
> identity plus enough scalar source metadata to prove correct token
> boundaries.

Architectural form tested:

```text
caller-owned U8 *source
caller-provided source length
I64 cursor

          ↓

      LexNext(...)

          ↓

token kind             (I64)
start offset           (I64)
length                 (I64)
optional integer value / auxiliary scalar  (I64)
new cursor             (I64)
```

The probe explicitly does NOT assume a Token struct or token array.

---

## 3. Candidate aggregate-free B0 ABI

The illustrative interface (illustrative, NOT pre-authorized syntax):

```c
I64 LexNext(
    U8  *src,
    I64  src_len,
    I64 *cursor,
    I64 *tok_start,
    I64 *tok_len,
    I64 *tok_aux
);
```

Interpretation:

```text
return value = token kind (I64 scalar)
*cursor      = first unconsumed byte
*tok_start   = source offset of token
*tok_len     = token length
*tok_aux     = optional scalar payload (e.g. TK_INT value)
```

Decisive test:

```text
Can B0 communicate useful token metadata without:
  STRUCT01
  ARRAY01
  heap allocation
  byte stores?
```

If yes, those features remain deferred.

---

## 4. Source-length policy

Default contract:

```text
src + explicit src_len          (PTR_PLUS_LENGTH)
```

Avoids NUL-terminated magic, allows bounds-aware scanning
(`cursor < src_len`), and does not depend on `0`-byte sentinels.

If current language makes PTR_PLUS_LENGTH impossible, fall back to
NUL termination only if recon proves it works; record evidence rather
than forcing the preferred model.

---

## 5. Token identity model (target)

```text
TOK_EOF         = scalar I64 constant
TOK_IDENT       = scalar
TOK_INT         = scalar (+ auxiliary value)
TOK_PUNCT       = scalar (the punctuator byte itself, or its ASCII)
TOK_ERROR       = scalar
```

No enum feature required; ordinary integer constants suffice.
Keywords at B0 may remain as TOK_IDENT (parser resolves them later) —
this ACT does not force keyword-specific IDs.

---

## 6. Token text model (target)

```text
TOKEN_TEXT_MODEL = SOURCE_SLICE(start, length)
```

Identifiers and strings refer to source bytes by offset/length.
No copying of identifier text into a heap buffer.
No byte-store required for token text representation.

---

## 7. C1 RED — lexical-demand recon (THIS PHASE)

Authoritative trailer for C1:

```text
ACT: ACT-POLYC-B0-SUBSTRATE-RECON01
ACT-Phase: RED
```

No production changes.

C1 evidence root:

```text
evidence/ACT-POLYC-B0-SUBSTRATE-RECON01/c1/
```

Required artifacts:

```text
lexer-source-inventory.txt      current C lexer enumeration
lexical-demand-matrix.tsv       per-class disposition
candidate-b0-api.txt            aggregate-free ABI candidate
current-capability-map.tsv      probe ops vs closed substrate
probe-plan.txt                  per-probe plan for C2
bootstrap-corpus.txt            frozen corpus identity
```

---

## 8. Lexical surface inventory — what the C lexer actually does

The C compiler lexer (`src/lexer.c`, 2163 LOC) recognizes, via the
top-level dispatch `lexCore` (line 1129) and its helpers:

```text
whitespace           ' ', '\t' (handled in switch; line 1161-1167)
newline              '\n', '\r' (line 1151-1159; tracked as lineno)
identifiers          [A-Za-z_$][A-Za-z0-9_$]* (lexIdentifier, line 873)
keyword resolution   via symbol_table mapGetLen lookup (line 1469)
integers             [0-9]+ with hex/0x/0b (lexNumeric, line 1076)
floats               including 0x[...] float suffixes (line 794-870)
strings              "..." with escapes (lexString, line 890; arena-allocated)
char consts          'x' / '\n' / '\xHH' (lexCharConst, line 997)
line comments        // ... \n (lexSkipCodeComment, line 762-769)
block comments       /* ... */ (line 770-792; no nesting)
single punct         ASCII byte -> TK_PUNCT
multi-char punct     ++, --, ==, !=, <=, >=, &&, ||,
                     <<, >>, <<=, >>=, +=, -=, *=, /=, %=,
                     &=, |=, ^=
preprocessor         #include/#define/#if/#ifdef/... (lexPreProcDirective)
```

Not every feature in this list is in B0 scope. This is the
demand source, not the implementation list.

---

## 9. B0 lexical-demand matrix (frozen at C1)

Disposition encoding:

```text
MUST_B0             required for the first PolyC lexer/tokenizer
DEFER_B1            recognized in the inherited lexer, deferred
NOT_IN_CORPUS       corpus does not contain it (does not block)
```

| class | example | in corpus? | B0 disposition |
| --- | --- | --- | --- |
| whitespace (sp) | ` `, `\t` | yes | MUST_B0 |
| newline | `\n`, `\r` | yes | MUST_B0 |
| identifier | `foo`, `_x9` | yes | MUST_B0 |
| keyword | `I64`, `return` | yes | MUST_B0 (handled as TOK_IDENT; parser resolves later) |
| decimal integer | `0`, `42`, `12345` | yes | MUST_B0 |
| single-char punct | `+`, `;`, `(`, `}` | yes | MUST_B0 |
| multi-char punct | `==`, `<=`, `++`, `&&`, `||` | yes | MUST_B0 (subset chosen by recon) |
| line comment | `// ...` | yes | MUST_B0 |
| block comment | `/* ... */` | yes | MUST_B0 |
| hex integer | `0xFF` | yes | DEFER_B1 (decimal-only is sufficient for B0) |
| float literal | `3.14` | no | NOT_IN_CORPUS |
| string literal | `"hello"` | yes | DEFER_B1 (recognize boundaries only; do not decode escapes; source-slice only — does NOT require byte store) |
| char literal | `'a'`, `'\n'` | yes | DEFER_B1 (recognize boundaries; record scalar byte; no escape decoding required for B0) |
| preprocessor | `#include` | no | NOT_IN_CORPUS |
| nested comment | n/a | n/a | DEFER_B1 |

This matrix is **provisional**: C2 may revise it if probes prove
that a DEFER_B1 class is actually required to keep the lexer
compiler-relevant (e.g. if the bootstrap corpus exercises a token
form we did not initially list). Any revision is recorded as
**lexical-demand-matrix.tsv.rev** with explicit reason.

---

## 10. Bootstrap corpus freeze

Three-layer corpus:

```text
Corpus A — synthetic scanner exercise
  src/tests/b0-substrate-recon01/corpus_a.HC
  Small hand-crafted byte buffer covering every MUST_B0 class.
  Length, contents, and expected token sequence are recorded in
  evidence/ACT-POLYC-B0-SUBSTRATE-RECON01/c1/bootstrap-corpus.txt.

Corpus B — small existing PolyC source fixture
  A bounded slice from src/tests/llvm-gep01/readat.HC
  (or any other small fixture we choose) — real compiler-valid source.

Corpus C — bounded slice of compiler/tooling
  A bounded slice of src/tests/llvm-byte-memory01/red_byte_to_i64.HC
  (or similar) — real source containing comments, line/block comments,
  multi-char operators, identifiers, decimal integers.
```

The chosen files and exact byte content are SHA-256-frozen in the
C1 evidence directory. No giant compiler source file is included
merely to force every lexical feature into B0.

---

## 11. Probes planned for C2

The integrated probe is a real PolyC program (`LexMain` etc.)
under `src/tests/b0-substrate-recon01/`. C2 compiles it via
`hcc --emit-llvm`, verifies with `llvm-as` and `opt --passes=verify`,
then runs it natively and compares against the frozen per-token
oracle. It produces a deterministic I64 digest of the token stream
without allocating a token array.

Per-probe files (initially sketched in C1, finalized in C2):

```text
probe_identifier.HC      identifier-start/stop boundary cases
probe_decimal_int.HC     single + multi-digit integer scanning
probe_whitespace.HC      skip space/tab/newline/CR
probe_lookahead.HC       one- and two-byte lookahead (src[c], src[c+1])
probe_line_comment.HC    // until \n or src_len
probe_block_comment.HC   /* ... */ until */
probe_punct_multi.HC     ==, !=, <=, >=, ++, --, &&, || (subset)
probe_token_at_a_time.HC integrated token-at-a-time driver
```

Each probe returns/records a deterministic scalar digest over its
inputs and is mechanically compared against a frozen oracle.

---

## 12. Feature-demand matrix (initial freeze)

For every operation the integrated probe will use, name the
already-closed substrate owner:

| operation | owner |
| --- | --- |
| I8/U8 source load | BYTE-MEMORY |
| `src[c]` indexed load | GEP01 |
| `src[c+1]` lookahead | GEP01 + IR_IADD |
| byte comparison | BYTE-MEMORY |
| I64 arithmetic (add/sub/mul) | existing scalar (CORE04-RESUME01) |
| ICMP | existing scalar |
| branch / control flow | existing scalar |
| mutable cursor (`*cur = *cur + 1`) | LOCAL-MEM2REG (Option W) |
| function calls | existing scalar |
| I64 return | existing scalar |
| I64 pointer-output store | MEMORY01 |
| I64 out-parameter return path | existing return-slot / aggregate ABI (IR-RETURN-SLOT-FORWARDING01) |

Rows marked `UNKNOWN` at C1 are recon failures until resolved.
The C2 evidence file `feature-demand-matrix.tsv` re-records this
with concrete fixture-level attribution.

---

## 13. Explicit candidate features — initial dispositions

| feature | initial disposition | basis |
| --- | --- | --- |
| STRUCT01 | NOT_REQUIRED_FOR_B0 | token-at-a-time + scalar out-params |
| ARRAY01 | NOT_REQUIRED_FOR_B0 | digest + scalar metadata |
| heap allocation | NOT_REQUIRED_FOR_B0 | caller-owned source slice |
| byte store | NOT_REQUIRED_FOR_B0 | tokens reference source slices |
| stack byte arrays | NOT_REQUIRED_FOR_B0 | no token-array needed |
| general strings | NOT_REQUIRED_FOR_B0 | source-slice tokens |
| pointer-to-pointer | NOT_REQUIRED_FOR_B0 | cursor is I64 out-param |
| I64-element GEP | NOT_REQUIRED_FOR_B0 | only byte GEP needed |
| general pointer arithmetic | NOT_REQUIRED_FOR_B0 | cursor is integer-indexed |
| bitwise ops | NOT_REQUIRED_FOR_B0 | byte compare only |
| shifts | NOT_REQUIRED_FOR_B0 | not used |
| division / remainder | NOT_REQUIRED_FOR_B0 | not used |
| switch | NOT_REQUIRED_FOR_B0 | if/else sufficient |
| enum | NOT_REQUIRED_FOR_B0 | scalar int constants sufficient |
| global mutable state | NOT_REQUIRED_FOR_B0 | cursor passed as out-param |
| function pointers / callbacks | NOT_REQUIRED_FOR_B0 | direct call |
| recursive calls | NOT_REQUIRED_FOR_B0 | single non-recursive driver |
| varargs | NOT_REQUIRED_FOR_B0 | fixed signatures |
| file I/O | NOT_REQUIRED_FOR_B0 | caller-provided buffer |

Each row is re-disposed at C2 if probes disagree. C3 explicitly
records the final disposition in `b0-decision.txt`.

---

## 14. Token-at-a-time state probe (the decisive integration test)

C2 writes a bounded PolyC program equivalent to:

```text
cursor = 0

repeat:
    kind = LexNext(src, len, &cursor, &start, &length, &aux)
    if kind == TOK_EOF: break
    digest = digest * K
    digest = digest + kind
    digest = digest + start
    digest = digest + length
    if kind == TOK_INT: digest = digest + aux

print digest
print "BYTES_CONSUMED=" cursor
```

No token array. No `malloc`. No struct unless already available
and clearly useful — and the probe must also establish whether
structs/arrays are **necessary** (not merely convenient).

The digest is evidence-only; per-token oracle comparison
(captured separately) is the real correctness test.

---

## 15. Reference oracle

For the tiny frozen corpus, the per-token expected matrix is
hand-written and committed at C2. This avoids the cost of
maintaining a duplicate PolyC reference scanner.

Comparison surface:

```text
token kind
start
length
aux (where applicable)
final cursor
```

Digest alone is insufficient for debugging.

---

## 16. Conservation (must be GREEN at C3)

```text
make clean
make
make llvm-all

llvm-gep01-test
llvm-byte-memory01-test
llvm-spike-test
llvm-intops01-test
ir-return-slot-forwarding01-test
harness-evidence-isolation-test
llvm-cap-table-verifier

shell-loc-gate

factory-v2-commit-msg-check
factory-append-only-test
factory-closure-status
gate-fast
```

Plus patch hygiene and worktree cleanliness:

```text
git diff --check HEAD^ HEAD
git status --porcelain
```

---

## 17. Production-delta gate

```text
git diff <ENTRY_HEAD>..<FINAL_HEAD> -- src/
```

must contain only test fixtures under `src/tests/`. No change to
compiler, runtime, neutral IR, backend, optimizer, parser, lexer.
If any of those change: `HALT_SCOPE_DRIFT`.

---

## 18. No new Bash

```text
no new .sh files
```

Substantive probe logic lives in `.HC` fixtures. Evidence capture
runs inline with the existing test gate conventions.

---

## 19. C2 EVIDENCE phase

Authoritative trailer:

```text
ACT: ACT-POLYC-B0-SUBSTRATE-RECON01
ACT-Phase: EVIDENCE
```

There is no IMPL commit.

C2 evidence root:

```text
evidence/ACT-POLYC-B0-SUBSTRATE-RECON01/c2/
```

Expected files (only those relevant after C1 demand freeze):

```text
probe-matrix.txt
identifier.txt
integer.txt
whitespace.txt
lookahead.txt
comments.txt
punctuator.txt
token-state.txt
token-oracle.txt
feature-demand-matrix.tsv
llvm-verify.txt
runtime.txt
missing-feature-analysis.txt
b0-decision.txt
```

---

## 20. LLVM evidence (closure-critical)

For each probe:

```text
hcc --emit-llvm
llvm-as
opt -passes=verify
```

Must succeed. Capture enough LLVM to confirm:

```text
byte indexed loads use GEP01 path
mutable locals remain verifier-clean
no unauthorized pointer integerization
no unexpected aggregate dependency
```

---

## 21. Runtime evidence

Probes run with bounded deterministic inputs.

```text
identifier cases
integer cases
whitespace cases
lookahead case
comment case
punctuator case
integrated token stream over Corpus A
integrated token stream over Corpus B
integrated token stream over Corpus C
```

Expected vs actual must be explicit. Exit code alone is not PASS.

---

## 22. Negative controls

At minimum:

```text
empty source (len = 0)              -> TOK_EOF
one-byte source                     -> single token, then EOF
invalid leading byte                -> TOK_ERROR (or EOF, per contract)
unterminated // line comment        -> consumes to src_len, then EOF
unterminated /* block comment       -> consumes to src_len, then EOF (or TOK_ERROR)
boundary-at-EOF (token ends at last byte) -> consumes exactly src_len
```

Deterministic, no crash, no verifier failure.

---

## 23. Decision algorithm

### Outcome A — SUBSTRATE_SUFFICIENT

All MUST_B0 classes compile, verify, and run correctly.
Integrated probe reproduces the frozen oracle.

```text
VERDICT = PASS
NEXT    = ACT-POLYC-BOOTSTRAP01
```

### Outcome B — one missing feature blocks B0

```text
VERDICT = HALT_SUBSTRATE_GAP
NEXT    = ACT-POLYC-<smallest-feature>
```

The next ACT is **mechanically named** by the evidence; no
speculative reuse of historical names.

### Outcome C — multiple gaps

Rank by dependency. Select the **first causal blocker**.
Record remaining gaps as unverified downstream hypotheses.

---

## 24. ARRAY01/STRUCT01 decision (must be answered at CLOSE)

```text
ARRAY01 needed before BOOTSTRAP01?   YES / NO
STRUCT01 needed before BOOTSTRAP01?  YES / NO
```

YES requires a concrete B0 source construct that cannot be
represented otherwise. The token-at-a-time/source-slice model
is the hypothesis to be disproved.

---

## 25. Allocation decision

```text
heap allocation needed before B0?    YES / NO
```

Expected NO based on source-slice tokens. Freeze only after probes.

---

## 26. Byte-store decision

```text
byte store needed before B0?         YES / NO
```

Expected NO based on source-slice tokens. If the chosen design
forces constructing mutable byte strings, this ACT HALTs with
a dedicated successor and no byte-store work here.

---

## 27. Commit topology

```text
C1 RED         ACT + demand freeze + first probes (skeleton)
C2 EVIDENCE    full probe matrix + integrated driver + oracle + LLVM
C3 CLOSE       acceptance matrix + roadmap + verdict
```

Deliberately NO IMPL commit. If an IMPL is needed, the recon
discovered its own HALT.

---

## 28. Acceptance criteria

1. AC01  GEP01 predecessor is CLOSED PASS.
2. AC02  BYTE-MEMORY predecessor remains GREEN.
3. AC03  LOCAL-MEM2REG conservation remains GREEN.
4. AC04  current compiler lexer/input model mechanically inventoried.
5. AC05  B0 mission explicitly narrower than parser/AST/compiler.
6. AC06  bootstrap corpus frozen with byte identity.
7. AC07  lexical-demand matrix complete for the corpus.
8. AC08  token-at-a-time API expressibility tested.
9. AC09  source-slice token text model tested.
10. AC10 identifier scanning tested if MUST_B0.
11. AC11 decimal integer scanning tested if MUST_B0.
12. AC12 whitespace scanning tested.
13. AC13 bounded lookahead tested when required.
14. AC14 comments tested or classified DEFER.
15. AC15 character literals tested or classified DEFER.
16. AC16 string literals tested or classified DEFER.
17. AC17 EOF/bounds behavior tested.
18. AC18 deterministic lexical-error representation tested.
19. AC19 integrated token-at-a-time probe compiles.
20. AC20 closure-critical LLVM assembles/verifies.
21. AC21 integrated runtime output matches oracle.
22. AC22 bootstrap corpus consumes exactly the expected bytes.
23. AC23 feature-demand matrix has no unowned operation.
24. AC24 ARRAY01 necessity explicitly YES/NO with evidence.
25. AC25 STRUCT01 necessity explicitly YES/NO with evidence.
26. AC26 heap-allocation necessity explicitly YES/NO.
27. AC27 byte-store necessity explicitly YES/NO.
28. AC28 no production semantics changed.
29. AC29 no new >50 LOC shell.
30. AC30 all compiler conservation gates pass.
31. AC31 Factory gates pass.
32. AC32 commit-range patch hygiene truthful.
33. AC33 working tree clean.
34. AC34 exactly one next ACT selected.

---

## 29. HALT taxonomy (use the narrowest truthful result)

```text
HALT_SUBSTRATE_GAP
HALT_B0_CONTRACT_AMBIGUOUS
HALT_AGGREGATE_REQUIRED
HALT_BYTE_STORE_REQUIRED
HALT_ALLOCATION_REQUIRED
HALT_POINTER_SEAM_REQUIRED
HALT_INTEGER_OP_REQUIRED
HALT_CONTROL_FLOW_REQUIRED
HALT_LLVM_VERIFY
HALT_RUNTIME_MISMATCH
HALT_CONSERVATION_REGRESSION
HALT_SCOPE_DRIFT
```

Stop at the first causal blocker.

---

## 30. Explicit non-goals

```text
BOOTSTRAP01 itself
ARRAY01
STRUCT01
BYTE-STORE01
a string-library ACT
a malloc ACT
a parser
a preprocessor
a macro engine
a source-file loader
a tooling-runtime ACT
a Bash migration
a general language-completeness audit
```

Track B (`codium-polyc2`) remains independent.

---

## 31. Required final report

VERDICT, IDENTITY (ENTRY_HEAD / C1_RED / C2_EVIDENCE / C3_CLOSE /
FINAL_HEAD / WORKTREE), B0 CONTRACT (input model, token delivery,
token kind, token text model, metadata model, corpus), LEXICAL DEMAND
(whitespace, identifiers, keywords, integers, punctuators,
multi-char operators, line comments, block comments, char literals,
string literals, EOF/error), SUBSTRATE PROBES (byte load, indexed
load, lookahead, arithmetic, comparisons, mutable cursor, out params,
control flow), INTEGRATED TOKEN PROBE (compile, llvm-as, opt verify,
runtime, oracle parity, bytes consumed, final cursor), FEATURE
DECISIONS (ARRAY01, STRUCT01, BYTE_STORE, HEAP_ALLOCATION,
NEW_INTOPS, OTHER_GAP), PRODUCTION DELTA, SHELL DELTA, GATES,
PATCH HYGIENE, RESIDUE, ROADMAP STATE, NEXT ACT.

Expected PASS shape:

```text
VERDICT = PASS
ROADMAP STATE = CLOSED
NEXT ACT = ACT-POLYC-BOOTSTRAP01
```
