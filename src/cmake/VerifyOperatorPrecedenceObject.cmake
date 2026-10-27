# ACT-POLYC-SELFHOST-PARSER-SLICE03 C2 IMPL
#
# Fail-closed verification of the operator-precedence subject.
#
# The object is the SOLE source of the production parser's
# operator-precedence authority. If it were missing, empty, or missing the
# exported symbol, the production compiler would silently fall back to
# the legacy C implementation. This script makes that outcome impossible:
# it either confirms the object is a real object carrying exactly one
# strong global text definition of the expected symbol, or it aborts the
# build with a concrete reason token.
#
# WHAT CHANGED (relative to the SLICE02 version of this file):
#
#   D1-A  The expected symbol SPELLING is resolved from the TARGET
#         OBJECT FORMAT, which is passed in explicitly. The SLICE02
#         version hard-coded the Mach-O spelling "_X", so a perfectly
#         valid ELF object -- which spells the same C symbol "X" -- was
#         rejected on Linux purely because of its platform.
#
#   D1-B  A record of type "U" (undefined reference) is REJECTED.
#         The SLICE02 version only searched for the name in the raw
#         output, so an object containing no implementation at all
#         satisfied it.
#
#   D1-C  The name must match EXACTLY. The SLICE02 version used a
#         prefix regex, so "_BootstrapOperatorPrecedenceExtra"
#         satisfied it.
#
#   D1-D  A lowercase type (local symbol) is REJECTED. A weak or
#         common definition is REJECTED. More than one matching
#         definition is REJECTED.
#
#   D2    The script is now invoked from BOTH producer mode and
#         prebuilt-object mode, so the same strict gate applies to
#         every path that can link the production compiler.
#
# HOW THE SYMBOL TABLE IS READ
#
#   nm --format=posix --no-weak <object>
#
# Both Apple nm and GNU nm implement these two flags with the SAME
# meaning, which is what makes this check portable:
#
#   --format=posix  one record per symbol: "<name> <type> <value> <size>"
#   --no-weak       weak and common definitions are OMITTED entirely
#
# The type letters are the same on both platforms:
#
#   T  global strong text (code)      <- the ONLY acceptable kind
#   U  undefined reference             <- rejected
#   t  local text                      <- rejected
#   W  weak text                       <- filtered out by --no-weak
#   C  common                          <- filtered out by --no-weak
#
# WHY --no-weak IS LOAD-BEARING: on ELF, GNU nm reports a weak
# definition as "W", so the type letter alone would reject it. On Mach-O
# the default nm reports a weak definition as "T" -- the SAME letter as
# a strong definition -- so the type letter alone CANNOT reject it
# there. A weak definition is also LINKABLE: it satisfies a production
# reference at link time, so accepting it would admit an object with no
# strong production authority. Filtering it out removes the ambiguity on
# both platforms.
#
# The Mach-O-only "-m" flag is deliberately NOT used: GNU nm rejects it
# ("nm: invalid option -- m").
#
# Invoked as a CMake script (-P) with:
#   -DOPERATOR_PRECEDENCE_OBJECT=<path to the object>          (required)
#   -DOPERATOR_PRECEDENCE_EXPECTED_SYMBOL=<logical symbol>     (optional,
#                                                                  default
#                                                                  BootstrapOperatorPrecedence)
#   -DOPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT=<Mach-O|ELF>    (optional,
#                                                                  default Mach-O)
#   -DOPERATOR_PRECEDENCE_NM=<path to nm>                      (optional;
#                                                                  defaults to
#                                                                  the toolchain
#                                                                  nm passed by
#                                                                  the caller)
#
# The object format is NEVER guessed from the host: during a
# cross-compile the host's format is not the target's format, and
# guessing wrong rejects a correct object (or accepts a wrong one).

# ---------------------------------------------------------------------------
# The canonical LOGICAL symbol. Its object-format spelling is derived below.
# ---------------------------------------------------------------------------
if (NOT OPERATOR_PRECEDENCE_EXPECTED_SYMBOL)
    set(OPERATOR_PRECEDENCE_EXPECTED_SYMBOL "BootstrapOperatorPrecedence")
endif()

# ---------------------------------------------------------------------------
# The target object format -> the spelling of the symbol in that format.
# ---------------------------------------------------------------------------
if (NOT OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT)
    set(OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT "Mach-O")
endif()

string(TOUPPER "${OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT}" _op_format)

if (_op_format STREQUAL "MACH-O" OR _op_format STREQUAL "MACHO" OR _op_format STREQUAL "DARWIN")
    set(_op_target_symbol "_${OPERATOR_PRECEDENCE_EXPECTED_SYMBOL}")
elseif (_op_format STREQUAL "ELF")
    set(_op_target_symbol "${OPERATOR_PRECEDENCE_EXPECTED_SYMBOL}")
else()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_UNSUPPORTED_OBJECT_FORMAT "
        "OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT=${OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT} "
        "is neither Mach-O nor ELF, so the spelling of "
        "${OPERATOR_PRECEDENCE_EXPECTED_SYMBOL} in the target object is "
        "unknown. Refusing to link the production compiler without a "
        "verified PolyC operator-precedence authority.")
endif()

# ---------------------------------------------------------------------------
# The object must exist.
# ---------------------------------------------------------------------------
if (NOT OPERATOR_PRECEDENCE_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_INVALID_OBJECT "
        "OPERATOR_PRECEDENCE_OBJECT is not set. Cannot verify the "
        "operator-precedence subject.")
endif()

if (NOT EXISTS "${OPERATOR_PRECEDENCE_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_INVALID_OBJECT "
        "operator-precedence subject ${OPERATOR_PRECEDENCE_OBJECT} was not "
        "produced. Refusing to link the production compiler without a "
        "verified PolyC operator-precedence authority.")
endif()

# ---------------------------------------------------------------------------
# The object must be non-empty.
# ---------------------------------------------------------------------------
file(SIZE "${OPERATOR_PRECEDENCE_OBJECT}" _op_size)
if (_op_size LESS_EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_INVALID_OBJECT "
        "operator-precedence subject ${OPERATOR_PRECEDENCE_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified "
        "PolyC operator-precedence authority.")
endif()

# ---------------------------------------------------------------------------
# The nm tool. The caller passes the CONFIGURED TOOLCHAIN's nm, so a
# cross-compile inspects the target object with a tool that understands
# the target format. A missing tool is a hard error, never a pass.
# ---------------------------------------------------------------------------
if (OPERATOR_PRECEDENCE_NM)
    set(_op_nm "${OPERATOR_PRECEDENCE_NM}")
else()
    find_program(_op_nm NAMES nm llvm-nm)
endif()

if (NOT _op_nm)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_NM_FAILURE "
        "no 'nm' found. The operator-precedence subject cannot be "
        "verified, so the production compiler is not linked.")
endif()

# ---------------------------------------------------------------------------
# Read the symbol table. --format=posix gives one "<name> <type> ..." record
# per symbol; --no-weak removes weak and common definitions.
# ---------------------------------------------------------------------------
execute_process(
    COMMAND "${_op_nm}" --format=posix --no-weak "${OPERATOR_PRECEDENCE_OBJECT}"
    OUTPUT_VARIABLE _op_nm_output
    ERROR_VARIABLE _op_nm_error
    RESULT_VARIABLE _op_nm_rc)

if (NOT _op_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_INVALID_OBJECT "
        "could not read the symbol table of ${OPERATOR_PRECEDENCE_OBJECT} "
        "(nm exit ${_op_nm_rc}: ${_op_nm_error}). Refusing to link the "
        "production compiler without a verified PolyC operator-precedence "
        "authority.")
endif()

# ---------------------------------------------------------------------------
# Classify every record whose name is EXACTLY the target spelling.
#
# A record is "<name> <type> <value> <size>". The type letter is the
# second whitespace-separated field. Records are matched on the EXACT
# name, so a suffix extension or a substring can never be confused with
# the target symbol.
# ---------------------------------------------------------------------------
set(_op_defined_count 0)
set(_op_undefined_count 0)
set(_op_local_count 0)
set(_op_other_count 0)
set(_op_matched_names "")

string(REPLACE "\n" ";" _op_lines "${_op_nm_output}")

foreach (_op_line IN LISTS _op_lines)
    if (_op_line STREQUAL "")
        continue()
    endif()

    # Split the record into its fields.
    string(REPLACE "\t" " " _op_line "${_op_line}")
    separate_arguments(_op_fields UNIX_COMMAND "${_op_line}")

    list(LENGTH _op_fields _op_field_count)
    if (_op_field_count LESS 2)
        continue()
    endif()

    list(GET _op_fields 0 _op_name)
    list(GET _op_fields 1 _op_type)

    # EXACT name match. A near-match is not a match.
    if (NOT _op_name STREQUAL "${_op_target_symbol}")
        continue()
    endif()

    list(APPEND _op_matched_names "${_op_name}")

    if (_op_type STREQUAL "T")
        math(EXPR _op_defined_count "${_op_defined_count} + 1")
    elseif (_op_type STREQUAL "U")
        math(EXPR _op_undefined_count "${_op_undefined_count} + 1")
    elseif (_op_type MATCHES "^[a-z]")
        # A lowercase type letter is a LOCAL symbol.
        math(EXPR _op_local_count "${_op_local_count} + 1")
    else()
        math(EXPR _op_other_count "${_op_other_count} + 1")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# The acceptance predicate.
# ---------------------------------------------------------------------------
if (_op_defined_count EQUAL 0)
    if (_op_undefined_count GREATER 0)
        set(_op_reason "REJECT_UNDEFINED_SYMBOL")
        set(_op_detail "the symbol ${_op_target_symbol} is present only as an UNDEFINED reference (type U); the object carries no implementation of it")
    elseif (_op_local_count GREATER 0)
        set(_op_reason "REJECT_LOCAL_SYMBOL")
        set(_op_detail "the symbol ${_op_target_symbol} is present only as a LOCAL symbol (lowercase type); it is not externally visible")
    elseif (_op_other_count GREATER 0)
        set(_op_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_op_detail "the symbol ${_op_target_symbol} is present but is not a strong global text definition")
    else()
        set(_op_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_op_detail "the symbol ${_op_target_symbol} was not found in the object; the object does not carry the required production entry point")
    endif()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "${_op_reason} ${_op_detail}. "
        "Refusing to link the production compiler without a verified PolyC "
        "operator-precedence authority.")
endif()

if (_op_defined_count GREATER 1)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "REJECT_DUPLICATE_DEFINITION the symbol ${_op_target_symbol} has "
        "${_op_defined_count} definitions in ${OPERATOR_PRECEDENCE_OBJECT}; "
        "exactly one is required. "
        "Refusing to link the production compiler without a verified PolyC "
        "operator-precedence authority.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
    "OPERATOR_PRECEDENCE_OBJECT_STATUS=PASS "
    "EXPECTED_SYMBOL=${OPERATOR_PRECEDENCE_EXPECTED_SYMBOL} "
    "TARGET_OBJECT_FORMAT=${OPERATOR_PRECEDENCE_TARGET_OBJECT_FORMAT} "
    "TARGET_SYMBOL=${_op_target_symbol} "
    "DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=${_op_defined_count} "
    "OBJECT_SIZE=${_op_size}")
