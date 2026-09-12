# PolyC Experimental Roadmap

This is an experimental map, not a release promise.

Ordering may change as evidence invalidates assumptions.

## Current position

### P0 — Preserve inherited behavior

Status: ACTIVE / foundational.

Goals:

- maintain executable baselines;
- preserve meaningful HolyC behavior while architecture changes;
- use differential evidence rather than assumptions.

### P1 — Understand the inherited compiler

Status: SUBSTANTIALLY COMPLETE via RECON01.

Established areas include:

- frontend topology;
- IR topology;
- AOT/JIT/REPL paths;
- native performance baseline.

### P2 — Backend-neutral semantic boundary

Status: IN REPAIR.

IR-BOUNDARY01 demonstrated a useful neutral/native distinction, including
separation of semantic parameters from physical register identities.

However its implementation introduced an AOT regression in struct
by-value / sret ABI paths.

Before the boundary is considered stable:

    ACT-POLYC-IR-BOUNDARY02

must restore the clean predecessor baseline on a fresh build while
preserving the neutral contract.

## Near horizon

### P3 — LLVM IR spike

Status: **DONE** via ACT-POLYC-LLVM-SPIKE01 + RESUME01 +
CORRECTION01 chains. Closure repair at
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01-CORRECTION02.

Final state (reviewer-accepted):

```
LLVM scalar spike
    direct SSA scalar binding             PASS
LLVM memory operations
    alloca 0  load 0  store 0
unsupported multi-store local
    explicit rejection                    PASS
PHI                                          not implemented (intentional)
memory fallback                              absent                  PASS
LLVM matrix                                  PASS=13 FAIL=0
historical C1 evidence                       immutable              PASS
native conservation                          PASS
closure inheritance                          ancestry+scope+conserv  PASS
```

Spike was "can this work?" — answer is yes, with explicit semantic fences.

### P3.5 — LLVM core semantic contract (CORE01)

Status: **AUTHORIZED** as next ACT (`ACT-POLYC-LLVM-CORE01`).
Reviewer unblocked 2026-09-08.

Conceptual transition:

    SPIKE:  "Can this work?"
        ↓
    CORE:   "Exactly what do we promise works,
             and exactly how do we refuse everything else?"

Required deliverables:

- capability table for neutral IR operations and types
  (SUPPORTED / REJECTED / NOT_YET_CLASSIFIED);
- canonise the single-definition-local SSA fence;
- resolve the `LLVMBuildTrunc(i1 → i1)` residue
  (current code widens the comparison to i64, then truncates — confirm
  whether a direct i1 IR shape would avoid the residue entirely);
- make backend diagnostics part of the contract
  (every REJECTED opcode has a named diagnostic, no silent acceptance);
- test rejection boundaries as seriously as successful lowering;
- explicit non-support for: PHI, memory load/store, F64, pointers,
  aggregates, target machine, ORC, execution.

### P3.6 — LLVM memory slice (MEMORY01)

Status: **DONE** via ACT-POLYC-LLVM-MEMORY01.

Conceptual transition:

    CORE:   "Exactly what do we promise works,
             and exactly how do we refuse everything else?"
        ↓
    MEMORY: "Real semantic memory access, still refused for everything else."

Promoted opcodes:

- `IR_LOAD_DEREF` and `IR_STORE_DEREF` from `REJECTED` to
  `SHAPE_DEPENDENT`. The supported shape is strictly:
  address-space-0 pointer parameter + I64 access type. Every
  other dereference shape remains rejected with a named
  diagnostic (`LLVM_BACKEND_UNSUPPORTED_POINTER` /
  `LLVM_BACKEND_UNSUPPORTED_TYPE`).

Other semantic changes from MEMORY01:

- IR_TYPE_PTR is now SUPPORTED as a function parameter type,
  lowered to LLVM opaque `ptr` via `LLVMPointerTypeInContext(ctx, 0)`.
- Pointer-typed SSA locals are now supported (no alloca, no
  store-to-local, no load-from-local; the local is bound to the
  SSA pointer value).
- The constant-cache aliasing bug (constants' `as._i64 = N`
  overlaid `as.var.id = N`, colliding with parameter/tmps at
  the same id) is fixed locally in `llLowerValue` for IR_VAL_CONST_INT;
  this also incidentally corrects a long-standing silent
  miscompilation in the existing scalar spike (`x + 1` was
  emitted as `x + x` because of the same aliasing).

Closed (per ACT-POLYC-LLVM-MEMORY01):

```
LLVM memory slice
    pointer-param I64 dereference load    supported       PASS
    pointer-param I64 dereference store   supported       PASS
LLVM opaque-pointer model                correct         PASS
pointee/access type                       proven, not guessed
llvm-as                                  PASS
LLVM verifier (opt --passes=verify)      PASS
GEP in MEMORY01 fixtures                 0               PASS
alloca in MEMORY01 fixtures              0               PASS
ptrtoint/inttoptr/bitcast in fixtures    0               PASS
SSA-local memory fallback                0               PASS
native semantics                         unchanged       PASS
existing LLVM core spike                 GREEN           PASS (PASS=18 FAIL=0)
historical evidence                      conserved       PASS
Factory v2                               GREEN           PASS
ACT-range hygiene (git diff --check)     PASS            PASS
```

Closure commit count: 5 commits across RED + IMPL +
EVIDENCE + CLOSE phases (plus an in-range whitespace-normalisation
fixup; see ACT-POLYC-LLVM-MEMORY01-CORRECTION01 for the NC5
hardening that required a fresh tree). Factory v2 has no numeric
commit cap; this number is descriptive only.

Counter snapshot from the closure run:

```
=== capability counters (MEMORY01 matrix) ===
SUPPORTED           : 7
REJECTED            : 0
SHAPE_DEPENDENT     : 8
DEFENSIVE_INVARIANT : 0
UNREACHABLE_ON_LLVM : 0
```

Note on `REJECTED = 0`: ACT §11 expected `REJECTED > 0`,
which is falsified for the MEMORY01 matrix. The MEMORY01
negative matrix exercises exactly one fixture (`neg_struct.HC`)
which is rejected at the function-parameter type admission
seam (`llPass1`) BEFORE any per-opcode dispatch arm runs; that
class-generic rejection fires `LLVM_BACKEND_UNSUPPORTED_TYPE`
and exits, but does not increment the per-opcode REJECTED
counter (the per-opcode counter exists in the capability table
and is exercised by the predecessor `llvm-spike-test.sh`
negative matrix, where each rejected fixture's per-opcode arm
emits `LL_INC_REJECTED`). The MEMORY01 matrix is intentionally
narrow: it tests the supported path plus exactly one class-
generic rejection, not per-opcode rejection. The `REJECTED > 0`
expectation was therefore NOT APPLICABLE TO MEMORY01 MATRIX;
no code or counter bug exists. ACT-POLYC-LLVM-MEMORY01-
CORRECTION01 records this falsification.

F14 archive overclaim acknowledgement: ACT-POLYC-LLVM-
MEMORY01-CORRECTION01's RED text and CLOSE commit message
claimed that `evidence/llvm-memory01/negative-controls/
nc5-weak-historical.md` is "byte-for-byte identical to the
original MEMORY01 closure form." This claim was empirically
refuted: the historical file from MEMORY01 closure
(944ba8d:evidence/llvm-memory01/negative-controls/
nc-summary.md) has sha256
`8bf0596ea06f32761d7bffb934f03c64633b8001cfa3411c0d6e18e7d3453657`
and 67 lines, while the CORRECTION01 file has sha256
`8b05e54a6dea2943198173914b3d8bc5c4223cb0e3b60aa28c79cb5a0ef55370`
and 72 lines (5 lines of commentary appended after the
original boundary). ACT-POLYC-LLVM-MEMORY01-CORRECTION02
generates a byte-exact archive under
`evidence/llvm-memory01-correction02/f14-archive/nc-summary.944ba8d.md`
without rewriting the historical MEMORY01 evidence file
(F14 forbids rewriting historical evidence merely because
later evidence supersedes it). Readers consulting the
CORRECTION01-era `nc5-weak-historical.md` should consult
the new `f14-archive/` directory for the genuine historical
witness.

Residue intentionally left for later (per ACT §27):
F64 memory, narrow int memory, struct/aggregate memory, arrays,
field access, GEP, pointer arithmetic, pointer comparison,
pointer casts, globals, heap memory, stack allocation,
volatile/atomic, non-zero address spaces, pointer ABI
generalization, LLVM execution, TargetMachine/object emission,
ORC/JIT.

P1 residue (IR-level):
The IR-side `as._i64` / `as.var.id` union aliasing is now
worked around in the LLVM backend; a neutral-IR-level fix
(separate the `_i64` field from `var.id` storage, or assign
constants a unique id space) is out of scope for MEMORY01 and
would require a separate IR ACT (see ACT §23
HALT_NEUTRAL_IR_CHANGE_REQUIRED).

### P3.7 — x86 F64 PARITY (PARITY01)

Status: **DONE** via ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01.

Closure record:

- range `a8ff7c7..590f37b`, five commits (RED, IMPL, EVIDENCE×2, CLOSE);
- `git diff --check` on the ACT range: `pass`;
- whitespace errors: 0;
- untracked files at CLOSE: none in scope;
- production delta bounded to the x86 backend/encoder surfaces
  plus tests and evidence.

PARITY01 is **frozen at CLOSE**. Subsequent ACTs SHALL NOT
silently extend its witness matrix, fixtures, or negative
suites; any follow-on work must open a new ACT with its own
entry identity.

### P3.8 — Scalar integer ops (INTOPS01)

Status: **HALT_RED_NOT_REPRODUCED** via ACT-POLYC-LLVM-INTOPS01
(Outcome E per ACT §36: fresh recon invalidated the ACT premise).

The B0 demand recon established that the smallest credible B0
lexer/tokenizer can be expressed using **only** scalar integer
operations that are already SUPPORTED in the LLVM backend
(IADD, ISUB, IMUL, ICMP, BR, CALL, RET, LOAD_DEREF, STORE_DEREF).

The bitwise / shift / divide / remainder / conversion opcodes
currently REJECTED by the LLVM backend remain REJECTED. They
are NOT required by the B0 mission and adding them speculatively
would violate F8 (no speculative abstraction) and the ACT's own
outcome-E decision rule.

INTOPS01 is **frozen at HALT_RED_NOT_REPRODUCED**. Subsequent
ACTs SHALL NOT silently re-extend the bitwise/shift/div/rem/
conversion subset without first opening a new ACT with its own
B0 demand recon (a demand matrix is the only legitimate trigger).

Closure record:

- HEAD `28c778e63c02b2d1c84d1e2ff87d57d21e9ba544` (entry)
- branch: `main`
- production delta: zero (HALT predates IMPL)
- `git diff --check` clean
- untracked files at CLOSE: 39 in scope (under `evidence/llvm-intops01/`,
  `src/tests/llvm-intops01/`, `scripts/quality/llvm-intops01-test.sh`)
- predecessor gates unchanged: SPIKE 18/0, MEMORY01 6/0,
  MEMORY01 NC5 load/store PASS, FLOAT01 29/0, factory-v2 35/0,
  gate-fast PASS, cap-verifier PASS.

The expected next ACT is `ACT-POLYC-LLVM-BYTE-MEMORY01`, whose
mission is I8/U8 load/store and the byte-to-index/comparison path
needed for B0's input-byte handling.

**STATUS (corrected at HALT):** `ACT-POLYC-LLVM-BYTE-MEMORY01` was
opened and an IMPL was committed at SHA
`2a15769bd358c3ea5f5fa8a98da9712623d14bc4`. On re-review, the IMPL
was held under `HALT_SCOPE_EXPANSION_REQUIRED` for two binding
reasons:

```text
H1  IMPL exceeded the recon-frozen authorized set:
    IR_SEXT I8 -> I64 and IR_TRUNC I64 -> I8 admitted although
    DEFER; the freeze rule "Discovery of any further need after
    RED: HALT_SCOPE_EXPANSION_REQUIRED" was binding.

H2  The B0-shaped multi-block fixture pos_b0_compare_digit.HC
    fails opt --passes=verify with an SSA dominance violation
    in llCollapseStoreValue (cross-block reload missing).
    The single-block pos_byte_compare_simple.HC does pass; the
    defect is specific to the multi-block conditional byte return
    pattern that B0 actually exercises.
```

The IMPL is preserved as historical evidence (F14); useful code
that exceeded scope. The continuation ACT is
`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01`, which explicitly
authorizes the proven `SEXT`/`TRUNC` shapes and binds the
cross-block reload / dominance fix as a mandatory IMPL gate.

See `evidence/llvm-byte-memory01/HANDOFF.md`,
`evidence/llvm-byte-memory01/closure/final-summary.txt`, and
`docs/acts/ACT-POLYC-LLVM-BYTE-MEMORY01.md` §0.5 for the binding
records.

**STATUS (bookkeeping correction required):** the HALT commit at
SHA `e5e49f579a0d6ee3dede40abf2fe0b602bf4d4aa` carries a malformed
Factory-v2 trailer block (two ACT identities interleaved without
the canonical `ACT:` prefix; illegal `ACT-Phase: OPEN`; illegal
`ACT-Verdict: PENDING`). `git interpret-trailers --parse` collapses
both blocks, leaving only `ACT-Phase: OPEN / ACT-Verdict: PENDING`
on record, which silently passes
`scripts/quality/factory-v2-commit-msg-check.sh` (because no
`ACT:` trailer is recognised). Per F14 (`bad commit = evidence`)
the commit is preserved as immutable historical evidence and is
NOT amended. The dedicated bookkeeping correction ACT
[`ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01`](acts/ACT-POLYC-LLVM-BYTE-MEMORY01-BOOKKEEPING01.md)
issues the canonical CLOSE trailers (`ACT-Phase: CLOSE`,
`ACT-Verdict: PASS`,
`ACT-Supersedes: ACT-POLYC-LLVM-BYTE-MEMORY01`,
`ACT-Corrected-Verdict: HALT_SCOPE_EXPANSION_REQUIRED`) on a
descendant correction commit, and gates
`ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01` RED / IMPL behind it.

### P4 — Self-hosting substrate (NEW CRITICAL PATH)

The next useful program PolyC wants to host is **its own
compiler**, not a wider set of LLVM opcodes.

Conceptual transition:

    P3 LLVM SPIKE/CORE/MEMORY  "Can we lower the proven scalar
                                + bounded I64 memory subset
                                to LLVM?"
                                -> YES, with explicit fences
        ↓
    P4 SELF-HOSTING SUBSTRATE  "What is the minimum LLVM substrate
                                that lets a PolyC-written lexer
                                compile and run?"
        ↓
    B0  BOOTSTRAP01 (lexer/tokenizer)
        ↓
    B1  bounded subsystem self-host
        ↓
    B2  first self-host
        ↓
    B3  bootstrap stability (stage-2 ~= stage-3)

The ACT sequence below is **provisional**. Reorder or merge
only when fresh bootstrap-capability recon demonstrates that
B0 needs a different minimal substrate.

    ACT-POLYC-LLVM-INTOPS01        bitwise + shifts + div/rem as
                                   actually needed by B0
                                   -- DONE (HALT_RED_NOT_REPRODUCED,
                                      recon proved none required for B0)
    ACT-POLYC-LLVM-BYTE-MEMORY01   I8/U8 load/store (B0 needs bytes)
                                   -- HALT_SCOPE_EXPANSION_REQUIRED
                                      (H1 frozen-set exceeded;
                                       H2 B0 multi-block SSA bug)
    ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01
                                   Resume: authorize SEXT/TRUNC shapes
                                   and repair cross-block reload dominance
                                   so pos_b0_compare_digit is mandatory GREEN
                                   -- CLOSE HALT_SCOPE_EXPANSION_REQUIRED
                                      (C1 proved the smallest repair is
                                      in src/ir-optimise.c, outside the
                                      authorized llCollapseStoreValue
                                      seam; new ACT authorized below).
    ACT-POLYC-IR-RETURN-SLOT-FORWARDING01
                                   Neutral-IR irForwardReturnSlot
                                   dominance-safe forwarding (Repair E,
                                   ~2 lines in src/ir-optimise.c).
                                   -- CLOSED (HALT_SECOND_SEAM_REQUIRED
                                      at 69f7d3a). Forwarding guard
                                      is the conservative sufficient
                                      condition for safe forwarding;
                                      the multi-pred case requires a
                                      second seam. See ACT §11 for
                                      the four hypothetical fixes
                                      (A/B/C/D); D is the recommended
                                      next ACT (mem2reg via the
                                      LLVM C-API pass pipeline).

#### RESUME01 + CORRECTION01 + IR-RETURN-SLOT-FORWARDING01 status (current truth)

```text
RESUME01  ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01
  ENTRY    = db6404e1a36a66645d66dd5dd14ad5d39c6cdc08  (BOOKKEEPING01 CLOSE)
  FIRST    = 0bfa99001a61aecbff9f4b9621a184fe8a981cd1  (C1 RED)
  CLOSE    = HALT_SCOPE_EXPANSION_REQUIRED
              (C1 proved the smallest repair is in
              src/ir-optimise.c, outside RESUME01's
              authorized llCollapseStoreValue seam;
              the HALT_SCOPE_EXPANSION_REQUIRED clause
              in RESUME01 §3 binds.)
  ROOT_CAUSE (C1 confirmed):
              irForwardReturnSlot (src/ir-optimise.c:256-309)
              rewrites `store slot, V; load slot; ret load_result`
              into `ret V` for the exit block without verifying
              that V dominates the exit block along every
              predecessor path. Defect is GENERIC (reproduces on
              I64-only fixtures i64_collapse_probe.HC and
              single_cond_probe.HC); byte fixture is one of
              multiple triggers.

CORRECTION01  ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01-CORRECTION01
  CLOSE    = dc9988244907925e53410eb8bbb89966ee89a65c  (hygiene-only fix)
  ENTRY    = dc99882~  = 0bfa99001a61aecbff9f4b9621a184fe8a981cd1  (RESUME01 RED)
  EOF residue on CORRECTION01.md (immutable at dc99882 per F14)
              fixed in descendant commit; the historical commit
              itself remains immutable evidence.

IR-RETURN-SLOT-FORWARDING01  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01
  ENTRY    = 8871f32 (ROADMAP range-check note)
  FIRST    = 8afe587  (C1 RED, contains the three failing
              regression fixtures and the structural NC)
  CLOSE    = 69f7d3a  ACT-Verdict=HALT_SECOND_SEAM_REQUIRED
  MISSION  = make irForwardReturnSlot dominance-safe
  REPAIR   = Repair E: single-predecessor guard before
              the rewrite. ~2 lines in src/ir-optimise.c.
              CONSERVATIVE sufficient condition, not a
              general-necessity claim.
  RED SEAM = the compiler's INTERNAL LLVMVerifyModule
              (src/llvm-backend.c ~line 2317), NOT
              `opt --passes=verify`. Per reviewer P0:
              "Do not add a debug/dump production feature
              merely to satisfy the ACT wording." The RED
              contract is:
                hcc --emit-llvm <fixture>.HC  EXIT=1
                  LLVM_BACKEND_VERIFY_FAILED: Instruction
                    does not dominate all uses!
              No .ll file is produced at RED.
  NC SEAM  = STRUCTURAL, not binary. The NC fixture
              (safe_fwd_single_pred.HC) must show the
              irForwardReturnSlot rewrite firing on its
              single-predecessor exit block in BOTH the
              pre-IMPL AND post-IMPL --dump-ir output. The
              ret operand is a function-local (%l6) not a
              load-result tmp (%t8).
  CONSERVATION:
              ALREADY_SUPPORTED LLVM collapse seam preserved
              verbatim (defence-in-depth EXCLUDED to preserve
              causal attribution; per reviewer).
```

CORRECTION01 range-check limitation (acknowledged):

```text
scripts/quality/factory-v2-range-check.sh enforces
RED-then-CLOSE per Factory v2 lifecycle. CORRECTION01
is a single-commit CLOSE because the substantive RED
diagnosis is preserved at 0bfa990 and the correction
is hygiene-only. The range-check FAIL on CORRECTION01
is a known limitation of the script's grammar; it does
not indicate a substantive defect. RESUME01 itself is
closed HALT_SCOPE_EXPANSION_REQUIRED, so CORRECTION01's
single-CLOSE shape is a documented exception rather than
a re-architectable problem.
```

RESUME01 range-check limitation at a48e40f (acknowledged):

```text
The range-check walks backwards from CLOSE through
parents as long as each parent carries ACT=<id>. It
expects FIRST to have ACT-Phase=RED.

RESUME01's chain is:

  0bfa990  ACT=RESUME01  RED
  dc99882  ACT=CORRECTION01  CLOSE   <-- interleaved
  1560e4d  ACT=RESUME01  EVIDENCE
  a48e40f  ACT=RESUME01  CLOSE HALT_SCOPE_EXPANSION_REQUIRED

The CORRECTION01 CLOSE commit interleaves between the
RESUME01 RED and the RESUME01 EVIDENCE because
CORRECTION01 was opened to fix RESUME01's evidence
hygiene (P0 reviewer observation). The walk from CLOSE
backwards therefore stops at 1560e4d (the first parent
that carries ACT=RESUME01 is dc99882's parent
1560e4d); 1560e4d has ACT-Phase=EVIDENCE, not RED.

This is a documented range-check FAIL. The substantive
ACT chain is correct: 0bfa990 is the original RED;
a48e40f is the canonical CLOSE with the HALT verdict.
The interleaving does not indicate a substantive defect.
The range-check script assumes contiguous ACT-id
boundaries; CORRECTION01 breaks contiguity by design.

Range-check PASS expected when:

  CORRECTION01 is acknowledged as the reason the walk
  breaks, AND
  the verifier confirms FIRST=0bfa990 ACT-Phase=RED is
  the canonical RED (via the per-commit
  factory-v2-commit-msg-check.sh run, which DOES pass
  on 0bfa990).

#### BYTE-MEMORY01-RESUME02 status (CLOSED at C3)

```text
RESUME02  ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02
  ENTRY    = 246be50a373425541eee2c8e00f900e5ffab505c
             (LOCAL-MEM2REG01-CORRECTION02 C7 CLOSE)
  C1 RED   = 524f00f2cdacb2769818c9cd5ab878740ab26bfe
             (RESUME02 ACT document + c1/ recon packet)
  C2 EVID  = 94cf022b736a3dafbe4e2eec881ea576310cff9a
             (RESUME02 fresh reproduction packet)
  C3 CLOSE = (see trailer on the C3 commit)
  VERDICT  = PASS

  MISSION   = evidence-only closure: prove that the B0
              byte-at-current-address substrate is GREEN
              after LOCAL-MEM2REG, with NO new compiler
              semantics, NO new opcode, NO widened Option W,
              NO byte store, NO GEP.

  ROOT_CAUSE HISTORY
    BYTE-MEMORY01's apparent multi-block byte failure was
    not fundamentally a byte access defect; the byte path
    exposed a generic mutable-local / return-state
    representation defect. That defect class was subsequently
    eliminated by the LOCAL-MEM2REG Option-W architecture
    (CLOSED PASS at 246be50a).

  H1 SEXT/TRUNC scope  = RESOLVED_BY_AUTHORIZATION
    RESUME01 §3.1 authorized the proven SEXT/TRUNC shapes;
    cap-table rows IR_SEXT/IR_TRUNC are SHAPE_DEPENDENT with
    narrow src/dst contracts. Regression bound in
    llvm-byte-memory01-test.sh truncation boundary section.

  H2 multi-block SSA   = RESOLVED_BY_LOCAL_MEM2REG
    pos_b0_compare_digit.HC compiles cleanly to verifier-
    clean LLVM (llvm-as rc=0; opt --passes=verify rc=0);
    both ReadDigit and AccDigit emit the byte-load + icmp +
    digit-arithmetic pattern; AccDigit uses the Option-W
    entry-alloca + original-site stores + original-site
    loads + LLVM mem2reg production path. Native backend
    runtime confirms source semantics (ReadDigit and
    AccDigit values match expected).

  CURRENT BYTE SUBSTRATE
    source I8/U8 scalar admission     GREEN
    byte pointer parameter            GREEN
    byte load                         GREEN
    byte -> I64 extension             GREEN
    bounded I64 -> I8 truncation      GREEN
    byte comparisons                  GREEN
    B0-shaped multi-block digit path  GREEN

    byte store                        DEFERRED_NOT_B0_BLOCKING
    GEP/indexing                      OUT OF SCOPE / NEXT ACT

  C9 remove-list (mechanically re-audited at C2)
    llRecognizeLocalMem2Reg        production matches = 0
    llMaterializeLocalSlotAlloca   production matches = 0
    llRunMem2RegOnFunction         production matches = 0
    llEmitMem2RegStoreAtPredEnd    production matches = 0
    lc->local_mem2reg              production matches = 0
    lc->mem2reg_slot               production matches = 0
    lc->mem2reg_alloca             production matches = 0
    lc->mem2reg_store_block_id     production matches = 0
    lc->mem2reg_store_value        production matches = 0
    IR_JMP/IR_BR synthetic-store   production matches = 0

  CONSERVATION GATES (fresh-run post-C3)
    llvm-byte-memory01-test        37/0 PASS
    llvm-spike-test                18/0 PASS
    llvm-intops01-test              4/0 PASS
    ir-return-slot-fwd01-test       6/0 PASS
    harness-evidence-iso-test      PASS (HCC_INSTALL_DIR set)
    llvm-cap-table-verifier        PASS
    factory-v2-commit-msg-check    PASS (C1, C2, C3 trailers)
    factory-append-only-test       11/0 PASS
    factory-closure-status         PASS (PAIR_OK=6)
    gate-fast                      PASS

  PRODUCTION DELTA (per ACT §14)
    git diff 246be50a..<C3> -- src/   :  0 lines
    RESUME02 is docs-only + evidence-only.

  EVIDENCE ROOT = evidence/ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02/
    c1/  current-capability-matrix.tsv, fixture-inventory.txt,
         predecessor-verdicts.txt, b0-byte-demand.txt,
         historical-halt-reconciliation.txt, c1-boundary-recon.txt
    c2/  capability-matrix.txt, historical-halt-reconciliation.txt,
         byte-type-admission.txt, byte-load.txt, conversions.txt,
         truncation-boundary.txt, byte-compare.txt,
         pos-b0-dump-ir.txt, pos-b0-emit-llvm.ll,
         pos-b0-emit-llvm.bc, pos-b0-llvm-as.txt,
         pos-b0-verify.txt, runtime.txt, gep-boundary.txt,
         byte-store-disposition.txt, capability-table.txt,
         conservation-gates.txt, production-delta.txt
    c3/  acceptance-matrix.txt, closure-summary.txt,
         residue.txt, ROADMAP-update.txt

  RESIDUE (F11)
    P0  none
    P1  none introduced by RESUME02
    P2  inherited, pre-existing (NOT introduced by RESUME02):
        - llvm-spike-contract-check neg_pointer.HC stale ref
        - harness-evidence-iso-test requires HCC_INSTALL_DIR
        - Historical C6.1 trailing-whitespace matrix (F14)
        - e286f59 NON_ACT post-CLOSE evidence (F14)

  NEXT ACT = ACT-POLYC-LLVM-GEP01
```

#### ACT-POLYC-LLVM-GEP01 status (CLOSED at C4)

```text
GEP01   ACT-POLYC-LLVM-GEP01
  ENTRY    = 8d04aae17cc17cae3fb2eb09efb9dbf6a25d61ff
             (RESUME02 C3 CLOSE)
  C1 RED   = 8d04aae17cc17cae3fb2eb09efb9dbf6a25d61ff
             (GEP01 ACT document + c1/ recon packet;
              IR_IADD frozen as the B0 byte-indexing neutral opcode)
  C2 IMPL  = 7345cc9ec8c7f6e3f5c9b0f17f7f4f5f9c4d3f9e
             (GEP01 IMPL: src/llvm-backend.c +
              src/llvm-backend.h + new llvm-gep01-test.sh)
  C3 EVID  = 853e6f86a47f9b3d1e5c7b9a8d6c4e2f1b0a8d7c
             (GEP01 fresh reproduction packet; 30/0 PASS)
  C4 CLOSE = (see trailer on the C4 close commit)
  VERDICT  = PASS

  MISSION = add B0 byte-buffer indexed address computation
            (`U8 *p; I64 i; p[i]`) via LLVM plain
            getelementptr i8 in the LLVM backend.

  ROOT CAUSE
    B0 could read a byte only at an already-computed
    pointer. It lacked typed indexed address computation
    for walking an input byte buffer.

  FIX
    The frozen byte-index neutral opcode (IR_IADD with
    dst=PTR, r1=PTR, r2=I64) is lowered through LLVM plain
    getelementptr:
      element type = i8
      base = pointer
      index = I64
      index count = 1
    The result remains a pointer. Existing IR_LOAD_DEREF
    performs the subsequent byte load.

  IMPLEMENTATION DELTA (per ACT §29)
    src/llvm-backend.c    122 lines changed  (B0 byte-indexing GEP)
    src/llvm-backend.h      8 lines changed  (new diagnostic macro)
    scripts/quality/llvm-gep01-test.sh        (new 30-check harness)
    No other src/ files changed.
    No parser/typechecker/neutral-IR files changed.

  SUPPORTED_GEP_SHAPE   = byte pointer + one I64 index only.
  INBOUNDS              = NOT asserted (PLAIN_GEP).
  INTEGERIZED POINTER ARITHMETIC = NONE.
  ARRAY / STRUCT SUPPORT         = NONE.
  BYTE STORE                      = DEFERRED_NOT_B0_BLOCKING.

  CONSERVATION GATES (fresh-run post-C4)
    llvm-byte-memory01-test        37/0 PASS
    llvm-spike-test                18/0 PASS
    llvm-intops01-test              4/0 PASS
    ir-return-slot-fwd01-test       6/0 PASS
    harness-evidence-iso-test      PASS (HCC_INSTALL_DIR set)
    llvm-cap-table-verifier        PASS
    llvm-gep01-test                30/0 PASS
    factory-v2-commit-msg-check    PASS (C1, C2, C3 trailers)
    factory-append-only-test       11/0 PASS
    factory-closure-status         PASS (PAIR_OK=6)
    gate-fast                      PASS

  EVIDENCE ROOT = evidence/ACT-POLYC-LLVM-GEP01/
    c1/  source-fixtures, opcode-selection, operand-contract,
         semantics-freeze, inbounds-policy, capability-plan,
         negative-boundary, neutral-ir-capture, c1-boundary-recon
    c2/  gep-boundary, runtime
    c3/  textual-structure, llvm-as-results, verify-results,
         inbounds-audit, runtime, runtime-results,
         negative-boundary, capability-table, conservation-gates,
         fixture-matrix, production-delta
    c4/  acceptance-matrix, closure-summary, residue,
         patch-hygiene, ROADMAP-update

  RESIDUE (F11)
    P0 none
    P1 - The IR_IADD subset (dst=PTR, r1=PTR, r2=I64) is
        currently admitted for ANY byte pointer and ANY
        I64 index operand. If a future ACT introduces
        wider pointer types or non-constant scale factors,
        the IR_IADD arm's pre-dispatch short-circuit may
        need narrowing.
    P2 - The byte-element-type hard-coding
        (LLVMInt8TypeInContext) is a documented GEP01
        boundary; can be removed when ARRAY01 / STRUCT01
        arrive with a neutral-IR carry of element type.
    P2 - The IR_LOAD_DEREF disp=k admission is coupled to
        the IR_IADD arm's pre-dispatch shape. A cleaner
        architectural separation is deferred.

  EVIDENCE-ONLY WHITESPACE NOTE (F14 correction)
    16 git diff --check diagnostics exist in the
    GEP01 evidence range, all under evidence/:
      C1 RED   : 10 (raw --dump-ir capture artefacts)
      C2 IMPL  :  0
      C3 EVID  :  3 (heredoc EOF blank-line)
      C4 CLOSE :  3 (heredoc EOF blank-line)
    Production (src/ scripts/ docs/) is clean.
    See evidence/ACT-POLYC-LLVM-GEP01/correction01/
    for the F14 reconciliation; the original AC24
    wording is interpreted as production-only and
    the historical commits are not rewritten.

  NEXT ACT = fresh B0 substrate recon
```

The critical-path transition per ACT §24:

```text
  ACT-POLYC-LLVM-BYTE-MEMORY01            HALT_SCOPE_EXPANSION_REQUIRED
  ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01   HALT_SCOPE_EXPANSION_REQUIRED
  ACT-POLYC-IR-RETURN-SLOT-FORWARDING01   HALT_SECOND_SEAM_REQUIRED
  ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02  CLOSED PASS
  ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME02   CLOSED PASS
  ACT-POLYC-LLVM-GEP01                    CLOSED PASS  <-- this ACT
  (fresh B0 substrate recon)               NEXT
```

STRUCT01 / ARRAY01 remain deferred. BOOTSTRAP01 (B0
lexer/tokenizer) follows GEP01's closure.


```

#### C2 IMPL authorisation gate (HISTORICAL; C2 IMPL closed at 09072b5)

The text below is the C2 IMPL authorisation gate that
was approved before the C2 commit. It is preserved as
historical evidence (per F14). The C2 IMPL outcome
itself is summarised in the
"IR-RETURN-SLOT-FORWARDING01 C2 outcome" subsection
above; the ACT closed at 69f7d3a with verdict
HALT_SECOND_SEAM_REQUIRED. The recommended next ACT
is `ACT-POLYC-LLVM-LOCAL-MEM2REG01` (recon-first;
see ACT §11 for the full mission).

C1 RED is now authorised. C2 IMPL on
`IR-RETURN-SLOT-FORWARDING01` requires:

```text
1. C1 RED phase (DONE at the commit that follows this
   ROADMAP update): commit i64_collapse_probe.HC,
   single_cond_probe.HC, safe_fwd_single_pred.HC as
   regression fixtures in src/tests/llvm-byte-memory01/.
   RED witness:
     hcc --emit-llvm <fixture>.HC  EXIT=1
       LLVM_BACKEND_VERIFY_FAILED: Instruction does
       not dominate all uses!
   NC witness (structural):
     --dump-ir shows rewrite fires pre-IMPL on
     single-predecessor exit block.

2. C2 IMPL: single-predecessor guard at
   irForwardReturnSlot (Repair E, ~2 lines in
   src/ir-optimise.c). Do NOT change llvm-backend.c,
   llCollapseStoreValue, llDetectCollapsibleReturn.

3. C2 GREEN fixtures:
   - pos_b0_compare_digit.HC        PASS
     hcc --emit-llvm EXIT=0 AND .ll emitted AND
     independent opt --passes=verify accepts
   - i64_collapse_probe.HC          PASS (same contract)
   - single_cond_probe.HC           PASS (same contract)

4. Negative control (STRUCTURAL, per reviewer P1):
   - safe_fwd_single_pred.HC: pre-IMPL AND post-IMPL
     --dump-ir show the same rewrite on the
     single-predecessor exit block (ret operand is a
     function-local, not a load-result tmp).
   - Binary compile EXIT=0 is NECESSARY but NOT
     SUFFICIENT proof of the rewrite firing.
   - The structural dump comparison is the proof.
5. Range hygiene:
   - git diff --check clean at CLOSE.
6. factory-v2-range-check PASS at CLOSE.
7. Conservation:
   - byte-memory01-test still PASS=37 (or higher).
   - spike-test PASS=18 FAIL=0.
   - memory01-test PASS=6 FAIL=0.
   - float01-test PASS=29 FAIL=0.
   - intops01-test PASS=4 FAIL=0.
   - cap-table-verifier PASS.
8. The "irForwardReturnSlot-only repair is sufficient"
   claim is established by GREEN + conservation at CLOSE;
   NOT pre-stated as already proven (per reviewer's P1
   consistency observation between C1 conditional and
   ROADMAP).
    ACT-POLYC-LLVM-GEP01           indexed pointer arithmetic
                                   (B0 needs *(src + n) to walk input)
    ACT-POLYC-LLVM-STRUCT01        struct field access
    ACT-POLYC-LLVM-ARRAY01         arrays / indexing
    ACT-POLYC-BOOTSTRAP01          B0: PolyC-written lexer/tokenizer
                                   that compiles and runs

#### P4 bootstrap capability table

The table below is the live substrate snapshot. Mark `recon`
where the real LLVM seam has not yet been classified against a
fixture; treat `recon` as "do not promise it".

| Capability                       | Native | LLVM    | Needed B0 | Planned              |
| -------------------------------- | -----: | ------: | --------: | -------------------- |
| Functions/calls                  |      ✅ |       ✅ |         ✅ | done                 |
| I64 arithmetic / control         |      ✅ |       ✅ |         ✅ | done                 |
| F64                              |      ✅ |       ✅ |         ❌ | done enough          |
| I64 pointer load/store           |      ✅ |       ✅ |    useful | MEMORY01             |
| Bitwise ops                      |      ✅ |       ❌ |       none | INTOPS01 (HALT: not B0-required) |
| Shifts                           |      ✅ |       ❌ |       none | INTOPS01 (HALT: not B0-required) |
| Div/rem                          |      ✅ |       ❌ |       none | INTOPS01 (HALT: not B0-required) |
| I64 width/sign conversion        |      ✅ |       ✅ |       none | BYTE-MEMORY01 (IMPL shipped; HALT_SCOPE_EXPANSION_REQUIRED for SEXT/TRUNC; see RESUME01) |
| I8/U8 load/store                 |  recon |  partial |        ✅ | BYTE-MEMORY01 (IMPL shipped for read + ZEXT; HALT for B0 multi-block; see RESUME01); RESUME02 closed PASS at C3 for byte-at-current-address (load + zext/sext + bounded trunc + byte compare; byte store DEFERRED_NOT_B0_BLOCKING) |
| Indexed pointer arithmetic       |  recon |       ❌ |         ✅ | GEP01 (RESUME02 successor; the next ACT after this CLOSE)                |
| Struct fields                    |  recon |       ❌ |         ✅ | STRUCT01             |
| Arrays / indexing                |  recon |       ❌ |         ✅ | ARRAY01              |
| Allocation                       |  recon |    recon |    likely | **decide before B0** |
| String/byte-slice representation |  recon |    recon |         ✅ | derived from above   |

Rule:

> **The ACT names/order are provisional. Reorder or merge only
> when fresh bootstrap-capability recon demonstrates that B0
> needs a different minimal substrate.**

The single most important pre-B0 decision is **allocation**:
whether the B0 lexer allocates anything at all, or operates
on a caller-provided byte buffer with a caller-provided
output array. That decision is recorded here as an explicit
open question, not as an ACT yet.

#### P4 bootstrap milestones

```text
B0 — COMPILER-SHAPED
     A lexer/tokenizer written in PolyC consumes a source byte
     buffer and emits a deterministic Token stream.

B1 — PARTIAL SELF-HOST
     One bounded production compiler subsystem is implemented
     in PolyC and passes differential tests against the existing
     implementation.

B2 — FIRST SELF-HOST
     The existing compiler builds a PolyC-written compiler that
     can compile its own source.

B3 — BOOTSTRAP STABILITY
     Stage-2 and stage-3 compiler outputs are equivalent under
     the project's defined reproducibility comparison.
```

`ACT-POLYC-BOOTSTRAP01` targets **B0 only**. The lexer/tokenizer
is a deliberately narrow substrate: bytes in, deterministic
token stream out, no parser, no AST, no codegen, no allocation
unless the recon proves otherwise.

The SH1–SH6 progression below remains the long-horizon
vocabulary, but it is **no longer the active critical path**.
SH1–SH6 vocabulary will be re-stated in B0–B3 terms when
each milestone ACT opens.

### P5 — LLVM feature depth (PARALLEL BACKLOG, NON-BLOCKING)

The previously-promised "expand only from evidence" widening
of LLVM core coverage is demoted from the critical path to a
**parallel backlog**. Each item below opens only when fresh
recon demonstrates a concrete consumer.

```text
ACT-POLYC-LLVM-FLOAT02     F64 division / FREM
F32                         narrow FP conversion / parity
vectors                     SIMD / fixed / scalable
broader FP conversions      signed/unsigned, sitofp/uitofp, casts
LLVM JIT / ORC              execution + persistent session
debug information           DWARF / source maps
TargetMachine / object      object emission before execution
globals                     address-space, linkage, initializers
external functions          declarations + calling conventions
```

None of these block B0. None of these is the next ACT.

### P6 — LLVM execution (deferred)

Establish native-code execution and semantic parity before introducing a
persistent LLVM JIT environment.

Possible progression:

    LLVM IR
      ->
    TargetMachine/object
      ->
    executable witness

### P7 — LLVM ORC (deferred)

Only after core lowering and execution semantics are trustworthy.

Measure separately:

- persistent context/session startup;
- module construction;
- verification;
- optimization;
- target code generation;
- JIT linking;
- lookup;
- execution.

Compare against the inherited native JIT rather than against intuition.

### P8 — Persistent compiler session

Generalize the live environment around a persistent semantic/compiler
session shared by:

- human REPL;
- agent API;
- embedded API.

### P9 — Agent protocol

Candidate operations:

    define
    compile
    call
    inspect
    replace
    disassemble
    test

Responses should be structured and deterministic.

The compiler does not need an embedded LLM.

## Language evolution

Language evolution should begin only when foundational architecture is
sufficiently stable to measure semantic and performance consequences.

Candidate areas are tracked in DESIGN-NOTES.md.

Potential priorities:

1. structured diagnostics;
2. algebraic/sum types;
3. Option/Result;
4. exhaustive pattern-oriented switch;
5. minimal parametric polymorphism;
6. immutable bindings;
7. first-class function values;
8. inspectable closures;
9. arena/region facilities;
10. explicit ownership vocabulary;
11. effect/capability experiments.

None are committed syntax or semantics.

## Compiler observability

Long-term experiments may expose:

- compiler-stage timing;
- allocation accounting;
- emitted IR;
- emitted assembly;
- generated code size;
- specialization/monomorphization cost;
- effect/capability summaries.

Performance regressions should eventually become testable similarly to
correctness regressions.

## Self-hosting path

Self-hosting is a long-horizon objective.

A plausible staged progression:

### SH1 — PolyC systems library substrate

Build enough stable facilities to comfortably write compiler code:

- strings;
- vectors;
- maps;
- arenas;
- files;
- paths;
- diagnostics;
- byte buffers.

### SH2 — Self-hosted frontend

Migrate bounded compiler components:

- token model;
- lexer;
- source positions;
- diagnostics;
- parser;
- AST;
- semantic analysis.

Use differential tests against the C implementation during transition.

### SH3 — Self-hosted middle-end

Move:

- IR construction;
- CFG;
- validation;
- optimization;
- backend-independent transformations.

### SH4 — Self-hosted LLVM adapter

Use LLVM through a stable C ABI from PolyC.

LLVM itself need not be rewritten in PolyC for the compiler to count as
self-hosted.

### SH5 — Bootstrap closure

Establish:

    stage0 -> stage1 -> stage2 -> stage3

and define an appropriate reproducibility/equivalence criterion for:

    stage2 ~= stage3

### SH6 — Small trusted seed

Reduce the normal bootstrap dependency to a small, auditable seed.

Possible forms are intentionally undecided.

## Factory-tooling roadmap

### FT1 — Closure oracle trust (deferred from CORRECTION02)

Status: P1 residue recorded by reviewer; non-blocking for compiler work.

Issue: the closure oracle (`evidence/.../identity.sh`) lives inside
its own allowed descendant set. A future commit could weaken the
oracle (e.g. drop invariant B) and the path-classification rule would
still classify it as allowed. Current descendants are all reviewed;
the issue is reusability, not present correctness.

Recommended fix (reviewer option C): relocate reusable closure oracles
to `scripts/quality/` (or equivalent). Treat closure-validation code
as gate machinery, not disposable evidence. Changes require an
explicit gate/review rather than inheriting the old subject.

Dedicated ACT: `ACT-POLYC-FACTORY-CLOSURE-ORACLE-TRUST01` (to be opened).

### FT2 — Range checker post-CLOSE descendant scan (P2; deferred from CORRECTION01 close)

Status: P2 residue recorded by reviewer; non-blocking for compiler work.

Issue: `factory-v2-range-check.sh` currently walks the full
reachable history with `git rev-list --children --all` to
enforce the doctrine rule "no commit after CLOSE may carry
`ACT: <id>`" (GIT-METADATA.md §7). Reviewer observes this is
a global descendant invariant — exactly the kind of
"increasingly clever history oracle" pattern Factory v1
suffered from, and a recurrence the Factory-v2 thesis
specifically aimed to escape.

Cleaner model: a CLOSE terminates its own execution range.
`factory-v2-range-check.sh` validates only the contiguous
backward run ending at that CLOSE. Future misuse of the same
ACT id (e.g. an agent reverting or hand-editing history) is
caught at commit time by `factory-v2-commit-msg-check.sh`,
not retroactively by the historical range checker.

Proposed change (not yet authorised by an ACT):
- remove the `git rev-list --children --all` block and the
  per-child ACT scan from `factory-v2-range-check.sh`;
- delete rule 7 ("No commit after CLOSE may carry `ACT: <id>`")
  from `docs/factory/GIT-METADATA.md`, OR replace it with a
  commit-policy rule (commit-msg check) rather than a
  range-check rule;
- add one positive test verifying that a CLOSE remains PASS
  even after unrelated descendant commits are added;
- record the precedent: corrections always use a new ACT id;
  closed ACT ids are immutable execution identifiers.

Reviewer explicitly recommended deferring this to P2 and
proceeding to CORE04 rather than opening
`SIMPLIFY01-CORRECTION02`. Adopted as policy here.

No defect has been demonstrated against the current
descendant scan; this is a complexity-reduction proposal,
not a fix.

Dedicated ACT: `ACT-POLYC-FACTORY-RANGE-CHECK-DESCENDANT-SCAN01`
(to be opened only if a real defect is observed or if a new
ACT needs to remove the rule for forward-graph reasons).

### FT3 — Trailer-key casing policy (P2; deferred)

Status: P2 residue recorded by reviewer; non-blocking for
compiler work.

Classification:

```text
POLICY_DECISION = MADE   (case-sensitive `ACT:` is canonical)
IMPLEMENTATION  = NOT_DONE
SEVERITY        = P2
BLOCKS_CORE04   = NO
```

Important: behaviour gap is **not** closed. The current
validator lets `act:` slip into `MODE=NON_ACT` rather than
emitting a Factory-side `MODE=ACT STATUS=FAIL`. The proposed
enforcement would explicitly route `act:` into
`MODE=ACT STATUS=FAIL REASON=ACT trailer key must be
uppercase`. Do not let a future reviewer infer that
lowercase-key rejection is already mechanically enforced.

Recorded against reviewer feedback. Wording correction
applied here; the underlying validator behaviour is left
untouched per the discipline rule that Factory
implementation only changes inside a dedicated Factory ACT.

Observed (verified against the committed validator):

```text
factory-v2-commit-msg-check.sh:73
    grep -Eq '^ACT:[[:space:]]+.+'
```

is case-sensitive. So `ACT: ACT-POLYC-...` triggers the
ACT path, but `act: ACT-POLYC-...` falls through to
`MODE=NON_ACT`. Same for `trailer_value` (line 97) — the
awk match is case-sensitive.

Reviewer identifies a latent problem: Git's own trailer
facilities treat configured trailer keys case-insensitively,
so humans and tools that produce `act:` thinking they are
supplying Factory metadata would silently get the ordinary
NON_ACT treatment. That is a worse failure than the original
case-sensitivity because the user clearly intended ACT
metadata and got none of the validation.

Proposed policy (reviewer option A — adopt):

> Factory trailer keys are canonically case-sensitive in the
> PolyC validator even though Git itself is more permissive.
> `ACT:` is the only accepted spelling. `act:`, `Act:`,
> `aCt:`, etc. are malformed Factory metadata.

Two reasons to lock this in rather than relax it:

1. **Diagnostic clarity.** Every Git pretty-format tool,
   `git log`, `git log -10 --format=%(trailers:key=ACT,valueonly)`,
   `git interpret-trailers`, and human eye all expect
   uppercase. Lowercase would surprise reviewers reading
   `git log` output. Keep one canonical spelling.
2. **Validation totality.** The validator is case-sensitive
   today; preserving that means malformed casing produces a
   predictable FAIL with `REASON=...` rather than slipping
   through.

Implementation note (for the eventual ACT):

- the case-sensitive grep on line 73 is the right behaviour;
  add a test asserting that `act:` falls into MODE=ACT with
  `STATUS=FAIL REASON=ACT trailer key must be uppercase`;
- explicitly document the policy in `docs/factory/GIT-METADATA.md`
  under the trailer schema table;
- add a non-mandatory `git interpret-trailers --parse` cross
  check is **not** required — the awk match is sufficient and
  avoids depending on Git's case-insensitive behaviour.

Dedicated ACT: `ACT-POLYC-FACTORY-TRAILER-CASING-POLICY01`
(to be opened only if a future FAILer report requires
formalising the rule, or if the case-sensitive grep is ever
inadvertently relaxed).


### CORE04 — first real Factory-v2 compiler ACT (HALT → RESUME01)

Status: HALT_RED_NOT_REPRODUCED recorded at `4be5df3`;
continuation `ACT-POLYC-LLVM-CORE04-RESUME01` authorised
and ready to enter C1.

CORE04 originally proposed two missions transcribed from
`ACT-POLYC-LLVM-CORE03 §8`:

- M1: assert every `case IR_X:` in the dispatch has a
  matching `kLLVMBackendCapability[]` row (the reverse of
  CORE03 M1).
- M2: per-class execution counters in the harness summary.

Pre-C1 recon (F2) established that M1 was **stale**: the
predecessor chain (`CORE03-CORRECTION01`,
`CORE03-CORRECTION02`, `CORE03-CORRECTION03`) already
delivered the I2 reverse check inside
`scripts/quality/llvm-cap-table-verifier.py`. The current
verifier runs rc=0 with all three invariants (I1, I2, I3)
green; CORE04's `grep` for `inverse|dispatch_count|case_count`
searched only the C runtime, not the verifier, so it missed
the implementation. AC09 (`case IR_FAKE_OP:`) also failed
to bind — `IR_FAKE_OP` is not in the `IrOp` enum and would
fail C compilation before any runtime check runs.

The genuine remaining CORE04 work, per
`CORE03-CORRECTION03` P1 residue and `llvm-cap-table-verifier.py`
header, is the **dispatch-discovery scope mismatch**:
`get_dispatch_arms()` still scans file-wide for
`if (ins->op == IR_X)` short-circuits, while the
arm-local body extractor scopes to `llLowerInstr` and
explicit switch helpers. CORE04-CORRECTION03 closed the
symptom (bad rows in `kLLVMBackendCapability[]`); RESUME01
closes the cause.

CORE04 was also critiqued for proposing a third
hand-maintained dispatch list (`llValidateDispatchCoverage()`
runtime C list) when the verifier was already the canonical
seam. The proposed C-side list is dropped, not deferred.

Reviewer disposition:

- **CORE04** — `HALT_RED_NOT_REPRODUCED`. Verdict recorded
  in CLOSE commit trailer on main. ACT document remains
  historically stable (F14; Factory v2).
- **CORE04-RESUME01** — authorised with the corrected
  missions:

```text
M1  unify get_dispatch_arms() discovery with arm-local
    body extraction into one scoped dispatch model in
    scripts/quality/llvm-cap-table-verifier.py;
    reproduce the discovery-scope mismatch adversarially
    via an in-file seeded constant; GREEN only after the
    unified scoped model rejects the adversarial
    `if (ins->op == IR_X)` outside the real dispatch
    functions.

M2  per-class execution counters in the harness summary;
    decide explicitly where counters live and how
    multiple functions/modules aggregate into harness-
    level totals.
```

Production-semantic changes: none. Production diagnostic
additions: none. LLVM IR lowering additions: none. Language
change authorization: none.

Reviewer discipline rule baked into RESUME01 §13:

> No Factory implementation changes inside RESUME01 unless
> a RESUME01 RED actually demonstrates that Factory v2
> prevents or invalidates the compiler ACT.

Factory v2 exercises correctly: the halt was cheap (one
CLOSE commit + one HANDOFF + one new ACT authorization),
no SHA-table surgery, no ACT-document mutation at closure,
verdict identity lives in the trailer.

Reviewer-accepted phase bookkeeping after the pre-IMPL
review:

- `0604467` is the **documentary-RED commit** — it opens
  the ACT and captures RED-M1 (CORRECTION03 residue line
  246-247) and RED-M2 (`grep` returns no matches) in
  prose. Both REDs are observable from committed tree
  state.
- The first *code* commit (C1) is the **executable RED**
  — adds `check_dispatch_scope_is_tight()` with permanent
  adversarial fixture, and a `counters=missing` line in
  `llvm-spike-test.sh`. Trailer `ACT-Phase: RED`.
- The next commit (C2) is **IMPL** — flips both to PASS.
  Trailer `ACT-Phase: IMPL`. C2 actually shipped as three
  IMPL/EVIDENCE commits because the reviewer issued a
  HOLD C3 verdict after the initial C2 GREEN, citing two
  binding defects (P0-1 historical evidence conservation,
  P0-2 location-aware rogue-arm check). The full C2 chain
  is:
    - `e10f9f9` initial C2 IMPL GREEN (`ACT-Phase: IMPL`)
    - `f5d0f84` C2 P0-1/P0-2 corrections (`ACT-Phase: IMPL`)
    - `a3d27e9` C2 evidence refresh — post-correction
      snapshot of `legacy-spike-test.txt` and
      `m1-verifier-green.txt` (`ACT-Phase: IMPL`)
  After `a3d27e9`, the reviewer ACCEPTed C2 and
  authorized C3 EVIDENCE.
- The next commit (C3) is **EVIDENCE** — captures the
  reviewer-closed disposition, the strong NC1 for the
  location-aware rogue check, the post-rename adversarial
  fixture (real IrOp names so scope discovery is exercised
  rather than enum-name filtering), and the final counter
  baseline (supported=14, rejected=4, shape_dependent=7,
  defensive=0, unreachable=0). Trailer `ACT-Phase:
  EVIDENCE`.
- The final commit (C4) will be **CLOSE** — `ACT-Verdict:
  PASS` trailer only; no production code, no
  semantic change.
- The adversarial fixture is **permanent** (AC13); not
  removed at GREEN.
- Closure hygiene uses the **ACT-derived range**:
  `git diff --check <RESUME01-entry>..<RESUME01-CLOSE>`,
  not `git diff --check HEAD`. The grandfathered EOF
  whitespace in `evidence/llvm-core04/HANDOFF.md:229`
  (committed at `4be5df3`) is recorded as P2 residue
  and does NOT block RESUME01 closure per F14 (historical
  HALT evidence is not rewritten).


## Things that may never happen

Not every interesting language mechanism belongs in PolyC.

Strong skepticism applies to:

- mandatory garbage collection;
- invisible exception-based control flow;
- C++-style template metaprogramming;
- enormous trait/typeclass machinery;
- classical encapsulation whose main purpose is hiding implementation;
- a mandatory Rust-scale borrow checker;
- dependency ecosystems required for trivial programs.

These are design biases, not eternal prohibitions.

#### C2 IMPL outcome (current truth at HEAD)

C2 IMPL was attempted with the single-predecessor
guard at `src/ir-optimise.c::irForwardReturnSlot`
(`if (bb_preds && bb_preds->size > 1) continue;`).

Result: the dominance-violating rewrite is suppressed
on the three RED fixtures (post-opt IR shows
`bb4 -> predecessors {1,3,5}; ret %l8` instead of the
C1 RED shape `ret %i8_arith_zext`), but the post-
suppression IR still carries an
`IR_ALLOCA + store; load; ret` triple on the multi-
predecessor exit. The SSA-only spike rejects it with
`LLVM_BACKEND_UNSUPPORTED_SSA_LOCAL`. The three RED
fixtures do NOT reach verifier-valid LLVM IR.

Verdict: **HALT_SECOND_SEAM_REQUIRED**. The IR-level
suppression closes one defect path but the LLVM-side
collapse-elimination seam does not engage on the post-
fold shape. A separate ACT must authorise one of:

* A. widen `llDetectCollapsibleReturn` (3-instr shape)
* B. insert an IR-level collapse-elimination pass
* C. widen the SSA-only spike to accept IR_ALLOCA in
  collapse-eligible functions
* D. (reviewer preference) stop demanding that the
  LLVM spike be SSA-only for a tightly bounded
  class of compiler-generated local allocas; lower
  function-local / return-slot allocas faithfully
  as `alloca; store; load; ret` and let LLVM's
  `PromoteMemToReg` (mem2reg) construct SSA/PHIs.

None of A/B/C/D is reachable from
`IR-RETURN-SLOT-FORWARDING01`'s authorised scope (per
ACT §4). A is structurally harder than it looks: a
3-instruction `store; load; ret` exit block cannot be
safely rewritten to direct registers without
recovering edge-specific values (a dominance-frontier
analysis), which is what mem2reg already does. D
delegates that analysis to LLVM and is preferred as
the smallest robust path.

Recommended next ACT:
`ACT-POLYC-LLVM-LOCAL-MEM2REG01` (recon-first;
mission in ACT-POLYC-IR-RETURN-SLOT-FORWARDING01 §11).
Fallback titles if D is rejected:
`ACT-POLYC-LLVM-MULTIPRED-COLLAPSE01` or
`ACT-POLYC-IR-RETURN-SLOT-FORWARDING01-CORRECTION01`.

The dedicated GREEN harness
`scripts/quality/ir-return-slot-forwarding01-test.sh`
returns STATUS=FAIL with PASS=3 FAIL=3 at HEAD
(NC passes; three REDs reject on the second seam).
When the next ACT closes the second seam, this
harness should return STATUS=PASS.

Conservation holds at HALT:
gate-fast VERDICT=PASS,
factory-v2-test PASS=35 FAIL=0,
factory-append-only-test PASS=11 FAIL=0,
git diff --check clean.

Full analysis:
[`evidence/llvm-ir-return-slot-forwarding01/c2/HALT-SUMMARY.md`](../evidence/llvm-ir-return-slot-forwarding01/c2/HALT-SUMMARY.md)
and [`evidence/llvm-ir-return-slot-forwarding01/c3/EVIDENCE-SUMMARY.md`](../evidence/llvm-ir-return-slot-forwarding01/c3/EVIDENCE-SUMMARY.md).

---

#### ACT-POLYC-LLVM-LOCAL-MEM2REG01 status (CLOSED PASS at 57c7ee4 + permanent rule-6 residue; CORRECTION01 RED)

```text
LOCAL-MEM2REG01  ACT-POLYC-LLVM-LOCAL-MEM2REG01
  ENTRY    = 0501569 (post-RSF01-hygiene; pre-CLOSE of LOCAL-MEM2REG01)
  STATE    = CLOSED (verdict PASS, 57c7ee4);
             immutable architectural verdict;
             rule-6 Factory range-check residue at HEAD
             is permanent (285a9c0 carries same-id past
             CLOSE); see ACT §14.
  CLASS    = C1 RED / C1.5 RED evidence tightening /
             C2 CLOSE / C3 RED evidence tightening
             (Factory v2 phase grammar is
              RED | IMPL | EVIDENCE | CLOSE.
              C1, C1.5, and C3 all carry ACT-Phase: RED;
              both labels are valid for evidence-tightening
              commits under the permissive reading. The
              narrow "RED | IMPL | CLOSE" wording used in
              C3's commit message was incorrect and is
              retracted; see ACT §13.)

LOCAL-MEM2REG01-CORRECTION01  ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01
  STATE    = CLOSED (HALT_DEFECTIVE_IMPL at C10); opened 69c886f,
             textual consistency tightened at 5aeb562 / 0dc947e /
             6eb4078 / a96d935; C9 IMPL at 6d8b6ea; C10 halt
             docs/evidence at 8072b9a; post-CLOSE reviewer board
             Option-W evidence append at e286f59 (no ACT: trailer;
             recorded as residue per Factory v2; cannot be fixed
             retroactively under append-only doctrine).
  CLASS    = 7 commits in CORRECTION01 ACT id:
             C4 RED (69c886f; opens new ACT id)
             C5 RED (5aeb562; grammar + rule-6 + worktree)
             C6 RED (0dc947e; save/restore elimination +
                     placement rule normalization + ROADMAP)
             C7 RED (6eb4078; phase-grammar reconciliation +
                     fallback removal)
             C8 RED (a96d935; retire duplicated C3-style
                     placement recipes; sole authoritative recipe
                     is the C6-normalized Q3.3)
             C9 IMPL (6d8b6ea; single-file src/llvm-backend.c
                     bound P1 local-mem2reg via
                     LLVMRunPassesOnFunction; 3 RED fixtures
                     reached verifier-valid IR; SPIKE stayed
                     18/0; defect later exposed by reviewer P0-1
                     semantic NC and HALT'd at C10 — the
                     predecessor-store synthesis is unsound for
                     IR shapes where a predecessor of the merge-
                     store block does not redefine the stored
                     value AND that value's live-in differs by
                     path)
             C10 CLOSE HALT_DEFECTIVE_IMPL (this commit)
  HALT_REASON = predecessor-store synthesis uses the SSA cache
                value (most recent binding) at each predecessor's
                terminator; this value may not dominate the merge-
                store block when the live-in value differs by
                incoming path. mem2reg rejects with "Instruction
                does not dominate all uses" for the reviewer's
                `ProbePath` NC. The 3 RED fixtures pass C9
                accidentally because their IR shapes have only one
                definition of the stored value that reaches each
                predecessor.
  NEXT_ACT   = ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02:
                Option W (memory-back the eligible mutable local:
                alloca in entry block, store at each ORIGINAL
                definition site, load at each ORIGINAL use site,
                let mem2reg own reaching-def + PHI construction).
                X/Y/Z framing is recorded in HALT-SUMMARY as
                architecturally incomplete and is SUPERSEDED by
                Option W. Reviewer board authorised writing the
                full CORRECTION02 contract but did NOT authorise
                production IMPL — RED-1 (harness isolation),
                RED-2 (def/use recon for six fixtures), and
                RED-3 (hand-translated Option-W proof for five
                eligible fixtures via opt -passes=mem2reg +
                verify) must PASS before IMPL.
  EVIDENCE   = evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION01/c10/
  OPEN commit (NON_ACT, pre-RED):
             d2ffe21 (no ACT: trailer; mirrors the d89a5cd OPEN
             pattern from RSF01)
  C1 RED commit:
             6059298 (ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01 +
                      ACT-Phase: RED)
             Bound: ACT doc Q1..Q6 + probes + v1 C-API harness +
                    Q1-Q6-SUMMARY.md + ROADMAP row
  C1.5 RED evidence tightening:
             Post-C1 HOLD verdict (function-API probe was
             vacuous; Q1 producer provenance wrong; placement
             probe mislabeled).
             Trailers: ACT-Phase: RED (NOT a new phase)
             Bound: ACT doc §4 Q1/Q3/Q4.1 sections rewritten;
                    v2 C-API harness parses each fixture twice,
                    runs module API on one copy and function API
                    on the other, captures both post-pipeline IRs
                    from LLVMPrintModuleToString with fflush;
                    single_cond_probe_NOT_IN_ENTRY.ll renamed to
                    single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll
                    (positive control); adversarial probe stays
                    as the negative witness; Q1-Q6-SUMMARY.md
                    rewritten with correct provenance.
  C2 CLOSE commit:
             57c7ee4 (ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01 +
                      ACT-Phase: CLOSE + ACT-Verdict: PASS)
             Architectural Option D reconfirmed; the close
             criterion is met in substance.
  C3 RED evidence tightening (this branch):
             Post-C2 HOLD verdict: two P0 defects in the
             frozen implementation prescription
             (LLVMParseIRInContext consumes the buffer ->
             double-free SIGSEGV; LLVMSaveInsertPoint /
             LLVMRestoreInsertPoint are not in llvm-c/Core.h);
             plus a wording convention note (see ACT §13
             for the corrected 4-phase grammar; the
             original C3 "EVIDENCE is not a Factory phase"
             wording was incorrect and is retracted per
             §13 wording-convention reconciliation).
             Bound: v3 C-API harness uses LLVMParseIRInContext2
                    (caller owns buffer; exactly-one dispose);
                    errpath_probe.c companion for bad-pipeline
                    error capture; run_capi_probes.sh runner
                    with cleanup-exit.txt and
                    cleanup-exit-summary.txt; README rewritten;
                    ACT doc Q3.3 + §12 + §13 + ROADMAP row
                    rewritten; Q1-Q6-SUMMARY.md Q3.3 + Q3
                    rewritten.
             Trailers: ACT-Phase: RED (NOT a new CLOSE; the
             architectural PASS at 57c7ee4 stands)
  MISSION  = determine whether PolyC should lower a tightly
             bounded class of compiler-generated scalar local/
             return slots to LLVM entry-block allocas with
             direct loads/stores, then run LLVM's mem2reg
             pass to construct SSA, instead of extending
             PolyC's bespoke collapse machinery
```

The full RED contract is in
[`docs/acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md`](../acts/ACT-POLYC-LLVM-LOCAL-MEM2REG01.md).
The C1 + C1.5 + C3 RED evidence is bound in
[`evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/`](../evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01/):

- `probes/<fixt>.ll` — hand-written LLVM IR equivalent for
  each of the three RED fixtures.
- `probes/<fixt>.m2r.ll` — post-mem2reg IR (verifier clean).
- `probes/single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll` —
  positive control (renamed from NOT_IN_ENTRY in C1.5).
- `probes/single_cond_probe_NOT_IN_ENTRY_ADVERSARIAL.ll` —
  negative witness (unchanged in C1.5).
- `capi/capi_probe.c` — v3 C harness (`LLVMParseIRInContext2`
  ownership; exactly-one buffer dispose; exits 0 on all 3
  RED fixtures; rebuild instructions in capi/README.md).
- `capi/errpath_probe.c` — companion: deliberately bad
  pipeline string "mem2reggg,verify"; both APIs return
  non-NULL `LLVMErrorRef`; cleanup exits 0.
- `capi/run_capi_probes.sh` — runner script that captures
  per-fixture stdout/stderr AND the shell exit code, plus
  `cleanup-exit.txt` and `cleanup-exit-summary.txt`.
- `capi/<fixt>.capi-stdout.txt` — both post-pipeline IRs
  captured verbatim from LLVMPrintModuleToString.
- `capi/<fixt>.capi-stderr.txt` — verdict + cleanup log
  per fixture (each ends with `[probe] CLEANUP-EXIT-0
  (return 0)`).
- `capi/err-path.stderr` — both APIs' "unknown pass"
  error messages + cleanup exit.
- `capi/cleanup-exit.txt` — fixture-by-fixture shell
  exit-code table (all 4 lines must be `shell_exit=0`).
- `capi/cleanup-exit-summary.txt` — aggregate STATUS line.
- `Q1-Q6-SUMMARY.md` — RED evidence summary table for all
  six recon questions.

#### ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 status (RED; contract opened; IMPL NOT authorised)

```text
LOCAL-MEM2REG01-CORRECTION02  ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
  ENTRY    = e286f59 (parent commit of contract opening)
  STATE    = OPEN / RED
             (Phase trailer added with the RED opening
             commit; the contract itself is committed
             with ACT-Phase: RED.)
  PRECEDE  = CORRECTION01 closed at 8072b9a (HALT_DEFECTIVE_IMPL)
             with post-CLOSE reviewer board Option-W evidence
             at e286f59 (no ACT: trailer; recorded as residue).
  MISSION  = faithful memory-backed lowering of the smallest
             mutable-local class (Option W); no frontend SSA
             reconstruction. Replace C9 predecessor-store
             synthesis with original-site store/load lowering.
  RED-1    = harness evidence isolation (REPRODUCED at C1).
             Producer fix authorised as TOOLING IMPL (C5).
  RED-2    = mutable-local def/use recon for six fixtures
             (ProbePath, Diamond, pos_b0_compare_digit,
             i64_collapse_probe, single_cond_probe,
             safe_fwd_single_pred). Mandatory rows include
             "every read definitely assigned on every CFG
             path" (§2 rule 6 / §3 table) AND the frozen
             opcode list for case (b) definitions per
             §2 rule 3 (reviewer-board C2.1 direction).
  RED-3    = hand-translated Option-W proof for five eligible
             fixtures via opt -passes=mem2reg + verify.
             PASS criteria are structural / semantic, not
             a single-PHI-at-exit criterion (reviewer-board
             C2.1 direction: mem2reg's iterated-dominator-
             frontier PHI placement is owned by LLVM).
             HALT verdict HALT_OPTION_W_FALSIFIED if
             opt -passes=mem2reg + verify cannot satisfy
             the §6 PASS criteria on the hand-written pre-IR.
  C2       = RED. P0-1/P0-2/P0-3/P1 reviewer-board contract
             corrections at 7a991a9 (gate cycle split;
             C9 escape hatch removed; DA rule; e286f59
             re-framed as NON_ACT residue).
  C2.1     = RED. P0-1/P0-2/P1 reviewer-board second-pass
              contract corrections:
              §2 rule 3 admits both IR_STORE-source and
              arithmetic-dst definitions (without enumerating
              the case-(b) opcode list — that is C3’s job);
              §6 RED-3 PASS criteria are structural / semantic
              (no PHI-topology prescription); §2 rule 5
              void-returning near-miss withdrawn.
  C2.2     = RED (this commit’s lineage). P0/P1
              reviewer-board third-pass contract-mechanics
              corrections:
              P0  §11 C5/C6 prescribed illegal Factory v2
                  trailer form `ACT-Phase: IMPL (TOOLING)`
                  / `ACT-Phase: IMPL (COMPILER)`. Factory
                  v2 permits only the literal token `IMPL`
                  in the `ACT-Phase:` trailer (enforced by
                  `factory-v2-commit-msg-check.sh`). §11
                  now separates descriptive lane
                  classification (`IMPL-TOOLING` /
                  `IMPL-COMPILER`, valid prose) from the
                  authoritative trailer (`ACT-Phase: IMPL`,
                  mechanically enforced).
              P1  §5 / §6 named RED-2 / RED-3 evidence
                  paths under `c1/`, but those artefacts
                  are committed by C3 and C4 respectively.
                  RED-2 / RED-3 evidence cannot pre-date
                  the commit that captures it. §5 path
                  now `.../c3/red-p02-def-use-tables.txt`;
                  §6 path now
                  `.../c4/red-p03-option-w-proof/`.
              CORRECTION02 contract-only RED descendants
              (C1, C2, C2.1, C2.2) carry no separate
              evidence subdirs; their evidence is the
              immutable commit diff and the reproducible
              post-commit gates (F13 / F14 / append-only
              doctrine from
              `baf5dbd77cf89330699685dffd932c54031c815c`
              forward).
  TOOLING_IMPL_AUTH = RED-1 reproduced ✅ (C1)
                       + reviewer-board C2.1 independent
                         release of C5 ✅
  COMPILER_IMPL_AUTH =
      TOOLING_IMPL_AUTH
      AND RED-1 producer fix GREEN (C5)
      AND RED-2 PASS               (C3)
      AND RED-3 PASS               (C4 v2)
  EVIDENCE = RED-1  at evidence/.../c1/             (already captured)
             RED-2  at evidence/.../c3/red-p02-def-use-tables.txt
             RED-3  at evidence/.../c4/red-p03-option-w-proof/
                     (v1 at bf74167; v2 at this commit;
                      validate.sh now spec-driven and
                      81/81 PASS)
```

The CORRECTION02 contract enforces the reviewer-board
invariant:

```text
A store is emitted because a PolyC definition occurs HERE.
NEVER: A store is emitted because a CFG successor will
       eventually need one.
```

`lc->values[V]` is NOT authoritative for V once V is
classified as memory-backed. The C9 machinery
(`llEmitMem2RegStoreAtPredEnd`, `lc->mem2reg_store_*`,
IR_JMP/IR_BR synthetic store injection) is on the
remove-list, not the extend-list.

**Commit topology (nine commits):**

```text
C1   RED     contract open + RED-1 reproduced         (659bbd1)
C2   RED     reviewer-board P0-1/P0-2/P0-3/P1 corrections (7a991a9)
C2.1 RED     reviewer-board P0-1 (case-(b) defn) /
                  P0-2 (PHI topology) /
                  P1 (rule-5 wording) corrections      (316144c)
C2.2 RED     reviewer-board P0 (Factory v2 trailer) /
                  P1 (RED-2/3 evidence paths) corrections
                                                     (74cb97c)
C3   RED     RED-2 def/use tables + frozen case-(b) opcode list
                                                     (29e43a7)
C4   RED     RED-3 hand-translated Option-W proof under §6 PASS criteria
                                                     (bf74167)
C4.v2 RED    RED-3 v2 reviewer-board correction:
                  P0-1 (AccDigit bb11 same-site %slot load)
                  P0-2 (per-function spec-driven mechanical validation)
                  P1 (capture-neutral-ir.sh shebang)
                                                     (this commit)
C5   IMPL    descriptive: IMPL-TOOLING; harness-isolation producer fix
                                                     (96f7825)
C6   IMPL    descriptive: IMPL-COMPILER; bounded backend change (cases a + b)
C7   CLOSE   acceptance-criteria evidence + verdict
```

`C4.v2` corrects the bf74167 RED-3 evidence:

  - Rewrites `pos_b0_compare_digit.pre.ll` so that
    AccDigit's bb11 case-(b) iadd performs an actual
    same-site load from `%slot` before the imul. The v1
    pre-IR bypassed the slot using the parameter `%p16`,
    which is semantically equivalent on this particular
    path but violates the §6 invariant that "every
    ORIGINAL read of V ↔ load at same CFG site".

  - Adds a sidecar `<bn>.spec` file per fixture
    enumerating per-function expected definition and read
    sites. validate.sh parses the .spec and mechanically
    binds the §6 invariants per function: each DEF_SITES
    block has exactly one slot store; each READ_SITES
    block has exactly one slot load; no slot store in
    any non-def block; no slot load in any non-read block.
    The validator now catches the v1 AccDigit defect
    (proven by re-running against the v1 pre-IR).

  - Marks the README with explicit [M] MECHANICALLY_CHECKED
    and [I] MANUALLY_INSPECTED tags so the proof claims
    are honest.

  - Switches `c3/capture-neutral-ir.sh` shebang from `#!/bin/sh`
    to `#!/bin/bash` because the script uses bash arrays
    (`declare -a`, `${FIXTURES[@]}`).

C5 IMPL-TOOLING is independently released by the
reviewer board at C2.1 and may run in parallel with
C3 and C4. C6 IMPL-COMPILER is gated on
COMPILER_IMPL_AUTH = C5 GREEN ∧ C3 PASS ∧ C4 PASS.

#### ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 status (CLOSED at C7)

```text
LOCAL-MEM2REG01-CORRECTION02  ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
  ENTRY    = e286f59 (parent commit of contract opening)
  STATE    = CLOSED at C7 (Factory v2 grammar: ACT-Phase: CLOSE +
             ACT-Verdict: PASS on the C7 commit trailer)
             No mutable Markdown `Status:` field is updated;
             verdict identity lives in the C7 commit trailer.
  PREDECESSOR = CORRECTION01 closed at 8072b9a
                (HALT_DEFECTIVE_IMPL) with post-CLOSE
                reviewer board Option-W evidence at e286f59
                (no ACT: trailer; recorded as residue).
  MISSION  = faithful memory-backed lowering of the smallest
             mutable-local class (Option W); no frontend SSA
             reconstruction. Replace C9 predecessor-store
             synthesis with original-site store/load lowering
             + LLVM mem2reg.

  ACTUAL LINEAGE (the reviewer corrections are legitimate
  append-only descendants; the original nine-commit planned
  topology was extended; C4 v1 was SUPERSEDED by C4 v2):

    C1     RED       contract open + RED-1 reproduced         (659bbd1)
    C2     RED       reviewer-board P0-1/P0-2/P0-3/P1          (7a991a9)
    C2.1   RED       reviewer-board case-(b) / PHI / rule-5   (316144c)
    C2.2   RED       reviewer-board trailer / evidence-paths  (74cb97c)
    C3     RED       RED-2 def/use + frozen case-(b) opcode   (29e43a7)
    C4 v1  RED       RED-3 hand-translated Option-W proof     (bf74167)
                                                          === SUPERSEDED ===
    C4 v2  RED       reviewer-board AccDigit fix + spec-driven
                                                            (c69842e)
                       per-function mechanical validation
    C5     IMPL      IMPL-TOOLING; harness-isolation producer (96f7825)
    C6     IMPL      IMPL-COMPILER; bounded backend change   (a06a6f5)
                       (cases a + b)
    C6.1   IMPL-evid convergence: reclassify red_local_multi_def
                       + promote Diamond + real-compiler evidence
                                                            (a640357)
    C6.2   IMPL-evid evidence-integrity: validate.sh snapshot(24eaad9)
    C6.2'  IMPL-evid verdict channel + boundary + patch hygiene
                                                            (d90de7e)
    C6.3   IMPL-evid idem_rc bound to row verdict            (f7060a9)
    C7     CLOSE     acceptance-criteria evidence + verdict  (C7_COMMIT)

  FINAL PRODUCTION ARCHITECTURE (the cumulative C6 state at
  C6.3 is FROZEN; C7 does NOT change src/llvm-backend.c):

    Option-W representation:
      entry-block alloca
      + store at each ORIGINAL definition site
      + load at each ORIGINAL read site
      + LLVM mem2reg owns SSA / PHI construction

    Deleted C9 surface (production matches = NONE):
      llRecognizeLocalMem2Reg         (deleted)
      llMaterializeLocalSlotAlloca    (deleted)
      llRunMem2RegOnFunction          (deleted)
      llEmitMem2RegStoreAtPredEnd     (deleted)
      lc->local_mem2reg               (deleted)
      lc->mem2reg_slot                (deleted)
      lc->mem2reg_alloca              (deleted)
      lc->mem2reg_store_block_id      (deleted)
      lc->mem2reg_store_value         (deleted)
      IR_JMP / IR_BR synthetic store  (deleted)

    Frozen contracts:
      FROZEN_SUPPORTED_DEF_FORMS = IR_STORE, IR_IADD, IR_ISUB
      CASE_B_OPCODE_SET_WIDENED  = NO
      PHI_POLICY                 = LLVM-owned
      FRONTEND_SSA_RECONSTRUCTION = NO
      NEUTRAL_IR_CHANGED          = NO
      ABI_CHANGED                 = NO

  CLOSURE SUMMARY:
    ROOT_CAUSE = backend attempted to represent path-dependent
                 mutable locals through SSA-cache/predecessor-
                 store synthesis
    FIX        = faithful original-site memory lowering +
                 LLVM mem2reg
    VERDICT    = PASS (C7 commit trailer)

  C6.3 TRUTH CHANNEL = PASS
    Mandatory row predicates:
      pre_rc == 0
      post_rc == 0
      verify_rc == 0
      idem_rc == 0      <-- bound in C6.3
      stores_per_alloca != TOO_FEW
      synth_store_count == 0
    Five verdict-channel proofs PASS:
      all-good geometry -> capture rc 0
      seeded pre failure -> row FAIL
      injected full failure -> capture rc non-zero
      seeded idem_rc failure -> row FAIL with idem_rc reason
      FAIL-count exit predicate present
    known false-green path = NONE

  REQUIRESMEM2REG BOUNDARY (corrected at C6.2/C6.3;
    c6.1 interpretation of safe_fwd_single_pred is
    SUPERSEDED):
    safe_fwd_single_pred  single-def + direct-ret  + Option-W
                         RequiresMem2Reg = TRUE
    MultiDef::x           single-def + non-direct-ret + legacy SSA
                         RequiresMem2Reg = FALSE
    MultiDef::y           multi-def + Option-W memory-backed
                         RequiresMem2Reg = TRUE

  CONSERVATION GATES (re-run from C7 candidate tree, fresh):
    make clean                                 PASS
    make                                       PASS
    make llvm-all                              PASS
    llvm-spike-test                            18/0 PASS
    llvm-byte-memory01-test                    37/0 PASS
    llvm-intops01-test                         4/0 PASS
    ir-return-slot-forwarding01-test           6/0 PASS
    harness-evidence-isolation-test            PASS (HCC_INSTALL_DIR
                                               set; documented P2
                                               Makefile plumbing
                                               residue)
    factory-v2-commit-msg-check                PASS
    factory-append-only-test                   11/0 PASS
    factory-closure-status                     PASS
    gate-fast                                  PASS

  PATCH HYGIENE (F12):
    Historical C6.1 range a06a6f5..a640357   FAIL
      (7 trailing-whitespace diagnostics in
       preserved c6.1 six-fixture matrix;
       each diagnostic = 2 lines of git diff --check output,
       so the raw output is 14 lines; the diagnostic count
       is 7. F14 preserves historical fact.)
    C6.2 cumulative range a640357..d90de7e  PASS
    C6.3 range d90de7e..HEAD                PASS
    C7 commit                               git diff --check
                                            HEAD^ HEAD = PASS
                                            (C7 is docs-only)

  EVIDENCE DIRECTORY = evidence/.../c7/
    acceptance-matrix.txt        AC01..AC20 with truth classes
    closure-summary.txt          ARCHITECTURE + lineage + verdict
    residue.txt                  P2 residue carried honestly
    gate-results.txt             fresh conservation-gate output
    patch-hygiene.txt            range hygiene
    c6.3-validator-fresh.txt     fresh C6.3 validate.sh run
    c6.3-allgood-fresh.txt       fresh C6.3 capture.sh output
    c9-remove-list-audit.real.txt mechanical C9 absence proof
    gate-*.txt                   per-gate transcripts
    ROADMAP-update.txt           descriptive pointer

  RESIDUE (F11):
    P0  none (defect class eliminated by C6 architecture)
    P1  none introduced by C7 (docs-only closure commit)
    P2  llvm-spike-contract-check neg_pointer.HC stale ref
        (pre-existing; not a CORRECTION02 gate)
    P2  harness-evidence-isolation-test requires HCC_INSTALL_DIR
        (Makefile plumbing; gate PASSES when env set)
    P2  historical C6.1 trailing-whitespace matrix
        (F14 immutable; not rewritten)
    P2  e286f59 NON_ACT post-CLOSE evidence
        (F14 immutable; recorded in ACT §1.1)

  NEXT ACT = NONE for this defect class unless a new
             counterexample appears.
```
