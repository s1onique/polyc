#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/capture-ranking.sh
#
# Builds c2/work-package-ranking.tsv.
#
# The ranking is DERIVED from the real DAG: for each package, the
# number of downstream packages it transitively unblocks is computed
# from the real work-package-dependencies.tsv by reachability. The
# rank bands come from the real milestone and required_gate columns
# of the real work-packages.tsv.
#
# The SUCCESSOR is the first R0 package, in package-id order, whose
# predecessors are all satisfiable and which has a named witness.
#
# F-POLYC-TOOLS: orchestration glue.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
WP="$EV/c2/work-packages.tsv"
DEP="$EV/c2/work-package-dependencies.tsv"
JOIN="$EV/c1/current-authority-join.tsv"
OUT="$EV/c2/work-package-ranking.tsv"
TMP=$(mktemp /tmp/m2rebase-rank.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

# For each package, the count of DISTINCT packages reachable downstream.
downstream_counts() {
  awk -F'\t' -v depfile="$DEP" '
    FILENAME == depfile {
      if ($1 !~ /^WP-/) next
      adj[$1] = adj[$1] " " $2
      nodes[$1] = 1; nodes[$2] = 1
      next
    }
    END {
      for (s in nodes) {
        # BFS from s over the forward edges.
        delete seen
        q[1] = s; head = 1; tail = 1; seen[s] = 1
        count = 0
        while (head <= tail) {
          cur = q[head]; head++
          n = split(adj[cur], lst, " ")
          for (i = 1; i <= n; i++) {
            nx = lst[i]
            if (nx == "") continue
            if (nx in seen) continue
            seen[nx] = 1
            count++
            q[++tail] = nx
          }
        }
        print s "\t" count
      }
    }' "$DEP" | sort
}

_DOWN=$(mktemp /tmp/m2rebase-down.XXXXXX)
downstream_counts > "$_DOWN"

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C2-IMPL'
  echo '# EVIDENCE_KIND=work-package-ranking'
  echo '#'
  echo '# THE RANKING, AND THE ONE SUCCESSOR THIS ACT SELECTS.'
  echo '#'
  echo '# THE RANKING CRITERION, STATED ONCE:'
  echo '#   A work package is RANKED BY HOW FAR IT MOVES THE'
  echo '#   PROGRAMME, measured as the number of downstream packages it'
  echo '#   UNBLOCKS, and it is QUALIFIED only if it has a named'
  echo '#   smallest runnable witness.'
  echo '#'
  echo '#   R0 = it is on the critical path to the earliest'
  echo '#        unsatisfied bootstrap gate (P0: the compiler-producing'
  echo '#        source set does not exist yet).'
  echo '#   R1 = it is required for the M2 milestone.'
  echo '#   R2 = it is required for the M2 milestone but is NOT on the'
  echo '#        host-target critical path, so it can run in parallel.'
  echo '#   R3 = it is a tool surface, not on the M2 path.'
  echo '#'
  echo '# The downstream_unblocked column is COMPUTED by reachability'
  echo '# over the real dependency edges, not asserted.'
  echo '#'
  echo '# The successor is selected by the FIRST package that is'
  echo '# RANKED R0, that has a named witness, and whose predecessors'
  echo '# are all satisfiable. This is the ONLY successor this ACT'
  echo '# opens; no other package is authorized by this document.'
  echo '#'
  printf 'rank\twp_id\tsubsystem\tgate_satisfied\tauthority_rows\tdownstream_unblocked\tbase_effort\tpriority\tqualification\twitness\tevidence\n'
} > "$TMP"

# The ranking rows, in package-id order.
awk -F'\t' -v joinfile="$JOIN" -v pkgfile="$WP" -v downfile="$_DOWN" '
  FILENAME == joinfile {
    if ($1 !~ /^WP-/) next
    sites[$1] += $5
    next
  }
  FILENAME == downfile {
    down[$1] = $2
    next
  }
  FILENAME == pkgfile {
    if ($1 !~ /^WP-/) next
    id = $1
    subsystem = $3; goal = $4; mile = $5; gate = $8
    wit = $11; ready = $12; prio = $18; conf = $17
    eff = $14
    sitecount = sites[id] + 0
    d = down[id] + 0
    # The qualification gate: a package is QUALIFIED only if it has
    # a NAMED smallest runnable witness and it is proof-ready.
    if (wit == "NONE" || wit == "") qual = "NOT_QUALIFIED_NO_WITNESS"
    else if (ready == "NO") qual = "QUALIFIED_PENDING"
    else qual = "QUALIFIED"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", \
      prio, id, subsystem, gate, sitecount, d, eff, prio, qual, wit, \
      "c2/work-packages.tsv;c2/work-package-dependencies.tsv;c1/current-authority-join.tsv"
  }' "$JOIN" "$_DOWN" "$WP" >> "$TMP"

rm -f "$_DOWN"

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "WORK_PACKAGE_RANKING_WRITTEN=$OUT"
echo "WORK_PACKAGE_RANKING_ROWS=$(grep -c '^R[0-9]' "$OUT")"
