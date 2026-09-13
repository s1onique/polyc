cmake_minimum_required(VERSION 3.10)

project(HolyC)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_C_STANDARD_REQUIRED True)
set(CMAKE_C_STANDARD 11)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ../)

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
    # ACT-POLYC-SELFHOST-LEXER01 C2 IMPL: link the operator /
    # punctuation classifier (tools/bootstrap/selfhost-lexer-
    # operator-classify.HC, compiled by stage0) into the stage1
    # binary. Optional via BOOTSTRAP06_OPERATOR_OBJECT; default
    # path is ./build/bootstrap06-operator-classify.o.
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT)
        set(BOOTSTRAP06_OPERATOR_OBJECT "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.o")
    endif()
    if (EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT}")
        target_link_libraries(hcc-bootstrap02 ${BOOTSTRAP02_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT} m)
        message(STATUS "ACT-POLYC-SELFHOST-LEXER01: linking stage0 operator component ${BOOTSTRAP06_OPERATOR_OBJECT}")
    else()
        target_link_libraries(hcc-bootstrap02 ${BOOTSTRAP02_IDENT_OBJECT} m)
        message(STATUS "ACT-POLYC-SELFHOST-LEXER01: operator component not yet built; linking only B1")
    endif()
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
    # ACT-POLYC-SELFHOST-LEXER01 C2 IMPL: also link the operator
    # component (this time as produced by stage1).
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT_STAGE1)
        set(BOOTSTRAP06_OPERATOR_OBJECT_STAGE1 "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.stage1.o")
    endif()
    if (EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1}")
        target_link_libraries(hcc-bootstrap03 ${BOOTSTRAP03_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE1} m)
    else()
        target_link_libraries(hcc-bootstrap03 ${BOOTSTRAP03_IDENT_OBJECT} m)
    endif()
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
    # ACT-POLYC-SELFHOST-LEXER01 C2 IMPL: also link the operator
    # component as produced by stage2.
    if (NOT BOOTSTRAP06_OPERATOR_OBJECT_STAGE2)
        set(BOOTSTRAP06_OPERATOR_OBJECT_STAGE2 "${CMAKE_SOURCE_DIR}/../build/bootstrap06-operator-classify.stage2.o")
    endif()
    if (EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2}")
        target_link_libraries(hcc-bootstrap04 ${BOOTSTRAP04_IDENT_OBJECT} ${BOOTSTRAP06_OPERATOR_OBJECT_STAGE2} m)
    else()
        target_link_libraries(hcc-bootstrap04 ${BOOTSTRAP04_IDENT_OBJECT} m)
    endif()
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

set(HCC_PATH "${CMAKE_INSTALL_PREFIX}/bin/hcc")

# Command for unit tests
add_custom_target(unit-test
    COMMAND ${CMAKE_COMMAND} -E echo "Running unit tests..."
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
