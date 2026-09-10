; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q4 architectural probe
; --------------------------------------------------------
; Hand-written LLVM IR equivalent of
;     src/tests/llvm-byte-memory01/i64_collapse_probe.HC
; after the irForwardReturnSlot guard.
;
; The original PolyC IR (from --dump-ir at HEAD):
;
;     bb1: store %l2 i64, %p1
;          alloca %t5 i64, 8
;          load %l6 i64, %p3
;          cmp_ge %t8, %l6, 10
;          br %t8, bb3, bb4
;     bb3: cmp_le %t9, %l6, 99
;          br %t9, bb5, bb6
;     bb5: iadd %l2, %l2, %l6
;          jmp bb6
;     bb6: jmp bb4
;     bb4: predecessors = {1, 6}   ; post-opt: {1, 3, 5}
;          store %t5, %l2
;          jmp bb2
;     bb2: load %t11, %t5
;          ret %t11
;
; After PolyC's basic optimisations, bb6 folds into bb4 via
; the %t9 false arm being constant-folded in bb3; the merge
; at bb4 ends up with three reaching values from bb1, bb3,
; bb5. The post-optimisation shape (from
; evidence/llvm-ir-return-slot-forwarding01/c2/i64_collapse_probe-impl-dump-ir.txt
; "===== After basic optimisations =====") is captured here.

define i64 @Probe(i64 %p1, ptr %p3) {
entry:
  %slot = alloca i64
  ; bb1
  store i64 %p1, ptr %slot
  %l6 = load i64, ptr %p3
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:
  %t9 = icmp sle i64 %l6, 99
  br i1 %t9, label %bb5, label %bb4

bb5:
  %slot.bb5.in = load i64, ptr %slot
  %slot.bb5.next = add i64 %slot.bb5.in, %l6
  store i64 %slot.bb5.next, ptr %slot
  br label %bb4

bb4:
  ; merge point: predecessors = {bb1, bb3, bb5}
  ; three distinct reaching values for %slot
  br label %bb2

bb2:
  %t11 = load i64, ptr %slot
  ret i64 %t11
}
