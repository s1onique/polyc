; Hand-translated pre-mem2reg LLVM IR for single_cond_probe.
; Source: src/tests/llvm-byte-memory01/single_cond_probe.HC
; Target mutable local: %l2 (i64)
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
; C4 RED-3: hand-translated Option-W pre-IR.
;
; Per Option-W contract:
;   alloca once in entry block        -> %slot in bb_entry
;   store at every ORIGINAL def site  -> bb1:store, bb3:iadd
;   load at every ORIGINAL read site  -> bb3:iadd RHS, bb4:ret-store
;   NO predecessor-injected stores
;   NO terminator-motivated stores

define i64 @Probe(i64 %p1, ptr %p3) {
bb_entry:
  %slot = alloca i64
  %ret_slot = alloca i64
  ; bb1: store %l2, %p1  (case-a original definition)
  store i64 %p1, i64* %slot
  %x = load i64, ptr %p3
  %cond_ge = icmp sge i64 %x, 10
  br i1 %cond_ge, label %bb3, label %bb4

bb3:
  ; ORIGINAL definition of %l2 (case-b iadd):
  ;   rhs = lower(iadd %l2, %l2, %l6)
  ;   -> load %l2 from slot, then add with %x (= %l6)
  %l2_rhs = load i64, i64* %slot
  %add_rhs = add i64 %l2_rhs, %x
  store i64 %add_rhs, i64* %slot
  br label %bb4

bb4:
  ; ORIGINAL read of %l2 (compiler-generated return handling):
  %tmp = load i64, i64* %slot
  store i64 %tmp, i64* %ret_slot
  br label %bb_exit

bb_exit:
  %ret = load i64, i64* %ret_slot
  ret i64 %ret
}
