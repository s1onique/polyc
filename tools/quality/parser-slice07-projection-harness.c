/* The CONDITIONAL-PROJECTION READ-COUNT HARNESS.
 *
 * It replicates the EXACT projection guard that src/parser.c uses, but
 * over an INSTRUMENTED host node whose `declvar` field access is
 * COUNTED.  The instrumented node's declvar access is a FUNCTION CALL,
 * so the harness can OBSERVE whether the projection read it, without
 * ever invoking undefined behaviour: for a non-declaration statement
 * the instrumented node simply reports that the field was absent.
 *
 * The harness NEVER dereferences a null pointer.  For the non-AST_DECL
 * case the instrumented accessor returns a sentinel WITHOUT reading
 * anything, which is exactly what "the C side never touched
 * stmt->declvar" must mean.
 */
#include <stdio.h>

/* The instrumented host node. */
struct InstAst {
    int kind;                 /* stmt->kind */
    int declvar_kind;         /* stmt->declvar->kind, valid only when declvar_reads == 1 */
    int declvar_present;      /* 0 -> the field is ABSENT and reading it would trap */
    int declvar_reads;        /* the READ COUNT */
    int trap_on_read;         /* 1 -> a read of an absent field is a TRAP */
    int trapped;              /* the TRAP flag */
};

static int instrumented_declvar_kind(struct InstAst *n)
{
    n->declvar_reads = n->declvar_reads + 1;
    if (n->declvar_present == 0) {
        n->trapped = 1;
        return 0;
    }
    return n->declvar_kind;
}

/* THE PROJECTION GUARD -- byte-for-byte the shape of the guard in
 * src/parser.c:parseCompoundStatementInternal. */
static int project_and_decide(struct InstAst *stmt, int ast_decl_value)
{
    int projected_stmt_kind = stmt->kind;
    int projected_declvar_kind = 0;
    if (projected_stmt_kind == ast_decl_value) {
        projected_declvar_kind = instrumented_declvar_kind(stmt);
    }
    /* The frozen rule, transcribed. */
    if (projected_stmt_kind == ast_decl_value && projected_declvar_kind == 256) {
        return 0;   /* SKIP */
    }
    return 1;       /* APPEND */
}

#define AST_DECL 263
#define AST_GVAR 256

int main(void)
{
    struct InstAst n;
    int r;

    /* CASE 1: a NON-declaration whose declvar field is ABSENT.
     * Reading it would trap.  The projection must NOT read it. */
    n.kind = 270;                 /* AST_RETURN */
    n.declvar_kind = 0;
    n.declvar_present = 0;        /* ABSENT */
    n.declvar_reads = 0;
    n.trap_on_read = 1;
    n.trapped = 0;
    r = project_and_decide(&n, AST_DECL);
    printf("CASE1_NONDECL_ABSENT_DECLVAR result=%d reads=%d trapped=%d\n",
           r, n.declvar_reads, n.trapped);

    /* CASE 2: a non-declaration whose declvar IS present with a
     * global value.  The projection must NOT read it either: the
     * legacy && short-circuits. */
    n.kind = 270;
    n.declvar_kind = AST_GVAR;
    n.declvar_present = 1;
    n.declvar_reads = 0;
    n.trapped = 0;
    r = project_and_decide(&n, AST_DECL);
    printf("CASE2_NONDECL_GLOBAL_DECLVAR result=%d reads=%d trapped=%d\n",
           r, n.declvar_reads, n.trapped);

    /* CASE 3: a DECLARATION whose declvar IS a global.  The projection
     * MUST read it exactly once, and the decision must be SKIP. */
    n.kind = AST_DECL;
    n.declvar_kind = AST_GVAR;
    n.declvar_present = 1;
    n.declvar_reads = 0;
    n.trapped = 0;
    r = project_and_decide(&n, AST_DECL);
    printf("CASE3_DECL_GLOBAL result=%d reads=%d trapped=%d\n",
           r, n.declvar_reads, n.trapped);

    /* CASE 4: a DECLARATION whose declvar is a local.  Exactly one
     * read, and the decision must be APPEND. */
    n.kind = AST_DECL;
    n.declvar_kind = 261;
    n.declvar_present = 1;
    n.declvar_reads = 0;
    n.trapped = 0;
    r = project_and_decide(&n, AST_DECL);
    printf("CASE4_DECL_LOCAL result=%d reads=%d trapped=%d\n",
           r, n.declvar_reads, n.trapped);

    return 0;
}
