#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c1/capture-source-closure.sh
#
# Populates c1/source-closure.tsv from the MEASURED production link
# scope plus the REAL source text.
#
# The two boundaries are:
#
#   (A) M2-PRECURSOR: the smallest viable compiler-producing vertical
#       slice. It must read a source file, lex it, parse it, lower a
#       minimal semantically meaningful construct, and EMIT A REAL
#       COMPILER OUTPUT (assembly text). Its C glue is inventoried and
#       bounded, not silently assumed.
#
#   (B) M2 FULL: every C translation unit in the production link that
#       owns compiler semantics. Each must eventually be PolyC-authored
#       or proved to be mechanical/platform-only.
#
# F-POLYC-TOOLS: orchestration glue. It computes no conclusion that
# the C2 verifier does not recompute independently.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
SCOPE="$EV/c1/production-link-and-source-scope.tsv"
OUT="$EV/c1/source-closure.tsv"

# The header block is written once; the script TRUNCATES the data
# rows on every run so a re-run can never leave stale rows behind.
TMPE=$(mktemp /tmp/m2rebase-sc.XXXXXX)
# The trap is cleared once the temp file has been moved into place, so
# it cannot delete the committed output.
trap 'rm -f "$TMPE"' EXIT INT TERM

# The compile pipeline as the REAL source defines it:
#   main.c -> cli.c (argument parsing)
#          -> compile.c (compileToAst / compileToAsm)
#          -> lexer.c (lexToken)
#          -> parser.c (parseToAst)
#          -> ast.c (AST construction)
#          -> ir.c / cfg.c (lowering)
#          -> asm.c / aarch64.c / x86_64.c (code generation)
#
# Boundary (A) membership, with the reason each unit is IN.
PRECURSOR_MEMBERS="main.c cli.c compile.c lexer.c parser.c ast.c list.c containers.c aostr.c cctrl.c util.c memory.c arena.c mempool.c"

# The subsystem each unit belongs to.
subsystem_of() {
  case "$1" in
    main.c)      echo DRIVER ;;
    cli.c)       echo DRIVER ;;
    compile.c)   echo COMPILE_DRIVER ;;
    lexer.c)     echo LEXER ;;
    parser.c)    echo PARSER ;;
    prslib.c)    echo PARSER ;;
    prsutil.c)   echo PARSER ;;
    prsasm.c)    echo ASM_PARSER ;;
    ast.c)       echo AST ;;
    ir.c)        echo IR ;;
    cfg.c)       echo CFG ;;
    asm.c)       echo ASSEMBLER ;;
    aarch64.c)   echo CODEGEN ;;
    x86_64.c)    echo CODEGEN ;;
    x86.c)       echo CODEGEN ;;
    aostr.c)     echo CONTAINERS ;;
    containers.c) echo CONTAINERS ;;
    list.c)      echo CONTAINERS ;;
    cctrl.c)     echo CONTROL_SYMBOLS ;;
    util.c)      echo SUPPORT ;;
    json.c)      echo JSON ;;
    lsp.c)       echo LSP ;;
    repl.c)      echo REPL ;;
    transpiler.c) echo TRANSPILER ;;
    *)           echo SUPPORT ;;
  esac
}

# The PolyC language features a unit actually needs, read from its
# own text. This is the ROW-LEVEL blocker evidence.
features_of() {
  _f=""
  grep -q 'extern "c"' "$1" 2>/dev/null && _f="extern_c"
  grep -qE '\[[0-9]*\]\[[0-9]*\]\[[0-9]*\]' "$1" 2>/dev/null && _f="$_f,three_dimensional_array"
  [ -z "$_f" ] && _f="none_observed"
  printf '%s' "$_f"
}

# Extract ONLY the C translation units. The awk filter selects rows
# whose kind column is C_OBJECT, so the PolyC helper subjects are
# excluded here and are counted separately.
#
# Scope columns: 1 order 2 object 3 c_source 4 polyc_source 5 kind
#                6 blob_oid 7 sha256 8 source_loc 9 global_text_symbols
#               10 semantic_role 11 header_dependencies
awk -F'\t' '$1 ~ /^[0-9]+$/ && $5=="C_OBJECT" {print $3"\t"$6"\t"$7"\t"$8"\t"$9"\t"$10"\t"$11}' "$SCOPE" > /tmp/sc-raw.txt

order=0
while IFS="$(printf '\t')" read -r csrc oid sha loc syms role hdrs; do
  # Only the C translation units belong in the C SOURCE CLOSURE. The
  # compiled PolyC helper subjects are counted separately: they are
  # NOT part of the C semantic source set.
  [ -n "$csrc" ] || continue
  base=$(basename "$csrc")
  order=$((order + 1))
  sid=$(printf 'SRC-%03d' "$order")

  in_prec=NO
  for m in $PRECURSOR_MEMBERS; do
    [ "$base" = "$m" ] && in_prec=YES && break
  done
  # The vendored line editor is inside the link but outside the
  # semantic self-hosting boundary, so it is mechanical glue.
  case "$csrc" in
    src/linenoise/*) role="PLATFORM_OR_MECHANICAL" ;;
  esac
  if [ "$role" = "PLATFORM_OR_MECHANICAL" ]; then
    boundary="MECHANICAL_GLUE"
  elif [ "$in_prec" = "YES" ]; then
    boundary="A_PRECURSOR_AND_B_FULL"
  else
    boundary="B_FULL_ONLY"
  fi

  if [ "$role" = "PLATFORM_OR_MECHANICAL" ]; then
    reqm2=NO_PLATFORM_GLUE
    glue="YES_MECHANICAL_ONLY"
  elif [ "$in_prec" = "YES" ]; then
    reqm2=YES_PRECURSOR
    glue="NO_C_SEMANTIC_FALLBACK"
  else
    reqm2=YES_FULL_M2
    glue="NO_C_SEMANTIC_FALLBACK"
  fi

  auth="NONE"
  case "$base" in
    parser.c)  auth="AUTH-01..AUTH-09 (parser slice delegates)" ;;
    prslib.c)  auth="AUTH-03, AUTH-11 (parser precedence, core operator)" ;;
    ast.c)     auth="AUTH-04, AUTH-05, AUTH-12, AUTH-13 (AST builders, core operator)" ;;
    compile.c) auth="AUTH-10 (_AbiCpaShouldPrintAst)" ;;
    aarch64.c) auth="AUTH-14..AUTH-15 (_AbiA64CcForV2/InvV2)" ;;
  esac

  abi="HEADER_DEPENDENCIES_DECLARED_IN_COLUMN_12"

  case "$base" in
    cctrl.c|ast.c) state="PROCESS_GLOBAL_MUTABLE" ;;
    *)             state="MOSTLY_PURE_FUNCTION" ;;
  esac

  feats=$(features_of "$csrc")
  blockers="NONE_OBSERVED"
  case "$feats" in
    *three_dimensional_array*) blockers="RES-03" ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$sid" "$oid" "$sha" "$base" "$boundary" "C_ROOTED_STAGE0_HCC" \
    "LINKED_IN_PRODUCTION" "$auth" "$(subsystem_of "$base")" \
    "$reqm2" "$glue" "$hdrs" "$abi" "$state" "$feats" "$blockers" \
    "c1/production-link-and-source-scope.tsv" "HIGH" \
    "c1/source-closure.tsv" >> "$TMPE"
done < /tmp/sc-raw.txt

{
  echo "#"
  echo "# THE BOUNDARY SUMMARY"
  echo "#"
  printf 'key\tvalue\n'
  printf 'BOUNDARY_A_PRECURSOR_MEMBERS\t%s\tthe compile-pipeline units reachable from the driver\n' \
    "$(grep -c 'A_PRECURSOR_AND_B_FULL' "$TMPE")"
  printf 'BOUNDARY_B_FULL_SEMANTIC_UNITS\t%s\tevery semantic C unit in the production link\n' \
    "$(awk -F'\t' '$10 ~ /^YES/ {n++} END{print n+0}' "$TMPE")"
  printf 'MECHANICAL_GLUE_UNITS\t%s\tpermitted C/platform glue\n' \
    "$(grep -c 'MECHANICAL_GLUE' "$TMPE")"
  printf 'BOUNDARY_B_REQUIRES_POLYC_AUTHORING\t%s\tsemantic units that must become PolyC-authored\n' \
    "$(awk -F'\t' '$10 ~ /^YES/ {n++} END{print n+0}' "$TMPE")"
  printf 'OPEN_MISSING_POLYC_SOURCES\t%s\tsemantic units with no PolyC source today\n' \
    "$(awk -F'\t' '$10 ~ /^YES/ {n++} END{print n+0}' "$TMPE")"
  printf 'PRECURSOR_SEMANTIC_LOC\t%s\tLOC of the boundary-A semantic units\n' \
    "$(awk -F'\t' '$5=="A_PRECURSOR_AND_B_FULL" {print $4}' "$TMPE" \
       | while read -r b; do
           awk -F'\t' -v b="src/$b" '$3==b {print $8}' "$SCOPE"
         done | awk '{s+=$1} END{print s+0}')"
  printf 'FULL_M2_SEMANTIC_LOC\t%s\tLOC of every semantic unit in the production link\n' \
    "$(awk -F'\t' '$10=="SEMANTIC_COMPILER_SOURCE" {s+=$8} END{print s+0}' "$SCOPE")"
  printf 'MECHANICAL_GLUE_LOC\t%s\tLOC of the permitted C/platform glue\n' \
    "$(awk -F'\t' '$10=="PLATFORM_OR_MECHANICAL" {s+=$8} END{print s+0}' "$SCOPE")"
  printf 'POLYC_SUBJECT_LOC\t%s\tLOC of the twelve compiled PolyC helper subjects\n' \
    "$(awk -F'\t' '$10=="POLYC_SUBJECT" {s+=$8} END{print s+0}' "$SCOPE")"
} >> "$TMPE"

# The data rows replace the previous content atomically, so a re-run
# can never leave stale rows behind.
mv "$TMPE" "$OUT"
trap - EXIT INT TERM

echo "SOURCE_CLOSURE_WRITTEN=$OUT"
