# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 C2 IMPL
#
# Fail-closed verification of the control-flow-token subject.
#
# The object is the SOLE source of the production parser's
# control-flow-token authority. If it were missing, empty, or missing the
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
#         prefix regex, so "_BootstrapValidPostControlFlowTokenExtra"
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
#   -DCONTROL_FLOW_TOKEN_OBJECT=<path to the object>          (required)
#   -DCONTROL_FLOW_TOKEN_EXPECTED_SYMBOL=<logical symbol>     (optional,
#                                                                  default
#                                                                  BootstrapValidPostControlFlowToken)
#   -DCONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT=<Mach-O|ELF>    (optional,
#                                                                  default Mach-O)
#   -DCONTROL_FLOW_TOKEN_NM=<path to nm>                      (optional;
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
if (NOT CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL)
    set(CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL "BootstrapValidPostControlFlowToken")
endif()

# ---------------------------------------------------------------------------
# The target object format -> the spelling of the symbol in that format.
# ---------------------------------------------------------------------------
if (NOT CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT)
    set(CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT "Mach-O")
endif()

string(TOUPPER "${CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT}" _cft_format)

if (_cft_format STREQUAL "MACH-O" OR _cft_format STREQUAL "MACHO" OR _cft_format STREQUAL "DARWIN")
    set(_cft_target_symbol "_${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL}")
elseif (_cft_format STREQUAL "ELF")
    set(_cft_target_symbol "${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL}")
else()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_UNSUPPORTED_OBJECT_FORMAT "
        "CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT=${CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT} "
        "is neither Mach-O nor ELF, so the spelling of "
        "${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL} in the target object is "
        "unknown. Refusing to link the production compiler without a "
        "verified PolyC control-flow-token authority.")
endif()

# ---------------------------------------------------------------------------
# The object must exist.
# ---------------------------------------------------------------------------
if (NOT CONTROL_FLOW_TOKEN_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_INVALID_OBJECT "
        "CONTROL_FLOW_TOKEN_OBJECT is not set. Cannot verify the "
        "control-flow-token subject.")
endif()

if (NOT EXISTS "${CONTROL_FLOW_TOKEN_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_INVALID_OBJECT "
        "control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT} was not "
        "produced. Refusing to link the production compiler without a "
        "verified PolyC control-flow-token authority.")
endif()

# ---------------------------------------------------------------------------
# The object must be non-empty.
# ---------------------------------------------------------------------------
file(SIZE "${CONTROL_FLOW_TOKEN_OBJECT}" _cft_size)
if (_cft_size LESS_EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_INVALID_OBJECT "
        "control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified "
        "PolyC control-flow-token authority.")
endif()

# ---------------------------------------------------------------------------
# The nm tool. The caller passes the CONFIGURED TOOLCHAIN's nm, so a
# cross-compile inspects the target object with a tool that understands
# the target format. A missing tool is a hard error, never a pass.
# ---------------------------------------------------------------------------
if (CONTROL_FLOW_TOKEN_NM)
    set(_cft_nm "${CONTROL_FLOW_TOKEN_NM}")
else()
    find_program(_cft_nm NAMES nm llvm-nm)
endif()

if (NOT _cft_nm)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_NM_FAILURE "
        "no 'nm' found. The control-flow-token subject cannot be "
        "verified, so the production compiler is not linked.")
endif()

# ---------------------------------------------------------------------------
# Read the symbol table. --format=posix gives one "<name> <type> ..." record
# per symbol; --no-weak removes weak and common definitions.
# ---------------------------------------------------------------------------
execute_process(
    COMMAND "${_cft_nm}" --format=posix --no-weak "${CONTROL_FLOW_TOKEN_OBJECT}"
    OUTPUT_VARIABLE _cft_nm_output
    ERROR_VARIABLE _cft_nm_error
    RESULT_VARIABLE _cft_nm_rc)

if (NOT _cft_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_INVALID_OBJECT "
        "could not read the symbol table of ${CONTROL_FLOW_TOKEN_OBJECT} "
        "(nm exit ${_cft_nm_rc}: ${_cft_nm_error}). Refusing to link the "
        "production compiler without a verified PolyC control-flow-token "
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
set(_cft_defined_count 0)
set(_cft_undefined_count 0)
set(_cft_local_count 0)
set(_cft_other_count 0)
set(_cft_matched_names "")

string(REPLACE "\n" ";" _cft_lines "${_cft_nm_output}")

foreach (_cft_line IN LISTS _cft_lines)
    if (_cft_line STREQUAL "")
        continue()
    endif()

    # Split the record into its fields.
    string(REPLACE "\t" " " _cft_line "${_cft_line}")
    separate_arguments(_cft_fields UNIX_COMMAND "${_cft_line}")

    list(LENGTH _cft_fields _cft_field_count)
    if (_cft_field_count LESS 2)
        continue()
    endif()

    list(GET _cft_fields 0 _cft_name)
    list(GET _cft_fields 1 _cft_type)

    # EXACT name match. A near-match is not a match.
    if (NOT _cft_name STREQUAL "${_cft_target_symbol}")
        continue()
    endif()

    list(APPEND _cft_matched_names "${_cft_name}")

    if (_cft_type STREQUAL "T")
        math(EXPR _cft_defined_count "${_cft_defined_count} + 1")
    elseif (_cft_type STREQUAL "U")
        math(EXPR _cft_undefined_count "${_cft_undefined_count} + 1")
    elseif (_cft_type MATCHES "^[a-z]")
        # A lowercase type letter is a LOCAL symbol.
        math(EXPR _cft_local_count "${_cft_local_count} + 1")
    else()
        math(EXPR _cft_other_count "${_cft_other_count} + 1")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# The acceptance predicate.
# ---------------------------------------------------------------------------
if (_cft_defined_count EQUAL 0)
    if (_cft_undefined_count GREATER 0)
        set(_cft_reason "REJECT_UNDEFINED_SYMBOL")
        set(_cft_detail "the symbol ${_cft_target_symbol} is present only as an UNDEFINED reference (type U); the object carries no implementation of it")
    elseif (_cft_local_count GREATER 0)
        set(_cft_reason "REJECT_LOCAL_SYMBOL")
        set(_cft_detail "the symbol ${_cft_target_symbol} is present only as a LOCAL symbol (lowercase type); it is not externally visible")
    elseif (_cft_other_count GREATER 0)
        set(_cft_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_cft_detail "the symbol ${_cft_target_symbol} is present but is not a strong global text definition")
    else()
        set(_cft_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_cft_detail "the symbol ${_cft_target_symbol} was not found in the object; the object does not carry the required production entry point")
    endif()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "${_cft_reason} ${_cft_detail}. "
        "Refusing to link the production compiler without a verified PolyC "
        "control-flow-token authority.")
endif()

if (_cft_defined_count GREATER 1)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "REJECT_DUPLICATE_DEFINITION the symbol ${_cft_target_symbol} has "
        "${_cft_defined_count} definitions in ${CONTROL_FLOW_TOKEN_OBJECT}; "
        "exactly one is required. "
        "Refusing to link the production compiler without a verified PolyC "
        "control-flow-token authority.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
    "CONTROL_FLOW_TOKEN_OBJECT_STATUS=PASS "
    "EXPECTED_SYMBOL=${CONTROL_FLOW_TOKEN_EXPECTED_SYMBOL} "
    "TARGET_OBJECT_FORMAT=${CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT} "
    "TARGET_SYMBOL=${_cft_target_symbol} "
    "DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=${_cft_defined_count} "
    "OBJECT_SIZE=${_cft_size}")
