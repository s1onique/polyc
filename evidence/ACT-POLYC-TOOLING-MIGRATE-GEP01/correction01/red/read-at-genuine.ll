; Genuine-shape positive control for ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01
; C1.2 RED-AMEND selftest.
;
; This file MUST be accepted by the restored predicate for
; rows 04 / 07. It exercises the same dynamic-index GEP shape
; that real hcc emits for read-at: both operands are numbered
; SSA values.
;
; Purpose: prevents a tautological selftest that only proves
; rejection of the malformed fixtures. If a future regression
; broke the predicate so that it rejected ALL IR (always
; FALSE), the selftest would still pass on the negative
; cases alone. This positive control catches that.
;
; Row 08 (%gep_i8 SSA-value binding) is intentionally NOT
; satisfied by this fixture; this is a row-04/07 control only.

; ModuleID = 'genuine_dynamic_gep'
source_filename = "genuine_dynamic_gep"

define i64 @ReadAt(ptr %0, i64 %1) {
bb1:
  %tmp_x = getelementptr i8, ptr %0, i64 %1
  %ld_deref = load i8, ptr %tmp_x, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  ret i64 %zext_i8_i64
}
