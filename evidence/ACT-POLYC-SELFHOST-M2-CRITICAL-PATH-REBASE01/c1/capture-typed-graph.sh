#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c1/capture-typed-graph.sh
#
# Rebuilds c1/typed-graph-versioned.tsv from the CENSUS01 committed
# graph edges, re-classifying every edge against this ACT's criteria
# and padding EVERY row to the exact 10-column layout.
#
# The earlier hand-assembled version of this file had 236 ragged
# rows (9 fields against a 10-field header). This generator makes
# that class of defect impossible.
#
# F-POLYC-TOOLS: orchestration glue; the classification table is
# data, the counting is done by the POSIX tools below.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
SRC="evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/graph-edges.tsv"
OUT="$EV/c1/typed-graph-versioned.tsv"
TMP=$(mktemp /tmp/m2rebase-graph.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C1-EVIDENCE'
  echo '# EVIDENCE_KIND=typed-graph-versioned'
  echo '#'
  echo '# THE GRAPH, WITH ITS SCOPE EXPLICIT AND ITS EDGES CLASSIFIED.'
  echo '#'
  echo '# SCOPE = BASE_GRAPH. The archived CENSUS01 graph-edges.tsv as'
  echo '# committed, with EVERY edge re-classified against this ACT s'
  echo '# section 3.4 criteria. The scope name travels with the file so a'
  echo '# count from another scope can never be silently substituted.'
  echo '#'
  echo '# Every row has exactly 10 columns.'
  echo '#'
  printf 'edge_id\tsrc_id\tdst_id\tedge_type\tmandatory_for\tmandatory\tobserved_or_inferred\tgraph_scope\tm2_classification\tevidence_note\n'
} > "$TMP"

# classify <edge_type> -> <mandatory_for> <mandatory> <m2_classification>
classify() {
  case "$1" in
    TYPE_REPRESENTATION) echo "TYPE_LAYOUT_BEFORE_SEMANTICS	YES	LAYOUT_ONLY_CANDIDATE" ;;
    CALLBACK)            echo "CALLBACK_CONTRACT_BEFORE_SEMANTICS	YES	CALLBACK_CANDIDATE" ;;
    MUTABLE_STATE)       echo "GLOBAL_STATE_OWNERSHIP_BEFORE_SEMANTICS	YES	PROVEN_STATE_CANDIDATE" ;;
    RECOVERY)            echo "RECOVERY_PATH_BEFORE_SEMANTICS	YES	RECOVERY_CANDIDATE" ;;
    CALLS)               echo "AVAILABILITY_ONLY	NO	CALL_AVAILABILITY" ;;
    *)                   echo "AVAILABILITY_ONLY	NO	CALL_AVAILABILITY" ;;
  esac
}

# The two edges this ACT specifically examined in C0 and C1.
case_note() {
  case "$1" in
    E-TYP-0136)
      echo "header inclusion alone (src/compile.c:1); OBSERVED_LAYOUT_COUPLING, NOT a proven mandatory atomic-migration edge" ;;
    E-MUT-0137)
      echo "its own evidence cites the include line (src/compile.c:1), not a use site; UNSUPPORTED WITNESS for a global-state obligation" ;;
    *)
      echo "NO_NOTE: the archived evidence column for this edge is the shared class-level statement, not an edge-specific witness" ;;
  esac
}

# Read the source table, skipping its header and any comment rows.
awk -F'\t' 'NR>1 && $1 !~ /^#/ && NF>=12 {print}' "$SRC" | while IFS="$(printf '\t')" read -r eid src dst etype mfor mand obs ev callsite xfer cfg cert; do
  set -- $(classify "$etype" | tr '\t' ' ')
  _mfor="$1"
  _mand="$2"
  _cls="$3"
  _note=$(case_note "$eid")
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tBASE_GRAPH\t%s\t%s\n' \
    "$eid" "$src" "$dst" "$etype" "$_mfor" "$_mand" "$obs" "$_cls" "$_note" >> "$TMP"
done

mv "$TMP" "$OUT"
trap - EXIT INT TERM

_rows=$(awk -F'\t' '/^E-/ {n++} END {print n+0}' "$OUT")
_cols=$(awk -F'\t' '/^E-/ {print NF; exit}' "$OUT")
_ragged=$(awk -F'\t' '/^E-/ {c[NF]++} END {k=0; for (x in c) if (x!=10) k+=c[x]; print k+0}' "$OUT")
_mand=$(awk -F'\t' '/^E-/ && $6=="YES" {n++} END {print n+0}' "$OUT")

echo "TYPED_GRAPH_WRITTEN=$OUT"
echo "TYPED_GRAPH_EDGES=$_rows"
echo "TYPED_GRAPH_COLUMNS=$_cols"
echo "TYPED_GRAPH_RAGGED_ROWS=$_ragged"
echo "TYPED_GRAPH_MANDATORY_EDGES=$_mand"
echo "TYPED_GRAPH_EDGE_TYPE_HISTOGRAM:"
awk -F'\t' '/^E-/ {print $4}' "$OUT" | sort | uniq -c | sed 's/^/  /'
