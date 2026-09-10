; ACT-POLYC-LLVM-LOCAL-MEM2REG01 -- Q3 placement NEGATIVE witness
; ------------------------------------------------------------
; Same CFG as single_cond_probe, but the alloca is placed
; inside bb3, a conditional predecessor of bb2 (the function
; has bb1 as its entry block; bb3 is reached only when the
; icmp predicate is true). The alloca's user (%t10) lives in
; bb2, which is also reachable from bb4 (a non-bb3
; predecessor), so the alloca does NOT dominate its only use.
;
; This is the actual placement-negative witness. It exercises
; what happens when llvm-backend.c forgets to save/restore
; the insertion point to the entry block before emitting
; LLVMBuildAlloca.
;
; EXPECTED: opt -passes=mem2reg rejects with
; "Instruction does not dominate all uses!" -- exactly what
; we observe (see .m2r.stderr).
;
; The entry-block positive control is
; single_cond_probe_ENTRY_BLOCK_NAMED_BB1.ll (renamed from
; single_cond_probe_NOT_IN_ENTRY.ll in the C2 evidence
; commit, per reviewer correction).

define i64 @Probe(i64 %p1, ptr %p3) {
bb1:
  %l6 = load i64, ptr %p3
  %t8 = icmp sge i64 %l6, 10
  br i1 %t8, label %bb3, label %bb4

bb3:
  %slot = alloca i64
  store i64 %p1, ptr %slot
  %slot.bb3.next = add i64 %p1, %l6
  store i64 %slot.bb3.next, ptr %slot
  br label %bb4

bb4:
  br label %bb2

bb2:
  %t10 = load i64, ptr %slot
  ret i64 %t10
}
