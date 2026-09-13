C2 IMPL pack for ACT-POLYC-BOOTSTRAP01-CORRECTION01
====================================================

Files:

  - implementation-delta.txt      what changed and why
  - cardinality-exception.txt     the EXCEPTION 4 record
  - section-reorder-record.txt    ACT §-order repair (above)
  - corrected-authoring-copy.txt  pointer to the corrected
                                  ACT document
  - eof-strip-delta.txt           byte-level evidence of
                                  the EOF blank-line strip
  - c2-required-result.txt        the required-result block

The C2 commits are:

  4a78bdf  C1 RED: open ACT-POLYC-BOOTSTRAP01-CORRECTION01
  fcc2150  C2 IMPL: strip 3 EOF blank lines (DEFECT-2)

(this file is written by C2 and is not yet committed;
it will be staged with the C3 evidence commit)

Mechanical pre-conditions met at the end of C2:

  - tools/ EOF blank lines: 3 stripped
  - historical-cardinality-exceptions.txt: EXCEPTION 4
    appended
  - section-reorder-record.txt: written
  - corrected authoring copy: written

Residue (still open at end of C2):

  - DEFECT-3 captured-evidence trailing whitespace at
    evidence/ACT-POLYC-BOOTSTRAP01/c3/fresh-build.txt:144
    is recorded as GOVERNANCE_RESIDUE; not blocking.
