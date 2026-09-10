; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4 architectural probe
; --------------------------------------------------------
; Hand-written LLVM IR equivalent of
;     src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
; (specifically, the function `ReadDigit`) after the
; irForwardReturnSlot guard.
;
; The original PolyC IR (from
; evidence/llvm-ir-return-slot-forwarding01/c2/pos_b0_compare_digit-impl-dump-ir.txt
; "===== After basic optimisations ====="):
;
;     bb1: store %l2, %p1
;          alloca %t3 i64, 8
;          load* %t5 i8, %p1 (zext-promoted to i64 t6)
;          trunc %l4 i8, %t6
;          store %l8 i64, 0
;          cmp_ge %t9, %l4, 48  ; br %t9, bb3, bb4
;     bb3: cmp_le %t11, %l4, 57 ; br %t11, bb5, bb4
;     bb5: isub %l8, %l8, %l4 + 48
;          jmp bb4
;     bb4: predecessors = {bb1, bb3, bb5}
;          store %t3, %l8
;          load %t15, %t3
;          ret %t15
;
; The candidate slot is %t3 (an i64; the byte source is
; zext-promoted to i64 before the slot write, so the slot
; itself is I64). It has three reaching values on entry to
; bb4 (from bb1's initial 0, from bb3's fall-through, and
; from bb5's isub-then-jmp).

define i64 @ReadDigit(ptr %p1) {
entry:
  %slot = alloca i64
  ; bb1
  store i64 0, ptr %slot          ; initial bind (l8 = 0)
  %byte.src = load i8, ptr %p1
  %l4 = zext i8 %byte.src to i64
  %t9 = icmp sge i64 %l4, 48      ; digit >= '0' ?
  br i1 %t9, label %bb3, label %bb4

bb3:
  %t11 = icmp sle i64 %l4, 57     ; digit <= '9' ?
  br i1 %t11, label %bb5, label %bb4

bb5:
  %l8.bb5.in = load i64, ptr %slot
  %l8.bb5.next = sub i64 %l8.bb5.in, %l4
  %l8.bb5.adjusted = add i64 %l8.bb5.next, -48
  store i64 %l8.bb5.adjusted, ptr %slot
  br label %bb4

bb4:
  ; merge point: predecessors = {bb1, bb3, bb5}
  ; three distinct reaching values for %slot (0 / 0 / sub)
  br label %bb2

bb2:
  %t15 = load i64, ptr %slot
  ret i64 %t15
}
