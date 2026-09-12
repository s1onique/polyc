; Synthetic malformed read-at IR for ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01 RED.
; Second C1.2 RED-AMEND adversary for rows 04 / 07.
;
; Defect vs legacy contract:
;   row 04/07: base operand is symbolic ("%base") instead of a
;   numbered SSA value ("%[0-9]+"). The index operand IS
;   numbered ("%1"). This MUST be rejected by the restored
;   predicate because the legacy regex requires BOTH operands
;   to be `%[0-9]+`.
;
; A helper implementing ONLY "prefix + digits after prefix"
; (i.e. checking just the base operand) would falsely accept
; this fixture. The C1.2 contract for rows 04 / 07 requires
; BOTH operands to be numbered on the same line.

; ModuleID = 'malformed_symbolic_base'
source_filename = "malformed_symbolic_base"

define i64 @ReadAt(ptr %base, i64 %1) {
bb1:
  %tmp_x = getelementptr i8, ptr %base, i64 %1
  %ld_deref = load i8, ptr %tmp_x, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  ret i64 %zext_i8_i64
}
