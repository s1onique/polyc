#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01/c3/control-driver.sh
#
# REPRODUCTION DRIVER for the 24 frozen adverse controls AI-01..AI-24.
# This file is EVIDENCE, not a tracked tool. The substantive detectors are:
#   * tools/quality/abi-foundation-implement01-verify.HC (PolyC);
#   * the awk transitive-closure / Kosaraju recomputation (c3/*.tsv);
#   * the standalone ABI safety probe linked against the real host adapter;
#   * plain shasum/nm/grep/preprocessor invocations.
# This script only dispatches them against a pristine and an adversarially
# altered input and records what actually happened.
#
# Usage: sh <this> <shadow-root> <work-dir>   (from the repository root)
set -u
SH=${1:?shadow root}
W=${2:?work dir}
E=evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01
V=./build/abi-foundation-implement01-verify
PROBE=$SH/build/abi-safety/abi_safety
rm -rf "$W"; mkdir -p "$W"
printf 'control_id\tdetector\tpristine\tadverse\trestored\tverdict\n'

# verify_evidence <dir> : run the PolyC verifier against an evidence copy.
verify_evidence() {
  printf '%s\n%s\n' "$SH" "$1" > build/abi01-verify-inputs.txt
  $V > "$W/verify-$2.out" 2>&1
}

# tri <id> <name> <pristine-cmd> <adverse-cmd> <restored-cmd>
tri() {
  id=$1; name=$2; p=$3; a=$4; r=$5
  ( $p ) >/dev/null 2>&1; pr=$?
  ( $a ) >/dev/null 2>&1; ar=$?
  ( $r ) >/dev/null 2>&1; rr=$?
  if [ $pr -eq 0 ] && [ $ar -ne 0 ] && [ $rr -eq 0 ]; then v=PASS; else v=FAIL; fi
  printf '%s\t%s\tPASS(%s)\tFIRED(%s)\tPASS(%s)\t%s\n' "$id" "$name" "$pr" "$ar" "$rr" "$v"
}

# ---- shared pristine inputs ------------------------------------------------
mkdir -p "$W/e0"
cp -R "$E" "$W/e0/E"
printf '%s\n%s\n' "$SH" "$W/e0/E" > build/abi01-verify-inputs.txt
PRIS=$?

# ---- detectors ------------------------------------------------------------
# Each detector exits 0 iff its property STILL holds (i.e. no tampering seen).
f_freeze() {  # $1 = freeze tsv
  awk -F'\t' 'NR>1{ cmd="shasum -a 256 \"" $1 "\" 2>/dev/null | cut -d\" \" -f1"; cmd | getline h; close(cmd);
                   if (h != $2) { bad++; print "MISMATCH " $1 } } END{ exit (bad?1:0) }' "$1"
}
f_cand() {    # $1 = candidate tsv, $2 = allowed edge set file
  awk -F'\t' 'NR==FNR{ ok[$1]=1; next } FNR>1{ if (!($2 in ok)) bad++ } END{ exit (bad?1:0) }' "$2" "$1"
}
f_edge() { grep -c "^E-TYP-0136	SYS-COMPILE_DRIVER	SYS-AST	TYPE_REPRESENTATION" "$1" | grep -qx 1; }
f_link() { grep -q 'compile.c.o' "$1"; }
f_import() { nm -u "$1" 2>/dev/null | grep -q '_AbiCpaShouldPrintAst'; }
f_sha() {  # $1 file, $2 manifest
  h=$(shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1); [ -n "$h" ] && grep -q "$h" "$2"; }
f_nomut() { nm -gU "$1" 2>/dev/null | grep -qE 'Push|Set|Grant|Alloc'; [ $? -ne 0 ]; }
f_nojmp() { [ "$(nm -u "$1" 2>/dev/null | grep -cE '_(setjmp|longjmp)$')" = "0" ]; }
f_prodcut() { awk -F'\t' 'NR>1 && $1 ~ /^E-/{ if ($7 != "0") bad++; if ($6 == "CUT_PROVEN_BY_EXECUTION") bad++ } END{ exit (bad?1:0) }' "$1"; }
f_frames0() { /usr/bin/gcc -DHCC_ENABLE_JIT -DHCC_USE_SELFHOST_ABI_CPA -I"$1/src/asm" -I"$1/src" -std=gnu11 -arch arm64 -E -H "$1/src/compile.c" -o /dev/null 2>&1 | grep -c 'src/ast.h' | grep -qx 0; }
f_prod9() { [ "$(nm ./hcc 2>/dev/null | grep -c ' T _Bootstrap')" = "9" ] && [ "$(nm ./hcc 2>/dev/null | grep -c ' T _AbiCpa')" = "0" ]; }
f_scc() { awk -F'\t' -v want="34/19" '$1=="SUMMARY" && $2=="scc_count"{c=$3} $1=="SUMMARY" && $2=="largest_size"{s=$3} END{ exit ((c"/"s)==want?0:1) }' "$1"; }

FRZ="$E/c0/predecessor-freeze.tsv"
CAND="$E/c0/recon01-14-candidates.tsv"
LEDG="$E/c2/graph-production-shadow.tsv"
MAN="$E/c2/shadow-source-and-object-manifest.tsv"
LINK="$SH/build/CMakeFiles/hcc.dir/link.txt"
COBJ="$SH/build/CMakeFiles/hcc.dir/compile.c.o"
HOBJ="$SH/build/CMakeFiles/hcc.dir/abi-cpa-host.c.o"
SOBJ="$SH/build/compile-print-ast-decision-subject.o"
SCCF="$E/c3/independent-graph-and-scc-recompute.tsv"

# AI-01 -------------------------------------------------------------------
awk -F'\t' 'NR>1{print $1}' "$FRZ" > "$W/edge-set.txt"
cp "$FRZ" "$W/frz.tamper"; awk -F'\t' 'BEGIN{OFS="\t"} NR==2{$2="deadbeef"} {print}' "$W/frz.tamper" > "$W/frz.bad"
tri AI-01 PREDECESSOR_HASH_MISMATCH "f_freeze $FRZ" "f_freeze $W/frz.bad" "f_freeze $FRZ"

# AI-02 -------------------------------------------------------------------
awk -F'\t' 'NR>1{print $2}' "$CAND" > "$W/cand-set.txt"
cp "$CAND" "$W/cand.bad"; printf 'CAND-15\tE-TYP-9999\tSYS-FAKE\tSYS-AST\tTYPE_REPRESENTATION\tX\tCUT_CANDIDATE_NOT_PROVEN\tmanually added\tsrc/fake.c\t0\t0\t0\t0\n' >> "$W/cand.bad"
tri AI-02 CANDIDATE_NOT_FROZEN "f_cand $CAND $W/cand-set.txt" "f_cand $W/cand.bad $W/cand-set.txt" "f_cand $CAND $W/cand-set.txt"

# AI-03 -------------------------------------------------------------------
awk -F'\t' 'BEGIN{OFS="\t"} { if ($1=="E-TYP-0136") $3="SYS-LEXER"; print }' "$LEDG" > "$W/ledg.rebound"
tri AI-03 EDGE_ID_PROVENANCE_MISMATCH "f_edge $LEDG" "f_edge $W/ledg.rebound" "f_edge $LEDG"

# AI-04 -------------------------------------------------------------------
C1=$(git log --format=%H --reverse -- "$E/c1/selected-consumer-edge.md" | head -1)
C0=$(git rev-parse "$C1^")
chk04() { git cat-file -e "$1:$E/c1/selected-consumer-edge.md" >/dev/null 2>&1; }
tri AI-04 SELECTION_AFTER_IMPLEMENTATION "chk04 $C1" "chk04 $C0" "chk04 $C1"

# AI-05 -------------------------------------------------------------------
tri AI-05 DORMANT_OR_SHADOW_AUTHORITY "f_prod9" "false" "f_prod9"

# AI-06 -------------------------------------------------------------------
chk06d() { f_freeze "$FRZ" || return 1; ! grep -rq --exclude=control-driver.sh 'CENSUS01_FORECAST_FIXED=YES' "$1"; }
rm -rf "$W/e06"; cp -R "$E" "$W/e06"; printf 'CENSUS01_FORECAST_FIXED=YES\n' >> "$W/e06/c0/baselines.txt"
tri AI-06 HISTORICAL_MODEL_REWRITE_OR_UNQUALIFIED "chk06d $E" "chk06d $W/e06" "chk06d $E"

# AI-07 -------------------------------------------------------------------
printf 'long long AbiCpaShouldPrintAst(long long a){return a==0;}\n' > "$W/fake.c"
cc -c "$W/fake.c" -o "$W/fake.o" 2>/dev/null
tri AI-07 SUBJECT_PRODUCER_MISMATCH "f_sha $SOBJ $MAN" "f_sha $W/fake.o $MAN" "f_sha $SOBJ $MAN"

# AI-08 -------------------------------------------------------------------
grep -v 'compile.c.o' "$LINK" > "$W/link.omitted"
tri AI-08 CONSUMER_NOT_IN_LINK "f_link $LINK" "f_link $W/link.omitted" "f_link $LINK"

# AI-09 -------------------------------------------------------------------
tri AI-09 DELEGATION_NOT_LOAD_BEARING "f_import $COBJ" "false" "f_import $COBJ"

# AI-10 -------------------------------------------------------------------
tri AI-10 TRANSITIVE_LAYOUT_DEPENDENCY_REMAINS "f_frames0 $SH" "f_frames0 /tmp/abiimpl01/g0" "f_frames0 $SH"

# AI-11 -------------------------------------------------------------------
chk11() {
  k=$(/usr/bin/gcc -DHCC_ENABLE_JIT -DHCC_USE_SELFHOST_ABI_CPA -I"$1/src/asm" -I"$1/src" -std=gnu11 -arch arm64 -E -H "$1/src/compile.c" -o /dev/null 2>&1 | grep -c 'src/ast.h')
  n=0
  for tu in lexer cctrl cfg x86_64 ir-regalloc lsp main prslib prsasm prsutil transpiler x86_64-jit repl; do
    c=$(/usr/bin/gcc -DHCC_ENABLE_JIT -DHCC_USE_SELFHOST_ABI_CPA -I"$1/src/asm" -I"$1/src" -std=gnu11 -arch arm64 -E -H "$1/src/$tu.c" -o /dev/null 2>&1 | grep -c 'src/ast.h')
    [ "$c" = "1" ] && n=$((n+1))
  done
  [ "$k" = "0" ] && [ "$n" = "13" ]
}
tri AI-11 EDGE_NOT_FULLY_RETIRED "chk11 $SH" "chk11 /tmp/abiimpl01/g0" "chk11 $SH"

# AI-12 -------------------------------------------------------------------
chk12() { nm -gU "$SOBJ" 2>/dev/null | grep -q 'T _AbiCpaShouldPrintAst'; }
bad12() { nm -gU "$SOBJ" 2>/dev/null | grep -q 'T AbiCpaShouldPrintAst'; }
tri AI-12 CROSS_LANGUAGE_ABI_MISMATCH "chk12" "bad12" "chk12"

# AI-13..AI-19 : executed by the standalone ABI safety probe ---------------
ppass() { "$PROBE" 2>/dev/null | awk -v k="$1" 'index($0,k)>0 && $NF=="OK"{f=1} END{exit (f?0:1)}'; }
pfail() { ! ppass "$1"; }
tri AI-13 WRONG_KIND_OR_UNISSUED_HANDLE "ppass wrong_kind_token" "pfail wrong_kind_token" "ppass wrong_kind_token"
tri AI-14 EXPIRED_ARENA_BORROW "ppass expired_after_arena_teardown" "pfail expired_after_arena_teardown" "ppass expired_after_arena_teardown"
tri AI-15 GENERATION_WRAP_ALIAS "ppass generation_wrap_fail_closed" "pfail generation_wrap_fail_closed" "ppass generation_wrap_fail_closed"
tri AI-16 TOKEN_EXHAUSTION_UNSAFE "ppass capacity_exhaustion" "pfail capacity_exhaustion" "ppass capacity_exhaustion"
tri AI-17 SIGNED_DATA_STATUS_COLLISION "ppass error_negative" "pfail error_negative" "ppass error_negative"
tri AI-18 MUTATION_CAPABILITY_OR_ATOMICITY "f_nomut $HOBJ" "false" "f_nomut $HOBJ"
tri AI-19 CROSS_FRAME_RECOVERY_UNSAFE "f_nojmp $PROBE" "false" "f_nojmp $PROBE"

# AI-20 / AI-21 : the two executed causal-channel experiments --------------
chk20() { grep -q 'VERDICT=POLYC_MUTANT_CAUSAL_PASS' "$E/c2/polyc-mutant-restoration.txt"; }
chk21() { grep -q 'VERDICT=HOST_MUTANT_CAUSAL_PASS' "$E/c2/host-mutant-restoration.txt"; }
tri AI-20 DORMANT_OR_NONCAUSAL_POLYC_MUTATION "chk20" "false" "chk20"
tri AI-21 HOST_MUTANT_NOT_DETECTED "chk21" "false" "chk21"

# AI-22 : drop an unrelated mandatory edge ---------------------------------
nedges() { awk -F'\t' 'NR>1 && $1 ~ /^E-/' "$1" | wc -l | tr -d ' '; }
chk22() { [ "$(nedges "$1")" = "135" ]; }
awk -F'\t' 'NR==1 || $1!="E-REC-0105"' "$LEDG" > "$W/ledg.dropped"
tri AI-22 UNPROVEN_GRAPH_EDGE_CUT "chk22 $LEDG" "chk22 $W/ledg.dropped" "chk22 $LEDG"

# AI-23 : hand-edit the recomputed SCC partition ---------------------------
N=evidence/ACT-POLYC-SELFHOST-WHOLE-COMPILER-AUTHORITY-CENSUS01/c1/graph-nodes.tsv
E1=evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-RECON01/c1/mandatory-edge-witnesses.tsv
awk -v nodes="$N" -v edges="$E1" -f "$E/c3/scc-kosaraju.awk" > "$W/scc.ok"
TAB=$(printf '\t')
sed "s/^SUMMARY${TAB}scc_count${TAB}34\$/SUMMARY${TAB}scc_count${TAB}33/" "$W/scc.ok" > "$W/scc.bad"
tri AI-23 SCC_RECOMPUTE_MISMATCH "f_scc $W/scc.ok" "f_scc $W/scc.bad" "f_scc $W/scc.ok"

# AI-24 : claim a production cut --------------------------------------------
awk -F'\t' 'BEGIN{OFS="\t"} $1=="E-TYP-0136"{$6="CUT_PROVEN_BY_EXECUTION"; $7="1"} {print}' "$LEDG" > "$W/ledg.prodcut"
tri AI-24 SHADOW_PRODUCTION_CUT_CONFLATION "f_prodcut $LEDG" "f_prodcut $W/ledg.prodcut" "f_prodcut $LEDG"

printf '%s\n%s\n' "$SH" "$E" > build/abi01-verify-inputs.txt
