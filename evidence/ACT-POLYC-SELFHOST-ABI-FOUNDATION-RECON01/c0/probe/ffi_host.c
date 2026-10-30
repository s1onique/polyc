#include <stdio.h>
#include <stdint.h>
long long AbiHostEchoI64(long long token) { return token; }
long long AbiHostSizes(long long which) {
    if (which == 0) return (long long)sizeof(long long);
    if (which == 1) return (long long)sizeof(int);
    if (which == 2) return (long long)sizeof(_Bool);
    return -1;
}
_Bool AbiHostBool(_Bool value) { return value ? 1 : 0; }
long long AbiProbeEcho(long long);
long long AbiProbeSizes(long long);
_Bool AbiProbeBool(_Bool);
int main(void) {
    long long t = (long long)0xFEDCBA9876543210ULL;
    long long echo = AbiProbeEcho(t);
    printf("PROBE_ECHO_IN=0x%llx OUT=0x%llx MATCH=%d\n", (unsigned long long)t, (unsigned long long)echo, echo == t);
    printf("HOST_SIZEOF_I64=%lld BOOL_HOST=%lld BOOL_POLYC=%lld\n", AbiHostSizes(0), AbiHostSizes(2), AbiProbeSizes(2));
    printf("PROBE_BOOL_TRUE=%d PROBE_BOOL_FALSE=%d\n", (int)AbiProbeBool(1), (int)AbiProbeBool(0));
    return (echo == t) ? 0 : 1;
}
