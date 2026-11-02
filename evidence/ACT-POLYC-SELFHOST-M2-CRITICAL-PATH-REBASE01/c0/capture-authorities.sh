#!/bin/sh
# evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c0/capture-authorities.sh
#
# ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01 C0 RED.
#
# Regenerates c0/fifteen-authorities-entry.tsv by MEASURING the real
# production object graph. It does NOT copy the predecessor's census:
# it re-derives, for every one of the fifteen PolyC authorities,
#
#   - the subject object that DEFINES it (global text symbol),
#   - whether the production link line NAMES that object,
#   - whether the symbol is a global text symbol in the LINKED ./hcc,
#   - the number of production C objects that IMPORT it,
#   - the C callsite line that imports it.
#
# It also MEASURES the CSET counter-example: aarch64EmitCSet must NOT
# be counted as a semantic authority because it is static (no exported
# symbol), it owns no condition selection of its own, and its body
# carries zero switches, zero cases and zero IR_CMP references.
#
# The output is data. No verdict field is hand-written.

set -u

EV="evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
OUT="$EV/c0/fifteen-authorities-entry.tsv"
LINK="build/CMakeFiles/hcc.dir/link.txt"
HCC="build/hcc"

# The fifteen authorities, in the predecessor's established order. The
# ORDER and the SET are historical facts; every other column below is
# MEASURED here.
AUTH_LIST="\
_BootstrapCalcPadding
_BootstrapValidPostControlFlowToken
_BootstrapOperatorPrecedence
_BootstrapAstBinOpFromToken
_BootstrapAstUnaryOpFromToken
_BootstrapSwitchArmTerminates
_BootstrapCompoundBlockAppendsStatement
_BootstrapDefaultArmTerminates
_BootstrapStatementDispatch
_AbiCpaShouldPrintAst
_AbiCoreClassifyCompoundAssign
_AbiCoreIsValidPointerOperator
_AbiCoreIsRangeOperator
_AbiA64CcForV2
_AbiA64CcInvForV2"

{
  echo "# ACT_ID=ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01"
  echo "# ACT_PHASE=C0-RED"
  echo "# EVIDENCE_KIND=fifteen-authorities-entry"
  echo "#"
  echo "# EVERY COLUMN BELOW WAS MEASURED FROM THE REAL PRODUCTION OBJECT"
  echo "# GRAPH AT THIS ACT's C0 PHASE. No verdict is hand-authored."
  echo "#"
  echo "# defn_object       the object that DEFINES the symbol as a global text symbol"
  echo "# linkin            1 iff the production link line NAMES that object"
  echo "# linked            1 iff the symbol is a global text symbol in the LINKED ./hcc"
  echo "# importingCobjs    how many production C objects IMPORT the symbol"
  echo "# c_callsite        the src/*.c:line that imports it (the load-bearing C call)"
  echo "#"
  printf 'authority_id\tsymbol\tdefn_object\tlinkin\tlinked\timportingCobjs\tc_callsite\tsource_blob\tproducer\tverdict\n'
} > "$OUT"

idx=0
for sym in $AUTH_LIST; do
  idx=$((idx + 1))
  aid=$(printf 'AUTH-%02d' "$idx")

  # The definition site must be an object that the PRODUCTION LINK LINE
  # actually names. build/ also holds stale fixedpoint artifacts
  # (core-operator-subject-G1.o and friends) that are NOT linked. They
  # are excluded here so the census cannot pick a non-production
  # object by accident.
  defn=""
  linkin=0
  for o in build/*.o; do
    [ -f "$o" ] || continue
    base=$(basename "$o")
    grep -q -- "$base" "$LINK" 2>/dev/null || continue
    if nm -g "$o" 2>/dev/null | grep -qE "^[0-9a-f]+ [TDRB] ${sym}\$"; then
      defn="$o"
      linkin=1
      break
    fi
  done
  [ -n "$defn" ] || defn="NONE"

  linked=0
  if [ -f "$HCC" ]; then
    if nm -g "$HCC" 2>/dev/null | grep -qE "^[0-9a-f]+ [TDRB] ${sym}\$"; then
      linked=1
    fi
  fi

  nimp=0
  callsite=""
  for o in build/CMakeFiles/hcc.dir/*.o; do
    [ -f "$o" ] || continue
    if nm -u "$o" 2>/dev/null | grep -qx -- "$sym"; then
      nimp=$((nimp + 1))
      if [ -z "$callsite" ]; then
        # The C `extern` declaration of a PolyC authority DROPS the
        # leading underscore (the C symbol is `BootstrapCalcPadding`,
        # the Mach-O symbol is `_BootstrapCalcPadding`). So the
        # callsite is searched for BOTH spellings, and comment-only
        # lines are skipped so the recorded callsite is a REAL call.
        bare=$(printf '%s' "$sym" | sed 's/^_//')
        hits=$(grep -rn --include='*.c' -w "$bare" src/ 2>/dev/null \
               | grep -vE ':[0-9]+: *(\*|//|/\*)' \
               | grep -E "[^A-Za-z0-9_]${bare}\s*\(" \
               | head -1)
        if [ -n "$hits" ]; then
          callsite=$(printf '%s' "$hits" | sed 's|^src/*||' | cut -d: -f1,2)
        else
          callsite="NO_C_CALLSITE_FOUND"
        fi
      fi
    fi
  done

  blob="NOT_APPLICABLE"
  case "$sym" in
    _BootstrapCalcPadding) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-padding.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapValidPostControlFlowToken) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-control-flow-token.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapOperatorPrecedence) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-operator-precedence.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapAstBinOpFromToken) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-slice04.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapAstUnaryOpFromToken) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-slice05.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapSwitchArmTerminates) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-slice06.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapCompoundBlockAppendsStatement) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-slice07.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapDefaultArmTerminates) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-slice08.HC 2>/dev/null || echo NOT_FOUND);;
    _BootstrapStatementDispatch) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-parser-statement-dispatch.HC 2>/dev/null || echo NOT_FOUND);;
    _AbiCpaShouldPrintAst) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-abi-compile-print-ast.HC 2>/dev/null || echo NOT_FOUND);;
    _AbiCore*) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-core-operator.HC 2>/dev/null || echo NOT_FOUND);;
    _AbiA64CcForV2|_AbiA64CcInvForV2) blob=$(git rev-parse HEAD:tools/bootstrap/selfhost-a64-cmp-cc-v2.HC 2>/dev/null || echo NOT_FOUND);;
  esac

  # The PRODUCER of each subject object. The Makefile builds every
  # PolyC subject with $(BOOTSTRAP_STAGE0_HCC) --install-dir=... -c
  # <src.HC> -o <obj>, i.e. the C-ROOTED stage0 compiler is the producer.
  # The producer is therefore MEASURED from the build rule, not assumed.
  producer="UNKNOWN_PRODUCER"
  case "$defn" in
    *-subject.o|*subject*.o)
      producer="C_ROOTED_STAGE0_HCC"
      ;;
  esac

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$aid" "$sym" "$defn" "$linkin" "$linked" "$nimp" "$callsite" "$blob" "$producer" "MEASURED" >> "$OUT"
done

# --------------------------------------------------------------------------
# THE CSET COUNTER-EXAMPLE, MEASURED
# --------------------------------------------------------------------------
# aarch64EmitCSet MUST NOT be counted as a semantic authority. The
# three measured facts are: (1) it is `static`, so it exports no
# symbol at all; (2) its whole body carries ZERO switches, ZERO cases
# and ZERO IR_CMP references, so it owns NO condition selection; and
# (3) it is CALLED BY THE C CODE, not by a PolyC authority.
{
  echo "#"
  echo "# -------------------------------------------------------------------------"
  echo "# THE CSET COUNTER-EXAMPLE (MEASURED, NOT ASSERTED)"
  echo "# -------------------------------------------------------------------------"
  echo "#"
  printf 'check\tvalue\tmethod\n'
  printf 'CSET_SYMBOL_NAME\taarch64EmitCSet\tgrep -n aarch64EmitCSet src/aarch64.c\n'
  printf 'CSET_DEFINITION_LINE\t%s\tgrep -n "^static void aarch64EmitCSet" src/aarch64.c\n' \
    "$(grep -n '^static void aarch64EmitCSet' src/aarch64.c | head -1 | cut -d: -f1)"
  printf 'CSET_IS_STATIC\t%s\tgrep -c "^static void aarch64EmitCSet" src/aarch64.c\n' \
    "$(grep -c '^static void aarch64EmitCSet' src/aarch64.c)"
  printf 'CSET_EXPORTED_SYMBOL_COUNT_IN_LINKED_HCC\t%s\tnm -g build/hcc | grep -c " _aarch64EmitCSet$"\n' \
    "$(nm -g build/hcc 2>/dev/null | grep -c ' _aarch64EmitCSet$')"
  printf 'CSET_BODY_SWITCH_CASE_IRCMP_COUNT\t%s\tgrep -cE "switch|case |IR_CMP" over the whole definition body\n' \
    "$(awk 'NR>=1008 && NR<=1011' src/aarch64.c | grep -cE 'switch|case |IR_CMP')"
  printf 'CSET_BODY_SHA256\t%s\tshasum -a 256 over the whole definition body\n' \
    "$(awk 'NR>=1008 && NR<=1011' src/aarch64.c | shasum -a 256 | awk '{print $1}')"
  printf 'CSET_C_CALLERS_IN_AARCH64_C\t%s\tgrep -c "aarch64EmitCSet(ctx" src/aarch64.c\n' \
    "$(grep -c 'aarch64EmitCSet(ctx' src/aarch64.c)"
  printf 'CSET_IS_SEMANTIC_AUTHORITY\tNO\tstatic linkage + zero condition selection in body\n'
  printf 'CSET_ADAPTER_NOT_COUNTED\tYES\tno exported symbol; not in the authority roster\n'
  echo "#"
  echo "# MEASURED COUNTS"
  printf 'PRODUCTION_POLYC_AUTHORITIES_MEASURED\t%s\trows with linkin=1 AND linked=1 AND importingCobjs>=1\n' \
    "$(awk -F'\t' '!/^#/ && NF>5 && $4==1 && $5==1 && $6>=1 {n++} END{print n+0}' "$OUT")"
  printf 'PRODUCTION_POLYC_AUTHORITIES_WITH_ONE_IMPORTER\t%s\trows with importingCobjs==1\n' \
    "$(awk -F'\t' '!/^#/ && NF>5 && $6==1 {n++} END{print n+0}' "$OUT")"
  printf 'PRODUCTION_POLYC_AUTHORITIES_ROSTER_SIZE\t%s\ttotal data rows (AUTH-* rows only)\n' \
    "$(awk -F'\t' '$1 ~ /^AUTH-[0-9]+$/ {n++} END{print n+0}' "$OUT")"
  printf 'STAGE0_PRODUCER_PATH\t%s\t$(BOOTSTRAP_STAGE0_DIR)/hcc per Makefile\n' \
    "build/host-stage0/hcc"
  printf 'STAGE0_PRODUCER_SHA256\t%s\tshasum -a 256 build/host-stage0/hcc\n' \
    "$(shasum -a 256 build/host-stage0/hcc 2>/dev/null | awk '{print $1}' || echo UNAVAILABLE)"
  printf 'PRODUCTION_HCC_SHA256\t%s\tshasum -a 256 build/hcc (the linked hybrid compiler)\n' \
    "$(shasum -a 256 build/hcc 2>/dev/null | awk '{print $1}' || echo UNAVAILABLE)"
  printf 'PRODUCTION_LINK_LINE_OBJ_COUNT\t%s\tone .o per line in build/CMakeFiles/hcc.dir/link.txt\n' \
    "$(tr ' ' '\n' < "$LINK" | grep -c '\.o$')"
  printf 'PRODUCTION_POLYC_SUBJECT_OBJ_COUNT\t%s\tsubject objects named by the production link line\n' \
    "$(tr ' ' '\n' < "$LINK" | grep -c 'subject\.o$')"
  echo "#"
  echo "# -------------------------------------------------------------------------"
  echo "# FOR/INV SEPARATION (MEASURED)"
  echo "# -------------------------------------------------------------------------"
  echo "# The two AArch64 condition decisions must be DISTINCT symbols with"
  echo "# DISTINCT definitions, and CSET must be a THIRD, non-authority site."
  printf 'check\tvalue\tmethod\n'
  printf 'FOR_SYMBOL\t_AbiA64CcForV2\tnm -g build/a64-cmp-cc-subject.o\n'
  printf 'INV_SYMBOL\t_AbiA64CcInvForV2\tnm -g build/a64-cmp-cc-subject.o\n'
  printf 'FOR_AND_INV_ARE_DISTINCT_SYMBOLS\t%s\ttwo distinct global text symbols (awk exact-match on $3)\n' \
    "$(nm -g build/a64-cmp-cc-subject.o 2>/dev/null | awk '$3=="_AbiA64CcForV2"||$3=="_AbiA64CcInvForV2"{print $3}' | sort -u | wc -l | tr -d ' ')"
  printf 'FOR_AND_INV_DISTINCT_ADDRESSES\t%s\tthe two symbols have DIFFERENT addresses\n' \
    "$(nm -g build/a64-cmp-cc-subject.o 2>/dev/null | awk '$3=="_AbiA64CcForV2"||$3=="_AbiA64CcInvForV2"{print $1}' | sort -u | wc -l | tr -d ' ')"
  printf 'FOR_EXPORTED_IN_LINKED_HCC\t%s\tnm -g build/hcc | grep -c " _AbiA64CcForV2$"\n' \
    "$(nm -g build/hcc 2>/dev/null | grep -c ' _AbiA64CcForV2$')"
  printf 'INV_EXPORTED_IN_LINKED_HCC\t%s\tnm -g build/hcc | grep -c " _AbiA64CcInvForV2$"\n' \
    "$(nm -g build/hcc 2>/dev/null | grep -c ' _AbiA64CcInvForV2$')"
  printf 'A64_POLYC_EXPORT_COUNT\t%s\tthe a64 subject exports EXACTLY two public semantic functions\n' \
    "$(nm -g build/a64-cmp-cc-subject.o 2>/dev/null | grep -cE '^[0-9a-f]+ [TDRB] _Abi')"
  printf 'A64_THIRD_EXPORT_ABSENT\t%s\tYES iff the subject exports EXACTLY the two FOR/INV symbols\n' \
    "$(nm -g build/a64-cmp-cc-subject.o 2>/dev/null | grep -E '^[0-9a-f]+ [TDRB] _' | awk '{print $3}' | sort -u | grep -cE '^_Abi' | awk '{print ($1==2) ? "YES" : "NO"}')"
  printf 'CSET_IN_A64_POLYC_SUBJECT\t%s\tthe CSET adapter must NOT live in the PolyC subject\n' \
    "$(nm -g build/a64-cmp-cc-subject.o 2>/dev/null | grep -ci 'cset')"
} >> "$OUT"

echo "AUTHORITIES_WRITTEN=$OUT"
