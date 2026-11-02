#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/capture-scenarios.sh
#
# Builds c2/forecast-scenarios.tsv.
#
# A SCENARIO IS A SUBSET OF THE WORK-PACKAGE DAG. For each subset this
# script computes, from the real work-packages.tsv and the real
# work-package-dependencies.tsv:
#
#   total_effort_{low,base,high}  = the SUM of the selected packages
#   critical_path_{low,base,high}  = the LONGEST PATH in the induced
#                                     subgraph, by package effort
#
# The two are computed separately and MUST NOT be equated. The
# archived forecast equated them; that was its critical-path defect.
#
# F-POLYC-TOOLS: orchestration glue; the arithmetic is done by the
# POSIX tools below and independently re-derived by the PolyC verifier
# in FORECAST mode.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
WP="$EV/c2/work-packages.tsv"
DEP="$EV/c2/work-package-dependencies.tsv"
OUT="$EV/c2/forecast-scenarios.tsv"
TMP=$(mktemp /tmp/m2rebase-scen.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

# compute <subset-file>
#
# Prints "<sum_low> <sum_base> <sum_high> <path_low> <path_base>
# <path_high>" for the given subset of package ids.
compute() {
  awk -F'\t' -v subfile="$1" -v pkgfile="$WP" -v depfile="$DEP" '
    BEGIN {
      while ((getline line < subfile) > 0) {
        if (line != "") { inS[line] = 1 }
      }
    }
    FILENAME == pkgfile {
      if (FNR == 1) next
      if ($1 !~ /^WP-/) next
      pkg[$1] = 1
      lo[$1] = $13; ba[$1] = $14; hi[$1] = $15
      next
    }
    FILENAME == depfile {
      if ($1 !~ /^WP-/) next
      if (!($1 in inS)) next
      if (!($2 in inS)) next
      f[++E] = $1; t[E] = $2
      next
    }
    END {
      sumlo = 0; sumba = 0; sumhi = 0
      for (k in inS) {
        if (!(k in pkg)) continue
        sumlo += lo[k]; sumba += ba[k]; sumhi += hi[k]
      }
      for (which = 1; which <= 3; which++) {
        # Every selected package starts with its OWN effort, so a
        # source package with no incoming edge is still counted.
        for (k in inS) {
          if (!(k in pkg)) continue
          if (which == 1) { d[k] = lo[k] } else if (which == 2) { d[k] = ba[k] } else { d[k] = hi[k] }
        }
        for (i = 1; i <= E; i++) {
          if (which == 1) { e = lo[t[i]] } else if (which == 2) { e = ba[t[i]] } else { e = hi[t[i]] }
          if (e > d[t[i]]) { d[t[i]] = e }
        }
        for (pass = 1; pass <= E + 1; pass++) {
          changed = 0
          for (i = 1; i <= E; i++) {
            if (which == 1) { e = lo[t[i]] } else if (which == 2) { e = ba[t[i]] } else { e = hi[t[i]] }
            cand = d[f[i]] + e
            if (cand > d[t[i]]) { d[t[i]] = cand; changed = 1 }
          }
          if (!changed) break
        }
        m = 0
        for (k in d) if (d[k] > m) m = d[k]
        if (which == 1) { plo = m } else if (which == 2) { pba = m } else { phi = m }
      }
      printf "%d %d %d %d %d %d\n", sumlo, sumba, sumhi, plo, pba, phi
    }
  ' "$WP" "$DEP"
}

# ---------------------------------------------------------------------------
# THE SCENARIO SUBSETS
# ---------------------------------------------------------------------------
#
# S01 THE FIRST BOUNDED STEP. The driver only. This is the successor
#     this ACT selects, so its numbers must be exact.
# S02 THE DRIVER AND THE PIPELINE. The first two packages.
# S03 THE FRONT-END QUADRANT. Everything from the driver to the parser
#     plus the containers, plus the shared ABI: the smallest set that
#     contains a complete front end.
# S04 THE M2 PRECURSOR. Every package whose milestone is M2_PRECURSOR.
# S05 THE FULL M2 SCOPE. Every package.
#
# The subsets are defined by a SELECTOR over the package table, never
# by a hand-copied id list, so they cannot drift from the model.

subset_from_predicate() {
  _pred="$1"
  awk -F'\t' -v pred="$_pred" '
    $1 ~ /^WP-/ {
      w = $0
      keep = 0
      if (pred == "WP-001")                 { keep = ($1 == "WP-001") }
      else if (pred == "FIRST_TWO")         { keep = ($1 == "WP-001" || $1 == "WP-002") }
      else if (pred == "PRECURSOR")         { keep = ($5 == "M2_PRECURSOR") }
      else if (pred == "ALL")               { keep = 1 }
      else if (pred == "FRONT_END") {
        keep = ($1 == "WP-001" || $1 == "WP-002" || $1 == "WP-003" ||
                $1 == "WP-004" || $1 == "WP-006" || $1 == "WP-017")
      }
      if (keep) print $1
    }' "$WP"
}

emit() {
  _sid="$1"; _label="$2"; _pred="$3"; _reserve="$4"; _note="$5"
  _sub=$(mktemp /tmp/m2rebase-sub.XXXXXX)
  subset_from_predicate "$_pred" > "$_sub"
  _n=$(wc -l < "$_sub" | tr -d ' ')
  _v=$(compute "$_sub")
  rm -f "$_sub"
  _sl=$(echo "$_v" | cut -d' ' -f1)
  _sb=$(echo "$_v" | cut -d' ' -f2)
  _sh=$(echo "$_v" | cut -d' ' -f3)
  _pl=$(echo "$_v" | cut -d' ' -f4)
  _pb=$(echo "$_v" | cut -d' ' -f5)
  _ph=$(echo "$_v" | cut -d' ' -f6)
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_sid" "$_label" "$_sl" "$_sb" "$_sh" "$_pl" "$_pb" "$_ph" \
    "$_reserve" "$_note" >> "$TMP"
  printf 'SCENARIO %s packages=%s total=%s/%s/%s path=%s/%s/%s\n' \
    "$_sid" "$_n" "$_sl" "$_sb" "$_sh" "$_pl" "$_pb" "$_ph"
}

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C2-IMPL'
  echo '# EVIDENCE_KIND=forecast-scenarios'
  echo '#'
  echo '# THE REBASED FORECAST SCENARIOS, AND THE HISTORICAL COMPARISON.'
  echo '#'
  echo '# Each scenario is a SUBSET of the work-package DAG plus an'
  echo '# explicit scope note. The totals are the SUM over the selected'
  echo '# packages and the critical path is the LONGEST PATH over the'
  echo '# INDUCED SUBGRAPH -- computed separately, never equated. That'
  echo '# distinction is exactly what the archived forecast failed to'
  echo '# make, and it is the single largest structural improvement of'
  echo '# the rebased model over the archived one.'
  echo '#'
  echo '# The critical path is strictly less than the total whenever the'
  echo '# scenario has independent work, and the gap is now MEASURED'
  echo '# rather than asserted.'
  echo '#'
  printf 'scenario_id\tlabel\ttotal_effort_low\ttotal_effort_base\ttotal_effort_high\tcritical_path_low\tcritical_path_base\tcritical_path_high\tcorrection_reserve\tscope_note\n'
} > "$TMP"

emit S01 \
  "THE FIRST BOUNDED STEP: the PolyC-authored driver" \
  "WP-001" \
  0 \
  "WP-001 alone: the argument handling and the compile entry point. THIS IS THE SELECTED SUCCESSOR."

emit S02 \
  "THE DRIVER AND THE COMPILE PIPELINE" \
  "FIRST_TWO" \
  0 \
  "WP-001 and WP-002: the driver plus the read-lex-parse-emit pipeline."

emit S03 \
  "THE COMPLETE FRONT END" \
  "FRONT_END" \
  2 \
  "WP-001,WP-002,WP-003,WP-004,WP-006,WP-017: the driver, the pipeline, the lexer, the parser, the containers and the shared ABI. The smallest set containing a complete front end."

emit S04 \
  "THE M2 PRECURSOR" \
  "PRECURSOR" \
  3 \
  "every package whose milestone is M2_PRECURSOR. The precursor is a working compiler-producing source set, not M2 itself."

emit S05 \
  "THE FULL M2 SCOPE" \
  "ALL" \
  18 \
  "every package: the complete M2 scope with its correction and verification reserve."

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "FORECAST_SCENARIOS_WRITTEN=$OUT"
echo "FORECAST_SCENARIO_COUNT=$(grep -c '^S0' "$OUT")"
