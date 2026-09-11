#include <stdio.h>

extern long long Diamond(long long flag, long long x);
extern long long ProbePath(long long a, long long b);
extern long long Probe(long long acc, unsigned char *p);
extern long long MultiDef(long long a, long long b, long long c);
extern long long SafeFwdSinglePred(long long x);

int main(void) {
    long long r;

    r = Diamond(1, 42);
    printf("Diamond(1, 42) = %lld (expected 43)\n", r);
    if (r != 43) return 1;

    r = Diamond(0, 42);
    printf("Diamond(0, 42) = %lld (expected 41)\n", r);
    if (r != 41) return 2;

    r = ProbePath(0, 42);
    printf("ProbePath(0, 42) = %lld (expected 10)\n", r);
    if (r != 10) return 3;

    r = ProbePath(5, 42);
    printf("ProbePath(5, 42) = %lld (expected 43)\n", r);
    if (r != 43) return 4;

    r = ProbePath(-3, 42);
    printf("ProbePath(-3, 42) = %lld (expected -42)\n", r);
    if (r != -42) return 5;

    r = MultiDef(0, 7, 0);
    printf("MultiDef(0, 7, 0) = %lld (expected 7)\n", r);
    if (r != 7) return 6;

    r = MultiDef(99, 7, 1);
    printf("MultiDef(99, 7, 1) = %lld (expected 198)\n", r);
    if (r != 198) return 7;

    printf("ALL RUNTIME CHECKS PASS\n");
    return 0;
}
