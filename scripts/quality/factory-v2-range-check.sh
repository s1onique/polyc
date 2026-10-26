#!/bin/sh
# scripts/quality/factory-v2-range-check.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01
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
# CORRECTION01 changes (vs SIMPLIFY01):
#   - replaced shell-glob `case` patterns for ACT id and
#     ACT-Verdict with `grep -Eq` against the documented
#     regex grammar;
#   - removed `gsub(/[[:space:]]+/, "_", $0)` from the
#     ACT-Verdict extraction so the literal trailer value
#     is what gets validated.
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
    "")
        fail "ACT id argument empty"
        ;;
esac
if ! printf '%s\n' "$ACT_ID" | grep -Eq '^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$'; then
    fail "ACT id '$ACT_ID' does not match regex ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+\$"
fi

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2 (Work package C).
#
# The range check used to read trailers through git's %(trailers)
# formatter. That formatter shares the underlying trailer parser with
# `git interpret-trailers --parse`, which REJECTS A WHOLE TRAILER BLOCK
# when ANY key in it contains an underscore. The canonical Factory keys
# HALT_CLASS and BLOCKS_NEXT therefore made a conforming HALT_* CLOSE
# commit unreadable: ACT:, ACT-Phase: and ACT-Verdict: all vanished.
#
# The range check now consumes the SAME normalized interpretation as the
# commit-message check, via the shared library
# scripts/quality/factory-v2-trailer-compat.inc, which BOTH validators
# source. The raw commit message is never mutated and no second trailer
# grammar is introduced.
#
# See docs/factory/GIT-METADATA.md section 2.5 for the binding contract.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/factory-v2-trailer-compat.inc"

CLOSE_TRAILERS=$(factory_trailer_parse_commit "$CLOSE")
if [ -z "$CLOSE_TRAILERS" ]; then
    # Fail closed: the CLOSE commit carries ACT-like metadata that could
    # not be parsed (typically a HALT_* CLOSE whose HALT_CLASS /
    # BLOCKS_NEXT keys made git drop the whole trailer block). It is NOT
    # a non-ACT commit and must not be silently accepted.
    _close_raw=$(mktemp -t polyc-v2-range-raw2.XXXXXX)
    factory_trailer_raw_commit "$CLOSE" > "$_close_raw"
    _like=$(factory_trailer_act_like_count "$_close_raw")
    rm -f "$_close_raw"
    if [ "$_like" -gt 0 ]; then
        fail "CLOSE $CLOSE carries ACT-like trailer metadata (count=$_like) but no parseable trailer block; footer is malformed or unparseable"
    fi
    fail "CLOSE $CLOSE carries no parseable Factory trailer block"
fi

close_act_count=$(printf '%s\n' "$CLOSE_TRAILERS" | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
if [ "$close_act_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT: $ACT_ID (count=$close_act_count)"
fi

close_phase_count=$(printf '%s\n' "$CLOSE_TRAILERS" | grep -Ec '^ACT-Phase:[[:space:]]+CLOSE$' || true)
if [ "$close_phase_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT-Phase: CLOSE (count=$close_phase_count)"
fi

close_verdict_count=$(printf '%s\n' "$CLOSE_TRAILERS" | grep -Ec '^ACT-Verdict:' || true)
if [ "$close_verdict_count" -ne 1 ]; then
    fail "CLOSE $CLOSE does not carry exactly one ACT-Verdict (count=$close_verdict_count)"
fi

VERDICT_RAW=$(printf '%s\n' "$CLOSE_TRAILERS" \
    | awk '/^ACT-Verdict:[[:space:]]+/ {
        sub(/^ACT-Verdict:[[:space:]]+/, "", $0)
        print
        exit
    }')

# CORRECTION01: literal trailer value (no underscore
# rewriting); regex match via grep -Eq, NOT shell glob.
if [ -z "$VERDICT_RAW" ]; then
    fail "CLOSE ACT-Verdict value empty"
fi
if ! printf '%s\n' "$VERDICT_RAW" \
        | grep -Eq '^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'; then
    fail "CLOSE ACT-Verdict '$VERDICT_RAW' does not match verdict grammar ^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)\$"
fi

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

    parent_trailers=$(factory_trailer_parse_commit "$parent")
    parent_act_count=$(printf '%s\n' "$parent_trailers" | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
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
first_phase=$(factory_trailer_parse_commit "$FIRST" | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
if [ "$first_phase" != "RED" ]; then
    fail "FIRST commit $FIRST has ACT-Phase='$first_phase', expected RED"
fi

# Exactly one CLOSE in range; CLOSE must be the last commit.
close_count=0
last_sha=""
while IFS= read -r sha; do
    [ -z "$sha" ] && continue
    last_sha="$sha"
    p=$(factory_trailer_parse_commit "$sha" | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
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
    t=$(factory_trailer_parse_commit "$sha")
    act_in_sha=$(printf '%s\n' "$t" | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
    if [ "$act_in_sha" -ne 1 ]; then
        fail "commit $sha in range does not carry ACT: $ACT_ID"
    fi
    phase_in_sha=$(printf '%s\n' "$t" | awk -F': ' '/^ACT-Phase:/ { print $2; exit }')
    case "$phase_in_sha" in
        RED|IMPL|EVIDENCE|CLOSE)
            ;;
        *)
            fail "commit $sha in range has invalid ACT-Phase='$phase_in_sha'"
            ;;
    esac
    if [ "$sha" != "$CLOSE" ]; then
        sup=$(printf '%s\n' "$t" | grep -Ec '^ACT-Supersedes:' || true)
        cor=$(printf '%s\n' "$t" | grep -Ec '^ACT-Corrected-Verdict:' || true)
        if [ "$sup" -gt 0 ] || [ "$cor" -gt 0 ]; then
            fail "commit $sha in range carries supersession trailers; only CLOSE may"
        fi
    fi
done < "$tmp_full"

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2 (Work package C).
#
# No commit after CLOSE may carry ACT=<id>.
#
# The previous implementation enumerated only the DIRECT CHILDREN of
# CLOSE (`git rev-list --children`). That let a same-ACT continuation
# ESCAPE detection whenever an ordinary commit (one carrying no ACT
# trailer) sat between CLOSE and the continuation, because the ordinary
# commit is the direct child and the continuation is a grandchild.
# Measured at C1: CLOSE -> ordinary commit -> same-ACT IMPL was
# ACCEPTED with rc=0 STATUS=PASS.
#
# The rule is about the whole DESCENDANT PATH of CLOSE, so the check now
# walks every commit reachable from CLOSE (excluding CLOSE itself) and
# rejects any of them that carries ACT:<id>.
#
# The walk is restricted to commits that DESCEND FROM CLOSE. Commits that
# merely exist in the repository (other branches, or unrelated history
# reachable by other parents) are not descendants of CLOSE and are not
# affected by this ACT's closure.
tmp_desc=$(mktemp -t polyc-v2-range-desc.XXXXXX)
tmp_kids2=$(mktemp -t polyc-v2-range-kids2.XXXXXX)
# Enumerate CLOSE's DESCENDANTS by walking the child relation forward.
#
# `git rev-list --children` emits, for each commit, its own SHA followed
# by the SHAs of its children. Starting at CLOSE and following the child
# edges forward yields exactly the commits that descend from CLOSE.
# Walking forward (rather than reading only the direct children) is what
# catches a continuation hidden behind an intervening ordinary commit.
git rev-list --children --all > "$tmp_kids2" 2>/dev/null || true
awk -v start="$CLOSE" '
    { line[NR] = $0; n = NR }
    END {
        # build a map: parent -> list of children
        for (i = 1; i <= n; i++) {
            split(line[i], f, " ")
            for (j = 2; j <= length(f); j++) {
                kids[f[1]] = kids[f[1]] " " f[j]
            }
        }
        q[1] = start
        head = 1; tail = 1
        while (head <= tail) {
            c = q[head++]
            m = split(kids[c], arr, " ")
            for (i = 1; i <= m; i++) {
                if (arr[i] == "") continue
                if (seen[arr[i]]) continue
                seen[arr[i]] = 1
                q[++tail] = arr[i]
            }
        }
        for (i = 1; i <= tail; i++) {
            if (q[i] == start) continue
            print q[i]
        }
    }
' "$tmp_kids2" > "$tmp_desc" 2>/dev/null || true

# CLOSE itself is not a continuation of itself.
grep -v "^${CLOSE}\$" "$tmp_desc" > "$tmp_desc.filtered" 2>/dev/null || true
mv "$tmp_desc.filtered" "$tmp_desc"
while IFS= read -r kid; do
    [ -z "$kid" ] && continue
    kid_trailers=$(factory_trailer_parse_commit "$kid")
    kid_act_count=$(printf '%s\n' "$kid_trailers" | grep -Ec "^ACT:[[:space:]]+${ACT_ID}\$" || true)
    if [ "$kid_act_count" -ge 1 ]; then
        fail "commit $kid after CLOSE still carries ACT: $ACT_ID; ACT must not continue past CLOSE"
    fi
done < "$tmp_desc"

echo "ACT=$ACT_ID"
echo "ENTRY=$ENTRY"
echo "FIRST=$FIRST"
echo "CLOSE=$CLOSE"
echo "COMMITS=$commits_total"
echo "VERDICT=$VERDICT_RAW"
echo "STATUS=PASS"
exit 0
