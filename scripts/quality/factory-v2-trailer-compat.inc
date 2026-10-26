# scripts/quality/factory-v2-trailer-compat.inc
#
# ACT-POLYC-FACTORY-V2-HALT-TRAILER-PARSER01 C2.
#
# SHARED trailer-compatibility library for the Factory-v2 validators.
# This file is SOURCED, not executed. It carries the single canonical
# interpretation of Factory trailer metadata used by BOTH
# factory-v2-commit-msg-check.sh and factory-v2-range-check.sh
# (ACT section D2: shared interpretation; no redundant second parser).
#
# WHY THIS EXISTS
#
# The canonical Factory trailer keys HALT_CLASS and BLOCKS_NEXT contain
# underscores. Git's standard trailer parser (git 2.54.0) does not merely
# drop an underscore-bearing trailer: it REJECTS THE WHOLE TRAILER BLOCK.
# Measured:
#
#   printf 'x\n\nACT: A\nACT-Phase: CLOSE\n' | git interpret-trailers --parse
#     -> ACT: A / ACT-Phase: CLOSE                (parses)
#   printf 'x\n\nACT: A\nACT-Phase: CLOSE\nHALT_CLASS: G\n' \
#     | git interpret-trailers --parse
#     -> (empty; the whole block is dropped)
#
# Because HALT_CLASS and BLOCKS_NEXT are mandatory on every HALT_* CLOSE,
# a conforming HALT_* CLOSE lost its ACT:, ACT-Phase: and ACT-Verdict:
# trailers as well. The commit-message validator then took its fail-open
# path (MODE=NON_ACT / STATUS=PASS) and the range validator reported
# count=0.
#
# THE NORMALIZATION
#
# Only the two known underscore-bearing keys are rewritten, and only in a
# TEMPORARY COPY. The raw commit message is never mutated. The parsed
# keys are mapped back to their canonical names, so no caller ever sees
# "HALT-CLASS" or "BLOCKS-NEXT". Values, ordering, duplicate detection,
# cardinalities and trailer-block boundaries are preserved. No other key
# is normalized, and a malformed lookalike (e.g. "HALT CLASS:") is
# rejected rather than silently corrected.
#
# The authoritative HALT classification semantics live in
# tools/factory/factory-halt-classification.HC; the validators reproduce
# them and are verified against that classifier.

# The ACT-like trailer keys. A key counts as ACT metadata only when it
# starts a line and is followed by a colon and whitespace.
FACTORY_ACT_KEYS_RE='^(ACT|ACT-Phase|ACT-Verdict|ACT-Supersedes|ACT-Corrected-Verdict|HALT_CLASS|BLOCKS_NEXT):[[:space:]]+'

# Rewrite the two underscore-bearing keys into Git-compatible temporary
# keys. Usage: factory_trailer_normalize <in-file> <out-file>
factory_trailer_normalize() {
    sed -e 's/^HALT_CLASS:/HALT-CLASS:/' \
        -e 's/^BLOCKS_NEXT:/BLOCKS-NEXT:/' \
        "$1" > "$2"
}

# Map the temporary keys back to their canonical names.
factory_trailer_canonicalize() {
    sed -e 's/^HALT-CLASS:/HALT_CLASS:/' \
        -e 's/^BLOCKS-NEXT:/BLOCKS_NEXT:/'
}

# Parse a message FILE into canonical Factory trailer lines.
# Usage: factory_trailer_parse_file <message-file>
factory_trailer_parse_file() {
    _norm=$(mktemp -t polyc-v2-fh.XXXXXX)
    factory_trailer_normalize "$1" "$_norm"
    git interpret-trailers --parse < "$_norm" 2>/dev/null \
        | factory_trailer_canonicalize
    rm -f "$_norm"
}

# Parse a COMMIT into canonical Factory trailer lines.
# Usage: factory_trailer_parse_commit <commit>
factory_trailer_parse_commit() {
    _raw=$(mktemp -t polyc-v2-fr.XXXXXX)
    _norm=$(mktemp -t polyc-v2-fn.XXXXXX)
    git --no-pager log -1 --format='%B' "$1" > "$_raw" 2>/dev/null || true
    factory_trailer_normalize "$_raw" "$_norm"
    git interpret-trailers --parse < "$_norm" 2>/dev/null \
        | factory_trailer_canonicalize
    rm -f "$_raw" "$_norm"
}

# The raw commit message of a commit.
# Usage: factory_trailer_raw_commit <commit>
factory_trailer_raw_commit() {
    git --no-pager log -1 --format='%B' "$1" 2>/dev/null || true
}

# Count ACT-like trailer keys in a raw message, INDEPENDENTLY of whether
# git could parse the trailer block. This is what makes the validators
# fail CLOSED.
# Usage: factory_trailer_act_like_count <message-file>
factory_trailer_act_like_count() {
    _n=$(grep -Ec "$FACTORY_ACT_KEYS_RE" "$1" 2>/dev/null) || _n=0
    printf '%s\n' "$_n" | head -n 1
}

# Count how many separate trailer REGIONS in the raw message carry
# ACT-like keys. ACT metadata spread across more than one region (a
# split trailer block) is MALFORMED and must be rejected rather than
# partially accepted.
# Usage: factory_trailer_act_region_count <message-file>
factory_trailer_act_region_count() {
    _r=$(awk '
        /^(ACT|ACT-Phase|ACT-Verdict|ACT-Supersedes|ACT-Corrected-Verdict|HALT_CLASS|BLOCKS_NEXT):[[:space:]]+/ {
            factory = 1
        }
        /^[[:space:]]*$/ {
            if (factory) { regions++; factory = 0 }
            next
        }
        {
            if (!/^[A-Za-z][A-Za-z0-9_-]*:[[:space:]]+/) {
                if (factory) { regions++; factory = 0 }
            }
        }
        END { if (factory) regions++; print regions + 0 }
    ' "$1" 2>/dev/null) || _r=0
    printf '%s\n' "$_r" | head -n 1
}
