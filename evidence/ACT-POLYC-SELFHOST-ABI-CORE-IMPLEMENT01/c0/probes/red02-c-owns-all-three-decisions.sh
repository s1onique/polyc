#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C0 RED-02
#
# DETECTOR: all three selected decisions are currently made in C. The C
#   decision sites are live in the production objects and NO PolyC core
#   operator symbol is imported by them.
# ANTI-CONTROL: a mere `extern` DECLARATION of a PolyC symbol is NOT
#   delegation -- the detector requires an actual object-level import.
set -u
cd "$(dirname "$0")/../../../.." || exit 2
OBJ=${1:-/tmp/polyc-aci01-c0-prod/CMakeFiles/hcc.dir}
CA_C=$(grep -c 'TK_ADD_EQU' src/prslib.c)
PO_C=$(grep -c 'AST_BIN_OP_LOG_AND' src/ast.c)
RO_C=$(grep -c 'astIsRangeOperator' src/ast.c)
CA_IMP=$(nm "$OBJ/prslib.c.o" 2>/dev/null | grep -c ' U _AbiCore')
PO_IMP=$(nm "$OBJ/ast.c.o" 2>/dev/null | grep -c ' U _AbiCore')
echo "DETECTOR=all three selected decisions are still made in C"
echo "SITE_CA_C_SOURCE_TK_ADD_EQU_OCCURRENCES=$CA_C"
echo "SITE_PO_C_SOURCE_AST_BIN_OP_LOG_AND_OCCURRENCES=$PO_C"
echo "SITE_RO_C_SOURCE_CALLER_OCCURRENCES=$RO_C"
echo "CA_OBJECT_POLYC_CORE_IMPORTS=$CA_IMP"
echo "PO_OBJECT_POLYC_CORE_IMPORTS=$PO_IMP"
echo "ANTI_CONTROL=an extern DECLARATION alone must not be mistaken for delegation"
echo "CA_OBJECT_DEFINES_PARSE_COMPOUND_ASSIGN=$(nm "$OBJ/prslib.c.o" 2>/dev/null | grep -c ' T _parseCompoundAssign')"
echo "PO_OBJECT_DEFINES_AST_IS_VALID_POINTER_OP=$(nm "$OBJ/ast.c.o" 2>/dev/null | grep -c ' T _astIsValidPointerOp')"
echo "RO_OBJECT_DEFINES_AST_IS_RANGE_OPERATOR=$(nm "$OBJ/ast.c.o" 2>/dev/null | grep -c ' T _astIsRangeOperator')"
if [ "$CA_IMP" -eq 0 ] && [ "$PO_IMP" -eq 0 ]; then echo "RED02_RESULT=RED_CONFIRMED"; else echo "RED02_RESULT=NOT_RED"; fi
if [ "$(nm "$OBJ/ast.c.o" 2>/dev/null | grep -c ' T _astIsRangeOperator')" -eq 1 ]; then
  echo "RED02_ANTI_CONTROL=DETECTOR_IS_SENSITIVE"; else echo "RED02_ANTI_CONTROL=DETECTOR_INSENSITIVE"; fi
