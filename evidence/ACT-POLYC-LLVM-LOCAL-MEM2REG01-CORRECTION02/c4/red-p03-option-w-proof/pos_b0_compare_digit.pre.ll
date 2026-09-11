; Hand-translated pre-mem2reg LLVM IR for pos_b0_compare_digit.
; Source: src/tests/llvm-byte-memory01/pos_b0_compare_digit.HC
; Target mutable locals: ReadDigit::%l8, AccDigit::%l17
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02
; C4 RED-3: hand-translated Option-W pre-IR.
;
; Two functions, each Option-W eligible under §2.
; The B0 byte-load / zext / trunc fragments are not part
; of the Option-W target. The option-W target is the I64
; local whose definition sites are case-(a) or case-(b)
; in the frozen set.

; ----------------------------------------------------------------------------
; ReadDigit(U8 *p) -> I64
; Target: %l8 (i64)
; Original definitions of %l8:
;   bb1: store %l8, 0      (case-a)
;   bb5: isub %l8, %t13, 48 (case-b)
; Original reads of %l8:
;   bb4: store %t3, %l8    (compiler-generated return handling)
; ----------------------------------------------------------------------------

define i64 @ReadDigit(ptr %p) {
bb_entry:
  %slot = alloca i64
  %ret_slot = alloca i64
  ; bb1: store %l8, 0  (case-a original definition)
  store i64 0, i64* %slot
  ; byte-load fragment (not Option-W target; present for shape):
  %c = load i8, ptr %p
  %c_ext = zext i8 %c to i64
  %cond_ge = icmp sge i64 %c_ext, 48
  br i1 %cond_ge, label %bb3, label %bb4

bb3:
  %cond_le = icmp sle i64 %c_ext, 57
  br i1 %cond_le, label %bb5, label %bb4

bb5:
  ; ORIGINAL definition of %l8 (case-b isub):
  ;   rhs = lower(isub %l8, %t13, 48) -> sub %c_ext, 48
  ;   store rhs -> %slot
  %sub_rhs = sub i64 %c_ext, 48
  store i64 %sub_rhs, i64* %slot
  br label %bb4

bb4:
  ; ORIGINAL read of %l8 (compiler-generated return handling):
  %tmp = load i64, i64* %slot
  store i64 %tmp, i64* %ret_slot
  br label %bb_exit

bb_exit:
  %ret = load i64, i64* %ret_slot
  ret i64 %ret
}

; ----------------------------------------------------------------------------
; AccDigit(I64 acc, U8 *p) -> I64
; Target: %l17 (i64)
; Original definitions of %l17:
;   bb7: store %l17, %p16  (case-a)
;   bb11: iadd %l17, %t32, %l29  (case-b; self-referential RHS reads %l17)
; Original reads of %l17:
;   bb11: imul %t32, %l17, 10    (case-b RHS source -- self-referential read)
;   bb10: store %t20, %l17       (compiler-generated return handling)
; ----------------------------------------------------------------------------

define i64 @AccDigit(i64 %p16, ptr %p18) {
bb_entry:
  %slot = alloca i64
  %ret_slot = alloca i64
  ; bb7: store %l17, %p16  (case-a original definition)
  store i64 %p16, i64* %slot
  ; byte-load fragment (not Option-W target; present for shape):
  %c = load i8, ptr %p18
  %c_ext = zext i8 %c to i64
  %cond_ge = icmp sge i64 %c_ext, 48
  br i1 %cond_ge, label %bb9, label %bb10

bb9:
  %cond_le = icmp sle i64 %c_ext, 57
  br i1 %cond_le, label %bb11, label %bb10

bb11:
  ; ORIGINAL definition of %l17 (case-b iadd):
  ;   Neutral-IR shape:  imul %t32, %l17, 10
  ;                     iadd %l17, %t32, %l29
  ;   The case-(b) iadd dst=%l17 has an RHS that reads %l17
  ;   (via the imul). Per the §6 invariant:
  ;     every ORIGINAL read of V <-> load at same CFG site
  ;   The bb11 read of %l17 must be backed by an actual
  ;   same-site load from the slot. The earlier translation
  ;   bypassed the slot using the parameter %p16, which is
  ;   semantically equivalent for this particular path only
  ;   because no other definition of %l17 dominates bb11.
  ;   That equivalence is incidental, not structural, and
  ;   the lowered IR must not rely on it. Faithful lowering:
  ;     - lower imul:  %t32 = mul <loaded %l17>, 10
  ;     - lower iadd:  store %t32 + %l29 -> %slot
  ;   where %l29 lower = (c_ext - 48).
  %l17_rhs = load i64, i64* %slot
  %mul_rhs = mul i64 %l17_rhs, 10
  %sub_rhs = sub i64 %c_ext, 48
  %add_rhs = add i64 %mul_rhs, %sub_rhs
  store i64 %add_rhs, i64* %slot
  br label %bb10

bb10:
  ; ORIGINAL read of %l17 (compiler-generated return handling):
  %tmp = load i64, i64* %slot
  store i64 %tmp, i64* %ret_slot
  br label %bb_exit

bb_exit:
  %ret = load i64, i64* %ret_slot
  ret i64 %ret
}
