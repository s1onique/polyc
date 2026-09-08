#!/bin/sh
# scripts/quality/factory-v2-range-check.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
#
# Factory v2 ACT range validator.
#
# For a closed Factory-v2 ACT, derives:
#
#   ENTRY    = FIRST^ (parent of FIRST)
#   FIRST    = first commit in the immediately contiguous
#              backwards run carrying ACT=<id>
#   CLOSE    = <CLOSE-COMMIT> (the argument, resolved)
#   COMMITS  = number of commits in FIRST..CLOSE (inclusive)
#   VERDICT  = the value of the ACT-Verdict trailer on CLOSE
#
# Enforces:
#
#   1. CLOSE has ACT=<id>, ACT-Phase=CLOSE, exactly one
#      ACT-Verdict.
#   2. Every commit in FIRST..CLOSE has ACT=<same id> with a
#      valid ACT-Phase.
#   3. FIRST has ACT-Phase=RED.
#   4. Exactly one CLOSE exists in FIRST..CLOSE and it is the
#      last commit.
#   5. ACT-Supersedes / ACT-Corrected-Verdict, if present,
#      appear only on CLOSE.
#   6. No commit after CLOSE carries ACT=<id>.
#
# No numeric commit-count rule.
#
# Usage:
#   factory-v2-range-check.sh <ACT-ID> <CLOSE-COMMIT>
#
# Output (rc=0):
#   ACT=<id>
#   ENTRY=<derived>
#   FIRST=<derived>
#   CLOSE=<derived>
#   COMMITS=<derived>
#   VERDICT=<from trailer>
#   STATUS=PASS
#
# Output (rc=1) on any violation:
#   STATUS=FAIL
#   REASON=<reason>

set -eu

if [ "$#" -ne 2 ]; then
    echo "STATUS=ERROR"
    echo "REASON=usage: factory-v2-range-check.sh <ACT-ID> <CLOSE-COMMIT>"
    exit 2
fi

ACT_ID="$1"
CLOSE_INPUT="$2"

if ! CLOSE=$(git rev-parse --verify "${CLOSE_INPUT}^{commit}" 2>/dev/null); then
    echo "STATUS=ERROR"
    echo "REASON=cannot resolve commit: $CLOSE_INPUT"
    exit 2
fi

fail() {
    echo "STATUS=FAIL"
    echo "REASON=$1"
    exit 1
}

case "$ACT_ID" in
    ACT-POLYC-[A-Z0-9][A-Z0-9_-]*)
        ;;
    *)
        fail "ACT id '$ACT_ID' does not match ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]*\$"
        ;;
esac

# Read CLOSE's trailers via git-log %(trailers). Use a sentinel
# string ('@@@') as the trailer separator; NUL bytes cannot be
# stored in shell variables.
CLOSE_TRAILERS=$(git --no-pager log -1 --format='%(trailers:key=ACT,key=ACT-Phase,key=ACT-Verdict,key=ACT-Supersedes,key=ACT-Corrected-Verdict,separator=@@@)' "$CLOSE" 2>/dev/null) || \
    fail "git log %(trailers:...) unsupported; need Git 2.32+"

close_act_count=$(printf '%s' "$CLOSE_TRAILERS" | tr '@@@' '\n' | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
if [ "$close_act_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT: $ACT_ID (count=$close_act_count)"
fi

close_phase_count=$(printf '%s' "$CLOSE_TRAILERS" | tr '@@@' '\n' | grep -Ec '^ACT-Phase:[[:space:]]+CLOSE$' || true)
if [ "$close_phase_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT-Phase: CLOSE (count=$close_phase_count)"
fi

close_verdict_count=$(printf '%s' "$CLOSE_TRAILERS" | tr '@@@' '\n' | grep -Ec '^ACT-Verdict:' || true)
if [ "$close_verdict_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT-Verdict (count=$close_verdict_count)"
fi

VERDICT_RAW=$(printf '%s' "$CLOSE_TRAILERS" | tr '@@@' '\n' \
    | awk '/^ACT-Verdict:[[:space:]]+/ {
        sub(/^ACT-Verdict:[[:space:]]+/, "", $0)
        gsub(/[[:space:]]+/, "_", $0)
        print
        exit
    }')

case "$VERDICT_RAW" in
    "")
        fail "CLOSE ACT-Verdict value empty"
        ;;
    PASS|PASS_[A-Z0-9_]*|HALT_[A-Z0-9_]*)
        ;;
    *)
        fail "CLOSE ACT-Verdict '$VERDICT_RAW' does not match verdict grammar"
        ;;
esac

# Walk parents backwards while commits carry ACT=<id>.
tmp_matches=$(mktemp -t polyc-v2-range.XXXXXX)
tmp_full=$(mktemp -t polyc-v2-range-full.XXXXXX)
tmp_kids=$(mktemp -t polyc-v2-range-kids.XXXXXX)
trap 'rm -f "$tmp_matches" "$tmp_full" "$tmp_kids"' EXIT

cur="$CLOSE"
while :; do
    parents=$(git rev-list --parents -n 1 "$cur" 2>/dev/null || true)
    parent=$(printf '%s' "$parents" | awk '{ print $2 }')
    if [ -z "$parent" ] || [ "$parent" = "$cur" ]; then
        printf '%s\n' "$cur" >> "$tmp_matches"
        break
    fi

    parent_act=$(git --no-pager log -1 --format='%(trailers:key=ACT,separator=@@@)' "$parent" 2>/dev/null || true)
    parent_act_count=$(printf '%s' "$parent_act" | tr '@@@' '\n' | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
    if [ "$parent_act_count" -ne 1 ]; then
        printf '%s\n' "$cur" >> "$tmp_matches"
        break
    fi

    printf '%s\n' "$cur" >> "$tmp_matches"
    cur="$parent"
done

matches=$(tail -r "$tmp_matches" 2>/dev/null || tac "$tmp_matches")
FIRST=$(printf '%s\n' "$matches" | head -n 1)
LAST=$(printf '%s\n' "$matches" | tail -n 1)

if [ "$LAST" != "$CLOSE" ]; then
    fail "range walk does not end at CLOSE (got $LAST)"
fi

if ! ENTRY=$(git rev-parse --verify "${FIRST}^" 2>/dev/null); then
    ENTRY="(root)"
fi

# Enumerate FIRST..CLOSE inclusive.
if ! git rev-list --reverse "${FIRST}^..${CLOSE}" > "$tmp_full" 2>/dev/null; then
    if ! git rev-list --reverse "${FIRST}..${CLOSE}" > "$tmp_full" 2>/dev/null; then
        fail "cannot enumerate ${FIRST}..${CLOSE}"
    fi
fi
commits_total=$(wc -l < "$tmp_full" | tr -d ' ')

# FIRST must be RED.
first_phase=$(git --no-pager log -1 --format='%(trailers:key=ACT-Phase,separator=@@@)' "$FIRST" 2>/dev/null | tr '@@@' '\n' | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
if [ "$first_phase" != "RED" ]; then
    fail "FIRST commit $FIRST has ACT-Phase='$first_phase', expected RED"
fi

# Exactly one CLOSE in range; CLOSE must be the last commit.
close_count=0
last_sha=""
while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    last_sha="$sha"
    p=$(git --no-pager log -1 --format='%(trailers:key=ACT-Phase,separator=@@@)' "$sha" 2>/dev/null | tr '@@@' '\n' | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
    if [ "$p" = "CLOSE" ]; then
        close_count=$((close_count + 1))
    fi
done < "$tmp_full"

if [ "$close_count" -ne 1 ]; then
    fail "expected exactly 1 CLOSE commit in range, found $close_count"
fi

if [ "$last_sha" != "$CLOSE" ]; then
    fail "CLOSE must be the last commit in range (last=$last_sha close=$CLOSE)"
fi

# Every commit must carry ACT=<id>, valid phase; no
# supersession trailers except on CLOSE.
while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    t=$(git --no-pager log -1 --format='%(trailers:key=ACT,key=ACT-Phase,key=ACT-Supersedes,key=ACT-Corrected-Verdict,separator=@@@)' "$sha" 2>/dev/null)
    act_in_sha=$(printf '%s' "$t" | tr '@@@' '\n' | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
    if [ "$act_in_sha" -ne 1 ]; then
        fail "commit $sha in range does not carry ACT: $ACT_ID"
    fi
    phase_in_sha=$(printf '%s' "$t" | tr '@@@' '\n' | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
    case "$phase_in_sha" in
        RED|IMPL|EVIDENCE|CLOSE)
            ;;
        *)
            fail "commit $sha in range has invalid ACT-Phase='$phase_in_sha'"
            ;;
    esac
    if [ "$sha" != "$CLOSE" ]; then
        sup=$(printf '%s' "$t" | tr '@@@' '\n' | grep -Ec '^ACT-Supersedes:' || true)
        cor=$(printf '%s' "$t" | tr '@@@' '\n' | grep -Ec '^ACT-Corrected-Verdict:' || true)
        if [ "$sup" -gt 0 ] || [ "$cor" -gt 0 ]; then
            fail "commit $sha in range carries supersession trailers; only CLOSE may"
        fi
    fi
done < "$tmp_full"

# No commit after CLOSE may carry ACT=<id>.
# `git rev-list --children` only emits a child's SHA on the
# line of its parent, so we walk the full reachable set and
# extract children of CLOSE specifically.
git rev-list --children --all > "$tmp_kids" 2>/dev/null || true
kids=$(awk -v c="$CLOSE" '$1 == c {
    for (i = 2; i <= NF; i++) print $i
}' "$tmp_kids" 2>/dev/null || true)
for kid in $kids; do
    [ -z "$kid" ] && continue
    kid_act=$(git --no-pager log -1 --format='%(trailers:key=ACT,separator=@@@)' "$kid" 2>/dev/null || true)
    kid_act_count=$(printf '%s' "$kid_act" | tr '@@@' '\n' | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
    if [ "$kid_act_count" -ge 1 ]; then
        fail "commit $kid after CLOSE still carries ACT: $ACT_ID; ACT must not continue past CLOSE"
    fi
done

echo "ACT=$ACT_ID"
echo "ENTRY=$ENTRY"
echo "FIRST=$FIRST"
echo "CLOSE=$CLOSE"
echo "COMMITS=$commits_total"
echo "VERDICT=$VERDICT_RAW"
echo "STATUS=PASS"
exit 0
