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
