; Per-function Option-W expectation for ProbePath.pre.ll.
; The validator mechanically binds the §6 invariants against
; the .pre.ll using this spec.
;
; Format (one stanza per function):
;   FN: <symbol>
;   TARGET: <%local>
;   DEF_SITES: <block>[:<case>], <block>[:<case>], ...
;   READ_SITES: <block>[:<kind>], <block>[:<kind>], ...
;
; where:
;   <case>   = a | b        (definition: case-a IR_STORE or case-b arith)
;   <kind>   = ret|self|rhs (read: ret=compiler return slot; self=self-ref RHS;
;                            rhs=non-self RHS)
;
; Mechanical invariants bound:
;   - For every DEF_SITES entry, exactly one `store i64 ..., i64* %slot`
;     appears in that basic block.
;   - For every READ_SITES entry, exactly one `load i64, i64* %slot`
;     appears in that basic block.
;   - No `store i64 ..., i64* %slot` appears in any basic block that
;     is NOT in DEF_SITES.
;   - No `load i64, i64* %slot` appears in any basic block that
;     is NOT in READ_SITES.
;   - The alloca appears exactly once and only in the function entry.
;
; ACT: ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02

FN: ProbePath
TARGET: %l6
DEF_SITES: bb_entry:a, bb3:b, bb5:b
READ_SITES: bb6:ret
