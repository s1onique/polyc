#!/bin/sh
# scripts/quality/factory-closure-status-check.sh
#
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01 M1:
# exact-token factory closure-status oracle with independent
# bidirectional completeness against the bounded managed universe.
#
# This script is genuine POSIX /bin/sh. It uses case/awk/grep/sed
# and explicit positional variables only; no associative arrays,
# no Bash extensions. It is invokable under both `sh` and `dash`.
#
# Bounded managed universe (authoritative; named in the ACT):
#
#   MANAGED_ACTS     = 5  hard-coded list
#   MANAGED_HANDOFFS = 5  hard-coded list
#
# The manifest (docs/factory/act-handoff-map.tsv) is the pairing
# map. The checker enumerates the manifest AND the bounded managed
# universe independently, then computes four set differences:
#
#   UNMAPPED_MANAGED_ACTS      = MANAGED_ACTS     \ MANIFEST_ACTS
#   UNMAPPED_MANAGED_HANDOFFS  = MANAGED_HANDOFFS \ MANIFEST_HANDOFFS
#   EXTRA_MANIFEST_ACTS        = MANIFEST_ACTS     \ MANAGED_ACTS
#   EXTRA_MANIFEST_HANDOFFS    = MANIFEST_HANDOFFS \ MANAGED_HANDOFFS
#
# Any non-zero value in those four counters, plus any of the
# previously-bound counters (DUPLICATE_*, MISSING_*, MALFORMED_*,
# EXACT_VERDICT_MISMATCHES), plus MANIFEST_ROWS=0, plus a manifest
# parse failure, all cause exit 1 with STATUS=FAIL.
#
# Token regex (unchanged from the predecessor):
#   ^(OPEN|PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$

set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)
cd "$REPO_ROOT"

MANIFEST="docs/factory/act-handoff-map.tsv"

# Bounded managed universe (R1: independent enumeration, hard-coded).
MANAGED_ACTS="
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION01.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION02.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION03.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION04.md
docs/acts/ACT-POLYC-LLVM-CORE03-CORRECTION05.md
"
MANAGED_HANDOFFS="
evidence/llvmspike01-core03-correction01/HANDOFF.md
evidence/llvmspike01-core03-correction02/HANDOFF.md
evidence/llvmspike01-core03-correction03/HANDOFF.md
evidence/llvmspike01-core03-correction04/HANDOFF.md
evidence/llvmspike01-core03-correction05/HANDOFF.md
"

if [ ! -f "$MANIFEST" ]; then
    echo "POLYC_GATE=factory-closure-status"
    echo "STATUS=ERROR"
    echo "REASON=manifest not found: $MANIFEST"
    exit 2
fi

# Counters
MANAGED_ACTS_COUNT=0
MANAGED_HANDOFFS_COUNT=0
MANIFEST_ROWS=0
MANIFEST_PARSE_ERRORS=0
DUPLICATE_ACT_PATHS=0
DUPLICATE_HANDOFF_PATHS=0
MISSING_ACT_FILES=0
MISSING_HANDOFF_FILES=0
MALFORMED_ACT_STATUS=0
MALFORMED_HANDOFF_VERDICT=0
EXACT_VERDICT_MISMATCHES=0
UNMAPPED_MANAGED_ACTS=0
UNMAPPED_MANAGED_HANDOFFS=0
EXTRA_MANIFEST_ACTS=0
EXTRA_MANIFEST_HANDOFFS=0
PAIR_OK=0
PAIR_FAIL=0

# Strip leading whitespace and blank lines from a here-doc list.
strip_list() {
    printf '%s\n' "$1" | sed -e 's/^[[:space:]]*//' -e '/^$/d'
}

# token_ok: POSIX-compliant regex test (no bashisms).
token_ok() {
    case "$1" in
        "") return 1;;
    esac
    printf '%s\n' "$1" | grep -Eq '^(OPEN|PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'
}

extract_status_token() {
    awk '
        /^##[[:space:]]+Status[[:space:]]*$/ { in_status=1; next }
        in_status && /^##[[:space:]]/        { exit }
        in_status && /^[[:space:]]*$/        { next }
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

count_status_headings() {
    grep -cE '^##[[:space:]]+Status[[:space:]]*$' "$1" 2>/dev/null || printf '0\n'
}

count_verdict_sections() {
    # Count lines that equal "VERDICT" exactly.
    grep -cE '^VERDICT[[:space:]]*$' "$1" 2>/dev/null || printf '0\n'
}

# Count a clean list and store into the named variable.
count_clean_lines() {
    printf '%s\n' "$1" | sed -e 's/^[[:space:]]*//' -e '/^$/d' | wc -l | tr -d ' '
}

# Build a clean newline-separated list to a temp file.
list_to_tmp() {
    TMP=$(mktemp)
    printf '%s\n' "$1" | sed -e 's/^[[:space:]]*//' -e '/^$/d' > "$TMP"
    printf '%s\n' "$TMP"
}

# ------------------------------------------------------------------
# Phase 1: parse manifest, detect duplicates, missing files,
# malformed metadata, exact-token mismatches. Also write the
# set of manifest ACT paths and manifest HANDOFF paths to a temp
# file each for later set-difference computation.
# ------------------------------------------------------------------

MANIFEST_ACTS_TMP=$(mktemp)
MANIFEST_HANDOFFS_TMP=$(mktemp)
SEEN_ACT_TMP=$(mktemp)
SEEN_HANDOFF_TMP=$(mktemp)
trap 'rm -f "$MANIFEST_ACTS_TMP" "$MANIFEST_HANDOFFS_TMP" "$SEEN_ACT_TMP" "$SEEN_HANDOFF_TMP"' EXIT

# Parse manifest line-by-line (no associative arrays).
while IFS="$(printf '\t')" read -r act_path handoff_path; do
    # Skip comments and blanks.
    case "$act_path" in
        ""|\#*) continue ;;
    esac
    if [ -z "$handoff_path" ]; then
        MANIFEST_PARSE_ERRORS=$((MANIFEST_PARSE_ERRORS+1))
        echo "MANIFEST_PARSE_ERROR  line=$act_path  reason=missing_handoff"
        continue
    fi
    MANIFEST_ROWS=$((MANIFEST_ROWS+1))
    printf '%s\n' "$act_path"     >> "$MANIFEST_ACTS_TMP"
    printf '%s\n' "$handoff_path" >> "$MANIFEST_HANDOFFS_TMP"

    # Duplicate detection (R-pre: already required by predecessor ACT).
    if grep -Fxq "$act_path" "$SEEN_ACT_TMP"; then
        DUPLICATE_ACT_PATHS=$((DUPLICATE_ACT_PATHS+1))
        echo "DUPLICATE_ACT_PATH  $act_path"
    else
        printf '%s\n' "$act_path" >> "$SEEN_ACT_TMP"
    fi
    if grep -Fxq "$handoff_path" "$SEEN_HANDOFF_TMP"; then
        DUPLICATE_HANDOFF_PATHS=$((DUPLICATE_HANDOFF_PATHS+1))
        echo "DUPLICATE_HANDOFF_PATH  $handoff_path"
    else
        printf '%s\n' "$handoff_path" >> "$SEEN_HANDOFF_TMP"
    fi

    # File presence.
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

    # Metadata cardinality.
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

    # Token extraction and exact-token equality.
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

# ------------------------------------------------------------------
# Phase 2: independent managed-universe completeness (R1+R2).
# Compute four set-difference counters:
#   UNMAPPED_MANAGED_ACTS      = MANAGED_ACTS     \ MANIFEST_ACTS
#   UNMAPPED_MANAGED_HANDOFFS  = MANAGED_HANDOFFS \ MANIFEST_HANDOFFS
#   EXTRA_MANIFEST_ACTS        = MANIFEST_ACTS     \ MANAGED_ACTS
#   EXTRA_MANIFEST_HANDOFFS    = MANAGIFEST_HANDOFFS \ MANAGED_HANDOFFS
# ------------------------------------------------------------------

MANAGED_ACTS_TMP=$(list_to_tmp "$MANAGED_ACTS")
MANAGED_HANDOFFS_TMP=$(list_to_tmp "$MANAGED_HANDOFFS")
trap 'rm -f "$MANIFEST_ACTS_TMP" "$MANIFEST_HANDOFFS_TMP" "$SEEN_ACT_TMP" "$SEEN_HANDOFF_TMP" "$MANAGED_ACTS_TMP" "$MANAGED_HANDOFFS_TMP"' EXIT

MANAGED_ACTS_COUNT=$(count_clean_lines "$MANAGED_ACTS")
MANAGED_HANDOFFS_COUNT=$(count_clean_lines "$MANAGED_HANDOFFS")

# UNMAPPED_MANAGED_ACTS: managed ACTs not in manifest.
while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! grep -Fxq "$path" "$MANIFEST_ACTS_TMP"; then
        UNMAPPED_MANAGED_ACTS=$((UNMAPPED_MANAGED_ACTS+1))
        echo "UNMAPPED_MANAGED_ACT  $path"
    fi
done < "$MANAGED_ACTS_TMP"

# UNMAPPED_MANAGED_HANDOFFS: managed HANDOFFs not in manifest.
while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! grep -Fxq "$path" "$MANIFEST_HANDOFFS_TMP"; then
        UNMAPPED_MANAGED_HANDOFFS=$((UNMAPPED_MANAGED_HANDOFFS+1))
        echo "UNMAPPED_MANAGED_HANDOFF  $path"
    fi
done < "$MANAGED_HANDOFFS_TMP"

# EXTRA_MANIFEST_ACTS: manifest ACTs not in managed universe.
while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! grep -Fxq "$path" "$MANAGED_ACTS_TMP"; then
        EXTRA_MANIFEST_ACTS=$((EXTRA_MANIFEST_ACTS+1))
        echo "EXTRA_MANIFEST_ACT  $path"
    fi
done < "$MANIFEST_ACTS_TMP"

# EXTRA_MANIFEST_HANDOFFS: manifest HANDOFFs not in managed universe.
while IFS= read -r path; do
    [ -z "$path" ] && continue
    if ! grep -Fxq "$path" "$MANAGED_HANDOFFS_TMP"; then
        EXTRA_MANIFEST_HANDOFFS=$((EXTRA_MANIFEST_HANDOFFS+1))
        echo "EXTRA_MANIFEST_HANDOFF  $path"
    fi
done < "$MANIFEST_HANDOFFS_TMP"

# ------------------------------------------------------------------
# Phase 3: emit counters and decide exit.
# ------------------------------------------------------------------

echo
echo "POLYC_GATE=factory-closure-status"
echo "MANIFEST=$MANIFEST"
echo "MANAGED_ACTS=$MANAGED_ACTS_COUNT"
echo "MANAGED_HANDOFFS=$MANAGED_HANDOFFS_COUNT"
echo "MANIFEST_ROWS=$MANIFEST_ROWS"
echo "MANIFEST_PARSE_ERRORS=$MANIFEST_PARSE_ERRORS"
echo "DUPLICATE_ACT_PATHS=$DUPLICATE_ACT_PATHS"
echo "DUPLICATE_HANDOFF_PATHS=$DUPLICATE_HANDOFF_PATHS"
echo "MISSING_ACT_FILES=$MISSING_ACT_FILES"
echo "MISSING_HANDOFF_FILES=$MISSING_HANDOFF_FILES"
echo "MALFORMED_ACT_STATUS=$MALFORMED_ACT_STATUS"
echo "MALFORMED_HANDOFF_VERDICT=$MALFORMED_HANDOFF_VERDICT"
echo "UNMAPPED_MANAGED_ACTS=$UNMAPPED_MANAGED_ACTS"
echo "UNMAPPED_MANAGED_HANDOFFS=$UNMAPPED_MANAGED_HANDOFFS"
echo "EXTRA_MANIFEST_ACTS=$EXTRA_MANIFEST_ACTS"
echo "EXTRA_MANIFEST_HANDOFFS=$EXTRA_MANIFEST_HANDOFFS"
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
   || [ "$UNMAPPED_MANAGED_ACTS" -gt 0 ] \
   || [ "$UNMAPPED_MANAGED_HANDOFFS" -gt 0 ] \
   || [ "$EXTRA_MANIFEST_ACTS" -gt 0 ] \
   || [ "$EXTRA_MANIFEST_HANDOFFS" -gt 0 ] \
   || [ "$EXACT_VERDICT_MISMATCHES" -gt 0 ] \
   || [ "$PAIR_FAIL" -gt 0 ]; then
    echo "STATUS=FAIL"
    echo "VERDICT=FAIL"
    exit 1
fi

echo "STATUS=PASS"
echo "VERDICT=PASS"
exit 0
