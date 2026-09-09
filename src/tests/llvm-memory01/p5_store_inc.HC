/* P5: Store value produced by scalar arithmetic.
 *
 * Source equivalent to:
 *   I64 StoreInc(I64 *p)
 *   {
 *       *p = *p + 1;
 *       return *p;
 *   }
 *
 * (Reading back *p at the end keeps the local promotion chain
 *  intact and verifies the value produced by *p + 1 is the one
 *  actually stored.)
 */
I64 StoreInc(I64 *p)
{
    *p = *p + 1;
    return *p;
}
