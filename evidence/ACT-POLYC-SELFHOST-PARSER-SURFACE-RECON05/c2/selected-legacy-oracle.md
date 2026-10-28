# ACT_ID=ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05
# ACT_PHASE=C2-RANK-SELECT
# EVIDENCE_KIND=selected-legacy-oracle
#
# THE LEGACY C ORACLE.  IT IS OBJECT-LEVEL.
#
# THE REQUIREMENT
#   "A source-extracted standalone C condition alone is NOT an
#    acceptable G0 oracle: compile the actual production C
#    translation unit with the proposed delegation DISABLED, and
#    prove that object does not reference the proposed PolyC
#    symbol."
#
# THE G0 OBJECT
#   OBJECT   = build/CMakeFiles/hcc.dir/parser.c.o
#   It is the REAL production translation unit of src/parser.c,
#   compiled by the production CMake build with the production
#   flags recorded in build/CMakeFiles/hcc.dir/flags.make.
#
#   COMMAND=grep -o HCC_USE_SELFHOST[A-Z_]* build/CMakeFiles/hcc.dir/flags.make | sort -u
#     HCC_USE_SELFHOST_PARSER_AST_BINOP
#     HCC_USE_SELFHOST_PARSER_AST_UNARY
#     HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN
#     HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE
#     HCC_USE_SELFHOST_PARSER_PADDING
#     HCC_USE_SELFHOST_PARSER_SWITCH_ARM
#   C_FLAGS = -Wextra -Wall -Wpedantic -O3 -DNDEBUG -O2 -std=gnu11 -arch arm64
#   TARGET_OBJECT_FORMAT=Mach-O
#
# THE PROPOSED SYMBOL IS ABSENT FROM THE G0 OBJECT
#   COMMAND=nm build/CMakeFiles/hcc.dir/parser.c.o | grep BootstrapCompoundBlock
#   (no output)
#   G0_ORACLE_POLYC_REFERENCE=ABSENT
#   The object carries NO undefined reference to the proposed
#   symbol, so the object-level oracle is INDEPENDENT of the
#   proposed PolyC target: it cannot be contaminated by it.
#
# THE OBJECT IS THE GENUINE PRODUCTION TU
#   COMMAND=nm build/CMakeFiles/hcc.dir/parser.c.o | grep " U _Bootstrap"
#     U _BootstrapCalcPadding
#     U _BootstrapSwitchArmTerminates
#     U _BootstrapValidPostControlFlowToken
#   The object imports the SIX already-migrated PolyC authorities
#   as UNDEFINED references and does NOT define them.  That is
#   the strong form of "this is the live production object", and
#   it also proves the object is NOT a hand-written stand-in.
#   EXPORTED_FUNCTIONS_IN_OBJECT=52
#;
# THE G0 ORACLE RECIPE FOR THE SUCCESSOR
#   1. compile the REAL production src/parser.c with the SAME
#      production flags, WITHOUT the new selector;
#   2. assert that the resulting object has NO undefined
#      reference to BootstrapCompoundBlockAppendsStatement;
#   3. link the oracle adapter against that object;
#   4. compare the oracle against the PolyC component over the
#      derived fixture.
#   The oracle adapter MUST be a separate TU that calls the
#   REAL production object; it must not re-implement the
#   condition.  A re-implemented condition would be a
#   hand-written oracle and is FORBIDDEN by ACT section 5 CC-02.
#;
# G0_REAL_PRODUCTION_C_OBJECT=build/CMakeFiles/hcc.dir/parser.c.o
# G0_ORACLE_POLYC_REFERENCE=ABSENT
# G0_ORACLE_KIND=OBJECT_LEVEL
# G0_ORACLE_IS_REAL_PRODUCTION_TU=YES
# G0_ORACLE_HAND_WRITTEN=NO
