# ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Issue canonical Factory-v2 CLOSE trailers for
`ACT-POLYC-LLVM-BYTE-MEMORY01` and `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`,
correctly superseding the malformed trailer block on the prior HALT
commit.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessors (F14 preserved):**

- `ACT-POLYC-LLVM-BYTE-MEMORY01` -- `HALT_SCOPE_EXPANSION_REQUIRED`
  (H1 frozen-set exceeded; H2 B0 multi-block SSA dominance bug).
  The HALT commit at SHA `e5e49f5` carries a malformed Factory-v2
  trailer block (`git interpret-trailers --parse` collapses to
  `ACT-Phase: OPEN / ACT-Verdict: PENDING`, neither legal under
  `docs/factory/GIT-METADATA.md` section 2.1 / section 2.2).
- `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01` -- currently AUTHORIZATION_ARTIFACT
  only; no execution commits yet.

**Class:** FACTORY-V2 TRAILER CORRECTION (governance bookkeeping,
no production code change)

**Production semantic changes:** **NONE.**

**Neutral-IR / ABI changes:** **NONE.**

---

## 0. Mission

Issue canonical Factory-v2 trailers on a single correction commit
that:

1. CLOSEs `ACT-POLYC-LLVM-BYTE-MEMORY01` with verdict
   `HALT_SCOPE_EXPANSION_REQUIRED` (the verdict that the malformed
   `e5e49f5` failed to record).
2. Authorizes `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01` (the
   authorization artifact) and explicitly records that the first
   RESUME01 execution commit MUST carry
   `ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`,
   `ACT-Phase: RED`, and no `ACT-Verdict`.

No production code, test, neutral IR, or capability counter is
changed by this ACT.

## 1. Authorized set (delta from `BYTE-MEMORY01` recon freeze)

```text
NONE.

This ACT has zero production-code authorization. Its sole scope
is the Factory-v2 trailer block of one descendant correction
commit.
```

## 2. RED (mandatory)

There is no RED phase in the conventional RED/IMPL/EVIDENCE/CLOSE
sense. The "RED" equivalent for this ACT is the mechanical
verification that `e5e49f5`'s trailer block is malformed. The
verification must be reproduced and captured as evidence before
the correction commit is authored.

```text
reproduce_malformed_trailer -- capture e5e49f5.msg then run
git interpret-trailers --parse
sh scripts/quality/factory-v2-commit-msg-check.sh e5e49f5.msg
```

## 3. Source change scope (bounded)

1. The single correction commit's commit message MUST carry the
   canonical trailer block (the Factory-v2 grammar in
   `docs/factory/GIT-METADATA.md` section 2.1, 2.2, 2.3):

   ```text
   ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01
   ACT-Phase: CLOSE
   ACT-Verdict: PASS
   ACT-Supersedes: ACT-POLYC-LLVM-BYTE-MEMORY01
   ACT-Corrected-Verdict: HALT_SCOPE_EXPANSION_REQUIRED
   ```

   No other trailer block, no `OPEN` phase, no `PENDING` verdict.

2. The correction commit's file changes are limited to:
   - `docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md` --
     section 0.5 trailer-correctness note (already added by the
     predecessor commit; this ACT confirms the cross-reference).
   - `docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01.md` --
     this document.
   - `docs/ROADMAP.md` -- P4 sequence marks this correction ACT
     and binds the BYTE-MEMORY01 HALT verdict to the canonical
     CLOSE trailer.

3. No `src/` change. No `scripts/` change (the validator is
   correct; the malformed trailer is in the commit message, not
   in the validator). No `evidence/` change other than the
   immutable record of the malformed-trailer observation in
   `evidence/llvm-byte-memory01/closure/e5e49f5-trailer-correctness.txt`.

## 4. IR / ABI / neutral-IR boundary changes

**NONE.**

## 5. CAPABILITY COUNTERS binding

**NONE.** No capability counter changes.

## 6. Closure gates

| Gate                              | Status requirement                                                  |
|-----------------------------------|---------------------------------------------------------------------|
| `factory-v2-commit-msg-check.sh`  | MODE=ACT  ACT=ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01  PHASE=CLOSE  VERDICT=PASS  STATUS=PASS |
| `git interpret-trailers --parse`  | Reports `ACT-Supersedes:` and `ACT-Corrected-Verdict:`              |
| `factory-v2-range-check.sh`       | PASS -- the correction commit is its own one-commit range with PHASE=CLOSE |
| `factory-append-only-test.sh`     | PASS=11 FAIL=0                                                      |
| `factory-v2-test`                 | PASS=35 FAIL=0                                                      |
| `git diff --check`                | clean                                                               |
| `gate-fast`                       | VERDICT=PASS                                                        |

## 7. Out-of-scope

- All production code paths in `src/`.
- All test harnesses in `scripts/quality/`.
- All neutral IR / capability counter updates.
- The HALT reasons themselves -- those are recorded in
  `ACT-POLYC-LLVM-BYTE-MEMORY01.md` and are not re-litigated here.
- The continuation ACT `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`
  is referenced but NOT CLOSED here.

## 8. NEXT ACT (provisional)

After this BOOKKEEPING01 ACT closes, the next ACT is
`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`. The first commit of its
RED phase must carry:

```text
ACT: ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01
ACT-Phase: RED
```

with no `ACT-Verdict` trailer, no `OPEN` phase, and no
malformed-trailer block.
