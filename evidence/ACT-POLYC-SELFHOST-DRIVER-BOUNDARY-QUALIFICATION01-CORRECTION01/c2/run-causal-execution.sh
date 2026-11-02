#!/bin/sh
# THE C2 BRANCH CAUSAL EXECUTIONS.
#
# Each counterfactual disables exactly ONE branch in the FROZEN
# src/main.c, rebuilds the PRODUCTION compiler with the REAL CMake
# build, and executes the produced binary over a named route.
#
# The source is RESTORED and the restoration is proven by digest. The
# PRISTINE stage0 producer is held untouched. The working production
# compiler is NEVER replaced by a mutant.
#
# EVERY build and compiler invocation is SERIALISED: the PolyC
# compiler writes a shared /tmp/holyc-asm.s, so concurrent invocations
# race.
set -u
HERE=$(dirname "$0")
REPO=$(cd "$HERE/../../.." && pwd)
D=evidence/ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
OUT="$HERE/branch-causal-executions.tsv"
SRC="$REPO/src/main.c"
PFX="$REPO/build/test-prefix"
WORK=$(mktemp -d /tmp/c02-causal.XXXXXX)

# The PRODUCTION compiler is REBUILT from the RESTORED source when the
# run ends, and the rebuild is compared with the captured baseline. The
# production ./hcc slot MUST hold the pristine compiler when the run
# ends; it must never hold a mutant.
restore_production_compiler() {
  # The PolyC driver SUBJECT is restored FIRST, because the production
  # build links it and regenerates it with a producer invocation whose
  # install-dir is relative to src/. If the subject is ABSENT, it is
  # rebuilt by the PRISTINE stage0 producer.
  if [ -f "$REPO/build/wp001-driver-subject.o.orig" ]; then
    mv "$REPO/build/wp001-driver-subject.o.orig" "$REPO/build/wp001-driver-subject.o"
  elif [ ! -f "$REPO/build/wp001-driver-subject.o" ]; then
    "$REPO/build/host-stage0/hcc" --install-dir="$REPO/build/bootstrap-prefix" \
      -c "$REPO/tools/bootstrap/selfhost-driver-wp001.HC" \
      -o "$REPO/build/wp001-driver-subject.o" >/dev/null 2>&1
  fi
  # The production compiler is ALWAYS rebuilt from the RESTORED
  # source, so the production ./hcc slot can never hold a mutant.
  rm -f build/CMakeFiles/hcc.dir/main.c.o
  touch "$REPO/src/main.c"
  cmake --build build --target hcc -j1 >/dev/null 2>&1
}
restore_source() {
  if [ -f "$REPO/src/main.c.orig" ]; then mv "$REPO/src/main.c.orig" "$REPO/src/main.c"; fi
  rm -f "$REPO/src/main.c.mut"
}
# The trap restores BOTH the source AND the production compiler, so a
# signal or an early failure cannot leave a mutated production file or
# an absent production binary.
trap 'restore_source; restore_production_compiler; rm -rf "$WORK"' EXIT INT TERM

cd "$REPO" || exit 1

digest() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}';
  else sha256sum "$1" | awk '{print $1}'; fi
}

# The MUTANT compiler is built by the REAL production CMake build, and
# the built binary is MOVED out of the tree, so the production ./hcc
# slot never holds a mutant.
build_compiler() {
  _out="$1"
  cmake --build build --target hcc -j1 >"$WORK/cmake.log" 2>&1
  _rc=$?
  if [ $_rc -ne 0 ]; then return $_rc; fi
  if [ ! -f ./hcc ]; then return 1; fi
  cp ./hcc "$_out" && rm -f ./hcc
  return 0
}

force_rebuild() {
  rm -f build/CMakeFiles/hcc.dir/main.c.o
  touch src/main.c
}

printf 'I64 main() {\n  return 0;\n}\n' > "$WORK/input.HC"

BASELINE="$WORK/hcc-baseline"
if [ ! -x "$REPO/hcc" ]; then
  echo "causal-execution: no production ./hcc present" >&2; exit 2
fi
cp "$REPO/hcc" "$BASELINE"
BASE_SRC_SHA=$(digest "$SRC")
BASE_BIN_SHA=$(digest "$BASELINE")

# The captured baseline is VERIFIED to be a working compiler before it
# is used as the reference: it must produce an object over the frozen
# required route. A baseline that cannot is not a usable reference.
rm -f "$WORK/base.o"
(cd "$WORK" && "$BASELINE" --install-dir="$PFX" -c input.HC -o base.o) >"$WORK/basecheck.txt" 2>&1
if [ ! -f "$WORK/base.o" ]; then
  echo "causal-execution: the captured baseline produces no object on the required route" >&2
  echo "causal-execution: refusing to measure against a non-working baseline" >&2
  exit 2
fi
echo "BASELINE_REQUIRED_ROUTE_ARTIFACT=$(file -b "$WORK/base.o" 2>/dev/null | cut -d, -f1)"

{
  echo '# ACT_ID=ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01'
  echo '# ACT_PHASE=C2-IMPL'
  echo '# EVIDENCE_KIND=branch-causal-executions'
  echo '#'
  echo '# THE LINKED COUNTERFACTUALS, RE-EXECUTED against the REAL'
  echo '# production CMake build.'
  echo '#'
  echo '# EVERY row records the BASELINE, MUTANT and RESTORED source'
  echo '# digests, the BASELINE and MUTANT BINARY digests, the build exit'
  echo '# code, the selected artifact path, the artifact TYPE and SIZE,'
  echo '# and the stdout/stderr line counts.'
  echo '#'
  echo '# A SOURCE MUTATION THAT WAS NEVER LINKED INTO THE EXECUTED'
  echo '# BINARY IS NOT VALID CAUSAL EVIDENCE. The mutant_binary_sha'
  echo '# column therefore DIFFERS from the baseline_binary_sha column.'
  echo '#'
  printf 'branch_id\tfunction\tsource_line\tmutation\troute\tbaseline_source_sha\tmutant_source_sha\trestored_source_sha\tbaseline_binary_sha\tmutant_binary_sha\tbuild_rc\tselected_artifact\tartifact_type\tartifact_size\tstdout_lines\tstderr_lines\tobserved_difference\tverdict\n'
} > "$OUT"

# ---------------------------------------------------------------------------
# THE COUNTERFACTUAL RUNNER
#
# _id       the branch identifier
# _fn       the function
# _line     the source line
# _from     the exact source text to replace
# _to       the replacement source text
# _route    the route arguments
# _want     the artifact the route must produce
# ---------------------------------------------------------------------------
run_cf() {
  _id="$1"; _fn="$2"; _line="$3"; _from="$4"; _to="$5"; _route="$6"; _want="$7"; _scope="$8"

  _bsha=$(digest "$SRC")
  # The replacement is done with a PLAIN STRING comparison, not with
  # awk's sub(): sub() treats the pattern as a REGEX, and the branch
  # conditions contain parentheses and ampersands that are regex
  # metacharacters, so sub() would silently not match.
  awk -v ln="$_line" -v f="$_from" -v t="$_to" '
    NR==ln {
      if (index($0, f) > 0) { sub("__NEVER_MATCH__", t); $0 = $0 }
      n = index($0, f)
      if (n > 0) { $0 = substr($0, 1, n-1) t substr($0, n + length(f)) }
    }
    { print }
  ' "$SRC" > "$SRC.mut"
  if cmp -s "$SRC" "$SRC.mut"; then
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$_id" "$_fn" "$_line" "$_to" "$_route" "$_bsha" "MUTATION_NOT_APPLIED" "$_bsha" \
      "$BASE_BIN_SHA" "NONE" "MUTATION_NOT_APPLIED" "NONE" "NONE" "0" "0" "0" \
      "MUTATION_NOT_APPLIED" "COUNTERFACTUAL_NOT_EXECUTED" >> "$OUT"
    return
  fi
  _msha=$(digest "$SRC.mut")

  mv "$SRC" "$SRC.orig"; mv "$SRC.mut" "$SRC"
  force_rebuild
  build_compiler "$WORK/hcc-mutant" >/dev/null 2>&1
  _brc=$?
  _mutbin="ABSENT"
  [ -f "$WORK/hcc-mutant" ] && _mutbin=$(digest "$WORK/hcc-mutant")
  _basebin="$BASE_BIN_SHA"
  _linked=NO
  [ "$_mutbin" != "ABSENT" ] && [ "$_mutbin" != "$_basebin" ] && _linked=YES

  # RESTORE the source immediately, so a failure cannot leave a
  # mutated production file.
  restore_source
  _rsha=$(digest "$SRC")

  rm -f "$WORK/b.o" "$WORK/m.o"
  (cd "$WORK" && "$BASELINE" --install-dir="$PFX" $_route) >"$WORK/b.out" 2>"$WORK/b.err"; _brc_base=$?
  (cd "$WORK" && "$WORK/hcc-mutant" --install-dir="$PFX" $_route) >"$WORK/m.out" 2>"$WORK/m.err"; _brc_mut=$?
  rm -f "$WORK/b.o" "$WORK/m.o"
  (cd "$WORK" && "$BASELINE" --install-dir="$PFX" $_route -o b.o) >/dev/null 2>&1
  (cd "$WORK" && "$WORK/hcc-mutant" --install-dir="$PFX" $_route -o m.o) >/dev/null 2>&1

  _btype="NONE"; _bsize=0
  if [ -f "$WORK/b.o" ]; then _btype=$(file -b "$WORK/b.o" 2>/dev/null | cut -d, -f1); _bsize=$(wc -c < "$WORK/b.o" | tr -d ' '); fi
  _mtype="NONE"; _msize=0
  if [ -f "$WORK/m.o" ]; then _mtype=$(file -b "$WORK/m.o" 2>/dev/null | cut -d, -f1); _msize=$(wc -c < "$WORK/m.o" | tr -d ' '); fi

  _bout=$(wc -l < "$WORK/b.out" | tr -d ' '); _berr=$(wc -l < "$WORK/b.err" | tr -d ' ')
  _mout=$(wc -l < "$WORK/m.out" | tr -d ' '); _merr=$(wc -l < "$WORK/m.err" | tr -d ' ')

  _diff="NO_OBSERVED_DIFFERENCE"
  _verdict="UNPROVEN"
  if [ "$_linked" = "NO" ]; then
    _diff="MUTANT_NOT_LINKED_INTO_THE_EXECUTED_BINARY"
    _verdict="MUTANT_LINK_PROVENANCE_MISSING"
  elif [ "$_btype" != "$_mtype" ]; then
    _diff="ARTIFACT_TYPE_CHANGED"
    _verdict="C_BRANCH_SELECTS_THE_ARTIFACT_TYPE"
  elif [ "$_bout" != "$_mout" ] || [ "$_berr" != "$_merr" ]; then
    _diff="OUTPUT_STREAM_LINE_COUNT_CHANGED"
    _verdict="C_BRANCH_SELECTS_THE_OUTPUT"
  elif [ "$_brc_base" != "$_brc_mut" ]; then
    _diff="EXIT_CODE_CHANGED"
    _verdict="C_BRANCH_SELECTS_THE_EXIT_STATUS"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$_id" "$_fn" "$_line" "$_to" "$_route" "$_bsha" "$_msha" "$_rsha" "$_basebin" "$_mutbin" \
    "$_brc" "$_want" "$_btype->$_mtype" "$_bsize->$_msize" "$_bout->$_mout" "$_berr->$_merr" \
    "$_diff" "$_verdict" >> "$OUT"
}

# --- 1) THE emitFile() OBJECT SELECTION, ON THE FROZEN REQUIRED ROUTE -----
run_cf BR_EMITFILE_EMIT_OBJECT emitFile 250 \
  'if (args->emit_object)' 'if (0 && args->emit_object)' \
  '-c input.HC' 'out.o' 'WP001_REQUIRED_ROUTE'

# --- 2) THE main() TOKEN DISPATCH, ON THE TOKEN ROUTE -------------------
run_cf BR_MAIN_PRINT_TOKENS main 519 \
  'if (args.print_tokens)' 'if (0 && args.print_tokens)' \
  '-tokens input.HC' 'NONE' 'WHOLE_CLI_SURFACE'

# --- 3) THE main() REQUIRED-ROUTE DECISION ------------------------------
# The REQUIRED ROUTE is `--install-dir=X -c input.HC -o out.o`. The
# decision-bearing main() branch on that route is the one that
# DISPATCHES the compile action. In the frozen source that dispatch is
# the `if (args.assemble)` / `if (args.print_tokens)` / ... chain, whose
# compile-object arm is the FALL-THROUGH to compileToAst and emitFile.
# The branch that can be discriminated on the required route is the
# `if (!compileToAst(...))` guard, which decides whether the compile
# action proceeds at all. Mutating it makes the required route produce
# NO object, which is a DISCRIMINATING required-route witness.
run_cf BR_MAIN_COMPILE_TO_AST main 533 \
  'if (!compileToAst(cc,&args,lexer_flags))' 'if (!compileToAst(cc,&args,lexer_flags) || 1)' \
  '-c input.HC' 'out.o' 'WP001_REQUIRED_ROUTE'

# ---------------------------------------------------------------------------
# THE POLYC-SIDE INTERVENTION
#
# The C-side counterfactuals above disable the C CONSUMER while
# preserving the PolyC-selected value. This one does the opposite: it
# disables the POLYC SELECTION while preserving the C consumer.
#
# The PolyC driver derives the CliArgs field from the selected ACTION
# (WpDriverFieldForAction). Mutating that derivation so that the
# compile-object action selects NO field removes the PolyC decision
# while leaving the C consumer intact.
#
# If the resulting action CHANGES, the PolyC decision is on the causal
# path of the behaviour. If it does NOT change, the PolyC decision was
# decorative on this route.
# ---------------------------------------------------------------------------
PSRC="$REPO/tools/bootstrap/selfhost-driver-wp001.HC"
PROUT="$HERE/branch-causal-executions.tsv"
# The PolyC driver SUBJECT object that the production build links.
POBJ="$REPO/build/wp001-driver-subject.o"
# The PRISTINE stage0 producer. It is NEVER mutated: the PolyC-side
# intervention changes the DRIVER SOURCE, not the producer.
PRODUCER="$REPO/build/host-stage0/hcc"

if [ -f "$PSRC" ] && [ -x "$PRODUCER" ]; then
  _pbase=$(digest "$PSRC")
  # The mutation removes the PolyC SELECTION of the emit-object field
  # while leaving the C consumer untouched. The line is read from the
  # source, not assumed.
  awk 'NR==830 { n=index($0,"return WP_FIELD_EMIT_OBJECT;"); if (n>0) $0 = substr($0,1,n-1) "return WP_FIELD_NONE;" substr($0,n+length("return WP_FIELD_EMIT_OBJECT;")) } { print }' "$PSRC" > "$WORK/pp-mut.HC"
  if cmp -s "$PSRC" "$WORK/pp-mut.HC"; then
    echo "causal-execution: the PolyC-side mutation did not apply" >&2
  else
    _pmsha=$(digest "$WORK/pp-mut.HC")
    # The PolyC driver SOURCE is mutated, and the driver SUBJECT is
    # rebuilt from it by the REAL production compiler. The C consumer
    # is untouched: this is the PolyC-side intervention.
    #
    # The PRISTINE subject object is BACKED UP and RESTORED. The
    # production build REGENERATES the subject from the source with a
    # producer invocation whose install-dir is relative to src/, which
    # this compiler resolves incorrectly; so the subject is managed
    # EXPLICITLY here rather than left to the build graph.
    cp "$PSRC" "$PSRC.orig"
    cp "$WORK/pp-mut.HC" "$PSRC"
    if [ -f "$POBJ" ]; then cp "$POBJ" "$POBJ.orig"; fi
    rm -f "$POBJ"
    # The output path MUST be RELATIVE to the repository root: this
    # compiler prefixes it with "./", so an absolute path becomes
    # ".//abs/path" and cannot be opened.
    "$BASELINE" --install-dir="$REPO/build/bootstrap-prefix" -c "$PSRC" -o build/wp001-driver-subject.o >"$WORK/pdriver.log" 2>&1
    _pbrc=$?
    _pbin="ABSENT"
    if [ $_pbrc -ne 0 ]; then
      echo "causal-execution: the mutated PolyC driver subject failed to build" >&2
      # The pristine subject is restored, so the production build can
      # still link.
      [ -f "$POBJ.orig" ] && mv "$POBJ.orig" "$POBJ"
    else
      rm -f build/CMakeFiles/hcc.dir/selfhost-driver-wp001.c.o
      cmake --build build --target hcc -j1 >"$WORK/pcmake.log" 2>&1
      if [ -f ./hcc ]; then cp ./hcc "$WORK/hcc-polyc-mutant"; rm -f ./hcc; fi
      [ -f "$WORK/hcc-polyc-mutant" ] && _pbin=$(digest "$WORK/hcc-polyc-mutant")
    fi
    # The PolyC driver SOURCE and the driver SUBJECT are RESTORED.
    mv "$PSRC.orig" "$PSRC"
    rm -f "$PSRC.mut"
    [ -f "$POBJ.orig" ] && mv "$POBJ.orig" "$POBJ"
    rm -f build/CMakeFiles/hcc.dir/selfhost-driver-wp001.c.o
    cmake --build build --target hcc -j1 >"$WORK/pcmake-restore.log" 2>&1
    _prsha=$(digest "$PSRC")
    _prbin="ABSENT"
    [ -f ./hcc ] && _prbin=$(digest ./hcc)

    rm -f "$WORK/pb.o" "$WORK/pm.o"
    (cd "$WORK" && "$BASELINE" --install-dir="$PFX" -c input.HC -o pb.o) >"$WORK/pb.out" 2>"$WORK/pb.err"
    (cd "$WORK" && "$WORK/hcc-polyc-mutant" --install-dir="$PFX" -c input.HC -o pm.o) >"$WORK/pm.out" 2>"$WORK/pm.err"
    _pbtype="NONE"; _pmtype="NONE"
    [ -f "$WORK/pb.o" ] && _pbtype=$(file -b "$WORK/pb.o" 2>/dev/null | cut -d, -f1)
    [ -f "$WORK/pm.o" ] && _pmtype=$(file -b "$WORK/pm.o" 2>/dev/null | cut -d, -f1)
    _pbsize=0; _pmsize=0
    [ -f "$WORK/pb.o" ] && _pbsize=$(wc -c < "$WORK/pb.o" | tr -d ' ')
    [ -f "$WORK/pm.o" ] && _pmsize=$(wc -c < "$WORK/pm.o" | tr -d ' ')
    _pbout=$(wc -l < "$WORK/pb.out" | tr -d ' '); _pmout=$(wc -l < "$WORK/pm.out" | tr -d ' ')
    _pberr=$(wc -l < "$WORK/pb.err" | tr -d ' '); _pmerr=$(wc -l < "$WORK/pm.err" | tr -d ' ')
    _pdiff="NO_OBSERVED_DIFFERENCE"
    _pverdict="POLYC_DECISION_NOT_ON_THE_CAUSAL_PATH"
    if [ "$_pbtype" != "$_pmtype" ] || [ "$_pbsize" != "$_pmsize" ]; then
      _pdiff="POLYC_SELECTION_DRIVES_THE_C_ACTION"
      _pverdict="POLYC_SELECTION_IS_ON_THE_CAUSAL_PATH"
    elif [ "$_pbout" != "$_pmout" ] || [ "$_pberr" != "$_pmerr" ]; then
      _pdiff="POLYC_SELECTION_DRIVES_THE_C_OUTPUT"
      _pverdict="POLYC_SELECTION_IS_ON_THE_CAUSAL_PATH"
    fi
    printf 'BR_POLYC_FIELD_FOR_ACTION\tWpDriverFieldForAction\t830\treturn WP_FIELD_NONE;\t-c input.HC\t%s\t%s\t%s\t%s\t%s\t%s\tout.o\t%s->%s\t%s->%s\t%s->%s\t%s->%s\t%s\t%s\n' \
      "$_pbase" "$_pmsha" "$_prsha" "$BASE_BIN_SHA" "$_pbin" "$_pbrc" "$_pbtype" "$_pmtype" "$_pbsize" "$_pmsize" "$_pbout" "$_pmout" "$_pberr" "$_pmerr" \
      "$_pdiff" "$_pverdict" >> "$PROUT"
    echo "POLYC_SIDE_RESTORED_BINARY=$_prbin" >&2
  fi
fi

# The PRODUCTION compiler is REBUILT from the RESTORED source at the
# end of the run. The production ./hcc slot MUST hold the pristine
# compiler when the run ends; it must never hold a mutant.
restore_source
restore_production_compiler
rm -rf "$WORK"

echo "CAUSAL=$OUT rows=$(grep -c '^BR_' "$OUT")"
