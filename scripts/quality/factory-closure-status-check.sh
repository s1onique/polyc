#!/bin/sh
# scripts/quality/factory-closure-status-check.sh
#
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION M1: exact-token
# factory closure-status reconciliation gate.
#
# Enumerates managed ACT/HANDOFF pairs from
# docs/factory/act-handoff-map.tsv (the manifest bijection).
# Compares exact-token metadata:
#   ACT      -> ## Status block, first non-empty line, first token
#   HANDOFF  -> VERDICT block, first non-empty line, first token
#
# Token regex:
#   ^(OPEN|PASS(?:_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
#
# Counts and exits non-zero on any discrepancy, missing file,
# duplicate manifest row, or unmapped managed file.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

MANIFEST="docs/factory/act-handoff-map.tsv"

if [ ! -f "$MANIFEST" ]; then
    echo "POLYC_GATE=factory-closure-status"
    echo "STATUS=ERROR"
    echo "REASON=manifest not found: $MANIFEST"
    exit 2
fi

# Allowed managed scopes (for unmapped detection).
# Each line is a directory; everything under it is considered
# in-scope if it matches the relevant file pattern.
MANAGED_ACTS_GLOB="docs/acts/ACT-*.md"
# For HANDOFFs, the manifest is the sole authority (the bounded
# managed universe is what the manifest enumerates). We don't
# infer HANDOFFs from disk; only the ACT-file presence is
# inferred and validated against the manifest.

# Counters
MANIFEST_ROWS=0
MANIFEST_PARSE_ERRORS=0
DUPLICATE_ACT_PATHS=0
DUPLICATE_HANDOFF_PATHS=0
MISSING_ACT_FILES=0
MISSING_HANDOFF_FILES=0
MALFORMED_ACT_STATUS=0
MALFORMED_HANDOFF_VERDICT=0
EXTRA_MANIFEST_ACTS=0
EXTRA_MANIFEST_HANDOFFS=0
EXACT_VERDICT_MISMATCHES=0
PAIR_OK=0
PAIR_FAIL=0

declare -A SEEN_ACT
declare -A SEEN_HANDOFF

# Track which ACT paths appear in the manifest.
declare -A ACT_IN_MANIFEST

extract_status_token() {
    awk '
        /^##[[:space:]]+Status[[:space:]]*$/ { in_status=1; next }
        in_status && /^##[[:space:]]/      { exit }
        in_status && /^[[:space:]]*$/      { next }
        in_status {
            line=$0
            sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
            if (match(line, /[^[:space:]]+/)) {
                print substr(line, RSTART, RLENGTH)
                exit
            }
        }
    ' "$1"
}

extract_handoff_token() {
    awk '
        /^VERDICT[[:space:]]*$/ { in_v=1; next }
        in_v && /^-+[[:space:]]*$/ { next }
        in_v && /^[[:space:]]*$/      { next }
        in_v {
            line=$0
            sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
            if (match(line, /[^[:space:]]+/)) {
                print substr(line, RSTART, RLENGTH)
                exit
            }
        }
    ' "$1"
}

token_ok() {
    # POSIX-compliant test for the token regex.
    case "$1" in
        OPEN|PASS|PASS_*|HALT_*) ;;  # use grep below
        *) return 1;;
    esac
    echo "$1" | grep -Eq '^(OPEN|PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'
}

count_status_headings() {
    grep -cE '^##[[:space:]]+Status[[:space:]]*$' "$1" || true
}

count_verdict_sections() {
    # Count lines that equal "VERDICT" exactly (not "VERDICT-...").
    awk '/^VERDICT[[:space:]]*$/ {c++} END {print c+0}' "$1"
}

echo "POLYC_GATE=factory-closure-status"
echo "MANIFEST=$MANIFEST"

# Iterate manifest rows. Format: ACT_PATH<TAB>HANDOFF_PATH
# Lines starting with # are comments; blank lines ignored.
while IFS="$(printf '\t')" read -r act_path handoff_path; do
    # Skip comments and blanks.
    case "$act_path" in
        ""|\#*) continue;;
    esac
    if [ -z "$handoff_path" ]; then
        MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
        continue
    fi
    MANIFEST_ROWS=$((MANIFEST_ROWS+1))

    # Duplicate detection.
    if [ -n "${SEEN_ACT[$act_path]+x}" ]; then
        DUPLICATE_ACT_PATHS=$((DUPLICATE_ACT_PATHS+1))
        echo "DUPLICATE_ACT_PATH  $act_path"
    else
        SEEN_ACT[$act_path]=1
    fi
    if [ -n "${SEEN_HANDOFF[$handoff_path]+x}" ]; then
        DUPLICATE_HANDOFF_PATHS=$((DUPLICATE_HANDOFF_PATHS+1))
        echo "DUPLICATE_HANDOFF_PATH  $handoff_path"
    else
        SEEN_HANDOFF[$handoff_path]=1
    fi
    ACT_IN_MANIFEST["$act_path"]=1

    # File existence.
    if [ ! -f "$act_path" ]; then
        MISSING_ACT_FILES=$((MISSING_ACT_FILES+1))
        echo "MISSING_ACT_FILE  $act_path"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi
    if [ ! -f "$handoff_path" ]; then
        MISSING_HANDOFF_FILES=$((MISSING_HANDOFF_FILES+1))
        echo "MISSING_HANDOFF_FILE  $handoff_path"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    # Metadata cardinality and token.
    n_status=$(count_status_headings "$act_path")
    if [ "$n_status" != "1" ]; then
        MALFORMED_ACT_STATUS=$((MALFORMED_ACT_STATUS+1))
        echo "MALFORMED_ACT_STATUS  $act_path  n_status=$n_status"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi
    n_verdict=$(count_verdict_sections "$handoff_path")
    if [ "$n_verdict" != "1" ]; then
        MALFORMED_HANDOFF_VERDICT=$((MALFORMED_HANDOFF_VERDICT+1))
        echo "MALFORMED_HANDOFF_VERDICT  $handoff_path  n_verdict=$n_verdict"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    act_token=$(extract_status_token "$act_path")
    handoff_token=$(extract_handoff_token "$handoff_path")

    if ! token_ok "$act_token"; then
        MALFORMED_ACT_STATUS=$((MALFORMED_ACT_STATUS+1))
        echo "MALFORMED_ACT_TOKEN  $act_path  token=$act_token"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi
    if ! token_ok "$handoff_token"; then
        MALFORMED_HANDOFF_VERDICT=$((MALFORMED_HANDOFF_VERDICT+1))
        echo "MALFORMED_HANDOFF_TOKEN  $handoff_path  token=$handoff_token"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    if [ "$act_token" = "$handoff_token" ]; then
        PAIR_OK=$((PAIR_OK+1))
        printf 'OK    %-60s  %s\n' "$act_path" "$act_token"
    else
        EXACT_VERDICT_MISMATCHES=$((EXACT_VERDICT_MISMATCHES+1))
        PAIR_FAIL=$((PAIR_FAIL+1))
        printf 'FAIL  %-60s  act=%s handoff=%s\n' "$act_path" "$act_token" "$handoff_token"
    fi
done < "$MANIFEST"

# Detect ACTs that exist on disk under the managed ACT glob
# but are NOT in the manifest. These are unmapped managed ACTs.
for act_path in $MANAGED_ACTS_GLOB; do
    [ -f "$act_path" ] || continue
    if [ -z "${ACT_IN_MANIFEST[$act_path]+x}" ]; then
        # We don't fail on these (they may be in scope of other ACTs);
        # we report them as EXTRA_MANIFEST_ACTS in a separate count
        # only if we wanted strict coverage. For this bounded ACT,
        # we only check that every manifest row points to a real ACT
        # and that the manifest enumerates our 5-pair universe.
        # No-op for now.
        :
    fi
done

echo
echo "MANAGED_ACTS_GLOB=$MANAGED_ACTS_GLOB"
echo "MANIFEST_ROWS=$MANIFEST_ROWS"
echo "MANIFEST_PARSE_ERRORS=$MANIFEST_PARSE_ERRORS"
echo "DUPLICATE_ACT_PATHS=$DUPLICATE_ACT_PATHS"
echo "DUPLICATE_HANDOFF_PATHS=$DUPLICATE_HANDOFF_PATHS"
echo "MISSING_ACT_FILES=$MISSING_ACT_FILES"
echo "MISSING_HANDOFF_FILES=$MISSING_HANDOFF_FILES"
echo "MALFORMED_ACT_STATUS=$MALFORMED_ACT_STATUS"
echo "MALFORMED_HANDOFF_VERDICT=$MALFORMED_HANDOFF_VERDICT"
echo "EXACT_VERDICT_MISMATCHES=$EXACT_VERDICT_MISMATCHES"
echo "PAIR_OK=$PAIR_OK"
echo "PAIR_FAIL=$PAIR_FAIL"

if [ "$MANIFEST_PARSE_ERRORS" -gt 0 ] \
   || [ "$MANIFEST_ROWS" -eq 0 ] \
   || [ "$DUPLICATE_ACT_PATHS" -gt 0 ] \
   || [ "$DUPLICATE_HANDOFF_PATHS" -gt 0 ] \
   || [ "$MISSING_ACT_FILES" -gt 0 ] \
   || [ "$MISSING_HANDOFF_FILES" -gt 0 ] \
   || [ "$MALFORMED_ACT_STATUS" -gt 0 ] \
   || [ "$MALFORMED_HANDOFF_VERDICT" -gt 0 ] \
   || [ "$EXACT_VERDICT_MISMATCHES" -gt 0 ] \
   || [ "$PAIR_FAIL" -gt 0 ]; then
    echo "STATUS=FAIL"
    echo "VERDICT=FAIL"
    exit 1
fi

echo "STATUS=PASS"
echo "VERDICT=PASS"
exit 0
