#!/bin/sh
# scripts/quality/factory-halt-classification-check.sh
#
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
#
# Factory v2 trailer classifier for `HALT_CLASS` and
# `BLOCKS_NEXT`. Codifies the trailer contract defined
# at docs/acts/ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01.md
# §0 and at docs/factory/GIT-METADATA.md §2.4.
#
# CONTRACT (post-CLOSE of this ACT, applied only to
# the commit(s) explicitly named on the command line;
# this script does NOT walk repository history):
#
#   PASS verdict (effective PASS(_...)*):
#       HALT_CLASS  : forbidden (count must be 0)
#       BLOCKS_NEXT : forbidden (count must be 0)
#
#   HALT_* verdict (effective HALT_<TOKEN>):
#       HALT_CLASS  : required (count == 1), value in
#                     { GOVERNANCE, PRODUCTION, SAFETY,
#                       AUTHORIZATION, DEPENDENCY }
#       BLOCKS_NEXT : required (count == 1), value in
#                     { YES, NO }
#       class/boolean combination valid.
#
# Combinations:
#       GOVERNANCE     -> BLOCKS_NEXT = NO   (mandatory)
#       PRODUCTION     -> BLOCKS_NEXT = YES  (mandatory)
#       SAFETY         -> BLOCKS_NEXT = YES  (mandatory)
#       AUTHORIZATION  -> BLOCKS_NEXT = YES  (mandatory)
#       DEPENDENCY     -> BLOCKS_NEXT = YES|NO (either)
#
# USAGE:
#
#   factory-halt-classification-check.sh <commit-message-file>
#
# Inspects ONE commit message at a time. Does NOT walk
# history. Activation boundary: the C2 IMPL commit of
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01. Historical
# CLOSE commits are NOT validated by this script.
#
# Parsing note: we do NOT delegate to
# `git interpret-trailers --parse` because Git's
# built-in trailer parser (as of 2.54.0) does NOT
# accept underscores in trailer keys; HALT_CLASS and
# BLOCKS_NEXT are dropped by that parser. We parse
# directly with `grep -E` against the documented
# `<KEY>:[[:space:]]+<VALUE>` shape and require an
# explicit "Key: value" line. The same additive
# constraint applies to `ACT-Verdict` etc., but the
# existing `factory-v2-commit-msg-check.sh` already
# validates those.

set -eu

if [ "$#" -ne 1 ]; then
    echo "STATUS=ERROR"
    echo "REASON=usage: factory-halt-classification-check.sh <commit-message>"
    exit 2
fi

MSG_FILE="$1"

if [ ! -f "$MSG_FILE" ]; then
    echo "STATUS=ERROR"
    echo "REASON=commit message file not found: $MSG_FILE"
    exit 2
fi

# Parse trailers directly. We mirror the documented
# trailer shape: a line that matches `^<KEY>:[[:space:]]+`
# where KEY is one of {ACT, ACT-Phase, ACT-Verdict,
# HALT_CLASS, BLOCKS_NEXT}. The full commit message
# body is also kept so we can locate ACT-Verdict etc.
msg=$(cat "$MSG_FILE")

# has_act_trailer: does any line match '^ACT:'?
if ! printf '%s\n' "$msg" | grep -Eq '^ACT:[[:space:]]'; then
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

# trailer_value: extract the first matching trailer
# value. Returns the literal value (no whitespace
# rewriting). Empty string if absent.
trailer_value() {
    key="$1"
    printf '%s\n' "$msg" \
        | grep -E "^${key}:[[:space:]]" \
        | head -1 \
        | sed -E "s/^${key}:[[:space:]]+//"
}

count_trailer() {
    key="$1"
    printf '%s\n' "$msg" \
        | grep -Ec "^${key}:[[:space:]]" || true
}

ACT_ID=$(trailer_value ACT)
ACT_PHASE=$(trailer_value ACT-Phase)
ACT_VERDICT=$(trailer_value ACT-Verdict)
HALT_CLASS=$(trailer_value HALT_CLASS)
BLOCKS_NEXT=$(trailer_value BLOCKS_NEXT)

HALT_CLASS_COUNT=$(count_trailer HALT_CLASS)
BLOCKS_NEXT_COUNT=$(count_trailer BLOCKS_NEXT)

# Non-CLOSE commits are not bound by the new contract.
if [ "$ACT_PHASE" != "CLOSE" ]; then
    echo "MODE=ACT"
    echo "ACT=$ACT_ID"
    echo "PHASE=$ACT_PHASE"
    echo "VERDICT=$ACT_VERDICT"
    echo "HALT_CLASS=$HALT_CLASS"
    echo "BLOCKS_NEXT=$BLOCKS_NEXT"
    echo "STATUS=PASS"
    exit 0
fi

# CLOSE phase. Branch on verdict shape.
if printf '%s\n' "$ACT_VERDICT" | grep -Eq '^HALT_[A-Z0-9_]+$'; then
    if [ "$HALT_CLASS_COUNT" -ne 1 ]; then
        fail "HALT_CLASS count=${HALT_CLASS_COUNT}, expected 1 for HALT verdict"
    fi
    if [ "$BLOCKS_NEXT_COUNT" -ne 1 ]; then
        fail "BLOCKS_NEXT count=${BLOCKS_NEXT_COUNT}, expected 1 for HALT verdict"
    fi
    case "$HALT_CLASS" in
        GOVERNANCE|PRODUCTION|SAFETY|AUTHORIZATION|DEPENDENCY)
            ;;
        *)
            fail "HALT_CLASS '$HALT_CLASS' not in enum"
            ;;
    esac
    case "$BLOCKS_NEXT" in
        YES|NO)
            ;;
        *)
            fail "BLOCKS_NEXT '$BLOCKS_NEXT' not in {YES, NO}"
            ;;
    esac
    case "$HALT_CLASS:$BLOCKS_NEXT" in
        GOVERNANCE:NO|PRODUCTION:YES|SAFETY:YES|AUTHORIZATION:YES|DEPENDENCY:YES|DEPENDENCY:NO)
            ;;
        GOVERNANCE:YES)
            fail "GOVERNANCE requires BLOCKS_NEXT=NO"
            ;;
        PRODUCTION:NO)
            fail "PRODUCTION requires BLOCKS_NEXT=YES"
            ;;
        SAFETY:NO)
            fail "SAFETY requires BLOCKS_NEXT=YES"
            ;;
        AUTHORIZATION:NO)
            fail "AUTHORIZATION requires BLOCKS_NEXT=YES"
            ;;
        *)
            fail "combination $HALT_CLASS/$BLOCKS_NEXT rejected"
            ;;
    esac
elif printf '%s\n' "$ACT_VERDICT" | grep -Eq '^PASS(_[A-Z0-9_]+)*$'; then
    if [ "$HALT_CLASS_COUNT" -ne 0 ]; then
        fail "PASS verdict forbids HALT_CLASS (count=${HALT_CLASS_COUNT})"
    fi
    if [ "$BLOCKS_NEXT_COUNT" -ne 0 ]; then
        fail "PASS verdict forbids BLOCKS_NEXT (count=${BLOCKS_NEXT_COUNT})"
    fi
fi

echo "MODE=ACT"
echo "ACT=$ACT_ID"
echo "PHASE=$ACT_PHASE"
echo "VERDICT=$ACT_VERDICT"
echo "HALT_CLASS=$HALT_CLASS"
echo "BLOCKS_NEXT=$BLOCKS_NEXT"
echo "STATUS=PASS"
exit 0
