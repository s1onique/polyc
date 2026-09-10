/* Runtime correctness NC for C9 IMPL.
 *
 * Exercises the 3 RED fixtures at RUNTIME (not just IR-verifier-clean)
 * with multiple inputs covering different CFG paths. If C9's
 * predecessor-store synthesis produces verifier-clean but
 * semantically-wrong IR, this test will expose it.
 *
 * Expected outputs are hand-computed from the source semantics.
 */

I64 ReadDigit(U8 *p);
I64 AccDigit(I64 acc, U8 *p);
I64 Probe(I64 acc, I64 *p);

U8 bytes[16];

I64 main() {
    /* ReadDigit(U8 *p):
     *   d = 0
     *   if (*p >= '0' && *p <= '9') d = *p - '0'
     *   return d
     */
    bytes[0] = '0'; /* '0' = 48 */
    bytes[1] = '5';
    bytes[2] = '9';
    bytes[3] = 'A'; /* not a digit */
    bytes[4] = '/'; /* < '0' */
    bytes[5] = ':'; /* > '9' */

    "ReadDigit(\"0\") = %d (expect 0)\n", ReadDigit(&bytes[0]);
    "ReadDigit(\"5\") = %d (expect 5)\n", ReadDigit(&bytes[1]);
    "ReadDigit(\"9\") = %d (expect 9)\n", ReadDigit(&bytes[2]);
    "ReadDigit(\"A\") = %d (expect 0)\n", ReadDigit(&bytes[3]);
    "ReadDigit(\"/\") = %d (expect 0)\n", ReadDigit(&bytes[4]);
    "ReadDigit(\":\") = %d (expect 0)\n", ReadDigit(&bytes[5]);

    /* AccDigit(I64 acc, U8 *p):
     *   if (*p >= '0' && *p <= '9') acc = acc * 10 + (*p - '0')
     *   return acc
     */
    "AccDigit(100, \"0\") = %d (expect 100)\n",  AccDigit(100, &bytes[0]);
    "AccDigit(100, \"5\") = %d (expect 1005)\n", AccDigit(100, &bytes[1]);
    "AccDigit(100, \"9\") = %d (expect 1009)\n", AccDigit(100, &bytes[2]);
    "AccDigit(100, \"A\") = %d (expect 100)\n",  AccDigit(100, &bytes[3]);

    /* Probe(I64 acc, I64 *p):
     *   x = *p
     *   if (x >= 10) {
     *     if (x <= 99) acc = acc + x
     *   }
     *   return acc
     */
    I64 v9  = 9;
    I64 v10 = 10;
    I64 v50 = 50;
    I64 v100 = 100;
    "Probe(1, 9)   = %d (expect 1)\n",   Probe(1, &v9);
    "Probe(1, 10)  = %d (expect 11)\n",  Probe(1, &v10);
    "Probe(1, 50)  = %d (expect 51)\n",  Probe(1, &v50);
    "Probe(1, 100) = %d (expect 1)\n",   Probe(1, &v100);
    "Probe(0, 50)  = %d (expect 50)\n",  Probe(0, &v50);

    return 0;
}
