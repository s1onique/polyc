#!/bin/sh
# BUILD THE ADVERSE INPUT MUTATIONS FOR THE 18 CORRECTION CONTROLS.
#
# Each mutation is a DETERMINISTIC edit of ONE pristine input file,
# applied to a DISPOSABLE COPY. The pristine input is never written to.
#
# EACH CONTROL MUTATES THE SIDE THAT PRODUCES ITS OWN REASON TOKEN.
# The two sides of a comparison are DIFFERENT defects: a substituted
# predicate on the LEDGER side is a drift, and a rewritten predicate on
# the FROZEN side is a contract rewrite.
set -u
REPO=/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
I=$D/c2/inputs
M=$D/c2/negative-control-inputs
cd "$REPO" || exit 1
rm -rf "$M"; mkdir -p "$M"

# NC-C01: AC14 phase altered in the FROZEN table.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC14\t/{ $2="C1" } {print}' "$I/frozen-phase-and-predicate.tsv" > "$M/nc-c01-frozen-phase-and-predicate.tsv"

# NC-C02: AC14 predicate SUBSTITUTED on the LEDGER side.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC14\t/{ $4="Every decision-bearing main() branch in scope is trivially classified" } {print}' "$I/correction-acceptance-ledger.tsv" > "$M/nc-c02-correction-acceptance-ledger.tsv"

# NC-C18: the ORIGINAL acceptance predicate REWRITTEN on the FROZEN side.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC14\t/{ $3="Every decision-bearing main() branch in scope classified, vacuously" } {print}' "$I/frozen-phase-and-predicate.tsv" > "$M/nc-c18-frozen-phase-and-predicate.tsv"

# NC-C03: a PROVEN_AS_FROZEN criterion whose CITED witness does not
# carry the frozen subject.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC29\t/{ $6="NO" } {print}' "$I/witness-existence.tsv" > "$M/nc-c03-witness-existence.tsv"

# NC-C04: a duplicate AC identifier.
{ cat "$I/correction-acceptance-ledger.tsv"; awk -F'\t' 'BEGIN{OFS="\t"} /^AC01\t/{print}' "$I/correction-acceptance-ledger.tsv"; } > "$M/nc-c04-correction-acceptance-ledger.tsv"

# NC-C05: a missing AC identifier (AC14 removed).
awk -F'\t' 'BEGIN{OFS="\t"} /^AC14\t/{next} {print}' "$I/correction-acceptance-ledger.tsv" > "$M/nc-c05-correction-acceptance-ledger.tsv"

# NC-C06: a METADATA row is counted as a criterion.
{ cat "$I/correction-acceptance-ledger.tsv"; printf 'AC_ROSTER_SIZE\tC0\tPASS\tthe correction acceptance roster has thirty-two criteria\t-\tC0\t-\tMETADATA\tcompiled-polyc-correction-verifier\tMETADATA\n'; } > "$M/nc-c06-correction-acceptance-ledger.tsv"

# NC-C07: the status totals are forged.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC17\t/{ $3="FAIL" } {print}' "$I/correction-acceptance-ledger.tsv" > "$M/nc-c07-correction-acceptance-ledger.tsv"

# NC-C08: a cited witness path is missing from the close tree, for a
# criterion proven AS FROZEN, whose cited witness IS the binding.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC29\t/{ $4="NO" } {print}' "$I/witness-existence.tsv" > "$M/nc-c08-witness-existence.tsv"

# NC-C09: a witness is taken from the WRONG phase, for a criterion
# proven AS FROZEN, whose cited witness IS the binding.
awk -F'\t' 'BEGIN{OFS="\t"} /^AC29\t/{ $5="NO" } {print}' "$I/witness-existence.tsv" > "$M/nc-c09-witness-existence.tsv"

# NC-C10: a TOKEN-ROUTE witness is counted as required-route proof.
awk -F'\t' 'BEGIN{OFS="\t"} /^BR_MAIN_PRINT_TOKENS\t/{ $9="PROVEN_REACHABLE" } {print}' "$I/branch-inventory.tsv" > "$M/nc-c10-branch-inventory.tsv"

# NC-C11: FUNCTION reachability substituted for BRANCH reachability: the
# branch is claimed reachable but carries no branch-level proof.
awk -F'\t' 'BEGIN{OFS="\t"} /^BR_MAIN_PRINT_TOKENS\t/{ $9="PROVEN_REACHABLE"; $13="NONE"; $14="FUNCTION_LEVEL_TRACE_ONLY" } {print}' "$I/branch-inventory.tsv" > "$M/nc-c11-branch-inventory.tsv"

# NC-C12: C execution automatically equated with C policy: a C SEMANTIC
# OWNER verdict without the independent-policy evidence.
awk -F'\t' 'BEGIN{OFS="\t"} /^BR_EMITFILE_EMIT_OBJECT\t/{ $9="NO" } {print}' "$I/ownership.tsv" > "$M/nc-c12-ownership.tsv"

# NC-C13: an unlinked mutant is accepted.
awk -F'\t' 'BEGIN{OFS="\t"} /^BR_EMITFILE_EMIT_OBJECT\t/{ $13="NO" } {print}' "$I/ownership.tsv" > "$M/nc-c13-ownership.tsv"

# NC-C14: the comparator observes NO dimensions.
awk -F'\t' 'BEGIN{OFS="\t"} /^BR_EMITFILE_EMIT_OBJECT\t/{ $12="NONE" } {print}' "$I/ownership.tsv" > "$M/nc-c14-ownership.tsv"

# NC-C15: a NOT_REMEASURED baseline is laundered into a fresh PASS.
printf 'key\tHISTORICAL_VALUE\tFRESH_MEASUREMENT\tCONSERVATION_VERDICT\nGATE_FAST\tNOT_REMEASURED\tPASS\tCONSERVED\n' > "$M/nc-c15-baseline.tsv"

# NC-C16: an external success claimed BEFORE close.
awk -F'\t' 'BEGIN{OFS="\t"} /^PREDECESSOR_EXTERNAL_PROBE\t/{ $3="BEFORE_CLOSE" } {print}' "$I/chronology.tsv" > "$M/nc-c16-chronology.tsv"

# NC-C17: a historical receipt chronology is invented.
awk -F'\t' 'BEGIN{OFS="\t"} /^HISTORICAL_ACT_TERMINALITY\t/{ $2="EXTERNAL_SUCCESS" } {print}' "$I/chronology.tsv" > "$M/nc-c17-chronology.tsv"

ls -1 "$M" | wc -l
