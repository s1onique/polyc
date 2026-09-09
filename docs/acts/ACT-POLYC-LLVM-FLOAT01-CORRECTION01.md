# ACT-POLYC-LLVM-FLOAT01-CORRECTION01

**Title:** FLOAT01 closure contract correction

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** IMPLEMENTATION (correction; F64 lowering stays)

**Predecessor:** ACT-POLYC-LLVM-FLOAT01 (RED+IMPL+EVIDENCE+CLOSE PASS - corrected)

**Production semantic changes:** FORBIDDEN (F64 lowering in tree stays)

**IR / ABI / LLVM authorization:** NONE

---

## 0. Mission

Repair the FLOAT01 closure contract defects identified by the
reviewer WITHOUT modifying the working F64 lowering, and obtain
a genuinely verified CLOSE.

## 1. Why

Reviewer (`FLOAT01 closure review`, post-`c73400b`) identified:

- **P0-1 (mechanical):** ACT-range `git diff --check` failed on
  `evidence/llvm-float01/red/red-matrix-raw.txt:144` (trailing
  blank line).
- **P0-2 (F3 RED discipline):** Every RED reproducer tripped at
  the F64 parameter admission check
  (`LLVM_BACKEND_UNSUPPORTED_TYPE`), not at the dispatch seam.
  REDs 2-7 (FADD/FSUB/FMUL/FCMP/FCMP->BR) were never
  independently reproduced at their named opcode arms. What was
  reproduced is RED-A: F64 admission unsupported.
- **P0-3 (HALT overridden):** The recon identified a
  target-specific aarch64 vs x86_64 semantic divergence for NaN
  comparisons, but the RED summary self-authorised the aarch64
  semantic as "binding oracle" without an ACT contract. The
  predecessor ACT-POLYC-LLVM-MEMORY01 references FLOAT01 as the
  next ACT but no FLOAT01 ACT document was created; the recon
  became its own authorization. That violates F2/F3.
- **P1-1 (LLVM/x86 claim technically wrong):** HANDOFF says
  `fcmp olt` targeting x86 "would emit `ucomisd + setb`". LLVM
  IR `fcmp olt` is target-independent; the unordered-accepting
  lowering is a property of PolyC's NATIVE x86 backend, not LLVM.
- **P1-2 (fast-math C API explanation wrong):** The fast-math
  purity evidence claims the LLVMBuild* calls "default the
  fast-math flags argument to zero". These C API calls do NOT
  take a fast-math flag argument at all.
- **P1-3 (negative witness gap):** `neg_float_to_int.HC` claims
  the IR-level opcode is `IR_FPTOSI`, but the actual IR contains
  only `IR_SITOFP` (for the `0.0` constant). The negative matrix
  lacks an independent IR_FPTOSI witness.

## 2. Scope

### allowed

- `evidence/llvm-float01/{red,impl}/*.txt` - corrections to the
  documents that misrepresent the actual evidence.
- `evidence/llvm-float01/red/RED-SUMMARY.md` - reclassification.
- `evidence/llvm-float01/red/recon-comparison-semantics.txt` -
  clarified host-vs-target separation.
- `evidence/llvm-float01/impl/{fast-math-purity,
  comparison-predicate-map,negative-matrix}.txt` and
  `EVIDENCE-SUMMARY.md` - corrections to factual claims.
- `docs/handoffs/HANDOFF-POLYC-LLVM-FLOAT01.md` - corrections.
- `evidence/llvm-float01/red/recon-ll-semantics.txt` (NEW) -
  LLVM LangRef semantics contract.
- `src/tests/llvm-float01/neg_fptosi_witness.HC` (NEW) - real
  fixture lowering to IR_FPTOSI.
- `evidence/llvm-float01/correction01/*` - correction captures.

### forbidden

- Any change to `src/llvm-backend.c`, `src/llvm-backend-cap.c`,
  `src/ir.c`, `src/ast.c`, `src/prslib.c`, or any production file.
- Any change to the emitted IR for the 13 positive fixtures.
- Any change to native backend behaviour (aarch64, x86_64, JIT).
- Any widening of F64 scope (FDIV/FREM, F32, vectors, casts).

## 3. Mission tasks

### M1 - whitespace hygiene

Already executed (commit `48fb1f5`): trimmed trailing blank line
in `evidence/llvm-float01/red/red-matrix-raw.txt`. ACT-range
`git diff --check HEAD~5..HEAD` now PASSES.

### M2 - truthful RED reclassification

Replace the RED summary's "RED-2..RED-7 are reachable only AFTER
the IMPL phase accepts F64 parameters" with a true taxonomy:

```
RED-A  (REPRODUCED at RED, RED commit 4592d79):
       F64 parameter / return admission is rejected at
       llTypeSupported / llParamTypeSupported. 16 reproducer
       fixtures all trip this gate first. RC=1, no .ll produced.

Q-3..Q-7  (POST-ADMISSION qualification, RED+EVIDENCE phases):
       These are NOT principal REDs in the F3 sense because the
       pre-IMPL production code never reaches the dispatch arms.
       They are post-admission qualification checks: they exercise
       the F64-accepted dispatch arms after IMPL to verify the
       emitted IR matches the contract. Each is documented in
       evidence/llvm-float01/impl/positive-matrix.txt and
       comparison-predicate-map.txt.
```

### M3 - comparison-semantic HALT decision

The ACT authorises the resolution explicitly:

```
PolyC's LLVM backend MUST emit the LLVM LangRef-defined
ordered predicates (oeq / olt / ole / ogt / oge) and une for !=,
because those are the only LLVM IR predicates whose semantics
are target-independent and aligned with the canonical IEEE-754
unordered-compared-to-NaN convention that PolyC documents in
docs/CHARTER.md.

The x86_64 native backend's IR_FCMP dispatch
(src/x86_64.c:670-679, src/x86_64-jit.c:425-433) emits
sete/setne/setb/setbe/seta/setae after `ucomisd`. With UCOMISD
setting ZF=PF=CF=1 on NaN/unordered operands, FOUR of six
predicates produce the WRONG IEEE-754 / LangRef result:
  EQ (sete):    NaN -> 1   WRONG; expected 0
  NE (setne):   NaN -> 0   WRONG; expected 1
  LT (setb):    NaN -> 1   WRONG; expected 0
  LE (setbe):   NaN -> 1   WRONG; expected 0
  GT (seta):    NaN -> 0   CORRECT (matches ogt NaN->false)
  GE (setae):   NaN -> 0   CORRECT (matches oge NaN->false)
The defect matrix is mechanically derived from `ucomisd` flag
behaviour in evidence/llvm-float01/red/recon-ll-semantics.txt.
Defect set for the next ACT: EQ/NE/LT/LE. Conservation
controls: GT/GE must NOT change. This is a PolyC native-backend
defect independent of the LLVM backend. It is recorded as P0
residue under ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 (NOT
scoped to this ACT and NOT silently fixed here).

Per F15, this ACT does NOT modify the x86_64 native backend.
```

The recon-comparison-semantics.txt is updated to:
1. State the LangRef-defined semantics (independent of any native
   backend).
2. State the host (aarch64) JIT/AOT oracle result, framed as a
   witness rather than an authority.
3. Record the x86_64 native divergence as observed residue.
4. State that the LLVM backend binds to the LangRef semantics,
   which are aligned with the aarch64 host oracle AND the IEEE-754
   convention.

### M4 - correct LLVM/x86 statement

The HANDOFF says:

> x86_64-native F64 float arithmetic. The x86_64 native backend
> uses `ucomisd` + `setb`, which on NaN returns 1 (unordered).

Rewrite to:

> x86_64-native F64 float arithmetic. The PolyC x86_64 native
> backend emits `ucomisd` + `setb` / `setbe` / `setne`, which on
> NaN returns 1 (unordered), differing from the IEEE-754
> ordered-comparison convention used by PolyC's LLVM backend.
> LLVM IR `fcmp olt` semantics are target-independent and always
> produce false on NaN (per the LLVM LangRef), so the LLVM
> backend emits `fcmp olt double` regardless of the host target
> triple. The x86_64 native backend divergence is a PolyC
> native-backend defect.

### M5 - correct fast-math C-API explanation

The fast-math-purity.txt currently says:

> The structural mechanism is built into the C API: LLVMBuildFAdd
> / LLVMBuildFSub / LLVMBuildFMul / LLVMBuildFCmp with only
> two/three arguments default the fast-math flags argument to
> zero.

Rewrite to:

> The fast-math purity is enforced by source discipline: the
> IMPL phase calls `LLVMBuildFAdd` / `LLVMBuildFSub` /
> `LLVMBuildFMul` / `LLVMBuildFCmp` (each is a 4-arg function:
> builder, lhs, rhs, name; or builder, predicate, lhs, rhs,
> name for FCmp) and never calls `LLVMSetFastMathFlags` or any
> equivalent flag-setting API. Fast-math flags are not an
> argument of these builder calls; they are applied separately
> to the produced LLVMValueRef. None are applied here, so every
> emitted `.fp instruction` carries zero fast-math flags.

The structural gate (`positive-matrix.txt` grep) is unchanged.

### M6 - independent IR_FPTOSI negative witness

Create `src/tests/llvm-float01/neg_fptosi_witness.HC` that lowers
to IR_FPTOSI via the AST_ASSIGN path:

```c
I64 ToInt(F64 x) {
    I64 j;
    j = x;       /* AST_ASSIGN -> irLowerCast -> IR_FPTOSI */
    return j;
}
```

Capture the LLVM backend rejection of this fixture (it must say
`opcode fptosi`). Record:
- actual IR opcode that tripped,
- expected opcode in docstring,
- the real chain.

### M7 - re-run gates with new evidence

After M1-M6 land:

```
git diff --check HEAD~5..HEAD         PASS  (M1 evidence)
llvm-float01-test.sh                 FLOAT01_PASS=28 FAIL=0
                                       + 1 new witness (neg_fptosi)
llvm-spike-test.sh                   PASS=18 FAIL=0
llvm-memory01-test.sh                PASS=6 FAIL=0
llvm-memory01-nc5-probe.sh           PASS
llvm-cap-table-verifier.py           PASS
factory-v2-test.sh                   PASS=35 FAIL=0
gate-fast.sh                         VERDICT=PASS
```

## 4. Closure

```
VERDICT: PASS
IDENTITY: (final CLOSE commit SHA, recorded by trailer)
RED: 48fb1f5 (M1) + correction01/RED (M2, M3, M6)
IMPL: correction01/IMPL (M4, M5 documentation corrections)
EVIDENCE: correction01/EVIDENCE (M7 captures)
GATES: all PASS
SCOPE: per section 2 (no production code touched)
RESIDUE: ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 (new recommendation)
NEXT ACT: ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 (or FLOAT02)
```
