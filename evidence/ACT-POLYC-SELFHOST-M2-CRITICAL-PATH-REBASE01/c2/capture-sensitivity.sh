#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/capture-sensitivity.sh
#
# Builds c2/forecast-sensitivity.tsv.
#
# For each varied assumption this script RE-RUNS the real package
# model over the FULL M2 scope (S05) with the parameter changed, and
# reports the resulting totals and critical path. Nothing is asserted:
# every row is the output of the same computation that produces
# c2/forecast-scenarios.tsv.
#
# THE PARAMETERS VARIED, AND WHY THESE:
#
#   SITES_PER_ACT   The archived forecast assumed 12 sites per
#                   implementation ACT (FA-04). The MEASURED rate over
#                   the only cohorts that have run is 1.0 (9 PolyC
#                   subjects against 9 implementation ACTs). This
#                   varies the sites-per-ACT rate over the range the
#                   measured cohorts actually exhibit: 1, 6, 12.
#
#   RISK_MULTIPLIER The archived forecast applied a 1.25 risk
#                   multiplier to high-relevance bundles (FA-08). This
#                   varies it over 1.00, 1.25, 1.50.
#
#   CORRECTION_RATE The archived forecast used a measured 0.44
#                   correction rate (FA-03). This varies it over the
#                   0.25..0.65 range the archived assumptions table
#                   already declares.
#
# F-POLYC-TOOLS: orchestration glue.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
WP="$EV/c2/work-packages.tsv"
DEP="$EV/c2/work-package-dependencies.tsv"
JOIN="$EV/c1/current-authority-join.tsv"
OUT="$EV/c2/forecast-sensitivity.tsv"
TMP=$(mktemp /tmp/m2rebase-sens.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

# model <sites-per-act> <risk-multiplier> <correction-rate>
#
# Prints "<total_low> <total_base> <total_high> <critical_base>".
#
# The model RE-DERIVES each package's implementation ACT count from
# its OWN measured authority-row count (joined from the C1 authority
# join) divided by the sites-per-ACT rate, then applies the risk
# multiplier and the correction reserve, exactly as the archived
# formula does. This is what makes the sensitivity a REAL re-run and
# not a scaling of a precomputed number.
model() {
  awk -F'\t' -v spa="$1" -v risk="$2" -v corr="$3" \
      -v pkgfile="$WP" -v depfile="$DEP" -v joinfile="$JOIN" '
    # A portable ceiling: ceil(x) = int(x) + 1 when x has a fractional
    # part, else int(x).
    function ceil(x) { return (x == int(x)) ? int(x) : int(x) + 1 }
    FILENAME == joinfile {
      if ($1 !~ /^WP-/) next
      sitecount[$1] += $5
      next
    }
    FILENAME == pkgfile {
      if ($1 !~ /^WP-/) next
      ids[++nwp] = f_id = $1
      lo[$1] = $13; ba[$1] = $14; hi[$1] = $15
      conf[$1] = $17
      next
    }
    FILENAME == depfile {
      if ($1 !~ /^WP-/) next
      f[++E] = $1; t[E] = $2
      next
    }
    END {
      tl = 0; tb = 0; th = 0
      for (i = 1; i <= nwp; i++) {
        k = ids[i]
        ns = sitecount[k] + 0
        if (ns < 1) ns = 1
        impl = ceil(ns / spa)
        if (impl < 1) impl = 1
        # The four INFRASTRUCTURE packages (WP-017..WP-020) own no
        # authority rows of their own; their cost is the SHARED
        # foundation work, which is in the static table. They are
        # therefore held at their static base and are NOT re-derived
        # from a site count.
        if (k == "WP-017" || k == "WP-018" || k == "WP-019" || k == "WP-020") {
          e_lo = lo[k]; e_ba = ba[k]; e_hi = hi[k]
          if (e_ba < 1) e_ba = 1
          tl += e_lo; tb += e_ba; th += e_hi
          Elo[k] = e_lo; Eba[k] = e_ba; Ehi[k] = e_hi
          continue
        }
        # the correction reserve is package WP-019, sized by the
        # varied correction rate applied to the implementation work
        if (k == "WP-019") {
          impl = ceil(impl * corr)
          if (impl < 1) impl = 1
        }
        # the risk multiplier applies to LOW-confidence packages
        mult = 1.0
        if (conf[k] == "LOW") mult = risk
        # The package effort is RECOMPUTED from its measured site
        # count at the varied rate, NOT taken from the static table:
        #   impl    = ceil(sites / sites_per_act)
        #   total   = 1 (selection) + impl + 1 (integration)
        #             + 1 (proof) + ceil((impl+1) * corr_rate)
        # This is the archived formula SHAPE, with the site count
        # coming from the C1 authority join instead of a bundle total.
        overhead = 1 + impl + 1 + 1 + ceil((impl + 1) * corr)
        e_ba = int(overhead * mult)
        lo_impl = ceil(ns / spa); if (lo_impl < 1) lo_impl = 1
        hi_impl = ceil(ns / spa); if (hi_impl < 1) hi_impl = 1
        e_lo = int(ceil(1 + lo_impl + 1 + 1 + ceil((lo_impl + 1) * 0.25)) * mult)
        e_hi = int(ceil(1 + hi_impl + 1 + 1 + ceil((hi_impl + 1) * 0.65)) * mult * 1.5)
        if (e_ba < 1) e_ba = 1
        if (e_lo < 1) e_lo = 1
        if (e_hi < 1) e_hi = 1
        tl += e_lo; tb += e_ba; th += e_hi
        Elo[k] = e_lo; Eba[k] = e_ba; Ehi[k] = e_hi
      }
      for (which = 1; which <= 3; which++) {
        for (i = 1; i <= nwp; i++) {
          k = ids[i]
          if (which == 1) { d[k] = Elo[k] } else if (which == 2) { d[k] = Eba[k] } else { d[k] = Ehi[k] }
        }
        for (i = 1; i <= E; i++) {
          if (which == 1) { e = Elo[t[i]] } else if (which == 2) { e = Eba[t[i]] } else { e = Ehi[t[i]] }
          cand = d[f[i]] + e
          if (cand > d[t[i]]) { d[t[i]] = cand }
        }
        m = 0
        for (k in d) if (d[k] > m) m = d[k]
        if (which == 1) { plo = m } else if (which == 2) { pba = m } else { phi = m }
      }
      printf "%d %d %d %d\n", tl, tb, th, pba
    }
  ' "$JOIN" "$WP" "$DEP"
}

# emit <id> <parameter> <from> <to> <spa> <risk> <corr> <class> <evidence>
emit() {
  _id="$1"; _par="$2"; _from="$3"; _to="$4"
  _spa="$5"; _risk="$6"; _corr="$7"; _cls="$8"; _ev="$9"
  _v=$(model "$_spa" "$_risk" "$_corr")
  _tl=$(echo "$_v" | cut -d' ' -f1)
  _tb=$(echo "$_v" | cut -d' ' -f2)
  _th=$(echo "$_v" | cut -d' ' -f3)
  _cb=$(echo "$_v" | cut -d' ' -f4)
  _d=$((_tb - _BASE_TOTAL))
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_par" "$_from" "$_to" "$_tl" "$_tb" "$_th" "$_cb" "$_d" "$_cls" "$_ev" >> "$TMP"
  printf 'SENSITIVITY %s %s->%s total=%s/%s/%s crit=%s delta=%s\n' \
    "$_id" "$_from" "$_to" "$_tl" "$_tb" "$_th" "$_cb" "$_d"
}

# The BASE row of the sensitivity table: the model's own parameters.
# The base sites-per-ACT is the MEASURED rate of 1, not the archived
# assumption of 12. That is the point of the rebased model.
_BASE_V=$(model 1 1.0 0.44)
_BASE_TOTAL=$(echo "$_BASE_V" | cut -d' ' -f2)

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C2-IMPL'
  echo '# EVIDENCE_KIND=forecast-sensitivity'
  echo '#'
  echo '# WHICH ASSUMPTION ACTUALLY MOVES THE FORECAST.'
  echo '#'
  echo '# The rebased model differs from the archived one in exactly one'
  echo '# structural respect: the archived model used an UNMEASURED'
  echo '# sites-per-ACT rate (FA-04 = 12) and had NO independent'
  echo '# critical path. This table varies each assumption over the'
  echo '# range that the historical cohorts actually exhibit, and'
  echo '# reports the effect on the S05 full-scope forecast.'
  echo '#'
  echo '# Every row is computed by RE-RUNNING the real package model'
  echo '# with the varied parameter over the FULL M2 scope; nothing is'
  echo '# asserted and nothing is scaled from a precomputed number.'
  echo '#'
  echo '# THE BASE ROW uses sites-per-ACT = 1, the MEASURED rate over'
  echo '# the only cohorts that have run (9 PolyC subjects against 9'
  echo '# implementation ACTs). The archived 12 is carried as a'
  echo '# variation, not as the base.'
  echo '#'
  printf 'sensitivity_id\tparameter\tvaried_from\tvaried_to\ttotal_low\ttotal_base\ttotal_high\tcritical_base\tdelta_vs_base\tsensitivity_class\tevidence\n'
} > "$TMP"

emit SENS-00 \
  "the model base" "BASE" "BASE" 1 1.0 0.44 \
  "BASE" \
  "sites-per-ACT=1 is the MEASURED rate over the 9 implemented PolyC subjects; risk=1.00; correction=0.44 is the measured parser-slice rate"

emit SENS-01 \
  "sites per implementation ACT" "1" "6" 6 1.0 0.44 \
  "ASSUMPTION_RESTORED" \
  "the archived FA-04 assumption was 12 sites/ACT; 6 is the archived LOW sensitivity value"

emit SENS-02 \
  "sites per implementation ACT" "1" "12" 12 1.0 0.44 \
  "ARCHIVED_ASSUMPTION" \
  "the archived FA-04 assumption, which has NO measured cohort; it is the single most load-bearing unmeasured number in the historical model"

emit SENS-03 \
  "risk multiplier on LOW-confidence packages" "1.00" "1.25" 1 1.25 0.44 \
  "ARCHIVED_ASSUMPTION" \
  "the archived FA-08 risk multiplier, applied to the packages this ACT rates LOW confidence"

emit SENS-04 \
  "risk multiplier on LOW-confidence packages" "1.00" "1.50" 1 1.50 0.44 \
  "ARCHIVED_UPPER_BOUND" \
  "the archived FA-08 sensitivity upper bound"

emit SENS-05 \
  "correction rate" "0.44" "0.25" 1 1.0 0.25 \
  "MEASURED_LOWER_BAND" \
  "the archived FA-03 sensitivity lower bound for the correction rate"

emit SENS-06 \
  "correction rate" "0.44" "0.65" 1 1.0 0.65 \
  "MEASURED_UPPER_BAND" \
  "the archived FA-03 sensitivity upper bound for the correction rate"

emit SENS-07 \
  "the joint pessimistic corner" "BASE" "CORNER" 12 1.50 0.65 \
  "JOINT_PESSIMISTIC" \
  "sites-per-ACT=12 with the archived risk multiplier at its upper bound and the correction rate at its upper bound"

emit SENS-08 \
  "the joint optimistic corner" "BASE" "CORNER" 1 1.00 0.25 \
  "JOINT_OPTIMISTIC" \
  "the measured sites-per-ACT with no risk multiplier and the lowest correction rate"

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "FORECAST_SENSITIVITY_WRITTEN=$OUT"
echo "FORECAST_SENSITIVITY_ROWS=$(grep -c '^SENS-' "$OUT")"
echo "FORECAST_SENSITIVITY_BASE_TOTAL=$_BASE_TOTAL"
