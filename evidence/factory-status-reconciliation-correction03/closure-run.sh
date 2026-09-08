#!/bin/sh
# closure-run.sh -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
#
# Mechanically captures:
#   (1) identity-red.txt   -- verbatim capture of the committed
#       CORRECTION02 HANDOFF IDENTITY block at the predecessor
#       HEAD (849677a). This is the RED witness for CORRECTION03.
#   (2) identity-green.txt -- mechanical capture of the CORRECTION02
#       endpoints (which are immutable in the repository):
#         CORRECTION02_ENTRY_HEAD = 2d7ff45de22b826abb3096ed611cd7ac02f05134
#         CORRECTION02_RED_HEAD   = b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
#         CORRECTION02_IMPL_HEAD  = d9b996188678022fd7e35cc82588de17408eb2f9
#         CORRECTION02_DOCS_HEAD  = 849677ade3d6275996409846bbe99be49c6145b1
#         git rev-list --count 2d7ff45..849677a = 3
#
# These four SHAs are immutable regardless of when this script runs;
# they do not require any "this commit" / "next commit" placeholder.

set -eu

EVIDENCE_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$EVIDENCE_DIR/../.."

# (1) identity-red.txt -- verbatim capture of the committed CORRECTION02 HANDOFF
#     IDENTITY block. Source: the committed file at predecessor HEAD 849677a.
cat > "$EVIDENCE_DIR/identity-red.txt" <<'RED_EOF'
# identity-red.txt
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
# Verbatim capture of the IDENTITY block of the committed
# CORRECTION02 HANDOFF, as it appears at the predecessor HEAD
# 849677ade3d6275996409846bbe99be49c6145b1. This is the
# RED witness for this ACT (HALT_CORRECTION02_CLOSURE_STATE_UNBOUND).
#
# Source: evidence/factory-status-reconciliation-correction02/HANDOFF.md
# Source commit (the commit that contains the bad record):
#   849677ade3d6275996409846bbe99be49c6145b1
# (this is the CORRECTION02 closure commit; the bad HANDOFF
#  IDENTITY block was authored in that commit and is preserved
#  per F14.)

RED_EOF

# Capture the actual IDENTITY block of the CORRECTION02 HANDOFF.
# We use sed from the committed tree at predecessor HEAD 849677a.
git show 849677ade3d6275996409846bbe99be49c6145b1:evidence/factory-status-reconciliation-correction02/HANDOFF.md \
    | sed -n '/^IDENTITY (mechanically derived/,/^WHY THIS ACT EXISTS/p' \
    >> "$EVIDENCE_DIR/identity-red.txt"

# (2) identity-green.txt -- mechanical capture of CORRECTION02 endpoints.
CORRECTION02_ENTRY=2d7ff45de22b826abb3096ed611cd7ac02f05134
CORRECTION02_RED=b62f940f8b3bdf6dd0b1d2ba517cd45a4e5c03f3
CORRECTION02_IMPL=d9b996188678022fd7e35cc82588de17408eb2f9
CORRECTION02_DOCS=849677ade3d6275996409846bbe99be49c6145b1

COUNT_3=$(git rev-list --count "$CORRECTION02_ENTRY".."$CORRECTION02_DOCS")

cat > "$EVIDENCE_DIR/identity-green.txt" <<GREEN_EOF
# identity-green.txt
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION03
# Mechanically derived correct identity record for
# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02.
#
# All four SHAs below are immutable in the repository. They do not
# require "this commit" placeholders and cannot become stale.
#
# Produced by: closure-run.sh at
#   $(date -u +%Y-%m-%dT%H:%M:%SZ)
# CORRECTION03 entry HEAD (the immutable predecessor into CORRECTION03):
#   $CORRECTION02_DOCS

CORRECTION02_ENTRY_HEAD = $CORRECTION02_ENTRY
                          (predecessor ACT-POLYC-FACTORY-STATUS-RECONCILIATION
                           closure commit; entry into the CORRECTION01 chain)

CORRECTION02_RED_HEAD   = $CORRECTION02_RED
                          (CORRECTION02 C1: ACT contract + RED witnesses)

CORRECTION02_IMPL_HEAD  = $CORRECTION02_IMPL
                          (CORRECTION02 C2: bounded universe grows by 1 pair)

CORRECTION02_DOCS_HEAD  = $CORRECTION02_DOCS
                          (CORRECTION02 C3: HANDOFF + ACT status PASS;
                           this is also the immutable entry HEAD into CORRECTION03)

git rev-list --count $CORRECTION02_ENTRY..$CORRECTION02_DOCS = $COUNT_3
                          (3 commits in the CORRECTION02 chain)
GREEN_EOF

echo 'captured:'
echo "  $EVIDENCE_DIR/identity-red.txt   ($(wc -l < $EVIDENCE_DIR/identity-red.txt) lines)"
echo "  $EVIDENCE_DIR/identity-green.txt ($(wc -l < $EVIDENCE_DIR/identity-green.txt) lines)"
