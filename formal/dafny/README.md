# PolyC Dafny formal proofs (opt-in)

This directory hosts Dafny models of selected PolyC
contracts, used as **build-time evidence** by the
opt-in formal gate `make formal-dafny`.

## Scope (MVP)

The current model is a pure Dafny spec of the frozen
PolyC identifier scanner contract. See
[`identifier-scan.dfy`](identifier-scan.dfy) and the
ACT evidence under
`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/`.

The Dafny model is **not** a formal verification of the
PolyC / HolyC implementation in `src/lexer.c`. It is a
formalisation of the contract, expressed in Dafny.

The model covers ASCII inputs only. Bytes >= 0x80 are
explicitly OUT OF SCOPE; the ctype / signed-char
boundary belongs to a future correspondence ACT.

## Toolchain (pinned)

- Dafny 4.11.0 standalone macOS-arm64 distribution
  (release archive `dafny-4.11.0-arm64-macos-13.zip`,
  SHA-256 `c90c75e7d5db9c6ccbb7127840dfe43f0ac938b039
  a7ebed146d8ead383a572f`). Driver version string
  `4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2`.
- Z3 4.12.1 (bundled inside the same release archive).

The Dafny distribution and Z3 binary are NOT committed.
`make formal-dafny` runs
`scripts/quality/formal-dafny.sh`, which expects them
under `tools/dafny/`. Provisioning is documented in
`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01/toolchain.txt`.

## Running

```sh
make formal-dafny
```

This runs `scripts/quality/formal-dafny.sh`, which:

1. Verifies the pinned Dafny driver version string
   matches `4.11.0+fcb2042d6d043a2634f0854338c08feeaaaf4ae2`
   (I1) and the bundled Z3 prefix matches
   `Z3 version 4.12.1` (I2). Mismatch fails closed
   (exit 3) BEFORE any verification.
2. Runs `dafny verify` on `identifier-scan.dfy` with
   `--solver-path "$Z3"` (I7 — the exact Z3
   executable we just authenticated is the exact
   solver Dafny uses, not whatever PATH resolution
   would have picked) plus
   `--warn-redundant-assumptions` and
   `--warn-contradictory-assumptions`. Any warning
   becomes a hard error (Dafny 4.11.0 default) and
   fails the gate.
3. Runs `dafny audit`; preserves its exit code (I4),
   parses the exact `Dafny auditor completed with N
   findings` summary (I5), and independently requires
   the plain-text audit report to be empty (I6).
4. Writes all runtime artefacts under
   `build/formal-dafny/` (I3) — never under
   `evidence/`. The `evidence/` tree is reserved for
   one-time closure captures and is immutable under
   the gate.

### Shell portability

The gate script declares `#!/bin/sh` and uses only
POSIX constructs. It is verified to run cleanly
under both the native `/bin/sh` on this host and
`/bin/dash` (invoked explicitly as a separate
executable); no Bash-only extensions such as
`PIPESTATUS` are used. See
`evidence/ACT-POLYC2-DAFNY-PROOF-MVP01-CORRECTION01/
red-posix-sh.txt` for the dash PASS witness.

## Out of scope

The following are deferred to future ACTs and are NOT
introduced here:

- ACT-POLYC2-DAFNY-CORRESPONDENCE01 (model ↔ HolyC
  implementation equivalence, including ctype /
  signed-char boundaries)
- ACT-POLYC2-DAFNY-PROOF-STABILITY01
- ACT-POLYC2-LEAN-PROOF-MVP01
- ACT-POLYC2-ROCQ-PROOF-MVP01
- ACT-POLYC2-FSTAR-PROOF-MVP01
