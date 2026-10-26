cmake_minimum_required(VERSION 3.10)

project(HolyC)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_C_STANDARD_REQUIRED True)
set(CMAKE_C_STANDARD 11)

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The runtime output directory is now OVERRIDABLE.
#
# The historical behaviour was an unconditional
#     set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ../)
# which sent EVERY runtime artifact (hcc, hcc-bootstrap02/03/04) to the
# repository root. That made an isolated stage0 build impossible: the
# stage0 compiler would overwrite the production ./hcc.
#
# The default is UNCHANGED (../), so every existing consumer -- including
# the release workflow, which copies ./hcc -- keeps working exactly as
# before. A build that wants an isolated output directory now sets
# HCC_RUNTIME_OUTPUT_DIRECTORY instead of fighting the normal variable.
#
# NOTE: a plain -DHCC_RUNTIME_OUTPUT_DIRECTORY=... on the command line
# would be a CACHE variable, and the unconditional `set(...)` below is a
# NORMAL variable, so the normal variable would win. We therefore read
# the cache value explicitly below. This is the failure mode the C1
# design warned about.
if (DEFINED HCC_RUNTIME_OUTPUT_DIRECTORY AND NOT "${HCC_RUNTIME_OUTPUT_DIRECTORY}" STREQUAL "")
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${HCC_RUNTIME_OUTPUT_DIRECTORY}")
else()
    set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ../)
endif()

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build (Debug or Release)" FORCE)
endif()

add_definitions(-DINSTALL_PREFIX="${CMAKE_INSTALL_PREFIX}")

# Add debugging symbols for Debug builds
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_definitions(DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fsanitize=address")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()

if (HCC_LINK_SQLITE3)
    add_compile_definitions(HCC_LINK_SQLITE3)
endif()

execute_process(
  COMMAND git rev-parse HEAD
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE HCC_GIT_HASH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

add_compile_definitions(HCC_GIT_HASH="${HCC_GIT_HASH}")

# Optionally, add more flags or options depending on the build type
# For example, optimization flags for Release builds:
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2")

set(SOURCES
    asm.c
    aostr.c
    arena.c
    ast.c
    cctrl.c
    cfg-print.c
    cfg.c
    cli.c
    containers.c
    compile.c
    aarch64.c
    ir.c
    ir-debug.c
    ir-eval.c
    ir-optimise.c
    ir-regalloc.c
    ir-types.c
    json.c
    lexer.c
    list.c
    lsp.c
    main.c
    memory.c
    mempool.c
    parser.c
    prsasm.c
    prslib.c
    prsutil.c
    transpiler.c
    x86.c
    x86_64.c
)

set(HEADERS
    aostr.h
    arena.h
    asm.h
    ast.h
    cctrl.h
    cfg-print.h
    cfg.h
    cli.h
    compile.h
    config.h
    json.h
    lsp.h
    containers.h
    ir.h
    ir-debug.h
    ir-eval.h
    ir-regalloc.h
    ir-types.h
    lexer.h
    list.h
    memory.h
    mempool.h
    parser.h
    prsasm.h
    prslib.h
    prsutil.h
    util.h
    transpiler.h
    version.h
    x86.h
    x86_64.h
)

add_subdirectory(asm)

option(HCC_ENABLE_JIT "Build the optional in-process JIT (aarch64 & x86_64)" OFF)
if (HCC_ENABLE_JIT)
    list(APPEND SOURCES jit-common.c aarch64-jit.c x86_64-jit.c repl.c
         memsafe.c linenoise/linenoise.c)
    list(APPEND HEADERS jit-common.h aarch64-jit.h x86_64-jit.h repl.h
         memsafe.h linenoise/linenoise.h)
    # Vendored (antirez/linenoise) - don't hold it to our warning bar.
    set_source_files_properties(linenoise/linenoise.c
                                PROPERTIES COMPILE_FLAGS "-w")
endif()

# ACT-POLYC-LLVM-SPIKE01-RESUME01: experimental LLVM 22 C-API consumer.
# Opt-in for the spike. Defaults OFF so existing native gates pass
# without requiring LLVM on the build host. When ON, hcc links
# against the LLVM 22 C API and --emit-llvm becomes available.
#
# The discovery is mechanical: find llvm-config, derive include
# flags / libraries / link flags. We require major version 22 - any
# other version is rejected up front so the spike cannot accidentally
# be built against an older LLVM (whose C API surface differs).
option(HCC_ENABLE_LLVM "Build the LLVM 22 C-API backend spike (ACT-POLYC-LLVM-SPIKE01-RESUME01)" OFF)
if (HCC_ENABLE_LLVM)
    find_program(LLVM_CONFIG_EXECUTABLE NAMES llvm-config
                 DOC "llvm-config executable (LLVM 22.x required)")
    if (NOT LLVM_CONFIG_EXECUTABLE)
        message(FATAL_ERROR
            "HCC_ENABLE_LLVM=ON but llvm-config is not on PATH. "
            "Install LLVM 22.x (e.g. nixpkgs#llvmPackages_22.llvm.dev) "
            "or set HCC_ENABLE_LLVM=OFF.")
    endif()
    execute_process(
        COMMAND ${LLVM_CONFIG_EXECUTABLE} --version
        OUTPUT_VARIABLE LLVM_CONFIG_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    string(REGEX MATCH "^([0-9]+)\\.([0-9]+)\\.([0-9]+)"
           _ "${LLVM_CONFIG_VERSION}")
    set(LLVM_VERSION_MAJOR "${CMAKE_MATCH_1}")
    if (NOT LLVM_VERSION_MAJOR EQUAL 22)
        message(FATAL_ERROR
            "HCC_ENABLE_LLVM=ON but llvm-config reports version "
            "${LLVM_CONFIG_VERSION}. ACT-POLYC-LLVM-SPIKE01-RESUME01 "
            "requires LLVM 22.x exactly.")
    endif()
    execute_process(
        COMMAND ${LLVM_CONFIG_EXECUTABLE} --cflags
        OUTPUT_VARIABLE LLVM_CFLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
        COMMAND ${LLVM_CONFIG_EXECUTABLE} --libs core
        OUTPUT_VARIABLE LLVM_LIBS_CORE
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
        COMMAND ${LLVM_CONFIG_EXECUTABLE} --ldflags
        OUTPUT_VARIABLE LLVM_LDFLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE)
    separate_arguments(LLVM_CFLAGS UNIX_COMMAND "${LLVM_CFLAGS}")
    separate_arguments(LLVM_LIBS_CORE UNIX_COMMAND "${LLVM_LIBS_CORE}")
    separate_arguments(LLVM_LDFLAGS UNIX_COMMAND "${LLVM_LDFLAGS}")
    message(STATUS "LLVM 22 C-API: ${LLVM_CONFIG_EXECUTABLE} (${LLVM_CONFIG_VERSION})")
    list(APPEND SOURCES llvm-backend.c)
    list(APPEND SOURCES llvm-backend-cap.c)
    list(APPEND HEADERS llvm-backend.h)
    list(APPEND HEADERS llvm-backend-cap.h)
endif()

add_executable(hcc ${SOURCES} ${HEADERS})

# ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01 C2 IMPL:
# Link the qualified PolyC BootstrapCalcPadding component into the
# production hcc binary so the parser delegates padding calculation
# to the PolyC implementation. The dedicated selector
# `HCC_USE_SELFHOST_PARSER_PADDING` is defined here so the production
# parser-padding delegation is INDEPENDENT of the generic lexer
# `HCC_USE_SELFHOST_COMPONENTS` flag (which would also require linking
# the lexer subjects).
#
# Why opt-in (not unconditional):
#   - keeps the production build hermetic: the parser-padding
#     component object (build/parser-padding-subject.o) must exist
#     before hcc is linked;
#   - mirrors the existing lexer opt-in pattern (HCC_ENABLE_BOOTSTRAP02_STAGE1)
#     so the standard `make all` flow remains explicit about which
#     self-hosted components are present.
#
# To build the production hcc with PolyC parser-padding delegation:
#
#   make parser-padding-component                  # builds build/parser-padding-subject.o
#   cmake -S ./src -B ./build \
#         -DHCC_USE_SELFHOST_PARSER_PADDING=ON \
#         -DPARSER_PADDING_OBJECT=<abs>/build/parser-padding-subject.o \
#         ...
#   make -C ./build hcc
#
# Default: ON (the production hcc exercises the PolyC authority by
# default; this is the whole point of the delegation ACT).
option(HCC_USE_SELFHOST_PARSER_PADDING
       "Link the parser-padding PolyC component into hcc and enable parser-padding delegation. ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01."
       ON)

if (HCC_USE_SELFHOST_PARSER_PADDING)
    if (NOT PARSER_PADDING_OBJECT)
        set(PARSER_PADDING_OBJECT "${CMAKE_SOURCE_DIR}/../build/parser-padding-subject.o")
    endif()
    # ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
    # The padding object is now a DECLARED build artifact of the hcc
    # target, not an accidental warm-tree assumption.
    #
    # The previous contract was a configure-time `if(NOT EXISTS)` probe.
    # That check could only ever observe an object a human had produced
    # by hand, because nothing in the build graph ever SCHEDULED the
    # object's production. On a clean checkout the configure therefore
    # aborted before the compiler could ever be built -- the cycle the
    # ACT was opened to remove.
    #
    # The repair keeps the fail-closed property and moves the failure
    # from "the object does not exist yet" to "the object could not be
    # produced". The two cases are distinguished by an explicit
    # PARSER_PADDING_PRODUCER variable:
    #
    #   * PARSER_PADDING_PRODUCER set -> CMake schedules production of
    #     the object itself via add_custom_command(OUTPUT ... DEPENDS ...),
    #     so `make -C build hcc` builds it from the current source tree.
    #     A missing producer is a hard configure error, never a silent
    #     fallback to the legacy C implementation.
    #
    #   * PARSER_PADDING_PRODUCER unset -> the object must already
    #     exist (the historical contract). A missing object is a hard
    #     configure error naming the exact command to run.
    #
    # In BOTH cases the object is REQUIRED. There is no path on which
    # the production compiler silently links the legacy CalcPadding.
    if (PARSER_PADDING_PRODUCER)
        # The producer is the stage0 compiler that will compile the
        # PolyC padding subject. It must exist before we can schedule.
        if (NOT EXISTS "${PARSER_PADDING_PRODUCER}")
            message(FATAL_ERROR
                "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
                "PARSER_PADDING_PRODUCER=${PARSER_PADDING_PRODUCER} does not exist. "
                "The parser-padding object cannot be produced without it. "
                "Run 'make bootstrap-stage0' first.")
        endif()
        if (NOT EXISTS "${PARSER_PADDING_SOURCE}")
            message(FATAL_ERROR
                "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: "
                "PARSER_PADDING_SOURCE=${PARSER_PADDING_SOURCE} does not exist. "
                "The parser-padding object cannot be produced from a missing subject.")
        endif()
        get_filename_component(_pp_source_dir "${PARSER_PADDING_SOURCE}" DIRECTORY)
        get_filename_component(_pp_source_name "${PARSER_PADDING_SOURCE}" NAME)
        get_filename_component(_pp_object_dir "${PARSER_PADDING_OBJECT}" DIRECTORY)
        # The bootstrap prefix holds the canonical headers the stage0
        # compiler resolves against. It is header-only: no runtime
        # archive is required to compile the padding subject.
        add_custom_command(
            OUTPUT "${PARSER_PADDING_OBJECT}"
            COMMAND "${CMAKE_COMMAND}" -E make_directory "${_pp_object_dir}"
            COMMAND "${PARSER_PADDING_PRODUCER}"
                    --install-dir=${PARSER_PADDING_PREFIX}
                    -c "${PARSER_PADDING_SOURCE}"
                    -o "${PARSER_PADDING_OBJECT}"
            DEPENDS "${PARSER_PADDING_SOURCE}" "${PARSER_PADDING_PRODUCER}"
            WORKING_DIRECTORY "${_pp_source_dir}"
            COMMENT "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: producing parser-padding subject ${PARSER_PADDING_OBJECT}"
            VERBATIM)
        # Fail closed if the producer could not write the object: a
        # successful exit from the producer with a missing output, an
        # empty output, or an output without the exported symbol is a
        # hard error, never a silent legacy fallback.
        add_custom_command(
            OUTPUT "${PARSER_PADDING_OBJECT}.verified"
            COMMAND "${CMAKE_COMMAND}"
                    -DPARSER_PADDING_OBJECT=${PARSER_PADDING_OBJECT}
                    -P "${CMAKE_SOURCE_DIR}/cmake/VerifyParserPaddingObject.cmake"
            COMMAND "${CMAKE_COMMAND}" -E touch "${PARSER_PADDING_OBJECT}.verified"
            DEPENDS "${PARSER_PADDING_OBJECT}"
            COMMENT "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: verifying parser-padding subject"
            VERBATIM)
        add_custom_target(hcc-parser-padding-subject
            DEPENDS "${PARSER_PADDING_OBJECT}.verified")
        add_dependencies(hcc hcc-parser-padding-subject)
        message(STATUS "ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01: production hcc SCHEDULES parser-padding subject production: ${PARSER_PADDING_OBJECT}")
    elseif (NOT EXISTS "${PARSER_PADDING_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01: required self-host "
            "parser-padding component missing at ${PARSER_PADDING_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc --install-dir=<prefix> -c tools/bootstrap/selfhost-parser-padding.HC -o ${PARSER_PADDING_OBJECT}. "
            "Or configure with -DPARSER_PADDING_PRODUCER=<stage0 hcc> to have the "
            "build graph produce it.")
    endif()
    target_compile_definitions(hcc PRIVATE HCC_USE_SELFHOST_PARSER_PADDING)
    target_link_libraries(hcc ${PARSER_PADDING_OBJECT})
    message(STATUS "ACT-POLYC-SELFHOST-PARSER-PADDING-DELEGATE01: production hcc links parser-padding PolyC component: ${PARSER_PADDING_OBJECT}")
endif()

# ACT-POLYC-SELFHOST-PARSER-SLICE02 C2 IMPL:
# Link the qualified PolyC BootstrapValidPostControlFlowToken component
# into the production hcc binary and enable the control-flow-token
# delegation. The dedicated selector
# `HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN` is defined here so the
# production control-flow-token delegation is INDEPENDENT of the parser-
# padding selector and of the generic lexer
# `HCC_USE_SELFHOST_COMPONENTS` flag (which would also require linking
# the lexer subjects).
#
# The same fail-closed discipline as the parser-padding component
# applies: if the producer is configured, the build graph SCHEDULES the
# component's production and verifies the exported symbol; if it is not,
# a missing component is a hard configure error, never a silent legacy
# fallback.
option(HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN
       "Link the control-flow-token PolyC component into hcc and enable control-flow-token delegation. ACT-POLYC-SELFHOST-PARSER-SLICE02."
       ON)

if (HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN)
    if (NOT CONTROL_FLOW_TOKEN_OBJECT)
        set(CONTROL_FLOW_TOKEN_OBJECT "${CMAKE_SOURCE_DIR}/../build/parser-control-flow-token-subject.o")
    endif()

    # ---------------------------------------------------------------------
    # ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01 C2 IMPL (D1-A, D2):
    #
    # The TARGET OBJECT FORMAT and the TOOLCHAIN nm are resolved here and
    # passed EXPLICITLY to the verifier.
    #
    # The format must NOT be guessed from the host: during a cross-compile
    # the host's format is not the target's format. The SLICE02 verifier
    # hard-coded the Mach-O spelling "_X", so a valid ELF object -- which
    # spells the same C symbol "X" -- was rejected on Linux purely
    # because of its platform. That was reproduced natively on
    # Linux/ELF/x86_64 (see the ACT evidence).
    #
    # CMAKE_NM is the CONFIGURED TOOLCHAIN's nm, so the target object is
    # inspected by a tool that understands the target format. If it is not
    # available the build fails loudly instead of silently substituting a
    # host nm.
    # ---------------------------------------------------------------------
    if (NOT CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT)
        if (APPLE)
            set(CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT "Mach-O")
        elseif (UNIX AND NOT APPLE)
            set(CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT "ELF")
        else()
            message(FATAL_ERROR
                "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
                "cannot determine the target object format for this platform. "
                "Configure with -DCONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT=<Mach-O|ELF> "
                "so the control-flow-token symbol spelling can be resolved "
                "for the target rather than guessed from the host.")
        endif()
    endif()

    if (NOT CONTROL_FLOW_TOKEN_NM)
        set(CONTROL_FLOW_TOKEN_NM "${CMAKE_NM}")
    endif()
    if (NOT CONTROL_FLOW_TOKEN_NM)
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: "
            "REJECT_NM_FAILURE the configured toolchain provides no nm "
            "(CMAKE_NM is empty), so the control-flow-token subject cannot "
            "be verified. Configure with -DCONTROL_FLOW_TOKEN_NM=<path to nm> "
            "to inspect the target object with a tool that understands the "
            "target format. Refusing to link the production compiler.")
    endif()

    # ---------------------------------------------------------------------
    # D2: BOTH producer mode and prebuilt-object mode converge on the
    # SAME strict verifier, and the verification runs BEFORE the link.
    #
    # The old SLICE02 wiring verified only in producer mode and used a
    # ".verified" stamp file whose staleness could turn an altered object
    # into an accepted one. Here the verifier is invoked from a custom
    # command that re-runs whenever the object is newer than the stamp,
    # and the stamp is CONTENT-ADDRESSED: it records the object's SHA, so
    # replacing the object with different content invalidates it even if
    # the timestamp is preserved (AC15).
    # ---------------------------------------------------------------------
    set(_cft_stamp "${CONTROL_FLOW_TOKEN_OBJECT}.verified")

    if (CONTROL_FLOW_TOKEN_PRODUCER)
        if (NOT EXISTS "${CONTROL_FLOW_TOKEN_PRODUCER}")
            message(FATAL_ERROR
                "ACT-POLYC-SELFHOST-PARSER-SLICE02: CONTROL_FLOW_TOKEN_PRODUCER=${CONTROL_FLOW_TOKEN_PRODUCER} does not exist. "
                "The control-flow-token component cannot be produced without it.")
        endif()
        if (NOT EXISTS "${CONTROL_FLOW_TOKEN_SOURCE}")
            message(FATAL_ERROR
                "ACT-POLYC-SELFHOST-PARSER-SLICE02: CONTROL_FLOW_TOKEN_SOURCE=${CONTROL_FLOW_TOKEN_SOURCE} does not exist. "
                "The control-flow-token component cannot be produced from a missing subject.")
        endif()
        get_filename_component(_cft_source_dir "${CONTROL_FLOW_TOKEN_SOURCE}" DIRECTORY)
        get_filename_component(_cft_source_name "${CONTROL_FLOW_TOKEN_SOURCE}" NAME)
        get_filename_component(_cft_object_dir "${CONTROL_FLOW_TOKEN_OBJECT}" DIRECTORY)
        get_filename_component(_cft_object_name "${CONTROL_FLOW_TOKEN_OBJECT}" NAME)
        add_custom_command(
            OUTPUT "${CONTROL_FLOW_TOKEN_OBJECT}"
            COMMAND "${CONTROL_FLOW_TOKEN_PRODUCER}"
                    --install-dir=${CONTROL_FLOW_TOKEN_PREFIX}
                    -c "${CONTROL_FLOW_TOKEN_SOURCE}"
                    -o "${CONTROL_FLOW_TOKEN_OBJECT}"
            DEPENDS "${CONTROL_FLOW_TOKEN_SOURCE}" "${CONTROL_FLOW_TOKEN_PRODUCER}"
            WORKING_DIRECTORY "${_cft_source_dir}"
            COMMENT "ACT-POLYC-SELFHOST-PARSER-SLICE02: producing control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT}"
            VERBATIM)
        message(STATUS "ACT-POLYC-SELFHOST-PARSER-SLICE02: production hcc SCHEDULES control-flow-token subject production: ${CONTROL_FLOW_TOKEN_OBJECT}")
    elseif (NOT EXISTS "${CONTROL_FLOW_TOKEN_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-PARSER-SLICE02: required self-host "
            "control-flow-token component missing at ${CONTROL_FLOW_TOKEN_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc --install-dir=<prefix> -c tools/bootstrap/selfhost-parser-control-flow-token.HC -o ${CONTROL_FLOW_TOKEN_OBJECT}. "
            "Or configure with -DCONTROL_FLOW_TOKEN_PRODUCER=<stage0 hcc> to have the "
            "build graph produce it.")
    else()
        message(STATUS "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: production hcc uses a PREBUILT control-flow-token subject: ${CONTROL_FLOW_TOKEN_OBJECT}")
    endif()

    # ---------------------------------------------------------------------
    # The single strict verification gate, shared by BOTH modes.
    #
    # The verification is a custom TARGET, not an OUTPUT-producing custom
    # command. A custom command with an OUTPUT file is considered
    # up-to-date whenever that file exists and is newer than its
    # dependencies -- which is exactly the stale-stamp hazard. The
    # pre-existing tree demonstrates the hazard concretely: a 0-byte
    # "build/parser-control-flow-token-subject.o.verified" left by an
    # earlier build made CMake report "Built target
    # hcc-control-flow-token-subject" WITHOUT running the verifier at
    # all, so an altered object would have been linked unverified.
    #
    # A custom target's command ALWAYS runs, so the verifier executes on
    # every relevant production build and the object content is checked
    # every time. The stamp file is still written, but it is a RECORD of
    # the verification (it records the object's SHA), never the thing that
    # decides whether the verification happens (AC15).
    #
    # The stamp is additionally validated against the object's SHA when
    # it exists, so a stamp left behind by a DIFFERENT object content is
    # detected and reported rather than silently trusted.
    # ---------------------------------------------------------------------
    add_custom_target(hcc-control-flow-token-verify
        COMMAND "${CMAKE_COMMAND}"
                -DCONTROL_FLOW_TOKEN_OBJECT=${CONTROL_FLOW_TOKEN_OBJECT}
                -DCONTROL_FLOW_TOKEN_EXPECTED_SYMBOL=BootstrapValidPostControlFlowToken
                -DCONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT=${CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT}
                -DCONTROL_FLOW_TOKEN_NM=${CONTROL_FLOW_TOKEN_NM}
                -P "${CMAKE_SOURCE_DIR}/cmake/VerifyControlFlowTokenObject.cmake"
        COMMAND "${CMAKE_COMMAND}"
                -DCONTROL_FLOW_TOKEN_OBJECT=${CONTROL_FLOW_TOKEN_OBJECT}
                -DCONTROL_FLOW_TOKEN_STAMP=${_cft_stamp}
                -P "${CMAKE_SOURCE_DIR}/cmake/WriteControlFlowTokenObjectStamp.cmake"
        DEPENDS "${CONTROL_FLOW_TOKEN_OBJECT}"
        COMMENT "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: verifying control-flow-token subject ${CONTROL_FLOW_TOKEN_OBJECT}"
        VERBATIM
        USES_TERMINAL)

    # The verification gates the link: the production compiler is never
    # linked without a verified PolyC control-flow-token authority.
    add_dependencies(hcc hcc-control-flow-token-verify)

    # The link itself must ALSO depend on the object, so the object is
    # re-read by the linker whenever it changes.
    set_property(TARGET hcc APPEND PROPERTY
        LINK_DEPENDS "${CONTROL_FLOW_TOKEN_OBJECT}")

    target_compile_definitions(hcc PRIVATE HCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN)
    target_link_libraries(hcc ${CONTROL_FLOW_TOKEN_OBJECT})
    message(STATUS "ACT-POLYC-SELFHOST-PARSER-SLICE02: production hcc links control-flow-token PolyC component: ${CONTROL_FLOW_TOKEN_OBJECT}")
    message(STATUS "ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01: production hcc VERIFIES the control-flow-token subject (both producer and prebuilt modes); "
                   "target format=${CONTROL_FLOW_TOKEN_TARGET_OBJECT_FORMAT}; nm=${CONTROL_FLOW_TOKEN_NM}")
endif()

# ACT-POLYC-BOOTSTRAP02 C2 IMPL — opt-in stage1 build that
# links the B1 PolyC component (BootstrapScanIdent) into a
# SEPARATE binary (hcc-bootstrap02) which uses the modified
# src/lexer.c::lexIdentifier delegation. The default `./hcc`
# build is UNCHANGED: src/lexer.c references
# BootstrapScanIdent unconditionally, but the production
# default build does not provide it; the opt-in flag is the
# explicit way to build the stage1 binary.
#
# Why an opt-in option (not a default):
#   - the production `./hcc` build must continue to build
#     without requiring tools/bootstrap/bootstrap02-ident.HC
#     to have been pre-compiled by stage0 hcc;
#   - this keeps the standard `make all` flow hermetic;
#   - the B1 component requires a SEPARATE stage0 hcc
#     compile pass (because BootstrapScanIdent is the very
#     component we are trying to validate).
#
# To build the stage1 binary:
#
#   ./hcc --install-dir=<prefix> -c \
#       ../tools/bootstrap/bootstrap02-ident.HC \
#       -o build/bootstrap02-ident.o
#
#   cmake -S ./src -B ./build-stage1 \
#       -DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
#       -DBOOTSTRAP02_IDENT_OBJECT=<abs-path>/build/bootstrap02-ident.o \
#       ...
#   make -C ./build-stage1 hcc-bootstrap02
#
# Defaults: OFF (production binary builds as before).
option(HCC_ENABLE_BOOTSTRAP02_STAGE1
       "Link the B1 PolyC component (BootstrapScanIdent) into a separate stage1 binary (hcc-bootstrap02). ACT-POLYC-BOOTSTRAP02."
       OFF)

if (HCC_ENABLE_BOOTSTRAP02_STAGE1)
    if (NOT BOOTSTRAP02_IDENT_OBJECT)
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP02_STAGE1=ON but BOOTSTRAP02_IDENT_OBJECT is not set. "
            "Pass -DBOOTSTRAP02_IDENT_OBJECT=<abs-path>/build/bootstrap02-ident.o "
            "produced by: ./hcc -c tools/bootstrap/bootstrap02-ident.HC -o build/bootstrap02-ident.o")
    endif()
    if (NOT EXISTS "${BOOTSTRAP02_IDENT_OBJECT}")
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP02_STAGE1=ON but BOOTSTRAP02_IDENT_OBJECT=${BOOTSTRAP02_IDENT_OBJECT} "
            "does not exist. Build it first with stage0 hcc.")
    endif()
    # The B1 object is consumed at link time only; we build a
    # SEPARATE executable so the production `./hcc` binary
    # tree remains a stage0 reference (no mutation).
    add_executable(hcc-bootstrap02 ${SOURCES} ${HEADERS})
    # ACT-POLYC-SELFHOST-LEXER01 §26: the generic stage1+ selector
    # is HCC_USE_SELFHOST_COMPONENTS. The legacy macro
    # HCC_BOOTSTRAP02_STAGE1 is normalized at the source level in
    # src/lexer.c::lexIdentifier; we still pass both for clarity.
    target_compile_definitions(hcc-bootstrap02 PRIVATE
        HCC_USE_SELFHOST_COMPONENTS
        HCC_BOOTSTRAP02_STAGE1)
    if (HCC_ENABLE_JIT)
        target_link_libraries(hcc-bootstrap02 tasm ${CMAKE_DL_LIBS})
    endif()
    # ACT-POLYC-SELFHOST-LEXER01-CORRECTION01 C2 IMPL: link the
    # operator / punctuation classifier (tools/bootstrap/
    # selfhost-lexer-operator-classify.HC, compiled by stage0)
    # into the stage1 binary. Per correction01, the operator
    # object is now a HARD prerequisite: HCC_USE_SELFHOST_COMPONENTS
    # is enabled above, so the source expects _BootstrapClassifyOperator;
    # accidental fail-closed via the linker is no longer enough.
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT)
        set(BOOTSTRAP06_OPERATOR_OBJECT "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.o")
    endif()
    if (NOT EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: required self-host "
            "operator component missing at ${BOOTSTRAP06_OPERATOR_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc -c tools/bootstrap/selfhost-lexer-operator-classify.HC "
            "-o build/bootstrap06-operator-classify.o")
    endif()
    target_link_libraries(hcc-bootstrap02 ${BOOTSTRAP02_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT} m)
    message(STATUS "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: stage1 operator component linked (fail-closed): ${BOOTSTRAP06_OPERATOR_OBJECT}")
    # ACT-POLYC-SELFHOST-LEXER02 C2 IMPL — also link the
    # scalar literal component (BootstrapScanScalarLiteral).
    # Per §38 / §55, fail-closed: the object MUST exist when
    # HCC_USE_SELFHOST_COMPONENTS is enabled.
    if (NOT LEXER07_SCALAR_OBJECT)
        set(LEXER07_SCALAR_OBJECT "${CMAKE_SOURCE_DIR}/../build/lexer07-scalar-literal.o")
    endif()
    if (NOT EXISTS "${LEXER07_SCALAR_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER02: required self-host "
            "scalar literal component missing at ${LEXER07_SCALAR_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc -c tools/bootstrap/selfhost-lexer-scalar-literal.HC "
            "-o build/lexer07-scalar-literal.o")
    endif()
    target_link_libraries(hcc-bootstrap02 ${LEXER07_SCALAR_OBJECT})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER02: stage1 scalar literal component linked (fail-closed): ${LEXER07_SCALAR_OBJECT}")
    # ACT-POLYC-SELFHOST-LEXER03 C2 IMPL — also link the
    # trivia component (BootstrapScanTrivia). Per §38 / §55,
    # fail-closed.
    if (NOT LEXER08_TRIVIA_OBJECT)
        set(LEXER08_TRIVIA_OBJECT "${CMAKE_SOURCE_DIR}/../build/lexer08-trivia.o")
    endif()
    if (NOT EXISTS "${LEXER08_TRIVIA_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER03: required self-host "
            "trivia component missing at ${LEXER08_TRIVIA_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc -c tools/bootstrap/selfhost-lexer-trivia.HC "
            "-o build/lexer08-trivia.o")
    endif()
    target_link_libraries(hcc-bootstrap02 ${LEXER08_TRIVIA_OBJECT})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER03: stage1 trivia component linked (fail-closed): ${LEXER08_TRIVIA_OBJECT}")
    # ACT-POLYC-SELFHOST-LEXER04 C2 IMPL — also link the
    # link directive component (BootstrapLinkDirective).
    # Per §38 / §55, fail-closed.
    if (NOT LEXER09_LINK_OBJECT)
        set(LEXER09_LINK_OBJECT "${CMAKE_SOURCE_DIR}/../build/lexer09-link.o")
    endif()
    if (NOT EXISTS "${LEXER09_LINK_OBJECT}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER04: required self-host "
            "link directive component missing at ${LEXER09_LINK_OBJECT}. "
            "Build it first with stage0 hcc: "
            "./hcc -c tools/bootstrap/selfhost-lexer-link.HC "
            "-o build/lexer09-link.o")
    endif()
    target_link_libraries(hcc-bootstrap02 ${LEXER09_LINK_OBJECT})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER04: stage1 link directive component linked (fail-closed): ${LEXER09_LINK_OBJECT}")
    install(TARGETS hcc-bootstrap02 DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif()

# ACT-POLYC-BOOTSTRAP03 C2 IMPL — opt-in stage2 build that
# links the B1 PolyC component (BootstrapScanIdent), this
# time as compiled BY STAGE1 (not by stage0), into a SEPARATE
# stage2 binary (hcc-bootstrap03). Mirrors the B1 stage1
# pattern but with an additional opt-in flag so the
# provenance invariant is explicit in the build graph.
#
# Provenance invariant (ACT §5): the object linked here MUST
# be the stage1-produced one. Because stage2's lexIdentifier
# still uses the same _BootstrapScanIdent symbol, we route
# through the existing #ifdef HCC_BOOTSTRAP02_STAGE1 dispatch
# in src/lexer.c. We add a SECOND define
# (HCC_BOOTSTRAP03_STAGE2) so the build graph can distinguish
# which stage's B1 object the binary carries, and so a future
# auditor can see the chain at compile-time.
#
# To build the stage2 binary:
#
#   ./build/hcc-bootstrap02 --install-dir=<prefix> -c \
#       ../tools/bootstrap/bootstrap02-ident.HC \
#       -o build/bootstrap03-ident.stage1.o
#
#   cmake -S ./src -B ./build/hcc-bootstrap03-build \
#       -DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
#       -DBOOTSTRAP02_IDENT_OBJECT=<abs>/build/bootstrap02-ident.o \
#       -DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
#       -DBOOTSTRAP03_IDENT_OBJECT=<abs>/build/bootstrap03-ident.stage1.o \
#       ...
#   make -C ./build/hcc-bootstrap03-build hcc-bootstrap03
#
# Defaults: OFF (the production binary tree stays unchanged).
option(HCC_ENABLE_BOOTSTRAP03_STAGE2
       "Link the B1 PolyC component (BootstrapScanIdent) compiled by stage1 into a separate stage2 binary (hcc-bootstrap03). ACT-POLYC-BOOTSTRAP03."
       OFF)

if (HCC_ENABLE_BOOTSTRAP03_STAGE2)
    if (NOT HCC_ENABLE_BOOTSTRAP02_STAGE1)
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP03_STAGE2=ON requires HCC_ENABLE_BOOTSTRAP02_STAGE1=ON. "
            "Stage2 must carry the B1 component symbol; the only delegation path is the B1 stage1 dispatch.")
    endif()
    if (NOT BOOTSTRAP03_IDENT_OBJECT)
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP03_STAGE2=ON but BOOTSTRAP03_IDENT_OBJECT is not set. "
            "Pass -DBOOTSTRAP03_IDENT_OBJECT=<abs-path>/build/bootstrap03-ident.stage1.o "
            "produced by: ./build/hcc-bootstrap02 -c tools/bootstrap/bootstrap02-ident.HC -o <path>")
    endif()
    if (NOT EXISTS "${BOOTSTRAP03_IDENT_OBJECT}")
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP03_STAGE2=ON but BOOTSTRAP03_IDENT_OBJECT=${BOOTSTRAP03_IDENT_OBJECT} "
            "does not exist. Build it first with stage1 hcc-bootstrap02.")
    endif()
    # Stage2 is consumed as the ONLY B1 source for its link.
    # The build graph ensures stage1's object is the link input;
    # the distinct BOOTSTRAP03_IDENT_OBJECT path makes that
    # provenance checkable. Stage2 also depends on the stage0
    # B1 object path being present only for the cmake-time
    # HCC_BOOTSTRAP02_STAGE1 dispatch (which gates the symbol
    # lookup), but the actual link for stage2 uses BOOTSTRAP03.
    #
    # IMPORTANT: in a future ACT where multiple stage objects
    # need to coexist (B3), the BOOTSTRAP02_IDENT_OBJECT input
    # here is only needed at compile-time because src/lexer.c's
    # dispatch was already compiled into stage2's source units.
    # We therefore build a SEPARATE stage2 executable; do NOT
    # overwrite hcc or hcc-bootstrap02.
    add_executable(hcc-bootstrap03 ${SOURCES} ${HEADERS})
    # ACT-POLYC-SELFHOST-LEXER01 §26: use generic selector.
    target_compile_definitions(hcc-bootstrap03 PRIVATE
        HCC_USE_SELFHOST_COMPONENTS
        HCC_BOOTSTRAP02_STAGE1
        HCC_BOOTSTRAP03_STAGE2)
    if (HCC_ENABLE_JIT)
        target_link_libraries(hcc-bootstrap03 tasm ${CMAKE_DL_LIBS})
    endif()
    # ACT-POLYC-SELFHOST-LEXER01-CORRECTION01 C2 IMPL: also link
    # the operator component (this time as produced by stage1).
    # Per correction01, fail-closed.
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT_STAGE1)
        set(BOOTSTRAP06_OPERATOR_OBJECT_STAGE1 "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.stage1.o")
    endif()
    if (NOT EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: required stage2 "
            "operator component missing at ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1}. "
            "Build it first with stage1 hcc-bootstrap02: "
            "./hcc-bootstrap02 -c tools/bootstrap/selfhost-lexer-operator-classify.HC "
            "-o build/bootstrap06-operator-classify.stage1.o")
    endif()
    target_link_libraries(hcc-bootstrap03 ${BOOTSTRAP03_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1} m)
    message(STATUS "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: stage2 operator component linked (fail-closed): ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1}")
    # ACT-POLYC-SELFHOST-LEXER02 C2 IMPL — also link the
    # scalar literal component (this time as produced by
    # stage1).
    if (NOT LEXER07_SCALAR_OBJECT_STAGE1)
        set(LEXER07_SCALAR_OBJECT_STAGE1 "${CMAKE_SOURCE_DIR}/../build/lexer07-scalar-literal.stage1.o")
    endif()
    if (NOT EXISTS "${LEXER07_SCALAR_OBJECT_STAGE1}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER02: required stage2 "
            "scalar literal component missing at ${LEXER07_SCALAR_OBJECT_STAGE1}. "
            "Build it first with stage1 hcc-bootstrap02: "
            "./hcc-bootstrap02 -c tools/bootstrap/selfhost-lexer-scalar-literal.HC "
            "-o build/lexer07-scalar-literal.stage1.o")
    endif()
    target_link_libraries(hcc-bootstrap03 ${LEXER07_SCALAR_OBJECT_STAGE1})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER02: stage2 scalar literal component linked (fail-closed): ${LEXER07_SCALAR_OBJECT_STAGE1}")
    # ACT-POLYC-SELFHOST-LEXER03 C2 IMPL — also link the
    # trivia component as produced by stage1.
    if (NOT LEXER08_TRIVIA_OBJECT_STAGE1)
        set(LEXER08_TRIVIA_OBJECT_STAGE1 "${CMAKE_SOURCE_DIR}/../build/lexer08-trivia.stage1.o")
    endif()
    if (NOT EXISTS "${LEXER08_TRIVIA_OBJECT_STAGE1}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER03: required stage2 "
            "trivia component missing at ${LEXER08_TRIVIA_OBJECT_STAGE1}. "
            "Build it first with stage1 hcc-bootstrap02: "
            "./hcc-bootstrap02 -c tools/bootstrap/selfhost-lexer-trivia.HC "
            "-o build/lexer08-trivia.stage1.o")
    endif()
    target_link_libraries(hcc-bootstrap03 ${LEXER08_TRIVIA_OBJECT_STAGE1})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER03: stage2 trivia component linked (fail-closed): ${LEXER08_TRIVIA_OBJECT_STAGE1}")
    # ACT-POLYC-SELFHOST-LEXER04 C2 IMPL — also link the
    # link directive component as produced by stage1.
    if (NOT LEXER09_LINK_OBJECT_STAGE1)
        set(LEXER09_LINK_OBJECT_STAGE1 "${CMAKE_SOURCE_DIR}/../build/lexer09-link.stage1.o")
    endif()
    if (NOT EXISTS "${LEXER09_LINK_OBJECT_STAGE1}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER04: required stage2 "
            "link directive component missing at ${LEXER09_LINK_OBJECT_STAGE1}. "
            "Build it first with stage1 hcc-bootstrap02: "
            "./hcc-bootstrap02 -c tools/bootstrap/selfhost-lexer-link.HC "
            "-o build/lexer09-link.stage1.o")
    endif()
    target_link_libraries(hcc-bootstrap03 ${LEXER09_LINK_OBJECT_STAGE1})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER04: stage2 link directive component linked (fail-closed): ${LEXER09_LINK_OBJECT_STAGE1}")
    install(TARGETS hcc-bootstrap03 DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif()

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — opt-in stage3 build that
# links the B1 PolyC component (BootstrapScanIdent), this
# time as compiled BY STAGE2 (not by stage0 or stage1), into
# a SEPARATE stage3 binary (hcc-bootstrap04). Mirrors the B2
# stage2 pattern but with one additional opt-in flag so the
# provenance invariant for the stage2->stage3 edge is
# explicit in the build graph.
#
# Provenance invariant (ACT §6): the object linked here MUST
# be the stage2-produced one. Because stage3's lexIdentifier
# still uses the same _BootstrapScanIdent symbol under the
# same HCC_BOOTSTRAP02_STAGE1 dispatch (frozen in src/lexer.c),
# stage3's compile-time definition set is
#   HCC_BOOTSTRAP02_STAGE1   <-- lexer delegation gate
#   HCC_BOOTSTRAP04_STAGE3   <-- build-graph distinctness only
# The new STAGE3 macro mirrors B2's STAGE2 macro: it exists
# purely so the build graph can distinguish stage3 from
# stage2, not because the lexer requires a new branch.
#
# To build the stage3 binary:
#
#   ./build/hcc-bootstrap03 --install-dir=<prefix> -c \
#       ../tools/bootstrap/bootstrap02-ident.HC \
#       -o build/bootstrap04-ident.stage2.o
#
#   cmake -S ./src -B ./build/hcc-bootstrap04-build \
#       -DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
#       -DBOOTSTRAP02_IDENT_OBJECT=<abs>/build/bootstrap02-ident.o \
#       -DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
#       -DBOOTSTRAP03_IDENT_OBJECT=<abs>/build/bootstrap03-ident.stage1.o \
#       -DHCC_ENABLE_BOOTSTRAP04_STAGE3=ON \
#       -DBOOTSTRAP04_IDENT_OBJECT=<abs>/build/bootstrap04-ident.stage2.o \
#       ...
#   make -C ./build/hcc-bootstrap04-build hcc-bootstrap04
#
# Defaults: OFF (the production binary tree stays unchanged).
option(HCC_ENABLE_BOOTSTRAP04_STAGE3
       "Link the B1 PolyC component (BootstrapScanIdent) compiled by stage2 into a separate stage3 binary (hcc-bootstrap04). ACT-POLYC-BOOTSTRAP04."
       OFF)

if (HCC_ENABLE_BOOTSTRAP04_STAGE3)
    if (NOT HCC_ENABLE_BOOTSTRAP03_STAGE2)
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP04_STAGE3=ON requires HCC_ENABLE_BOOTSTRAP03_STAGE2=ON. "
            "Stage3 must carry the B1 component symbol; the only delegation path is the B1 stage1 dispatch.")
    endif()
    if (NOT BOOTSTRAP04_IDENT_OBJECT)
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP04_STAGE3=ON but BOOTSTRAP04_IDENT_OBJECT is not set. "
            "Pass -DBOOTSTRAP04_IDENT_OBJECT=<abs-path>/build/bootstrap04-ident.stage2.o "
            "produced by: ./build/hcc-bootstrap03 -c tools/bootstrap/bootstrap02-ident.HC -o <path>")
    endif()
    if (NOT EXISTS "${BOOTSTRAP04_IDENT_OBJECT}")
        message(FATAL_ERROR
            "HCC_ENABLE_BOOTSTRAP04_STAGE3=ON but BOOTSTRAP04_IDENT_OBJECT=${BOOTSTRAP04_IDENT_OBJECT} "
            "does not exist. Build it first with stage2 hcc-bootstrap03.")
    endif()
    # Stage3 is consumed as the ONLY B1 source for its link.
    # The build graph ensures stage2's object is the link input;
    # the distinct BOOTSTRAP04_IDENT_OBJECT path makes that
    # provenance checkable.
    #
    # We build a SEPARATE stage3 executable; do NOT overwrite
    # hcc, hcc-bootstrap02, or hcc-bootstrap03.
    add_executable(hcc-bootstrap04 ${SOURCES} ${HEADERS})
    # ACT-POLYC-SELFHOST-LEXER01 §26: use generic selector.
    target_compile_definitions(hcc-bootstrap04 PRIVATE
        HCC_USE_SELFHOST_COMPONENTS
        HCC_BOOTSTRAP02_STAGE1
        HCC_BOOTSTRAP04_STAGE3)
    if (HCC_ENABLE_JIT)
        target_link_libraries(hcc-bootstrap04 tasm ${CMAKE_DL_LIBS})
    endif()
    # ACT-POLYC-SELFHOST-LEXER01-CORRECTION01 C2 IMPL: also link
    # the operator component as produced by stage2. Per
    # correction01, fail-closed.
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT_STAGE2)
        set(BOOTSTRAP06_OPERATOR_OBJECT_STAGE2 "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.stage2.o")
    endif()
    if (NOT EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: required stage3 "
            "operator component missing at ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2}. "
            "Build it first with stage2 hcc-bootstrap03: "
            "./hcc-bootstrap03 -c tools/bootstrap/selfhost-lexer-operator-classify.HC "
            "-o build/bootstrap06-operator-classify.stage2.o")
    endif()
    target_link_libraries(hcc-bootstrap04 ${BOOTSTRAP04_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2} m)
    message(STATUS "ACT-POLYC-SELFHOST-LEXER01-CORRECTION01: stage3 operator component linked (fail-closed): ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2}")
    # ACT-POLYC-SELFHOST-LEXER02 C2 IMPL — also link the
    # scalar literal component (this time as produced by
    # stage2).
    if (NOT LEXER07_SCALAR_OBJECT_STAGE2)
        set(LEXER07_SCALAR_OBJECT_STAGE2 "${CMAKE_SOURCE_DIR}/../build/lexer07-scalar-literal.stage2.o")
    endif()
    if (NOT EXISTS "${LEXER07_SCALAR_OBJECT_STAGE2}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER02: required stage3 "
            "scalar literal component missing at ${LEXER07_SCALAR_OBJECT_STAGE2}. "
            "Build it first with stage2 hcc-bootstrap03: "
            "./hcc-bootstrap03 -c tools/bootstrap/selfhost-lexer-scalar-literal.HC "
            "-o build/lexer07-scalar-literal.stage2.o")
    endif()
    target_link_libraries(hcc-bootstrap04 ${LEXER07_SCALAR_OBJECT_STAGE2})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER02: stage3 scalar literal component linked (fail-closed): ${LEXER07_SCALAR_OBJECT_STAGE2}")
    # ACT-POLYC-SELFHOST-LEXER03 C2 IMPL — also link the
    # trivia component as produced by stage2.
    if (NOT LEXER08_TRIVIA_OBJECT_STAGE2)
        set(LEXER08_TRIVIA_OBJECT_STAGE2 "${CMAKE_SOURCE_DIR}/../build/lexer08-trivia.stage2.o")
    endif()
    if (NOT EXISTS "${LEXER08_TRIVIA_OBJECT_STAGE2}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER03: required stage3 "
            "trivia component missing at ${LEXER08_TRIVIA_OBJECT_STAGE2}. "
            "Build it first with stage2 hcc-bootstrap03: "
            "./hcc-bootstrap03 -c tools/bootstrap/selfhost-lexer-trivia.HC "
            "-o build/lexer08-trivia.stage2.o")
    endif()
    target_link_libraries(hcc-bootstrap04 ${LEXER08_TRIVIA_OBJECT_STAGE2})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER03: stage3 trivia component linked (fail-closed): ${LEXER08_TRIVIA_OBJECT_STAGE2}")
    # ACT-POLYC-SELFHOST-LEXER04 C2 IMPL — also link the
    # link directive component as produced by stage2.
    if (NOT LEXER09_LINK_OBJECT_STAGE2)
        set(LEXER09_LINK_OBJECT_STAGE2 "${CMAKE_SOURCE_DIR}/../build/lexer09-link.stage2.o")
    endif()
    if (NOT EXISTS "${LEXER09_LINK_OBJECT_STAGE2}")
        message(FATAL_ERROR
            "ACT-POLYC-SELFHOST-LEXER04: required stage3 "
            "link directive component missing at ${LEXER09_LINK_OBJECT_STAGE2}. "
            "Build it first with stage2 hcc-bootstrap03: "
            "./hcc-bootstrap03 -c tools/bootstrap/selfhost-lexer-link.HC "
            "-o build/lexer09-link.stage2.o")
    endif()
    target_link_libraries(hcc-bootstrap04 ${LEXER09_LINK_OBJECT_STAGE2})
    message(STATUS "ACT-POLYC-SELFHOST-LEXER04: stage3 link directive component linked (fail-closed): ${LEXER09_LINK_OBJECT_STAGE2}")
    install(TARGETS hcc-bootstrap04 DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif()

if (HCC_ENABLE_JIT)
    target_compile_definitions(hcc PRIVATE HCC_ENABLE_JIT)
    target_link_libraries(hcc tasm ${CMAKE_DL_LIBS})
endif()

if (HCC_ENABLE_LLVM)
    target_compile_definitions(hcc PRIVATE HCC_ENABLE_LLVM)
    target_compile_options(hcc PRIVATE ${LLVM_CFLAGS})
    target_link_libraries(hcc ${LLVM_LDFLAGS} ${LLVM_LIBS_CORE})
endif()

# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01 C2-1: provenance-strict
# hcc selection. The cmake-driven install seam must NOT silently
# fall through to the freshly-built ./hcc (commit 6ba9f5ec) which
# regressed on ARM64 inline-asm and cannot produce a complete all.o.
#
# Strict contract:
#   - If build/hcc-bootstrap04 (commit ffee58b, the last known-good
#     producer) is present, use it. This is the canonical producer.
#   - If it is NOT present, the install seam DOES NOT silently fall
#     through. Instead it FATAL_ERRORs at configure time, forcing the
#     caller to build the bootstrap chain first.
#   - The fallback to ${CMAKE_INSTALL_PREFIX}/bin/hcc is removed
#     because the fresh hcc at HEAD regressed.
#
# This is the cmake analogue of the Makefile lib-tos provenance
# contract (see Makefile lines around LIBTOS_HCC). Both seams use
# the same bootstrap-or-fail policy.
# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The strict runtime-producer check has MOVED from global configure time
# to the points where the runtime producer is actually REQUIRED.
#
# Why it had to move (the B2 blocker):
#   The producer build/hcc-bootstrap04 is itself produced by the chain
#       bootstrap04-stage3 -> bootstrap03-stage2 -> bootstrap02-stage1
#                          -> bootstrap02-component-build
#                          -> test-prefix-install -> cmake configure
#   and the configure-time gate demanded the very artifact that the
#   chain was supposed to produce. A compiler-only configuration was
#   therefore impossible from a clean tree, which is a bootstrap-graph
#   defect, not a runtime defect.
#
# What did NOT change (F5 -- the check must not disappear):
#   The provenance contract is still fail-closed and is still enforced
#   with the SAME pinned identity. There are exactly two consumers of
#   the runtime producer, and BOTH now verify it at the moment of use:
#
#     * the `unit-test` custom target  (test harness compilation)
#     * the libtos install seam         (runtime archive production)
#
#   A configuration that merely BUILDS the compiler never needs the
#   producer and is therefore no longer blocked by it.
set(HCC_BOOTSTRAP "${CMAKE_SOURCE_DIR}/../build/runtime-producer/hcc-bootstrap04")

# Fail-closed verification of the runtime producer, factored out so that
# the unit-test target and the install seam use the SAME check.
include(${CMAKE_SOURCE_DIR}/cmake/RequireRuntimeProducer.cmake)

# The producer is only resolved at the point of use. The path is still
# recorded so the install seam and the unit-test target address the
# SAME artifact.
set(HCC_PATH "${HCC_BOOTSTRAP}")

# Command for unit tests
add_custom_target(unit-test
    COMMAND ${CMAKE_COMMAND} -E echo "Running unit tests..."
    COMMAND ${CMAKE_COMMAND}
            -DHCC_BOOTSTRAP=${HCC_BOOTSTRAP}
            -DHCC_BOOTSTRAP_EXPECTED_SHA=${HCC_BOOTSTRAP_EXPECTED_SHA}
            -P ${CMAKE_SOURCE_DIR}/cmake/RequireRuntimeProducer.cmake
    COMMAND ${HCC_PATH} -o test-runner ${CMAKE_SOURCE_DIR}/tests/run.HC
    COMMAND ${CMAKE_SOURCE_DIR}/tests/test-runner
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/tests
    COMMENT "Building and running unit tests"
    USES_TERMINAL
)

target_link_libraries(hcc m)

# Install the executable
install(TARGETS hcc DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)


# Install the header file
install(FILES ${CMAKE_SOURCE_DIR}/holyc-lib/tos.HH DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# Custom installation step to run `hcc` during install.
#
# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION02 adds errno_shim.c, a tiny
# C file that must be linked into libtos.a and libtos.dylib so the
# Tooling runtime's EINTR-retry paths can read errno.
#
# ACT-POLYC-TOOLING-RUNTIME01-CORRECTION03 fixes several defects in
# the install step:
#   1. `execute_process(COMMAND ...)` does NOT invoke a shell on POSIX
#      (CMake passes argv directly). The previous form
#      `ar r ... && ranlib ...` passed `&&` as a literal argv member,
#      which `ar` interpreted as a member filename and failed. We split
#      into separate `execute_process` calls, each with
#      `COMMAND_ERROR_IS_FATAL ANY`.
#   2. `-D__APPLE__` was passed unconditionally to `hcc`, lying about
#      the platform. We now pass it only inside the `if(APPLE)` branch
#      where errno_shim.o actually gets compiled and linked.
#   3. None of the install sub-commands declared failure fatal;
#      install could silently continue past a broken archive. Every
#      sub-command now has `COMMAND_ERROR_IS_FATAL ANY`.
#   4. The original install did not produce libtos.dylib (unversioned
#      symlink). Without it, downstream `-ltos` linkage picks up
#      libtos.a's full symbol set, which collides with any program
#      that also #includes tooling.HC (and therefore has the same
#      symbols). The canonical layout (see build/test-prefix/lib)
#      ships the symlink so AOT resolves against the dylib. We now
#      produce it.
#
# Build flow (each step is its own execute_process with no shell):
#   1. hcc -lib all.HC
#      Produces all.o and libtos.a. hcc ALSO attempts to link
#      libtos.dylib but fails (because all.o references _Errno which
#      errno_shim.o doesn't exist yet). We tolerate that exit-1 and
#      continue.
#   2. cc -c errno_shim.c -> errno_shim.o
#   3. ar r libtos.a errno_shim.o   (re-archive with shim added)
#   4. ranlib libtos.a
#   5. cc -dynamiclib all.o errno_shim.o -> libtos.0.0.1.dylib
#   6. ln -sf libtos.0.0.1.dylib libtos.dylib   (downstream -ltos resolves here)
#   7. install(FILES) libtos.a, libtos.0.0.1.dylib into ${CMAKE_INSTALL_PREFIX}/lib
#
# macOS-only for now; glibc support lives in ACT-POLYC-TOOLING-LINUX-PORT01.
if (APPLE)
    set(LIBTOS_BUILD_DIR "${CMAKE_BINARY_DIR}/libtos-build")
    file(MAKE_DIRECTORY "${LIBTOS_BUILD_DIR}")
    # ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
    # The provenance-strict runtime producer check now runs AT THE POINT
    # WHERE THE RUNTIME IS ACTUALLY PRODUCED, not at global configure
    # time. The check itself is UNCHANGED in strength: the producer must
    # exist and must match the pinned identity. Only its TRIGGER moved.
    #
    # If the install step executes without a qualified bootstrap04, this
    # FATAL_ERROR aborts the install. It never falls back to stage0, to
    # the host compiler, or to any other producer.
    install(CODE "
        set(HCC_BOOTSTRAP \"${HCC_BOOTSTRAP}\")
        set(HCC_BOOTSTRAP_EXPECTED_SHA \"${HCC_BOOTSTRAP_EXPECTED_SHA}\")
        include(\"${CMAKE_SOURCE_DIR}/cmake/RequireRuntimeProducer.cmake\")
        hcc_require_runtime_producer()
    ")
    # CORRECTION05: Fresh-output invariant.
    # The producer (hcc -lib) is allowed to exit non-zero (its own dylib
    # link attempt fails on _Errno pre-shim); the install step then
    # *re-runs* cc -dynamiclib with errno_shim.o included.
    # If we did not clean LIBTOS_BUILD_DIR before the install step, a
    # stale all.o from a previous install could survive a failed hcc
    # invocation. The downstream `if(NOT EXISTS all.o)` guard would
    # see the stale file and the install would proceed using yesterday's
    # object — a false GREEN.
    # We force the producer to start from an empty output state by
    # removing any candidate outputs at install time. After this,
    # `if(NOT EXISTS all.o)` is meaningful (it really tests that *this*
    # hcc invocation produced all.o, not that some prior run did).
    install(CODE "
        file(REMOVE
            \"${LIBTOS_BUILD_DIR}/all.o\"
            \"${LIBTOS_BUILD_DIR}/errno_shim.o\"
            \"${LIBTOS_BUILD_DIR}/libtos.a\"
            \"${LIBTOS_BUILD_DIR}/libtos.0.0.1.dylib\")
    ")
    if (DEFINED HCC_LINK_SQLITE3)
        install(CODE "execute_process(COMMAND \"${HCC_PATH}\" --install-dir=${CMAKE_INSTALL_PREFIX} -D__APPLE__ -DHCC_LINK_SQLITE3 -lib tos ${CMAKE_SOURCE_DIR}/holyc-lib/all.HC WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" RESULT_VARIABLE hcc_lib_result)")
    else()
        install(CODE "execute_process(COMMAND \"${HCC_PATH}\" --install-dir=${CMAKE_INSTALL_PREFIX} -D__APPLE__ -fPIC -lib tos ${CMAKE_SOURCE_DIR}/holyc-lib/all.HC WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" RESULT_VARIABLE hcc_lib_result)")
    endif()
    install(CODE "
        if(NOT hcc_lib_result EQUAL 0)
            message(WARNING \"hcc -lib exited with code \${hcc_lib_result}; this is expected when all.o references _Errno. Continuing.\")
        endif()
        if(NOT EXISTS \"${LIBTOS_BUILD_DIR}/all.o\")
            message(FATAL_ERROR \"hcc -lib did not produce all.o in ${LIBTOS_BUILD_DIR}; cannot continue.\")
        endif()
    ")
    install(CODE "execute_process(COMMAND cc -O0 -c ${CMAKE_SOURCE_DIR}/holyc-lib/errno_shim.c -o errno_shim.o WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" COMMAND_ERROR_IS_FATAL ANY)")
    install(CODE "execute_process(COMMAND ar r libtos.a errno_shim.o WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" COMMAND_ERROR_IS_FATAL ANY)")
    install(CODE "execute_process(COMMAND ranlib libtos.a WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" COMMAND_ERROR_IS_FATAL ANY)")
    install(CODE "execute_process(COMMAND cc -dynamiclib -Wl,-install_name,${CMAKE_INSTALL_PREFIX}/lib/libtos.0.0.1.dylib all.o errno_shim.o -o libtos.0.0.1.dylib -lpthread -lc -lm WORKING_DIRECTORY \"${LIBTOS_BUILD_DIR}\" COMMAND_ERROR_IS_FATAL ANY)")
    install(FILES "${LIBTOS_BUILD_DIR}/libtos.a" DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
    install(FILES "${LIBTOS_BUILD_DIR}/libtos.0.0.1.dylib" DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
    # CORRECTION03: install(FILES) only copies regular files; symlinks must
    # be created in the install prefix explicitly. Without this symlink,
    # downstream `-ltos` linkage pulls in libtos.a's full symbol set
    # (instead of the dylib), causing duplicate-symbol errors when a
    # program also `#include`s tooling.HC.
    install(CODE "execute_process(COMMAND ln -sf libtos.0.0.1.dylib ${CMAKE_INSTALL_PREFIX}/lib/libtos.dylib COMMAND_ERROR_IS_FATAL ANY)")
else()
    # ACT-POLYC-TOOLING-LINUX-PORT01 (P1 residue): Linux build of libtos
    # is not yet wired. We deliberately do NOT pass -D__APPLE__ here —
    # the HolyC `#if defined(__APPLE__)` guards in tooling.HC will then
    # fall through to the `#else` `#error` branch and the build will
    # fail honestly, instead of silently producing a forged-Apple
    # libtos that links against a Linux libc that lacks `__error`.
    message(FATAL_ERROR "Tooling runtime host is macOS-only in this build. "
        "Linux support is ACT-POLYC-TOOLING-LINUX-PORT01.")
endif()
