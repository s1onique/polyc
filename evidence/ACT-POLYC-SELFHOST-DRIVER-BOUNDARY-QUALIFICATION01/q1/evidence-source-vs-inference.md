# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
# ACT_PHASE=Q1-EVIDENCE
# EVIDENCE_KIND=evidence-source-vs-inference
#
# WHAT IS MEASURED AND WHAT IS INFERRED. A claim belongs to
# exactly one of these two columns, and a claim that belongs to
# neither is not made.
#
claim	column	basis
the entry HEAD, TREE, branch and replace-ref state are exact	MEASURED	git rev-parse, git branch, git replace -l
the five family ACT ranges are as recomputed	MEASURED	git rev-list plus the canonical range validator
the parent carries two terminal CLOSEs	MEASURED	git log over the first-parent ancestry
the CORRECTION04 CLOSE is e3f8382d and no descendant carries its ACT id	MEASURED	git rev-list plus git show --format=%B
the 32 historical IDs join with 0 missing, 0 duplicate, 0 extra	MEASURED	an exact set join against the committed C0 census
the historical class counts are 13/16/3	MEASURED	a count over the committed census body
the C-OFF oracle has 0 driver symbols and 0 driver relocations	MEASURED	nm over the G0 binary and cli.c.o
the C-ON production cli.c.o has exactly 8 driver relocations	MEASURED	nm -u over the production cli.c.o
four driver action-selection symbols have 0 importing C objects	MEASURED	a per-symbol count over every production C object
the live per-function call graph of cli.c.o and main.c.o	MEASURED	objdump -r, per-section relocation counts
the mutated emitFile arm changes the produced artifact	MEASURED	a compiled, linked and executed mutant compiler
the mutated main() arm removes the token stream	MEASURED	a compiled, linked and executed mutant compiler
the PolyC field mutation drives the C consumer	MEASURED	a compiled, linked and executed PolyC mutant
the 21-case corpus agrees between the two generations	MEASURED	an executed comparison of exit code and artifact
the external receipt binds to the CORRECTION04 CLOSE and tree	MEASURED	the receipt bytes compared against git rev-parse
the historical post-CLOSE EXECUTION TIME is proven	INFERRED	NOT ESTABLISHED; the receipt asserts a PROBE_TIME and carries an mtime, but the commit topology is the only ordering authority
the parent's terminality-outcome.tsv was a PROSPECTIVE RESULT	MEASURED	its presence in the parent CLOSE tree
the CORRECTION04 terminality-outcome.tsv was a POST-CLOSE observation	MEASURED	the commit that introduced it is the post-CLOSE ordinary commit
that the eight relocations prove the absence of a C decision	INFERRED	REJECTED; a relocation is a link reference, not a decision
that main() and emitFile() contain no live C decision	INFERRED	REJECTED; two linked counterfactuals show the opposite
that 32 review rows equal 32 migrated authorities	INFERRED	REJECTED; the live object graph holds 16 authority subjects
