#!/bin/sh
# scripts/quality/factory-v2-commit-msg-check.sh
#
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01
# ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01-CORRECTION01
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
#                        ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$
#   ACT-Phase          : exactly 1, one of
#                        RED | IMPL | EVIDENCE | CLOSE
#   ACT-Verdict        : exactly 0 for RED/IMPL/EVIDENCE;
#                        exactly 1 for CLOSE;
#                        matches
#                        ^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
#   ACT-Supersedes     : optional, 0 or 1
#   ACT-Corrected-Verdict:
#                        optional, 0 or 1;
#                        if present, ACT-Supersedes MUST be present
#
# Parsing is delegated to `git interpret-trailers --parse`
# to avoid inventing a second trailer grammar.
#
# CORRECTION01 changes (vs SIMPLIFY01):
#   - removed `gsub(/[[:space:]]+/, "_", $0)` from
#     trailer_value() so the literal parsed value is what
#     gets validated (no whitespace-to-underscore rewrite);
#   - replaced POSIX shell `case` patterns with `grep -Eq`
#     against the documented regex grammar so malformed
#     ids / verdict values cannot reach STATUS=PASS through
#     shell-glob semantics.
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

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2.
#
# The canonical Factory trailer keys HALT_CLASS and BLOCKS_NEXT contain
# underscores. Git's standard trailer parser (git 2.54.0) REJECTS A WHOLE
# TRAILER BLOCK when ANY key in it contains an underscore, so the entire
# ACT footer -- including ACT:, ACT-Phase: and ACT-Verdict: -- was
# silently dropped. The validator then saw no ACT trailer and took the
# fail-open path (MODE=NON_ACT / STATUS=PASS).
#
# The shared compatibility normalization lives in
# scripts/quality/factory-v2-trailer-compat.inc, which this validator
# and the range validator BOTH source. It rewrites ONLY the two known
# underscore-bearing keys into Git-compatible temporary keys, for the
# purpose of parsing ONLY, and maps them back to their canonical names.
# The raw commit message is never mutated.
#
# See docs/factory/GIT-METADATA.md section 2.5 for the binding contract.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/factory-v2-trailer-compat.inc"

TMP_NORM=$(mktemp -t polyc-v2-norm.XXXXXX)
trap 'rm -f "$TMP_NORM"' EXIT

# Parse the message with the shared normalized interpretation.
parsed=$(factory_trailer_parse_file "$MSG_FILE") || parsed=""

RAW_ACT_LIKE=$(factory_trailer_act_like_count "$MSG_FILE")
RAW_ACT_REGIONS=$(factory_trailer_act_region_count "$MSG_FILE")

# FAIL CLOSED (D3): the raw message carries ACT-like trailer keys but
# the parse did not yield a usable ACT trailer. This is either a
# malformed/split trailer block, or a key shape git cannot parse. Either
# way it MUST NOT be classified as an ordinary non-ACT commit.
if [ "$RAW_ACT_LIKE" -gt 0 ] && ! printf '%s\n' "$parsed" | grep -Eq '^ACT:[[:space:]]+.+'; then
    echo "MODE=ACT"
    echo "STATUS=FAIL"
    echo "REASON=ACT-like trailer metadata present (count=${RAW_ACT_LIKE}) but no parseable ACT trailer; footer is malformed or unparseable"
    exit 1
fi

# FAIL CLOSED: ACT metadata split across more than one trailer region is
# a malformed footer. Do not accept a partial trailer block.
if [ "$RAW_ACT_REGIONS" -gt 1 ]; then
    echo "MODE=ACT"
    echo "STATUS=FAIL"
    echo "REASON=ACT trailer metadata is split across ${RAW_ACT_REGIONS} separate trailer regions; footer is malformed"
    exit 1
fi

# If no ACT trailer, this is an ordinary commit. Pass.
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
# line's value with the leading "<key>:[[:space:]]+" stripped.
# The returned value is the LITERAL parsed value; whitespace
# is not rewritten.
#
# Note: the value may contain spaces. We pass it via a here
# string so trailing whitespace survives. Downstream callers
# MUST treat the returned value as opaque text.
trailer_value() {
    key="$1"
    printf '%s\n' "$parsed" \
        | awk -v k="^${key}:[[:space:]]+" '$0 ~ k {
            sub(k, "", $0)
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
HALT_CLASS_RAW=$(trailer_value HALT_CLASS)
BLOCKS_NEXT_RAW=$(trailer_value BLOCKS_NEXT)

ACT_COUNT=$(count_trailer ACT)
PHASE_COUNT=$(count_trailer ACT-Phase)
VERDICT_COUNT=$(count_trailer ACT-Verdict)
SUPERSEDES_COUNT=$(count_trailer ACT-Supersedes)
CORR_VERDICT_COUNT=$(count_trailer ACT-Corrected-Verdict)
HALT_CLASS_COUNT=$(count_trailer HALT_CLASS)
BLOCKS_NEXT_COUNT=$(count_trailer BLOCKS_NEXT)

# Card 1: exactly one ACT
if [ "$ACT_COUNT" -ne 1 ]; then
    fail "ACT trailer count=${ACT_COUNT}, expected 1"
fi

# Card 2: exactly one ACT-Phase
if [ "$PHASE_COUNT" -ne 1 ]; then
    fail "ACT-Phase trailer count=${PHASE_COUNT}, expected 1"
fi

# Validate ACT identifier regex.
# POSITIVE contract:
#   ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$
# (at least 2 characters after the prefix; matches what
# docs/factory/GIT-METADATA.md section 2.1 actually binds.)
#
# Implementation note: regex match is performed with
# `grep -Eq`, NOT with POSIX shell `case` patterns.
# Shell-glob `*` would match any string after the first
# character class and silently accept malformed ids.
if [ -z "$ACT_ID_RAW" ]; then
    fail "ACT trailer value empty"
fi
if ! printf '%s\n' "$ACT_ID_RAW" \
        | grep -Eq '^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+$'; then
    fail "ACT id '$ACT_ID_RAW' does not match regex ^ACT-POLYC-[A-Z0-9][A-Z0-9_-]+\$"
fi

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
#
# POSITIVE contract:
#   ^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$
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
        if [ -z "$ACT_VERDICT_RAW" ]; then
            fail "CLOSE ACT-Verdict empty"
        fi
        if ! printf '%s\n' "$ACT_VERDICT_RAW" \
                | grep -Eq '^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'; then
            fail "CLOSE ACT-Verdict '$ACT_VERDICT_RAW' does not match verdict grammar ^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)\$"
        fi
        ;;
esac

# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2 (Work package B).
#
# HALT classification trailers (docs/factory/GIT-METADATA.md section 2.4).
# These are only meaningful on a CLOSE commit. The semantics are the
# ones implemented by the authoritative PolyC classifier
# (tools/factory/factory-halt-classification.HC); they are reproduced
# here so that the two shell validators and the classifier agree.
#
#   HALT_CLASS  = GOVERNANCE | PRODUCTION | SAFETY |
#                 AUTHORIZATION | DEPENDENCY
#   BLOCKS_NEXT = YES | NO
#
#   HALT_CLASS      | BLOCKS_NEXT
#   ----------------|--------------
#   GOVERNANCE      | NO
#   PRODUCTION      | YES
#   SAFETY          | YES
#   AUTHORIZATION   | YES
#   DEPENDENCY      | YES or NO
#
# A HALT_* verdict requires exactly one HALT_CLASS and exactly one
# BLOCKS_NEXT. A PASS(_...)* verdict forbids both.
if [ "$ACT_PHASE_RAW" = "CLOSE" ]; then
    case "$ACT_VERDICT_RAW" in
        HALT_*)
            if [ "$HALT_CLASS_COUNT" -ne 1 ]; then
                fail "HALT_CLASS count=${HALT_CLASS_COUNT}, expected 1 for HALT verdict"
            fi
            if [ "$BLOCKS_NEXT_COUNT" -ne 1 ]; then
                fail "BLOCKS_NEXT count=${BLOCKS_NEXT_COUNT}, expected 1 for HALT verdict"
            fi
            case "$HALT_CLASS_RAW" in
                GOVERNANCE|PRODUCTION|SAFETY|AUTHORIZATION|DEPENDENCY)
                    ;;
                *)
                    fail "HALT_CLASS '$HALT_CLASS_RAW' not in enum {GOVERNANCE,PRODUCTION,SAFETY,AUTHORIZATION,DEPENDENCY}"
                    ;;
            esac
            case "$BLOCKS_NEXT_RAW" in
                YES|NO)
                    ;;
                *)
                    fail "BLOCKS_NEXT '$BLOCKS_NEXT_RAW' not in {YES, NO}"
                    ;;
            esac
            case "$HALT_CLASS_RAW" in
                GOVERNANCE)
                    required_blocks_next=NO
                    ;;
                PRODUCTION|SAFETY|AUTHORIZATION)
                    required_blocks_next=YES
                    ;;
                *)
                    # DEPENDENCY allows either.
                    required_blocks_next=""
                    ;;
            esac
            if [ -n "$required_blocks_next" ] \
                && [ "$BLOCKS_NEXT_RAW" != "$required_blocks_next" ]; then
                fail "HALT_CLASS $HALT_CLASS_RAW requires BLOCKS_NEXT=$required_blocks_next"
            fi
            ;;
        PASS|PASS_*)
            if [ "$HALT_CLASS_COUNT" -ne 0 ]; then
                fail "PASS verdict forbids HALT_CLASS (count=${HALT_CLASS_COUNT})"
            fi
            if [ "$BLOCKS_NEXT_COUNT" -ne 0 ]; then
                fail "PASS verdict forbids BLOCKS_NEXT (count=${BLOCKS_NEXT_COUNT})"
            fi
            ;;
    esac
fi

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
    if [ -z "$ACT_CORR_VERDICT_RAW" ]; then
        fail "ACT-Corrected-Verdict value empty"
    fi
    if ! printf '%s\n' "$ACT_CORR_VERDICT_RAW" \
            | grep -Eq '^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$'; then
        fail "ACT-Corrected-Verdict '$ACT_CORR_VERDICT_RAW' does not match verdict grammar ^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)\$"
    fi
fi

echo "MODE=ACT"
echo "ACT=$ACT_ID_RAW"
echo "PHASE=$ACT_PHASE_RAW"
echo "VERDICT=$ACT_VERDICT_RAW"
echo "SUPERSEDES=$ACT_SUPERSEDES_RAW"
echo "CORRECTED_VERDICT=$ACT_CORR_VERDICT_RAW"
echo "HALT_CLASS=$HALT_CLASS_RAW"
echo "BLOCKS_NEXT=$BLOCKS_NEXT_RAW"
echo "STATUS=PASS"
exit 0
