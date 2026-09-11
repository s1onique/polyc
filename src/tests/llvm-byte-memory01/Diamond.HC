/* Diamond (production fixture for ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02):
 * classic diamond CFG, single mutable local, distinct branches converge.
 *
 *   I64 Diamond(I64 flag, I64 x) {
 *       I64 r;
 *       if (flag != 0) r = x + 1;
 *       else          r = x - 1;
 *       return r;
 *   }
 *
 *   Diamond(true, 42)  == 43   (x + 1)
 *   Diamond(false, 42) == 41   (x - 1)
 *
 * Source-path semantics required: at the join, the returned
 * value must reflect the executed branch.
 *
 * History:
 *   C3 evidence-only:  evidence/.../c3/fixture-diamond/Diamond.HC
 *   C6.1 promoted:     src/tests/llvm-byte-memory01/Diamond.HC
 *                      (original used `if (flag)` directly; C6.1
 *                       rewrites to `if (flag != 0)` because the
 *                       front-end lowers `if (x)` as a TRUNC/I8 path
 *                       which the backend does not authorise in this
 *                       ACT's MEMORY01 scope.)
 */
I64 Diamond(I64 flag, I64 x) {
    I64 r;
    if (flag != 0) {
        r = x + 1;
    } else {
        r = x - 1;
    }
    return r;
}
