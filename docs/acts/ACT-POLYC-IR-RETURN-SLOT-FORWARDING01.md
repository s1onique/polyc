# ACT-POLYC-IR-RETURN-SLOT-FORWARDING01

**Mission:** make the neutral-IR `irForwardReturnSlot` pass
dominance-safe so that the canonical
`store return_slot, V; load return_slot; ret load_result`
shape survives any multi-block / multi-predecessor exit
block.

**Class:** MACHINE-ENFORCED CAPABILITY CONTRACT —
neutral-IR optimisation correctness repair.

**Language semantic changes:** **NONE**. PolyC source
semantics are unchanged.

**Production compiler change:** **YES** — bounded
neutral-IR optimisation correctness repair in
`src/ir-optimise.c::irForwardReturnSlot`.

**Predecessor:** `ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`
CLOSE `HALT_SCOPE_EXPANSION_REQUIRED`. C1 evidence at
[`evidence/llvm-byte-memory01-resume01/c1/`](../../evidence/llvm-byte-memory01-resume01/c1/)
isolated the defect upstream of the LLVM collapse code: the
neutral-IR pass `irForwardReturnSlot`
(`src/ir-optimise.c:256-309`) rewrites
`store slot, V; load slot; ret load_result` into
`ret V` for the exit block without verifying that `V`
dominates the exit block along every predecessor path. The
defect is generic; it reproduces on I64-only fixtures
(`i64_collapse_probe.HC`, `single_cond_probe.HC`).

## 0. Authority and scope

The RESUME01 contract (see
[`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md`](ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01.md)
§1 and §3) explicitly forbids "IR-builder seam changes
OUTSIDE the llCollapseStoreValue reload selection repair"
and mandates `HALT_SCOPE_EXPANSION_REQUIRED` if the smallest
invariant-preserving repair requires "changes outside the
authorized `llCollapseStoreValue` seam". C1 demonstrated
that the smallest repair is in `src/ir-optimise.c`, not
`src/llvm-backend.c`. RESUME01 closes with
`HALT_SCOPE_EXPANSION_REQUIRED`; this ACT
(`IR-RETURN-SLOT-FORWARDING01`) is the natural continuation
with a correctly authorized production seam.

The reviewer's recommended naming preference: this defect
is "not really an LLVM collapse defect" (C1 proved it is a
neutral-IR optimisation defect). Hence the
`IR-RETURN-SLOT-FORWARDING01` name rather than
`LLVM-IR-COLLAPSE-FIX01`.

## 1. Authorized set (delta from RESUME01 recon freeze)

The recon freeze at
[`evidence/llvm-byte-memory01-resume01/c1/`](../../evidence/llvm-byte-memory01-resume01/c1/)
is REPLACED by the following authorized set:

```text
IMPLEMENT
  src/ir-optimise.c
    irForwardReturnSlot
      dominance-safe forwarding (conservative sufficient
      condition: only forward when the exit block has a
      single predecessor)

PRESERVE
  src/llvm-backend.c
  llCollapseStoreValue
  llDetectCollapsibleReturn
  src/llvm-backend-cap.c

EXPLICITLY FORBIDDEN
  changes to llvm-backend.c
  changes to llCollapseStoreValue
  changes to llDetectCollapsibleReturn
  changes to ALREADY_SUPPORTED behaviour
  changes to byte / i64 / i8 / u8 lowering semantics
  changes to neutral-IR opcode semantics
  changes to dispatch-table coverage machinery
  general pointer aliasing machinery, TBAA metadata
```

Defence-in-depth changes to `llCollapseStoreValue` /
`llDetectCollapsibleReturn` are EXCLUDED because C1 now
proves those seams are not the producer of the invalid IR;
a simultaneous change would destroy causal attribution.

## 2. RED (mandatory, all must fail under `opt --passes=verify`)

The RED fixtures must be committed BEFORE this ACT's IMPL
commit (so the failing witness is on record):

```text
pos_b0_compare_digit.HC        FAIL  (B0-shaped multi-block
                                       conditional byte
                                       return; carried over
                                       from RESUME01)
i64_collapse_probe.HC          FAIL  (I64-only generic
                                       trigger; two-arm
                                       conditional collapse)
single_cond_probe.HC           FAIL  (I64-only generic
                                       trigger; single
                                       conditional,
                                       multi-predecessor exit)
```

All three fixtures must produce LLVM IR that
`opt --passes=verify` rejects with
`"Instruction does not dominate all uses!"`.

## 3. Source change scope (bounded)

1. `src/ir-optimise.c` — repair `irForwardReturnSlot`
   (lines 256-309) so the rewrite `rt->dst = st->r1;` only
   fires when the exit block has a single predecessor.
   The exact mechanism is:

   ```c
   // before the rewrite at line 287:
   if (irBlockGetPredecessors(fn, bb)->size != 1)
       continue;
   ```

   The guard is a deliberately conservative
   **mechanically-testable sufficient condition**, not a
   claim of general necessity. Multi-predecessor exit
   blocks where the value being substituted for the load
   is defined in a common dominator are deliberately not
   optimized; the canonical `store; load; ret` shape
   survives and is handled correctly by the existing
   LLVM-side collapse seam (`llCollapseStoreValue` +
   `llDetectCollapsibleReturn`).

   This is **Repair E** from the reviewer's enumerated
   options (A, B, C, D, E). Reviewer selected E because E
   is conservatively safer than A/D (no need for
   predecessor-wise definition reasoning) and smaller than
   B (no PHI insertion) and C (no value-flow analysis).

2. NO change to `src/llvm-backend.c`.
3. NO change to `src/llvm-backend-cap.c`.
4. NO change to the neutral-IR opcode grammar.
5. NO change to dispatch-table coverage machinery.

## 4. GREEN (mandatory)

```text
pos_b0_compare_digit.HC        PASS
i64_collapse_probe.HC          PASS
single_cond_probe.HC           PASS
```

## 5. Negative control (mandatory)

A single-predecessor exit block case (e.g. a previously
forwarding fixture from `evidence/llvm-intops01/` or a
purpose-built fixture) must STILL observe the
`irForwardReturnSlot` rewrite. This proves the guard is
not over-broad (it does not regress the safe-case
forwarding).

## 6. IR / ABI / neutral-IR boundary changes

**NONE.** The neutral IR is unchanged.
`irForwardReturnSlot` is a pre-existing optimisation pass
whose semantics are constrained to single-predecessor exit
blocks.

## 7. Closure gates

| Gate                         | Status requirement                                        |
|------------------------------|-----------------------------------------------------------|
| `byte-memory01-test.sh`      | PASS — including `pos_b0_compare_digit` GREEN            |
| `pos_b0_compare_digit` verify| PASS — `opt --passes=verify` accepts                     |
| `i64_collapse_probe` verify  | PASS — `opt --passes=verify` accepts                     |
| `single_cond_probe` verify   | PASS — `opt --passes=verify` accepts                     |
| Negative control             | PASS — single-predecessor forwarding still observed      |
| `cap-table-verifier`         | PASS                                                      |
| `intops01-test`              | PASS=4 FAIL=0                                             |
| `spike-test`                 | PASS=18 FAIL=0                                            |
| `memory01-test`              | PASS=6 FAIL=0                                             |
| `float01-test`               | PASS=29 FAIL=0                                            |
| `factory-v2-test`            | PASS=35 FAIL=0                                            |
| `factory-append-only-test`   | PASS=11 FAIL=0                                            |
| `gate-fast`                  | VERDICT=PASS, `git diff --check` clean                    |

## 8. Out-of-scope

- changes to `src/llvm-backend.c` (defence-in-depth
  excluded; causal attribution preserved)
- GEP / pointer indexing
- `ptrtoint` / `inttoptr`
- `alloca` byte array
- `IR_STORE_DEREF` byte shape
- bitwise / shift / division opcodes
- multi-byte arbitrary-width memory
- F32 / F64 widening
- new frontend syntax
- new neutral IR opcode
- new native backend semantics
- unaligned / volatile / atomic memory
- general SSA dominance / PHI inference machinery (the
  guard is conservative-by-design; we are not building a
  general dominance-aware forwarding pass)

## 9. NEXT ACT (provisional)

After IR-RETURN-SLOT-FORWARDING01 closes, the next ACTs in
sequence are:

- `ACT-POLYC-LLVM-GEP01` — bounded GEP/indexing for arrays
  / structs (can now proceed safely; the dominance bug no
  longer lurks upstream).
- `ACT-POLYC-LLVM-STRUCT01` — struct field access.
- `ACT-POLYC-LLVM-ARRAY01` — arrays / indexing.
- `ACT-POLYC-BOOTSTRAP01` — B0: PolyC-written lexer /
  tokenizer that compiles and runs.

If after IMPL the GREEN test suite demonstrates that
`irForwardReturnSlot`-only repair is sufficient (no other
seam in `llvm-backend.c` was implicated), then
`BYTE-MEMORY01-RESUME02` may close `BYTE-MEMORY01` cleanly.
If a second seam is implicated, `BYTE-MEMORY01-RESUME02`
opens with the newly authorized second seam.

## 10. Hand-off summary (descriptive)

```text
ENTRY       = dc99882 (CORRECTION01 CLOSE)
FIRST       = <RED commit for this ACT>
CLOSE       = pending

Substance   = neutral-IR irForwardReturnSlot single-
              predecessor guard (Repair E, ~2 lines in
              src/ir-optimise.c).
RED         = pos_b0_compare_digit.HC FAIL,
              i64_collapse_probe.HC FAIL,
              single_cond_probe.HC FAIL.
GREEN       = all three + negative control + conservation.
CONSERVATION= ALREADY_SUPPORTED LLVM collapse seam
              preserved verbatim; byte-memory01-test still
              PASS=37; spike/memory01/float01 tests
              unchanged.
```

Per `docs/factory/GIT-METADATA.md`, this document is
descriptive only; the verdict authority is the CLOSE
commit's `ACT-Verdict` trailer.
