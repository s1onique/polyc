# ACT-POLYC-BOOTSTRAP01 — B0 compiler-shaped bootstrap

> **CORRECTED AUTHORING COPY.** This file is a structurally
> reordered copy of `docs/acts/ACT-POLYC-BOOTSTRAP01.md`
> deposited by `ACT-POLYC-BOOTSTRAP01-CORRECTION01`. The
> original ACT document remains in place at
> `docs/acts/ACT-POLYC-BOOTSTRAP01.md` as F14 historical
> evidence; its section ordering is preserved there. This
> copy is the structurally-correct reading: sections §0
> through §37 are emitted in numerical order, followed by
> the "Execution metadata" and "Closure handoff" blocks.
>
> **No semantic content was changed.** Only the section
> ordering was repaired.

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** B0 compiler-shaped bootstrap — implement a
PolyC-written allocation-free lexer/tokenizer, compile it
through the proven substrate, and prove deterministic
token-stream semantics.

**Class:** BOOTSTRAP / SELF-HOSTING-SUBSTRATE / B0

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor chain:**

- `ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01` (CLOSED PASS at C6)
- `ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01` +
  bounded corrections
- `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` + closure-truth
  corrections

**Current predecessor board signal:** the AArch64 production
delta is mechanically GREEN; the remaining GEP01 D1/D2
failures are classified `GOVERNANCE / BLOCKS_NEXT=NO` unless
this ACT mechanically proves that B0 depends on them.

**Production semantic changes:** AUTHORIZED only for the
B0 lexer/tokenizer implementation and the minimum
test/build seam required to compile/run it.

**Production changes forbidden:**

- Parser implementation
- AST implementation
- Code generation changes
- LLVM backend semantic widening
- Native backend semantic widening
- AOT relocation semantic changes
- Allocation/runtime widening (unless C1 mechanically
  proves allocation is unavoidable; if so HALT before
  mutation)
- GEP01 gate repair (unless C1 mechanically proves B0
  depends on the broken GEP01 infrastructure itself rather
  than merely the already-proven compiler capability)
- Historical evidence mutation

---

## 0. Mission

Advance PolyC from "compiler substrate proven" to the first
**compiler-shaped program written in PolyC**.

B0 is:

```text
source bytes
    ↓
PolyC-written lexer/tokenizer
    ↓
caller-owned Token[]
    ↓
## 1. Frozen B0 architecture

```text
B0  COMPILER-SHAPED
    PolyC-written lexer/tokenizer
    bytes in
    deterministic Token stream out

B1  bounded subsystem self-host

B2  first self-host

B3  bootstrap stability
    stage-2 ~= stage-3
```

This ACT targets **B0 only**.
## 2. Golden B0 constraint: allocation-free first

The default design is allocation-free:

```text
BootstrapLex(
    U8   *src,
    I64   src_len,
    BootstrapToken *out,
    I64   out_cap,
    I64  *out_count
)
```

Ownership contract is frozen:

```text
source storage      = caller owned
token storage       = caller owned
lexer heap allocs   = 0
hidden global arena = forbidden
output resizing     = forbidden
```

If fresh recon proves the compiler/language cannot express
B0 without dynamic allocation:

```text
HALT_ALLOCATION_SUBSTRATE_REQUIRED
HALT_CLASS  = DEPENDENCY
BLOCKS_NEXT = YES
```

Do not silently add allocator semantics.

## 3. Token representation

```text
Token {
    kind
    start
    len
}
```

Required semantics:

```text
kind   = bounded token-kind enum/integer
start  = byte offset into caller source
len    = token byte length
```

Tokens must not own copied lexeme strings. The source
buffer remains the authority for lexeme bytes.

## 4. Frozen lexical subset

```text
TK_EOF       = 0
TK_IDENT     = 1
TK_INT       = 2
TK_LPAREN    = 3
TK_RPAREN    = 4
TK_LBRACE    = 5
TK_RBRACE    = 6
TK_LBRACKET  = 7
TK_RBRACKET  = 8
TK_COMMA     = 9
TK_SEMI      = 10
TK_PLUS      = 11
TK_MINUS     = 12
TK_STAR      = 13
TK_SLASH     = 14
TK_ASSIGN    = 15
```

Whitespace skipped: `' '`, `'\t'`, `'\n'`, `'\r'`.

Identifier grammar: `[A-Za-z_][A-Za-z0-9_]*`.

Integer grammar: `[0-9]+`.

Everything else: `LEX_UNSUPPORTED_BYTE` (status code 2).

Do not add in B0: comments, strings, character escapes,
floating literals, numeric bases, preprocessor, keywords
as separate token classes, multi-character operators,
Unicode identifier rules — unless F2 proves one is
unavoidable.

## 5. C1 RED — successor dependency determination

Create `evidence/ACT-POLYC-BOOTSTRAP01/c1/successor-dependency.txt`
with these exact logical outputs:

```text
B0_USES_INDEXED_BYTE_ACCESS       = YES | NO
B0_REQUIRES_GEP_COMPILER_FEATURE  = YES | NO
B0_REQUIRES_GEP01_HARNESS         = YES | NO
B0_REQUIRES_GATE_PUSH             = YES | NO

GEP01_D1_BLOCKS_B0                = YES | NO
GEP01_D2_BLOCKS_B0                = YES | NO
```

### Dependency rule

A dependency is **not** established merely because B0
exercises a compiler feature also exercised by GEP01.

```text
B0 uses indexed byte access
        ≠
B0 depends on llvm-gep01-test.HC infrastructure
```

`B0_REQUIRES_GEP01_HARNESS=YES` requires mechanical
evidence such as:

- B0's authoritative build invokes that harness; or
## 6. C1 dependency decision matrix

### Outcome A — expected useful path

```text
B0_REQUIRES_GEP_COMPILER_FEATURE = YES
B0_REQUIRES_GEP01_HARNESS        = NO
GEP01_D1_BLOCKS_B0               = NO
GEP01_D2_BLOCKS_B0               = NO
```

Meaning: the production GEP/byte substrate is used, but
the broken GEP01 verification infrastructure is not a
runtime/build dependency of B0. Proceed to B0
implementation.

### Outcome B — real predecessor dependency

If either D1 or D2 is mechanically required:

```text
B0_REQUIRES_GEP01_HARNESS = YES
```

then close C1 with:

```text
ACT-Verdict: HALT_GEP01_DEPENDENCY_REQUIRED
HALT_CLASS: DEPENDENCY
BLOCKS_NEXT: YES
NEXT_ACT: ACT-POLYC-INTEGRATION-GEP01-GATE-RECOVERY01
```

Do not implement B0 in the same turn.

### Outcome C — no GEP dependency

```text
B0_REQUIRES_GEP_COMPILER_FEATURE = NO
```

Record it and continue. Do not add artificial GEP usage
merely to exercise the substrate.


deterministic token stream
```

The B0 program must:

- be written in PolyC/HolyC accepted by the current compiler;
- consume a caller-provided byte buffer plus explicit length;
- write tokens into a caller-provided output array;
- return a mechanically checkable status/count;
- compile through the current production compiler;
- lower through the current backend substrate;
- link and execute;
- produce token streams equivalent to an independent oracle
  for the frozen B0 lexical subset.

B0 deliberately does **not** mean: parser, AST, semantic
analysis, code generation, compiler executable, stage-2
compiler, stage-3 compiler, full self-host. Those belong to
later B1/B2/B3 work.

## 7. C1 RED — freeze semantic oracle before implementation

Create an independent reference implementation or oracle
fixture in C. It must not share the B0 PolyC implementation
logic textually.

```text
tools/quality/bootstrap01-lexer-oracle.c
```

Input/output contract:

```text
stdin/file/argv fixture
    ↓
reference lexer
    ↓
ordinal kind start len
```

The oracle must exist **before** the PolyC implementation
lands.

## 8. C1 frozen fixture matrix

At minimum freeze these cases:

| ID  | Input                                         | Required semantic point    |
| --- | --------------------------------------------- | -------------------------- |
| T01 | `foo`                                         | single identifier          |
| T02 | `_foo9`                                       | identifier grammar         |
| T03 | `12345`                                       | integer                    |
| T04 | `foo 123`                                     | whitespace transition      |
| T05 | `a+b*c;`                                      | punctuation sequence       |
| T06 | `f(x,y)`                                      | parens/comma               |
| T07 | `a[12]`                                       | indexed punctuation        |
| T08 | `{a=1;}`                                      | braces/assignment          |
| T09 | ` \t\nfoo\r`                                  | all frozen whitespace      |
| T10 | `` empty                                      | EOF only                   |
| T11 | `abc$def`                                     | unsupported-byte error     |
| T12 | tiny output capacity                          | bounded overflow path      |
| T13 | nonzero source slice/start if API supports it | pointer/offset correctness |
| T14 | long identifier within caller buffer          | loop/backedge behavior     |

No fuzzing is required for B0 closure.

## 9. Output-capacity contract

The lexer must fail closed when token capacity is
insufficient. No buffer overwrite.

Frozen result codes:

```text
LEX_OK                = 0
LEX_OUTPUT_FULL       = 1
LEX_UNSUPPORTED_BYTE  = 2
LEX_INVALID_INPUT     = 3
```

Required negative control: T12 (out_cap = N - 1) returns
`LEX_OUTPUT_FULL` with no write beyond `out_cap` and
`out_count <= out_cap`.

## 10. No hidden C implementation in the B0 subject

Forbidden:

```text
PolyC wrapper calling a C lexer
C lexer linked behind a thin PolyC façade
generated token stream fixture presented as execution
host-side pretokenization
shell parsing
Python parsing
```

C may be used only as: independent reference oracle, test
driver, native linkage glue where unavoidable.

The lexing state machine itself must execute from code
compiled from the PolyC B0 source.

## 11. F2 capability recon

Create `evidence/ACT-POLYC-BOOTSTRAP01/c1/b0-capability-map.txt`
with each capability mapped to a substrate ACT. See C1
packet for the actual table.

## 12. Allocation decision gate

`B0_ALLOCATION = NOT_REQUIRED` is mechanically frozen for
the intended design. If not:

```text
HALT_ALLOCATION_SUBSTRATE_REQUIRED
```

## 13. C2 implementation

Expected new subject:

```text
tools/bootstrap/bootstrap01-lexer.HC
```

Expected API shape (exact syntax may adapt to real PolyC
declarations):

```text
I64 BootstrapLex(
    U8 *src,
    I64 src_len,
    BootstrapToken *out,
    I64 out_cap,
    I64 *out_count
)
```

Implementation requirements:

- single forward scan;
- no recursion required;
- no dynamic allocation;
- no source mutation;
- no global mutable lexer state;
- bounded writes;
- deterministic result.

## 14. Token kind stability

Token kind numbers are explicit and frozen once C2 lands.

The oracle and PolyC subject must compare through an
explicit B0 token ABI.

## 15. C2 runner

Create one deterministic runner that builds the subject,
runs all fixtures, captures actual tokens, compares to
oracle, prints exact totals, exits nonzero on mismatch.

## 16. Required subject pipeline

```text
PolyC B0 source
   ↓
hcc (native path)              → a.out
hcc --emit-llvm (LLVM path)    → .ll
   ↓
llvm-as → opt --passes=verify
   ↓
native object/executable
   ↓
run fixtures
   ↓
compare token stream to independent C oracle
```

The B0 program proves the LLVM/self-host substrate where
available; the native path remains the authoritative
execution seam.

## 17. Differential oracle

For every T01–T14 applicable case:

```text
REFERENCE_STATUS == SUBJECT_STATUS
REFERENCE_COUNT  == SUBJECT_COUNT

for each token i:
    REF.kind  == SUB.kind
    REF.start == SUB.start
    REF.len   == SUB.len
```

A matching return code without matching token contents is
not PASS. A matching token count without matching spans is
not PASS.

## 18. Determinism gate

Every successful fixture runs at least twice from freshly
initialized output memory.

## 19. Source immutability gate

For at least one fixture, hash/copy source before, run
BootstrapLex, compare source after. `SOURCE_MUTATED = NO`.

## 20. Boundary controls

Required negative controls:

```text
NC1 src=NULL, len>0           (if representable)
NC2 out=NULL, out_cap>0       (if representable)
NC3 out_count=NULL            (if representable)
NC4 src_len<0                 (if representable)
NC5 out_cap<0                 (if representable)
NC6 unsupported byte          (T11)
NC7 output full               (T12)
NC8 empty source              (T10)
```

If PolyC's safe calling conventions make some null case
impossible/unrepresentable, document that mechanical fact
rather than inventing a fake fixture.

## 21. B0 compiler-feature fence

This ACT must not expand the compiler merely because the
B0 implementation initially uses an unsupported convenience
construct. The compiler should be widened only if the
feature is **intrinsic to B0's frozen mission**. Otherwise:

```text
HALT_BOOTSTRAP_SUBSTRATE_GAP
HALT_CLASS: DEPENDENCY
BLOCKS_NEXT: YES
```

## 22. GEP01 D1/D2 handling

Per C1 outcome, throughout this ACT:

```text
GEP01 D1 = NON_BLOCKING_GOVERNANCE_RESIDUE
GEP01 D2 = NON_BLOCKING_GOVERNANCE_RESIDUE
```

Do not repeatedly re-litigate them in C2/C3/C4.

## 23. `gate-push` handling

`gate-push` status is captured, but it is not automatically
a B0 closure predicate. Per C1:

```text
B0_REQUIRES_GATE_PUSH = YES|NO
```
## 24. Canonical B0 semantic acceptance criteria

See the AC01..AC44 list in
`evidence/ACT-POLYC-BOOTSTRAP01/c4/acceptance-matrix.txt`.

## 25. Strong B0 closure criterion

PASS requires the conjunction captured in the closure
truth block at `evidence/ACT-POLYC-BOOTSTRAP01/c4/closure-summary.txt`.



- B0 consumes its generated artifact/output; or
- the unresolved D1/D2 facility is itself needed to
  compile, link, execute, or verify B0; or
- without that facility B0 semantic correctness cannot be
  mechanically established by this ACT's own direct
  witness.

A prose statement that "GEP comes before bootstrap" is not
sufficient under F-MECHANICAL-BLOCKING.

## 26. Fresh-tree evidence protocol

Before authoritative C3: `make clean`. Rebuild required
compiler/runtime artifacts through the canonical build
seam. Delete all B0 intermediate artifacts (`.ll`, `.bc`,
`.o`, executables, oracle binaries, captured token outputs
generated by an earlier run). Rebuild and rerun.

## 27. C3 runtime witness

C3 includes one human-readable combined witness plus
equivalent machine-comparison totals for every frozen
fixture.

## 28. Required evidence packet

See per-phase directories
`evidence/ACT-POLYC-BOOTSTRAP01/c{1,2,3,4}/`. Plus
`evidence/ACT-POLYC-BOOTSTRAP01/HANDOFF.md`.

## 29. Production file scope

Authorized production additions:

- `tools/bootstrap/bootstrap01-lexer.HC`
- `tools/bootstrap/bootstrap01-lexer-defs.HH` (optional)

Test/oracle additions:

- `tools/quality/bootstrap01-lexer-oracle.c`
- `tools/quality/bootstrap01-lexer-test.HC` (driver)

Conditionally: `Makefile` (one small deterministic B0 test
target).

No compiler source file is pre-authorized.

## 30. Build target

If Makefile integration is warranted, prefer:

```text
make bootstrap01-test
```

with deterministic output:

```text
BOOTSTRAP01_PASS=<N>
BOOTSTRAP01_FAIL=0
STATUS=PASS
```

No new shell harness >50 LOC.

## 31. No replacement of the production lexer yet

Even on PASS:

```text
current compiler lexer = unchanged
```

B0 proves a PolyC-written lexer can exist. It does **not**
switch the production compiler to use it.

## 32. HALT taxonomy

- `HALT_GEP01_DEPENDENCY_REQUIRED` — C1 proves B0 requires
  the broken GEP01 infrastructure.
- `HALT_ALLOCATION_SUBSTRATE_REQUIRED` — allocation is
  mechanically unavoidable for the frozen B0 mission.
- `HALT_BOOTSTRAP_SUBSTRATE_GAP` — a compiler feature
  genuinely required by B0 is missing.
- `HALT_BOOTSTRAP_SEMANTIC_MISMATCH` — B0 compiles/runs but
  differs from the independent oracle.
- `HALT_BOOTSTRAP_NONDETERMINISTIC` — repeated executions
  produce different semantic token streams.
- `HALT_OUTPUT_BOUNDARY_VIOLATION` — out-capacity negative
  control overwrites or reports impossible state.
- `HALT_SCOPE_EXPANSION_REQUIRED` — correct repair
  requires parser/AST/codegen/compiler semantic work
  outside frozen scope.

Historical whitespace, stale captions, old trailer defects,
broad digest warnings, and already-classified GEP01 D1/D2
with no B0 dependency: `NON_BLOCKING_GOVERNANCE_RESIDUE`.

## 33. Commit topology

```text
C1 RED
C2 IMPL
C3 EVIDENCE
C4 CLOSE
```

## 34. Push policy

B0 closure and push permission are separate decisions. If
`ACT-Verdict = PASS` but canonical pre-push still fails
solely on a previously classified non-B0 GEP01 governance
residue: do not bypass pre-push; do not use `--no-verify`;
do not force-push.

## 35. B0 PASS roadmap transition

On PASS:

```text
P4 SELF-HOSTING SUBSTRATE        GREEN FOR B0

B0 BOOTSTRAP01
  POLYC_LEXER                    PASS
  BYTES_IN                       PASS
  TOKEN_STREAM_OUT               PASS
  DETERMINISTIC                  PASS
  ALLOCATION                     NOT_REQUIRED
  LLVM_COMPILE_VERIFY_RUN        PASS (path-dependent)

NEXT:
  B1 bounded subsystem self-host
```

## 36. B1 handoff question

C4 recommends a B1 ACT only after evidence identifies the
best bounded next subsystem. Candidate question:

```text
Can the proven B0 lexer replace one bounded production lexer
path and pass differential tests against the current compiler?
```

## 37. Closure truth block

On PASS, freeze exactly the semantic shape captured in
`evidence/ACT-POLYC-BOOTSTRAP01/c4/closure-summary.txt`.

---

## Execution metadata

Execution identity is stored in Git commit trailers.

Every ACT commit:

```text
ACT: ACT-POLYC-BOOTSTRAP01
ACT-Phase: RED|IMPL|EVIDENCE|CLOSE
```

CLOSE additionally:

```text
ACT-Verdict: <exact verdict>
```

The original authorization artifact remains historically
stable; there is no OPEN -> PASS / HALT mutation. The ACT
document is NOT modified at closure.

## Closure handoff

Use the Factory v2 HANDOFF template at
`docs/factory/HANDOFF-TEMPLATE.md` (Factory v2 section).
Reviewers run:

```sh
sh scripts/quality/factory-v2-range-check.sh ACT-POLYC-BOOTSTRAP01 HEAD
```


A `YES` requires a demonstrated successor dependency. If
`NO` and gate-push fails solely because of already-classified
GEP01 D1/D2: ACT B0 semantic closure may still PASS;
gate-push status is recorded honestly; no push is performed
unless the push gate itself passes.

