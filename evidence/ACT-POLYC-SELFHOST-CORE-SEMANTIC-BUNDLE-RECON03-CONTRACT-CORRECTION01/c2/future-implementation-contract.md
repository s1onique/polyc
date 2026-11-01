# The future implementation contract

ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON03-CONTRACT-CORRECTION01
Phase: C2 IMPL
Binding ABI: **ABI-A64-CMP-CC-2**
Disposition: PASS_CORRECTED_TWO_PLUS_ADAPTER (subject to the C3 and C4 gates)

**This contract does not authorize implementation.** It freezes what
`ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01` must
build and must re-verify. It is that ACT's input, not its permission.

It SUPERSEDES the authorization to implement using ABI-A64-CMP-CC-1
**only**. RECON03's historical verdict, RECON03's original text and
IMPLEMENT02's historical HALT are all preserved unchanged.

## 1. The target

```
PRODUCTION_AUTHORITIES_BEFORE          = 13
FUTURE_NEW_POLYC_AUTHORITIES           = 2
FUTURE_TOTAL_AUTHORITIES_AFTER         = 15
NEW_PRODUCTION_AUTHORITIES_BY_THIS_ACT = 0
NEW_PROVEN_GRAPH_CUTS_BY_THIS_ACT      = 0
```

The future ACT's target is **13 → 15**, not 13 → 16. It must migrate
exactly **two** semantic decisions and **no** third.

## 2. The two sites to migrate, and the one to keep

| Site | Function | Whole range | Whole SHA-256 | Classification | Migrate? |
|---|---|---|---|---|---|
| SITE-A64-CC-FOR | `aarch64CcFor` | `[35517,36575)` | `6ad4b25dc0473eeb2665690c7eff0d45100c6d184f1fff04bc374bf415a7e617` | INDEPENDENT_SEMANTIC_DECISION | **YES** |
| SITE-A64-CC-INV | `aarch64CcInvFor` | `[36577,37494)` | `56ee5cf27e10e4a0919588713ef77a481017a2962bf713cc3f51796d8c53b7cc` | INDEPENDENT_SEMANTIC_DECISION | **YES** |
| SITE-A64-CSET | `aarch64EmitCSet` | `[37566,37718)` | `8a1f2573c7eeb598816edcd96830cdd695b733f6ad12c47f859ea46575cec540` | C_MECHANICAL_ADAPTER | **NO** -- the emitter stays in C |

Source blob: `src/aarch64.c` at
`6a53ac8f2e320aa8b0f7fc23ea9bd90be0334229` (101705 bytes).
Range convention: zero-based half-open `[start,end)`; the closing `}`
is the last byte of the range.

The successor must RE-DERIVE these boundaries and digests itself. It
must not trust this document alone.

## 3. The ABI to implement

```c
const unsigned char *AbiA64CcForV2(int64_t comparison_kind, int64_t is_float);
const unsigned char *AbiA64CcInvForV2(int64_t comparison_kind, int64_t is_float);
```

There is **no third export**. The frozen `U0 AbiA64CmpCcEmitCSet(I64,I64)`
is **removed**, not repaired: it has no observable output channel, and
the site it would have carried owns no independent decision.

The full ABI specification, the input domain, the ownership rules and
the lifetime rules are in `c2/corrected-abi-v2.md`.

## 4. What the successor must build

1. A new PolyC component under `tools/bootstrap/` exporting the two
   functions above, with the suffix tables transcribed from the live C
   tables using their source-derived numeric `IrCmpKind` values.
2. A new CMake rule that **schedules** the subject's production from
   `$(BOOTSTRAP_STAGE0_HCC)`, so the build graph produces it and no
   manual prerequisite command is needed. The rule must **fail
   closed** when the producer or the prefix is missing.
3. A dedicated selector (of the same shape as the existing
   `HCC_USE_SELFHOST_*` selectors) so that the selector-OFF C oracle
   remains a genuine, uncontaminated oracle.
4. A C-side call site that obtains the suffix through the PolyC
   decision, with the **C body dormant** in the selector-ON build.
5. The `aarch64EmitCSet` adapter kept in C, with its call to the
   condition decision preserved and its fixed format string unchanged.

## 5. The fixture specification

The fixture set must cover, at minimum:

- every integer kind `IR_CMP_EQ`..`IR_CMP_UGE` (0..9), on the integer
  path;
- every float kind `IR_CMP_EQ`, `IR_CMP_NE`, `IR_CMP_LT`, `IR_CMP_LE`,
  `IR_CMP_GT`, `IR_CMP_GE` (0..5), on the float path;
- the four integer-only kinds `IR_CMP_ULT`..`IR_CMP_UGE` on the float
  path, which must **fail closed**;
- the eight ordered/unordered kinds `IR_CMP_OEQ`..`IR_CMP_ORD`
  (10..17), on both paths, which must **fail closed**;
- `IR_CMP_INVALID` (-1), on both paths, which must **fail closed**;
- at least one out-of-domain value, which must **fail closed**;
- the explicit **zero discriminant** case `IR_CMP_EQ == 0`, which must
  return `"eq"` and must NOT be mistaken for a failure;
- an explicit **cset emission** case, which must produce the exact
  production bytes `cset    x0, <suffix>\n\t`.

## 6. The required causal experiments

One experiment **per actual authority** -- **two**, not three:

| Experiment | Site | Must show |
|---|---|---|
| POST-MIG-FOR | SITE-A64-CC-FOR | a PolyC mutation of the FOR decision changes the emitted assembly AND the compiled program's behaviour, reproducing the recorded transition |
| POST-MIG-INV | SITE-A64-CC-INV | a PolyC mutation of the INV decision changes the emitted false-side branch AND the compiled program's behaviour |

The CSET site gets **no** authority experiment, because it owns no
authority. The future ACT must instead show:

- the **adapter preservation witness**: the compiled PolyC FOR result
  feeds the unchanged host `cset` formatting and produces the exact
  expected bytes;
- the **host-only formatting anti-control**: formatting the same
  suffix entirely in C produces a byte-identical result, which proves
  the adapter contributes no independent decision.

The future ACT must also show the **C dormancy** of the migrated FOR
and INV bodies in the selector-ON build.

## 7. The producer and differential obligations

- one genuine **selector-OFF C production oracle**, verified to import
  NO PolyC subject symbol;
- three **pairwise-distinct** PolyC subject producers (distinct
  executable digests);
- four separately observed semantic result streams;
- all **12 ordered stream comparisons** (PAIR-01..12);
- all **12 heterogeneous invariants** (FROZEN-01..12), tracked as a
  **DIFFERENT** roster. A count of 12 in one roster never discharges
  the other;
- the producer identities named `C_TOOLCHAIN` and `POLYC_PRODUCER_1..5`
  with an explicit crosswalk away from the predecessor's ambiguous
  `G0`/`G1`/`G2`/`G3` labels.

The crosswalk, the two rosters in full and the measured producer
digests are in `c1/producer-dag-and-12plus12-crosswalk.tsv` and
`c2/corrected-producer-dag.tsv`.

## 8. The build / Make / CMake fail-closed plan

- The subject object is produced by `$(BOOTSTRAP_STAGE0_HCC)` with an
  explicit output path.
- If the producer or the bootstrap prefix is absent, the build must
  **fail closed** with a message that names the missing artifact and
  the command that produces it. It must not silently fall back to
  another producer, to a stale object, or to the legacy C path.
- The selector-OFF configuration must remain the DEFAULT for the C
  oracle, so the oracle is never contaminated by a PolyC import.
- The known `/tmp/holyc-asm.s` shared-scratch race remains OPEN and
  must be worked around by **serialisation** until it is fixed by a
  separately authorized ACT.

## 9. The target after a future PASS

```
13 -> 15 production PolyC authorities
2 migrated semantic decisions
1 preserved C mechanical adapter
0 new production graph cuts claimed without proof
SELFHOST_M2_ACHIEVED = NO
SLICE10_AUTHORIZED  = NO
```

## 10. The successor ACT

```
ACT-POLYC-SELFHOST-ABI-CORE-BUNDLE-IMPLEMENT02-CORRECTED01
```

Its entry is this correction's CLOSE. Its sole binding implementation
contract is **ABI-A64-CMP-CC-2**. It is proposed, NOT created and NOT
executed by this ACT.
