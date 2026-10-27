# ACT-POLYC-SELFHOST-PARSER-SLICE03 C2 IMPL
#
# Write the CONTENT-ADDRESSED verification stamp for the operator-precedence
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
#   -DOPERATOR_PRECEDENCE_OBJECT=<path to the object>   (required)
#   -DOPERATOR_PRECEDENCE_STAMP=<path to the stamp>     (required)

if (NOT OPERATOR_PRECEDENCE_OBJECT)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "OPERATOR_PRECEDENCE_OBJECT is not set; cannot write the stamp.")
endif()

if (NOT OPERATOR_PRECEDENCE_STAMP)
    message(FATAL_ERROR
        "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
        "OPERATOR_PRECEDENCE_STAMP is not set; cannot write the stamp.")
endif()

file(SHA256 "${OPERATOR_PRECEDENCE_OBJECT}" _op_sha)

# Validate a pre-existing stamp: an EMPTY stamp (the 0-byte file the
# pre-existing tree carried) or one recorded for DIFFERENT content is
# stale and is reported, never trusted.
if (EXISTS "${OPERATOR_PRECEDENCE_STAMP}")
    file(READ "${OPERATOR_PRECEDENCE_STAMP}" _op_stamp_text)
    string(STRIP "${_op_stamp_text}" _op_stamp_text)
    if (_op_stamp_text STREQUAL "")
        message(STATUS
            "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
            "STALE_STAMP_DETECTED the previous stamp "
            "${OPERATOR_PRECEDENCE_STAMP} was empty; it is rewritten with "
            "the SHA of the object that was just verified.")
    else()
        string(REGEX MATCH "OBJECT_SHA256=([0-9a-f]+)" _op_stamp_match "${_op_stamp_text}")
        set(_op_stamp_sha "${CMAKE_MATCH_1}")
        if (NOT _op_stamp_sha STREQUAL "${_op_sha}")
            message(STATUS
                "ACT-POLYC-SELFHOST-PARSER-SLICE03: "
                "STALE_STAMP_DETECTED the previous stamp "
                "${OPERATOR_PRECEDENCE_STAMP} recorded a DIFFERENT object "
                "content; it is rewritten with the SHA of the object that "
                "was just verified.")
        endif()
    endif()
endif()

file(WRITE "${OPERATOR_PRECEDENCE_STAMP}"
    "ACT_POLYC_SELFHOST_PARSER_SLICE02_HARDEN01=VERIFIED\n"
    "OBJECT=${OPERATOR_PRECEDENCE_OBJECT}\n"
    "OBJECT_SHA256=${_op_sha}\n")
