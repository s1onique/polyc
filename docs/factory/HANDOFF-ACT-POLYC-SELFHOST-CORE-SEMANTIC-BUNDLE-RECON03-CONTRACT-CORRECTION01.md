# HANDOFF — ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01

VERDICT
------

PASS

  This document is DESCRIPTIVE ONLY. The authoritative verdict for this
  ACT lives in the `ACT-Verdict` trailer of its CLOSE commit, per
  `docs/factory/GIT-METADATA.md` section 1.

  The disposition is PASS_CORRECTED_TWO_PLUS_ADAPTER.

```text
DISPOSITION  = PASS_CORRECTED_TWO_PLUS_ADAPTER
BUNDLE_MODE  = TWO_PLUS_ADAPTER
ABI          = ABI-A64-CMP-CC-2 (new, correction-owned)
FUTURE       = 13 -> 15 production PolyC authorities
ENTRY_HEAD   = 500d2fce1259b03bad7f10795c11346dadcc70d0
ENTRY_TREE   = 0fb68fa280a3a405a84a303a5585babf4bfe7c0e
BRANCH       = main
NEXT_ACT     = ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01
                (PROPOSED ONLY -- not created, not executed)
NEXT_TARGET_AUTHORIZED = NO
SELFHOST_M2_ACHIEVED   = NO
SLICE10_AUTHORIZED     = NO
PUSH_PERFORMED         = NO
```

## What was wrong, and what this ACT did about it

`ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03` selected the
AArch64 comparison-condition-code bundle `CAND-CMP-CC-A64` and froze a
successor contract. `ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02`
then measured that the frozen contract could not be implemented, and
halted with two blocking discrepancies:

1. **the source-range/digest binding was internally inconsistent** — the
   C1 record and the C2 contract paired the same digest with two
   different byte ranges, and neither C2 range hashed to the digest the
   contract claimed;
2. **the third export had no observable output channel** — a
   `U0 AbiA64CmpCcEmitCSet(I64,I64)` with two copied scalars cannot
   convey the suffix an emitted `cset` must carry.

This ACT is the separately authorized, forward-only correction. It
supplies a new contract under a new ABI version and **changes no
historical record**.

## The three findings

### 1. The authoritative whole-definition boundaries

The three whole definitions were re-derived by **two methods that share
no code** — a compiled PolyC byte-level lexical scanner that tracks
comments, strings, character literals and brace nesting, and a POSIX
`grep`/`wc`/`awk`/`dd`/`shasum` scanner. They agree byte-for-byte:

| Site | Function | Range | Size | SHA-256 |
|---|---|---|---|---|
| SITE-A64-CC-FOR | `aarch64CcFor` | `[35517,36575)` | 1058 | `6ad4b25dc0473eeb2665690c7eff0d45100c6d184f1fff04bc374bf415a7e617` |
| SITE-A64-CC-INV | `aarch64CcInvFor` | `[36577,37494)` | 917 | `56ee5cf27e10e4a0919588713ef77a481017a2962bf713cc3f51796d8c53b7cc` |
| SITE-A64-CSET | `aarch64EmitCSet` | `[37566,37718)` | 152 | `8a1f2573c7eeb598816edcd96830cdd695b733f6ad12c47f859ea46575cec540` |

The convention is frozen: zero-based half-open `[start,end)`, with the
closing `}` as the **last byte** of the range.

Four digest concepts are kept strictly apart. The whole-function
digests are **generated**, never copied. The three historical C1
digests reproduce **exactly** at their recorded intervals and are
relabelled `C1_PARTIAL_INTERVAL` — which reveals that the C1 interval
for CSET *coincides* with its whole definition, while the C1 intervals
for FOR and INV are strict prefixes. The three historical C2 ranges are
rehashed and **all three mismatch** the digest the contract paired
with them, so IMPLEMENT02's finding is confirmed, not disputed.

### 2. The CSET site is a mechanical adapter, not a third authority

This was **measured**, not assumed, and the ACT's decision rule was
executed rather than pre-decided.

* **At the source level**: the CSET whole definition contains **zero**
  `switch`, **zero** `case ` and **zero** `IR_CMP_` occurrences. Its
  entire semantic content is one call to `aarch64CcFor` plus a fixed
  format string. FOR and INV each contain two switches, sixteen cases
  and sixteen `IR_CMP_` references.
* **Empirically**: a mutation confined entirely to the FOR table
  changes the `cset` emission from `lt` to `ge` **while the CSET site
  stays byte-identical**. The CSET output is fully determined by FOR.
  A mutation confined to CSET proves only that the **emitter is
  live** — which is exactly the literal-substitution case the ACT says
  does not establish an independent selection.
* **From the predecessor's own records**: RECON03's CSET
  site-isolation record says its mutation "replaces the call to
  `aarch64CcFor` with a constant", and RECON03's FOR record says "the
  CSET witness shares the `aarch64CcFor` table and is therefore NOT an
  isolation control for this site". A witness that cannot isolate a
  site cannot establish that site as an authority.

**`BUNDLE_MODE = TWO_PLUS_ADAPTER`**, `FUTURE_NEW_POLYC_AUTHORITIES =
2`, `FUTURE_TOTAL = 15`.

The three **original physical site IDs** and the selected bundle ID
are preserved verbatim. RECON03's recorded selection is neither erased
nor relabelled; the successor *adds* a measured classification to it.

### 3. A new observable ABI, proven through the real seam

`ABI-A64-CMP-CC-2` has **two** exports:

```c
const unsigned char *AbiA64CcForV2(int64_t comparison_kind, int64_t is_float);
const unsigned char *AbiA64CcInvForV2(int64_t comparison_kind, int64_t is_float);
```

The third export is **removed, not repaired**: it had no observable
output channel, and the site it would have carried owns no independent
decision.

The ABI was proven implementable and observable through the **real
seam** — a disposable prototype compiled by the production `./hcc` for
`aarch64-apple-darwin`, exported from a Mach-O arm64 object, and
linked into a disposable C host: **28 checks, 0 failures**, covering
the zero discriminant (`IR_CMP_EQ == 0` returns `"eq"`, never an
error), the borrowed lifetime, every invalid and unsupported kind
returning `NULL`, the real compiled PolyC FOR result feeding the
unchanged host `cset` formatting to produce the exact bytes
`cset    x0, lt`, and a host-only formatting anti-control producing a
byte-identical result that proves the adapter contributes no
independent decision. All twelve AArch64 suffixes assemble against the
real assembler and the invalid suffix is rejected.

The producer DAG is resolved into unambiguous names — `C_TOOLCHAIN` and
`POLYC_PRODUCER_1..5`, six executables with six distinct digests —
with an explicit crosswalk away from the predecessor's self-referential
`G0`/`G1`/`G2`/`G3` labels, which assigned `G0` to two different
executables. The 12 ordered `PAIR` stream comparisons and the 12
heterogeneous `FROZEN` invariants are recorded as **two distinct
rosters**; a count of 12 in one never discharges the other.

## What was preserved

RECON03 remains `PASS / PASS_SELECTED_CORE_BUNDLE`. IMPLEMENT02 remains
`HALT`. The original contract's digest
`77e2a0d5168f02b9f8b550319e60ea32dc6a9f59064a4f54fd2b209ae735f681` was
re-derived from the live Git blob and is unchanged, and both its
at-CLOSE and its current blob OIDs are recorded without erasing
history. The 523-path F14 predecessor freeze re-verifies with **zero**
mismatches. All **13** production PolyC authorities are linked, with the
historical 12/13-at-IMPLEMENT01-CLOSE count kept separate from the
13/13 correction-inclusive count. The production graph is conserved at
52 nodes / 134 mandatory edges / 34 SCCs / largest 19, with
`E-TYP-0136` the sole proven cut and **zero** new cuts. There is **no
production semantic delta**: this ACT changed no production source, no
selector, no object and no gate.

## Honest non-green status

`F-NO-PYTHON` remains **FAIL** at the same 12 known violations with 0
new. `F-POLYC-TOOLS` remains **UNAVAILABLE** — its canonical checker
does not exist in this tree. The broad LEXER07 corpus and the
cross-target prefix are recorded as **NOT_REMEASURED**, not relabelled
green. The parser is 376/376 over 90 real blocks with the
assertion-sequence MD5 `b6f117eb1386ca80f81bc06226e2a741`, and the
three direct lexers are 89/89, 45/45 and 23/23.

## The successor

```text
ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01
```

**Proposed only.** Not created, not executed. Its entry is this ACT's
CLOSE and its sole binding implementation contract is
`ABI-A64-CMP-CC-2`, with a target of **13 → 15** and the emitter kept
C-mechanical. It must carry independent `G0`–`G3` comparisons, a
post-migration causal experiment **per actual authority** (two, not
three), the adapter-preservation witness, the host-only formatting
anti-control, and C dormancy.

`NEXT_TARGET_AUTHORIZED=NO`, `SELFHOST_M2_ACHIEVED=NO`,
`SLICE10_AUTHORIZED=NO`.

## Evidence

```text
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01/
  c0/  entry-identity.tsv, historical-ancestry-and-post-close.tsv,
       predecessor-f14-freeze.tsv, original-contract-identity.tsv,
       thirteen-authorities.tsv, baseline-parser-lexer.txt,
       baseline-non-green.txt, five-red-executions.tsv,
       frozen-50-ac.tsv, frozen-24-nc.tsv
  c1/  whole-definition-boundaries.tsv, partial-vs-whole-digest-audit.tsv,
       semantic-authority-cset-classification.tsv,
       c-only-mutants-and-site-isolation.tsv,
       input-domain-and-abi-ownership.tsv,
       producer-dag-and-12plus12-crosswalk.tsv
  c2/  corrected-source-ranges.tsv(.sha256), corrected-abi-v2.md(.sha256),
       semantic-authority-vs-adapter.tsv, corrected-bundle-members.tsv,
       corrected-selection-binding.tsv, corrected-producer-dag.tsv,
       future-implementation-contract.md, contract-correction-join.tsv,
       real-seam-prototype-and-observability.tsv
  c3/  independent-rehash-and-join.tsv, full-50-ac-ledger.tsv,
       negative-controls-executed.tsv, verifier-anti-selftests.tsv,
       conservation-and-graph.txt, gates-f14-append-only.txt,
       implementation-readiness-verdict.tsv
  c4/  terminality-plan.txt
```

The ACT-local verifier is
`tools/quality/a64-cmp-cc-contract-correction01-verify.HC`, a compiled
PolyC tool that computes its own SHA-256 digests, parses the live
source bytes and the live enum header, and never reads a claimed PASS
field.
