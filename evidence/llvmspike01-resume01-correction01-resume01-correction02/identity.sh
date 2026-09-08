#!/usr/bin/env bash
# Re-generate identity.txt at any later HEAD.
# Usage: bash evidence/llvmspike01-resume01-correction01-resume01-correction02/identity.sh
set -euo pipefail
# resolve repo root from this script's path
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
cd "$root"
this=evidence/llvmspike01-resume01-correction01-resume01-correction02
{
  echo "# Identity (dynamic binding)"
  echo
  echo "ENTRY_HEAD  = bde6045a200a1526435fd161f41b59e02df012b7"
  echo
  echo "## Topology"
  echo "commits in bde6045a..HEAD  = $(git rev-list --count bde6045a200a1526435fd161f41b59e02df012b7..HEAD)"
  echo
  echo "## Closure subject (resolved dynamically)"
  SUBJECT=$(grep '^SUBJECT=' "$this/gate-push-final.log" | head -1 | cut -d= -f2)
  SUBJECT_FULL=$(git rev-parse "$SUBJECT^{commit}")
  echo "SUBJECT       = $SUBJECT"
  echo "SUBJECT_FULL  = $SUBJECT_FULL"
  echo "HEAD          = $(git rev-parse HEAD)"
  echo
  echo "## merge-base check"
  if git merge-base --is-ancestor "$SUBJECT_FULL" HEAD; then
    echo "SUBJECT_FULL ancestor of HEAD = YES"
  else
    echo "SUBJECT_FULL ancestor of HEAD = NO"
  fi
  echo
  echo "## P0-2 AC"
  out=$(git diff bde6045a200a1526435fd161f41b59e02df012b7..HEAD -- \
    evidence/llvmspike01-resume01-correction01/red-1B.emit-llvm.ll \
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.ll \
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.txt)
  [ -z "$out" ] && echo "diff -> empty (PASS)" || echo "AC FAIL: $out"
  echo
  echo "## C1 SHAs"
  shasum -a 256 \
    evidence/llvmspike01-resume01-correction01/red-1B.emit-llvm.ll \
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.ll \
    evidence/llvmspike01-resume01-correction01/red-2.emit-llvm.txt
} > "$this/identity.txt"
echo "regenerated $this/identity.txt"
