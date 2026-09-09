ACT-POLYC-LLVM-FLOAT01 / RED summary (CORRECTED per CORRECTION01 M2)
=====================================================================

Entry identity:        4043579fb0be8145f77b3ae2e9f75ffd5097b15b (branch main)
Predecessor gates:     PASS (spike 18, MEMORY01 6, NC5 both, factory-v2 35, gate-fast PASS)
Recon evidence:        recon-f64-type.txt, recon-comparison-semantics.txt,
                        recon-ll-semantics.txt (NEW, M3)
Capability baseline:   recon-cap-table-float.txt (all F64 ops REJECTED)

== RED classification (truthful) ==

F3 RED discipline requires the principal RED to reproduce AT the
production seam that the IMPL will fix. The production seam for
the F64 slice is the F64-type admission check
(`llTypeSupported` / `llParamTypeSupported`), because accepting
F64 in the type table is the entry point for all subsequent
FADD/FSUB/FMUL/FCMP/BR dispatch arms. Therefore:

  RED-A (REPRODUCED at RED, RED commit 4592d79) -- principal RED.
        F64 parameter / return admission is rejected. 16 reproducer
        fixtures all trip this gate first. RC=1, no .ll produced,
        named diagnostic on stderr.

        Reproducers (all trip RED-A):
          01_identity_f64.HC      LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          02_const_f64.HC         LLVM_BACKEND_UNSUPPORTED_TYPE  return value
          03_fadd.HC              LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          04_fsub.HC              LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          05_fmul.HC              LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          06_cmp_eq.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          07_cmp_ne.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          08_cmp_lt.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          09_cmp_le.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          10_cmp_gt.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          11_cmp_ge.HC            LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          12_cmp_branch.HC        LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          13_mixed_float_expr.HC  LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          neg_fdiv.HC             LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          neg_float_to_int.HC     LLVM_BACKEND_UNSUPPORTED_TYPE  parameter
          neg_int_to_float.HC     LLVM_BACKEND_UNSUPPORTED_TYPE  return value

  Q-3..Q-7 (POST-ADMISSION qualification; RED+EVIDENCE phases).
        These are NOT independent principal REDs in the F3 sense
        because the pre-IMPL production code never reaches the
        dispatch arms. They are post-admission qualification
        checks: after IMPL accepts F64, the fixtures exercise
        the dispatch arms to verify the emitted IR matches the
        contract.

          Q-3  IR_FADD dispatch arm emits fadd double, SUPPORTED
          Q-4  IR_FSUB dispatch arm emits fsub double, SUPPORTED
          Q-5  IR_FMUL dispatch arm emits fmul double, SUPPORTED
          Q-6  IR_FCMP dispatch arm emits fcmp <pred> double
                  for all six predicates, SUPPORTED
          Q-7  IR_FCMP -> IR_BR chain emits fcmp + br i1, SUPPORTED

        Captured in evidence/llvm-float01/impl/positive-matrix.txt,
        comparison-predicate-map.txt, llvm-as.txt, opt-verify.txt.

== Negative fixtures (must remain rejected post-FLOAT01) ==

  neg_fdiv.HC           IR_FDIV dispatch arm rejects post-FLOAT01
                         with LLVM_BACKEND_UNSUPPORTED_FLOAT_ARITH.
  neg_float_to_int.HC   IR_SITOFP for the int 0 -> F64 0.0 constant
                         rejects with LLVM_BACKEND_UNSUPPORTED_CONVERSION
                         (not IR_FPTOSI as the docstring originally
                         claimed; see M6 below).
  neg_int_to_float.HC   IR_SITOFP for the int x -> F64 rejects with
                         LLVM_BACKEND_UNSUPPORTED_CONVERSION.
  neg_fptosi_witness.HC AST_ASSIGN lowering (src/ir.c:944) emits
                         IR_FPTOSI directly; rejects with
                         LLVM_BACKEND_UNSUPPORTED_CONVERSION
                         (diagnostic says `opcode fptosi`).
                         Independent IR_FPTOSI witness added in
                         CORRECTION01 M6 to fill the gap left by
                         the neg_float_to_int.HC docstring inaccuracy.

== Comparison-semantics resolution (M3) ==

The original RED summary self-authorised "the host's native
semantic as the binding oracle" without an ACT contract. The
correct binding for the LLVM backend is:

  1. The LLVM Language Reference Manual defines the semantics
     of `fcmp oeq/olt/ole/ogt/oge/une` to be target-independent.
     These are the predicates whose IEEE-754 unordered semantics
     (false-on-NaN for ordered; true-on-NaN for une) match PolyC's
     docs/CHARTER.md commitment.

  2. The host (aarch64) JIT/AOT oracle confirms this: NZCV=0011
     (binary: N=0 Z=0 C=1 V=1) from `fcmp NaN, x` causes
     `cset eq/mi/ls/gt/ge` to return 0 and `cset ne` to return 1.
     This is consistent with the LLVM IR ordered-predicate
     semantics.

  3. The PolyC x86_64 NATIVE backend's IR_FCMP dispatch
     (src/x86_64.c:670-679, src/x86_64-jit.c:425-433) emits
     sete/setne/setb/setbe/seta/setae after `ucomisd`. With
     UCOMISD setting ZF=PF=CF=1 on NaN/unordered operands, FOUR
     of six predicates produce the WRONG IEEE-754 / LangRef
     result (==, <, <= return 1; != returns 0). The remaining
     two (>, >=) coincidentally return 0, which matches ogt/oge.
     The defect set for the next ACT is EQ/NE/LT/LE; GT/GE are
     conservation controls. The x86_64 native divergence is
     recorded as P0 residue under
     ACT-POLYC-NATIVE-X86-FLOAT-CMP-PARITY01 and is NOT scoped
     to or fixed by this ACT.

  4. The LLVM backend binds to the LangRef semantics (which
     happen to coincide with the aarch64 host oracle). The
     per-ACT binding is:

         ==  -> oeq (NaN -> false)
         !=  -> une (NaN -> true)
         <   -> olt (NaN -> false)
         <=  -> ole (NaN -> false)
         >   -> ogt (NaN -> false)
         >=  -> oge (NaN -> false)

     This binding is recorded in
     evidence/llvm-float01/red/recon-ll-semantics.txt (NEW, M3).

The HALT_FLOAT_COMPARISON_SEMANTICS_CONFLICT triggered by the
aarch64/x86_64 divergence is RESOLVED at the backend-policy
level: the LLVM backend binds to the LangRef, and the x86_64
native divergence is recorded as a separate native-backend
defect (P2 residue).

== Counters observed at RED ==

RED-A:  supported=0 rejected=0 shape_dependent=0 defensive=0
        unreachable=0 (REJECTION of the admission gate is
        emitted before the per-op counter is incremented).

Q-3..Q-7: per-op counters exercised in IMPL/EVIDENCE phases
          (counter-matrix.txt).

== Implementation (IMPL) authorisation ==

Per the corrected RED classification, IMPL is authorised to
add F64-type admission (RED-A fix) AND to add the Q-3..Q-7
dispatch arms. Both are observable via the same RED-A fix
chain; the dispatch arms are exercised by post-admission
qualification in IMPL/EVIDENCE.
