# ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL
#
# Fail-closed verification of the control-flow-token subject.
#
# The object is the SOLE source of the production parser's
# control-flow-token authority. If it were missing, empty, or missing the
# exported symbol, the production compiler would silently fall back to
# the legacy C implementation. This script makes that outcome impossible:
# it either confirms the object is a real, symbol-bearing object, or it
# aborts the build.
#
# Invoked as a CMake script (-P) with:
#   -DCONTROL_FLOW_TOKEN_OBJECT=<path to the object>
#   -DCONTROL_FLOW_TOKEN_EXPECTED_SYMBOL=<symbol, default
#     _BootstrapValidPostControlFlowToken>

if (NOT CONTROL_FLOW_TOKEN_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "CONTROL_FLOW_TOKEN_OBJECT is not set. Cannot verify the control-flow-token subject.")
endif()

if (NOT EXISTS "${CONTROL_FLOW_TOKEN_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT} was not produced. "
        "Refusing to link the production compiler without a verified "
        "PolyC control-flow-token authority.")
endif()

file(SIZE "${CONTROL_FLOW_TOKEN_OBJECT}" _cft_size)
if (_cft_size LESS_EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified "
        "PolyC control-flow-token authority.")
endif()

if (NOT CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL)
    set(CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL "_BootstrapValidPostControlFlowToken")
endif()

# Look for the exported symbol in the object's symbol table. We use the
# platform's own nm; a missing nm is a hard error, never a pass.
find_program(_cft_nm NAMES nm llvm-nm)
if (NOT _cft_nm)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "no 'nm' found. The control-flow-token subject cannot be verified, "
        "so the production compiler is not linked.")
endif()

execute_process(
    COMMAND "${_cft_nm}" "${CONTROL_FLOW_TOKEN_OBJECT}"
    OUTPUT_VARIABLE _cft_nm_output
    ERROR_VARIABLE _cft_nm_error
    RESULT_VARIABLE _cft_nm_rc)

if (NOT _cft_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "could not read the symbol table of ${CONTROL_FLOW_TOKEN_OBJECT} "
        "(nm exit ${_cft_nm_rc}). Refusing to link the production compiler "
        "without a verified PolyC control-flow-token authority.")
endif()

string(REGEX MATCH "(^|[ \t])${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL}" _cft_symbol_hit
       "${_cft_nm_output}")
if (NOT _cft_symbol_hit)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02: "
        "symbol ${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL} not found in "
        "${CONTROL_FLOW_TOKEN_OBJECT}. Refusing to link the production "
        "compiler without a verified PolyC control-flow-token authority.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-PARSER-SLICE02: control-flow-token "
    "subject VERIFIED symbol=${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL} "
    "size=${_cft_size}")