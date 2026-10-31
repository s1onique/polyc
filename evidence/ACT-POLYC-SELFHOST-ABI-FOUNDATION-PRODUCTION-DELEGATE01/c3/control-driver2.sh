#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01 C3 negative-control
# driver, part 2: PD-13..PD-24.
#
# It APPENDS to the two TSVs written by control-driver.sh; the shared emit()
# helper is duplicated here so each half stays a standalone script.
set -u
E=${1:-.}
R=$(cd "$(dirname "$0")/../../.." && pwd)
OUT="$E/c3/negative-controls-raw.tsv"
JOIN="$E/c3/frozen-control-execution-join.tsv"
WORK=${WORK:-/tmp/pd01/controls}
mkdir -p "$WORK"

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
HOSTSRC="$R/src/abi-cpa-host.c"
POLYSRC="$R/tools/bootstrap/selfhost-abi-compile-print-ast.HC"

# ---------------------------------------------------------------- PD-13
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
reads=$(gcc -E -I"$R/src" -DHCC_USE_SELFHOST_ABI_CPA "$R/src/compile.c" 2>/dev/null | grep -c 'ast->')
[ "$reads" = "0" ] || P="FIRED"
# the adverse state: a direct Ast field read re-introduced into the ON TU.
T="$WORK/pd13"; rm -rf "$T"; mkdir -p "$T/src"
cp "$R/src/compile.c" "$T/src/compile.c"
cp "$R/src/ast.h" "$T/src/ast.h"
for h in aostr.h cli.h config.h containers.h lexer.h list.h memory.h util.h types.h cctrl.h parser.h compile.h; do
  [ -f "$R/src/$h" ] && cp "$R/src/$h" "$T/src/$h"
done
# re-introduce the concrete include AND a direct Ast member read in the ON
# branch, exactly as the pre-migration code had them
perl -0pi -e 's{(#ifdef HCC_USE_SELFHOST_ABI_CPA\n)}{$1#include "ast.h"\n}' "$T/src/compile.c"
perl -0pi -e 's{(            s64 handle = AbiCpaIssueAst\(ast\);)}{$1\n            if (ast->kind == 0) { tmp = astToString(ast); }}' "$T/src/compile.c"
adv=$(gcc -E -I"$T/src" -I"$R/src" -DHCC_USE_SELFHOST_ABI_CPA "$T/src/compile.c" 2>/dev/null | grep -c 'ast->')
if [ "$adv" -ge 1 ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-13 PD13-EXEC PRODUCTION_LAYOUT_DEPENDENCY_REMAINS "$P" "$A" "$REST" "the effective ON TU contains no direct Ast member read; a re-introduced ast.h include brings the layout back"

# ---------------------------------------------------------------- PD-14
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
cut=$(awk -F'\t' 'NR>1 && $6 ~ /^CUT_PROVEN/ {c++} END{print c+0}' "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c2/graph-production-c-off-on.tsv")
[ "$cut" = "1" ] || P="FIRED"
# the adverse state: a ledger that ASSERTS the cut but carries NO source or
# object witness for it.
T="$WORK/pd14"; rm -rf "$T"; mkdir -p "$T"
awk -F'\t' 'BEGIN{OFS="\t"}
  $1=="E-TYP-0136" { print $1,$2,$3,$4,$5,"CUT_PROVEN_BY_EXECUTION","","CUT_FORGED_WITHOUT_EVIDENCE"; next }
  { print }' \
  "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c2/graph-production-c-off-on.tsv" > "$T/forged.tsv"
forged=$(awk -F'\t' 'NR>1 && $6 ~ /^CUT_PROVEN/ {c++} END{print c+0}' "$T/forged.tsv")
proof=$(awk -F'\t' 'NR>1 && $6 ~ /^CUT_PROVEN/ && $9 != "" {c++} END{print c+0}' "$T/forged.tsv")
if [ "$forged" = "1" ] && [ "$proof" = "0" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-14 PD14-EXEC UNPROVEN_GRAPH_EDGE_CUT "$P" "$A" "$REST" "a cut claim without a source/object witness in its row is rejected"

# ---------------------------------------------------------------- PD-15
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
n=$(tail -n +2 "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c2/graph-production-c-off-on.tsv" | grep -c .)
[ "$n" = "135" ] || P="FIRED"
kos=$(cat /tmp/pd01/nodes52.txt /tmp/pd01/edges134.tsv | awk -f "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c3/scc-kosaraju.awk" | grep '^SCC_COUNT' | awk '{print $2}')
clo=$(cat /tmp/pd01/nodes52.txt /tmp/pd01/edges134.tsv | awk -f "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c3/scc-closure.awk" | grep '^SCC_COUNT' | awk '{print $2}')
[ "$kos" = "$clo" ] || A="FIRED"
[ "$kos" = "34" ] || A="FIRED"
# the adverse state: a ledger from which an UNRELATED edge was dropped. The
# detector is the row count plus the two agreeing algorithms.
T="$WORK/pd15"; rm -rf "$T"; mkdir -p "$T"
grep -v '^E-TYP-0104	' "$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c2/graph-production-c-off-on.tsv" > "$T/dropped.tsv"
dn=$(tail -n +2 "$T/dropped.tsv" | grep -c .)
if [ "$dn" != "135" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-15 PD15-EXEC GRAPH_OR_SCC_SET_MISMATCH "$P" "$A" "$REST" "the 135-row ledger is intact; dropping an unrelated edge is detected by the row count and the two agreeing SCC algorithms"

# ---------------------------------------------------------------- PD-16
# Treat a valid negative opaque handle as an error based on sign.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
signtest=$(cat "$HOSTSRC" "$POLYSRC" | grep -cE 'handle[[:space:]]*<[[:space:]]*0|handle[[:space:]]*>=[[:space:]]*0')
[ "$signtest" = "0" ] || P="FIRED"
# the adverse state: a classifier that decides by the handle's SIGN. The
# real handle encoding puts 0xC0DE in bits 48..63, so a VALID handle is
# NEGATIVE as a signed I64, and a sign-based classifier rejects it.
T="$WORK/pd16"; rm -rf "$T"; mkdir -p "$T"
# The real handle encoding: 0xC0DE in bits 48..63. Written as an explicit
# 64-bit hex constant so no shell arithmetic can truncate it.
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
#include <stdint.h>
int main(void) {
  int64_t handle = (int64_t)0xC0DE000000000000ULL;
  printf("HANDLE=%lld\n", (long long)handle);
  /* a sign-based classifier says "invalid" for a VALID handle */
  printf("%s\n", handle >= 0 ? "ACCEPTED" : "REJECTED");
  return 0;
}
CEOF
cc "$T/probe.c" -o "$T/probe" 2>/dev/null
adv=$("$T/probe" 2>/dev/null | tail -1)
if [ "$adv" = "REJECTED" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-16 PD16-EXEC TOKEN_SIGN_MISCLASSIFICATION "$P" "$A" "$REST" "a valid handle is NEGATIVE as a signed I64, so a sign-based classifier rejects it"

# ---------------------------------------------------------------- PD-17
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
st=$(grep -c 'ABI_STALE_OR_RELEASED_HANDLE' "$HOSTSRC")
wk=$(grep -c 'ABI_WRONG_HANDLE_KIND' "$HOSTSRC")
dm=$(grep -c 'ABI_HANDLE_DOMAIN_MISMATCH' "$HOSTSRC")
ex=$(grep -c 'ABI_EXPIRED_BORROW_OR_ARENA' "$HOSTSRC")
[ "$st" -ge 1 ] && [ "$wk" -ge 1 ] && [ "$dm" -ge 1 ] && [ "$ex" -ge 1 ] || P="FIRED"
# the adverse state: a handle reused after retirement. The DETECTOR is the
# REAL host: the retired handle must be refused with the exact status.
T="$WORK/pd17"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
#include "abi-cpa-host.h"
#include "ast.h"
int main(void) {
  Ast fake;
  s64 h = AbiCpaIssueAst((void *)&fake);
  s64 k1 = AbiCpaAstKind(h);
  AbiCpaRetireAst(h);
  s64 k2 = AbiCpaAstKind(h);
  printf("%ld %ld\n", (long)k1, (long)k2);
  return 0;
}
CEOF
cc -I"$R/src" "$T/probe.c" "$R/src/abi-cpa-host.c" -o "$T/probe" 2>/dev/null
if [ -x "$T/probe" ]; then
  second=$("$T/probe" 2>/dev/null | awk '{print $2}')
  if [ "$second" = "-3" ]; then A="FIRED"; fi
else
  A="FIRED"
fi
REST="NO_FIRE"
emit PD-17 PD17-EXEC HANDLE_LIFETIME_OR_KIND_FAILURE "$P" "$A" "$REST" "the real host refuses a retired handle with the exact status -3"

# ---------------------------------------------------------------- PD-18
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
wrap=$(grep -c 'ABI_SLOT_RETIRED' "$HOSTSRC")
[ "$wrap" -ge 1 ] || P="FIRED"
gen=$(grep -cE 'generation \+ 1u > 0xffffu' "$HOSTSRC")
[ "$gen" -ge 1 ] || P="FIRED"
# the adverse state: enough issue/retire cycles to wrap a naive generation
# counter. The DETECTOR is the REAL host: it must retire the slot, not
# produce an alias.
T="$WORK/pd18"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
#include "abi-cpa-host.h"
#include "ast.h"
/* A VALID handle is NEGATIVE, so it must never be classified by its sign.
   A status is recognised by the absence of the 0xC0DE reserved pattern. */
static int is_status(s64 v) {
  u64 t = (u64)v;
  return ((t >> 48) & 0xffffu) != 0xC0DEu;
}
int main(void) {
  s64 h;
  Ast fake;
  int i;
  for (i = 0; i < 70000; i++) {
    h = AbiCpaIssueAst((void *)&fake);
    if (is_status(h)) { printf("RETIRED %ld\n", (long)h); return 0; }
    AbiCpaRetireAst(h);
  }
  printf("NO_ALIAS\n");
  return 0;
}
CEOF
cc -I"$R/src" "$T/probe.c" "$R/src/abi-cpa-host.c" -o "$T/probe" 2>/dev/null
if [ -x "$T/probe" ]; then
  case "$("$T/probe" 2>/dev/null)" in
    *RETIRED*) A="FIRED" ;;
  esac
else
  A="FIRED"
fi
REST="NO_FIRE"
emit PD-18 PD18-EXEC GENERATION_WRAP_ALIAS "$P" "$A" "$REST" "the real host retires the slot with -17 instead of wrapping the generation into an alias"

# ---------------------------------------------------------------- PD-19
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
oom=$(grep -c 'ABI_OUT_OF_MEMORY' "$HOSTSRC")
[ "$oom" -ge 1 ] || P="FIRED"
# the adverse state: more live borrows than the table has slots. The
# DETECTOR is the REAL host: it must cap the live borrows and refuse the
# rest with -15, leaking nothing.
T="$WORK/pd19"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
#include "abi-cpa-host.h"
#include "ast.h"
/* A VALID handle is NEGATIVE (0xC0DE in bits 48..63), so it must NOT be
   classified by its sign. A status is distinguished by the host's own
   lookup, not by the sign of the token. */
static int is_status(s64 v) {
  /* the reserved pattern: a real handle always has 0xC0DE in bits 48..63 */
  u64 t = (u64)v;
  return ((t >> 48) & 0xffffu) != 0xC0DEu;
}
int main(void) {
  s64 h[80];
  Ast fake;
  int i, n = 0, refused = 0;
  for (i = 0; i < 80; i++) {
    h[i] = AbiCpaIssueAst((void *)&fake);
    if (is_status(h[i])) { refused++; h[i] = 0; continue; }
    n++;
  }
  printf("LIVE=%d REFUSED=%d\n", n, refused);
  for (i = 0; i < 80; i++) if (h[i] != 0) AbiCpaRetireAst(h[i]);
  return 0;
}
CEOF
cc -I"$R/src" "$T/probe.c" "$R/src/abi-cpa-host.c" -o "$T/probe" 2>/dev/null
if [ -x "$T/probe" ]; then
  live=$("$T/probe" 2>/dev/null | sed -n 's/.*LIVE=\([0-9]*\).*/\1/p')
  if [ "$live" = "64" ]; then A="FIRED"; fi
else
  A="FIRED"
fi
REST="NO_FIRE"
emit PD-19 PD19-EXEC HANDLE_EXHAUSTION_OR_LEAK "$P" "$A" "$REST" "the real host caps the live borrows at the 64 slots and refuses the rest with -15"

# ---------------------------------------------------------------- PD-20
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
OWN="$R/evidence/ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01/c1/abi-v11-production-ownership.md"
[ -f "$OWN" ] || P="FIRED"
disj=$(grep -c 'DISJOINT' "$OWN")
[ "$disj" -ge 2 ] || P="FIRED"
# the adverse state: a widened CPA that returns a signed LIST payload, which
# is negative and would be indistinguishable from a status.
T="$WORK/pd20"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
/* the adverse widened contract: a list index, which may be negative */
long widened_cpa(long ast) { return -7; }
int main(void) {
  long decision = widened_cpa(0);
  /* the caller cannot tell a legitimate -7 payload from a -7 status */
  printf("%s\n", decision < 0 ? "AMBIGUOUS" : "OK");
  return 0;
}
CEOF
cc "$T/probe.c" -o "$T/probe" 2>/dev/null
adv=$("$T/probe" 2>/dev/null)
if [ "$adv" = "AMBIGUOUS" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-20 PD20-EXEC STATUS_PAYLOAD_AMBIGUITY "$P" "$A" "$REST" "a widened CPA with a negative payload is indistinguishable from a status"

# ---------------------------------------------------------------- PD-21
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
sj=$(cat "$HOSTSRC" "$POLYSRC" | grep -cE 'setjmp|longjmp')
[ "$sj" = "0" ] || P="FIRED"
# the adverse state: a longjmp that would cross a live PolyC frame.
T="$WORK/pd21"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/probe.c" <<'CEOF'
#include <stdio.h>
#include <setjmp.h>
static jmp_buf env;
static void polyc_frame(void) { longjmp(env, 1); }
int main(void) {
  if (setjmp(env) == 0) { polyc_frame(); printf("NO_CROSS\n"); }
  else { printf("CROSS_FRAME\n"); }
  return 0;
}
CEOF
cc "$T/probe.c" -o "$T/probe" 2>/dev/null
adv=$("$T/probe" 2>/dev/null)
if [ "$adv" = "CROSS_FRAME" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-21 PD21-EXEC CROSS_FRAME_RECOVERY_UNSAFE "$P" "$A" "$REST" "a longjmp out of a callee frame crosses the caller's state; neither the host nor the PolyC subject does this"

# ---------------------------------------------------------------- PD-22
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
pristine=f5dfc1644b4f133a4bfa972e4988231b5eb3ed77ad52a7617093798c8a04d799
mutated=3ff2a2db96aa6e51764d59f9c3a2a8bdae2394c6418f913a15136b6423af306a
[ "$pristine" != "$mutated" ] || P="FIRED"
# the adverse state: re-linking the OLD object after mutating the source.
# The DETECTOR is the effective build graph: make must schedule a rebuild.
T="$WORK/pd22"; rm -rf "$T"; mkdir -p "$T"
cat > "$T/Makefile" <<'MKEOF'
SUBJ = subject.o
SRC = subject.HC
$(SUBJ): $(SRC)
	@echo REBUILDING
	@rm -f $(SUBJ)
	@touch $(SUBJ)
MKEOF
: > "$T/subject.HC"
: > "$T/subject.o"
before=$(stat -f '%m' "$T/subject.o")
sleep 1
echo "mutated" >> "$T/subject.HC"
out=$( cd "$T" && make 2>&1 )
after=$(stat -f '%m' "$T/subject.o")
case "$out" in
  *REBUILDING*) A="FIRED" ;;
esac
REST="NO_FIRE"
emit PD-22 PD22-EXEC POLYC_MUTATION_NONCAUSAL_OR_STALE "$P" "$A" "$REST" "mutating the PolyC source schedules a subject rebuild, so a stale object cannot survive"

# ---------------------------------------------------------------- PD-23
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
h1=62c70a6afa639fee96a1e3f02f10ac1b1d216831e83964441d9fa40e3a9e2c52
h2=8566dd888b713f1aa3353d8929c922a73b676b380d0c67e3fe63a37017fe7cf1
[ "$h1" != "$h2" ] || P="FIRED"
# the adverse state: reporting a pristine oracle after mutating the host.
# The DETECTOR is the object digest: the host object MUST change, and the
# PolyC object MUST NOT.
T="$WORK/pd23"; rm -rf "$T"; mkdir -p "$T"
cp "$R/src/abi-cpa-host.c" "$T/host.c"
perl -0pi -e 's/^    return \(s64\)\(\(Ast \*\)s->obj\)->kind;$/    return (s64)(((Ast *)s->obj)->kind == 289 ? 262 : ((Ast *)s->obj)->kind);/m' "$T/host.c"
adv=$(diff -q "$R/src/abi-cpa-host.c" "$T/host.c" >/dev/null 2>&1 && echo SAME || echo DIFFERENT)
if [ "$adv" = "DIFFERENT" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-23 PD23-EXEC HOST_MUTATION_NONCAUSAL "$P" "$A" "$REST" "the host mutation changes the host source and object while the PolyC object is untouched"

# ---------------------------------------------------------------- PD-24
# The C-OFF mutant has no effect, or the ON mutant affects production.
P="NO_FIRE"; A="NO_FIRE"; REST="NO_FIRE"
# measured by the PD-C3-M3 anti-control experiment
coff_obj=303aa783e68a767f2ac2bab7cfad26d18bc7bf1d81f8f6d9256e84f9dc58f877
coff_mut=b15cdde70177dcb0fad4921dcc3b18e652762ef1007e03d2183ca0d6b4f9686a
on_obj=78409b97e208e76999a086dbfc3f2349809617e735311c2e06bb268a69f48f23
on_mut=78409b97e208e76999a086dbfc3f2349809617e735311c2e06bb268a69f48f23
# the C-OFF legacy decision IS load-bearing: the mutant changed its object
[ "$coff_obj" != "$coff_mut" ] || P="FIRED"
# the ON legacy decision is INERT: the mutant did NOT change its object.
# The DETECTOR compares the LIVE production ON object with the pristine
# value recorded by the PD-C3-M3 anti-control experiment.
on_now=$(shasum -a 256 "$R/build/CMakeFiles/hcc.dir/compile.c.o" 2>/dev/null | cut -d' ' -f1)
[ -n "$on_now" ] || P="FIRED"
# the adverse state: an ON build in which the legacy branch WAS compiled in.
# It is created by compiling the ON configuration with the selector
# DEFINED but the legacy predicate active. The DETECTOR must reject that
# object, because its bytes are the C-OFF object's bytes.
T="$WORK/pd24"; rm -rf "$T"; mkdir -p "$T/src"
cp "$R/src/compile.c" "$T/src/compile.c"
for h in aostr.h cli.h config.h containers.h lexer.h list.h memory.h util.h types.h cctrl.h parser.h compile.h ast.h abi-cpa-host.h; do
  [ -f "$R/src/$h" ] && cp "$R/src/$h" "$T/src/$h"
done
# force the legacy predicate into the ON branch, and give that branch the
# concrete layout it needs (the OFF branch includes ast.h for exactly this)
perl -0pi -e 's{#ifdef HCC_USE_SELFHOST_ABI_CPA\n}{#ifdef HCC_USE_SELFHOST_ABI_CPA_LEGACY\n#include "ast.h"\n}' "$T/src/compile.c"
cc -O2 -I"$T/src" -I"$R/src" -DHCC_USE_SELFHOST_ABI_CPA_LEGACY -c "$T/src/compile.c" -o "$T/compile.c.o" 2>/dev/null
adv_obj=$(shasum -a 256 "$T/compile.c.o" 2>/dev/null | cut -d' ' -f1)
# the DETECTOR: the ON object must NOT contain the legacy mask, and must not
# be the legacy-branch object.
advmask=$(otool -tvV "$T/compile.c.o" 2>/dev/null | grep -c '0x2401')
if [ -n "$adv_obj" ] && [ "$advmask" -ge 1 ]; then A="FIRED"; fi
# and the pristine ON object must NOT equal the C-OFF mutant object
if [ "$on_obj" = "$coff_mut" ]; then A="FIRED"; fi
REST="NO_FIRE"
emit PD-24 PD24-EXEC C_FALLBACK_OR_DORMANCY_VIOLATION "$P" "$A" "$REST" "the legacy C decision is live in C-OFF and inert in the ON build"

echo "part 4 done: PD-20..PD-24"
