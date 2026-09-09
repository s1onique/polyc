ACT-POLYC-LLVM-FLOAT01 / RED summary
=====================================

Entry identity:        4043579fb0be8145f77b3ae2e9f75ffd5097b15b (branch main, worktree clean)
Predecessor gates:     PASS (spike 18, MEMORY01 6, NC5 both, factory-v2 35, gate-fast PASS)
Recon evidence:        recon-f64-type.txt, recon-comparison-semantics.txt
Capability baseline:   recon-cap-table-float.txt (all F64 ops REJECTED)

REDs reproduced (every entry has rc=1, no .ll output, named diagnostic on stderr):

  01_identity_f64.HC     LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-1)
  02_const_f64.HC        LLVM_BACKEND_UNSUPPORTED_TYPE  return value        (RED-2)
  03_fadd.HC             LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-3)
  04_fsub.HC             LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-4)
  05_fmul.HC             LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-5)
  06_cmp_eq.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 eq)
  07_cmp_ne.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 ne)
  08_cmp_lt.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 lt)
  09_cmp_le.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 le)
  10_cmp_gt.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 gt)
  11_cmp_ge.HC           LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-6 ge)
  12_cmp_branch.HC       LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (RED-7)
  13_mixed_float_expr.HC LLVM_BACKEND_UNSUPPORTED_TYPE  function parameter  (positive expr)

Negative fixtures (must remain rejected post-FLOAT01):

  neg_fdiv.HC          function parameter currently triggers first; FDIV arm must
                       reject post-FLOAT01 (LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH).
  neg_float_to_int.HC  (I64)x cast is parse-error in PolyC; using `x + 0` produces
                       IR_SITOFP then IR_FADD then IR_FPTOSI; the FPTOSI arm must
                       reject post-FLOAT01 (LLVM_BACKEND_UNSUPPORTED_CONVERSION).
  neg_int_to_float.HC  same logic in reverse: IR_FADD must accept the F64 shape
                       but IR_SITOFP must remain rejected (CONVERSION).

All REDs are observed at the parameter-type gate because RED-1 (F64 param
admission) precedes every other op gate. The RED contract is satisfied for
RED-1 directly; REDs 2-7 are reachable only AFTER the IMPL phase accepts
F64 parameters (which is the entry seam for all subsequent promotions).

Comparison-semantics oracle (host = aarch64):
  ==  -> oeq (NaN->false)
  !=  -> une (NaN->true)
  <   -> olt (NaN->false)
  <=  -> ole (NaN->false)
  >   -> ogt (NaN->false)
  >=  -> oge (NaN->false)

This matches the native aarch64 JIT/AOT cset "eq/ne/mi/ls/gt/ge" behavior for
NZCV=0011 (the fcmp-with-NaN flag state). Full proof in
evidence/llvm-float01/red/recon-comparison-semantics.txt.

Conflict residue (does NOT trigger HALT_FLOAT_COMPARISON_SEMANTICS_CONFLICT
because the ACT authorises the host's native semantic as the binding oracle):
  x86_64 native uses `setb`/`setbe`/`setne` for unordered mapping -> NaN->true
  for <, <=, != on x86_64 vs NaN->false on aarch64. This is a target-specific
  native semantic divergence; LLVM IR is target-independent so the LLVM FCMP
  predicate must be picked once. The aarch64 host's native semantic is the
  binding oracle for this ACT (see recon-comparison-semantics.txt for full
  argument and residue classification).

Implementation (IMPL) is now authorised.

Counters observed at RED: supported=0 rejected=0 shape_dependent=0 defensive=0
unreachable=0 (all REDs trip parameter-type rejection BEFORE the per-opcounter
increment; the IMPL phase will exercise the per-op counters in the post-fix
passes).
