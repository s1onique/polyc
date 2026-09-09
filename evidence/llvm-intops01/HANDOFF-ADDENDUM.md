# HANDOFF-ADDENDUM -- ACT-POLYC-LLVM-INTOPS01

## Procedural note (process residue)

This addendum is an **append-only** addition to the INTOPS01 CLOSE
commit `baf5dbd77cf89330699685dffd932c54031c815c`. It is recorded
as a brand-new commit; `baf5dbd` itself is **not amended**.

### Process contradiction acknowledged

Earlier in this run I produced the INTOPS01 CLOSE object, then
performed two further `git commit --amend` operations to fold in
corrected analysis (the I64-vs-byte wording tightening, the
dropped `.bc` file, and the cherry-equivalence analysis). That
procedure is **incompatible** with the append-only doctrine the
project has since adopted:

> **Once a commit exists, never amend/rewrite it.**

The CLOSE object that survives today (`baf5dbd`) is the
**final stable form** of the INTOPS01 HALT evidence. It carries
the same `ACT: ACT-POLYC-LLVM-INTOPS01`, `ACT-Phase: CLOSE`,
`ACT-Verdict: HALT_RED_NOT_REPRODUCED` trailers as the original
HALT.

### Last grandfathered rewrite

Per reviewer direction:

```text
APPEND_ONLY_START_POINT = baf5dbd77cf89330699685dffd932c54031c815c
```

No commit at or after this point may ever be amended, rebased,
filtered, replaced, squashed, or otherwise rewritten. `baf5dbd`
is the **last** commit whose formation involved rewrites of an
earlier commit object.

### Doctrine (verbatim from reviewer)

```text
A bad commit is evidence.
A correction is another commit.
History grows; history does not change.
```

`git replace` is especially incompatible with this model: Git
substitutes replacement objects for most commands, while
`--no-replace-objects` observes the underlying originals, so two
observers can see different effective history.

### What this addendum does

1. Records `APPEND_ONLY_START_POINT` for future ACTs.
2. Names the append-only doctrine so that subsequent ACTs can
   cite it.
3. Closes the INTOPS01 process loop without further rewrites.

### What this addendum does NOT do

1. Does not amend `baf5dbd`.
2. Does not redesign Factory tooling.
3. Does not change INTOPS01's semantic verdict.
4. Does not authorize any push to `origin/main`.

### Recommended next ACT

`ACT-POLYC-FACTORY-HISTORY-RECONCILE01` -- append-only merge of
`archive/local-main-before-reconcile` (`adb202c`) and
`archive/origin-main-before-reconcile` (`429b804`), starting from
`baf5dbd` (= `APPEND_ONLY_START_POINT`). This ACT is the
**immediate blocker** before any further compiler work (next:
`ACT-POLYC-LLVM-BYTE-MEMORY01`).

After that ACT lands, ordinary fast-forward push of the new merge
tip to `origin/main`.
