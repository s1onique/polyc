# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
# ACT_PHASE=Q1-EVIDENCE
# EVIDENCE_KIND=original-receipt-chronology-contract
#
# THE CHRONOLOGY RULES, FROZEN BEFORE THE RECEIPT IS EXAMINED.
#
# A tracked file that asserts a terminal outcome CANNOT be a
# post-CLOSE observation when that same file is already present in
# the CLOSE tree. Its presence in the CLOSE tree PROVES it
# predates the CLOSE. Such a file is a PROSPECTIVE RESULT that was
# committed BEFORE the observation it describes.
#
# The chronology is reconstructed from COMMIT ANCESTRY and EXACT
# TREE MEMBERSHIP, not from wall-clock timestamps: a file is
# "in the CLOSE tree" iff git ls-tree of the CLOSE commit names it.
#
# THE FOUR DISTINCT QUESTIONS, WHICH MUST NOT BE MERGED
#
key	domain	values
HISTORICAL_TRACKED_OUTCOME_PROVENANCE	the provenance of the tracked terminality-outcome.tsv	PRECOMMITTED_PROSPECTIVE_RESULT | NONE
ORIGINAL_EXTERNAL_RECEIPT	the claimed original external receipt	VERIFIED | CONTRADICTED | UNAVAILABLE
FRESH_EXTERNAL_REPLAY	the new read-only probe this ACT runs after its own CLOSE	PASS | FAIL | NOT_RUN
HISTORICAL_ACT_TERMINALITY_CONFIRMED	whether the HISTORICAL post-CLOSE execution is proven	YES | NO | UNPROVEN
#
# A FRESH REPLAY that PASSES does NOT make the HISTORICAL
# execution proven. The fresh replay binds to the CURRENT state
# with a NEW execution id. The filename of a receipt is NOT evidence
# of its generation time, and a filename matching a claimed stamp
# does not establish that the file was written at that time.
#
# THE MEASURED CHRONOLOGY OF THE WP-001 FAMILY
#
item	commit	tree_membership	verdict
PARENT_CLOSE_1	c57a4e8ba0882594eea3e6a9fcb7188ceb0bd169	contains ONLY terminality-plan.txt	the plan is present; NO outcome file
PARENT_CLOSE_2	2b061fe31e2be90c760aa54e1124c3ef42ee0d45	contains terminality-plan.txt AND terminality-outcome.tsv	THE OUTCOME FILE IS PRECOMMITTED IN THE CLOSE TREE
CORRECTION04_CLOSE	e3f8382d94c4c6fcc0370b4126d0e759145614fe	contains NO terminality-outcome.tsv	CORRECTION04 did NOT precommit an outcome
POST_CLOSE_COMMIT	299bf83731a54cdfa738cbff7ae9cbd02755b1d9	ADDS CORRECTION04/c4/terminality-outcome.tsv	the CORRECTION04 outcome file was added AFTER the CLOSE, by the post-CLOSE ordinary commit
