#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C0 RED-01
#
# DETECTOR: the production compiler defines no core-operator PolyC authority.
# ANTI-CONTROL: the EXISTING CPA authority IS present, proving the detector
#               can see a real PolyC authority when one exists.
set -u
cd "$(dirname "$0")/../../../.." || exit 2
PROD=${1:-/tmp/hcc}
N_CORE=$(nm "$PROD" 2>/dev/null | grep -cE ' T _AbiCore(ClassifyCompoundAssign|IsValidPointerOperator|IsRangeOperator)$')
N_CPA=$(nm "$PROD" 2>/dev/null | grep -c ' T _AbiCpaShouldPrintAst$')
echo "DETECTOR=production binary defines no core-operator PolyC authority symbol"
echo "PRODUCTION_BINARY=$PROD"
echo "CORE_OPERATOR_AUTHORITY_SYMBOL_COUNT=$N_CORE"
echo "SELECTOR_IN_CMAKE=$(grep -c 'HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY' src/CMakeLists.txt)"
echo "SELECTOR_IN_MAKEFILE=$(grep -c 'HCC_USE_SELFHOST_CORE_OPERATOR_CLASSIFY' Makefile)"
echo "POLYC_SUBJECT_SOURCE_COUNT=$(ls tools/bootstrap/selfhost-core-operator-*.HC 2>/dev/null | wc -l | tr -d ' ')"
echo "ANTI_CONTROL_SYMBOL=_AbiCpaShouldPrintAst"
echo "ANTI_CONTROL_SYMBOL_COUNT=$N_CPA"
if [ "$N_CORE" -eq 0 ]; then echo "RED01_RESULT=RED_CONFIRMED"; else echo "RED01_RESULT=NOT_RED"; fi
if [ "$N_CPA" -eq 1 ]; then echo "RED01_ANTI_CONTROL=DETECTOR_IS_SENSITIVE"; else echo "RED01_ANTI_CONTROL=DETECTOR_INSENSITIVE"; fi
