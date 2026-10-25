# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL
#
# Fail-closed verification of the parser-padding subject.
#
# The object is the SOLE source of the production parser's padding
# authority. If it were missing, empty, or missing the exported symbol,
# the production compiler would silently fall back to the legacy C
# implementation. This script makes that outcome impossible: it either
# confirms the object is a real, symbol-bearing object, or it aborts the
# build.
#
# Invoked as a CMake script (-P) with:
#   -DPARSER_PADDING_OBJECT=<path to the object>
#   -DPARSER_PADDING_EXPECTED_SYMBOL=<symbol, default _BootstrapCalcPadding>

if (NOT PARSER_PADDING_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "PARSER_PADDING_OBJECT is not set. Cannot verify the parser-padding subject.")
endif()

if (NOT EXISTS "${PARSER_PADDING_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "parser-padding subject ${PARSER_PADDING_OBJECT} was not produced. "
        "Refusing to link the production compiler without a verified "
        "PolyC padding authority.")
endif()

file(SIZE "${PARSER_PADDING_OBJECT}" _pp_size)
if (_pp_size LESS_EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "parser-padding subject ${PARSER_PADDING_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified "
        "PolyC padding authority.")
endif()

if (NOT PARSER_PADDING_EXPECTED_SYMBOL)
    set(PARSER_PADDING_EXPECTED_SYMBOL "_BootstrapCalcPadding")
endif()

# Look for the exported symbol in the object's symbol table. We use the
# platform's own nm; a missing nm is a hard error, never a pass.
find_program(_pp_nm NAMES nm llvm-nm)
if (NOT _pp_nm)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "no 'nm' found. The parser-padding subject cannot be verified, "
        "so the production compiler is not linked.")
endif()

execute_process(
    COMMAND "${_pp_nm}" "${PARSER_PADDING_OBJECT}"
    OUTPUT_VARIABLE _pp_nm_output
    ERROR_VARIABLE _pp_nm_error
    RESULT_VARIABLE _pp_nm_rc)

if (NOT _pp_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "could not read the symbol table of ${PARSER_PADDING_OBJECT} "
        "(nm exit ${_pp_nm_rc}). Refusing to link the production compiler "
        "without a verified PolyC padding authority.")
endif()

string(REGEX MATCH "(^|[ \t])${PARSER_PADDING_EXPECTED_SYMBOL}" _pp_symbol_hit
       "${_pp_nm_output}")
if (NOT _pp_symbol_hit)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
        "symbol ${PARSER_PADDING_EXPECTED_SYMBOL} not found in "
        "${PARSER_PADDING_OBJECT}. Refusing to link the production "
        "compiler without a verified PolyC padding authority.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: parser-padding "
    "subject VERIFIED symbol=${PARSER_PADDING_EXPECTED_SYMBOL} "
    "size=${_pp_size}")
