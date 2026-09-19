#!/bin/sh
# scripts/quality/libtos-n02-harness.sh
#
# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02 C2-3 thin dispatch
# wrapper. The substantive logic lives in the PolyC tool
# tools/quality/libtos-n02-isolate.HC. This shell script is
# argument-parsing + scratch-dir setup glue only (<=50 LOC).
#
# Usage:
#   scripts/quality/libtos-n02-harness.sh \
#       --pristine-archive <path-to-libtos.a> \
#       --scratch-dir <dir>
set -eu
PRISTINE=""
SCRATCH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --pristine-archive) PRISTINE="$2"; shift 2;;
    --scratch-dir)      SCRATCH="$2";  shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -n "$PRISTINE" ] && [ -n "$SCRATCH" ] || { echo "usage: --pristine-archive X --scratch-dir Y" >&2; exit 2; }
REPO_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HCC="${LIBTOS_HCC:-$REPO_ROOT/build/hcc-bootstrap04}"
OBJCOPY="${LIBTOS_OBJCOPY:-/opt/homebrew/opt/llvm@21/bin/llvm-objcopy}"
TOOL="$REPO_ROOT/build/libtos-n02-isolate"
mkdir -p "$SCRATCH"
cp "$PRISTINE" "$SCRATCH/libtos-pristine.a"
# The PolyC tool runs from its own directory (it uses relative
# paths for ar/nm). It takes the pristine archive name via -p
# and the scratch dir via -s. From inside the scratch dir, the
# pristine archive is at ./libtos-pristine.a.
exec "$TOOL" -p "$SCRATCH/libtos-pristine.a" -s "$SCRATCH" -c "$HCC" -o "$OBJCOPY"
