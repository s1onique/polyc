/* c1-oracle-harness.c
 *
 * Reproducible oracle harness for
 * ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01.
 *
 * The reference side is the REAL production function
 * parseValidPostControlFlowToken (src/parser.c:832..864), linked from the
 * production object build/CMakeFiles/hcc.dir/parser.c.o.  This harness only
 * DRIVES it; it does NOT re-implement the decision table (the predecessor's
 * ABI contract section 8 forbids a re-implementation as the reference).
 *
 * Usage: ./oracle <fixture-model.tsv>
 * Exit status: 0 = every row agrees with the stated expectation,
 *              1 = at least one disagreement,
 *              2 = usage / IO error.
 *
 * The exact build and run commands are in c1-fixture-oracle.txt.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

/* The REAL Lexeme layout, copied from src/lexer.h:172..187. */
typedef struct Lexeme {
    int tk_type;
    int len;
    int line;
    int col;
    char *start;
    int ishex;
    union { int64_t i64; double f64; };
} Lexeme;

/* The production function, declared exactly as in src/parser.c:832. */
int parseValidPostControlFlowToken(Lexeme *tok);

/* is_terminal is a UI global defined in src/main.c, which also defines
 * main() and therefore cannot be linked into this harness.  The oracle
 * never touches it; this definition exists only to satisfy the linker. */
int is_terminal = 0;

static int parse_ll(const char *s, int64_t *out) {
    char *end = NULL;
    long long v = strtoll(s, &end, 0);
    if (end == s || *end != '\0') return 0;
    *out = (int64_t)v;
    return 1;
}

int main(int argc, char **argv) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <fixture-model.tsv>\n", argv[0]);
        return 2;
    }
    FILE *f = fopen(argv[1], "r");
    if (!f) { perror("open"); return 2; }

    char line[8192];
    int rows = 0, accept = 0, reject = 0, disagree = 0;

    while (fgets(line, sizeof line, f)) {
        if (line[0] == '#' || line[0] == '\n') continue;
        if (strncmp(line, "F", 1) != 0) continue;

        /* id \t partition \t present \t kind \t value \t expected \t ... */
        char id[32];
        int present = 0;
        unsigned long long kind = 0;
        long long value = 0;
        int stated = 0;

        char *p = line;
        char *tokp = strtok(p, "\t");
        if (!tokp) continue;
        strncpy(id, tokp, sizeof id - 1);
        id[sizeof id - 1] = '\0';
        if (!strtok(NULL, "\t")) continue;                 /* partition */
        tokp = strtok(NULL, "\t"); if (!tokp) continue;   /* present */
        present = atoi(tokp);
        tokp = strtok(NULL, "\t"); if (!tokp) continue;   /* kind */
        kind = strtoull(tokp, NULL, 0);
        tokp = strtok(NULL, "\t"); if (!tokp) continue;   /* value */
        if (!parse_ll(tokp, (int64_t *)&value)) continue;
        tokp = strtok(NULL, "\t"); if (!tokp) continue;   /* expected */
        stated = atoi(tokp);

        Lexeme lex;
        memset(&lex, 0, sizeof lex);
        lex.tk_type = (int)kind;
        lex.i64 = (int64_t)value;

        int oracle = parseValidPostControlFlowToken(present ? &lex : NULL);

        rows++;
        if (oracle) accept++; else reject++;

        char kindbuf[32];
        if (kind == 0) snprintf(kindbuf, sizeof kindbuf, "0");
        else if (kind == 123456) snprintf(kindbuf, sizeof kindbuf, "123456");
        else snprintf(kindbuf, sizeof kindbuf, "0x%llx", kind);

        const char *verdict = (oracle == stated) ? "AGREE" : "*** DISAGREE ***";
        if (oracle != stated) disagree++;

        printf("%s\tpresent=%d\tkind=%s\tvalue=%lld\tstated=%d\toracle=%d\t%s\n",
               id, present, kindbuf, value, stated, oracle, verdict);
    }
    fclose(f);

    printf("ROWS=%d ACCEPT=%d REJECT=%d DISAGREE=%d\n",
           rows, accept, reject, disagree);
    return disagree ? 1 : 0;
}
