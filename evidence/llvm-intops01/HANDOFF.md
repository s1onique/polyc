# HANDOFF -- ACT-POLYC-LLVM-INTOPS01

## VERDICT

**HALT_RED_NOT_REPRODUCED (Outcome E per ACT §36)**

The ACT premise has been invalidated by fresh recon. The smallest
credible B0 lexer/tokenizer can be expressed using **only** scalar
integer operations that are already SUPPORTED in the LLVM backend.
No new integer opcode requires a real RED against an LLVM capability
seam.

This is a successful honest halt outcome, not incomplete work.

**What INTOPS01 actually proves** (F13 evidence-over-prose):

```text
B0's scalar integer arithmetic + control vocabulary is sufficient
with the current LLVM backend's supported subset. The two mechanical
probes (b0_lexer_shape_probe.HC and b0_digit_accum.HC) emit
verifier-clean LLVM IR using only IADD/ISUB/IMUL/ICMP/BR/CALL/RET/
LOAD_DEREF/STORE_DEREF.
```

**What INTOPS01 does NOT prove**:

```text
The actual B0 byte-representation path (`U8 *src` + index arithmetic
`*(src + n)` to walk source text) is sufficient. That is the explicit
mission of ACT-POLYC-LLVM-BYTE-MEMORY01 / GEP01, not INTOPS01.
```

## MISSION

Extend PolyC's LLVM backend with the scalar integer operations actually
required by the smallest credible B0 lexer/tokenizer, driven by B0
demand rather than LLVM opcode completeness.

Recon demonstrated that no scalar integer ops beyond what the LLVM
backend already supports are required by B0.

## B0 DEMAND

### Lexer sketch
see evidence/llvm-intops01/recon/b0-demand.md (262 lines).

The sketch is a single-token recognizer that:
- reads through an `I64 *src` cursor (i.e. **I64-typed** reads)
- classifies via ICMP range checks
- accumulates via IMUL+IADD (`v = v * 10 + digit`)
- writes output via STORE_DEREF through pointer parameters

Operations exercised: IR_IADD, IR_ISUB, IR_IMUL, IR_ICMP, IR_BR,
IR_CALL, IR_RET, IR_LOAD_DEREF, IR_STORE_DEREF.

Operations NOT exercised: bitwise (AND/OR/XOR/NOT), shifts, division,
remainder, conversion.

**Scope caveat (F13 evidence-over-prose)**: the probe is **I64-only**.
True B0 source-text walking needs `U8 *src` plus index arithmetic
(`*(src + n)`), which is **BYTE-MEMORY01 / GEP01 territory**, not
INTOPS01. INTOPS01 proves the scalar integer arithmetic + control
vocabulary is sufficient; it does **not** prove the byte-representation
and indexed-addressing path is sufficient. That gap is captured as
RESIDUE P1 and is the explicit mission of the next ACT.

### HCC lexer evidence
see evidence/llvm-intops01/recon/hcc-lexer-demand.md.

The existing HCC lexer (src/lexer.c) uses bitwise OR and shift only
in `lexCharConst` (character constants). For B0 (decimal integer
literals only), these are not required.

### Demand matrix
see evidence/llvm-intops01/recon/demand-matrix.tsv (27 lines, 26 rows).

Summary:
- 11 ALREADY_SUPPORTED (IADD, ISUB, IMUL, ICMP, BR/CMP_BR, CALL, RET, LOAD, STORE, LOAD_DEREF, STORE_DEREF)
- 12 DEFER (AND, OR, XOR, NOT, SHL, SHR, SAR, INEG, IDIV, UDIV, IREM, UREM)
- 3 DEFER to BYTE-MEMORY01 (TRUNC, ZEXT, SEXT)
- 0 IMPLEMENT

## AUTHORIZED SET

(see evidence/llvm-intops01/recon/authorized-set.txt)

### IMPLEMENT
    (none)

### DEFER
    IR_AND, IR_OR, IR_XOR, IR_NOT, IR_SHL, IR_SHR, IR_SAR, IR_INEG,
    IR_IDIV, IR_UDIV, IR_IREM, IR_UREM

### DEFER (to BYTE-MEMORY01)
    IR_TRUNC, IR_ZEXT, IR_SEXT

### ALREADY_SUPPORTED
    IR_IADD, IR_ISUB, IR_IMUL, IR_ICMP, IR_BR, IR_CMP_BR, IR_CALL, IR_RET,
    IR_LOAD, IR_STORE, IR_LOAD_DEREF, IR_STORE_DEREF

## SEMANTIC RECON

### Per-operation assessment (per evidence/llvm-intops01/recon/*.txt)

AND/OR/XOR/NOT (bitwise.txt):
    Source: `x & y`, `x | y`, `x ^ y`, `~x`
    Neutral IR: IR_AND, IR_OR, IR_XOR, IR_NOT
    Native AOT/JIT: SUPPORTED (x86/aarch64)
    LLVM: REJECTED (LLVM_BACKEND_UNSUPPORTED_INT_BITWISE)
    B0 demand: NO (not in B0 sketch; only `|` in lexCharConst, not B0-critical)
    Decision: DEFER

SHL/SHR/SAR (shifts.txt):
    Source: `x << n`, `x >> n`
    Neutral IR: IR_SHL, IR_SHR (logical), IR_SAR (arithmetic)
    Native AOT/JIT: SUPPORTED (with implicit count mask)
    LLVM: REJECTED (LLVM_BACKEND_UNSUPPORTED_INT_SHIFT)
    B0 demand: NO
    Semantic mismatch: LLVM `shl` with count >= bitwidth is poison;
    PolyC shifts are implicitly masked by architecture.
    Decision: DEFER (no demand; semantic mismatch unresolved)

IDIV/UDIV (division.txt):
    Source: `a / b`
    Neutral IR: IR_IDIV, IR_UDIV
    Native AOT/JIT: SUPPORTED (with /0 trap on x86)
    LLVM: REJECTED (LLVM_BACKEND_UNSUPPORTED_INT_DIVISION)
    B0 demand: NO (v*10+digit uses mul+add)
    Semantic divergence: HolyC traps on /0 (x86); LLVM has UB.
    Decision: DEFER (no demand; semantic divergence)

IREM/UREM (remainder.txt):
    Source: `a % b`
    Neutral IR: IR_IREM, IR_UREM
    Native AOT/JIT: SUPPORTED
    LLVM: REJECTED (LLVM_BACKEND_UNSUPPORTED_INT_REMAINDER)
    B0 demand: NO
    Decision: DEFER (no demand)

TRUNC/ZEXT/SEXT (conversions.txt):
    Source: `(U8)x`, `(U64)x`, etc.
    Neutral IR: IR_TRUNC, IR_ZEXT, IR_SEXT
    Native AOT/JIT: SUPPORTED
    LLVM: REJECTED (LLVM_BACKEND_UNSUPPORTED_CONVERSION)
    B0 demand: NO (I64->I8 boundary is BYTE-MEMORY01 territory)
    Decision: DEFER (defer to BYTE-MEMORY01)

## RED

(see evidence/llvm-intops01/red/RED-SUMMARY.md)

Outcome: HALT_RED_NOT_REPRODUCED (no IMPLEMENT rows).

Two mechanical-confirmation probes were authored to confirm that the
B0-required integer ops compile to clean LLVM IR via the **current**
backend:

- src/tests/llvm-intops01/b0_lexer_shape_probe.HC (single-token recognizer)
- evidence/llvm-intops01/recon/b0_digit_accum.HC (decimal accumulation)

Both pass llvm-as and opt --passes=verify.

## IMPLEMENTATION

None. Per F4 / F8 / ACT §36 Outcome E, no production code changes
were made.

## LLVM STRUCTURE

(see evidence/llvm-intops01/impl/llvm-structure.txt)

Both probes produce structurally pure LLVM IR:
- no alloca
- no GEP
- no pointer casts
- no float operations

Both pass `llvm-as` and `opt --passes=verify`.

## NATIVE PARITY

(see evidence/llvm-intops01/impl/native-parity.txt)

No new LLVM operations were added, so no new parity matrix is required.
Existing native parity for IADD/ISUB/IMUL/ICMP/BR/CALL/RET/LOAD_DEREF/
STORE_DEREF is established by SPIKE01-RESUME01 (PASS=18), CORE04-RESUME01,
and MEMORY01 (PASS=6).

PARITY01 is frozen at CLOSE (ROADMAP P3.7). On this aarch64 host, the
PARITY01 harness cannot run (no Rosetta); the host environment limitation
is documented in PARITY01's script. INTOPS01 does not modify native FP
semantics, so PARITY01's prior closure verdict remains authoritative.

## COUNTERS

(see evidence/llvm-intops01/impl/counter-matrix.txt)

Per the halt outcome, no cap-table rows were promoted. Predecessor
counters are unchanged. The cap verifier remains GREEN.

## DEFERRED OPERATIONS

(see evidence/llvm-intops01/impl/deferred-negative-matrix.txt)

12 operations (AND/OR/XOR/NOT/SHL/SHR/SAR/INEG/IDIV/UDIV/IREM/UREM)
remain REJECTED in the LLVM backend.

3 operations (TRUNC/ZEXT/SEXT) remain REJECTED and are deferred to
BYTE-MEMORY01.

## NEGATIVE CONTROLS

(see evidence/llvm-intops01/negative-controls/README.md)

Per the halt outcome, NC1/NC2/NC6/NC7/NC8 do not apply (no new
dispatch arms). NC3/NC4/NC5 are mechanically satisfied by the cap
verifier (which confirms dispatch <-> capability <-> harness bound).

## CONSERVATION

Per F10, no existing tracked files were modified. All predecessor
evidence (evidence/llvm-memory01/, evidence/llvm-float01/, etc.) is
intact. The worktree status at CLOSE shows only new (untracked) files
under evidence/llvm-intops01/, src/tests/llvm-intops01/, and
scripts/quality/llvm-intops01-test.sh.

## GATES

(see evidence/llvm-intops01/closure/gates.txt)

| Gate                          | Result | Notes                          |
|-------------------------------|--------|--------------------------------|
| scripts/quality/llvm-intops01-test.sh | PASS=4 FAIL=0 | INTOPS01 harness |
| scripts/quality/llvm-spike-test.sh    | PASS=18 FAIL=0 | SPIKE unchanged |
| scripts/quality/llvm-memory01-test.sh | PASS=6 FAIL=0 | MEMORY01 unchanged |
| scripts/quality/llvm-memory01-nc5-probe.sh load  | PASS | NC5 binding intact |
| scripts/quality/llvm-memory01-nc5-probe.sh store | PASS | NC5 binding intact |
| scripts/quality/llvm-float01-test.sh   | PASS=29 FAIL=0 | FLOAT01 unchanged |
| scripts/quality/native-x86-float-cmp-parity01-test.sh | UNAVAILABLE | host env (no Rosetta) |
| sh scripts/quality/factory-v2-test.sh  | PASS=35 FAIL=0 | Factory v2 intact |
| sh scripts/quality/gate-fast.sh        | STATUS=PASS VERDICT=PASS | |
| python3 scripts/quality/llvm-cap-table-verifier.py | PASS | dispatch<->cap bound |
| make clean && make llvm-all            | PASS | build clean |

## RESIDUE

P0 (blocks next decision): none.

P1 (important near-term work):
- B0 also needs pointer-arithmetic indexing (`*(src + n)`) to walk
  the source buffer, which MEMORY01 currently REJECTS. This is the
  planned BYTE-MEMORY01 / GEP01 ACT scope.
- B0 also needs I8/U8 byte representation; this is BYTE-MEMORY01.
- B0 may eventually need bitwise ops (e.g. for token-kind flags);
  if/when a real B0 demand is established, a follow-on ACT may
  re-open the bitwise subset.
- `scripts/quality/factory-v2-range-check.sh` requires the FIRST
  commit in a range to have `ACT-Phase=RED`. For HALTs there is no
  RED commit (HALT predates IMPL per F4 / Outcome E), so the
  per-ACT range check reports `STATUS=FAIL REASON=FIRST commit ...
  has ACT-Phase=CLOSE, expected RED`. The canonical
  `gate-fast.sh` and `factory-closure-status-check.sh` both
  PASS (PAIR_OK=6 STATUS=PASS VERDICT=PASS) because the bounded
  managed universe check correctly excludes this HALT. The
  range-checker limitation is a Factory-tooling gap (no HALT
  exception), not an INTOPS01 defect. A separate Factory ACT
  should teach the range-checker about HALT ranges.

P2 (deferred improvement): none within INTOPS01 scope.

## NEXT ACT

**NEXT_ACT = ACT-POLYC-LLVM-BYTE-MEMORY01**

Per ROADMAP P4:
- I8/U8 load/store (B0 needs bytes)
- byte -> index/comparison path
- without GEP generalization unless that ACT's recon proves the
  two cannot be separated
