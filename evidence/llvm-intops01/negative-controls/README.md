=== INTOPS01 negative controls ===

Per the halt outcome, NO new IMPLEMENT rows were added. Therefore,
most negative-control classes (NC1, NC2, NC6, NC7, NC8) defined in
ACT §23 do not apply — there is no new dispatch arm to break.

The applicable controls are:

## NC3 — counter increment (no-op, since no new dispatches)
    The cap verifier confirms the cap-table matches dispatch.
    No NEW counter increment was added; no per-fixture NC3 is needed.

## NC4 — capability-table mismatch (no-op, since no new rows)
    The cap verifier confirms the cap-table matches dispatch.
    No new row was added; no NC4 mutation is possible.

## NC5 — dispatch/table mismatch inverse (no-op)
    Same as NC4.

## Spurious-capability protection
    A regression test that asserts that hcc --print-cap-table
    does not promote any of IR_AND / IR_OR / IR_XOR / IR_NOT /
    IR_SHL / IR_SHR / IR_SAR / IR_INEG / IR_IDIV / IR_UDIV /
    IR_IREM / IR_UREM / IR_TRUNC / IR_ZEXT / IR_SEXT to
    SUPPORTED or SHAPE_DEPENDENT.

    This is mechanically guaranteed by the unchanged
    src/llvm-backend-cap.c file (see scope.txt).

## Direct cap-table check

    $ python3 scripts/quality/llvm-cap-table-verifier.py
    PASS  IR_AND     REJECTED  (unchanged)
    PASS  IR_OR      REJECTED  (unchanged)
    PASS  IR_XOR     REJECTED  (unchanged)
    PASS  IR_NOT     REJECTED  (unchanged)
    PASS  IR_SHL     REJECTED  (unchanged)
    PASS  IR_SHR     REJECTED  (unchanged)
    PASS  IR_SAR     REJECTED  (unchanged)
    PASS  IR_INEG    REJECTED  (unchanged)
    PASS  IR_IDIV    REJECTED  (unchanged)
    PASS  IR_UDIV    REJECTED  (unchanged)
    PASS  IR_IREM    REJECTED  (unchanged)
    PASS  IR_UREM    REJECTED  (unchanged)
    PASS  IR_TRUNC   REJECTED  (unchanged)
    PASS  IR_ZEXT    REJECTED  (unchanged)
    PASS  IR_SEXT    REJECTED  (unchanged)

    (full verifier output recorded in closure/cap-verifier.txt)
