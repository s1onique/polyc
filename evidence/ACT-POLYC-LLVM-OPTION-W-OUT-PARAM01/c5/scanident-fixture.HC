// ACT-POLYC-LLVM-OPTION-W-OUT-PARAM01 C5 EVIDENCE-B
// ScanIdent binding fixture (compilable subset).
//
// Translates the c1 binding fixture (g3.ir.txt) into
// compilable HolyC. Exercises ALL substrate features
// required for C5 EVIDENCE-B:
//
//   - U8 *src                  pointer parameter
//   - src[cursor]              byte load via GEP
//   - ch == ' '                IR_ICMP on widened byte vs constant
//   - ch == ' ' || ch == '\t'  IR_PHI from logical short-circuit
//   - cursor = cursor + 1      IR_IADD (case-b definition)
//   - *out_cursor = cursor     IR_STORE_DEREF as Option-W value read
//   - *out_len = ...           IR_STORE_DEREF as Option-W value read
//   - cursor - start           IR_ISUB
//   - return 0                 IR_RET
//
// This HC source is the SUBJECT of C5 EVIDENCE-B. It is
// compiled via `hcc --emit-llvm`, assembled via `llvm-as`,
// and verified via `opt --passes=verify`. The runtime
// oracle is exercised independently by the C reference
// scanident-oracle.c (compiled with `cc` on this host);
// the C reference must produce the binding-fixture-mandated
// (out_cursor, out_len) pairs for the 10 binding tests.
//
// c5-build.txt captures the exact reproduction procedure.

I64 ScanIdent(U8 *src, I64 len, I64 cursor,
              I64 *out_cursor, I64 *out_len)
{
    I64 start = cursor;
    while (cursor < len) {
        U8 ch = src[cursor];
        if (ch == ' ' || ch == '\t' || ch == '\n') break;
        cursor = cursor + 1;
    }
    *out_cursor = cursor;
    *out_len = cursor - start;
    return 0;
}
