# ACT-POLYC-SELFHOST-PARSER-SLICE04 C2 IMPL
#
# Fail-closed verification of the AST token-map subject.
#
# The object is the SOLE source of the production compiler's
# binary-operator classification authority.  If it were missing, empty, or
# missing the exported symbol, the production compiler would silently
# fall back to the legacy C implementation.  This script makes that
# outcome impossible: it either confirms the object is a real object
# carrying exactly one strong global text definition of the expected
# symbol, or it aborts the build with a concrete reason token.
#
# WHAT THIS FILE DOES DIFFERENTLY FROM THE SLICE03 EQUIVALENT
# ============================================================
#
# It is a NEW file (not a modification of the closed SLICE03 one), which
# is exactly why ACT section 3.1 authorizes
# src/cmake/VerifyAstTokenMapObject.cmake explicitly: SLICE03's build
# verifier was out of scope for SLICE03, and the same mistake must not
# be repeated here.
#
# The verification logic itself is the SLICE03 discipline, unchanged:
#
#   D1-A  The expected symbol SPELLING is resolved from the TARGET
#         OBJECT FORMAT, which is passed in explicitly, so a perfectly
#         valid ELF object is not rejected on a Mach-O host and vice
#         versa.
#
#   D1-B  A record of type "U" (undefined reference) is REJECTED.
#
#   D1-C  The name must match EXACTLY.
#
#   D1-D  A lowercase type (local symbol) is REJECTED.  A weak or
#         common definition is REJECTED.  More than one matching
#         definition is REJECTED.
#
#   D2    The script is invoked from BOTH producer mode and
#         prebuilt-object mode, so the same strict gate applies to
#         every path that can link the production compiler.
#
# HOW THE SYMBOL TABLE IS READ
#
#   nm --format=posix --no-weak <object>
#
# Both Apple nm and GNU nm implement these two flags with the SAME
# meaning.  The type letters are the same on both platforms:
#
#   T  global strong text (code)      <- the ONLY acceptable kind
#   U  undefined reference             <- rejected
#   t  local text                      <- rejected
#   W  weak text                       <- filtered out by --no-weak
#   C  common                          <- filtered out by --no-weak
#
# WHY --no-weak IS LOAD-BEARING: on ELF, GNU nm reports a weak
# definition as "W", so the type letter alone would reject it.  On
# Mach-O the default nm reports a weak definition as "T" -- the SAME
# letter as a strong definition -- so the type letter alone CANNOT
# reject it there.  A weak definition is also LINKABLE: it satisfies a
# production reference at link time, so accepting it would admit an
# object with no strong production authority.  Filtering it out removes
# the ambiguity on both platforms.
#
# Invoked as a CMake script (-P) with:
#   -DAST_TOKEN_MAP_OBJECT=<path to the object>                  (required)
#   -DAST_TOKEN_MAP_EXPECTED_SYMBOL=<logical symbol>            (optional,
#                                                                  default
#                                                                  BootstrapAstBinOpFromToken)
#   -DAST_TOKEN_MAP_TARGET_OBJECT_FORMAT=<Mach-O|ELF>           (optional,
#                                                                  default
#                                                                  Mach-O)
#   -DAST_TOKEN_MAP_NM=<path to nm>                              (optional;
#                                                                  defaults to
#                                                                  the toolchain
#                                                                  nm passed by
#                                                                  the caller)

# ---------------------------------------------------------------------------
# The canonical LOGICAL symbol. Its object-format spelling is derived below.
# ---------------------------------------------------------------------------
if (NOT AST_TOKEN_MAP_EXPECTED_SYMBOL)
    set(AST_TOKEN_MAP_EXPECTED_SYMBOL "BootstrapAstBinOpFromToken")
endif()

# ---------------------------------------------------------------------------
# The target object format -> the spelling of the symbol in that format.
# ---------------------------------------------------------------------------
if (NOT AST_TOKEN_MAP_TARGET_OBJECT_FORMAT)
    set(AST_TOKEN_MAP_TARGET_OBJECT_FORMAT "Mach-O")
endif()

string(TOUPPER "${AST_TOKEN_MAP_TARGET_OBJECT_FORMAT}" _am_format)

if (_am_format STREQUAL "MACH-O" OR _am_format STREQUAL "MACHO" OR _am_format STREQUAL "DARWIN")
    set(_am_target_symbol "_${AST_TOKEN_MAP_EXPECTED_SYMBOL}")
elseif (_am_format STREQUAL "ELF")
    set(_am_target_symbol "${AST_TOKEN_MAP_EXPECTED_SYMBOL}")
else()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_UNSUPPORTED_OBJECT_FORMAT "
        "AST_TOKEN_MAP_TARGET_OBJECT_FORMAT=${AST_TOKEN_MAP_TARGET_OBJECT_FORMAT} "
        "is neither Mach-O nor ELF, so the spelling of "
        "${AST_TOKEN_MAP_EXPECTED_SYMBOL} in the target object is "
        "unknown. Refusing to link the production compiler without a "
        "verified PolyC AST-operator authority.")
endif()

# ---------------------------------------------------------------------------
# The object must exist.
# ---------------------------------------------------------------------------
if (NOT AST_TOKEN_MAP_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_INVALID_OBJECT "
        "AST_TOKEN_MAP_OBJECT is not set. Cannot verify the "
        "AST-operator subject.")
endif()

if (NOT EXISTS "${AST_TOKEN_MAP_OBJECT}")
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_INVALID_OBJECT "
        "AST-operator subject ${AST_TOKEN_MAP_OBJECT} was not "
        "produced. Refusing to link the production compiler without a "
        "verified PolyC AST-operator authority.")
endif()

# ---------------------------------------------------------------------------
# The object must be non-empty.
# ---------------------------------------------------------------------------
file(SIZE "${AST_TOKEN_MAP_OBJECT}" _am_size)
if (_am_size LESS_EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_INVALID_OBJECT "
        "AST-operator subject ${AST_TOKEN_MAP_OBJECT} is empty. "
        "Refusing to link the production compiler without a verified "
        "PolyC AST-operator authority.")
endif()

# ---------------------------------------------------------------------------
# The nm tool.  The caller passes the CONFIGURED TOOLCHAIN's nm, so a
# cross-compile inspects the target object with a tool that understands
# the target format.  A missing tool is a hard error, never a pass.
# ---------------------------------------------------------------------------
if (AST_TOKEN_MAP_NM)
    set(_am_nm "${AST_TOKEN_MAP_NM}")
else()
    find_program(_am_nm NAMES nm llvm-nm)
endif()

if (NOT _am_nm)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_NM_FAILURE "
        "no 'nm' found. The AST-operator subject cannot be "
        "verified, so the production compiler is not linked.")
endif()

# ---------------------------------------------------------------------------
# Read the symbol table.
# ---------------------------------------------------------------------------
execute_process(
    COMMAND "${_am_nm}" --format=posix --no-weak "${AST_TOKEN_MAP_OBJECT}"
    OUTPUT_VARIABLE _am_nm_output
    ERROR_VARIABLE _am_nm_error
    RESULT_VARIABLE _am_nm_rc)

if (NOT _am_nm_rc EQUAL 0)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_INVALID_OBJECT "
        "could not read the symbol table of ${AST_TOKEN_MAP_OBJECT} "
        "(nm exit ${_am_nm_rc}: ${_am_nm_error}). Refusing to link the "
        "production compiler without a verified PolyC AST-operator "
        "authority.")
endif()

# ---------------------------------------------------------------------------
# Classify every record whose name is EXACTLY the target spelling.
# ---------------------------------------------------------------------------
set(_am_defined_count 0)
set(_am_undefined_count 0)
set(_am_local_count 0)
set(_am_other_count 0)
set(_am_matched_names "")

string(REPLACE "\n" ";" _am_lines "${_am_nm_output}")

foreach (_am_line IN LISTS _am_lines)
    if (_am_line STREQUAL "")
        continue()
    endif()

    string(REPLACE "\t" " " _am_line "${_am_line}")
    separate_arguments(_am_fields UNIX_COMMAND "${_am_line}")

    list(LENGTH _am_fields _am_field_count)
    if (_am_field_count LESS 2)
        continue()
    endif()

    list(GET _am_fields 0 _am_name)
    list(GET _am_fields 1 _am_type)

    # EXACT name match.  A near-match is not a match.
    if (NOT _am_name STREQUAL "${_am_target_symbol}")
        continue()
    endif()

    list(APPEND _am_matched_names "${_am_name}")

    if (_am_type STREQUAL "T")
        math(EXPR _am_defined_count "${_am_defined_count} + 1")
    elseif (_am_type STREQUAL "U")
        math(EXPR _am_undefined_count "${_am_undefined_count} + 1")
    elseif (_am_type MATCHES "^[a-z]")
        # A lowercase type letter is a LOCAL symbol.
        math(EXPR _am_local_count "${_am_local_count} + 1")
    else()
        math(EXPR _am_other_count "${_am_other_count} + 1")
    endif()
endforeach()

# ---------------------------------------------------------------------------
# The acceptance predicate.
# ---------------------------------------------------------------------------
if (_am_defined_count EQUAL 0)
    if (_am_undefined_count GREATER 0)
        set(_am_reason "REJECT_UNDEFINED_SYMBOL")
        set(_am_detail "the symbol ${_am_target_symbol} is present only as an UNDEFINED reference (type U); the object carries no implementation of it")
    elseif (_am_local_count GREATER 0)
        set(_am_reason "REJECT_LOCAL_SYMBOL")
        set(_am_detail "the symbol ${_am_target_symbol} is present only as a LOCAL symbol (lowercase type); it is not externally visible")
    elseif (_am_other_count GREATER 0)
        set(_am_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_am_detail "the symbol ${_am_target_symbol} is present but is not a strong global text definition")
    else()
        set(_am_reason "REJECT_SYMBOL_NAME_MISMATCH")
        set(_am_detail "the symbol ${_am_target_symbol} was not found in the object; the object does not carry the required production entry point")
    endif()
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "${_am_reason} ${_am_detail}. "
        "Refusing to link the production compiler without a verified PolyC "
        "AST-operator authority.")
endif()

if (_am_defined_count GREATER 1)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "REJECT_DUPLICATE_DEFINITION the symbol ${_am_target_symbol} has "
        "${_am_defined_count} definitions in ${AST_TOKEN_MAP_OBJECT}; "
        "exactly one is required. "
        "Refusing to link the production compiler without a verified PolyC "
        "AST-operator authority.")
endif()

message(STATUS
    "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
    "AST_TOKEN_MAP_OBJECT_STATUS=PASS "
    "EXPECTED_SYMBOL=${AST_TOKEN_MAP_EXPECTED_SYMBOL} "
    "TARGET_OBJECT_FORMAT=${AST_TOKEN_MAP_TARGET_OBJECT_FORMAT} "
    "TARGET_SYMBOL=${_am_target_symbol} "
    "DEFINED_GLOBAL_TEXT_SYMBOL_COUNT=${_am_defined_count} "
    "OBJECT_SIZE=${_am_size}")
