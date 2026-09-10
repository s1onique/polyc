# ACT-POLYC-LLVM-BYTE-MEMORY01-RESUME01-CORRECTION01

## Scope

Hygiene-only correction of the C1 RED evidence captured at
commit 0bfa990. The substantive compiler diagnosis is accepted;
this ACT addresses only the P0 mechanical contradiction between
the RED report's claim `git diff --check clean` and the actual
range digest, which reported 8 distinct whitespace diagnostics
(13 lines including context) across six files in
`evidence/llvm-byte-memory01-resume01/c1/`.

## Allowed changes

```text
evidence/llvm-byte-memory01-resume01/c1/*.md  -- strip trailing blank line(s) at EOF
evidence/llvm-byte-memory01-resume01/c1/*.txt -- strip trailing blank line(s) at EOF
evidence/llvm-byte-memory01-resume01/c1/*.ir  -- strip trailing whitespace on every line
                                                plus strip trailing blank line(s) at EOF
```

No `src/` change. No `scripts/` change. No `docs/` semantic
change. No `docs/ROADMAP.md` change. No `AGENTS.md` change.

## Forbidden changes

- any change to the substantive evidence text (compiler
  diagnosis, repair survey, CFG analysis);
- any addition or removal of an evidence file;
- any change to the RED-SUMMARY.md wording about the
  substantive findings.

## Diagnostics being corrected

From `git diff --check db6404e1a36a..0bfa990`:

```text
evidence/.../RED-SUMMARY.md:162       new blank line at EOF
evidence/.../cfg-before.txt:57        new blank line at EOF
evidence/.../collapse-recon.md:231    new blank line at EOF
evidence/.../entry.txt:20             trailing whitespace (4 spaces)
evidence/.../i64-probe.ir:30          trailing whitespace (space after heading)
evidence/.../i64-probe.ir:49          new blank line at EOF
evidence/.../pos-b0-before.ir:35      trailing whitespace (space after heading)
evidence/.../pos-b0-before.ir:96      trailing whitespace (space after heading)
evidence/.../pos-b0-before.ir:122     new blank line at EOF
```

## Pre-conditions for closure

1. `git diff --check db6404e1a36a..HEAD` returns no diagnostics.
2. `git diff --check` (working tree) returns no diagnostics.
3. `factory-v2-commit-msg-check` passes on the CORRECTION01 CLOSE
   commit trailer.
4. `gate-fast` passes.
5. `byte-memory01-test` still passes (no src/ change means this
   is automatic).
6. RESUME01 itself remains OPEN at RED phase (no verdict
   changed; no commit count claimed by RESUME01 altered).

## Rationale (F14)

The RED diagnosis is intact and accepted. F14 forbids
rewriting history; the substantive evidence is preserved in
0bfa990 unchanged. The CORRECTION01 commit is a forward-only
hygiene fix that satisfies the mechanical-evidence gate.

## Scope-conservation statement (F7)

Every changed line in the CORRECTION01 commit removes either
trailing whitespace or trailing blank lines at EOF. None of
those lines carries semantic content. F7 is satisfied because
the only changed lines are diagnostic-flagged lines whose
original content is preserved up to the removed whitespace.

## Phase boundary

This is a one-commit bounded ACT: a single CLOSE commit with
the hygiene fix. There is no RED phase because the original
RED diagnosis is preserved; the defect being corrected is the
RED report's hygiene claim, not the RED diagnosis.

