Mandatory-AC TSV verdict vocabulary (declared explicitly)
==========================================================

ACT: ACT-POLYC-SELFHOST-LEXER03-CORRECTION01-CORRECTION01

This file declares the verdict vocabulary for the
`mandatory-ac-status-*.tsv` evidence files. It is the explicit
contract that the original
`mandatory-ac-status-correction01.tsv` violated by putting the
token `CORRECTION01` in the verdict column for 6 rows.

## Allowed verdict tokens (closed set)

The `verdict` column of any `mandatory-ac-status-*.tsv`
MUST contain exactly one of:

  PASS
    The acceptance criterion is satisfied. The evidence_file
    column contains the file that demonstrates the satisfaction.

  FAIL
    The acceptance criterion is NOT satisfied. The evidence_file
    column contains the file that demonstrates the failure (or
    is empty if the failure is structural rather than evidence-
    documented).

  N/A
    The acceptance criterion is not applicable to this ACT.
    The evidence_file column is empty. The notes column MUST
    explain why the AC is N/A.

  DEFERRED
    The acceptance criterion is real but its resolution is
    deferred to a successor ACT. The notes column MUST name
    the successor ACT.

## Forbidden verdict tokens

Any token NOT in the closed set above is forbidden. In
particular:

  CORRECTION01
    FORBIDDEN. This token was used in the original
    mandatory-ac-status-correction01.tsv as an implicit
    "this AC was repaired by CORRECTION01" marker. The verdict
    column does not encode repair-status; it encodes verdicts.
    If a repair has been performed and is green, the verdict
    is PASS, and the notes column documents the repair.

  Any ACT-id (e.g. LEXER03-CORRECTION01, FACTORY-AGENT-GATES01)
    FORBIDDEN for the same reason: ACT-ids are not verdicts.

## Why this declaration matters

F13 (evidence over persuasive prose): the verdict column must
be readable by a downstream auditor without consulting the
notes column. If the verdict is `CORRECTION01`, an auditor
cannot tell whether the AC is green, red, N/A, or pending.

F5 (no test weakening): a closed-set vocabulary is strictly
more strict than an open-ended vocabulary. Future TSVs that
need to encode a "repair-source" marker must add a dedicated
column for that purpose, not extend the verdict column.

## Application to CORRECTION01's original TSV

The 6 rows with verdict=CORRECTION01 in
`mandatory-ac-status-correction01.tsv` are mechanically
non-PASS. Their underlying notes assert that the work is
green, so the corrected verdict is PASS. The corrected TSV
is at
`evidence/ACT-POLYC-SELFHOST-LEXER03/CORRECTION01-CORRECTION01/c3/mandatory-ac-status-correction01-correction01.tsv`.
