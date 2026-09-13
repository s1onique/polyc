C1 RED — open this ACT.

The principal RED is the existence (and last-modification trace) of
the legacy exceptions file:

  $ git log --oneline --follow -- \
      evidence/ACT-POLYC-FACTORY-NO-SHA-OF-SELF01/correction04/historical-cardinality-exceptions.txt

Expected output (one line minimum):
  9e6f6ab C2 IMPL: cardinality exception + corrected authoring copy + c2 evidence

This RED proves:
  - the legacy file was mutated by the BOOTSTRAP correction's C2 IMPL,
  - the mutation violated strict F14 (per DOCTRINE.md §24
    "appending ADDENDUM blocks to existing files is forbidden"),
  - therefore the file content currently reflects EXCEPTIONs 1..5,
    where EXCEPTIONs 4..5 were added by an ACT that had no authority
    over that evidence tree.

The required IMPL is therefore:
  - migrate EXCEPTIONs 1..5 to a canonical registry outside the
    evidence tree,
  - bit-identically restore the legacy file to its `4a78bdf^` state
    via a forward commit (no amend, no rebase).

A synthetic mock (e.g. "I assert the file was modified") is not an
acceptable RED; the mechanical `git log --follow` is.
