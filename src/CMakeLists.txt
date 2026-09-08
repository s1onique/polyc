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

# Custom installation step to run `hcc` during install
if (DEFINED HCC_LINK_SQLITE3)
    install(CODE "execute_process(COMMAND \"${HCC_PATH}\" -DHCC_LINK_SQLITE3 -lib tos ${CMAKE_SOURCE_DIR}/holyc-lib/all.HC WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/holyc-lib)")
else()
  install(CODE "execute_process(COMMAND \"${HCC_PATH}\" -fPIC -lib tos ${CMAKE_SOURCE_DIR}/holyc-lib/all.HC WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/holyc-lib)")
endif()
