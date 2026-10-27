# ACT-POLYC-SELFHOST-PARSER-SLICE04 C2 IMPL
#
# Write the CONTENT-ADDRESSED verification stamp for the AST token-map
# subject, and VALIDATE any pre-existing stamp against the object.
#
# The stamp is a RECORD of a successful verification, not the thing that
# decides whether a verification happens.  The verification itself is a
# custom target whose command ALWAYS runs, so the object content is
# checked on every relevant production build (ACT section 8.3: "No stale
# verification stamp may bypass the current object check").
#
# The stamp's CONTENT records the object's SHA.  If a stamp left behind
# by a DIFFERENT object content is found, that is reported rather than
# silently trusted: the caller has just verified the CURRENT object, and
# the stamp is about to be overwritten with the current SHA.
#
# Invoked as a CMake script (-P) with:
#   -DAST_TOKEN_MAP_OBJECT=<path to the object>   (required)
#   -DAST_TOKEN_MAP_STAMP=<path to the stamp>     (required)

if (NOT AST_TOKEN_MAP_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "AST_TOKEN_MAP_OBJECT is not set; cannot write the stamp.")
endif()

if (NOT AST_TOKEN_MAP_STAMP)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
        "AST_TOKEN_MAP_STAMP is not set; cannot write the stamp.")
endif()

file(SHA256 "${AST_TOKEN_MAP_OBJECT}" _am_sha)

# Validate a pre-existing stamp: an EMPTY stamp or one recorded for
# DIFFERENT content is stale and is reported, never trusted.
if (EXISTS "${AST_TOKEN_MAP_STAMP}")
    file(READ "${AST_TOKEN_MAP_STAMP}" _am_stamp_text)
    string(STRIP "${_am_stamp_text}" _am_stamp_text)
    if (_am_stamp_text STREQUAL "")
        message(STATUS
            "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
            "STALE_STAMP_DETECTED the previous stamp "
            "${AST_TOKEN_MAP_STAMP} was empty; it is rewritten with "
            "the SHA of the object that was just verified.")
    else()
        string(REGEX MATCH "OBJECT_SHA256=([0-9a-f]+)" _am_stamp_match "${_am_stamp_text}")
        set(_am_stamp_sha "${CMAKE_MATCH_1}")
        if (NOT _am_stamp_sha STREQUAL "${_am_sha}")
            message(STATUS
                "ACT-POLYC-SELFHOST-PARSER-SLICE04: "
                "STALE_STAMP_DETECTED the previous stamp "
                "${AST_TOKEN_MAP_STAMP} recorded a DIFFERENT object "
                "content; it is rewritten with the SHA of the object that "
                "was just verified.")
        endif()
    endif()
endif()

file(WRITE "${AST_TOKEN_MAP_STAMP}"
    "ACT_POLYC_SELFHOST_PARSER_SLICE04=VERIFIED\n"
    "OBJECT=${AST_TOKEN_MAP_OBJECT}\n"
    "OBJECT_SHA256=${_am_sha}\n")
