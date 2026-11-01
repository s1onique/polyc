# HANDOFF — ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02

Factory-Version: 2
Lifecycle: terminal handoff (descriptive only; the closure verdict is the
`ACT-Verdict` trailer of the CLOSE commit)
Class: SELFHOST / ABI_CORE / BUNDLED_CODEGEN_AUTHORITY_MIGRATION
Binding predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03,
PASS / PASS_SELECTED_CORE_BUNDLE
Selected bundle: CAND-CMP-CC-A64
Frozen ABI: ABI-A64-CMP-CC-1

VERDICT
------

HALT_SOURCE_RANGE_DIGEST

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The disposition is a measured HALT at the C0 contract audit. The
  ACT did NOT migrate any production decision, did NOT add any
  production authority, and did NOT claim any production graph cut.

## 1. What this ACT did, in one paragraph

This ACT was authorized to promote three AArch64 comparison-condition-code
sites (`aarch64CcFor`, `aarch64CcInvFor`, `aarch64EmitCSet`) from
production-authoritative C to production-authoritative compiled PolyC
through the frozen ABI `ABI-A64-CMP-CC-1`. Its authorization was
conditional: it could proceed to implementation only if the frozen
RECON03 successor contract proved internally coherent under an
independent C0 audit. The audit found that it does not. Two independent,
blocking, frozen-contract defects were measured. The ACT therefore halted
at C0, before any production edit, and proposes a separate forward-only
contract correction.

## 2. The two blocking discrepancies

### 2.1 C0-P1 — the frozen contract's source-range/digest table is inconsistent

RECON03's C1 record (`c1/core-sites.tsv`) and its C2 frozen contract
(`c2/selected-bundle-contract.md` section 2) pair the SAME source digest
with TWO DIFFERENT byte ranges.

The convention was established mechanically, not assumed. The digests
reproduce ONLY under the zero-based, half-open convention `[start, end)`.
Under that convention:

```text
SITE-A64-CC-FOR  C1 35517..36100  len 583  d22a99b3...  REPRODUCES
                C2 35517..36576  len 1059            DOES NOT REPRODUCE
SITE-A64-CC-INV  C1 36577..37019  len 442  5b08df7b...  REPRODUCES
                C2 36577..37495  len 918             DOES NOT REPRODUCE
SITE-A64-CSET    C1 37566..37718  len 152  8a1f2573...  REPRODUCES
                C2 37566..37719  len 153             DOES NOT REPRODUCE
```

An exhaustive SHA-256 search over EVERY `(start, length)` pair of the
whole 101705-byte committed `src/aarch64.c` blob found NO interval
anywhere matching the three C2 contract digests. The same search DID find
the three C1 digests at exactly the C1 offsets, which is the searcher's
mandatory positive control.

The two records do describe genuinely different byte sets, and the
distinction is not merely a label: the C1 ranges for FOR and INV cover
only the FLOAT sub-table (the integer switch lies outside them), while
the C2 ranges are the whole definitions plus a trailing newline. But a
label-only explanation cannot rescue the contract, because the contract
pairs a digest with a byte set that does not produce it.

The mechanically determined authoritative boundary table is recorded in
`c0/source-interval-independent-rehash.tsv`.

### 2.2 C0-P2 — the frozen third export has no observable output channel

The frozen ABI declares:

```polyc
U0 AbiA64CmpCcEmitCSet(I64 comparison_kind, I64 is_float);
```

Its parameter list carries two copied scalars. There is no pointer, no
callback and no state handle; the return type carries no value; and the
frozen contract itself forbids a callback, a global write, an
assembly-buffer pointer, and turning the return into a suffix pointer.

An exhaustive enumeration of the eight channels by which a `U0` call
could affect the emitted assembly found exactly one available: none.

The decision the site must carry IS the choice of suffix: the live
source is `aoStrCatFmt(ctx->buf, "cset    x0, %s\n\t", aarch64CcFor(cmp,
is_float));`, and RECON03's own CSET causal experiment "replaces the
call to aarch64CcFor with a constant". A suffix choice must be
transported; the frozen `U0` signature transports nothing.

Consequently the third site cannot become a third independent authority
under the frozen ABI. Leaving the decision in C would violate "old CSET
decision retired" (AC29) and "no active legacy C comparison-selection
code remains at the three ON call sites" (AC30); serving it from the
FOR export would violate AC29's independence requirement and is
explicitly forbidden ("count the FOR suffix reused by C as a third
independently selected authority").

This was proved by a compiled PolyC detector, not by argument: the
detector fires `INERT_CSET_AUTHORITY` on the frozen declaration and
accepts both plausible corrected ABIs (a `U0` with an out-parameter
cell, and a suffix-pointer return).

## 3. What was measured, and what was not touched

```text
ENTRY_HEAD                        = fd8d32e2a295f1a4b9239f552d20f12f416b33f0
ENTRY_TREE                        = cd467e521def0633d5aa88a71b97b739ccadb12b
BRANCH                            = main
REPLACE_REFS                      = 0
RECON03_CLOSE_SHA                 = 4a380e6a93c98736facf6d82fe3dd14cbc0a8728
RECON03_POST_CLOSE_ALL_COMMITS    = 2
RECON03_POST_CLOSE_ACT_COMMITS   = 0
PREDECESSOR_F14                   = PASS (57 paths, 0 mismatches)
PREDECESSOR_CONTRACT_SHA256       = 77e2a0d5168f02b9f8b550319e60ea32dc6a9f59064a4f54fd2b209ae735f681
PRODUCTION_POLYC_AUTHORITIES      = 13 (unchanged)
NEW_PRODUCTION_POLYC_AUTHORITIES = 0
PRODUCTION_GRAPH                  = 52 nodes / 134 mandatory edges / 34 SCC / largest 19 (unchanged)
NEW_PROVEN_GRAPH_CUTS             = 0
PRODUCTION_FILES_MODIFIED         = 0
PARSER_ASSERTIONS                 = 376/376 over 90 blocks
PARSER_ASSERTION_SEQUENCE_MD5     = b6f117eb1386ca80f81bc06226e2a741
LEXER07_DIRECT                    = 89/89
LEXER08_DIRECT                    = 45/45
LEXER09_DIRECT                    = 23/23
NEGATIVE_CONTROLS                 = 6/24 exercised at C0 (the other 18 are NOT_RUN)
MANDATORY_AC                      = 12 PASS / 3 FAIL / 34 NOT_RUN / 0 UNPROVEN / 1 DEFERRED
SELFHOST_M2_ACHIEVED              = NO
SLICE10_AUTHORIZED                = NO
```

The 13 existing authorities were re-verified over the CURRENT production
object graph: each is defined once, imported by exactly one production
caller object, and present in the linked `./hcc`. The historical
12/13-at-IMPLEMENT01-CLOSE and 13/13-correction-inclusive counts are
both preserved and are not collapsed.

## 4. The five REDs

Five reason-specific REDs were executed as genuine pristine -> adverse ->
restored cycles against a real compiled PolyC detector
(`tools/quality/abi-core-bundle-implement02-contract-audit.HC`), each
with its own physical execution and its own reason token:

```text
RED1 -> SOURCE_RANGE_SHA_MISMATCH       (NC05)
RED2 -> INERT_CSET_AUTHORITY            (NC07)
RED3 -> PRODUCER_IDENTITY_ALIAS         (NC09)
       DIFFERENTIAL_SCHEMA_CONFLATION   (NC10)
RED4 -> ZERO_DISCRIMINANT_COLLISION     (NC11)
RED5 -> POST_CLOSE_F14_OR_SCOPE_VIOLATION (NC03)
```

The detector's SHA-256 implementation is self-tested against three
FIPS 180-4 vectors before any digest is trusted, and RED1 was
additionally executed by two independent POSIX/Git instruments with the
same verdicts.

## 5. The predecessor's post-CLOSE history

The predecessor's five ACT commits were located by trailer, not by
counting back from HEAD. There are exactly two post-CLOSE descendants,
neither carrying an ACT trailer. The first edited the frozen contract's
section 10 only, to remove a self-referential digest and publish it in a
separate `.sha256` file; the contract's section 2 (the source ranges and
digests) and section 3 (the ABI, including all three export signatures)
are byte-identical to their CLOSE state, and no production source and no
other ACT's evidence was touched. This is recorded as an F14 observation
about the predecessor, not endorsed retroactively, and it is not a
reason to halt this ACT.

## 6. The proposed successor

`ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01`,
a forward-only correction of the frozen contract, which must:

1. replace the section 2 table with the mechanically determined
   authoritative function-boundary table and its exact bytes, hashes and
   blob OID (the table this ACT derived and recorded);
2. replace the third export's signature with one that has an observable
   output channel within the contract's other restrictions -- an
   out-parameter cell of the kind the repository already uses in
   `AbiCoreClassifyCompoundAssign`, or a suffix-pointer return -- with
   the ownership, lifetime and NULL-failure semantics spelled out; and
3. name its producers unambiguously, rather than calling two different
   executables "G0" and leaving G1/G2/G3 without executables.

The correction must then be followed by a separately authorized
implementation ACT. The U0 CSET output gap cannot be solved by editing
the ABI inside IMPLEMENT02, and it was not.

## 7. Residue recorded, not fixed

- The `/tmp/holyc-asm.s` shared-scratch race and the parallel `make -j`
  object race remain OPEN, as the frozen contract itself lists them.
- F-POLYC-TOOLS still has no landed authoritative checker.
- The ARM64 inline-assembly defect in `src/holyc-lib/memory.HC` and
  `strings.HC` is OPEN. It was PROVEN pre-existing by reproducing the
  identical failure in a detached worktree at the pristine entry commit
  with the pristine entry compiler.
- `F-NO-PYTHON` remains FAIL with 12 tracked Python files, the known
  baseline, and the checker is still not wired into `gate-fast`.
- The broad LEXER07 corpus was not re-measured in this ACT; its
  historical FAIL_KNOWN_BASELINE status (15 S0 failure identities) is
  recorded as the historical figure and is not relabelled as green.

## 8. Evidence tree

```text
evidence/ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02/
  c0/   entry-and-predecessor-ancestry.tsv
        predecessor-post-close-commit-audit.tsv
        predecessor-f14-freeze.tsv
        frozen-contract-identity.tsv
        source-interval-independent-rehash.tsv
        contract-audit.tsv
        cset-output-channel-proof.tsv
        producer-contract-reconciliation.tsv
        entry-13-authorities.tsv
        entry-baselines.txt
        five-red-observations.tsv
        frozen-50-ac.tsv
        frozen-24-nc.tsv
  c4/   terminality-plan.txt   # a PLAN, not a receipt
```

The `c1/`, `c2/` and `c3/` trees are ABSENT because those phases were
never reached. They were not created empty, and no criterion in them is
reported as PASS.
