# C1 — object, producer and target plan

**Frozen at C1.** The C2 implementation must produce exactly these
artifacts, from exactly these producers, and must measure them.

## 1. Artifacts

| Artifact | Path | Producer | Role |
|----------|------|----------|------|
| PolyC CPA subject | `build/selfhost-abi-cpa-subject.o` | `$(BOOTSTRAP_STAGE0_HCC)` (stage0) | defines `_AbiCpaShouldPrintAst` |
| C host adapter | `build/CMakeFiles/hcc.dir/abi-cpa-host.c.o` | `cc` (the host C compiler) | defines `AbiCpaIssueAst`, `AbiCpaAstKind`, `AbiCpaRetireAst`, `AbiAbiVersion` |
| Consumer TU | `build/CMakeFiles/hcc.dir/compile.c.o` | `cc` | imports `_AbiCpaShouldPrintAst` in the ON configuration |
| Production binary | `./hcc` | `cc` (link) | contains both, and the call is reachable from `-ast` |

## 2. Producer identity

The stage0 producer is the **same** digest-bound binary that produces the
nine existing parser subjects. The C2 evidence records the digest of the
producer that actually built the subject; a subject whose producer digest
does not appear in the C2 manifest is rejected.

**Measured at C1.** The canonical checkout carries a *warm* stage0 binary
(`build/host-stage0/hcc`, digest
`4264610a6286f603503a69ad57411910fe4207db9eade6915be675a38444fd02`) that
predates the current entry source; the **fresh** stage0 built from the
entry tree in the isolated G0 worktree digests
`ef510616f0cb15aeb00531883e293612aba08e143bd916d47ecc2ee10e923b72`.

```text
warm  canonical build/host-stage0/hcc  4264610a6286f603503a69ad57411910fe4207db9eade6915be675a38444fd02
fresh G0 worktree  build/host-stage0/hcc  ef510616f0cb15aeb00531883e293612aba08e143bd916d47ecc2ee10e923b72
warm  canonical ./hcc                   9e50565b9235ae2939b2333580b45956c3589dddc972e9f4bf6b8cbd2563d90a
fresh G0 worktree  ./hcc                c10034ee7f028cd1d0ad2f32805e496277d0a93a5c4b5e80e3d8a5c6b47f14bc
```

This difference is exactly the F9 "warm tree" hazard the repository
already documents: a warm build directory is **not** evidence about the
current tree. Every producer identity in the C2/C3 evidence is therefore
taken from a **freshly built** tree, and the C2 build is forced to rebuild
the stage0 producer from the current source rather than reusing the warm
binary.

The same applies to the production `./hcc`: the canonical checkout's binary
is warm and is NOT the G0 oracle. The G0 oracle used throughout C1/C2/C3
is the freshly built compiler in the isolated worktree, digest
`c10034ee7f028cd1d0ad2f32805e496277d0a93a5c4b5e80e3d8a5c6b47f14bc`.


## 3. Target

```text
target triple     arm64-apple-darwin
host arch         arm64 (uname -m)
compiler --version reports: arch: aarch64-apple-darwin
object format     Mach-O
symbol decoration one leading underscore
```

The subject object is architecture-checked at build time, exactly like the
nine existing subjects. A wrong-architecture object is rejected, never
linked.

## 4. Independent producers for G1/G2/G3

The C3 phase needs **three distinct producer executables** for the same
PolyC source:

| Generation | Configuration | Producer of the CPA subject | Producer of the compiler |
|------------|---------------|------------------------------|--------------------------|
| G0 | selector `OFF` | none (no subject exists) | the C-only production compiler |
| G1 | selector `ON` | the stage0 producer | the production `./hcc` |
| G2 | selector `ON` | the **production `./hcc`** | the production `./hcc`, in an isolated build root |
| G3 | selector `ON` | a **separately built bootstrap-generation** compiler | the production `./hcc` |

Each generation records the digest of every distinct producer executable.
If G1/G2/G3 producer independence cannot be achieved, the ACT **HALTs**
with the actual provenance blocker. The same binary is never counted three
times, and independence is never manufactured by renaming a path.

Deterministic identical subject objects are permitted when the producer
binaries are distinct — the *producer* identity is what is being varied.

## 5. The four-configuration differential

All four generations are executed against the frozen nine-witness corpus
(`c1/frozen-witness-corpus.tsv`) with exact stdout, stderr, exit status and
output-content identity, and all **twelve ordered pairs** are compared.
The prior `-ast` observable and the whole parser suite are preserved.

## 6. Causal experiments (C3)

Two new experiments, in isolated detached worktrees or equivalent isolated
build roots, with execution IDs distinct from IMPLEMENT01's historical
experiments:

1. **PolyC-authoritative mutation** — mutate only the selected PolyC
   predicate in the *new production* source
   (`tools/bootstrap/selfhost-abi-compile-print-ast.HC`), e.g. change the
   `AST_EXTERN_FUNC` visibility classification; rebuild the actual subject
   and the production compiler. The subject digest must change; the host
   object and the nine other subject objects must not; a frozen real `-ast`
   witness must change; and source, object, binary and witness must be
   restored to their pristine identities.
2. **Host-accessor mutation** — mutate the C host accessor's returned AST
   kind without modifying the PolyC predicate. The host digest must change;
   the PolyC object must remain unchanged; a frozen witness must change in
   the expected causal direction; and the host must be restored
   byte-identically.

Plus a **C-dormancy anti-control**: mutate only the legacy C decision
inside the selector-OFF branch, rebuild both C-OFF and production-ON.
C-OFF must change a causal witness; ON must remain equivalent and produce
a byte-identical ON `compile.c.o` if the mutant only modifies compiled-out
source. If this property cannot be demonstrated, the ACT reports the exact
cause and HALTs rather than claiming legacy retirement.
