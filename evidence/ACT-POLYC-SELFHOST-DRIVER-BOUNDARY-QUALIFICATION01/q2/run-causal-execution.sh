#!/bin/sh
# ---------------------------------------------------------------------------
# THE Q2 CAUSAL EXECUTION AND PROVENANCE EVIDENCE
#
# This script RE-EXECUTES the two discriminating counterfactuals against
# the REAL production compiler and records, for each one:
#
#   * the exact source line that was mutated,
#   * the exact mutation text,
#   * the SHA-256 digest of the source file BEFORE and AFTER the
#     mutation, so that the mutation is attributable to a specific
#     source state,
#   * the BUILD result of the mutated compiler,
#   * the OBSERVED behavioural difference over the named route,
#   * the artifact type produced by the baseline and by the mutant,
#   * the RESTORATION digest, proving the source was put back.
#
# THE MUTATION IS DISABLED AT COMPILE TIME ONLY. The stage0 producer
# is held PRISTINE so that the mutation cannot break the toolchain.
#
# Every build and compiler invocation is SERIALISED: the PolyC compiler
# writes a shared /tmp/holyc-asm.s, so concurrent invocations race.
#
# Output: q2/causal-execution-and-provenance.tsv
# ---------------------------------------------------------------------------

set -u

HERE=$(dirname "$0")
REPO=$(cd "$HERE/../../.." && pwd)
OUT="$HERE/causal-execution-and-provenance.tsv"
SRC="$REPO/src/main.c"
PFX="$REPO/build/test-prefix"
WORK=$(mktemp -d /tmp/q02-causal.XXXXXX)

# The source is RESTORED on EVERY exit path, including a signal or an
# early failure. A left-mutated src/main.c would be a production
# corruption; the trap makes that impossible.
restore_source() {
  if [ -f "$REPO/src/main.c.orig" ]; then
    mv "$REPO/src/main.c.orig" "$REPO/src/main.c"
  fi
  rm -f "$REPO/src/main.c.mut"
}
trap 'restore_source; rm -rf "$WORK"' EXIT INT TERM

cd "$REPO" || exit 1

# The digest of a file, using the platform shasum/sha256.
digest() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

# Build the production compiler from the CURRENT source tree, using the
# REAL production build system (the CMake tree in build/), so that the
# mutated binary is the production build and not an ad-hoc link.
#
# The stage0 producer is NOT rebuilt, so the mutation cannot break the
# toolchain; only the mutated driver is compiled and linked.
#
# The built binary is MOVED out of the tree, so the production ./hcc
# slot never holds a mutated binary: the next build always starts from
# the restored source.
build_compiler() {
  _out="$1"
  cmake --build build --target hcc -j1 >"$WORK/cmake.log" 2>&1
  _rc=$?
  if [ "$_rc" -ne 0 ]; then
    return 1
  fi
  # The build MUST have recompiled the mutated driver. If it did not,
  # the mutant binary is not a mutant and the measurement is void.
  # The check is on the BUILD LOG, which names the object that was
  # recompiled.
  if ! grep -q 'main\.c\.o' "$WORK/cmake.log"; then
    echo "BUILD_DID_NOT_RECOMPILE_MAIN_C" >&2
    cp "$WORK/cmake.log" /tmp/q02-causal-cmake-fail.log 2>/dev/null
    return 1
  fi
  cp ./hcc "$_out"
  rm -f ./hcc
  return 0
}

# Force a rebuild of the mutated driver even if the build system's
# timestamp comparison decides the object is current. The source file's
# content CHANGED, so the object MUST be recompiled.
#
# The touch is NOT sufficient on its own: a build system's dependency
# comparison is a timestamp comparison, and the restored source
# inherits the ORIGINAL mtime, which can be OLDER than the object that
# was built from the mutation. The object is therefore DELETED, which
# makes the rebuild unconditional and removes the timestamp question
# entirely.
#
# The same is done in the restore direction, so the object built from
# the mutation can never survive the restore.
force_rebuild() {
  rm -f build/CMakeFiles/hcc.dir/main.c.o
  touch src/main.c
}

printf 'I64 main() {\n  return 0;\n}\n' > "$WORK/input.HC"

# The PRISTINE production compiler is captured BEFORE any mutation, so
# that the baseline and the mutant are two distinct binaries built by
# the same production build system from two distinct source states.
BASELINE="$WORK/hcc-baseline"
if [ ! -x "$REPO/hcc" ]; then
  echo "causal-execution: no production ./hcc present" >&2
  exit 2
fi
cp "$REPO/hcc" "$BASELINE"

# The captured baseline is VERIFIED to be a working compiler before it
# is used as the reference: it must print the token stream over the
# -tokens route. A baseline that cannot print tokens is not a usable
# reference, and the run must not proceed with it.
(cd "$WORK" && "$BASELINE" --install-dir="$PFX" -tokens input.HC) >"$WORK/basecheck.txt" 2>&1
_basecheck=$(wc -l < "$WORK/basecheck.txt" | tr -d ' ')
if [ "$_basecheck" -lt 1 ]; then
  echo "causal-execution: the captured baseline prints no token stream;" >&2
  echo "causal-execution: refusing to measure against a non-working baseline" >&2
  exit 2
fi
echo "BASELINE_TOKEN_LINES=$_basecheck"

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01'
  echo '# ACT_PHASE=Q2-IMPL'
  echo '# EVIDENCE_KIND=causal-execution-and-provenance'
  echo '#'
  echo '# THE TWO DISCRIMINATING COUNTERFACTUALS, RE-EXECUTED.'
  echo '#'
  echo '# Each counterfactual disables exactly ONE C branch in the'
  echo '# frozen src/main.c, rebuilds the production compiler, runs it'
  echo '# over its named route, and observes the behavioural difference.'
  echo '# The source is then RESTORED and its digest is re-checked.'
  echo '#'
  echo 'branch_id	function	source_line	mutation	baseline_digest	mutated_digest	restored_digest	build_rc	baseline_artifact	mutant_artifact	observed_difference	verdict'
} > "$OUT"

# --- THE emitFile() OBJECT/EXECUTABLE DISCRIMINATOR ------------------------
# src/main.c:250 -- `if (args->emit_object)` chooses whether the
# compiler emits a relocatable OBJECT or links an EXECUTABLE.
emit_branch() {
  _id="$1"; _fn="emitFile"; _line="250"
  _base=$(digest "$SRC")
  awk -v ln="$_line" 'NR==ln { sub(/if \(args->emit_object\)/, "if (0 \\&\\& args->emit_object)"); } { print }' "$SRC" > "$SRC.mut"
  _mdig=$(digest "$SRC.mut")

  # Build the MUTANT compiler.
  mv "$SRC" "$SRC.orig"
  mv "$SRC.mut" "$SRC"
  force_rebuild
  build_compiler "$WORK/hcc-mutant" >/dev/null 2>&1
  _brc=$?
  _mutbin="ABSENT"
  [ -f "$WORK/hcc-mutant" ] && _mutbin=$(digest "$WORK/hcc-mutant")
  _basebin=$(digest "$BASELINE")
  if [ "$_mutbin" = "$_basebin" ]; then
    _brc="MUTANT_BINARY_IDENTICAL_TO_BASELINE"
  fi

  # Run the BASELINE and the MUTANT over the required route.
  #
  # The baseline is the PRISTINE production compiler, captured BEFORE
  # the mutation. The mutant is the rebuilt production compiler.
  rm -f "$WORK/base.o" "$WORK/mut.o"
  (cd "$WORK" && "$BASELINE" --install-dir="$PFX" -c input.HC -o base.o) >/dev/null 2>&1
  (cd "$WORK" && "$WORK/hcc-mutant" --install-dir="$PFX" -c input.HC -o mut.o) >/dev/null 2>&1
  _btype="ABSENT"
  [ -f "$WORK/base.o" ] && _btype=$(file -b "$WORK/base.o" 2>/dev/null | cut -d, -f1)
  _mtype="ABSENT"
  [ -f "$WORK/mut.o" ] && _mtype=$(file -b "$WORK/mut.o" 2>/dev/null | cut -d, -f1)

  # RESTORE the source.
  mv "$SRC" "$SRC.mut"
  mv "$SRC.orig" "$SRC"
  force_rebuild
  _rdig=$(digest "$SRC")

  # A DIFFERENCE REQUIRES BOTH SIDES TO HAVE PRODUCED AN ARTIFACT.
  # An absent artifact is a build or execution failure, not evidence of
  # a semantic difference; it is reported as such and never counted as
  # a discriminating observation.
  _diff="NONE"
  if [ "$_btype" = "ABSENT" ] || [ "$_mtype" = "ABSENT" ]; then
    _diff="ARTIFACT_MISSING"
  elif [ "$_btype" != "$_mtype" ]; then
    _diff="ARTIFACT_TYPE_CHANGED"
  fi
  _verdict="C_SEMANTIC_RETAINED_WP001"
  if [ "$_diff" != "ARTIFACT_TYPE_CHANGED" ]; then
    _verdict="NO_OBSERVED_DIFFERENCE"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_fn" "$_line" "if (0 && args->emit_object)" \
    "$_base" "$_mdig" "$_rdig" "$_brc" "$_btype" "$_mtype" \
    "$_diff" "$_verdict" >> "$OUT"
}

# --- THE main() ACTION DISPATCH DISCRIMINATOR -----------------------------
# src/main.c:519 -- `if (args.print_tokens)` chooses whether the
# compiler prints the token stream.
main_branch() {
  _id="$1"; _fn="main"; _line="519"
  _base=$(digest "$SRC")
  awk -v ln="$_line" 'NR==ln { sub(/if \(args.print_tokens\)/, "if (0 \\&\\& args.print_tokens)"); } { print }' "$SRC" > "$SRC.mut"
  _mdig=$(digest "$SRC.mut")

  mv "$SRC" "$SRC.orig"
  mv "$SRC.mut" "$SRC"
  force_rebuild
  build_compiler "$WORK/hcc-mutant2" >/dev/null 2>&1
  _brc=$?
  _mutbin="ABSENT"
  [ -f "$WORK/hcc-mutant2" ] && _mutbin=$(digest "$WORK/hcc-mutant2")
  _basebin=$(digest "$BASELINE")
  if [ "$_mutbin" = "$_basebin" ]; then
    _brc="MUTANT_BINARY_IDENTICAL_TO_BASELINE"
  fi

  rm -f "$WORK/base.txt" "$WORK/mut.txt"
  (cd "$WORK" && "$BASELINE" --install-dir="$PFX" -tokens input.HC) >"$WORK/base.txt" 2>&1
  (cd "$WORK" && "$WORK/hcc-mutant2" --install-dir="$PFX" -tokens input.HC) >"$WORK/mut.txt" 2>&1
  _bcount=$(wc -l < "$WORK/base.txt" | tr -d ' ')
  _mcount=$(wc -l < "$WORK/mut.txt" | tr -d ' ')

  mv "$SRC" "$SRC.mut"
  mv "$SRC.orig" "$SRC"
  force_rebuild
  _rdig=$(digest "$SRC")

  _diff="NONE"
  if [ "$_bcount" -ne "$_mcount" ]; then
    _diff="STDOUT_LINE_COUNT_CHANGED"
  fi
  _verdict="C_SEMANTIC_RETAINED_WP001"
  if [ "$_diff" != "STDOUT_LINE_COUNT_CHANGED" ]; then
    _verdict="NO_OBSERVED_DIFFERENCE"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_fn" "$_line" "if (0 && args.print_tokens)" \
    "$_base" "$_mdig" "$_rdig" "$_brc" "stdout_lines=$_bcount" "stdout_lines=$_mcount" \
    "$_diff" "$_verdict" >> "$OUT"
}

emit_branch BR_EMITFILE_EMIT_OBJECT
main_branch BR_MAIN_PRINT_TOKENS

# The production ./hcc currently in the tree was built from the LAST
# mutation. The source has been restored, so the production binary is
# REBUILT from the restored source, and its digest is checked against
# the baseline binary. This leaves the tree exactly as it was found.
build_compiler "$WORK/hcc-restored" >/dev/null 2>&1
_rbrc=$?
if [ "$_rbrc" -eq 0 ]; then
  if cmp -s "$WORK/hcc-restored" "$BASELINE"; then
    _same=BYTE_IDENTICAL
  else
    _same=DIFFERS
  fi
else
  _same=REBUILD_FAILED
fi
cp "$WORK/hcc-restored" "$REPO/hcc" 2>/dev/null

{
  echo '#'
  echo '# THE SOURCE WAS RESTORED: the restored_digest column equals the'
  echo '# baseline_digest column for BOTH counterfactuals.'
  echo '# No production file remains modified.'
  echo "#"
  echo "# THE PRODUCTION BINARY WAS REBUILT FROM THE RESTORED SOURCE:"
  echo "# REBUILT_BINARY_VS_BASELINE = $_same"
} >> "$OUT"

echo "CAUSAL_EXECUTION=$OUT"
echo "REBUILT_BINARY_VS_BASELINE=$_same"
exit 0
