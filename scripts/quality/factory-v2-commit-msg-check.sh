#!/bin/sh
# scripts/quality/factory-v2-commit-msg-check.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
#
# Factory v2 commit-message validator.
#
# Opt-in by trailer presence: if the commit message has no
# `ACT:` trailer, the validator returns rc=0 and prints
# MODE=NON_ACT. Ordinary Git commits remain possible.
#
# When an `ACT:` trailer is present, the validator enforces
# the trailer grammar defined in
# `docs/factory/GIT-METADATA.md`:
#
#   ACT                : exactly 1, matches
#                        ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]*$
#   ACT-Phase          : exactly 1, one of
#                        RED | IMPL | EVIDENCE | CLOSE
#   ACT-Verdict        : exactly 0 for RED/IMPL/EVIDENCE;
#                        exactly 1 for CLOSE;
#                        matches
#                        ^(PASS(?:_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
#   ACT-Supersedes     : optional, 0 or 1
#   ACT-Corrected-Verdict:
#                        optional, 0 or 1;
#                        if present, ACT-Supersedes MUST be present
#
# Parsing is delegated to `git interpret-trailers --parse`
# to avoid inventing a second trailer grammar.
#
# Usage:
#   factory-v2-commit-msg-check.sh <path-to-commit-message>
#
# Output (rc=0):
#   MODE=NON_ACT
# or:
#   MODE=ACT  ACT=<id>  PHASE=<phase>  VERDICT=<token>  STATUS=PASS
#
# Output (rc=1) on any violation:
#   MODE=ACT  STATUS=FAIL  REASON=<reason>

set -eu

if [ "$#" -ne 1 ]; then
    echo "STATUS=ERROR"
    echo "REASON=usage: factory-v2-commit-msg-check.sh <commit-message>"
    exit 2
fi

MSG_FILE="$1"

if [ ! -f "$MSG_FILE" ]; then
    echo "STATUS=ERROR"
    echo "REASON=commit message file not found: $MSG_FILE"
    exit 2
fi

# Parse trailers using Git's own parser.
parsed=$(git interpret-trailers --parse < "$MSG_FILE" 2>/dev/null) || parsed=""

# If no `ACT:` trailer, this is an ordinary commit. Pass.
if ! printf '%s\n' "$parsed" | grep -Eq '^ACT:[[:space:]]+.+'; then
    echo "MODE=NON_ACT"
    echo "STATUS=PASS"
    exit 0
fi

fail() {
    echo "MODE=ACT"
    echo "STATUS=FAIL"
    echo "REASON=$1"
    exit 1
}

# Extract a trailer value by key. Returns the FIRST matching
# line's value, trimmed of leading whitespace; collapses
# internal whitespace runs to a single underscore so the
# downstream verdict regex matches are well-defined.
trailer_value() {
    key="$1"
    printf '%s\n' "$parsed" \
        | awk -v k="^${key}:[[:space:]]+" '$0 ~ k {
            sub(k, "", $0)
            gsub(/[[:space:]]+/, "_", $0)
            print
            exit
        }'
}

count_trailer() {
    key="$1"
    printf '%s\n' "$parsed" \
        | grep -Ec "^${key}:[[:space:]]+" || true
}

ACT_ID_RAW=$(trailer_value ACT)
ACT_PHASE_RAW=$(trailer_value ACT-Phase)
ACT_VERDICT_RAW=$(trailer_value ACT-Verdict)
ACT_SUPERSEDES_RAW=$(trailer_value ACT-Supersedes)
ACT_CORR_VERDICT_RAW=$(trailer_value ACT-Corrected-Verdict)

ACT_COUNT=$(count_trailer ACT)
PHASE_COUNT=$(count_trailer ACT-Phase)
VERDICT_COUNT=$(count_trailer ACT-Verdict)
SUPERSEDES_COUNT=$(count_trailer ACT-Supersedes)
CORR_VERDICT_COUNT=$(count_trailer ACT-Corrected-Verdict)

# Card 1: exactly one ACT
if [ "$ACT_COUNT" -ne 1 ]; then
    fail "ACT trailer count=${ACT_COUNT}, expected 1"
fi

# Card 2: exactly one ACT-Phase
if [ "$PHASE_COUNT" -ne 1 ]; then
    fail "ACT-Phase trailer count=${PHASE_COUNT}, expected 1"
fi

# Validate ACT identifier regex
case "$ACT_ID_RAW" in
    "") fail "ACT trailer value empty" ;;
    *)
        case "$ACT_ID_RAW" in
            ACT-POLYC-[A-Z0-9][A-Z0-9_-]*)
                ;;
            *)
                fail "ACT id '$ACT_ID_RAW' does not match regex"
                ;;
        esac
        ;;
esac

# Validate phase enum
case "$ACT_PHASE_RAW" in
    RED|IMPL|EVIDENCE|CLOSE)
        ;;
    *)
        fail "ACT-Phase '$ACT_PHASE_RAW' not in {RED,IMPL,EVIDENCE,CLOSE}"
        ;;
esac


# Verdict rules: RED/IMPL/EVIDENCE -> no verdict.
# CLOSE -> exactly one verdict matching the grammar.
case "$ACT_PHASE_RAW" in
    RED|IMPL|EVIDENCE)
        if [ "$VERDICT_COUNT" -ne 0 ]; then
            fail "phase $ACT_PHASE_RAW forbids ACT-Verdict (count=${VERDICT_COUNT})"
        fi
        ;;
    CLOSE)
        if [ "$VERDICT_COUNT" -ne 1 ]; then
            fail "phase CLOSE requires exactly one ACT-Verdict (count=${VERDICT_COUNT})"
        fi
        case "$ACT_VERDICT_RAW" in
            "")
                fail "CLOSE ACT-Verdict empty"
                ;;
            *)
                case "$ACT_VERDICT_RAW" in
                    PASS|PASS_*)
                        case "$ACT_VERDICT_RAW" in
                            PASS|PASS_[A-Z0-9_]*)
                                ;;
                            *)
                                fail "CLOSE ACT-Verdict '$ACT_VERDICT_RAW' malformed"
                                ;;
                        esac
                        ;;
                    HALT_[A-Z0-9_]*)
                        ;;
                    *)
                        fail "CLOSE ACT-Verdict '$ACT_VERDICT_RAW' does not match verdict grammar"
                        ;;
                esac
                ;;
        esac
        ;;
esac

# ACT-Supersedes optionality: 0 or 1.
if [ "$SUPERSEDES_COUNT" -gt 1 ]; then
    fail "ACT-Supersedes trailer count=${SUPERSEDES_COUNT}, expected 0 or 1"
fi

# ACT-Corrected-Verdict optionality: 0 or 1; requires ACT-Supersedes.
if [ "$CORR_VERDICT_COUNT" -gt 1 ]; then
    fail "ACT-Corrected-Verdict trailer count=${CORR_VERDICT_COUNT}, expected 0 or 1"
fi

if [ "$CORR_VERDICT_COUNT" -eq 1 ] && [ "$SUPERSEDES_COUNT" -ne 1 ]; then
    fail "ACT-Corrected-Verdict requires ACT-Supersedes"
fi

# If ACT-Corrected-Verdict is present, its value must match
# the verdict grammar (it is a verdict about the predecessor).
if [ "$CORR_VERDICT_COUNT" -eq 1 ]; then
    case "$ACT_CORR_VERDICT_RAW" in
        "")
            fail "ACT-Corrected-Verdict value empty"
            ;;
        *)
            case "$ACT_CORR_VERDICT_RAW" in
                PASS|PASS_*)
                    case "$ACT_CORR_VERDICT_RAW" in
                        PASS|PASS_[A-Z0-9_]*)
                            ;;
                        *)
                            fail "ACT-Corrected-Verdict '$ACT_CORR_VERDICT_RAW' malformed"
                            ;;
                    esac
                    ;;
                HALT_[A-Z0-9_]*)
                    ;;
                *)
                    fail "ACT-Corrected-Verdict '$ACT_CORR_VERDICT_RAW' does not match verdict grammar"
                    ;;
            esac
            ;;
    esac
fi

echo "MODE=ACT"
echo "ACT=$ACT_ID_RAW"
echo "PHASE=$ACT_PHASE_RAW"
echo "VERDICT=$ACT_VERDICT_RAW"
echo "SUPERSEDES=$ACT_SUPERSEDES_RAW"
echo "CORRECTED_VERDICT=$ACT_CORR_VERDICT_RAW"
echo "STATUS=PASS"
exit 0
