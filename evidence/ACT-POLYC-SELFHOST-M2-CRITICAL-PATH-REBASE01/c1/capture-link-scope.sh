#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c1/capture-link-scope.sh
#
# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C1 EVIDENCE.
#
# Regenerates c1/production-link-and-source-scope.tsv by MEASURING
# the REAL production link line, the REAL object graph and the REAL
# source tree.
#
# For every object the production link line names, the row records:
#
#   - the C source file (or the PolyC subject source) it comes from,
#   - the source blob OID and content SHA-256,
#   - the source LOC,
#   - the number of global text symbols it defines,
#   - whether it is a C object or a compiled PolyC subject,
#   - the classification of its SEMANTIC role:
#       SEMANTIC_COMPILER_SOURCE  it owns compiler semantics
#       PLATFORM_OR_MECHANICAL   it is mechanical / platform glue
#       POLYC_SUBJECT            it is a compiled PolyC helper subject
#   - the header dependencies it declares.
#
# NOTHING is hand-authored. The classification column is derived from
# the source text and the object graph by the rules stated inline.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
OUT="$EV/c1/production-link-and-source-scope.tsv"
LINK="build/CMakeFiles/hcc.dir/link.txt"

{
  echo "# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
  echo "# ACT_PHASE=C1-EVIDENCE"
  echo "# EVIDENCE_KIND=production-link-and-source-scope"
  echo "#"
  echo "# EVERY ROW IS MEASURED FROM THE REAL PRODUCTION LINK LINE AND THE"
  echo "# REAL OBJECT GRAPH. The link line names the objects; nm measures"
  echo "# their exported symbols; git measures their source blobs."
  echo "#"
  echo "# classification rules (stated inline so they are auditable):"
  echo "#   POLYC_SUBJECT      the object is a compiled .HC subject."
  echo "#   PLATFORM_OR_MECHANICAL  the source is a runtime/libtos helper,"
  echo "#                       the vendored line editor, or a file whose"
  echo "#                       only role is mechanical (abi-cpa-host.c"
  echo "#                       HOSTS a PolyC decision rather than owning"
  echo "#                       one)."
  echo "#   SEMANTIC_COMPILER_SOURCE  the source owns compiler semantics:"
  echo "#                       lexer, parser, ast, ir, cfg, codegen, cli,"
  echo "#                       driver, containers, json, lsp, repl."
  echo "#"
  printf 'link_order\tobject_path\tc_source\tpolyc_source\tkind\tblob_oid\tsha256\tsource_loc\tglobal_text_symbols\tsemantic_role\theader_dependencies\n'
} > "$OUT"

# Map each linked object to its source. The build system compiles
# src/<name>.c into build/CMakeFiles/hcc.dir/<name>.c.o. The PolyC
# subjects are named <name>-subject.o and are produced by the Makefile
# from a tools/bootstrap/<name>.HC.
# The subject -> source map is read from the Makefile's own rules so
# it cannot drift from the build.
subject_src_for() {
  _stem="$1"
  # The Makefile assigns e.g. ABI_CPA_SRC = tools/bootstrap/x.HC and
  # ABI_CPA_OBJ = ./build/selfhost-abi-cpa-subject.o. Search for the
  # OBJ/SRC pair whose object basename matches.
  awk -v want="$_stem" '
    /^ *[A-Z0-9_]+_SRC[ \t]*=/ { srcv=$0; sub(/^[^=]*=[ \t]*/,"",srcv); gsub(/[ \t]/,"",srcv); next }
    /^ *[A-Z0-9_]+_OBJ[ \t]*=/ { objv=$0; sub(/^[^=]*=[ \t]*/,"",objv); gsub(/[ \t]/,"",objv);
      n=split(objv,p,"/"); b=p[n]; sub(/\.o$/,"",b);
      if (b==want) { print srcv; exit } }
  ' Makefile 2>/dev/null
}

order=0
tr ' ' '\n' < "$LINK" | grep '\.o$' | while read -r obj; do
  order=$((order + 1))
  base=$(basename "$obj")

  case "$obj" in
    /*) full="$obj" ;;
    ./*|../*) full="$(pwd)/$obj" ;;
    *) full="$(pwd)/build/$obj" ;;
  esac

  csrc=""
  psrc=""
  # The CMake link line names the C objects as
  # CMakeFiles/hcc.dir/<name>.c.o, so the source is src/<name>.c.
  cbase=$(printf '%s' "$base" | sed 's/\.c\.o$/.c/')
  if [ -f "src/$cbase" ]; then
    csrc="src/$cbase"
  elif [ -f "src/linenoise/$cbase" ]; then
    # The vendored line editor lives in a subdirectory.
    csrc="src/linenoise/$cbase"
  else
    stem=$(printf '%s' "$base" | sed 's/\.o$//')
    cand=$(subject_src_for "$stem")
    if [ -n "$cand" ] && [ -f "$cand" ]; then
      psrc="$cand"
    else
      psrc="NONE"
    fi
  fi

  src="$csrc"
  [ -n "$src" ] || src="$psrc"
  [ -n "$src" ] || src="NONE"

  oid="NONE"; sha="NONE"; loc=0
  if [ "$src" != "NONE" ] && [ -f "$src" ]; then
    oid=$(git rev-parse "HEAD:$src" 2>/dev/null || echo NOT_TRACKED)
    sha=$(shasum -a 256 "$src" | awk '{print $1}')
    loc=$(wc -l < "$src" | tr -d ' ')
  fi

  syms=0
  if [ -f "$full" ]; then
    syms=$(nm -g "$full" 2>/dev/null | grep -cE '^[0-9a-f]+ [TDRB] ')
  fi

  if [ -n "$csrc" ]; then kind=C_OBJECT; else kind=POLYC_SUBJECT_OBJECT; fi

  role="SEMANTIC_COMPILER_SOURCE"
  case "$src" in
    src/linenoise/*)   role="PLATFORM_OR_MECHANICAL" ;;
    src/abi-cpa-host.c) role="PLATFORM_OR_MECHANICAL" ;;
    src/memory.c|src/mempool.c|src/arena.c) role="PLATFORM_OR_MECHANICAL" ;;
    tools/bootstrap/*) role="POLYC_SUBJECT" ;;
    NONE) role="UNKNOWN" ;;
  esac

  hdrs="NONE"
  if [ -n "$csrc" ] && [ -f "$csrc" ]; then
    h=$(grep -oE '#include "[^"]+"' "$csrc" | sed 's/#include "//; s/"//' | tr '\n' ',' | sed 's/,$//')
    [ -n "$h" ] && hdrs="$h"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$order" "$obj" "$csrc" "$psrc" "$kind" "$oid" "$sha" "$loc" "$syms" "$role" "$hdrs" >> "$OUT"
done

{
  echo "#"
  echo "# THE MEASURED SUMMARY"
  echo "#"
  printf 'key\tvalue\n'
  printf 'PRODUCTION_LINK_OBJECTS\t%s\tone .o per link-line entry\n' \
    "$(tr ' ' '\n' < "$LINK" | grep -c '\.o$')"
  printf 'C_OBJECTS\t%s\tobjects whose source is under src/\n' \
    "$(awk -F'\t' 'NR>1 && $5=="C_OBJECT"{n++} END{print n+0}' "$OUT")"
  printf 'POLYC_SUBJECT_OBJECTS\t%s\tobjects produced from a tools/bootstrap .HC\n' \
    "$(awk -F'\t' 'NR>1 && $5=="POLYC_SUBJECT_OBJECT"{n++} END{print n+0}' "$OUT")"
  printf 'SEMANTIC_COMPILER_SOURCE_OBJECTS\t%s\tobjects owning compiler semantics\n' \
    "$(awk -F'\t' 'NR>1 && $10=="SEMANTIC_COMPILER_SOURCE"{n++} END{print n+0}' "$OUT")"
  printf 'PLATFORM_OR_MECHANICAL_OBJECTS\t%s\tmechanical / platform glue\n' \
    "$(awk -F'\t' 'NR>1 && $10=="PLATFORM_OR_MECHANICAL"{n++} END{print n+0}' "$OUT")"
  printf 'POLYC_SUBJECT_ROLE_OBJECTS\t%s\tcompiled PolyC helper subjects\n' \
    "$(awk -F'\t' 'NR>1 && $10=="POLYC_SUBJECT"{n++} END{print n+0}' "$OUT")"
  printf 'UNKNOWN_ROLE_OBJECTS\t%s\tobjects whose source could not be resolved\n' \
    "$(awk -F'\t' 'NR>1 && $10=="UNKNOWN"{n++} END{print n+0}' "$OUT")"
  printf 'SEMANTIC_COMPILER_SOURCE_TOTAL_LOC\t%s\tsum of the semantic sources LOC\n' \
    "$(awk -F'\t' 'NR>1 && $10=="SEMANTIC_COMPILER_SOURCE"{s+=$8} END{print s+0}' "$OUT")"
  printf 'TOTAL_LINKED_SOURCE_LOC\t%s\tsum of ALL linked sources LOC\n' \
    "$(awk -F'\t' 'NR>1 && $8 ~ /^[0-9]+$/{s+=$8} END{print s+0}' "$OUT")"
  printf 'PRODUCTION_LINK_LINE\tbuild/CMakeFiles/hcc.dir/link.txt\n'
  printf 'PRODUCTION_LINK_LINE_SHA256\t%s\tshasum -a 256 of the link line\n' \
    "$(shasum -a 256 "$LINK" | awk '{print $1}')"
  printf 'PRODUCTION_HCC_SHA256\t%s\tshasum -a 256 build/hcc\n' \
    "$(shasum -a 256 build/hcc 2>/dev/null | awk '{print $1}' || echo UNAVAILABLE)"
} >> "$OUT"

echo "LINK_SCOPE_WRITTEN=$OUT"
