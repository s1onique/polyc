# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04

## Identity

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04
- Phase:  C0 AUTH (authorization; no production mutation)
- Predecessor: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03
- Predecessor verdict (HANDOFF): PASS_TRUE_GREEN
- Predecessor reclassification (this ACT): FALSE_GREEN
- Reviewer disposition evidence:
  evidence/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04/
    c0/c0-reviewer-reclassification-disposition.txt
- Entry identity:
    git branch --show-current = main
    git rev-parse HEAD        = 8fbf51db74217879cc13e4665a49c12942a15670
    git status --short        = clean

## Predecessor in scope (reclassification, not repair)

- ACT id: ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03
- Open:   87aec89
- C1 RED: 1669bce
- C2 PRE: 6370707 (additive capture)
- C2 IMPL: f9906f1 (F14 restoration)
- C3 VERIFY: 26cbee8
- C4 CLOSE (claimed terminal): aa47d58
- C4 patch hygiene follow-up: 8fbf51d
- HANDOFF verdict recorded: PASS_TRUE_GREEN
- Reviewer verdict (this ACT's scope): FALSE_GREEN
- Reclassification of CORRECTION03:
    ENGINEERING_GREEN          (F14 restoration, additive capture,
                                 12/12 regression, oracle mechanics)
    PATCH_HYGIENE_AUTH_FAIL    (predicate #6 false: 4 EOF whitespace
                                 errors introduced by restoration)
    MANIFEST_SCOPE_DISCIPLINE_FAIL
                               (C0 ACT modified
                                 docs/factory/act-handoff-map.tsv
                                 which the same ACT declared out-of-scope)
    OVERALL                    FALSE_GREEN

### Two binding P0 defects the reviewer flagged

P0-1 — Authorized patch-hygiene predicate is false

  The CORRECTION03 ACT body, line 125, froze:

    6. git diff --check 0665ada..HEAD continues to report clean.

  At HEAD = 8fbf51d, this predicate is observably FALSE:

    $ git diff --check 0665ada..HEAD
    .../CORRECTION01/c2/c2-p02-n01-n05-regression.txt:29: new blank line at EOF.
    .../CORRECTION01/c3/c3-act-body-unchanged.txt:10: new blank line at EOF.
    .../CORRECTION01/c3/c3-checker-unchanged.txt:6: new blank line at EOF.
    .../CORRECTION01/c3/c3-manifest-unchanged.txt:6: new blank line at EOF.

  These errors are inherent to the b9a43f8 historical blobs (the
  files were added by CORRECTION01 with trailing blank lines). The
  CORRECTION02 patch-hygiene fix (f011d56) had previously removed
  these blanks via a separate forward-only commit. CORRECTION03's
  F14 restoration reverted CORRECTION01's evidence to those exact
  b9a43f8 blobs and therefore re-introduced the blanks. Both facts
  are true simultaneously:
    - F14 restoration is byte-faithful to b9a43f8.
    - Patch hygiene predicate 0665ada..HEAD = clean is unsatisfiable
      while the restoration stands and the predicate is anchored to
      a baseline that predates the addition of these files.

P0-2 — Manifest mutation occurred under explicit out-of-scope

  The CORRECTION03 ACT body, line 91, declared:

    docs/factory/act-handoff-map.tsv (working; do not touch)

  The C0 AUTH commit (87aec89) modified that exact file:

    $ git show 87aec89 -- docs/factory/act-handoff-map.tsv
    ... +ACT-...-CORRECTION03 row ...

  This is a F15 self-authorization defect: the C0 commit performed
  work that the same C0 commit declared out-of-scope.

## Scope (bounded)

This ACT is reclassification-only. It does not repair the
defects. It records the reviewer's FALSE_GREEN verdict as additive
evidence and freezes the reclassification. Repair requires a
subsequent bounded ACT (CORRECTION05 or beyond) whose scope
explicitly authorizes the necessary file mutations and patch
hygiene baseline; that ACT cannot be opened from this C0 because
this C0 lacks the authority to bind it.

### P0-1 recording (no repair)

- Record the predicate falsification as additive evidence at
  c0/c0-p01-patch-hygiene-falsification.txt.
- The 4 closed CORRECTION01 evidence files remain bitwise
  identical to their b9a43f8 blobs. F14 restoration stands.
- No attempt is made here to choose a different patch-hygiene
  baseline, because selecting a baseline that is actually clean
  would require either:
    (a) abandoning the F14 restoration (F15 scope expansion),
    (b) re-opening CORRECTION01 to clean its evidence at source
        (F14 immutability violation), or
    (c) amending CORRECTION02's whitespace-clean in place
        (F14 immutability violation of CORRECTION02).
  All three are out of scope per F7/F15.

### P0-2 recording (no repair)

- Record the manifest-mutation observation as additive evidence
  at c0/c0-p02-manifest-scope-violation.txt, with SHA-pinned
  evidence from commit 87aec89.
- The manifest self-row added by 87aec89 is forward-only history
  and remains in place. F14 forbids rewriting it.
- No retroactive "authorization" of the C0 manifest mutation is
  attempted here, because:
    - It would require editing CORRECTION03's C0 ACT body
      (F14 immutability), OR
    - Issuing a post-hoc ratification would constitute exactly
      the kind of post-hoc scope authorization F15 forbids.
  Per F4, this defect is recorded as evidence, not papered over.

### Forward-only reclassification statement

- CORRECTION03's HANDOFF at
  docs/factory/HANDOFF-ACT-POLYC-FACTORY-CLOSURE-ORACLE-
  EXTENSIBLE01-CORRECTION03.md claims PASS_TRUE_GREEN.
- This ACT records (does not rewrite) that the actual verdict is
  FALSE_GREEN with two binding P0 defects.
- Any downstream consumer of the closure oracle MUST treat the
  CORRECTION03 HANDOFF verdict as FALSE_GREEN, not as the literal
  text "PASS_TRUE_GREEN" it contains. The HANDOFF file remains
  immutable per F14; the reclassification lives at this ACT's
  c0/ namespace and propagates via the additive C3 12-pair
  oracle-self-row.

### Manifest self-row for this ACT (CORRECTION04)

- This ACT, like every closure-oracle ACT since CORRECTION02,
  MUST register itself in docs/factory/act-handoff-map.tsv
  for the 12-pair oracle to recognize it as a closed pair at C4.
- This ACT explicitly authorizes that mutation as IN-SCOPE at C0
  (here, in this "Manifest self-row" subsection). This converts
  the reviewer-flagged P0-2 from a defect of THIS ACT to an
  intentional, declared design decision.
- The mutation will be performed at C4 (HANDOFF commit), not at
  C0, so the C0 AUTH commit remains the smallest possible
  evidence-only commit.

## Authorized mutations (this ACT)

- C0: docs/acts/...-CORRECTION04.md (this ACT body) +
       evidence/.../CORRECTION04/c0/* (reviewer disposition +
       P0-1 + P0-2 evidence files)
- C4: docs/factory/act-handoff-map.tsv (self-row,
       EXPLICITLY authorized at this C0)
- C4: docs/factory/HANDOFF-...-CORRECTION04.md (HANDOFF)
- No other mutations.

## Out of scope (per F7/F15)

- tools/quality/factory-closure-status-test.HC
- scripts/quality/factory-closure-status-check.sh
- docs/factory/SHELL-BUDGET.tsv
- docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01.md
- docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION02.md
- docs/acts/ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION03.md
- All closed HANDOFFs (F14 immutability)
- The 4 closed CORRECTION01 evidence files (F14 restoration
  stands; no further mutation)
- Any pending Factory roadmap ACT (must wait for genuine closure)

## Success criteria

1. CORRECTION03's HANDOFF verdict is recorded as FALSE_GREEN in
   additive evidence at c0/.
2. The C0 AUTH commit does NOT modify docs/factory/act-handoff-
   map.tsv (the mutation happens at C4).
3. C3 VERIFY reruns the 12-pair closure oracle and confirms the
   self-pair transition: C3 state has CORRECTION04 listed in the
   manifest (added at C4) but missing its HANDOFF file (PAIR_FAIL
   expected for self-pair); C4 state has HANDOFF file present
   (PAIR_OK expected).
4. C3 VERIFY reruns the 12-case PolyC regression and confirms
   12/12 PASS.
5. C3 VERIFY confirms `git diff b9a43f8..HEAD -- evidence/.../
   CORRECTION01/` is empty (F14 restoration preserved).
6. C3 VERIFY records (does NOT fix) that `git diff --check
   0665ada..HEAD` is FALSE; C4 records that the patch hygiene
   is a known open defect pending CORRECTION05.
7. C3->C4 transition is HANDOFF + manifest-self-row ONLY. No
   post-C4 cleanup commits. Lifecycle smell from CORRECTION03 is
   not repeated.
8. Entry identity at C0: HEAD = 8fbf51d (clean worktree).

## HALT_CONDITIONS

This ACT halts at C0 if:
- Entry identity is not clean (worktree dirty or HEAD != 8fbf51d).
- Any of the c0/ evidence files cannot be produced from current
  tree state without violating F14 or F15.

This ACT halts at C1 if:
- The two reviewer-disposition citations cannot be reproduced
  against current tree.

This ACT halts at C3 if:
- 12/12 PolyC regression fails.
- 12-pair closure oracle's STATE TRANSITION math (C3 PAIR_FAIL=1,
  C4 PAIR_OK) does not hold.

## Residue / next ACT

The two binding P0s documented here require a CORRECTION05 ACT
(or later) whose scope explicitly:

  (a) selects a patch-hygiene baseline and either:
      - documents that baseline as the successor's authoritative
        one, or
      - performs a forward-only hygiene normalization that does
        NOT touch closed evidence but does add a
        forward-clean-commit that supersedes the b9a43f8 EOF
        blanks;
  (b) acknowledges the manifest self-row pattern as established
      factory practice and either ratifies it via checker change
      or explicitly removes it.

CORRECTION05 cannot be opened from this ACT. It requires its own
C0 AUTH at a future session, with a worktree that has been
verified clean and a deliberately chosen baseline.

Unblocked roadmap ACTs (ACT-POLYC-LIBTOS-SYMBOL-GAPS01,
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02,
ACT-POLYC-SELFHOST-SURFACE-RECON03) remain blocked until a
genuine PASS_TRUE_GREEN is recorded for the closure-oracle
lineage.

End of ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION04.
