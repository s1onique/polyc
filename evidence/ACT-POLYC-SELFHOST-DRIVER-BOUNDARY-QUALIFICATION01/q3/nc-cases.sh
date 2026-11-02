# ---------------------------------------------------------------------------
# THE TWENTY-FOUR NEGATIVE-CONTROL CASES
#
# Sourced by run-nc-matrix.sh. Each case names the detector, the
# expected reason token, and the PRISTINE and ADVERSE inputs.
#
# The ADVERSE input for each control is BUILT HERE, on a disposable
# copy, by mutating the specific fact that the control is about. The
# construction is therefore AUDITABLE: a reader can see exactly which
# fact was corrupted.
#
# Where the Q2 verifier already covers a control with an anti-
# selftest, the SAME corruption is used, so the control and the
# anti-selftest are not two different stories about one fact.
# ---------------------------------------------------------------------------

# mk <output> <input> <sed-style mutation helper>
#
# The helper `mutate` is defined here: it rewrites ONE cell of ONE
# row of a TSV, addressed by the row's first field and the column
# index, using awk field matching. It never addresses a row by line
# number, so the comment header cannot shift a target.
mutate() {
  # mutate <file> <id> <col> <newvalue>
  awk -F'\t' -v OFS='\t' -v id="$2" -v col="$3" -v val="$4" '
    $1 == id { $col = val }
    { print }
  ' "$1" > "$1.m"
  mv "$1.m" "$1"
}

# --- THE ADVERSE INPUT CONSTRUCTIONS ---------------------------------------

# NC01: a FORGED entry HEAD.
cp "$I/entry-identity.tsv" "$TMP/nc01.tsv"
mutate "$TMP/nc01.tsv" ENTRY_HEAD 3 "0000000000000000000000000000000000000000"

# NC02: the CORRECTION04 CLOSE identified as the WRONG commit.
cp "$I/chronology.tsv" "$TMP/nc02.tsv"
mutate "$TMP/nc02.tsv" CORRECTION04_TERMINAL_CLOSE 2 "0000000000000000000000000000000000000000"

# NC03: a parent commit with NO trailer promoted to a valid ACT trailer.
cp "$I/links.tsv" "$TMP/nc03.tsv"
mutate "$TMP/nc03.tsv" TRAILER_MODE 2 "MODE=ACT"

# NC04: the DUPLICATE parent CLOSE hidden.
cp "$I/chronology.tsv" "$TMP/nc04.tsv"
mutate "$TMP/nc04.tsv" HISTORICAL_DUPLICATE_CLOSES 2 "0"

# NC05: the PRE-COMMITTED terminality outcome called a later receipt.
cp "$I/chronology.tsv" "$TMP/nc05.tsv"
mutate "$TMP/nc05.tsv" HISTORICAL_TRACKED_OUTCOME_PROVENANCE 2 "VERIFIED_LATER_RECEIPT"

# NC06: the ORIGINAL external receipt claimed to exist without proof.
cp "$I/chronology.tsv" "$TMP/nc06.tsv"
mutate "$TMP/nc06.tsv" ORIGINAL_EXTERNAL_RECEIPT 3 "NO"

# NC07: a REPLAY claimed as the original historical receipt.
cp "$I/chronology.tsv" "$TMP/nc07.tsv"
mutate "$TMP/nc07.tsv" FRESH_EXTERNAL_REPLAY 2 "VERIFIED"

# NC08: a POST-CLOSE ACT-id commit omitted from the scan.
cp "$I/chronology.tsv" "$TMP/nc08.tsv"
mutate "$TMP/nc08.tsv" POST_CLOSE_ACT_ID_COMMITS 2 "7"

# NC09: a MISSING original 32-row ID.
cp "$I/historical-roster.tsv" "$TMP/nc09.tsv"
mutate "$TMP/nc09.tsv" A-C-DRIVER-cli-cliPanic-SL 1 "A-C-DRIVER-cli-cliPanic-XX"

# NC10: a DUPLICATE original 32-row ID.
cp "$I/current-classification.tsv" "$TMP/nc10.tsv"
awk -F'\t' -v OFS='\t' '
  $1 == "A-C-DRIVER-cli-cliPanic-SL" { print; print; next }
  { print }
' "$TMP/nc10.tsv" > "$TMP/nc10.tsv.m" && mv "$TMP/nc10.tsv.m" "$TMP/nc10.tsv"

# NC11: an ORIGINAL semantic row silently relabelled mechanical.
cp "$I/current-classification.tsv" "$TMP/nc11.tsv"
mutate "$TMP/nc11.tsv" A-C-DRIVER-cli-cliPanic-SL 4 "C_MECHANICAL"

# NC12: the main() semantic branch assumed DORMANT from no relocation.
cp "$I/current-classification.tsv" "$TMP/nc12.tsv"
mutate "$TMP/nc12.tsv" A-C-DRIVER-main-main-SW1 12 "PENDING"

# NC13: the emitFile() policy inferred MECHANICAL without a test.
cp "$I/current-classification.tsv" "$TMP/nc13.tsv"
mutate "$TMP/nc13.tsv" A-C-DRIVER-main-emitFile-FC 12 "PENDING"

# NC14: a PolyC-influenced C branch called AUTOMATICALLY PolyC-owned.
cp "$I/current-classification.tsv" "$TMP/nc14.tsv"
mutate "$TMP/nc14.tsv" A-C-DRIVER-cli-cliGetFileType-FC 7 "PENDING"

# NC15: an UNREACHABLE C branch asserted without call/object proof.
cp "$I/current-classification.tsv" "$TMP/nc15.tsv"
mutate "$TMP/nc15.tsv" A-C-DRIVER-cli-cliParseNop-SL 8 "5"

# NC16: a CHANGED mutant source never LINKED into the experimental binary.
cp "$I/links.tsv" "$TMP/nc16.tsv"
mutate "$TMP/nc16.tsv" MUTANT_LINKED 2 "0"

# NC17: the C-OFF oracle IMPORTING the WP-001 subject.
cp "$I/links.tsv" "$TMP/nc17.tsv"
mutate "$TMP/nc17.tsv" G0_DRIVER_IMPORTS 2 "8"

# NC18: a COMPARATOR that IGNORES a changed stderr, exit or output object.
cp "$I/links.tsv" "$TMP/nc18.tsv"
mutate "$TMP/nc18.tsv" COMPARATOR_FIELDS 2 "1"

# NC19: the off-route C policy OMITTED from the global remainder.
cp "$I/expect-ownership.tsv" "$TMP/nc19.tsv"
mutate "$TMP/nc19.tsv" WP001_GLOBAL_C_SEMANTIC_REMAINDER 2 "0"

# NC20: the 32 ROWS counted as 32 migrated authorities.
cp "$I/expect-authority.tsv" "$TMP/nc20.tsv"
mutate "$TMP/nc20.tsv" FINAL_AUTHORITIES 2 "32"

# NC21: the FULL WP-001 family counted as only 2 ACTs.
cp "$I/expect-family.tsv" "$TMP/nc21.tsv"
mutate "$TMP/nc21.tsv" WP001_ALL_ACTS_CONSUMED 2 "2"

# NC22: the HYBRID WP-001 compiler called M2.
cp "$I/expect-m2class.tsv" "$TMP/nc22.tsv"
mutate "$TMP/nc22.tsv" M2_ACHIEVED 2 "YES"

# NC23: a NON-GREEN historical baseline relabelled PASS.
cp "$I/milestone-claims.tsv" "$TMP/nc23.tsv"
mutate "$TMP/nc23.tsv" CROSS_TARGET_PREFIX 2 "PASS"

# NC24: a FORGED AC set, a self-claimed receipt or an early CLOSE.
#
# The ledger OMITS a frozen AC id. The ledger is the ledger input of
# the ACCEPT mode, so the omission is what the mode must catch.
cp "$HERE/acceptance-ledger.tsv" "$TMP/nc24.tsv"
awk -F'\t' -v OFS='\t' '!/^#/ && NF>0 && $1 == "AC02" { next } { print }' "$TMP/nc24.tsv" > "$TMP/nc24.tsv.m" && mv "$TMP/nc24.tsv.m" "$TMP/nc24.tsv"

# --- THE TWENTY-FOUR INVOCATIONS -------------------------------------------
#
# Each invocation names the detector, the expected reason token, the
# pristine input, the adverse input and, where the mode takes two
# files, the second (expectations) file.

# NC01 -- the entry HEAD is forged.
nc_verify NC01 ENTRY_IDENTITY_FORGED IDENTITY \
  "$I/entry-identity.tsv" "$TMP/nc01.tsv" "$I/expect-identity.tsv"

# NC02 -- the CORRECTION04 CLOSE is identified wrongly.
nc_verify NC02 CORRECTION_CLOSE_IDENTITY_WRONG CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc02.tsv" "$I/expect-chronology.tsv"

# NC03 -- a parent commit with NO trailer is promoted to a valid one.
nc_verify NC03 NON_ACT_TRAILER_PROMOTED LINKS \
  "$I/links.tsv" "$TMP/nc03.tsv" "$I/expect-links.tsv"

# NC04 -- the duplicate parent CLOSE is hidden.
nc_verify NC04 HISTORICAL_CLOSE_DUPLICATE_HIDDEN CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc04.tsv" "$I/expect-chronology.tsv"

# NC05 -- the pre-committed outcome is called a later receipt.
nc_verify NC05 PRECOMMITTED_RESULT_LAUNDERED CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc05.tsv" "$I/expect-chronology.tsv"

# NC06 -- the original receipt is claimed without proof.
nc_verify NC06 RECEIPT_EXISTENCE_NOT_PROVEN CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc06.tsv" "$I/expect-chronology.tsv"

# NC07 -- a replay is claimed as the original receipt.
nc_verify NC07 REPLAY_PROVENANCE_CONFLATED CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc07.tsv" "$I/expect-chronology.tsv"

# NC08 -- a post-CLOSE ACT-id commit is omitted from the scan.
nc_verify NC08 POST_CLOSE_ID_CARRIER_OMITTED CHRONOLOGY \
  "$I/chronology.tsv" "$TMP/nc08.tsv" "$I/expect-chronology.tsv"

# NC09 -- a 32-row ID is missing.
nc_verify NC09 DRIVER_ROSTER_ID_MISSING ROSTER \
  "$I/current-classification.tsv" "$TMP/nc09.tsv" "$I/historical-roster.tsv"

# NC10 -- a 32-row ID is duplicated.
nc_verify NC10 DRIVER_ROSTER_ID_DUPLICATE ROSTER \
  "$I/current-classification.tsv" "$TMP/nc10.tsv" "$I/historical-roster.tsv"

# NC11 -- an original semantic row is relabelled mechanical.
nc_verify NC11 HISTORICAL_CLASS_REWRITTEN HISTCLASS \
  "$I/current-classification.tsv" "$TMP/nc11.tsv" "$I/historical-roster.tsv"

# NC12 -- the main() branch is assumed dormant.
nc_verify NC12 ENTRY_BRANCH_CAUSAL_UNPROVEN OWNERSHIP \
  "$I/current-classification.tsv" "$TMP/nc12.tsv" "$I/expect-ownership.tsv"

# NC13 -- the emitFile() policy is inferred mechanical.
nc_verify NC13 EMITFILE_POLICY_UNPROVEN OWNERSHIP \
  "$I/current-classification.tsv" "$TMP/nc13.tsv" "$I/expect-ownership.tsv"

# NC14 -- a PolyC-influenced C branch is called PolyC-owned.
nc_verify NC14 DECISION_OWNER_NOT_TRACED OWNERSHIP \
  "$I/current-classification.tsv" "$TMP/nc14.tsv" "$I/expect-ownership.tsv"

# NC15 -- unreachability is asserted without proof.
nc_verify NC15 UNREACHABILITY_NOT_PROVEN OWNERSHIP \
  "$I/current-classification.tsv" "$TMP/nc15.tsv" "$I/expect-ownership.tsv"

# NC16 -- the changed mutant source was never linked.
nc_verify NC16 MUTATION_LINK_PROVENANCE_MISSING LINKS \
  "$I/links.tsv" "$TMP/nc16.tsv" "$I/expect-links.tsv"

# NC17 -- the C-OFF oracle imports the WP-001 subject.
nc_verify NC17 G0_DRIVER_CONTAMINATED LINKS \
  "$I/links.tsv" "$TMP/nc17.tsv" "$I/expect-links.tsv"

# NC18 -- the comparator ignores the changed output.
nc_verify NC18 COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE LINKS \
  "$I/links.tsv" "$TMP/nc18.tsv" "$I/expect-links.tsv"

# NC19 -- the off-route policy is omitted from the global remainder.
nc_verify NC19 GLOBAL_DRIVER_REMAINDER_UNDERCOUNTED SCOPE \
  "$I/current-classification.tsv" "$TMP/nc19.tsv" "$I/expect-ownership.tsv"

# NC20 -- the 32 rows are counted as 32 authorities.
nc_verify NC20 AUTHORITY_UNIT_MISMATCH AUTHORITY \
  "$I/production-authorities.tsv" "$TMP/nc20.tsv" "$I/expect-authority.tsv"

# NC21 -- the family is counted as only 2 ACTs.
nc_verify NC21 ACT_FAMILY_COST_UNDERCOUNTED FAMILY \
  "$I/act-family-inventory.tsv" "$TMP/nc21.tsv" "$I/expect-family.tsv"

# NC22 -- the hybrid compiler is called M2.
nc_verify NC22 M2_BOOTSTRAP_MISCLASSIFIED M2CLASS \
  "$I/milestone-claims.tsv" "$TMP/nc22.tsv" "$I/expect-m2class.tsv"

# NC23 -- a non-green baseline is relabelled PASS.
nc_verify NC23 KNOWN_BASELINE_FALSE_GREEN M2CLASS \
  "$I/milestone-claims.tsv" "$TMP/nc23.tsv" "$I/expect-m2class.tsv"

# NC24 -- a forged AC set, a self-claimed receipt or an early CLOSE.
nc_verify NC24 FACTORY_ACCEPTANCE_OR_TERMINALITY_FORGED ACCEPT \
  "$HERE/acceptance-ledger.tsv" "$TMP/nc24.tsv" "$I/frozen-ac.tsv"
