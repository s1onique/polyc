# ACT-POLYC-SELFHOST-LEXER04-CORRECTION06

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair the three CORRECTION05 closure-truth defects:
AC41 contract greenwash, post-C4 worktree dirt, and stub evidence
non-causality

**Repository:** PolyC
**Branch:** `main`

**Class:** SELFHOST / LEXER / QUALIFICATION-INFRA / CORRECTION-CORRECTION

**Priority:** P0

---

# 0. Mission

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION05` terminated as
**FALSE_GREEN** under Factory reviewer verification. The engineering
work (N02 PolyC authority, fixture canonicalization, token schema
implementation) is GREEN. The closure machinery has three P0 truth
defects:

```text
D1: AC41 witness contract was weakened from authorized
    PATCH_HYGIENE_ERRORS=0 to PATCH_HYGIENE_ERRORS=1
    (a witness contract semantic change, F5 violation)

D2: post-C4 worktree held 4 unstaged edits mutating witness
    contract, witness results, required-result, and ledger
    AFTER CORRECTION05 closed (AC43, AC44, F7 violations)

D3: ~30 C03 stub evidence files contain canonical KV pairs
    generated to satisfy the witness verifier rather than
    produced by the underlying mechanical predicates
    (causality reversal)
```

CORRECTION06 closes these three defects without amending any
CORRECTION05 commit.

---

# 1. Phase plan (5 phases)

```text
C0  AUTH        -- this ACT + entry identity + scope + authorization
                    integrity + dirty state RED capture
C1  RED         -- repair plan: which stubs get replaced by what
                    raw evidence, AC41 contract restore strategy,
                    AC42 contract restore, AC43/AC44 already-satisfied
                    explanation
C2  IMPL        -- if needed: a small production fix to genuinely
                    achieve PATCH_HYGIENE_ERRORS=0 (e.g., the C2
                    trailing-blank-line residue can be repaired by
                    a follow-up edit in C2 OR by accepting residue
                    and using the authorized predicate). The choice
                    is recorded in C1.
C3  EVIDENCE    -- replace stub evidence files with raw mechanical
                    evidence or mechanically derived projections;
                    restore c1-ac-witness-contract.tsv to authorized
                    AC41 value; re-run witness verifier; re-run
                    ledger verifier
C4  CLOSE       -- HANDOFF with verbatim witness/ledger summaries;
                    clean tree; ACT-Verdict: PASS_TRUE_GREEN
```

Topology cap: max 5 commits (C0..C4).

---

# 2. Predicates (what PASS_TRUE_GREEN requires)

```text
AC_TOTAL = 44
AC_PASS  = 44
AC_FAIL  = 0

WITNESS_TOTAL  = 75
WITNESS_PASS   = 75
WITNESS_FAIL   = 0
WITNESS_MISSING = 0

AC41  PATCH_HYGIENE_ERRORS = 0     (AUTHORIZED, restored from weakened)
AC42  CORRECTION05_COMMIT_COUNT = 5; C0_C1_C2_C3_C4_ORDER = YES
AC43  WORKTREE_CLEAN_AFTER_C4 = YES
AC44  POST_C4_COMMIT_COUNT = 0

TOKEN_SCHEMA_DUPLICATES = 0
WITNESS_KEYS_WITHOUT_SCHEMA = 0
TOKEN_SCHEMA_PRODUCER_CONSUMER_DRIFT = 0

N02_OUTCOME = PASS
MUTATED_COMPONENT_SHA256 = dcb7a478e751a598c161c7c42f8b2a327dace0679ba2fa58b387287cca88c683
```

---

# 3. HALT taxonomy

```text
HALT_AUTHORIZATION_INTEGRITY_FAIL
HALT_PRE_RED_PRODUCTION_CHANGE
HALT_WITNESS_CONTRACT_SEMANTIC_CHANGE_REQUIRED
HALT_POST_C4_MUTATION
HALT_STUB_EVIDENCE_REMAINS_FOR_MANDATORY_AC
HALT_RC_NOT_ZERO
HALT_WORKTREE_DIRTY_AT_C4
HALT_GIT_DIFF_CHECK_FAIL
```

---

# 4. Evidence required at C3 close

```text
c3-ac-witness-results.tsv       (75/75 PASS)
c3-mandatory-ac-status.tsv       (44/44 PASS, AC41=PATCH_HYGIENE_ERRORS=0)
c3-ac-ledger-summary.txt         (AC_LEDGER_RC=0)
c3-token-schema-verify.txt       (TOKEN_SCHEMA_VERIFY_RC=0)
c3-required-result.txt           (CORRECTION06_COMMIT_COUNT=5)
c3-raw-evidence-registry.tsv     (mapping stub -> raw evidence)
c3-stub-evidence-replaced.txt    (list of files replaced)
c3-ac41-restoration.txt          (verbatim C1 contract restore)
c3-n02-production-causal-control.txt  (N02_OUTCOME=PASS)
```

---

# 5. C4 close requirements

```text
- HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION06.md
- AC_LEDGER_RC=0, WITNESS_RC=0, TOKEN_SCHEMA_VERIFY_RC=0, N02_OUTCOME=PASS
- WORKTREE_CLEAN_AFTER_C4=YES
- POST_C4_COMMIT_COUNT=0
- ACT-Verdict: PASS_TRUE_GREEN trailer
- Exactly one C4 commit
- c4-parent-identity.txt updated
- c4-terminal-ledger.txt updated
- HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION05.md has been edited
  to RESCIND the FALSE_GREEN verdict (no amendment; new content
  appended in C4 only)
```

---

# 6. Authorized scope

Allowed file modifications:

- tools/quality/lexer09-*.HC (production tools)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c1-ac-witness-contract.tsv (RESTORE authorized value)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-*.txt (REPLACE stubs)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/c3-*.tsv (REPLACE stubs)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c3/mandatory-ac-status.tsv (RE-DERIVE)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION05/c4/c4-*.txt (re-touch if needed)
- evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION06/* (NEW)
- docs/acts/ACT-POLYC-SELFHOST-LEXER04-CORRECTION06.md (NEW)
- docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION05.md (RESCIND verdict)
- docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION06.md (NEW)

Forbidden:

- amend any CORRECTION05 commit
- modify src/holy_c/compiler/lexer*.HC (production frozen)
- weaken any authorized AC predicate
- close with a dirty worktree

---

# 7. Why CORRECTION05 cannot be amended

```text
F14 (current truth may invalidate history)
AGENTS.md append-only invariant (baf5dbd77c..)
pre-push hook .githooks/pre-push (3 graph checks)
```

CORRECTION05 history is immutable evidence. CORRECTION06 lives in
new commits that repair the closure machinery without rewriting
history.

---

# 8. ACT-Verdict semantics

This ACT's PASS_TRUE_GREEN means:

```text
AC41 PATCH_HYGIENE_ERRORS=0 holds in the committed C1 witness contract
    (NOT weakened to 1)
AC42 CORRECTION05_COMMIT_COUNT=5 holds in the committed C1 witness contract
AC43 WORKTREE_CLEAN_AFTER_C4=YES holds at C4 close
AC44 POST_C4_COMMIT_COUNT=0 holds at C4 close
D3 stub-evidence files that participate in mandatory ACs have been
    replaced with raw mechanical evidence or mechanically derived
    projections whose provenance points to raw evidence
```

This is a stricter verdict than CORRECTION05's claimed PASS_TRUE_GREEN.
