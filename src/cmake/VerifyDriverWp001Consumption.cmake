# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01
#
# Fail-closed verification that the production compiler CONSUMES the
# PolyC-selected emission action.
#
# A SYMBOL DEFINITION IS NOT CONSUMPTION. The PolyC driver subject may
# export WpDriverSelectedEmission and the production compiler may still
# never CALL it. In that state the PolyC action is DECORATIVE and the
# legacy C policy remains the real authority: the production compiler
# would still compile the required route exactly as before, and the
# transfer of authority would be a claim rather than a fact.
#
# This script therefore verifies the CONSUMPTION, not the definition.
# It reads the PRODUCTION OBJECT that performs the emission and
# requires an UNDEFINED REFERENCE to the emission accessor in that
# object. An object that does not import the accessor cannot be
# consuming it.
#
# Every failure path ABORTS the build with a distinct reason token.
# There is no "skip" path: the check cannot be skipped, because a
# skipped check is an unverified claim.

if (NOT DRIVER_WP001_PRODUCTION_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
        "REJECT_NO_PRODUCTION_OBJECT the verifier was invoked without the "
        "production object that performs the emission. The consumption "
        "check cannot be skipped: a symbol definition is not consumption.")
endif()

if (NOT EXISTS "${DRIVER_WP001_PRODUCTION_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
        "REJECT_MISSING_PRODUCTION_OBJECT the production object "
        "${DRIVER_WP001_PRODUCTION_OBJECT} does not exist. The consumption "
        "check cannot be skipped: a symbol definition is not consumption.")
endif()

# The spelling is resolved from the TARGET OBJECT FORMAT: Mach-O
# prefixes C symbols with an underscore, ELF does not.
if (DRIVER_WP001_TARGET_OBJECT_FORMAT STREQUAL "Mach-O")
    set(_dw_emission_symbol "_WpDriverSelectedEmission")
else()
    set(_dw_emission_symbol "WpDriverSelectedEmission")
endif()

execute_process(
    COMMAND "${DRIVER_WP001_NM}" --format=posix --no-weak "${DRIVER_WP001_PRODUCTION_OBJECT}"
    OUTPUT_VARIABLE _dw_prod_nm_output
    ERROR_VARIABLE _dw_prod_nm_error
    RESULT_VARIABLE _dw_prod_nm_rc)

if (NOT _dw_prod_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
        "REJECT_INVALID_PRODUCTION_OBJECT could not read the symbol table "
        "of ${DRIVER_WP001_PRODUCTION_OBJECT} (nm exit ${_dw_prod_nm_rc}: "
        "${_dw_prod_nm_error}). The consumption check cannot be skipped.")
endif()

string(REPLACE "\n" ";" _dw_prod_lines "${_dw_prod_nm_output}")

set(_dw_consumed 0)
set(_dw_defined 0)
foreach (_dw_prod_line IN LISTS _dw_prod_lines)
    if (_dw_prod_line STREQUAL "")
        continue()
    endif()
    string(REPLACE "\t" " " _dw_prod_line "${_dw_prod_line}")
    separate_arguments(_dw_prod_fields UNIX_COMMAND "${_dw_prod_line}")
    list(LENGTH _dw_prod_fields _dw_prod_field_count)
    if (_dw_prod_field_count LESS 2)
        continue()
    endif()
    list(GET _dw_prod_fields 0 _dw_prod_name)
    list(GET _dw_prod_fields 1 _dw_prod_type)
    if (NOT _dw_prod_name STREQUAL "${_dw_emission_symbol}")
        continue()
    endif()
    # An UNDEFINED reference (type U) is the consumption: the object
    # imports the accessor and the linker binds it to the PolyC subject.
    if (_dw_prod_type STREQUAL "U")
        set(_dw_consumed 1)
    endif()
    # A local DEFINITION would be a DUPLICATED ACTION SOURCE: the
    # production object would carry its own copy of the decision, and
    # the PolyC subject's decision would not be the one in force.
    if (_dw_prod_type STREQUAL "T")
        set(_dw_defined 1)
    endif()
endforeach()

if (_dw_defined GREATER 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
        "REJECT_DUPLICATE_ACTION_SOURCE the production object "
        "${DRIVER_WP001_PRODUCTION_OBJECT} DEFINES ${_dw_emission_symbol} "
        "itself. The production compiler would then carry its OWN copy of "
        "the emission decision and the PolyC subject's decision would not "
        "be the one in force. Refusing to link.")
endif()

if (_dw_consumed EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
        "REJECT_POLYC_ACTION_NOT_CONSUMED the production object "
        "${DRIVER_WP001_PRODUCTION_OBJECT} does not IMPORT "
        "${_dw_emission_symbol}. The PolyC driver subject exports the "
        "emission action, but the production compiler never CALLS it, so "
        "the action is decorative and the legacy C policy would remain "
        "the real authority. Refusing to link.")
endif()

file(SIZE "${DRIVER_WP001_PRODUCTION_OBJECT}" _dw_prod_size)

message(STATUS
    "ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01: "
    "DRIVER_WP001_CONSUMPTION_STATUS=PASS "
    "PRODUCTION_OBJECT=${DRIVER_WP001_PRODUCTION_OBJECT} "
    "CONSUMED_SYMBOL=${_dw_emission_symbol} "
    "PRODUCTION_OBJECT_SIZE=${_dw_prod_size}")
