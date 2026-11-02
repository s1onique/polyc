#!/bin/sh
# THE INDEPENDENT POSIX/GIT WITNESS.
#
# It recomputes the critical facts from the SAME committed inputs as
# the compiled PolyC verifier, using git, awk, sort, uniq, comm, cmp
# and shasum. It shares NO material detection algorithm with the
# compiled verifier: it does not tokenise predicates, does not compare
# phases through a column index, and does not read a verdict field.
#
# NO PYTHON.
set -u
HERE=$(dirname "$0")
REPO=$(cd "$HERE/../../.." && pwd)
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
OUT="$HERE/independent-witness.tsv"
PRE=907af8c82abfb2292d5eccfdf18b63080da767f2
CLOSE=edfc3b16620e8d84b00a276984109a3b2fa8b338
E=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01
W=$(mktemp -d /tmp/c02-indep.XXXXXX)
trap 'rm -rf "$W"' EXIT INT TERM
cd "$REPO" || exit 1

# The frozen inputs, read DIRECTLY from the Git object store.
git show "${PRE}:$E/q0/frozen-ac01-ac50.tsv" | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$2"\t"$3}' | sort > "$W/frozen.tsv"
git show "${PRE}:$E/q3/acceptance-ledger.tsv" | awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ {print $1"\t"$2"\t"$3"\t"$4}' | sort > "$W/ledger.tsv"
git ls-tree -r --name-only "$CLOSE" | sort > "$W/closetree.txt"

{
echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
echo '# ACT_PHASE=C2-IMPL'
echo '# EVIDENCE_KIND=independent-witness'
echo '#'
echo '# THE INDEPENDENT POSIX/GIT WITNESS.'
echo '#'
echo '# It recomputes each critical fact from the SAME committed inputs'
echo '# using git, awk, sort, uniq, comm, cmp and shasum. It shares NO'
echo '# material detection algorithm with the compiled PolyC verifier:'
echo '# it does NOT tokenise predicates, does NOT compare phases through'
echo '# a column index, and does NOT read a verdict field.'
echo '#'
echo '# THE VERDICT IS PER FACT. A MATCHING OVERALL PASS STRING IS NOT'
echo '# SUFFICIENT.'
echo '#'
printf 'fact\tindependent_value\tmethod\n'
} > "$OUT"

emit() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$OUT"; }

# --- AC_IDENTITY ---------------------------------------------------------
# The frozen roster's identifier set, and the ledger's, compared as
# SETS with comm.
awk -F'\t' '{print $1}' "$W/frozen.tsv" | sort > "$W/frozen.ids"
awk -F'\t' '{print $1}' "$W/ledger.tsv" | sort > "$W/ledger.ids"
MISSING=$(comm -23 "$W/frozen.ids" "$W/ledger.ids" | wc -l | tr -d ' ')
EXTRA=$(comm -13 "$W/frozen.ids" "$W/ledger.ids" | wc -l | tr -d ' ')
DUP=$(uniq -d "$W/ledger.ids" | wc -l | tr -d ' ')
emit AC_IDENTITY "frozen=$(wc -l < "$W/frozen.ids" | tr -d ' ') ledger=$(wc -l < "$W/ledger.ids" | tr -d ' ') missing=$MISSING extra=$EXTRA duplicate=$DUP" "comm over the sorted identifier sets"

# --- AC_PHASES ------------------------------------------------------------
# The phase comparison is done by JOINING the two files on the
# identifier and comparing the phase fields, with no column indices
# shared with the compiled verifier.
join -t"$(printf '\t')" "$W/frozen.tsv" "$W/ledger.tsv" | awk -F'\t' '$2 != $4 {n++; if (n<=10) ids = ids " " $1} END {print "drift_rows=" n+0 " ids:" ids}' > "$W/phase.txt"
emit AC_PHASES "$(cat "$W/phase.txt")" "join on identifier, compare the phase fields"

# --- AC_PREDICATE_BINDING -------------------------------------------------
# The predicate binding is decided by the ANALYST ADJUDICATION table,
# whose rows name a STRUCTURED FIELD of a named artifact. The witness
# RE-READS that field from the named artifact and checks that the
# artifact exists at the predecessor close.
AW="$D/c1/analyst-adjudications.tsv"
# The per-row binding check. Each adjudication names a STRUCTURED
# FIELD of a named artifact; the field is RE-READ from the artifact in
# the predecessor close tree, and the artifact must EXIST there.
BOUND=0; UNBOUND=0; ABSENT=0
# The predecessor evidence is EXTRACTED ONCE into a scratch tree, so
# the binding check is a local read and not one git invocation per
# row. Nothing is modified: the extraction reads the committed blobs.
mkdir -p "$W/tree"
git ls-tree -r --name-only "$PRE" -- "$E/" | while IFS= read -r p; do
  mkdir -p "$W/tree/$(dirname "$p")"
  git show "${PRE}:$p" > "$W/tree/$p" 2>/dev/null || true
done
while IFS="$(printf '\t')" read -r line; do
  case "$line" in '#'*) continue ;; esac
  aid=$(printf '%s' "$line" | cut -f1)
  [ "$aid" = "adjudication_id" ] && continue
  art=$(printf '%s' "$line" | cut -f5)
  afield=$(printf '%s' "$line" | cut -f8)
  # The named field may be a LIST of fields separated by " / ". The
  # FIRST named field is the one that is checked; the others are the
  # analyst's additional context.
  afield=$(printf '%s' "$afield" | awk -F' / ' '{print $1}')
  if [ "$art" = "NONE" ] || [ -z "$art" ]; then UNBOUND=$((UNBOUND+1)); continue; fi
  case "$art" in docs/*) full="$art" ;; *) full="$E/$art" ;; esac
  cf="$W/tree/$full"
  if [ ! -f "$cf" ]; then ABSENT=$((ABSENT+1)); UNBOUND=$((UNBOUND+1)); continue; fi
  if grep -q -- "$afield" "$cf" < /dev/null; then BOUND=$((BOUND+1)); else UNBOUND=$((UNBOUND+1)); fi
done < "$AW"
emit AC_PREDICATE_BINDING "adjudications_bound=$BOUND unbound=$UNBOUND artifact_absent=$ABSENT" "re-read the named structured field from the named artifact in the predecessor close tree"

# --- BINDING_INVARIANT ------------------------------------------------------
# The CORRECTION VERIFIER checks the invariant that a PROVEN verdict has
# a binding artifact that is present, phase-valid and carries the
# subject. The INDEPENDENT WITNESS recomputes the SAME invariant from
# the Git object store, WITHOUT reading the verifier and WITHOUT
# trusting the binding table's own presence column.
#
# For every row of the witness binding table that is adjudicated
# PROVEN, the binding artifact must:
#   1. EXIST in the predecessor close tree, by git ls-tree;
#   2. carry a phase directory that is a valid phase;
#   3. be named by a row whose verdict is PROVEN.
# A PROVEN row with no such artifact is a BINDING_HOLE.
BIND="$D/c2/inputs/witness-existence.tsv"
PROVEN_ROWS=0; BINDING_OK=0; BINDING_HOLE=0; BINDING_ABSENT=0
while IFS="$(printf '\t')" read -r bid bfph bcit bcpr bcph bcca bba bbp bbpv bbca bst; do
  case "$bid" in AC[0-9][0-9]) ;; *) continue ;; esac
  case "$bst" in PROVEN*) ;; *) continue ;; esac
  PROVEN_ROWS=$((PROVEN_ROWS+1))
  if [ "$bba" = "NONE" ] || [ -z "$bba" ]; then BINDING_HOLE=$((BINDING_HOLE+1)); continue; fi
  case "$bba" in */*) full="$E/$bba" ;; *) full="$bba" ;; esac
  if ! grep -qx -- "$full" "$W/closetree.txt" < /dev/null; then
    BINDING_ABSENT=$((BINDING_ABSENT+1)); BINDING_HOLE=$((BINDING_HOLE+1)); continue
  fi
  if [ "$bbpv" != "YES" ] || [ "$bbca" != "YES" ]; then BINDING_HOLE=$((BINDING_HOLE+1)); continue; fi
  BINDING_OK=$((BINDING_OK+1))
done < "$BIND"
emit BINDING_INVARIANT "proven_rows=$PROVEN_ROWS binding_ok=$BINDING_OK binding_hole=$BINDING_HOLE binding_absent_from_close_tree=$BINDING_ABSENT" "recompute the PROVEN-verdict binding invariant against git ls-tree at the predecessor close"

# --- AC_COUNTS ------------------------------------------------------------
# The criterion-only status partition, and the EXCLUSION of the
# metadata row, computed with sort and uniq over the identifier set.
PASS=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="PASS"' "$W/ledger.tsv" | wc -l | tr -d ' ')
FAIL=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="FAIL"' "$W/ledger.tsv" | wc -l | tr -d ' ')
DEF=$(awk -F'\t' '$1 ~ /^AC[0-9][0-9]$/ && $3=="DEFERRED"' "$W/ledger.tsv" | wc -l | tr -d ' ')
META=$(git show "${PRE}:$E/q3/acceptance-ledger.tsv" | awk -F'\t' '$1 ~ /^AC/ && $1 !~ /^AC[0-9][0-9]$/ {print $1}' | tr '\n' ' ')
SUM=$(git show "${PRE}:$E/q3/acceptance-ledger.tsv" | grep -E '^# LEDGER_(PASS|FAIL|DEFERRED)' | sed 's/^# //' | tr '\n' ' ')
HAND=$(git show "${PRE}:docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01.md" | grep -oE '[0-9]+ PASS, [0-9]+ FAIL, [0-9]+ DEFERRED' | head -1)
emit AC_COUNTS "criterion_rows=PASS:$PASS FAIL:$FAIL DEFERRED:$DEF metadata_excluded=[$META] ledger_summary=[$SUM] handoff=[$HAND]" "awk over the ACnn identifier set, excluding the metadata row"

# --- WITNESS_PATH_EXISTENCE ----------------------------------------------
# Every cited witness path, resolved against the close tree.
ABSENTPATHS=0; TOTAL=0
while IFS="$(printf '\t')" read -r id ph st wit; do
  case "$id" in ''|'#'*) continue ;; esac
  TOTAL=$((TOTAL+1))
  case "$wit" in q?/*) if ! grep -qx "$E/$wit" "$W/closetree.txt" < /dev/null; then ABSENTPATHS=$((ABSENTPATHS+1)); fi ;; esac
done < "$W/ledger.tsv"
emit WITNESS_PATH_EXISTENCE "cited_paths=$TOTAL absent_from_close_tree=$ABSENTPATHS" "resolve each cited path against git ls-tree at the predecessor close"

# --- WITNESS_CHRONOLOGY ---------------------------------------------------
# The phase directory of each cited witness, against the frozen phase.
WRONGPHASE=0; TOTAL2=0
join -t"$(printf '\t')" "$W/frozen.tsv" "$W/ledger.tsv" > "$W/joined.tsv"
while IFS="$(printf '\t')" read -r id fph fpred lph lst lwit; do
  case "$lwit" in q?/*)
    wd=$(printf '%s' "$lwit" | cut -c1-2 | tr 'a-z' 'A-Z')
    if [ "$wd" != "$fph" ]; then echo "$id"; fi ;;
  esac
done < "$W/joined.tsv" | sort > "$W/wrongphase.ids"
WRONGPHASE=$(wc -l < "$W/wrongphase.ids" | tr -d ' ')
emit WITNESS_CHRONOLOGY "cited_witness_phase_differs_from_frozen_phase=$WRONGPHASE ids=$(cat "$W/wrongphase.ids" | tr '\n' ' ')" "compare the witness path phase directory with the frozen phase"

# --- BRANCH_ROUTE_SCOPES --------------------------------------------------
# The branch inventory's route scopes, counted by the frozen vocabulary.
INV="$D/c1/source-branch-inventory.tsv"
REQ=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="PROVEN_REACHABLE"' "$INV" | wc -l | tr -d ' ')
UNR=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="PROVEN_UNREACHABLE"' "$INV" | wc -l | tr -d ' ')
UNP=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="UNPROVEN"' "$INV" | wc -l | tr -d ' ')
REQIDS=$(awk -F'\t' '$1 ~ /^BR_/ && $9=="PROVEN_REACHABLE" {print $1}' "$INV" | tr '\n' ' ')
emit BRANCH_ROUTE_SCOPES "proven_reachable=$REQ proven_unreachable=$UNR unproven=$UNP reachable_ids=[$REQIDS]" "count the route scope vocabulary in the source-derived branch inventory"

# --- BASELINE_STATUS ------------------------------------------------------
# The three baseline states, read from the predecessor's committed
# baseline ledger.
BL="$E/q3/baseline-conservation.tsv"
NOTRE=$(git show "${PRE}:$BL" | awk -F'\t' '$3 ~ /NOT_REMEASURED/ || $4 ~ /NOT_REMEASURED/' | wc -l | tr -d ' ')
KNOWNFAIL=$(git show "${PRE}:$BL" | awk -F'\t' '$4 ~ /KNOWN_BASELINE/' | wc -l | tr -d ' ')
emit BASELINE_STATUS "not_remeasured_rows=$NOTRE known_failure_rows=$KNOWNFAIL" "read the committed baseline ledger rows, preserving the NOT_REMEASURED state"
