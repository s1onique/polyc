; Per-function Option-W expectation for pos_b0_compare_digit.pre.ll.
; Two functions: ReadDigit (%l8) and AccDigit (%l17).
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

FN: ReadDigit
TARGET: %l8
DEF_SITES: bb_entry:a, bb5:b
READ_SITES: bb4:ret

FN: AccDigit
TARGET: %l17
DEF_SITES: bb_entry:a, bb11:b
; bb11 read is self-referential: the case-(b) iadd has RHS that
; reads %l17 (via the imul). The lowered IR must perform an
; actual same-site load from the slot, NOT bypass the slot
; using the parameter. This invariant is the mechanical
; regression guard for the AccDigit defect fixed in C4 v2.
READ_SITES: bb11:self, bb10:ret
