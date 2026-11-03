# CORRECTION03 C4 CHRONOLOGY AND ACCOUNTING CORRECTION

This file is FORWARD-ONLY evidence. It does not modify, rewrite, or
endorses any earlier committed artifact. The C0, C1, C2 and C3 commits
and their source bytes are preserved exactly as committed.

## 1. THE HISTORICAL CHRONOLOGY

The independent review's P2 finding was that the C1 contract could not
have been frozen before the implementation, because the C1 evidence
files were FIRST committed alongside the C2 implementation.

This is CONFIRMED by the Git object store. The complete commit sequence
for this ACT's evidence tree is:

```text
158709c7101f0d01959f9978e561c07122d7bee1  RED: reproduce emission precedence regression
cb6ffe9c5ec9d0a515a0ae28517e9e03700e3ff6  IMPL: preserve C-oracle emission precedence
cdd927ac804fe007a9440d577929984bbf4f08f8  EVIDENCE: prove emission precedence and C dormancy
```

There is NO separate C1 EVIDENCE commit. The C1 evidence files

```text
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c1/c-oracle-precedence.tsv
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c1/comparator-contract.md
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c1/precedence-contract.md
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c1/manifest.txt
```

were FIRST ADDED by the C2 IMPL commit `cb6ffe9c5ec9d0a515a0ae28517e9e03700e3ff6`,
which is the SAME commit that changed
`tools/bootstrap/selfhost-driver-wp001.HC`.

### THE CORRECTED CLAIM

The historically accurate statement is:

```text
The C1 precedence contract and the C2 implementation change were FIRST
COMMITTED TOGETHER, in the single commit
cb6ffe9c5ec9d0a515a0ae28517e9e03700e3ff6.
```

The historically INACCURATE statement -- and the one this ACT's own
C3 evidence must not repeat -- is:

```text
The C1 contract was frozen independently of, and before, the
implementation change.
```

NO claim of pre-implementation freezing is made anywhere in this ACT's
forward-only evidence. The C1 content itself was derived from the
selector-OFF C oracle's SOURCE and OBSERVED behaviour, and the C1
precedence table's eight rows were individually re-verified by the
independent review before this correction; what is NOT claimed is that
they were committed before the implementation.

The independent verification of the C1 CONTENT is recorded in
`c4/pre-implementation-freeze-retraction.md`.

## 2. THE 15-VERSUS-8 ABI CASE ACCOUNTING

The C2 README states:

```text
The direct compiled PolyC ABI probe also passed 15/15 cases, including the
six mixed object/assembly cases.
```

The SAME C2 commit's own green log states:

```text
CORRECTION03_ABI_PROBE_CASES	8
CORRECTION03_ABI_PROBE_FAILURES	0
```

The claim of "15/15" was INCORRECT. The compiled ABI probe had EIGHT
cases, not fifteen. The number fifteen belongs to the CORRECTION02
negative-control roster, which is a DIFFERENT measurement on a DIFFERENT
subject, and it does not apply to the CORRECTION03 ABI probe.

The ORIGINAL C2 claim is NOT changed retroactively. It remains in the
committed `c2/README.md` exactly as written, because F14 forbids
rewriting historical evidence. This file records the CORRECTION.

### THE CORRECTED ACCOUNTING

| subject | claimed in the original C2 README | measured in the C2 green log | corrected |
| --- | --- | --- | --- |
| CORRECTION03 artifact matrix cases | 8 | 8 | 8 |
| CORRECTION03 ABI probe cases | 15 | 8 | 8 |

### THE FORWARD-ONLY EXTENSION

This ACT's C4 remediation EXTENDS the ABI probe from EIGHT cases to
SIXTEEN cases. The extension is NEW, FORWARD-ONLY, supplemental evidence.
It is NOT a correction of the C2 measurement: the C2 measurement was
eight cases and remains eight cases.

The C4 ABI probe covers:

```text
the eight mandatory precedence cases (unchanged from C2/C3)
the DYNAMIC LIBRARY domain, in two argv shapes
the EXECUTABLE (default) domain, in two argv shapes
the DYNAMIC LIBRARY domain outranking the EXECUTABLE domain
the OBJECT domain outranking the DYNAMIC LIBRARY domain
an ARITY VIOLATION failing closed to the UNKNOWN emission
an argv with NO SOURCE FILE failing closed to the UNKNOWN emission
```

The full C4 case roster is recorded in `c4/abi-domain-coverage.tsv`.

## 3. THE SELF-REFERENTIAL MANIFEST HASHES

The committed `c2/manifest.txt` and `c3/manifest.txt` each list their OWN
sha256. A file cannot contain its own hash: the hash depends on the file
content, which would depend on the hash. The claimed hashes are
therefore WRONG, and they were wrong at the moment they were committed.

The measured discrepancy is recorded in `c4/self-referential-manifest-hashes.tsv`.

The committed manifests are NOT rewritten. A FORWARD-ONLY covering
manifest is added instead, and it EXCLUDES ITS OWN HASH by construction.
