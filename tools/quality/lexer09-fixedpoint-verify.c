// tools/quality/lexer09-fixedpoint-verify.c
//
// ACT-POLYC-SELFHOST-LEXER04 C2 IMPL.
//
// C-implementation of the 4-generation component fixed-point
// verifier. Mirrors the LEXER08 PolyC verifier byte-for-byte
// in verdict line format and exit code semantics.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

static int read_file(const char *path, unsigned char **out, size_t *out_size)
{
    FILE *f = fopen(path, "rb");
    if (!f) return -1;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n <= 0) { fclose(f); return -1; }
    unsigned char *buf = (unsigned char *)malloc((size_t)n);
    if (!buf) { fclose(f); return -1; }
    size_t r = fread(buf, 1, (size_t)n, f);
    fclose(f);
    if (r != (size_t)n) { free(buf); return -1; }
    *out = buf;
    *out_size = (size_t)n;
    return 0;
}

static int objects_byte_equal(const unsigned char *a, size_t asz,
                               const unsigned char *b, size_t bsz)
{
    if (asz != bsz) return 0;
    if (asz == 0) return 1;
    return memcmp(a, b, asz) == 0;
}

static int sha256_of_file(const char *path, char hex_out[65])
{
    char cmd[4096];
    snprintf(cmd, sizeof(cmd), "./build/lexer07-sha256 --file %s", path);
    FILE *p = popen(cmd, "r");
    if (!p) return -1;
    char buf[128];
    if (!fgets(buf, sizeof(buf), p)) { pclose(p); return -1; }
    pclose(p);
    size_t len = strlen(buf);
    while (len > 0 && (buf[len-1] == '\n' || buf[len-1] == '\r')) {
        buf[--len] = 0;
    }
    if (len != 64) return -1;
    strncpy(hex_out, buf, 65);
    return 0;
}

static void emit_bool(int b) {
    printf("%s", b ? "YES" : "NO");
}

#define MAX_FILES 5

int main(int argc, char **argv)
{
    int allow_closed = 0;
    const char *files[MAX_FILES];
    int nfiles = 0;
    for (int i = 1; i < argc; i++) {
        if (strncmp(argv[i], "--allow-closed", 14) == 0) {
            allow_closed = 1;
            continue;
        }
        if (nfiles >= MAX_FILES) {
            printf("FIXEDPOINT_VERIFIER_RC=2 reason=too-many-files\n");
            return 2;
        }
        files[nfiles++] = argv[i];
    }

    if (nfiles != 4 && nfiles != 5) {
        printf("FIXEDPOINT_VERIFIER_USAGE: <obj0> <obj1> <obj2> <obj3> [mutated]\n");
        return 2;
    }

    if (!allow_closed) {
        for (int i = 0; i < nfiles; i++) {
            if (strstr(files[i], "/CORRECTION0") != NULL &&
                strstr(files[i], "/c") != NULL) {
                printf("FIXEDPOINT_VERIFIER_RC=3 reason=closed-evidence path=%s\n",
                       files[i]);
                return 3;
            }
        }
    }

    unsigned char *bufs[MAX_FILES];
    size_t          sizes[MAX_FILES];
    char            shas[MAX_FILES][65];

    for (int i = 0; i < nfiles; i++) {
        sizes[i] = 0;
        bufs[i] = NULL;
        if (read_file(files[i], &bufs[i], &sizes[i]) != 0 || sizes[i] == 0) {
            printf("FIXEDPOINT_VERIFIER_RC=2 reason=missing-or-empty file=%s\n",
                   files[i]);
            if (bufs[i]) free(bufs[i]);
            return 2;
        }
        if (sha256_of_file(files[i], shas[i]) != 0) {
            printf("FIXEDPOINT_VERIFIER_RC=4 reason=sha256-error file=%s\n",
                   files[i]);
            free(bufs[i]);
            return 4;
        }
        printf("FILE[%d] path=%s size=%zu sha256=%s\n",
               i, files[i], sizes[i], shas[i]);
    }

    const char *pair_tags[6] = {
        "G0_G1", "G0_G2", "G0_G3",
        "G1_G2", "G1_G3", "G2_G3"
    };
    int pair_a[6] = {0, 0, 0, 1, 1, 2};
    int pair_b[6] = {1, 2, 3, 2, 3, 3};
    int pair_eq[6];

    int all_eq = 1;
    for (int k = 0; k < 6; k++) {
        int eq = objects_byte_equal(bufs[pair_a[k]], sizes[pair_a[k]],
                                     bufs[pair_b[k]], sizes[pair_b[k]]);
        pair_eq[k] = eq;
        printf("PAIR %s file_i=%d file_j=%d size_a=%zu size_b=%zu equal=",
               pair_tags[k], pair_a[k], pair_b[k],
               sizes[pair_a[k]], sizes[pair_b[k]]);
        emit_bool(eq);
        printf("\n");
        if (!eq) all_eq = 0;
    }

    if (nfiles == 5) {
        int eq = objects_byte_equal(bufs[3], sizes[3],
                                     bufs[4], sizes[4]);
        printf("PAIR G3_VS_MUTATED file_i=3 file_j=4 equal=");
        emit_bool(eq);
        printf("\n");
        if (eq) {
            printf("FIXEDPOINT_VERIFIER_RC=1 reason=mutated-equals-pristine\n");
            printf("NEGATIVE_CONTROL=FAIL reason=verifier-accepted-mutation\n");
            for (int i = 0; i < nfiles; i++) free(bufs[i]);
            return 1;
        }
        printf("BYTE_MISMATCH_DETECTED=YES\n");
        printf("NEGATIVE_CONTROL=PASS\n");
        printf("FIXEDPOINT_VERIFIER_RC=1 verdict=NEGATIVE_CONTROL_DETECTED_MISMATCH\n");
        for (int i = 0; i < nfiles; i++) free(bufs[i]);
        return 1;
    }

    if (all_eq) {
        printf("FIXEDPOINT_VERIFIER_RC=0 verdict=PASS\n");
        printf("LEXER09_LINK_FIXED_POINT_4_GENERATIONS=PASS\n");
        for (int i = 0; i < nfiles; i++) free(bufs[i]);
        return 0;
    }

    printf("FIXEDPOINT_VERIFIER_RC=1 verdict=FAIL\n");
    for (int i = 0; i < nfiles; i++) free(bufs[i]);
    return 1;
}
