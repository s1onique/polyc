; Per-function Option-W expectation for single_cond_probe.pre.ll.
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

FN: Probe
TARGET: %l2
DEF_SITES: bb_entry:a, bb3:b
READ_SITES: bb3:self, bb4:ret
