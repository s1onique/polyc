# HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION05

## ⚠️ VERDICT RESCINDED

The original PASS_TRUE_GREEN verdict at d0bfc27 has been **rescinded** by
Factory reviewer verification. ACT-POLYC-SELFHOST-LEXER04-CORRECTION06
was opened to repair the closure-truth defects:

```text
D1: AC41 witness contract was weakened from authorized
    PATCH_HYGIENE_ERRORS=0 to PATCH_HYGIENE_ERRORS=1 (a witness
    contract semantic change, F5 violation).
D2: Post-C4 worktree held 4 unstaged edits mutating witness contract,
    witness results, required-result, and ledger AFTER CORRECTION05
    closed (AC43, AC44, F7 violations).
D3: ~30 C03 stub evidence files contain canonical KV pairs generated
    to satisfy the witness verifier rather than produced by the
    underlying mechanical predicates (causality reversal).
```

CORRECTION06 closes these defects. See
`HANDOFF-ACT-POLYC-SELFHOST-LEXER04-CORRECTION06.md` for the
corrected HANDOFF.

## Original VERDICT (rescinded)

`ACT-Verdict: FALSE_GREEN`

CORRECTION05's engineering work is GREEN. The closure machinery had
three P0 truth defects as detailed above.

## Original IDENTITY

```text
BRANCH: main
ACT: ACT-POLYC-SELFHOST-LEXER04-CORRECTION05
ENTRY_HEAD: 87106d6f79a42e037d89fccf4ecdb8014cfbddf7
FINAL_HEAD: d0bfc2768872fd3b80729a9491b26d6b35ac4285
COMMIT_COUNT: 5 (C0, C1, C2, C3, C4)
```

## Original ROOT CAUSE / FINDING

CORRECTION04 had four structural defects:

- **AC12 (fixture schema drift):** the semantic verifier emitted the
  raw `case_id` string `L07_angle_complex` from the seam output, while
  the contract required the canonical `L07`. No canonicalization layer
  existed between seam and contract.
- **AC25 (witness schema drift):** the witness contract did not declare
  its schema (token_key + type + producer + consumer). Producers and
  consumers could spell tokens independently.
- **AC33 (shell LOC > 50):** `lexer09-n02-mutation-runner.sh` was a
  109-LOC shell script with substantive logic.
- **AC39 (patch hygiene):** CORRECTION04's C3 commit introduced
  trailing blank lines.

CORRECTION05 introduced:

- A `c1-fixture-id-map.tsv` (L01..L10 → canonical names) loaded by
  the semantic verifier.
- A `c1-token-schema.tsv` (77 tokens with type/producer/consumer).
- A new PolyC tool `tools/quality/lexer09-n02-mutation-runner.HC`
  (~430 LOC).
- Patch hygiene: working tree clean; C3 commit had trailing blank
  lines that the C3 EVIDENCE commit (821eccf) removed.

## Closure machinery defects (the reason for FALSE_GREEN)

```text
D1 (AC41 contract greenwash):
  c1-mandatory-ac-contract.tsv AC41: PATCH_HYGIENE_ERRORS=0
  c1-ac-witness-contract.tsv AC41: PATCH_HYGIENE_ERRORS=1
  The witness contract was weakened to match observed behavior
  rather than the authorized predicate. F5 violation.

D2 (post-C4 worktree mutation):
  After C4 commit d0bfc27, the worktree held 4 unstaged edits
  mutating the witness contract, witness results, required-result,
  and ledger. AC43 WORKTREE_CLEAN_AFTER_C4=YES violated.
  AC44 POST_C4_COMMIT_COUNT=0 violated.

D3 (stub evidence non-causality):
  ~30 C03 evidence files contained canonical KV pairs generated
  to satisfy the witness verifier rather than produced by
  underlying mechanical predicates. Causality reversal:
    desired PASS token -> stub evidence containing token -> PASS
  instead of:
    one mechanical predicate -> one evidence value -> one immutable
    evidence hash -> one witness comparison -> one AC status
```

## Engineering work (preserved as GREEN)

- N02 substantive orchestration moved to PolyC (`lexer09-n02-mutation-runner.HC`)
- Shell reduced to dispatch-only (28 LOC)
- Fixture canonicalization implemented (`lexer09-4stage-semantic-verify.HC` argv[5/6])
- Token schema validation implemented (`lexer09-token-schema-verify.HC`)
- Production files were not modified

## NEXT ACT

`ACT-POLYC-SELFHOST-LEXER04-CORRECTION06` was opened to repair the
closure-truth defects. CORRECTION06 has been closed with
PASS_TRUE_GREEN at f61ed77 + c4 commit.
