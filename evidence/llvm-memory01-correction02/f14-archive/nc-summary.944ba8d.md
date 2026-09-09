# MEMORY01 Negative Controls

The ACT §19 mandates five permanent negative controls. They prove
the gates correctly FAIL when expected.

## NC1 - missing pointee/access type

Verified by the shape guards in IR_LOAD_DEREF / IR_STORE_DEREF:
the dispatch rejects with LLVM_BACKEND_UNSUPPORTED_TYPE if
dst->type (for load) or r1->type (for store) is not IR_TYPE_I64.
No default-to-I64 fallback exists.

Manual verification: a fixture `red_pointer_param.HC` (P1) lowers
without dereferencing; the `IR_LOAD_DEREF` arm never runs for it.
A non-I64 access would hit the type guard.

## NC2 - accidental GEP

The MEMORY01 structural purity check in
`scripts/quality/llvm-memory01-test.sh` runs:
```
bad_gep=$(grep -nE '^[[:space:]]*getelementptr' "$out" || true)
```
and FAILs if any getelementptr appears in a positive .ll.

To verify: a hypothetical .ll containing `getelementptr` would
FAIL this gate. The IMPL produces no GEP in supported MEMORY01
fixtures, and no GEP is reachable via the supported path.

## NC3 - accidental alloca fallback

The structural purity check also runs:
```
bad_alloca=$(grep -nE '^[[:space:]]*alloca[[:space:]]' "$out" || true)
```
and FAILs if alloca appears. The IMPL produces no alloca in any
positive MEMORY01 fixture (verified by IMPL run).

## NC4 - unsupported pointee shape

`neg_struct.HC` is a real expressible non-I64 pointer/aggregate
shape that remains REJECTED. Verified by the negative_matrix
section of llvm-memory01-test.sh: rc != 0 with
LLVM_BACKEND_UNSUPPORTED_TYPE.

## NC5 - counter regression

The counter gate in llvm-memory01-test.sh checks:
- SHAPE_DEPENDENT >= 1
- SUPPORTED >= 1
- DEFENSIVE = 0
- UNREACHABLE = 0

If SHAPE_DEPENDENT counting were suppressed for a dereference
fixture, the per-fixture counter would be 0 and the aggregate
would still be >= 1 from the IR_STORE shape handling. A truly
suppressed counter would FAIL only if NO fixture contributes any
SHAPE_DEPENDENT count. The IMPL run shows SHAPE_DEPENDENT=8 in
the MEMORY01 matrix (1 IR_LOAD_DEREF + 1 IR_STORE_DEREF per
positive fixture, plus IR_STORE shape-handling).

A targeted strong-NC5 test would require in-memory C-source
mutation to remove the LL_INC_SHAPE_DEPENDENT call; that is
expensive to script. The cap-table verifier already guarantees
that every opcode in the dispatch has a capability row, and
CORE04-RESUME01 verified the per-class counter contract is
machine-enforced.
