#include <stdio.h>
long long AbiHostReport(long long which, long long value) {
    printf("POLYC_SIZEOF_%lld=%lld\n", which, value);
    return value;
}
long long AbiProbeTypeSizes(void);
long long AbiProbePtrToI64(unsigned char *);
unsigned char *AbiProbeI64ToPtr(long long);
int main(void) {
    long long packed = AbiProbeTypeSizes();
    printf("PACKED=%lld\n", packed);
    unsigned char buf[4] = {1,2,3,4};
    long long addr = AbiProbePtrToI64(buf);
    printf("PTR_ECHO_MATCH=%d\n", (unsigned char *)addr == buf);
    unsigned char *back = AbiProbeI64ToPtr(addr);
    printf("I64_TO_PTR_MATCH=%d VALUE=%d\n", back == buf, back ? (int)back[2] : -1);
    return 0;
}
