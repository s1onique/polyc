; Synthetic malformed read-at IR for ACT-POLYC-TOOLING-MIGRATE-GEP01-CORRECTION01 RED.
; Defects vs legacy contract:
;   row 04/07: dynamic-index GEP shape replaced by constant-index.
;   row 08:    SSA value renamed; load no longer uses the named GEP result.

; ModuleID = 'malformed_red'
source_filename = "malformed_red"

define i64 @ReadAt(ptr %0, i64 %1) {
bb1:
  %tmp_x = getelementptr i8, ptr %0, i64 2
  %ld_deref = load i8, ptr %tmp_x, align 1
  %zext_i8_i64 = zext i8 %ld_deref to i64
  ret i64 %zext_i8_i64
}
