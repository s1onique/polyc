; Hand-translated pre-mem2reg LLVM IR for Diamond.
; Source: c3/fixture-diamond/Diamond.HC
; Target mutable local: %l6 (i64)
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
; C4 RED-3: hand-translated Option-W pre-IR.
;
; Per Option-W contract:
;   alloca once in entry block        -> %slot in bb_entry
;   store at every ORIGINAL def site  -> bb3:iadd, bb4:isub
;   load at every ORIGINAL read site  -> bb5: store %t5, %l6
;   NO predecessor-injected stores
;   NO terminator-motivated stores
;
; Note: bb1 does not define %l6, so the bb1 br does NOT
; carry a store. The bb3 jmp and bb4 jmp do not carry stores.

define i64 @Diamond(i64 %p1, i64 %p3) {
bb_entry:
  %slot = alloca i64
  %ret_slot = alloca i64
  %flag_ne = icmp ne i64 %p1, 0
  br i1 %flag_ne, label %bb3, label %bb4

bb3:
  ; ORIGINAL definition of %l6 (case-b iadd):
  ;   rhs = lower(iadd %l6, %l4, 1) -> add %p3, 1
  ;   store rhs -> %slot
  %add_rhs = add i64 %p3, 1
  store i64 %add_rhs, i64* %slot
  br label %bb5

bb4:
  ; ORIGINAL definition of %l6 (case-b isub):
  ;   rhs = lower(isub %l6, %l4, 1) -> sub %p3, 1
  ;   store rhs -> %slot
  %sub_rhs = sub i64 %p3, 1
  store i64 %sub_rhs, i64* %slot
  br label %bb5

bb5:
  ; ORIGINAL read of %l6 (compiler-generated return handling):
  ;   load %l6 -> %tmp; store %ret_slot, %tmp
  %tmp = load i64, i64* %slot
  store i64 %tmp, i64* %ret_slot
  br label %bb_exit

bb_exit:
  %ret = load i64, i64* %ret_slot
  ret i64 %ret
}
