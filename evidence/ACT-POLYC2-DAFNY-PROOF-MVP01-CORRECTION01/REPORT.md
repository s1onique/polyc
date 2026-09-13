# ACT-POLYC2-DAFNY-PROOF-MVP01-CORRECTION01 — Closure Report

## VERDICT

```
VERDICT=PASS_MODEL_PROOF
EVIDENCE_STRENGTH=MODEL_PROOF
HALT_CLASS=NONE
```

## Identity

| Field               | Value                                                                |
|---------------------|----------------------------------------------------------------------|
| BRANCH              | harness/codium-polyc2                                                |
| BASELINE_HEAD       | 648bd3c46c79d7ec70e3898ac77d705f9038e20b                            |
| ACT_BASE_COMMIT     | 648bd3c46c79d7ec70e3898ac77d705f9038e20b                            |
| CORRECTS            | ACT-POLYC2-DAFNY-PROOF-MVP01 (still uncommitted at base)             |
| WORKTREE_PRE        | clean                                                                |
| WORKTREE_POST       | clean                                                                |

The MVP01 evidence packet was still staged, not
committed, at the time the defects were raised. This
correction therefore repairs the MVP01 artifacts
BEFORE the initial binding commit, rather than
opening an amendment against an already-bound ACT
(per F14 historical-truth discipline).

## Defects identified by external review

### D1 — P0: audit findings could escape the production gate

The original gate counted only report lines matching
`^(Warning|Error):`, but the actual Dafny auditor
emits the form:

```
file(line,col):Symbol: Definition has `assume`...
```

The auditor's textual summary `Dafny auditor
completed with N findings` was not parsed; the
auditor's exit status was discarded by `|| true`.

### D2 — P1: audit RED did not exercise the real gate

The original RED B demonstrated only that
`dafny audit` (called directly) found the assumption.
It did not prove that `make formal-dafny` would
reject the same assumption.

### D3 — P1: runtime gate mutated closed evidence

The original gate wrote `verify.txt`, `audit.txt`,
`audit-stdout.txt`, `audit-stderr.txt` into the
evidence packet on every invocation, contradicting
the append-only / immutability discipline.

### D4 — P1: toolchain pin was not enforced at runtime

The original gate tested only that the dafny/z3
binaries existed and were executable. Any binary
matching the paths would be accepted as "pinned".

### D5 — terminology

`DAFNY_DRIVER_SHA` was misleadingly used for the
upstream distribution archive digest.

### D6 — claim boundary

The frozen contract claimed provable equivalence to
production under "C locale" without an explicit
ASCII-domain qualifier; the signed-char / `isalpha`
UB boundary was not surfaced.

### D7 — documentation precision

README said "Dafny 4.11.0 (NuGet `Dafny` package)"
but the chosen installation is the standalone
macOS-arm64 release archive. REPORT.md line count
was 219; the actual file is 230 lines.

## Repairs applied

### D1 — audit-finding parser

`scripts/quality/formal-dafny.sh` now enforces seven
invariants:

```
I1  Dafny --version equals the pinned string.
    Mismatch -> exit 3, before any verification.
I2  Z3 -version starts with "Z3 version 4.12.1".
    Mismatch -> exit 3.
I3  All runtime artefacts go to build/formal-dafny/.
    evidence/ is NEVER modified by the gate.
I4  dafny audit exit status is preserved
    (no `|| true`); non-zero exits -> gate fail.
I5  The auditor's exact summary line
    "Dafny auditor completed with N findings"
    is parsed; N must equal 0.
I6  The plain-text audit report must be empty
    (size 0 bytes) when N == 0.
I7  dafny verify is invoked with --solver-path
    pointing at the EXACT Z3 executable the gate
    just authenticated (added by D15, the
    post-review pre-binding documentation sweep;
    see red-solver-binding.txt).
```

### D2 — audit RED exercises the real gate

Two RED witnesses now captured:

1. `red-assume-verify-gate.txt` — mutation
   `assume false;` injected into `LemmaMaximal`.
   Default verify flags elevate the warning to
   a hard error; gate exits 1.
2. `red-assume-audit-gate.txt` — same mutation,
   gate temporarily run with `--allow-warnings`
   so verify passes; gate exits 1 because
   `AUDIT_SUMMARY_N=1` (I5 catches it).

Canonical proof is bit-identically restored after
each RED (see `mutation-restoration.txt`).

### D3 — runtime artefacts moved to ephemeral location

```
RUNTIME_DIR = build/formal-dafny/
evidence/    = one-time closure captures, NOT
               mutated by the gate
```

Mechanical witness: `closed-evidence-immutability-
witness.txt` records sha256 hashes of every file
under `evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/` before
and after a successful gate run. The diff is empty:
21 files in, 21 files out, bit-identical.

`build/` is already in `.gitignore` and is not
tracked.

### D4 — runtime version identity check

Pinned:

```
EXPECTED_DAFNY_VERSION=4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2
EXPECTED_Z3_PREFIX=Z3 version 4.12.1
```

Both are checked via `$("$DAFNY" --version)` and
`$("$Z3" -version)` before any verification.

RED witness (`red-wrong-dafny-version.txt`):
  - A fake `dafny` whose `--version` returns
    `99.99.99+wrongsha` is substituted via sed.
  - Gate output: `FATAL: dafny version mismatch
    expected=4.11.0+... actual=99.99.99+wrongsha`.
  - Gate exit code: 3.
  - The real pinned distribution is untouched.

RED witness (`red-wrong-z3-version.txt`):
  - Same substitution for Z3.
  - Gate output: `FATAL: z3 version mismatch
    actual=Z3 version 99.99.99 - 64 bit`.
  - Gate exit code: 3.

### D5 — terminology

`claim-strength.txt` now labels:

```
DAFNY_DISTRIBUTION_ARCHIVE_SHA256=c90c75e7d5db9c6ccbb7127840dfe43f0ac938b039a7ebed146d8ead383a572f
DAFNY_DRIVER_SHA256=5d02cbb88300aef0726e933bd6f19754960b7409a9e0e2212a5e07edd1686012
```

The first is the upstream release archive digest;
the second is the actual extracted executable hash
(computed at correction time).

### D6 — claim boundary

`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/lexical-
contract-source.txt` now carries an explicit
`CLAIM_BOUNDARY` block:

```
MODEL_CHARACTER_DOMAIN                 = BYTE_0_255
FROZEN_IDENTIFIER_GRAMMAR              = ASCII
ASCII_PRODUCTION_CORRESPONDENCE_CLAIM  =
    CTYPE_C_LOCALE_FOR_ASCII_INPUTS
NON_ASCII_PRODUCTION_CORRESPONDENCE_CLAIM =
    NOT_CLAIMED
CTYPE_SIGNED_CHAR_UB_EXCLUDED_FROM_MODEL = true
```

The CTYPE_SIGNED_CHAR_UB_EXCLUDED_FROM_MODEL flag
records that:

1. ISO C requires ctype arguments to be
   representable as `unsigned char`;
2. Production passes `char` (typically signed)
   directly to `isalpha`/`isalnum`;
3. The Dafny model does not formalise this
   boundary;
4. Formalising the ctype + signed-char boundary
   belongs to the future
   ACT-POLYC2-DAFNY-CORRESPONDENCE01.

### D7 — documentation precision

`formal/dafny/README.md` now:

- states the toolchain source as the standalone
  macOS-arm64 release archive (not NuGet);
- lists the distribution archive SHA-256;
- documents the seven invariants I1..I7 (six
  from CORRECTION01 plus I7 explicit --solver-path
  binding added by D15);
- states that bytes >= 0x80 are out of scope.

`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/REPORT.md`
line-counts are corrected to:

```
formal/dafny/identifier-scan.dfy:  230 lines
formal/dafny/dfyconfig.toml:        26 lines
formal/dafny/README.md:             91 lines
scripts/quality/formal-dafny.sh:    48 lines
```

## Verification

Pinned Dafny 4.11.0 invoked via
`scripts/quality/formal-dafny.sh`:

```
POLYC_GATE=formal-dafny
DAFNY_VERSION=4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2
Z3_VERSION=Z3 version 4.12.1 - 64 bit
RUNTIME_DIR=build/formal-dafny

Dafny program verifier finished with 17 verified, 0 errors
AUDIT_RC=0
AUDIT_SUMMARY_N=0
AUDIT_FINDINGS=0 AUDIT_GATE=PASS
```

Exit code: 0.

Runtime artefacts written to `build/formal-dafny/`:
verify.txt, audit.txt (0 bytes), audit-stdout.txt,
audit-stderr.txt (0 bytes).

## Hard invariants preserved

```
HOLYC_IMPLEMENTATION_PROOF=false
MODEL_IMPLEMENTATION_EQUIVALENCE_PROVEN=false
SEMANTIC_PRESERVATION_PROVEN=false
WHOLE_COMPILER_CORRECTNESS_PROVEN=false
EVIDENCE_STRENGTH=MODEL_PROOF
```

The original Dafny model (`identifier-scan.dfy`)
received two comment-only edits after the REDs had
been captured (see D8 and D9 below). The Dafny
theorem / lemma / function / predicate content is
unchanged. Current and pre-comment-edit digests:

```
pre-comment-edit (at time of RED capture):
  82a4fb607b17dd5e920cfd6d11da35455b4496fc5766422610e90b46f4674711
post-comment-edit (current canonical):
  f6633cb4f61f6556e1b04d24c2bc085aa6916f9ce107b7969166d660f314f7f0
```

Both digests correspond to a Dafny model that
verifies 17 / 0 / 0 with the pinned Dafny 4.11.0
toolchain. The verification result is unchanged.

No theorem was weakened, no assume/axiom was added,
no Dafny version drift was introduced, no
production HolyC source under `src/` was modified.

## Post-review repairs (D8, D9)

After CORRECTION01 had captured all its REDs and
final taxonomy, external review surfaced two
factual defects and one over-strong claim in
description-only artefacts. They were repaired in
this final pre-binding pass without opening
CORRECTION02:

- **D8 (factual):** the model comment showed
  `ScanRest(s, ScanIdentStart(s,start),start)` —
  a call with three arguments, but `ScanRest`
  has two. The comment was corrected to
  `ScanRest(s, ScanIdentStart(s,start))`.
  Zero theorem impact.

- **D9 (factual / claim):** the model comment for
  `IsValidScanResult` described it as "capturing
  what production returns through the out-parameter
  and the rc channel". The production
  `lexIdentifier` ABI has no out-parameter and no
  rc channel (it returns `TK_IDENT` and sets
  `l->cur_strlen`). The comment was rewritten as
  an abstract-relation boundary, with the four
  observable production channels (cur_strlen,
  cursor position, lexRewindChar effect, return
  value) explicitly enumerated as deferred to
  ACT-POLYC2-DAFNY-CORRESPONDENCE01.
  Zero theorem impact.

- **D10 (terminology):** `TOOLCHAIN_RUNTIME_PIN_
  ENFORCED=true` was stronger than the mechanism.
  The gate enforces a runtime VERSION pin
  (dafny --version / z3 -version strings); it does
  NOT compare the SHA-256 of the dafny or z3
  executable against any recorded digest. The
  digests remain in evidence as provenance.
  The taxonomy was relabelled to
  `TOOLCHAIN_RUNTIME_VERSION_PIN_ENFORCED=true`
  and `TOOLCHAIN_BINARY_SHA_PIN_ENFORCED=false`,
  with a precise scope-of-runtime-check block
  added to toolchain.txt.

## Acceptance (C01..C18)

```
C01 canonical model still verifies          PASS  (17 verified / 0 errors)
C02 17 verified / 0 errors                  PASS  (verify.txt)
C03 canonical audit has exactly 0 findings  PASS  (AUDIT_SUMMARY_N=0)
C04 audit nonzero process status fails gate PASS  (I4; no || true)
C05 assume-false RED produces auditor       PASS  (red-assume-audit-gate.txt:
    finding                                      AUDIT_SUMMARY_N=1)
C06 assume-false RED causes make formal-    PASS  (red-assume-verify-gate.txt:
    dafny to exit nonzero                       RC=1; red-assume-audit-gate.txt:
                                                RC=1)
C07 canonical proof restored bit-identically PASS (REDs restored to
                                                82a4fb60...4674711; post-comment-
                                                edit canonical is f6633cb4...
                                                314f7f0; see D8 below)
C08 make formal-dafny does not modify       PASS  (closed-evidence-immutability-
    evidence/                                    witness.txt: 21 files in,
                                                21 files out, diff empty)
C09 exact Dafny 4.11.0 identity checked     PASS  (I1; red-wrong-dafny-version.txt
                                                shows RC=3)
C10 exact Z3 4.12.1 identity checked        PASS  (I2; red-wrong-z3-version.txt
                                                shows RC=3)
C11 wrong-version RED fails closed          PASS  (RC=3 in both REDs)
C12 distribution/archive digest correctly   PASS  (claim-strength.txt uses
    named                                        DAFNY_DISTRIBUTION_ARCHIVE_SHA256)
C13 README reflects standalone release       PASS  ("standalone macOS-arm64
    distribution                                  distribution" replaces "NuGet")
C14 ASCII-only implementation                PASS  (lexical-contract-source.txt
    correspondence explicitly bounded            CLAIM_BOUNDARY block)
C15 non-ASCII production correspondence      PASS  (NON_ASCII_PRODUCTION_
    remains NOT_CLAIMED                           CORRESPONDENCE_CLAIM=NOT_CLAIMED)
C16 no production HolyC source changed      PASS  (git status shows only
                                                formal/, scripts/, evidence/,
                                                Makefile, .gitignore)
C17 existing gate-fast remains PASS         PASS  (gate-fast.txt)
C18 EVIDENCE_STRENGTH remains MODEL_PROOF    PASS  (claim-strength.txt,
                                                REPORT.md, claim-strength.txt)

D8  ScanRest call-form comment correct       PASS  (3 args -> 2 args;
                                                ScanRest signature has 2)
D9  IsValidScanResult described as abstract PASS  (no out-parameter / rc
    endpoint relation (not ABI channel)           channel in production
                                                lexIdentifier ABI; ABI
                                                channels explicitly
                                                enumerated as deferred)
D10 runtime-pin claim matches mechanism     PASS  (relabelled to
                                                TOOLCHAIN_RUNTIME_VERSION_PIN_
                                                ENFORCED=true /
                                                TOOLCHAIN_BINARY_SHA_PIN_
                                                ENFORCED=false; scope of
                                                runtime check documented)
D11 gate is POSIX-portable /bin/sh           PASS  (PIPESTATUS removed;
                                                replace-pipeline-with-
                                                capture pattern; gate
                                                runs cleanly under both
                                                the native /bin/sh and
                                                an explicit dash
                                                invocation;
                                                red-posix-sh.txt captures
                                                the dash RC=0 PASS)
D12 line counts match current file sizes    PASS  (model: 225 -> 230
                                                lines; gate: 37 -> 41 -> 48
                                                LOC after D11+D15 fixes;
                                                README 77 -> 91 after the
                                                D15 "Shell portability"
                                                subsection; dfyconfig 26)
D13 .gitignore does not falsely claim        PASS  (changed "downloaded by
     the gate does provisioning                scripts/quality/formal-
                                                dafny.sh when the formal
                                                gate is exercised" to
                                                "used by scripts/quality/
                                                formal-dafny.sh. The
                                                script does NOT download
                                                or provision these")
D14 lexIdentifier rewind description is     PASS  (TK_IDENTS_CACHED removed;
     mechanically supported                     rewind only happens on
                                                non-NUL terminator; on
                                                NUL terminator no rewind
                                                occurs)
D15 explicit solver binding via --solver-path PASS  (verify now passes
                                                --solver-path "$Z3" so
                                                the exact Z3 executable
                                                we authenticated is the
                                                exact solver Dafny uses;
                                                new taxonomy field
                                                TOOLCHAIN_RUNTIME_SOLVER_
                                                PATH_PIN_ENFORCED=true;
                                                red-solver-binding.txt
                                                captures the witness)
D16 all line-count statements match current   PASS  (model 230; gate 48
     file sizes                                     after D11+D15+D16+D18; README 92
                                                   after the Shell-portability
                                                   subsection; dfyconfig 26;
                                                   SHELL-BUDGET.tsv updated)
D17 red-posix-sh.txt does not contradict      PASS  ("native /bin/sh" and
     itself about which shell is which               "explicit dash" are now
                                                    labelled separately;
                                                    host's /bin/sh not
                                                    mis-characterised as dash)
```

## Post-review summary

Substantive verdict is unchanged:
PASS_MODEL_PROOF, EVIDENCE_STRENGTH=MODEL_PROOF.

Seven reviewer repairs D11..D17 were applied in the
final pre-binding pass without opening CORRECTION02:

- D11: a real portability bug in scripts/quality/
  formal-dafny.sh (Bash-only PIPESTATUS used under
  /bin/sh shebang). Fixed by capturing exit status
  without a pipeline. Re-verified under both the
  native /bin/sh and an explicit /bin/dash
  invocation. Gate remains under TINY budget
  (48 LOC).

- D12: stale references (formerly 225 / 37 / 77) in
  REPORT.md updated to current actual sizes
  (230 lines for the model; 48 LOC for the gate;
  91 lines for the README; 26 for dfyconfig.toml).

- D13: .gitignore comment no longer claims the gate
  downloads Dafny. The script only checks for the
  binaries and exits 2 if they are absent.

- D14: the rewind description in
  lexical-contract-source.txt no longer refers to a
  TK_IDENTS_CACHED path that does not exist in the
  frozen C excerpt. It now states the
  mechanically-supported rewind-on-non-NUL rule,
  which is the state transition that the next
  CORRESPONDENCE01 ACT should formalise.

- D15: explicit solver binding. The Dafny verify
  invocation now passes --solver-path "$Z3" so the
  exact Z3 executable the gate authenticated is the
  exact solver Dafny uses for verification. The
  distribution ships both z3-4.12.1 and z3-4.14.1
  in z3/bin/, so without this flag a PATH-resolved
  invocation could pick the other. New taxonomy
  field TOOLCHAIN_RUNTIME_SOLVER_PATH_PIN_ENFORCED=
  true. Gate SHA updated to 4fa15966...aab3fb.

- D16: stale line-count statements in REPORT.md
  mechanically re-derived from current file sizes
  via wc -l (230 / 48 / 92 / 26). SHELL-BUDGET.tsv
  entry for formal-dafny.sh updated to 48/50.

- D17: red-posix-sh.txt rewritten so the host's
  /bin/sh and the explicit /bin/dash invocation are
  labelled separately; no longer claims the host's
  /bin/sh is dash.

## Final taxonomy

```
VERDICT=PASS_MODEL_PROOF
EVIDENCE_STRENGTH=MODEL_PROOF

MODEL_PROOF_VALID=true
AUDIT_GATE_LIVE=true
AUDIT_FINDINGS=0
TOOLCHAIN_RUNTIME_VERSION_PIN_ENFORCED=true
TOOLCHAIN_RUNTIME_SOLVER_PATH_PIN_ENFORCED=true
TOOLCHAIN_BINARY_SHA_PIN_ENFORCED=false
POSIX_SH_PORTABILITY_VERIFIED_UNDER_DASH=true
CLOSED_EVIDENCE_IMMUTABLE_UNDER_GATE=true

ASCII_PRODUCTION_CORRESPONDENCE_CLAIM=
    BOUNDED_SPECIFICATION_ALIGNMENT
NON_ASCII_PRODUCTION_CORRESPONDENCE_CLAIM=
    NOT_CLAIMED

HOLYC_IMPLEMENTATION_PROOF=false
MODEL_IMPLEMENTATION_EQUIVALENCE_PROVEN=false
SEMANTIC_PRESERVATION_PROVEN=false
WHOLE_COMPILER_CORRECTNESS_PROVEN=false

REMAINING_RESIDUE=NONE
```
