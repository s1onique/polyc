; Hand-translated pre-mem2reg LLVM IR for ProbePath.
; Source: src/tests/llvm-byte-memory01/nc_p01_predecessor_paths.HC
; Target mutable local: %l6 (i64)
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
; C4 RED-3: hand-translated Option-W pre-IR.
;
; Per Option-W contract:
;   alloca once in entry block        -> %slot in bb_entry
;   store at every ORIGINAL def site  -> bb1:10, bb3:iadd, bb5:isub
;   load at every ORIGINAL read site  -> bb6: store %t5, %l6
;   NO predecessor-injected stores
;   NO terminator-motivated stores
;
; Note: bb4 itself does not define %l6, so there is no
; store of %l6 at the bb4 terminator. The bb3 jmp and
; bb5 jmp do not carry stores.
;
; The ret uses the compiler-generated return slot %ret_slot
; which is loaded from at the exit block (bb_exit).

define i64 @ProbePath(i64 %p1, i64 %p3) {
bb_entry:
  %slot = alloca i64
  %ret_slot = alloca i64
  ; bb1: store %l6, 10  (case-a original definition in entry)
  ;   rhs = lower(store %l6, 10) -> 10
  ;   store rhs -> %slot
  store i64 10, i64* %slot
  %cond = icmp sgt i64 %p1, 0
  br i1 %cond, label %bb3, label %bb4

bb3:
  ; ORIGINAL definition of %l6 (case-b iadd):
  ;   rhs = lower(iadd %l6, %l4, 1) -> add %p3, 1
  ;   store rhs -> %slot
  %add_rhs = add i64 %p3, 1
  store i64 %add_rhs, i64* %slot
  br label %bb4

bb4:
  ; bb4 itself does NOT define %l6.
  ; No synthetic store injection.
  %cond2 = icmp slt i64 %p1, 0
  br i1 %cond2, label %bb5, label %bb6

bb5:
  ; ORIGINAL definition of %l6 (case-b isub):
  ;   rhs = lower(isub %l6, 0, %l4) -> sub 0, %p3
  ;   store rhs -> %slot
  %sub_rhs = sub i64 0, %p3
  store i64 %sub_rhs, i64* %slot
  br label %bb6

bb6:
  ; ORIGINAL read of %l6 (compiler-generated return handling):
  ;   load %l6 -> %tmp; store %ret_slot, %tmp
  %tmp = load i64, i64* %slot
  store i64 %tmp, i64* %ret_slot
  br label %bb_exit

bb_exit:
  %ret = load i64, i64* %ret_slot
  ret i64 %ret
}
