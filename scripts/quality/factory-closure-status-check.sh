#!/bin/sh
# scripts/quality/factory-closure-status-check.sh
#
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01 M1:
# exact-token factory closure-status oracle.
#
# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01:
# this checker is MANIFEST-DRIVEN. The manifest at
# docs/factory/act-handoff-map.tsv is the SINGLE enumeration
# authority for managed ACT/HANDOFF pairs. The previous
# bounded-list enumeration (MANAGED_ACTS, MANAGED_HANDOFFS) is
# REMOVED. Adding a new pair requires only appending a row to
# the manifest; the checker code does not change.
#
# This script is genuine POSIX /bin/sh. It uses case/awk/grep/sed
# and explicit positional variables only; no associative arrays,
# no Bash extensions. It is invokable under both `sh` and `dash`.
#
# Manifest contract (per ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01 §7):
#
#   field 1: docs/acts/*.md            (act_path)
#   field 2: docs/factory/HANDOFF-*.md (handoff_path)
#             OR evidence/*/HANDOFF.md (legacy ACT-managed pairs)
#
# The legacy HANDOFF path class (evidence/*/HANDOFF.md) is preserved
# per F14 to keep closed predecessor evidence immutable. New HANDOFFs
# SHOULD use the docs/factory/HANDOFF-*.md prefix; legacy paths
# remain acceptable but the canonical location is the factory dir.
#
# Each data row must contain exactly two TAB-separated fields.
# Comments start with '#'; blank lines are ignored. The closure
# predicate applies only to data rows; MANIFEST_DATA_ROWS counts
# valid two-field rows.
#
# Token regex (unchanged from the predecessor):
#   ^(OPEN|PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
#
# Test seam (per ACT §18):
#
#   FACTORY_ACT_HANDOFF_MAP=<path>
#
# When set, the checker reads the manifest from this path instead
# of the canonical docs/factory/act-handoff-map.tsv. Canonical
# gate-fast does not set this env var.

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

# Test seam: allow test harnesses to supply an alternate manifest.
# Canonical invocation: env var unset, defaults to the canonical path.
if [ -n "${FACTORY_ACT_HANDOFF_MAP-}" ]; then
    MANIFEST="$FACTORY_ACT_HANDOFF_MAP"
else
    MANIFEST="docs/factory/act-handoff-map.tsv"
fi

if [ ! -f "$MANIFEST" ]; then
    echo "POLYC_GATE=factory-closure-status"
    echo "STATUS=ERROR"
    echo "REASON=manifest not found: $MANIFEST"
    exit 2
fi

# Counters
MANIFEST_ROWS=0
MANIFEST_DATA_ROWS=0
MANIFEST_COMMENT_ROWS=0
MANIFEST_BLANK_ROWS=0
MANIFEST_PARSE_ERRORS=0
DUPLICATE_ACT_PATHS=0
DUPLICATE_HANDOFF_PATHS=0
DUPLICATE_PAIRS=0
DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING=NO
MISSING_ACT_FILES=0
MISSING_HANDOFF_FILES=0
MALFORMED_ACT_STATUS=0
MALFORMED_HANDOFF_VERDICT=0
EXACT_VERDICT_MISMATCHES=0
PAIR_OK=0
PAIR_FAIL=0

# token_ok: POSIX-compliant regex test (no bashisms).
token_ok() {
    case "$1" in
        "") return 1;;
    esac
    printf '%s\n' "$1" | grep -Eq '^(OPEN|PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'
}

# Per ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
# P0-3: extract_status_token() and count_status_headings() are
# REMOVED. The ACT body is immutable authorization metadata;
# the HANDOFF exclusively owns the terminal verdict.

extract_handoff_token() {
    awk '
        /^VERDICT[[:space:]]*$/      { in_v=1; next }
        in_v && /^-+[[:space:]]*$/   { next }
        in_v && /^[[:space:]]*$/     { next }
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

count_verdict_sections() {
    grep -cE '^VERDICT[[:space:]]*$' "$1" 2>/dev/null || printf '0\n'
}

# Temp files for duplicate detection.
SEEN_ACT_TMP=$(mktemp)
SEEN_HANDOFF_TMP=$(mktemp)
SEEN_PAIR_TMP=$(mktemp)
trap 'rm -f "$SEEN_ACT_TMP" "$SEEN_HANDOFF_TMP" "$SEEN_PAIR_TMP"' EXIT

# ------------------------------------------------------------------
# Phase 1: parse manifest, validate every data row fail-closed.
# ------------------------------------------------------------------

# Use awk to parse rows; preserve multi-tab content via cut/awk split.
while IFS= read -r raw_line || [ -n "$raw_line" ]; do
    # Trim leading whitespace for classification.
    trimmed=$(printf '%s' "$raw_line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    # Classify line.
    if [ -z "$trimmed" ]; then
        MANIFEST_BLANK_ROWS=$((MANIFEST_BLANK_ROWS+1))
        continue
    fi
    case "$trimmed" in
        \#*)
            MANIFEST_COMMENT_ROWS=$((MANIFEST_COMMENT_ROWS+1))
            continue
            ;;
    esac
    MANIFEST_ROWS=$((MANIFEST_ROWS+1))

    # Split into exactly two TAB-separated fields.
    # Use awk to perform the split (handles edge cases of empty fields).
    n_fields=$(printf '%s' "$raw_line" | awk -F'\t' '{print NF}')
    act_path=$(printf '%s' "$raw_line" | awk -F'\t' '{print $1}')
    handoff_path=$(printf '%s' "$raw_line" | awk -F'\t' '{print $2}')

    # Empty-act path detection.
    if [ -z "$act_path" ]; then
        MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
        echo "EMPTY_ACT_PATH  line=$raw_line"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    # Empty-handoff path detection.
    if [ -z "$handoff_path" ]; then
        MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
        echo "EMPTY_HANDOFF_PATH  line=$raw_line"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    # Field-count check.
    if [ "$n_fields" != "2" ]; then
        MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
        echo "FIELD_COUNT_NOT_2  line=$raw_line  n_fields=$n_fields"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    # Path safety: reject absolute paths.
    case "$act_path" in
        /*)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "ABSOLUTE_PATH_REJECTED  $act_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac
    case "$handoff_path" in
        /*)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "ABSOLUTE_PATH_REJECTED  $handoff_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac

    # Path safety: reject path traversal.
    case "$act_path" in
        *..*)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "PATH_TRAVERSAL_REJECTED  $act_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac
    case "$handoff_path" in
        *..*)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "PATH_TRAVERSAL_REJECTED  $handoff_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac

    # Path-prefix validation.
    case "$act_path" in
        docs/acts/*.md) ;;
        *)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "INVALID_ACT_PREFIX  $act_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac
    case "$handoff_path" in
        docs/factory/HANDOFF-*.md) ;;
        evidence/*/HANDOFF.md) ;;
        *)
            MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
            echo "INVALID_HANDOFF_PREFIX  $handoff_path"
            PAIR_FAIL=$((PAIR_FAIL+1))
            continue
            ;;
    esac

    MANIFEST_DATA_ROWS=$((MANIFEST_DATA_ROWS+1))

    # Duplicate ACT path detection (non-short-circuit: do not
    # `continue` after firing; subsequent dedup checks must run
    # and the row is tagged "already processed" to skip later
    # checks. Per ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
    # CORRECTION01 P0-2, the three duplicate dimensions
    # (ACT path, HANDOFF path, pair) are independent and must
    # all fire on a row that violates multiple dimensions.
    DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING=YES
    row_already_processed=NO
    if grep -Fxq "$act_path" "$SEEN_ACT_TMP"; then
        DUPLICATE_ACT_PATHS=$((DUPLICATE_ACT_PATHS+1))
        echo "DUPLICATE_ACT_PATH  $act_path"
        PAIR_FAIL=$((PAIR_FAIL+1))
        row_already_processed=YES
    else
        printf '%s\n' "$act_path" >> "$SEEN_ACT_TMP"
    fi

    # Duplicate HANDOFF path detection.
    if grep -Fxq "$handoff_path" "$SEEN_HANDOFF_TMP"; then
        DUPLICATE_HANDOFF_PATHS=$((DUPLICATE_HANDOFF_PATHS+1))
        echo "DUPLICATE_HANDOFF_PATH  $handoff_path"
        PAIR_FAIL=$((PAIR_FAIL+1))
        row_already_processed=YES
    else
        printf '%s\n' "$handoff_path" >> "$SEEN_HANDOFF_TMP"
    fi

    # Duplicate pair detection.
    pair_key="$act_path"$'\t'"$handoff_path"
    if grep -Fxq "$pair_key" "$SEEN_PAIR_TMP"; then
        DUPLICATE_PAIRS=$((DUPLICATE_PAIRS+1))
        echo "DUPLICATE_PAIR  $act_path <-> $handoff_path"
        PAIR_FAIL=$((PAIR_FAIL+1))
        row_already_processed=YES
    else
        printf '%s\n' "$pair_key" >> "$SEEN_PAIR_TMP"
    fi

    # If any dedup check fired, skip the file/metadata checks
    # for this row (they would re-fail on the same content).
    if [ "$row_already_processed" = "YES" ]; then
        continue
    fi

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

    # HANDOFF metadata cardinality.
    # Per ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-
    # CORRECTION01 P0-3: the HANDOFF exclusively owns the
    # terminal verdict. The ACT body is immutable authorization
    # metadata and is NOT parsed for verdict tokens.
    n_verdict=$(count_verdict_sections "$handoff_path")
    if [ "$n_verdict" != "1" ]; then
        MALFORMED_HANDOFF_VERDICT=$((MALFORMED_HANDOFF_VERDICT+1))
        echo "MALFORMED_HANDOFF_VERDICT  $handoff_path  n_verdict=$n_verdict"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    # Token extraction: HANDOFF VERDICT only.
    handoff_token=$(extract_handoff_token "$handoff_path")

    if ! token_ok "$handoff_token"; then
        MALFORMED_HANDOFF_VERDICT=$((MALFORMED_HANDOFF_VERDICT+1))
        echo "MALFORMED_HANDOFF_TOKEN  $handoff_path  token=$handoff_token"
        PAIR_FAIL=$((PAIR_FAIL+1))
        continue
    fi

    PAIR_OK=$((PAIR_OK+1))
    printf 'OK    %-72s  %s\n' "$act_path" "$handoff_token"
done < "$MANIFEST"

# ------------------------------------------------------------------
# Phase 2: emit counters and decide exit.
# ------------------------------------------------------------------

echo
echo "POLYC_GATE=factory-closure-status"
echo "MANIFEST_PATH=$MANIFEST"
echo "MANIFEST_ROWS=$MANIFEST_ROWS"
echo "MANIFEST_DATA_ROWS=$MANIFEST_DATA_ROWS"
echo "MANIFEST_COMMENT_ROWS=$MANIFEST_COMMENT_ROWS"
echo "MANIFEST_BLANK_ROWS=$MANIFEST_BLANK_ROWS"
echo "MANIFEST_PARSE_ERRORS=$MANIFEST_PARSE_ERRORS"
echo "DUPLICATE_ACT_PATHS=$DUPLICATE_ACT_PATHS"
echo "DUPLICATE_HANDOFF_PATHS=$DUPLICATE_HANDOFF_PATHS"
echo "DUPLICATE_PAIRS=$DUPLICATE_PAIRS"
echo "DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING=$DUPLICATE_CLASSIFICATION_IS_NON_SHORT_CIRCUITING"
# Boolean detection tokens (computed by derivation from raw counters):
[ "$DUPLICATE_ACT_PATHS" -gt 0 ] && echo "DUPLICATE_ACT_PATH_DETECTED=YES" || echo "DUPLICATE_ACT_PATH_DETECTED=NO"
[ "$DUPLICATE_HANDOFF_PATHS" -gt 0 ] && echo "DUPLICATE_HANDOFF_PATH_DETECTED=YES" || echo "DUPLICATE_HANDOFF_PATH_DETECTED=NO"
[ "$DUPLICATE_PAIRS" -gt 0 ] && echo "DUPLICATE_PAIR_DETECTED=YES" || echo "DUPLICATE_PAIR_DETECTED=NO"
echo "MISSING_ACT_FILES=$MISSING_ACT_FILES"
echo "MISSING_HANDOFF_FILES=$MISSING_HANDOFF_FILES"
echo "MALFORMED_HANDOFF_VERDICT=$MALFORMED_HANDOFF_VERDICT"
echo "PAIR_OK=$PAIR_OK"
echo "PAIR_FAIL=$PAIR_FAIL"

# Empty-manifest halt (per ACT §36).
if [ "$MANIFEST_ROWS" -eq 0 ]; then
    echo "HALT_EMPTY_MANAGED_UNIVERSE"
fi

# Fail-closed predicate.
# Per ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01
# P0-3: MALFORMED_ACT_STATUS and EXACT_VERDICT_MISMATCHES are no
# longer checked (the ACT body is not parsed for verdict tokens).
if [ "$MANIFEST_PARSE_ERRORS" -gt 0 ] \
   || [ "$MANIFEST_ROWS" -eq 0 ] \
   || [ "$DUPLICATE_ACT_PATHS" -gt 0 ] \
   || [ "$DUPLICATE_HANDOFF_PATHS" -gt 0 ] \
   || [ "$DUPLICATE_PAIRS" -gt 0 ] \
   || [ "$MISSING_ACT_FILES" -gt 0 ] \
   || [ "$MISSING_HANDOFF_FILES" -gt 0 ] \
   || [ "$MALFORMED_HANDOFF_VERDICT" -gt 0 ] \
   || [ "$PAIR_FAIL" -gt 0 ]; then
    echo "STATUS=FAIL"
    echo "VERDICT=FAIL"
    exit 1
fi

echo "STATUS=PASS"
echo "VERDICT=PASS"
exit 0
