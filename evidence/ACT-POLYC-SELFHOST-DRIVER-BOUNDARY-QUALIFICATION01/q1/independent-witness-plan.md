# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
# ACT_PHASE=Q1-EVIDENCE
# EVIDENCE_KIND=independent-witness-plan
#
# THE INDEPENDENT CROSS-CHECK PLAN, FROZEN BEFORE Q2.
#
# The Q2 compiled PolyC verifier MUST be cross-checked by an
# implementation that shares NO MATERIAL DETECTION ALGORITHM.
# The differences are enforced, not merely intended:
#
concern	compiled_polyc_verifier	independent_posix_git_witness
the 32-row join	a PolyC row-indexed hash-set join over the loaded rows	an awk exact-string membership test over the two ID files
the roster cardinality	a PolyC counter over the loaded row array	an awk line count over the same file
the authority count	a PolyC count of rows with importing_c_objs >= 1	an awk count over the same column with a different comparison form
the action-selection symbol set	four separate substring tests in the PolyC source	ONE awk regular expression over the symbol column
the ACT family count	a PolyC count of loaded inventory rows	an awk count over the act_id column
the chronology	a PolyC substring search for the tracked outcome in the tree list	an awk field test over the same tree list
the receipt provenance	a PolyC line count of terminal assertions	an awk three-pattern count over the same file
#
# The two implementations MUST agree on every identity,
# every category and every exception. A disagreement is a
# measurement failure and is reported as such, not averaged away.
