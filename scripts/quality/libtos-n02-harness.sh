#!/bin/bash
#
# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01 C2-4: N02 harness.
#
# Negative control N02: link is sensitive to actual symbol availability.
# The corrupted archive must contain ALL pristine members with ONLY
# _SpawnAndCapture's visibility changed from T to t. The link failure
# must be attributable to the symbol-hiding mutation alone.
#
# Procedure (per ACT §5 C2-4):
#   1. Verify prerequisites (archive exists, llvm-objcopy available).
#   2. Extract pristine archive members into a fresh scratch dir.
#   3. Use llvm-objcopy --localize-symbol to hide ONLY _SpawnAndCapture.
#   4. Verify the modified all.o has _SpawnAndCapture as 't' (local),
#      all other T symbols still as 'T' (global).
#   5. Rebuild corrupted archive via `ar rcs` with the modified all.o
#      AND the original errno_shim.o. errno_shim.o is NOT recompiled.
#   6. Compile a minimal PolyC consumer that requires _SpawnAndCapture
#      AND nothing else from libtos (Free, _Exit).
#   7. Link the consumer against the corrupted archive.
#   8. Verify the link fails with ONLY _SpawnAndCapture undefined.
#
# AC23 PASS iff:
#   HIDDEN_SYMBOL_LINK_RC=fail
#   UNDEFINED_SYMBOLS=_SpawnAndCapture (only)
#   CORRUPTED_ARCHIVE_PRESERVED_SYMBOLS=_FREE,_STRNCMP,_MEMSET,_STRLEN_FAST,_Errno
#   CORRUPTED_ARCHIVE_HIDDEN_SYMBOLS=_SpawnAndCapture
#   ERRNO_SHIM_IN_CORRUPTED=YES

set -u

# Defaults
PRISTINE_ARCHIVE="${TEST_PREFIX:-./build/test-prefix}/lib/libtos.a"
SCRATCH_DIR=""
CONSUMER_SRC=""

# Allow override
while [ $# -gt 0 ]; do
    case "$1" in
        --pristine-archive) PRISTINE_ARCHIVE="$2"; shift 2 ;;
        --scratch-dir)      SCRATCH_DIR="$2"; shift 2 ;;
        --consumer-src)     CONSUMER_SRC="$2"; shift 2 ;;
        *) echo "n02-harness: unknown arg '$1'" >&2; exit 2 ;;
    esac
done

# Pristine archive must exist
if [ ! -f "$PRISTINE_ARCHIVE" ]; then
    echo "n02-harness: FAIL: pristine archive $PRISTINE_ARCHIVE does not exist"
    echo "  (run 'make lib-tos' first to populate the test prefix)"
    exit 1
fi

# llvm-objcopy must be available
if ! command -v llvm-objcopy >/dev/null 2>&1; then
    echo "n02-harness: FAIL: llvm-objcopy not on PATH"
    exit 1
fi

# Use mktemp for scratch if not provided
if [ -z "$SCRATCH_DIR" ]; then
    SCRATCH_DIR="$(mktemp -d -t libtos-n02.XXXXXX)"
fi
mkdir -p "$SCRATCH_DIR"
echo "n02-harness: scratch dir: $SCRATCH_DIR"

# Step 1: extract pristine archive members
echo "n02-harness: step 1/8: extract pristine members"
(cd "$SCRATCH_DIR" && ar x "$PRISTINE_ARCHIVE") > "$SCRATCH_DIR/extract.log" 2>&1
if [ ! -f "$SCRATCH_DIR/all.o" ]; then
    echo "n02-harness: FAIL: pristine archive missing all.o"
    ls -la "$SCRATCH_DIR"
    exit 3
fi
if [ ! -f "$SCRATCH_DIR/errno_shim.o" ]; then
    echo "n02-harness: FAIL: pristine archive missing errno_shim.o"
    ls -la "$SCRATCH_DIR"
    exit 3
fi

# Step 2: verify pristine has _SpawnAndCapture as T
echo "n02-harness: step 2/8: verify pristine has T _SpawnAndCapture"
if ! nm "$SCRATCH_DIR/all.o" | grep -q ' T _SpawnAndCapture$'; then
    echo "n02-harness: FAIL: pristine all.o does not have T _SpawnAndCapture"
    nm "$SCRATCH_DIR/all.o" | grep -i spawn
    exit 4
fi

# Step 3: localize _SpawnAndCapture
echo "n02-harness: step 3/8: llvm-objcopy --localize-symbol=_SpawnAndCapture"
llvm-objcopy --localize-symbol=_SpawnAndCapture "$SCRATCH_DIR/all.o" \
    "$SCRATCH_DIR/all-corrupted.o" 2> "$SCRATCH_DIR/objcopy.log"
if [ ! -f "$SCRATCH_DIR/all-corrupted.o" ]; then
    echo "n02-harness: FAIL: llvm-objcopy did not produce corrupted all.o"
    cat "$SCRATCH_DIR/objcopy.log"
    exit 5
fi

# Step 4: verify the modification
echo "n02-harness: step 4/8: verify _SpawnAndCapture is now 't' (local)"
if ! nm "$SCRATCH_DIR/all-corrupted.o" | grep -q ' t _SpawnAndCapture$'; then
    echo "n02-harness: FAIL: _SpawnAndCapture is NOT localized"
    nm "$SCRATCH_DIR/all-corrupted.o" | grep -i spawn
    exit 6
fi

# Verify other required symbols are STILL T (global)
echo "n02-harness: step 4b/8: verify other T symbols preserved"
for sym in _FREE _STRNCMP _MEMSET _STRLEN_FAST; do
    if ! nm "$SCRATCH_DIR/all-corrupted.o" | grep -q " T ${sym}\$"; then
        echo "n02-harness: FAIL: pristine required symbol $sym is no longer T in modified all.o"
        exit 7
    fi
done

# Step 5: rebuild corrupted archive
echo "n02-harness: step 5/8: ar rcs libtos-corrupted.a all.o errno_shim.o"
# Use the modified all-corrupted.o as all.o in the archive so the
# corruption is the ONLY mutation relative to the pristine archive.
cp "$SCRATCH_DIR/all-corrupted.o" "$SCRATCH_DIR/all.o"
(cd "$SCRATCH_DIR" && ar rcs libtos-corrupted.a all.o errno_shim.o) \
    > "$SCRATCH_DIR/ar.log" 2>&1
if [ ! -f "$SCRATCH_DIR/libtos-corrupted.a" ]; then
    echo "n02-harness: FAIL: ar did not produce libtos-corrupted.a"
    cat "$SCRATCH_DIR/ar.log"
    exit 8
fi

# Verify corrupted archive structure
echo "n02-harness: step 5b/8: verify corrupted archive structure"
CORRUPTED_MEMBERS=$(ar t "$SCRATCH_DIR/libtos-corrupted.a" 2>/dev/null | sort)
# Filter out __.SYMDEF* (auto-generated by ar rcs; not relevant to mutation isolation)
CORRUPTED_DATA_MEMBERS=$(echo "$CORRUPTED_MEMBERS" | grep -v '^__\.SYMDEF' | sort)
EXPECTED_DATA_MEMBERS=$(printf "all.o\nerrno_shim.o" | sort)
if [ "$CORRUPTED_DATA_MEMBERS" != "$EXPECTED_DATA_MEMBERS" ]; then
    echo "n02-harness: FAIL: corrupted archive data members mismatch"
    echo "  expected: $EXPECTED_DATA_MEMBERS"
    echo "  actual:   $CORRUPTED_DATA_MEMBERS"
    exit 9
fi

# Verify _Errno is present (came from errno_shim.o)
if ! nm "$SCRATCH_DIR/libtos-corrupted.a" | grep -q ' T _Errno$'; then
    echo "n02-harness: FAIL: _Errno missing from corrupted archive"
    nm "$SCRATCH_DIR/libtos-corrupted.a" | grep -i errno
    exit 10
fi

# Verify _SpawnAndCapture is hidden in the archive
if nm "$SCRATCH_DIR/libtos-corrupted.a" | grep -q ' T _SpawnAndCapture$'; then
    echo "n02-harness: FAIL: _SpawnAndCapture is still T in corrupted archive"
    nm "$SCRATCH_DIR/libtos-corrupted.a" | grep -i spawn
    exit 11
fi

# Step 6: write minimal PolyC consumer
echo "n02-harness: step 6/8: write minimal consumer"
if [ -z "$CONSUMER_SRC" ]; then
    CONSUMER_SRC="$SCRATCH_DIR/_n02_consumer.HC"
    cat > "$CONSUMER_SRC" << 'CONSUMER_EOF'
// Minimal consumer that requires _SpawnAndCapture from libtos.
// Compiles to an object that references _SpawnAndCapture via the
// tooling_defs.HH forward declaration; does NOT inline the call.
#include "tooling_defs.HH"

U0 Test() {
  U8 *out = NULL;
  U8 *err = NULL;
  U8 *args[3];
  args[0] = "/bin/echo";
  args[1] = "hello";
  args[2] = NULL;
  I64 rc = SpawnAndCapture(args[0], args, &out, &err);
  if (out) Free(out);
  if (err) Free(err);
}

public U0 main(U64 argc, U8 **argv) {
  Test();
  Exit(0);
}
CONSUMER_EOF
fi

# Compile consumer
echo "n02-harness: step 6b/8: compile consumer"
# Find a working hcc: bootstrap preferred, then ./hcc
# Resolve to absolute path because we cd into SCRATCH_DIR below.
HCC=""
for cand in "./build/hcc-bootstrap04" "./hcc"; do
    if [ -x "$cand" ]; then
        HCC="$(cd "$(dirname "$cand")" && pwd)/$(basename "$cand")"
        break
    fi
done
if [ -z "$HCC" ]; then
    echo "n02-harness: FAIL: no hcc available"
    exit 12
fi
echo "n02-harness: using hcc=$HCC"
CONSUMER_OBJ="$SCRATCH_DIR/_n02_consumer.o"
INSTALL_DIR=$(dirname $(dirname "$PRISTINE_ARCHIVE"))
# hcc's include search uses CWD; pass tooling_defs.HH via absolute path
# embedded in the consumer source via a #include of the absolute path.
# We rewrite the consumer source so it includes via the absolute path.
# Locate the polyC repo root: this script is at $REPO_ROOT/scripts/quality/...
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ABS_HDR="$REPO_ROOT/src/holyc-lib/tooling_defs.HH"
sed "s|#include \"tooling_defs.HH\"|#include \"$ABS_HDR\"|" "$CONSUMER_SRC" \
    > "$SCRATCH_DIR/_n02_consumer_abs.HC"
CONSUMER_SRC_ABS="$SCRATCH_DIR/_n02_consumer_abs.HC"
(cd "$SCRATCH_DIR" && "$HCC" --install-dir="$INSTALL_DIR" \
    "$CONSUMER_SRC_ABS" -obj -o _n02_consumer.o) > "$SCRATCH_DIR/hcc.log" 2>&1
if [ ! -f "$CONSUMER_OBJ" ]; then
    echo "n02-harness: FAIL: consumer compile failed"
    cat "$SCRATCH_DIR/hcc.log"
    exit 13
fi

# Verify consumer requires _SpawnAndCapture
if ! nm -u "$CONSUMER_OBJ" | grep -q '_SpawnAndCapture$'; then
    echo "n02-harness: FAIL: consumer does not require _SpawnAndCapture"
    nm -u "$CONSUMER_OBJ"
    exit 14
fi

# Step 7: link against corrupted archive; expect FAIL with only _SpawnAndCapture undefined
echo "n02-harness: step 7/8: link consumer against corrupted archive"
LINK_LOG="$SCRATCH_DIR/link.log"
cc "$CONSUMER_OBJ" -L"$SCRATCH_DIR" -ltos-corrupted \
   -lpthread -lc -lm -o "$SCRATCH_DIR/_n02_consumer_corrupted" \
   > "$LINK_LOG" 2>&1
LINK_RC=$?

if [ "$LINK_RC" = "0" ]; then
    echo "n02-harness: FAIL: link succeeded against corrupted archive (RC=$LINK_RC)"
    echo "  expected: link failure citing _SpawnAndCapture"
    cat "$LINK_LOG"
    exit 15
fi

# Step 8: verify the only undefined symbol is _SpawnAndCapture
echo "n02-harness: step 8/8: verify only _SpawnAndCapture is undefined"
# Parse `ld: Undefined symbols:` block from the link log
UNDEFINED=$(awk '
  /^ld: Undefined symbols:/ { in_undef=1; next }
  in_undef && /^clang:/ { in_undef=0; next }
  in_undef && /^  _/ {
    # Strip leading whitespace and "referenced from:" tail
    line = $0
    sub(/^[[:space:]]+/, "", line)
    sub(/,.*$/, "", line)
    print line
  }
' "$LINK_LOG" | sort -u)
echo "n02-harness: undefined symbols reported:"
echo "$UNDEFINED" | sed 's/^/  /'

if [ -z "$UNDEFINED" ]; then
    echo "n02-harness: FAIL: link failed but no undefined symbols reported"
    cat "$LINK_LOG"
    exit 16
fi

# The ONLY undefined symbol must be _SpawnAndCapture
if [ "$UNDEFINED" != "_SpawnAndCapture" ]; then
    echo "n02-harness: FAIL: expected only _SpawnAndCapture undefined, got:"
    echo "$UNDEFINED" | sed 's/^/  /'
    echo "  This means N02 is confounded by additional mutations."
    exit 17
fi

# PASS
cat <<EOF
n02-harness: PASS
  HIDDEN_SYMBOL_LINK_RC=fail
  UNDEFINED_SYMBOLS=_SpawnAndCapture
  CORRUPTED_ARCHIVE_PRESERVED_SYMBOLS=_FREE,_STRNCMP,_MEMSET,_STRLEN_FAST,_Errno
  CORRUPTED_ARCHIVE_HIDDEN_SYMBOLS=_SpawnAndCapture
  ERRNO_SHIM_IN_CORRUPTED=YES
  N02=PASS
EOF
exit 0
