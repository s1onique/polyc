# ACT-POLYC2-DAFNY-PROOF-MVP01 — Closure Report

## VERDICT

```
VERDICT=PASS_MODEL_PROOF
EVIDENCE_STRENGTH=MODEL_PROOF
```

## Identity

| Field                | Value                                                       |
|----------------------|-------------------------------------------------------------|
| BRANCH               | harness/codium-polyc2                                       |
| BASELINE_HEAD        | 648bd3c46c79d7ec70e3898ac77d705f9038e20b                   |
| ACT_BASE_COMMIT      | 648bd3c46c79d7ec70e3898ac77d705f9038e20b                   |
| SUBJECT_FILE         | formal/dafny/identifier-scan.dfy                            |
| SUBJECT_SHA256       | f6633cb4f61f6556e1b04d24c2bc085aa6916f9ce107b7969166d660f314f7f0 |
| SUBJECT_SHA256_RED   | 82a4fb607b17dd5e920cfd6d11da35455b4496fc5766422610e90b46f4674711 |
|                       | (pre-comment-edit hash; both digests correspond to           |
|                       | a model that verifies 17 / 0 / 0 with the pinned             |
|                       | Dafny 4.11.0 toolchain)                                     |
| DAFNY_VERSION        | 4.11.0 (release v4.11.0)                                    |
| DAFNY_VERSION_FULL   | 4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2            |
| Z3_VERSION           | 4.12.1                                                      |
| WORKTREE_PRE         | clean                                                       |
| WORKTREE_POST        | clean                                                       |
| CORRECTION_ACT       | ACT-POLYC2-DAFNY-PROOF-MVP01-CORRECTION01                   |
|                       | (closes in same commit batch)                              |

## Entry / Predecessor Gates

- `git status --short` was empty before mutation (F1 satisfied).
- `git rev-parse HEAD` recorded in baseline.txt.
- Previous ACT (ACT-POLYC2-CODIUM-HARNESS-UPSTREAM-RESYNC01)
  closed cleanly; its HANDOFF/REPORT are present.
- No prior Dafny proof existed; this ACT is the first
  formal-proof ACT in the codium-polyc2 harness.

## Toolchain (Pinned)

Dafny 4.11.0 macOS-arm64 standalone distribution
extracted under `tools/dafny/dafny-4.11.0/`:

```
dafny executable: tools/dafny/dafny-4.11.0/dafny/dafny
dafny --version  = 4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2
z3 binary       : tools/dafny/dafny-4.11.0/dafny/z3/bin/z3-4.12.1
z3 -version     : Z3 version 4.12.1 - 64 bit
```

Recorded provenance identities (NOT runtime-enforced;
runtime enforcement is the version identity check +
the explicit --solver-path binding, see I1/I2/I7):

```
DAFNY_DISTRIBUTION_ARCHIVE_SHA256 = c90c75e7d5db9c6ccbb7127840dfe43f0ac938b039a7ebed146d8ead383a572f
DAFNY_DRIVER_SHA256               = 5d02cbb88300aef0726e933bd6f19754960b7409a9e0e2212a5e07edd1686012
Z3_VERSION                        = 4.12.1
```

The Dafny distribution archive digest matches the
GitHub release-asset digest; the Dafny driver
executable hash is computed at correction time.

Both binaries are Mach-O arm64 (verified via `file`).

Distribution was downloaded via gh-proxy.com
(mirror of GitHub release CDN) because direct
GitHub release-asset downloads were timing out on
this host.

## Lexical Contract Freeze

Source of truth: `src/lexer.c` lines 874-961
(lexIdentifier, default ctype path) and the
dispatcher gate at lexCore default arm
(`if (isalpha(ch) || ch == '_') { lexIdentifier(l, ch); }`).

Frozen byte-domain predicates (no ctype.h, no Unicode):

```
prod_is_ident_start(b)  = (b == '_' || isAsciiAlpha(b))
prod_is_ident_rest(b)   = (isAsciiAlpha(b) || isAsciiDigit(b)
                          || b == '_' || b == '$')
```

Bytes >= 0x80 are NEVER classified as identifier-
start or identifier-continue under the frozen
contract.

Production evaluates under the "C" locale, where
isalpha/isalnum give the ASCII subset. The Dafny
model asserts the ASCII contract only.

### Claim boundary (CORRECTION01)

```
MODEL_CHARACTER_DOMAIN                  = BYTE_0_255
FROZEN_IDENTIFIER_GRAMMAR               = ASCII
ASCII_PRODUCTION_CORRESPONDENCE_CLAIM   =
    CTYPE_C_LOCALE_FOR_ASCII_INPUTS
NON_ASCII_PRODUCTION_CORRESPONDENCE_CLAIM =
    NOT_CLAIMED
CTYPE_SIGNED_CHAR_UB_EXCLUDED_FROM_MODEL = true
```

The Dafny model does NOT formalise the C standard's
"argument representable as unsigned char" rule
(ISO C 7.4). Production passes `char` (typically
signed on x86_64/aarch64) directly to isalpha/
isalnum; this signed-char boundary belongs to a
future correspondence ACT (DAFNY-CORRESPONDENCE01).

See `evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/
lexical-contract-source.txt` for the full freeze.

## Model

File: `formal/dafny/identifier-scan.dfy` (230 lines).

```
newtype byte = x: int | 0 <= x < 256 witness 0
predicate IsIdentStart(b: byte)
predicate IsIdentContinue(b: byte)
function ScanIdentStart(s, start): nat
function ScanRest(s, i): nat
function ScanIdentEnd(s, start): nat
predicate IsValidScanResult(s, start, end)
lemma LemmaBounds        (P1)
lemma LemmaProgress      (P2)
lemma LemmaConsumed      (P3)
lemma LemmaMaximal       (P4)
lemma LemmaNoEarlyStop   (P5)
lemma LemmaDeterministic (P6)
```

Domain correspondence:

```
MODEL_INPUT_DOMAIN          = seq<byte>
IMPLEMENTATION_INPUT_DOMAIN = U8* + explicit length
DOMAIN_CORRESPONDENCE_CLAIM = SPECIFICATION_ALIGNMENT_ONLY
```

## Verification

Pinned Dafny 4.11.0 invoked via:

```sh
dafny verify --warn-redundant-assumptions \
             --warn-contradictory-assumptions \
             formal/dafny/identifier-scan.dfy
```

Result (`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/
verify.txt`):

```
Dafny program verifier finished with 17 verified, 0 errors
```

Exit code: 0.
Warnings: 0.

The redundant-assumption / contradictory-assumption
analysis is enabled by `formal/dafny/dfyconfig.toml`
(`warn-redundant-assumptions = true`,
`warn-contradictory-assumptions = true`).

In Dafny 4.11.0 the `--warn-redundant-assumptions`
flag elevates assumption warnings to hard errors by
default (no `--allow-warnings`); this is what makes
the verify path catch `assume false;` mutations.

## Audit

Pinned Dafny 4.11.0 invoked via:

```sh
dafny audit --report-file audit.txt \
            --report-format txt \
            formal/dafny/identifier-scan.dfy
```

Result (`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/
audit.txt`):

```
(empty, 0 bytes)
```

Result (`audit-stdout.txt`):

```
Dafny auditor completed with 0 findings

Dafny program verifier did not attempt verification
```

Process exit code: 0.
Findings: 0.

## Gate (CORRECTION01)

The stable gate
`scripts/quality/formal-dafny.sh` (48 LOC, opt-in,
not wired into gate-fast) enforces seven invariants:

```
I1  Dafny --version equals the pinned string.
I2  Z3 -version starts with "Z3 version 4.12.1".
I3  Runtime artefacts go to build/formal-dafny/;
    evidence/ is NEVER modified by the gate.
I4  dafny audit exit status is preserved
    (no `|| true`); non-zero exits fail closed.
I5  The auditor's exact summary line is parsed;
    N must equal 0.
I6  The plain-text audit report must be empty
    (size 0 bytes) when N == 0.
I7  dafny verify is invoked with --solver-path
    pointing at the EXACT Z3 executable we just
    authenticated (so the checked Z3 is the exact
    solver Dafny uses, not whatever PATH resolution
    would have picked).
```

RED witnesses proving AUDIT_GATE_LIVE:

```
red-assume-verify-gate.txt   RC=1  (default verify
                                    flags catch assume)
red-assume-audit-gate.txt    RC=1  (--allow-warnings;
                                    I5 AUDIT_SUMMARY_N=1)
red-wrong-dafny-version.txt  RC=3  (I1 catch)
red-wrong-z3-version.txt     RC=3  (I2 catch)
```

RED-B mechanical witness proving
CLOSED_EVIDENCE_IMMUTABLE_UNDER_GATE:

```
closed-evidence-immutability-witness.txt
  21 files in, 21 files out, diff empty
```

## RED witness A (theorem falsification)

Mutation: LemmaMaximal's postcondition changed to
`ensures false;` (impossible postcondition).

```
$ dafny verify ... mutated-identifier-scan.dfy
identifier-scan.dfy(195,10): Related location: this is the
postcondition that could not be proved
    | 195 |   ensures false
    |           ^^^^^

Dafny program verifier finished with 16 verified, 1 error
```

Exit code: 4.

Verifies that the verifier is checking a meaningful
property: when the postcondition is made impossible,
the verifier refuses to certify it.

Captured at `red-false-theorem.txt`.

Restoration: SHA-256 of restored file matches the
canonical pre-mutation / pre-comment-edit hash
`82a4fb60...4674711` exactly (see
`mutation-restoration.txt`). The post-comment-edit
canonical hash is `f6633cb4...314f7f0` and is also
recorded there.

## RED witness B (assumption escape — both paths)

Mutation: `assume false;` added to LemmaMaximal body.

### Path B1: default verify flags

```
$ ./scripts/quality/formal-dafny.sh
formal/dafny/identifier-scan.dfy(198,2): Warning: assume
  statement has no {:axiom} annotation
...
Dafny program verifier finished with 17 verified, 0 errors
Compilation failed because warnings were found and
  --allow-warnings is false
FATAL: verify non-zero
```

Exit code: 1.

Captured at `red-assume-verify-gate.txt`.

### Path B2: --allow-warnings (forces audit path)

The same mutation, with the gate temporarily patched
to add `--allow-warnings`:

```
$ ./scripts/quality/formal-dafny.sh  # patched
Dafny program verifier finished with 17 verified, 0 errors
AUDIT_RC=0
AUDIT_SUMMARY_N=1
FATAL: auditor reported 1 findings
formal/dafny/identifier-scan.dfy(192,6):LemmaMaximal:
  Definition has `assume` statement in body. ...
```

Exit code: 1.

This is the critical RED-B: when verify silently
accepts the assumption, the I5 invariant catches it.

Captured at `red-assume-audit-gate.txt`.

Restoration: SHA-256 of restored file matches the
canonical pre-mutation / pre-comment-edit hash
`82a4fb60...4674711` exactly. The post-comment-edit
canonical hash is `f6633cb4...314f7f0`; see
`mutation-restoration.txt` for the comment-edit
delta (two documentation blocks; zero theorem impact).

## Vacuity

The final configuration enables contradictory-
assumption analysis
(`warn-contradictory-assumptions = true`) and
redundant-assumption analysis
(`warn-redundant-assumptions = true`). After
restoration to the canonical proof, the verifier
emits 0 warnings of either kind.

Caveat (per ACT §13): Dafny's proof-dependency
analysis is itself heuristic around unsat-core
minimization. Claim:

```
NO_VACUITY_WARNING_DETECTED_BY_PINNED_DAFNY_CONFIGURATION
```

NOT:

```
PROOF_CAN_NEVER_BE_VACUOUS
```

## Timing

See `evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/timings.txt`.

```
Verify-only:       mean ≈ 0.915s   (n=6)
Audit-only:        mean ≈ 0.612s   (n=6)
Corrected gate:    mean ≈ 1.636s   (n=6)
```

The Dafny formal gate adds ~1.6s wall time per
invocation on this host (macOS 14.7.4 arm64, Apple
M-series, 8 cores, .NET 10.0.400). This is an initial
baseline; no SLO is asserted.

The correction adds ~0.15s vs the original MVP gate
(identity check + exact-summary parsing + empty-file
test). Acceptable.

## Existing Gates

`scripts/quality/gate-fast.sh` PASS after this ACT's
additions. Captured at `gate-fast.txt`. No existing
gate was modified, weakened, or skipped.

## Production Code Boundary

```
POLYC_PRODUCTION_HOLYC_CHANGED=false
```

No HolyC source under `src/` was modified by this ACT
or its correction. No Dafny artifact was added inside
production HolyC source directories; the entire
`formal/dafny/` tree is in a bounded location
dedicated to formal proofs.

## Gates

| Gate          | Status | Notes                                       |
|---------------|--------|---------------------------------------------|
| make formal-dafny | PASS | scripts/quality/formal-dafny.sh, exit 0     |
| ./scripts/quality/gate-fast.sh | PASS | existing gate, exit 0           |
| dafny verify  | PASS | 17 verified, 0 errors, 0 warnings           |
| dafny audit   | PASS | 0 findings                                  |

## Scope

In scope (this ACT):
- Dafny model of the PolyC identifier scanner contract
- Six theorems (P1..P6) verified by the pinned Dafny 4.11.0
- Audit with 0 findings
- Stable `make formal-dafny` entry point with
  I1..I7 invariants (six from CORRECTION01 plus
  I7 explicit --solver-path binding)
- Closed-evidence immutability under the gate
- ASCII / ctype claim boundary
- Timing baseline

Out of scope (deferred):
- Correspondence between Dafny model and PolyC HolyC
  implementation (ACT-POLYC2-DAFNY-CORRESPONDENCE01).
  This now has TWO explicit bridges to formalise:
  (a) scanner-algorithm correspondence, and
  (b) the ctype / signed-char semantic boundary.
- Proof stability / soundness amplification
  (ACT-POLYC2-DAFNY-PROOF-STABILITY01)
- Lean / Rocq / F* proof providers (deferred ACTs)

## Scientific Question (ACT §23)

### What useful claim did Dafny establish?

Dafny established a mechanical proof of six
properties of a pure spec of the PolyC identifier
scanner:

```
P1  start < ScanIdentEnd(s, start) <= |s|
P2  ScanIdentEnd(s, start) > start
P3  forall k :: start <= k < ScanIdentEnd(s, start)
        ==> IsIdentContinue(s[k])
P4  ScanIdentEnd(s, start) == |s|
        || !IsIdentContinue(s[ScanIdentEnd(s, start)])
P5  forall mid :: start < mid < ScanIdentEnd(s, start)
        ==> IsIdentContinue(s[mid])
P6  ScanIdentEnd is deterministic on (s, start).
```

This is a model proof, not an implementation proof.
The Dafny model is small (230 lines, 6 lemmas) and
auditable by hand.

### How many lines of model/proof were required?

```
formal/dafny/identifier-scan.dfy:     230 lines
formal/dafny/dfyconfig.toml:           26 lines
formal/dafny/README.md:                92 lines
scripts/quality/formal-dafny.sh:       48 lines
Makefile additions:                     7 lines
.gitignore additions:                  ~7 lines
                                  ----------
Total formal-source lines:           ~410 lines
```

### How much wall time does verification add?

```
verify-only:       ~0.92s
audit-only:        ~0.61s
full gate:         ~1.64s
```

The Dafny gate is fast (well under 2s) for this MVP.

### What assumptions remain outside the theorem?

- The Dafny `byte` newtype is faithful to the
  PolyC U8 byte domain (0..255). Dafny has no
  built-in `byte` type in 4.11.0; the newtype is a
  documented modelling choice, not a hidden
  refinement.
- The Z3 solver's soundness is taken on trust.
  This is unavoidable for any SMT-based proof
  assistant.
- Dafny's own correctness is taken on trust.
- The `newtype byte` declaration is treated as a
  refinement of `int`; Dafny's encoding of bounded
  integers may not preserve all `int` arithmetic
  properties, but our byte values are only ever
  compared against constants in 0..255.
- The frozen contract itself (see
  lexical-contract-source.txt) is taken as the
  binding spec; we did not re-derive it from the C
  standard library.
- The ctype / signed-char UB boundary is explicitly
  excluded from the model.

### What would be required to bind this model to the HolyC implementation?

Per ACT §22, that work is explicitly deferred to
ACT-POLYC2-DAFNY-CORRESPONDENCE01. The Dafny MVP
exposes two distinct correspondence bridges that
the correspondence ACT must address:

1. **Algorithm correspondence**: a verified
   compiler step (or hand-written extractor) that
   translates the Dafny function `ScanIdentEnd` to a
   C function with observable behaviour matching the
   Dafny endpoint relation for all valid inputs, and a
   proof that the observable C behaviour refines the
   Dafny endpoint. The Dafny MVP does NOT model the
   production ABI channels (l->cur_strlen, cursor
   position, lexRewindChar effect, TK_IDENT return
   value) — the correspondence ACT must explicitly
   bridge all four.

2. **Ctype / signed-char semantic boundary**: a
   mechanised model of the C semantics of
   `isalnum`, `isalpha`, `==`, `&&`, `||` on the
   `unsigned char` byte subset, with explicit
   handling of the signed-char-to-unsigned-char
   cast boundary required by ISO C 7.4.

This work is significant and explicitly deferred.
Scope and difficulty: UNKNOWN_AT_MVP. One
plausible-but-unverified stronger route would
use CompCert or a similar verified-C compiler,
which historically requires on the order of
10k+ lines of proof; that is speculation, not
a measurement, and is offered only as a rough
sense of scale.

### Was obtaining this evidence cheaper, clearer, or stronger than an equivalent custom verifier/property test?

Cheaper: NOT_MEASURED. The full Dafny gate runs
in ~1.6s wall time, but no equivalent PolyC
property-test implementation was built and timed
for direct comparison. A property test would
require (a) a PolyC test driver calling the
scanner and asserting the six properties, (b)
compiling and running it, (c) handling the
several hundred input combinations needed for
similar coverage confidence. Whether that total
work would be cheaper or more expensive than the
~405-line Dafny MVP is not established here.

Clearer: yes. The Dafny model is a ~230-line
executable specification; each lemma has named
pre/post-conditions. The PolyC oracle at
`tools/quality/bootstrap02-ident-oracle.c` is
~100 lines but covers only 15 fixtures; it does
not establish that the algorithm is correct for
ALL inputs.

Stronger: yes, modulo the model-vs-implementation
gap. The Dafny proof covers ALL valid inputs of
the frozen contract. The PolyC oracle covers only
15 fixtures. The Dafny proof does not, however,
cover the HolyC implementation directly — that
would require the correspondence work (deferred).

Conclusion: the Dafny MVP provides a stronger
and clearer piece of evidence about the FROZEN
CONTRACT than the existing 15-fixture oracle.
Whether it is cheaper is NOT_MEASURED (no
equivalent PolyC property test was built and
timed). The Dafny MVP does NOT replace the
oracle (which exercises the real implementation),
and it does NOT claim implementation equivalence.
