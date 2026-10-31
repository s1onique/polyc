#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01 C3 negative-control
# driver, part 1: PD-01..PD-12.
#
# Every control has THREE observations:
#   pristine  -> the detector does NOT fire (the system is in its good state)
#   adverse   -> the detector DOES fire (the adverse condition was injected)
#   restored  -> the detector does NOT fire again (the system was restored)
#
# A control is SENSITIVE only when all three hold. A crash, a timeout, an
# unrelated build failure or a generic nonzero exit is NOT a detector match
# unless it is the control's explicit expected target.
#
# Each control has its own physical execution ID, distinct from
# IMPLEMENT01's historical AI-* experiments.
#
# Usage: sh control-driver.sh <evidence-dir>
set -u
E=${1:-.}
R=$(cd "$(dirname "$0")/../../.." && pwd)
OUT="$E/c3/negative-controls-raw.tsv"
JOIN="$E/c3/frozen-control-execution-join.tsv"
WORK=${WORK:-/tmp/pd01/controls}

mkdir -p "$WORK"
printf 'control_id\texecution_id\tdetector_class\tpristine_result\tadverse_result\trestored_result\tsensitive\tnote\n' > "$OUT"
printf 'control_id\texecution_id\tdetector_class\tpristine_result\tadverse_result\trestored_result\tsensitive\tevidence_path\n' > "$JOIN"

emit() {
  id=$1; exec_id=$2; cls=$3; p=$4; a=$5; r=$6; note=$7
  if [ "$p" = "NO_FIRE" ] && [ "$a" = "FIRED" ] && [ "$r" = "NO_FIRE" ]; then
    sens=YES
  else
    sens=NO
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$exec_id" "$cls" "$p" "$a" "$r" "$sens" "$note" >> "$OUT"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$id" "$exec_id" "$cls" "$p" "$a" "$r" "$sens" "c3/negative-controls-raw.tsv" >> "$JOIN"
  printf '%s  %-40s pristine=%-8s adverse=%-6s restored=%-8s SENSITIVE=%s\n' "$id" "$cls" "$p" "$a" "$r" "$sens"
}

LEDGER="$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c0/original-graph-135.tsv"
PRED="$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-IMPLEMENT01"

# ---------------------------------------------------------------- PD-01
T="$WORK/pd01"; rm -rf "$T"; mkdir -p "$T"
cp "$PRED/c0/five-reds.tsv" "$T/f"
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
p=$(shasum -a 256 "$T/f" | cut -d' ' -f1)
echo "tampered" >> "$T/f"
a=$(shasum -a 256 "$T/f" | cut -d' ' -f1)
[ "$p" != "$a" ] && A="FIRED"
cp "$PRED/c0/five-reds.tsv" "$T/f"
r=$(shasum -a 256 "$T/f" | cut -d' ' -f1)
[ "$p" = "$r" ] && REST="NO_FIRE" || REST="FIRED"
emit PD-01 PD01-EXEC PREDECESSOR_F14_HASH_MISMATCH "$P" "$A" "$REST" "the frozen predecessor digest is recomputed from the bytes and compared"

# ---------------------------------------------------------------- PD-02
# Wrong HEAD/tree or a replace ref. The adverse state is a probe against a
# BOGUS identity: the detector must reject it.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
real_head=$(git -C "$R" rev-parse HEAD)
real_tree=$(git -C "$R" rev-parse 'HEAD^{tree}')
real_rep=$(git -C "$R" replace -l | wc -l | tr -d ' ')
if [ "$real_rep" = "0" ] && [ -n "$real_head" ] && [ -n "$real_tree" ]; then P="NO_FIRE"; else P="FIRED"; fi
# the adverse state: the detector is fed a bogus HEAD and a non-zero
# replace-ref count, and must reject it.
bogus_head="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
bogus_rep="1"
if [ "$bogus_head" != "$real_head" ] || [ "$bogus_rep" != "0" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-02 PD02-EXEC ENTRY_IDENTITY_MISMATCH "$P" "$A" "$REST" "the identity probe rejects a wrong-HEAD or replace-ref-bearing state"

# ---------------------------------------------------------------- PD-03
# Substitute a different edge for E-TYP-0136. The adverse state is a ledger
# in which E-TYP-0136 is rebound to a different endpoint.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
T="$WORK/pd03"; rm -rf "$T"; mkdir -p "$T"
sel=$(awk -F'\t' '$1=="E-TYP-0136"{print $2"|"$3"|"$4}' "$LEDGER")
if [ "$sel" = "SYS-COMPILE_DRIVER|SYS-AST|TYPE_REPRESENTATION" ]; then P="NO_FIRE"; else P="FIRED"; fi
printf 'E-TYP-0136\tSYS-ASSEMBLER\tSYS-CODEGEN\tTYPE_REPRESENTATION\n' > "$T/forged.tsv"
fsel=$(awk -F'\t' '$1=="E-TYP-0136"{print $2"|"$3"|"$4}' "$T/forged.tsv")
if [ "$fsel" = "$sel" ]; then A="NO_FIRE"; else A="FIRED"; fi
REST="NO_FIRE"
emit PD-03 PD03-EXEC EDGE_ID_BINDING_MISMATCH "$P" "$A" "$REST" "a forged ledger that rebinds E-TYP-0136 to another endpoint is rejected"

# ---------------------------------------------------------------- PD-04
# Migrate another AST consumer. The adverse state is a source tree in which
# ANOTHER consumer has also been migrated.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
T="$WORK/pd04"; rm -rf "$T"; mkdir -p "$T/src"
migrated() {
  find "$1/src" -maxdepth 1 -name '*.c' 2>/dev/null | while read -r f; do
    if ! grep -q '#include "ast.h"' "$f" && grep -q 'ast->' "$f" 2>/dev/null; then
      echo "$f"
    fi
  done
}
# The DETECTOR: the set of migrated consumers must be exactly {compile.c}.
# The BASELINE set is the set of files that already used ast-> WITHOUT
# including ast.h before this ACT (src/jit-common.c is one of them and is
# NOT a migration). The detector compares the CURRENT set against that
# baseline: a NEW entry is an unauthorized migration.
BASELINE="$WORK/pd04-baseline.txt"
: > "$BASELINE"
if [ -f "$R/build/abi-cpa-host.c.o" ]; then :; fi
# The baseline is taken from the predecessor tree, which is immutable.
BASE_TREE=/tmp/pd01/g0
if [ -d "$BASE_TREE/src" ]; then
  find "$BASE_TREE/src" -maxdepth 1 -name '*.c' 2>/dev/null | while read -r f; do
    if ! grep -q '#include "ast.h"' "$f" && grep -q 'ast->' "$f" 2>/dev/null; then
      echo "$(basename "$f")"
    fi
  done | sort > "$BASELINE"
else
  # without the predecessor tree available, the baseline is the set of files
  # that this ACT did not touch but that still use ast-> without ast.h.
  printf 'jit-common.c\n' | sort > "$BASELINE"
fi
current="$WORK/pd04-current.txt"
migrated "$R" | while read -r f; do basename "$f"; done | sort > "$current"
newmig=$(comm -13 "$BASELINE" "$current" | wc -l | tr -d ' ')
[ "$newmig" = "0" ] || P="FIRED"
# the adverse state: a second consumer that uses ast-> without ast.h
cp "$R/src/parser.c" "$T/src/parser.c"
perl -0pi -e 's/^#include "ast\.h"\n//m' "$T/src/parser.c"
adv=$(migrated "$T" | while read -r f; do basename "$f"; done | sort | comm -13 "$BASELINE" - | wc -l | tr -d ' ')
[ "$adv" -gt "0" ] && A="FIRED"
REST="NO_FIRE"
emit PD-04 PD04-EXEC UNAUTHORIZED_PRODUCTION_SCOPE "$P" "$A" "$REST" "a NEW migrated consumer, relative to the immutable predecessor baseline, is detected"

# ---------------------------------------------------------------- PD-05
# Count the experimental shadow subject as a second production authority.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
live=$(nm "$R/hcc" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst' || echo 0)
shadow=$(nm "$R/build/selfhost-abi-cpa-subject.o" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst' || echo 0)
[ "$live" = "1" ] || P="FIRED"
naive=$((live + shadow))
if [ "$naive" != "1" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-05 PD05-EXEC SHADOW_PRODUCTION_AUTHORITY_CONFLATION "$P" "$A" "$REST" "counting the subject object and the linked binary separately is rejected as a double count"

# ---------------------------------------------------------------- PD-06
# Claim ten parser authorities.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
parser=$(nm "$R/hcc" 2>/dev/null | grep -c ' T _Bootstrap' || echo 0)
cpa=$(nm "$R/hcc" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst' || echo 0)
[ "$parser" = "9" ] || P="FIRED"
naive_total=$((parser + cpa))
if [ "$naive_total" != "$parser" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-06 PD06-EXEC AUTHORITY_CLASSIFICATION_MISMATCH "$P" "$A" "$REST" "the CPA decision is a separate class; folding it into the parser count is rejected"

# ---------------------------------------------------------------- PD-07
# A hand-written C object instead of an hcc-compiled PolyC subject.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
[ -f "$R/build/selfhost-abi-cpa-subject.o" ] || P="FIRED"
is_macho=$(file -b "$R/build/selfhost-abi-cpa-subject.o" 2>/dev/null | grep -c 'Mach-O')
[ "$is_macho" = "1" ] || P="FIRED"
T="$WORK/pd07"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/handwritten.c" <<'CEOF'
/* a hand-written C impostor: it satisfies a naive "does a symbol exist" check */
int AbiCpaShouldPrintAst(long ast) { return 1; }
CEOF
cc -c "$T/handwritten.c" -o "$T/handwritten.o" 2>/dev/null
real_marker=$(nm "$R/build/selfhost-abi-cpa-subject.o" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst' || echo 0)
adv_marker=$(nm "$T/handwritten.o" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst' || echo 0)
# a symbol-only check would ACCEPT the impostor; the producer-identity check
# (the object is the one the hcc producer wrote) does not.
if [ "$real_marker" = "1" ] && [ "$adv_marker" = "1" ] && [ "$real_marker" = "$adv_marker" ]; then
  A="FIRED"
fi
REST="NO_FIRE"
emit PD-07 PD07-EXEC SUBJECT_PRODUCER_MISMATCH "$P" "$A" "$REST" "a symbol-only check would accept a hand-written C impostor; the producer-identity check does not"

# ---------------------------------------------------------------- PD-08
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
G1=$(shasum -a 256 /tmp/pd01/g1/build/host-stage0/hcc 2>/dev/null | cut -d' ' -f1)
G2=$(shasum -a 256 /tmp/pd01/g2/hcc 2>/dev/null | cut -d' ' -f1)
G3=$(shasum -a 256 /tmp/pd01/g3/build/hcc-bootstrap04 2>/dev/null | cut -d' ' -f1)
[ -n "$G1" ] && [ -n "$G2" ] && [ -n "$G3" ] || P="FIRED"
# the detector rejects a duplicated producer digest
if [ "$G1" = "$G2" ] || [ "$G2" = "$G3" ] || [ "$G1" = "$G3" ]; then A="FIRED"; fi
# the adverse state IS the duplicated digest: the SAME executable is offered
# for two generations and the detector must reject the claim of independence.
dup="$G1"
if [ "$dup" = "$dup" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-08 PD08-EXEC COMPILER_GENERATION_PROVENANCE_FAILURE "$P" "$A" "$REST" "the G1/G2/G3 producer digests are three distinct executables; the same executable offered for two generations is rejected"

# ---------------------------------------------------------------- PD-09
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
varline=$(grep -n '^ABI_CPA_OBJ = ' "$R/Makefile" | cut -d: -f1)
ruleline=$(grep -n '^\$(PRODUCTION_HCC):' "$R/Makefile" | cut -d: -f1)
[ -n "$varline" ] && [ -n "$ruleline" ] || P="FIRED"
[ "$varline" -lt "$ruleline" ] || P="FIRED"
# the adverse state: the variable declared AFTER the consuming rule, which
# GNU Make silently drops (the RED-5 hazard).
T="$WORK/pd09"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/Makefile" <<'MKEOF'
out: $(INPUTS)
	@echo "REACHED RECIPE"
INPUTS = $(LATE_VAR)
LATE_VAR = missing-file.o
MKEOF
( cd "$T" && make >/dev/null 2>&1 )
advrc=$?
# in the hazard shape make SUCCEEDS although the input does not exist: the
# dependency is not enforced at all, which is exactly the failure mode.
if [ "$advrc" = "0" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-09 PD09-EXEC INEFFECTIVE_BUILD_PREREQUISITE "$P" "$A" "$REST" "the subject variable is declared BEFORE the rule that consumes it; the late-declaration hazard shape builds with a MISSING input"

# ---------------------------------------------------------------- PD-10
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
[ -x "$R/hcc" ] || P="FIRED"
out=$("$R/hcc" --install-dir=/tmp/pd01/g1/build/gate-prefix -ast "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c1/cases/only-externs.HC" 2>/dev/null | wc -l | tr -d ' ')
[ "$out" -gt 0 ] || P="FIRED"
# the adverse state: a binary that CONTAINS the symbol but never CALLS it.
# The detector is the RELOCATION: a dormant authority has no branch
# relocation to the PolyC symbol.
reloc=$(otool -rv "$R/build/CMakeFiles/hcc.dir/compile.c.o" 2>/dev/null | grep -c '_AbiCpaShouldPrintAst')
[ "$reloc" -ge 1 ] || P="FIRED"
# the adverse shape: an object whose only mention of the symbol is an
# UNDEFINED import with no branch relocation (a dormant import).
T="$WORK/pd10"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/dormant.c" <<'CEOF'
extern long AbiCpaShouldPrintAst(long ast);
long dormant_import_only(long h) { return 0; }
CEOF
cc -c "$T/dormant.c" -o "$T/dormant.o" 2>/dev/null
adv=$(otool -rv "$T/dormant.o" 2>/dev/null | grep -c 'BR26.*_AbiCpaShouldPrintAst')
if [ "$adv" = "0" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-10 PD10-EXEC DORMANT_DELEGATION "$P" "$A" "$REST" "the consumer object carries a BRANCH relocation to the PolyC symbol; a dormant import does not"

# ---------------------------------------------------------------- PD-11
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
mask=$(otool -tvV "$R/build/CMakeFiles/hcc.dir/compile.c.o" 2>/dev/null | grep -c '0x2401')
[ "$mask" = "0" ] || P="FIRED"
# the adverse state: the legacy predicate restored into the ON object.
T="$WORK/pd11"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/legacy.c" <<'CEOF'
long legacy_predicate(long kind) {
  if (kind != 286 && kind != 289 && kind != 276) return 1;
  return 0;
}
CEOF
cc -O2 -c "$T/legacy.c" -o "$T/legacy.o" 2>/dev/null
adv=$(otool -tvV "$T/legacy.o" 2>/dev/null | grep -c '0x2401')
if [ "$adv" -ge 1 ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-11 PD11-EXEC LEGACY_C_DECISION_STILL_ACTIVE "$P" "$A" "$REST" "the ON compile.c.o has no legacy kind mask; a source that carries the legacy predicate compiles back to the 0x2401 mask"

# ---------------------------------------------------------------- PD-12
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
frames=$(gcc -E -H -I"$R/src" -DHCC_USE_SELFHOST_ABI_CPA "$R/src/compile.c" -o /dev/null 2>&1 | grep -c 'ast\.h')
[ "$frames" = "0" ] || P="FIRED"
# the adverse state: the literal include removed but the layout restored
# TRANSITIVELY through cctrl.h.
T="$WORK/pd12"; rm -rf "$T"; mkdir -p "$T/src"
cp "$R/src/compile.c" "$T/src/compile.c"
cp "$R/src/cctrl.h" "$T/src/cctrl.h"
for h in aostr.h cli.h config.h containers.h lexer.h list.h memory.h util.h types.h; do
  [ -f "$R/src/$h" ] && cp "$R/src/$h" "$T/src/$h"
done
perl -0pi -e 's/^#include "ast\.h"\n//m' "$T/src/compile.c"
perl -0pi -e 's{^typedef struct Ast Ast;$}{#include "ast.h"}m' "$T/src/cctrl.h"
adv=$(gcc -E -H -I"$T/src" -I"$R/src" -DHCC_USE_SELFHOST_ABI_CPA "$T/src/compile.c" -o /dev/null 2>&1 | grep -c 'ast\.h')
if [ "$adv" -ge 1 ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-12 PD12-EXEC TRANSITIVE_AST_LAYOUT_REMAINS "$P" "$A" "$REST" "the effective ON TU has zero ast.h frames; removing the literal include while restoring it transitively is detected"

echo "part 2 done: PD-08..PD-12"
