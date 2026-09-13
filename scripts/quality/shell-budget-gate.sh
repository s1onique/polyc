#!/bin/sh
# scripts/quality/shell-budget-gate.sh
# Per-file monotonic budget ratchet.
# Reads docs/factory/SHELL-BUDGET.tsv; fails on B1..B9.
# Hard cap: 50 LOC. Authoritative: docs/acts/ACT-POLYC-TOOLING-SHELL-BUDGET01.
set -eu
M=${1:-docs/factory/SHELL-BUDGET.tsv}
P=${2:-HEAD}
fail=0; fail_msg=""
note() { fail_msg="$fail_msg
$1"; fail=1; }
awk_aggregate() { awk -F'\t' 'NR>1 && $4=="GRANDFATHERED"{s+=$3} END{print s+0}' "$1"; }
new_total=$(awk_aggregate "$M")
old_total=$(git show "$P:$M" 2>/dev/null | awk_aggregate -)
old_total=${old_total:-0}
[ "$new_total" -le "$old_total" ] || note "B9 aggregate new=$new_total > old=$old_total"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
git ls-files '*.sh' | sort > "$tmp/cur"
awk -F'\t' 'NR>1 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7}' "$M" | sort > "$tmp/mf"
cut -f1 "$tmp/mf" > "$tmp/mp"
sort -u "$tmp/mp" > "$tmp/mpu"
[ "$(wc -l <"$tmp/mp")" -eq "$(wc -l <"$tmp/mpu")" ] || note "B-AMBIG duplicate path rows"
comm -23 "$tmp/cur" "$tmp/mp" > "$tmp/unbudgeted"
while read -r p; do [ -n "$p" ] && note "B4 unbudgeted path=$p"; done < "$tmp/unbudgeted"
while read -r line; do
    p=$(echo "$line" | cut -f1); base=$(echo "$line" | cut -f2); new=$(echo "$line" | cut -f3)
    st=$(echo "$line" | cut -f4); old=$(git show "$P:$M" 2>/dev/null | awk -F'\t' -v pp="$p" '$1==pp{print $3; exit}')
    [ "$new" -le "${old:-$new}" ] || note "B2 budget increase path=$p old=${old:-N/A} new=$new"
    case "$st" in
        MIGRATED) [ ! -f "$p" ] || note "B3 MIGRATED path exists: $p" ;;
        TINY|EXEMPT_WRAPPER) cur=$(wc -l <"$p" 2>/dev/null || echo 0); [ "$cur" -le 50 ] || note "B7 $st over 50 path=$p cur=$cur"; [ "$cur" -le "$new" ] || note "B-TINY $st over per-file budget path=$p cur=$cur budget=$new" ;;
        GRANDFATHERED)
            [ -f "$p" ] || note "B8 GRANDFATHERED absent path=$p (mark MIGRATED)"
            cur=$(wc -l <"$p" 2>/dev/null || echo 0); [ "$cur" -le "$new" ] || note "B1 GRANDFATHERED over budget path=$p cur=$cur budget=$new" ;;
    esac
done < "$tmp/mf"
if [ "$fail" -eq 0 ]; then echo "PASS shell-budget-gate aggregate=$new_total"; exit 0; fi
echo "FAIL shell-budget-gate$fail_msg"; exit 1
