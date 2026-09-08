#!/bin/sh
# scripts/quality/llvm-closure-status-check.sh
#
# ACT-POLYC-LLVM-CORE03-CORRECTION05 M1: closure-status-reconciliation
# fast gate.
#
# For each ACT in docs/acts/, compare:
#   - the Status line(s) of the ACT
#   - the VERDICT line of the matching HANDOFF in evidence/
#
# and FAIL if any pair disagrees.
#
# This is the third-time-is-the-charm gate: the closure-status
# reconciliation defect has now been observed three times in a row
#   - CORRECTION02: HANDOFF said PASS, ACT said HALT
#   - CORRECTION03: ACT Status self-pinned HEAD that had moved
#   - CORRECTION04: ACT Status said OPEN, HANDOFF said PASS
# The pattern is no longer optional.
#
# Pairing rule (deliberately strict):
#   ACT path: docs/acts/ACT-<...>.md
#   HANDOFF:  evidence/<matching-dir>/HANDOFF.md
#             where <matching-dir> is the lowercase form of the ACT
#             filename minus the .md extension, with the
#             "ACT-POLYC-" prefix stripped and remaining uppercase
#             segments lowercased.
#
# Example:
#   ACT-POLYC-LLVM-CORE03-CORRECTION04.md
#     -> evidence/llvmspike01-core03-correction04/HANDOFF.md
#   ACT-POLYC-IR-BOUNDARY01.md
#     -> evidence/ir-boundary01/HANDOFF.md
#   ACT-POLYC-LLVM-CORE01.md
#     -> evidence/llvmspike01-core01/HANDOFF.md
#
# This script is OPT-IN: only ACTs that have BOTH a Status block
# AND a HANDOFF are checked. ACTs without a HANDOFF (e.g.
# legacy ACTs predating the HANDOFF convention) are skipped.
#
# Status block tokenization:
#   - the FIRST line of the Status block is the verdict line.
#   - "PASS" / "HALT_" / "OPEN" are extracted as a single token.
# HANDOFF verdict tokenization:
#   - the FIRST non-empty line after a line containing "VERDICT"
#     is the verdict line.
#
# If the tokens agree -> OK for that ACT.
# If they disagree  -> FAIL for that ACT (the script exits 1 at
#                       the end with a summary).

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$REPO_ROOT"

ACTS_DIR=docs/acts
EVID_DIR=evidence

PASS=0
FAIL=0
FAIL_LIST=""

# Map ACT filename -> HANDOFF evidence dir
# llvmspike01-core03-correction04 -> evidence/llvmspike01-core03-correction04/
# We compute the lowercased tail minus ACT-POLYC- prefix.
act_to_evid_dir() {
    fname="$1"   # e.g. ACT-POLYC-LLVM-CORE03-CORRECTION04.md
    base="${fname%.md}"                     # ACT-POLYC-LLVM-CORE03-CORRECTION04
    base="${base#ACT-POLYC-}"               # LLVM-CORE03-CORRECTION04
    # Drop target prefix (LLVM- or IR- or FACTORY-) and lowercase
    case "$base" in
        LLVM-*)    tail="${base#LLVM-}";;       # CORE03-CORRECTION04
        IR-*)      tail="${base#IR-}";;         # BOUNDARY01
        FACTORY-*) tail="factory-${base#FACTORY-}";;
        *)         tail="$base";;
    esac
    tail="$(echo "$tail" | tr '[:upper:]' '[:lower:]')"
    # Special-case: llvmspike01-* ACTs live under evidence/llvmspike01-*/
    if [ "${tail#core}" != "$tail" ]; then
        echo "llvmspike01-$tail"
    elif [ "${tail#boundary}" != "$tail" ]; then
        echo "ir-$tail"
    elif [ "${tail#factory-}" != "$tail" ]; then
        echo "$tail"
    else
        echo "$tail"
    fi
}

# Extract the first non-comment verdict token from a Status block.
# Looks for the first "Status" heading and reads until the next heading.
extract_status_token() {
    file="$1"
    awk '
        /^##[[:space:]]+Status[[:space:]]*$/ { in_status=1; next }
        in_status && /^##[[:space:]]/      { exit }
        in_status && /^[[:space:]]*$/      { next }
        in_status {
            line=$0
            # Skip bullet markers
            sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
            # Extract first non-whitespace token
            if (match(line, /[^[:space:]]+/)) {
                tok = substr(line, RSTART, RLENGTH)
                print tok
                exit
            }
        }
    ' "$file"
}

# Extract the verdict token from a HANDOFF (looks for VERDICT section).
# The HANDOFF format used by PolyC is:
#   VERDICT
#   -------
#   PASS|HALT_<...>|OPEN
#
# We skip the underline (a line of only - characters).
extract_handoff_token() {
    file="$1"
    awk '
        /^VERDICT/ { in_v=1; next }
        in_v && /^-+[[:space:]]*$/ { next }   # skip underline
        in_v && /^[[:space:]]*$/      { next }
        in_v {
            line=$0
            sub(/^[[:space:]]*[-*][[:space:]]*/, "", line)
            if (match(line, /[^[:space:]]+/)) {
                tok = substr(line, RSTART, RLENGTH)
                print tok
                exit
            }
        }
    ' "$file"
}

# Iterate
for act_path in "$ACTS_DIR"/ACT-*.md; do
    [ -f "$act_path" ] || continue
    fname="$(basename "$act_path")"

    # Skip ACTs that are clearly not under our reconciliation scope
    # (e.g. ACT-POLYC-LLVM-CORE04.md if it has no HANDOFF).
    evid_dir="$(act_to_evid_dir "$fname")"
    handoff="$EVID_DIR/$evid_dir/HANDOFF.md"
    [ -f "$handoff" ] || continue

    act_token="$(extract_status_token "$act_path" 2>/dev/null || true)"
    handoff_token="$(extract_handoff_token "$handoff" 2>/dev/null || true)"

    if [ -z "$act_token" ] || [ -z "$handoff_token" ]; then
        continue
    fi

    # Normalise PASS comparison: ACT may say "PASS" with qualifier
    # ("PASS at ..."), HANDOFF may say "PASS". Compare first word.
    case "$act_token" in
        PASS*)    act_norm=PASS;;
        HALT*)    act_norm=HALT;;
        OPEN)     act_norm=OPEN;;
        *)        act_norm="$act_token";;
    esac
    case "$handoff_token" in
        PASS*)    h_norm=PASS;;
        HALT*)    h_norm=HALT;;
        OPEN)     h_norm=OPEN;;
        *)        h_norm="$handoff_token";;
    esac

    if [ "$act_norm" = "$h_norm" ]; then
        PASS=$((PASS+1))
        printf 'OK    %-50s act=%-6s handoff=%-6s\n' "$fname" "$act_norm" "$h_norm"
    else
        FAIL=$((FAIL+1))
        FAIL_LIST="$FAIL_LIST $fname(act=$act_norm/handoff=$h_norm)"
        printf 'FAIL  %-50s act=%-6s handoff=%-6s\n' "$fname" "$act_norm" "$h_norm"
    fi
done

echo
echo "===================================="
echo "Closure-status reconciliation summary"
echo "OK=$PASS  FAIL=$FAIL"
echo "===================================="

if [ "$FAIL" -gt 0 ]; then
    echo "FAILURES:$FAIL_LIST" >&2
    exit 1
fi
exit 0
