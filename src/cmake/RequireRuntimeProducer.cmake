# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL
#
# Provenance-strict runtime producer verification, factored out of
# src/CMakeLists.txt so that the SAME check can be invoked from both
# consumers of the runtime producer:
#
#   * the `unit-test` custom target
#   * the libtos install seam
#
# This file is included in two modes:
#
#   1. As a SCRIPT (-P): the required values arrive as -D cache
#      arguments. hcc_require_runtime_producer() is then called
#      explicitly by the caller.
#
#   2. As an INCLUDE from an install(CODE ...) block: the values are
#      already set in the enclosing scope.
#
# The check is fail-closed. It NEVER falls back to stage0, to the host
# compiler, to ${CMAKE_INSTALL_PREFIX}/bin/hcc, or to any other
# producer. A missing or unqualified producer aborts the operation.

function(hcc_require_runtime_producer)
    if (NOT HCC_BOOTSTRAP)
        message(FATAL_ERROR
            "libtos install seam: no runtime producer configured "
            "(HCC_BOOTSTRAP is empty). Refusing to install a runtime "
            "archive produced by an unknown producer.")
    endif()

    if (NOT EXISTS "${HCC_BOOTSTRAP}")
        message(FATAL_ERROR
            "libtos install seam: build/hcc-bootstrap04 not found at "
            "${HCC_BOOTSTRAP}. The current ./hcc at HEAD regressed on "
            "ARM64 inline-asm mnemonics and cannot produce a complete "
            "all.o. Build the bootstrap chain first via "
            "'make bootstrap04-component-build', then re-run cmake.")
    endif()

    if (HCC_BOOTSTRAP_EXPECTED_SHA)
        file(SHA256 "${HCC_BOOTSTRAP}" _hcc_bootstrap_actual_sha)
        if (NOT _hcc_bootstrap_actual_sha STREQUAL "${HCC_BOOTSTRAP_EXPECTED_SHA}")
            message(FATAL_ERROR
                "libtos install seam: runtime producer provenance check failed. "
                "${HCC_BOOTSTRAP} sha256=${_hcc_bootstrap_actual_sha} but the "
                "pinned expected identity is ${HCC_BOOTSTRAP_EXPECTED_SHA}. "
                "Refusing to install a runtime archive produced by an "
                "unqualified producer.")
        endif()
        message(STATUS
            "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: runtime producer "
            "provenance VERIFIED sha256=${_hcc_bootstrap_actual_sha}")
    endif()
endfunction()
