# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C2 IMPL
#
# Fail-closed verification of the PolyC compiler driver subject.
#
# The object is the SOLE source of the production compiler's CLI
# decision authority. If it were missing, empty, or missing one of the
# exported driver symbols, the production compiler would silently fall
# back to the legacy C parser. This script makes that outcome
# impossible: it either confirms the object is a real object carrying
# EVERY required driver symbol as a strong global text definition, or
# it aborts the build with a concrete reason token.
#
# THE REQUIRED SYMBOL ROSTER is the frozen ABI from
# evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01/c1/abi-ownership-and-recovery.md.
# All of them must be present: a partial driver is not a driver.
#
# Mach-O naming is NOT hard-coded: the expected symbol spellings are
# derived from the TARGET OBJECT FORMAT, which is passed in explicitly.

if (NOT DRIVER_WP001_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_NO_OBJECT the verifier was invoked without an object.")
endif()

if (NOT EXISTS "${DRIVER_WP001_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_MISSING_DRIVER_SUBJECT "
        "the PolyC driver subject ${DRIVER_WP001_OBJECT} does not exist. "
        "Refusing to link the production compiler without a verified PolyC "
        "compiler driver.")
endif()

file(SIZE "${DRIVER_WP001_OBJECT}" _dw_size)
if (_dw_size EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_EMPTY_DRIVER_SUBJECT "
        "the PolyC driver subject ${DRIVER_WP001_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified PolyC "
        "compiler driver.")
endif()

execute_process(
    COMMAND "${DRIVER_WP001_NM}" --format=posix --no-weak "${DRIVER_WP001_OBJECT}"
    OUTPUT_VARIABLE _dw_nm_output
    ERROR_VARIABLE _dw_nm_error
    RESULT_VARIABLE _dw_nm_rc)

if (NOT _dw_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_INVALID_OBJECT "
        "could not read the symbol table of ${DRIVER_WP001_OBJECT} "
        "(nm exit ${_dw_nm_rc}: ${_dw_nm_error}). Refusing to link the "
        "production compiler without a verified PolyC compiler driver.")
endif()

# ---------------------------------------------------------------------------
# The REQUIRED SYMBOL ROSTER.
#
# Every one of these must be a strong global text definition. The
# spelling is resolved from the TARGET OBJECT FORMAT: Mach-O prefixes
# C symbols with an underscore, ELF does not.
# ---------------------------------------------------------------------------
set(_dw_required_symbols
    WpDriverClassifyOption
    WpDriverClassifyArgument
    WpDriverUnknownArgCount
    WpDriverArityViolationCount
    WpDriverValueArgIndex
    WpDriverValueOffset
    WpDriverOptionField
    WpDriverOptionAction
    WpDriverSelectAction
    WpDriverMapStatus
    WpDriverDecide
    WpDriverSelectedAction
    WpDriverSelectedEmission)

string(REPLACE "\n" ";" _dw_lines "${_dw_nm_output}")

set(_dw_missing "")
set(_dw_undefined "")
set(_dw_local "")

foreach (_dw_sym IN LISTS _dw_required_symbols)
    if (DRIVER_WP001_TARGET_OBJECT_FORMAT STREQUAL "Mach-O")
        set(_dw_target_symbol "_${_dw_sym}")
    else()
        set(_dw_target_symbol "${_dw_sym}")
    endif()

    set(_dw_defined_count 0)
    set(_dw_undef_count 0)
    set(_dw_local_count 0)

    foreach (_dw_line IN LISTS _dw_lines)
        if (_dw_line STREQUAL "")
            continue()
        endif()
        string(REPLACE "\t" " " _dw_line "${_dw_line}")
        separate_arguments(_dw_fields UNIX_COMMAND "${_dw_line}")
        list(LENGTH _dw_fields _dw_field_count)
        if (_dw_field_count LESS 2)
            continue()
        endif()
        list(GET _dw_fields 0 _dw_name)
        list(GET _dw_fields 1 _dw_type)
        if (NOT _dw_name STREQUAL "${_dw_target_symbol}")
            continue()
        endif()
        if (_dw_type STREQUAL "T")
            math(EXPR _dw_defined_count "${_dw_defined_count} + 1")
        elseif (_dw_type STREQUAL "U")
            math(EXPR _dw_undef_count "${_dw_undef_count} + 1")
        elseif (_dw_type MATCHES "^[a-z]")
            math(EXPR _dw_local_count "${_dw_local_count} + 1")
        endif()
    endforeach()

    if (_dw_defined_count EQUAL 0)
        if (_dw_undef_count GREATER 0)
            list(APPEND _dw_undefined "${_dw_sym}")
        elseif (_dw_local_count GREATER 0)
            list(APPEND _dw_local "${_dw_sym}")
        else()
            list(APPEND _dw_missing "${_dw_sym}")
        endif()
    elseif (_dw_defined_count GREATER 1)
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
            "REJECT_DUPLICATE_DEFINITION the symbol ${_dw_target_symbol} has "
            "${_dw_defined_count} definitions in ${DRIVER_WP001_OBJECT}; "
            "exactly one is required. "
            "Refusing to link the production compiler without a verified PolyC "
            "compiler driver.")
    endif()
endforeach()

if (NOT _dw_missing STREQUAL "")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_SYMBOL_NAME_MISMATCH the driver subject "
        "${DRIVER_WP001_OBJECT} does not define: ${_dw_missing}. "
        "Refusing to link the production compiler without a verified PolyC "
        "compiler driver.")
endif()

if (NOT _dw_undefined STREQUAL "")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_UNDEFINED_SYMBOL the driver subject "
        "${DRIVER_WP001_OBJECT} carries these symbols only as UNDEFINED "
        "references: ${_dw_undefined}. "
        "Refusing to link the production compiler without a verified PolyC "
        "compiler driver.")
endif()

if (NOT _dw_local STREQUAL "")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
        "REJECT_LOCAL_SYMBOL the driver subject ${DRIVER_WP001_OBJECT} "
        "carries these symbols only as LOCAL symbols: ${_dw_local}. "
        "Refusing to link the production compiler without a verified PolyC "
        "compiler driver.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-DRIVER-MIGRATION01: "
    "DRIVER_WP001_OBJECT_STATUS=PASS "
    "EXPECTED_SYMBOL=${DRIVER_WP001_EXPECTED_SYMBOL} "
    "TARGET_OBJECT_FORMAT=${DRIVER_WP001_TARGET_OBJECT_FORMAT} "
    "REQUIRED_SYMBOL_COUNT=13 "
    "OBJECT_SIZE=${_dw_size}")
