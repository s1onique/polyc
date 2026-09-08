#!/bin/sh
# closure-run.sh -- ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02
# Captures the identity-red (verbatim text of the bad CORRECTION01
# HANDOFF IDENTITY block) and identity-green (mechanically derived
# correct identity chain via git rev-parse / git rev-list).

set -eu
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO"

OUT_DIR="evidence/factory-status-reconciliation-correction02"
mkdir -p "$OUT_DIR"

# ---- identity-red.txt: verbatim capture of the bad record ----
{
    echo '# identity-red.txt'
    echo '# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02'
    echo '# Verbatim capture of the IDENTITY block of the committed'
    echo '# CORRECTION01 HANDOFF, as it appears at HEAD. This is the'
    echo '# RED witness for this ACT (HALT_CORRECTION01_CLOSURE_IDENTITY_MISBOUND).'
    echo '#'
    echo '# Source: evidence/factory-status-reconciliation-correction01/HANDOFF.md'
    echo '# Captured by: closure-run.sh at'
    echo "#   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo '# Source commit:'
    echo "#   $(git rev-parse HEAD)"
    echo
    sed -n '/^IDENTITY$/,/^Total commits/p' \
        evidence/factory-status-reconciliation-correction01/HANDOFF.md
} > "$OUT_DIR/identity-red.txt"

# ---- identity-green.txt: mechanically derived correct record ----
ENTRY=$(git rev-parse 31564feb987dbe725305658712170d899caa6798)
RED_HEAD=$(git rev-parse c014d1f8f561dba18ecdad2d53035174408d9a47)
IMPL_HEAD=$(git rev-parse 15070c306e6c7e902722d6d1ae34e830b3e2a74c)
CLOSURE_HEAD=$(git rev-parse 2d7ff45de22b826abb3096ed611cd7ac02f05134)
COUNT_3=$(git rev-list --count 31564feb987dbe725305658712170d899caa6798..2d7ff45de22b826abb3096ed611cd7ac02f05134)
COUNT_END=$(git rev-list --count 31564feb987dbe725305658712170d899caa6798..HEAD)

{
    echo '# identity-green.txt'
    echo '# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION02'
    echo '# Mechanically derived correct identity chain for'
    echo '# ACT-POLYC-FACTORY-STATUS-RECONCILIATION-CORRECTION01.'
    echo '#'
    echo '# Produced by: closure-run.sh at'
    echo "#   $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo '# This ACT HEAD (where these values are bound):'
    echo "#   $(git rev-parse HEAD)"
    echo
    echo "ENTRY_HEAD       = $ENTRY"
    echo "RED_HEAD         = $RED_HEAD"
    echo "IMPL_HEAD        = $IMPL_HEAD"
    echo "CLOSURE_HEAD     = $CLOSURE_HEAD"
    echo "git rev-list --count ${ENTRY:0:7}^..${CLOSURE_HEAD:0:7} = $COUNT_3"
    echo
    echo '# Total commits in this ACT (CORRECTION02):'
    echo "# git rev-list --count ${ENTRY:0:7}^..HEAD = $COUNT_END"
} > "$OUT_DIR/identity-green.txt"

echo "captured:"
echo "  $OUT_DIR/identity-red.txt   ($(wc -l < $OUT_DIR/identity-red.txt) lines)"
echo "  $OUT_DIR/identity-green.txt ($(wc -l < $OUT_DIR/identity-green.txt) lines)"
