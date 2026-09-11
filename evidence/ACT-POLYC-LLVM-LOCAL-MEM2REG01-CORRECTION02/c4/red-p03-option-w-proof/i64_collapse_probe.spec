; Per-function Option-W expectation for i64_collapse_probe.pre.ll.
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

FN: Probe
TARGET: %l2
DEF_SITES: bb_entry:a, bb5:b
READ_SITES: bb5:self, bb4:ret
