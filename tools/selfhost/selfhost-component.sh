#!/bin/sh
# tools/selfhost/selfhost-component.sh
#
# ACT-POLYC-SELFHOST-SURFACE01 C2 IMPL — generic
# self-host component driver.
#
# Invoked from the Makefile targets
#   selfhost-component-build  COMPONENT=<id> STAGE=<n>
#   selfhost-component-test   COMPONENT=<id> STAGE=<n>
# and from the historical bootstrap* targets as a thin
# wrapper when the user invokes them directly.
#
# Operation (build):
#   1. validate registry via Python validator
#   2. resolve component row
#   3. resolve producer binary from STAGE
#   4. require producer exists and is executable
#   5. resolve source
#   6. compute deterministic output path
#   7. remove stale output
#   8. invoke producer directly with --install-dir prefix
#      (registry fields are DATA; we never eval them as
#       shell commands; --install-dir and -o are passed
#       from this script, not from the registry)
#   9. require rc=0 and output exists
#  10. verify expected symbol (with platform-aware link
#      decoration: leading underscore on Darwin)
#  11. emit provenance line(s) to stdout
#
# Operation (test): after a successful build, invoke the
# Makefile targets named in the registry row's
#   oracle
#   cursor_gate
#   production_seam_gate
# in sequence.
#
# No shell evaluation of registry data. Registry fields
# are DATA, not COMMANDS.

set -eu

REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REGISTRY="${REPO_ROOT}/docs/factory/SELF-HOST-COMPONENTS.tsv"
VALIDATOR="${REPO_ROOT}/scripts/quality/selfhost-component-registry.py"
TEST_PREFIX="${REPO_ROOT}/build/test-prefix"

OP="${1:-}"
shift || true

COMPONENT=""
STAGE=""

while [ $# -gt 0 ]; do
    case "$1" in
        COMPONENT=*)
            COMPONENT="${1#COMPONENT=}"
            ;;
        STAGE=*)
            STAGE="${1#STAGE=}"
            ;;
        *)
            echo "selfhost-component: unknown argument: $1" >&2
            exit 2
            ;;
    esac
    shift
done

if [ -z "$OP" ]; then
    echo "usage: selfhost-component.sh build|test COMPONENT=<id> STAGE=<n>" >&2
    exit 2
fi
if [ -z "$COMPONENT" ]; then
    echo "selfhost-component: COMPONENT=<id> is required" >&2
    exit 2
fi
if [ -z "$STAGE" ]; then
    echo "selfhost-component: STAGE=<n> is required" >&2
    exit 2
fi

# ---------------------------------------------------------------------------
# Stage -> producer binary mapping (binding).
# ---------------------------------------------------------------------------
case "$STAGE" in
    0) PRODUCER="./hcc" ;;
    1) PRODUCER="./build/hcc-bootstrap02" ;;
    2) PRODUCER="./build/hcc-bootstrap03" ;;
    *)
        echo "selfhost-component: unknown STAGE=$STAGE (expected 0|1|2)" >&2
        exit 1
        ;;
esac

# Platform-aware link-symbol prefix. Darwin prepends "_"
# to C symbol names in nm output; Linux does not. We
# encode the prefix here, NOT in the registry, because
# it is a link-decoration convention, not a component
# identity.
case "$(uname -s 2>/dev/null || echo unknown)" in
    Darwin)
        LINK_PREFIX="_"
        ;;
    *)
        LINK_PREFIX=""
        ;;
esac

# Validate registry (mandatory; no hidden defaults).
if ! python3 "$VALIDATOR" "$REGISTRY" >/dev/null; then
    echo "selfhost-component: registry validation FAILED" >&2
    exit 1
fi

# Parse the row for COMPONENT in a way that does NOT eval
# the values. We use awk to extract fields by index.
ROW=$(awk -F'\t' -v cid="$COMPONENT" '
    NR == 1 { next }
    $1 == cid { print; exit }
' "$REGISTRY")

if [ -z "$ROW" ]; then
    echo "selfhost-component: unknown component_id: $COMPONENT" >&2
    exit 1
fi

ROW_SOURCE=$(echo "$ROW" | awk -F'\t' '{ print $2 }')
ROW_SYMBOL=$(echo "$ROW" | awk -F'\t' '{ print $3 }')
ROW_ORACLE=$(echo "$ROW" | awk -F'\t' '{ print $7 }')
ROW_CURSOR=$(echo "$ROW" | awk -F'\t' '{ print $8 }')
ROW_SEAM=$(echo "$ROW" | awk -F'\t' '{ print $9 }')
ROW_STATE=$(echo "$ROW" | awk -F'\t' '{ print $6 }')

if [ "$ROW_STATE" = "DISABLED" ]; then
    echo "selfhost-component: $COMPONENT is DISABLED in registry; refusing to build" >&2
    exit 1
fi

# Compute deterministic generic output path.
GENERIC_OUT="build/selfhost/stage${STAGE}/${COMPONENT}.o"
mkdir -p "$(dirname "$GENERIC_OUT")"

# Sanity: source must exist and not alias the generic output.
if [ ! -f "$ROW_SOURCE" ]; then
    echo "selfhost-component: source missing: $ROW_SOURCE" >&2
    exit 1
fi
NORM_SRC=$(cd "$(dirname "$ROW_SOURCE")" && pwd)/$(basename "$ROW_SOURCE")
NORM_OUT=$(cd "$(dirname "$GENERIC_OUT")" && pwd)/$(basename "$GENERIC_OUT")
if [ "$NORM_SRC" = "$NORM_OUT" ]; then
    echo "selfhost-component: generic output aliases source ($NORM_OUT)" >&2
    exit 1
fi

if [ ! -x "$PRODUCER" ]; then
    echo "selfhost-component: producer $PRODUCER missing or not executable" >&2
    echo "selfhost-component: required for STAGE=$STAGE; build the previous stage first" >&2
    exit 1
fi

# Ensure test-prefix is set up; producers require it.
if [ ! -x "$REPO_ROOT/test-prefix-install" ] && [ ! -d "$TEST_PREFIX" ]; then
    mkdir -p "$TEST_PREFIX"
fi

# Build (registry fields are DATA; we drive the compiler
# with hardcoded flags, never with $ROW_SOURCE in an eval).
rm -f "$GENERIC_OUT"

# All stages use the same compile invocation. The only
# thing that changes between stages is which PRODUCER
# binary drives the compilation. The compiler receives
# only --install-dir, -c, -o; it never sees the registry.
"$PRODUCER" --install-dir="$TEST_PREFIX" \
    -c "$ROW_SOURCE" \
    -o "$GENERIC_OUT"
BUILD_RC=$?

if [ "$BUILD_RC" -ne 0 ] || [ ! -f "$GENERIC_OUT" ]; then
    echo "selfhost-component: build FAILED (rc=$BUILD_RC, output=$GENERIC_OUT)" >&2
    exit 1
fi

# Verify the expected symbol (platform-decorated).
EXPECTED="${LINK_PREFIX}${ROW_SYMBOL}"
if ! nm "$GENERIC_OUT" | grep -Eq " [TBDRS] ${EXPECTED}$"; then
    echo "selfhost-component: expected symbol ${EXPECTED} not found in ${GENERIC_OUT}" >&2
    echo "selfhost-component: nm output:" >&2
    nm "$GENERIC_OUT" | grep -E " [TBDRS] " >&2 || true
    exit 1
fi
SYMBOL_CHECK=PASS

# Provenance (binding fields).
PRODUCER_SHA=$(sha256sum "$PRODUCER" 2>/dev/null | awk '{ print $1 }' || echo "UNKNOWN")
OUTPUT_SHA=$(sha256sum "$GENERIC_OUT" 2>/dev/null | awk '{ print $1 }' || echo "UNKNOWN")

cat <<EOF
SELFHOST_COMPONENT_BUILD=PASS
SELFHOST_COMPONENT_ID=${COMPONENT}
SELFHOST_COMPONENT_SOURCE=${ROW_SOURCE}
SELFHOST_COMPONENT_PRODUCER_STAGE=${STAGE}
SELFHOST_COMPONENT_PRODUCER_BINARY=${PRODUCER}
SELFHOST_COMPONENT_PRODUCER_BINARY_SHA256=${PRODUCER_SHA}
SELFHOST_COMPONENT_OUTPUT=${GENERIC_OUT}
SELFHOST_COMPONENT_OUTPUT_SHA256=${OUTPUT_SHA}
SELFHOST_COMPONENT_EXPECTED_SYMBOL=${EXPECTED}
SELFHOST_COMPONENT_SYMBOL_CHECK=${SYMBOL_CHECK}
SELFHOST_COMPONENT_BUILD_RC=0
SELFHOST_COMPONENT_LINK_SYMBOL_PREFIX=${LINK_PREFIX}
SELFHOST_COMPONENT_REGISTRY=${REGISTRY}
EOF

if [ "$OP" = "test" ]; then
    # Test mode: run the registered Makefile gates. We
    # invoke `make` with the registered target names;
    # registry fields are consumed as bare arguments to
    # make, NOT as shell expressions, so no eval hazard.
    make -C "$REPO_ROOT" "$ROW_ORACLE"
    make -C "$REPO_ROOT" "$ROW_CURSOR"
    make -C "$REPO_ROOT" "$ROW_SEAM"
    cat <<EOF
SELFHOST_COMPONENT_TEST=PASS
SELFHOST_COMPONENT_TEST_ORACLE=${ROW_ORACLE}
SELFHOST_COMPONENT_TEST_CURSOR=${ROW_CURSOR}
SELFHOST_COMPONENT_TEST_SEAM=${ROW_SEAM}
EOF
fi
