#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c1/capture-authority-join.sh
#
# Joins the work packages against the REAL CENSUS01 authority table.
# The authority table is the source of truth for how many decision
# sites a package actually owns; nothing here is invented.
#
# F-POLYC-TOOLS: orchestration glue (<=50 LOC of intent; the counting
# itself is done by the POSIX tools below).

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
AUTH="evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/authorities.tsv"
OUT="$EV/c1/current-authority-join.tsv"
TMP=$(mktemp /tmp/m2rebase-join.XXXXXX)
trap 'rm -f "$TMP"' EXIT INT TERM

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01'
  echo '# ACT_PHASE=C1-EVIDENCE'
  echo '# EVIDENCE_KIND=current-authority-join'
  echo '#'
  echo '# THE JOIN BETWEEN THE WORK PACKAGES AND THE REAL AUTHORITY ROWS.'
  echo '#'
  echo '# Source of truth: the CENSUS01 authority table (2233 rows).'
  echo '# Each work package names the source set it owns; this file'
  echo '# reports how many real authority rows that source set carries,'
  echo '# so the package sizes are NOT invented and the work-package'
  echo '# count can be checked against the authority population.'
  echo '#'
  printf 'wp_id\towned_source_file\tauthority_rows_c\tpolyc_subject_rows\tauthority_total\tjoin_status\tevidence\n'
} > "$TMP"

emit() {
  _wp="$1"
  _f="$2"
  _c=$(awk -F'\t' -v want="$_f" 'NR>1 && $5==want && $4=="C"' "$AUTH" | wc -l | tr -d ' ')
  _p=$(awk -F'\t' -v want="$_f" 'NR>1 && $5==want && $4!="C"' "$AUTH" | wc -l | tr -d ' ')
  _t=$((_c + _p))
  if [ "$_t" -gt 0 ]; then _s=JOINED; else _s=NO_AUTHORITY_ROWS; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_wp" "$_f" "$_c" "$_p" "$_t" "$_s" \
    "evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/authorities.tsv" >> "$TMP"
}

emit WP-001 src/main.c
emit WP-001 src/cli.c
emit WP-002 src/compile.c
emit WP-002 src/cctrl.c
emit WP-003 src/lexer.c
emit WP-004 src/parser.c
emit WP-004 src/prslib.c
emit WP-004 src/prsutil.c
emit WP-005 src/ast.c
emit WP-006 src/aostr.c
emit WP-006 src/containers.c
emit WP-006 src/list.c
emit WP-007 src/ir.c
emit WP-008 src/cfg.c
emit WP-009 src/asm.c
emit WP-009 src/prsasm.c
emit WP-010 src/aarch64.c
emit WP-011 src/x86_64.c
emit WP-011 src/x86.c
emit WP-012 src/json.c
emit WP-013 src/lsp.c
emit WP-014 src/repl.c
emit WP-015 src/transpiler.c
emit WP-016 src/memsafe.c

mv "$TMP" "$OUT"
trap - EXIT INT TERM

echo "AUTHORITY_JOIN_WRITTEN=$OUT"
echo "AUTHORITY_JOIN_ROWS=$(grep -c '^WP-' "$OUT")"
echo "AUTHORITY_JOIN_TOTAL=$(awk -F'\t' '/^WP-/ {s+=$5} END {print s}' "$OUT")"
