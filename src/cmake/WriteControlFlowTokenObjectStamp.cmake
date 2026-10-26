# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 C2 IMPL
#
# Write the CONTENT-ADDRESSED verification stamp for the control-flow-token
# subject, and VALIDATE any pre-existing stamp against the object.
#
# The stamp is a RECORD of a successful verification, not the thing that
# decides whether a verification happens. The verification itself is a
# custom target whose command ALWAYS runs, so the object content is
# checked on every relevant production build (AC15).
#
# The stamp's CONTENT records the object's SHA. If a stamp left behind by
# a DIFFERENT object content is found, that is reported rather than
# silently trusted: the caller has just verified the CURRENT object, and
# the stamp is about to be overwritten with the current SHA.
#
# Invoked as a CMake script (-P) with:
#   -DCONTROL_FLOW_TOKEN_OBJECT=<path to the object>   (required)
#   -DCONTROL_FLOW_TOKEN_STAMP=<path to the stamp>     (required)

if (NOT CONTROL_FLOW_TOKEN_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "CONTROL_FLOW_TOKEN_OBJECT is not set; cannot write the stamp.")
endif()

if (NOT CONTROL_FLOW_TOKEN_STAMP)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
        "CONTROL_FLOW_TOKEN_STAMP is not set; cannot write the stamp.")
endif()

file(SHA256 "${CONTROL_FLOW_TOKEN_OBJECT}" _cft_sha)

# Validate a pre-existing stamp: an EMPTY stamp (the 0-byte file the
# pre-existing tree carried) or one recorded for DIFFERENT content is
# stale and is reported, never trusted.
if (EXISTS "${CONTROL_FLOW_TOKEN_STAMP}")
    file(READ "${CONTROL_FLOW_TOKEN_STAMP}" _cft_stamp_text)
    string(STRIP "${_cft_stamp_text}" _cft_stamp_text)
    if (_cft_stamp_text STREQUAL "")
        message(STATUS
            "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
            "STALE_STAMP_DETECTED the previous stamp "
            "${CONTROL_FLOW_TOKEN_STAMP} was empty; it is rewritten with "
            "the SHA of the object that was just verified.")
    else()
        string(REGEX MATCH "OBJECT_SHA256=([0-9a-f]+)" _cft_stamp_match "${_cft_stamp_text}")
        set(_cft_stamp_sha "${CMAKE_MATCH_1}")
        if (NOT _cft_stamp_sha STREQUAL "${_cft_sha}")
            message(STATUS
                "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
                "STALE_STAMP_DETECTED the previous stamp "
                "${CONTROL_FLOW_TOKEN_STAMP} recorded a DIFFERENT object "
                "content; it is rewritten with the SHA of the object that "
                "was just verified.")
        endif()
    endif()
endif()

file(WRITE "${CONTROL_FLOW_TOKEN_STAMP}"
    "ACT_POLYC_SELFHOST_PARSER_SLICE02_HARDEN01=VERIFIED\n"
    "OBJECT=${CONTROL_FLOW_TOKEN_OBJECT}\n"
    "OBJECT_SHA256=${_cft_sha}\n")
