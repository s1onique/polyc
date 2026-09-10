/* Diamond (new fixture for ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02):
 * classic diamond CFG, single mutable local, distinct branches converge.
 *
 *   I64 Diamond(I64 flag, I64 x) {
 *       I64 r;
 *       if (flag) r = x + 1;
 *       else     r = x - 1;
 *       return r;
 *   }
 *
 *   Diamond(true, 42)  == 43   (x + 1)
 *   Diamond(false, 42) == 41   (x - 1)
 *
 * Source-path semantics required: at the join, the returned
 * value must reflect the executed branch.
 */
I64 Diamond(I64 flag, I64 x) {
    I64 r;
    if (flag) {
        r = x + 1;
    } else {
        r = x - 1;
    }
    return r;
}
