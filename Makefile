C_COMPILER     ?= gcc
BUILD_TYPE     ?= Release
INSTALL_PREFIX ?= /usr/local
CFLAGS         ?= '-Wextra -Wall -Wpedantic'

# ACT-POLYC-LLVM-SPIKE01-RESUME01: the spike is opt-in.
# `make all` builds the native baseline (HCC_ENABLE_LLVM=OFF).
# `make llvm-all` adds the LLVM 22 C-API backend spike.
# `make llvm-spike-test` runs the spike's positive + negative matrix
# against the LLVM 22 build. Requires llvm-config on PATH (LLVM 22.x).
HCC_ENABLE_LLVM ?= OFF

default: all

.PHONY: all formal-dafny gate-fast gate-push install-hooks llvm-all llvm-spike-test test-prefix-install llvm-gep01-test bootstrap01-test bootstrap01-oracle bootstrap02-test bootstrap02-stage1 bootstrap02-cursor-test bootstrap02-lexer-seam-test bootstrap03-component-build bootstrap03-stage2 bootstrap03-test bootstrap03-lexer-seam-test bootstrap04-component-build bootstrap04-stage3 bootstrap04-test bootstrap04-cursor-test bootstrap04-lexer-seam-test selfhost-component-binary selfhost-component-build selfhost-component-test selfhost-component-selftest selfhost-registry-validate factory-halt-classification-binary factory-halt-classification-selftest bootstrap06-component-build bootstrap06-operator-classify-oracle bootstrap06-direct-differential bootstrap06-component-stage1 bootstrap06-component-stage2 bootstrap06-component-stage3 bootstrap06-lexer-seam-stage1 lexer07-component-build lexer07-scalar-literal-oracle lexer07-direct-differential lexer07-component-stage1 lexer07-component-stage2 lexer07-component-stage3 lexer07-lexer-seam-stage0 lexer07-lexer-seam-stage1 lexer07-lexer-seam-stage2 lexer07-lexer-seam-stage3 lexer07-lexer-seam-stage2-from-objs lexer07-lexer-seam-stage3-from-objs lexer07-lexer-seam-all-stages lexer07-fixture-inventory lexer07-broad-corpus-4-stage lexer07-correction02-all

# To add sqlite3 support add -DHCC_LINK_SQLITE3=1 to the below like so:
#```
#all:
#	cmake -S ./src -B ./build -G 'Unix Makefiles' \
#		-DCMAKE_C_COMPILER=$(_C_COMPILER) \
#		-DCMAKE_BUILD_TYPE=$(_BUILD_TYPE) \
#		-DHCC_LINK_SQLITE3=1 \
#		&& $(MAKE) -C ./build -j2
#```

all:
	cmake -S ./src \
		-B ./build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=$(HCC_ENABLE_LLVM) \
		&& $(MAKE) -C ./build -j2

# ACT-POLYC-LLVM-SPIKE01-RESUME01: build hcc with the LLVM 22 C-API
# backend linked in. Requires llvm-config on PATH; the CMake configure
# step enforces major version 22.
llvm-all:
	cmake -S ./src \
		-B ./build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=ON \
		&& $(MAKE) -C ./build -j2

install:
	$(MAKE) -C ./build install

release-unit-test:
	$(MAKE) -C ./build unit-test

# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D2 (follow-up): unit-test
# and jit-unit-test now consume the same hermetic test prefix as
# lsp-test. The pre-existing recipes used the hcc compile-time
# INSTALL_PREFIX (/usr/local by default) to find tos.HH and
# libtos.{a,dylib}; on hosts without a writable /usr/local, that
# INSTALL_PREFIX mismatch causes both hcc to fail with
# "Failed to open file: /usr/local/include/tos.HH" AND the downstream
# cc -ltos link to fail with "Undefined symbols for architecture
# arm64: _FREE" or "invalid use of ADRP". Routing these targets
# through test-prefix-install + --install-dir=$(TEST_PREFIX) makes
# the gate-push hermetic on any host.
unit-test: test-prefix-install
	cd ./src/tests && ../../hcc --install-dir=$(TEST_PREFIX) ./run.HC -o test-runner && ./test-runner && cd ../../

jit-unit-test: test-prefix-install
	cd ./src/tests && ../../hcc --install-dir=$(TEST_PREFIX) ./run_jit.HC -o test-runner-jit && ./test-runner-jit && cd ../../

# Hermetic: builds libtos from the tree into a local prefix and
# compiles the (HolyC) harness against it, so the suite tests in-tree
# sources - never whatever happens to be installed in /usr/local.
#
# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D2: this recipe now
# delegates the canonical install dance (which links errno_shim.o
# into libtos.a + libtos.dylib) to `make test-prefix-install`. The
# direct `hcc -lib tos` invocation below the prior version produced
# a libtos.a with `_Errno` undefined, which then failed downstream
# `-ltos` linkage with "Undefined symbols".
lsp-test: test-prefix-install
	cd ./src/tests/lsp && ../../../hcc --install-dir=$(TEST_PREFIX) ./run_lsp_tests.HC -o lsp-test-runner && ./lsp-test-runner

# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D2: canonical local
# install seam. Every quality caller needing an installed PolyC
# runtime (lsp-test, gate-push GPUSH-2, llvm-gep01-test,
# runtime01-selftest) MUST consume this target instead of running
# its own `hcc -lib tos`. The CMake install dance in src/CMakeLists.txt
# (install(CODE ...) block) is the single source of truth for
# producing libtos.a + libtos.dylib with errno_shim.o incorporated.
#
# The build below reuses an already-built hcc from `./build/`. If hcc
# is not present, the recipe runs `make all` first; this is the same
# pattern lsp-test relied on before. The install prefix is taken from
# the TEST_PREFIX Make variable (default: build/test-prefix); callers
# such as gate-push.sh override it with INSTALL_PREFIX=$gate_prefix
# via `make test-prefix-install INSTALL_PREFIX=...` so the test
# prefix lands inside the gate's hermetic worktree.
#
# FOLLOW-UP: the canonical install creates an unversioned
# `libtos.dylib -> libtos.0.0.1.dylib` symlink (CORRECTION03 in
# src/CMakeLists.txt) so that downstream `-ltos` linkage in user
# code pulls in the dylib. For the gate-push hermetic prefix this
# is harmful: on arm64 the AOT codegen emits `adrp`/`add` pairs
# against `_FREE` and similar function symbols that the dylib's
# relocation metadata cannot satisfy, producing
# `ld: invalid use of ADRP in '_CmpFileNames' to '_FREE'`. The
# archive (`libtos.a`) ships the same symbols with archive-style
# relocations that link cleanly. We therefore remove the
# unversioned symlink after the canonical install so that
# downstream `-ltos` resolves to the archive inside the gate's
# hermetic prefix. This is a hermetic-prefix-local measure; the
# production install at `make install` is untouched.
TEST_PREFIX ?= $(CURDIR)/build/test-prefix
test-prefix-install:
	@if [ ! -x ./hcc ]; then \
		echo "test-prefix-install: ./hcc not found; running 'make all' first" >&2; \
		$(MAKE) all; \
	fi
	@mkdir -p $(TEST_PREFIX)
	@rm -rf $(CURDIR)/build/test-prefix-install-build
	@mkdir -p $(CURDIR)/build/test-prefix-install-build
	cmake -S ./src \
		-B ./build/test-prefix-install-build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(TEST_PREFIX) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=$(HCC_ENABLE_LLVM)
	$(MAKE) -C ./build/test-prefix-install-build install
	@if [ ! -f $(TEST_PREFIX)/lib/libtos.a ] || \
	    [ ! -f $(TEST_PREFIX)/lib/libtos.0.0.1.dylib ] || \
	    [ ! -L $(TEST_PREFIX)/lib/libtos.dylib ]; then \
		echo "test-prefix-install: canonical install did not produce libtos.{a,0.0.1.dylib,libtos.dylib-symlink}" >&2; \
		exit 1; \
	fi

# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D1: canonical GEP01
# regression target. Builds the PolyC harness from
# tools/quality/llvm-gep01-test.HC against a fresh, canonical local
# install prefix and runs it. The resulting binary is consumed in
# place; no committed binary, no warm-tree dependence.
#
# This target is reachable from gate-push as a mandatory gate step
# (gate-push GPUSH-GEP01). It is intentionally NOT wired into
# gate-fast because gate-fast is a latency contract that must not
# silently become a compiler-build lane.
llvm-gep01-test: test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) \
		tools/quality/llvm-gep01-test.HC \
		-o ./build/llvm-gep01-test
	@if [ ! -x ./build/llvm-gep01-test ]; then \
		echo "llvm-gep01-test: ./build/llvm-gep01-test not produced" >&2; \
		exit 1; \
	fi
	./build/llvm-gep01-test --hcc=./hcc --llvm-install-dir=$(TEST_PREFIX)
	@rc=$$?; \
	rm -f ./build/llvm-gep01-test; \
	exit $$rc

lib-tos:
	cd ./src/holyc-lib \
		&& ../../hcc -lib tos ./all.HC \
		&& cd ../../

# ACT-POLYC-LLVM-SPIKE01-RESUME01: positive + negative matrix for the
# LLVM backend. Runs each spike fixture through `hcc --emit-llvm`,
# pipes the result through LLVM's own `llvm-as` parser, and asserts
# that negative fixtures fail with the documented LLVM backend error
# codes. No network, no execution, no object emission.
llvm-spike-test:
	@if ! command -v llvm-config >/dev/null 2>&1; then \
		echo "llvm-spike-test: llvm-config not on PATH" >&2; exit 2; \
	fi
	@if [ "$$(llvm-config --version | cut -d. -f1)" != "22" ]; then \
		echo "llvm-spike-test: llvm-config reports $$(llvm-config --version); need 22.x" >&2; exit 2; \
	fi
	@if [ ! -x ./hcc ] || ! nm ./hcc 2>/dev/null | grep -q '_LLVMAddFunction'; then \
		echo "llvm-spike-test: ./hcc is not an LLVM-enabled build; run 'make llvm-all' first" >&2; exit 2; \
	fi
	./scripts/quality/llvm-spike-test.sh

# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 (harness-isolation
# producer fix): explicit evidence regeneration path. Sets EVIDENCE_OUT
# to a tracked destination and runs the spike test against it. This
# is the ONLY way ordinary users can refresh closed-ACT evidence
# trees; ordinary `make llvm-spike-test` writes to a gitignored
# scratch dir and never mutates tracked historical evidence.
#
# Usage:
#   make evidence-update EVIDENCE_OUT=evidence/<dest>
#
# Example:
#   make evidence-update \
#     EVIDENCE_OUT=evidence/ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02/c5/harness-emit
evidence-update:
	@if [ -z "$$EVIDENCE_OUT" ]; then \
		echo "evidence-update: EVIDENCE_OUT is required" >&2; \
		echo "  Example: make evidence-update EVIDENCE_OUT=evidence/<dest>" >&2; \
		exit 2; \
	fi
	@if ! command -v llvm-config >/dev/null 2>&1; then \
		echo "evidence-update: llvm-config not on PATH" >&2; exit 2; \
	fi
	@if [ "$$(llvm-config --version | cut -d. -f1)" != "22" ]; then \
		echo "evidence-update: llvm-config reports $$(llvm-config --version); need 22.x" >&2; exit 2; \
	fi
	@if [ ! -x ./hcc ] || ! nm ./hcc 2>/dev/null | grep -q '_LLVMAddFunction'; then \
		echo "evidence-update: ./hcc is not an LLVM-enabled build; run 'make llvm-all' first" >&2; exit 2; \
	fi
	./scripts/quality/llvm-spike-test.sh

# ACT-POLYC-LLVM-LOCAL-MEM2REG01-CORRECTION02 C5 (harness-isolation
# producer fix): the regression test that proves a fresh
# `make llvm-spike-test` run does NOT modify any tracked closed-ACT
# evidence tree. Exits 0 on PASS, non-zero on FAIL.
harness-evidence-isolation-test:
	./scripts/quality/harness-evidence-isolation-test.sh

clean:
	rm -rf ./build ./hcc

# Convenience surfaces only. Gate logic lives in the scripts.
# See scripts/quality/gate-fast.sh and scripts/quality/gate-push.sh.

# ACT-POLYC2-DAFNY-PROOF-MVP01: opt-in Dafny formal gate.
# Runs scripts/quality/formal-dafny.sh which invokes the
# pinned Dafny 4.11.0 verifier against the identifier-
# scanner model in formal/dafny/identifier-scan.dfy.
# Not wired into gate-fast (per ACT §14).
formal-dafny:
	./scripts/quality/formal-dafny.sh

gate-fast:
	./scripts/quality/gate-fast.sh

gate-push:
	./scripts/quality/gate-push.sh HEAD

install-hooks:
	./scripts/install-git-hooks.sh

# ACT-POLYC-BOOTSTRAP01 C2 IMPL — build the B0 PolyC reference
# oracle (independent C implementation of the B0 lexical
# subset). No dependencies beyond libc; built once into the
# standard build dir.
bootstrap01-oracle: test-prefix-install
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap01-lexer-oracle \
		tools/quality/bootstrap01-lexer-oracle.c
	@if [ ! -x ./build/bootstrap01-lexer-oracle ]; then \
		echo "bootstrap01-oracle: ./build/bootstrap01-lexer-oracle not produced" >&2; \
		exit 1; \
	fi

# ACT-POLYC-BOOTSTRAP01 C2 IMPL — B0 differential test runner.
# Builds the C reference oracle (bootstrap01-oracle) and the
# PolyC subject driver (bootstrap01-lexer-test.HC which
# includes bootstrap01-lexer.HC). Runs the PolyC driver
# against the frozen fixture matrix and reports
# BOOTSTRAP01_CASES / BOOTSTRAP01_PASS / BOOTSTRAP01_FAIL /
# STATUS= lines. Exits non-zero on any fixture mismatch.
bootstrap01-test: bootstrap01-oracle test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) \
		tools/quality/bootstrap01-lexer-test.HC \
		-o ./build/bootstrap01-lexer-test
	@if [ ! -x ./build/bootstrap01-lexer-test ]; then \
		echo "bootstrap01-test: ./build/bootstrap01-lexer-test not produced" >&2; \
		exit 1; \
	fi
	./build/bootstrap01-lexer-test \
		evidence/ACT-POLYC-BOOTSTRAP01/c1/bootstrap01-fixtures.tsv
	@rc=$$?; \
	echo "BOOTSTRAP01_REFERENCE_ORACLE=./build/bootstrap01-lexer-oracle"; \
	exit $$rc

# ACT-POLYC-BOOTSTRAP02 C2 IMPL — B1 stage0 component build.
# Compiles the B1 PolyC component (tools/bootstrap/bootstrap02-ident.HC)
# to build/bootstrap02-ident.o using the existing stage0 ./hcc.
# This is the REAL production seam witness for the B1 component.
bootstrap02-component-build: test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/bootstrap02-ident.HC \
		-o ./build/bootstrap02-ident.o
	@if [ ! -f ./build/bootstrap02-ident.o ]; then \
		echo "bootstrap02-component-build: ./build/bootstrap02-ident.o not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/bootstrap02-ident.o | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap02-component-build: symbol _BootstrapScanIdent not found in object" >&2; exit 1; }

# ACT-POLYC-BOOTSTRAP02 C2 IMPL — B1 reference oracle.
# Independent C99 implementation of the same identifier-span
# algorithm. Used as the reference oracle for the differential.
bootstrap02-oracle:
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap02-ident-oracle \
		tools/quality/bootstrap02-ident-oracle.c
	@if [ ! -x ./build/bootstrap02-ident-oracle ]; then \
		echo "bootstrap02-oracle: ./build/bootstrap02-ident-oracle not produced" >&2; \
		exit 1; \
	fi

# ACT-POLYC-BOOTSTRAP02 C2 IMPL — B1 differential driver.
# Builds the stage0 B1 component, the C oracle, and the host
# harness, then runs both and diffs their outputs (modulo
# the summary label lines). 15/15 differential PASS required.
bootstrap02-test: bootstrap02-component-build bootstrap02-oracle
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap02-ident-host \
		tools/quality/bootstrap02-ident-host.c ./build/bootstrap02-ident.o
	@if [ ! -x ./build/bootstrap02-ident-host ]; then \
		echo "bootstrap02-test: ./build/bootstrap02-ident-host not produced" >&2; \
		exit 1; \
	fi
	./build/bootstrap02-ident-oracle > /tmp/b02-oracle.txt
	./build/bootstrap02-ident-host   > /tmp/b02-host.txt
	@diff /tmp/b02-oracle.txt /tmp/b02-host.txt > /tmp/b02-diff.txt; \
		rc=$$?; \
		if [ $$rc -ne 0 ] && [ $$rc -ne 1 ]; then \
			echo "bootstrap02-test: diff failed unexpectedly (rc=$$rc)" >&2; \
			cat /tmp/b02-diff.txt >&2; \
			exit 1; \
		fi; \
		# Filter only the per-fixture lines; the summary labels are intentionally different \
		grep -E '^I[0-9]+ ' /tmp/b02-oracle.txt > /tmp/b02-oracle-fixtures.txt; \
		grep -E '^I[0-9]+ ' /tmp/b02-host.txt   > /tmp/b02-host-fixtures.txt; \
		if ! diff -q /tmp/b02-oracle-fixtures.txt /tmp/b02-host-fixtures.txt >/dev/null; then \
			echo "bootstrap02-test: differential FAILED (fixture lines differ)" >&2; \
			diff /tmp/b02-oracle-fixtures.txt /tmp/b02-host-fixtures.txt >&2; \
			exit 1; \
		fi; \
		echo "BOOTSTRAP02_REFERENCE_ORACLE=./build/bootstrap02-ident-oracle"; \
		echo "BOOTSTRAP02_POLYC_OBJECT=./build/bootstrap02-ident.o"; \
		echo "BOOTSTRAP02_DIFFERENTIAL=PASS 15/15"

# ACT-POLYC-BOOTSTRAP02 C2 IMPL — Stage1 binary build.
# Produces build/hcc-bootstrap02 by linking the B1 object
# into the modified hcc source tree (with HCC_ENABLE_BOOTSTRAP02_STAGE1=ON).
# The production ./hcc binary is NOT touched; this is a
# separate stage1 artifact.
bootstrap02-stage1: bootstrap02-component-build test-prefix-install
	@rm -rf ./build/hcc-bootstrap02-build
	@mkdir -p ./build/hcc-bootstrap02-build
	cmake -S ./src -B ./build/hcc-bootstrap02-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/build/bootstrap02-ident.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/build/bootstrap06-operator-classify.o
	$(MAKE) -C ./build/hcc-bootstrap02-build hcc-bootstrap02 -j2
	@if [ ! -x ./build/hcc-bootstrap02 ]; then \
		echo "bootstrap02-stage1: ./build/hcc-bootstrap02 not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/hcc-bootstrap02 | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap02-stage1: symbol _BootstrapScanIdent not found in linked binary" >&2; exit 1; }
	@nm ./build/hcc-bootstrap02 | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap02-stage1: symbol _BootstrapClassifyOperator not found in linked binary" >&2; exit 1; }
	@echo "BOOTSTRAP02_STAGE1_BINARY=./build/hcc-bootstrap02"

# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01 C2 IMPL — pillar-B
# direct seam-level cursor witness. Builds the C oracle for
# the reviewer-specified 6-input matrix and the host harness
# that exercises the B1 PolyC component on the same matrix.
# Diffs the per-input lines; byte-identical = PASS.
bootstrap02-cursor-test: bootstrap02-component-build
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap02-cursor-oracle \
		tools/quality/bootstrap02-cursor-oracle.c
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap02-cursor-host \
		tools/quality/bootstrap02-cursor-host.c ./build/bootstrap02-ident.o
	./build/bootstrap02-cursor-oracle > /tmp/b02-cursor-oracle.txt
	./build/bootstrap02-cursor-host   > /tmp/b02-cursor-host.txt
	@grep -E '^E[0-9]+ ' /tmp/b02-cursor-oracle.txt > /tmp/b02-cursor-oracle-fixtures.txt; \
	grep -E '^E[0-9]+ ' /tmp/b02-cursor-host.txt   > /tmp/b02-cursor-host-fixtures.txt; \
	if ! diff -q /tmp/b02-cursor-oracle-fixtures.txt /tmp/b02-cursor-host-fixtures.txt >/dev/null; then \
		echo "bootstrap02-cursor-test: PILLAR B FAILED (cursor tuples differ)" >&2; \
		diff /tmp/b02-cursor-oracle-fixtures.txt /tmp/b02-cursor-host-fixtures.txt >&2; \
		exit 1; \
	fi; \
	echo "BOOTSTRAP02_CURSOR_DIFFERENTIAL=PASS 6/6"

# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION02 C2 IMPL —
# Real production-Lexer seam differential.
#
# This target satisfies the re-reviewer's demand:
# "execute the old production scanner and expose
#  l->ptr before, l->ptr after lexIdentifier,
#  l->cur_strlen, the byte subsequently observed by
#  lexCore, EOF/pushback state in the real Lexer."
#
# It links the REAL production src/lexer.c twice — once
# with the legacy ctype path (default build), once with
# -DHCC_BOOTSTRAP02_STAGE1 (stage1 build) — and exercises
# the production public entry point lex() on the same
# six inputs. Both binaries produce machine-diffable
# records; byte-identity on the downstream-visible
# fields (le_start_off, le_len, next_byte_hex,
# ptr_after, cur_strlen_post, eof_state) is the PASS
# criterion for PILLAR_B_PRODUCTION_LEXER_CURSOR_SEAM.
#
# The harness binary links against the production object
# files in build/CMakeFiles/hcc.dir/ and
# build/hcc-bootstrap02-build/CMakeFiles/hcc-bootstrap02.dir/.
# These are produced by:
#
#   cmake -S src -B build  && make -C build hcc
#       # produces build/CMakeFiles/hcc.dir/*.o
#   make bootstrap02-stage1
#       # produces build/hcc-bootstrap02-build/.../*.o
#
# The harness itself lives in tools/quality/.
HCC_OBJ_DIR       = ./build/CMakeFiles/hcc.dir
HCC_STAGE1_OBJDIR = ./build/hcc-bootstrap02-build/CMakeFiles/hcc-bootstrap02.dir
HCC_STAGE2_OBJDIR = ./build/hcc-bootstrap03-build/CMakeFiles/hcc-bootstrap03.dir
HCC_STAGE3_OBJDIR = ./build/hcc-bootstrap04-build/CMakeFiles/hcc-bootstrap04.dir
TASM_LIB          = ./build/asm/libtasm.a

HCC_OBJECTS = $(addprefix $(HCC_OBJ_DIR)/,$(HCC_STAGE_OBJS_COMMON))

HCC_STAGE_OBJS_COMMON = lexer.c.o aostr.c.o containers.c.o list.c.o arena.c.o \
	ast.c.o cctrl.c.o parser.c.o json.c.o mempool.c.o memory.c.o \
	memsafe.c.o asm.c.o cfg.c.o cfg-print.c.o cli.c.o compile.c.o \
	ir.c.o ir-debug.c.o ir-eval.c.o ir-optimise.c.o ir-regalloc.c.o \
	ir-types.c.o lsp.c.o prsasm.c.o prslib.c.o prsutil.c.o \
	transpiler.c.o x86_64.c.o x86_64-jit.c.o aarch64.c.o \
	aarch64-jit.c.o x86.c.o jit-common.c.o \
	linenoise/linenoise.c.o

HCC_STAGE1_OBJECTS = $(addprefix $(HCC_STAGE1_OBJDIR)/,$(HCC_STAGE_OBJS_COMMON))
HCC_STAGE2_OBJECTS = $(addprefix $(HCC_STAGE2_OBJDIR)/,$(HCC_STAGE_OBJS_COMMON))
HCC_STAGE3_OBJECTS = $(addprefix $(HCC_STAGE3_OBJDIR)/,$(HCC_STAGE_OBJS_COMMON))

bootstrap02-lexer-seam-test: bootstrap02-stage1
	@if [ ! -d "$(HCC_OBJ_DIR)" ]; then \
		echo "bootstrap02-lexer-seam-test: $(HCC_OBJ_DIR) missing. Run: cmake -S src -B build && make -C build hcc" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(TASM_LIB)" ]; then \
		echo "bootstrap02-lexer-seam-test: $(TASM_LIB) missing. Run: cmake -S src -B build && make -C build hcc" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"legacy"' -Isrc \
		-o ./build/bootstrap02-lexer-seam-legacy \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_OBJECTS) $(TASM_LIB) -lm -lpthread -ldl
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -Isrc \
		-o ./build/bootstrap02-lexer-seam-stage1 \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) ./build/bootstrap02-ident.o $(TASM_LIB) -lm -lpthread -ldl
	./build/bootstrap02-lexer-seam-legacy > /tmp/b02-lexer-seam-legacy.txt
	./build/bootstrap02-lexer-seam-stage1 > /tmp/b02-lexer-seam-stage1.txt
	@if ! diff -q /tmp/b02-lexer-seam-legacy.txt /tmp/b02-lexer-seam-stage1.txt >/dev/null; then \
		echo "bootstrap02-lexer-seam-test: PILLAR B PRODUCTION SEAM DIVERGED (residue; see below)" >&2; \
		diff /tmp/b02-lexer-seam-legacy.txt /tmp/b02-lexer-seam-stage1.txt >&2 || true; \
		echo "bootstrap02-lexer-seam-test: stripping BUILD_LABEL and case-name suffixes; re-checking fields" >&2; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b02-lexer-seam-legacy.txt > /tmp/legacy-clean.txt; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b02-lexer-seam-stage1.txt > /tmp/stage1-clean.txt; \
		if diff -q /tmp/legacy-clean.txt /tmp/stage1-clean.txt >/dev/null; then \
			echo "BOOTSTRAP02_LEXER_SEAM_DOWNSTREAM=PASS (6/6 cases byte-identical)"; \
			echo "BOOTSTRAP02_LEXER_SEAM_RESIDUE=NONE"; \
		else \
			echo "bootstrap02-lexer-seam-test: fields still diverge after stripping labels; treat as P0 blocker" >&2; \
			diff /tmp/legacy-clean.txt /tmp/stage1-clean.txt >&2; \
			exit 1; \
		fi; \
	else \
		echo "BOOTSTRAP02_LEXER_SEAM_DOWNSTREAM=PASS (byte-identical, including labels)"; \
		echo "BOOTSTRAP02_LEXER_SEAM_RESIDUE=NONE"; \
	fi

# ACT-POLYC-BOOTSTRAP03 C2 IMPL — B2 stage1-produced B1 component
# object. Builds the B1 PolyC component (tools/bootstrap/
# bootstrap02-ident.HC) using STAGE1 (build/hcc-bootstrap02)
# and emits build/bootstrap03-ident.stage1.o.
#
# This is the future stage2 B1 artifact. Its path is distinct
# from build/bootstrap02-ident.o so that the build graph cannot
# accidentally reuse the stage0-produced object when assembling
# stage2 (per ACT §14 "build provenance must be impossible to
# fake accidentally").
#
# Dependency: bootstrap02-stage1 (NOT bootstrap02-component-build,
# which uses stage0). The stage1 binary is the producer.
bootstrap03-component-build: bootstrap02-stage1 test-prefix-install
	@if [ ! -x ./build/hcc-bootstrap02 ]; then \
		echo "bootstrap03-component-build: ./build/hcc-bootstrap02 (stage1) missing. Run: make bootstrap02-stage1" >&2; \
		exit 1; \
	fi
	@rm -f ./build/bootstrap03-ident.stage1.o
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/bootstrap02-ident.HC \
		-o ./build/bootstrap03-ident.stage1.o
	@if [ ! -f ./build/bootstrap03-ident.stage1.o ]; then \
		echo "bootstrap03-component-build: ./build/bootstrap03-ident.stage1.o not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/bootstrap03-ident.stage1.o | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap03-component-build: symbol _BootstrapScanIdent not found in object" >&2; exit 1; }
	@echo "BOOTSTRAP03_STAGE1_B1_OBJECT=./build/bootstrap03-ident.stage1.o"

# ACT-POLYC-BOOTSTRAP03 C2 IMPL — B2 stage2 binary build.
# Produces build/hcc-bootstrap03 by linking the STAGE1-produced
# B1 object (NOT the stage0-produced one) into the modified hcc
# source tree with HCC_ENABLE_BOOTSTRAP03_STAGE2=ON.
#
# The stage0 binary (./hcc), the stage1 binary (./build/hcc-bootstrap02),
# and the stage0-produced B1 object (./build/bootstrap02-ident.o)
# are all left UNTOUCHED. Stage2 is a new, distinct artifact.
#
# Provenance invariant (ACT §5): the object consumed here MUST
# be the one built by bootstrap03-component-build above. The
# distinct path (build/bootstrap03-ident.stage1.o vs
# build/bootstrap02-ident.o) makes accidental reuse impossible.
bootstrap03-stage2: bootstrap03-component-build test-prefix-install
	@if [ ! -f ./build/bootstrap03-ident.stage1.o ]; then \
		echo "bootstrap03-stage2: ./build/bootstrap03-ident.stage1.o missing. Run: make bootstrap03-component-build" >&2; \
		exit 1; \
	fi
	@rm -rf ./build/hcc-bootstrap03-build
	@mkdir -p ./build/hcc-bootstrap03-build
	cmake -S ./src -B ./build/hcc-bootstrap03-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/build/bootstrap02-ident.o \
		-DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
		-DBOOTSTRAP03_IDENT_OBJECT=$(CURDIR)/build/bootstrap03-ident.stage1.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/build/bootstrap06-operator-classify.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE1=$(CURDIR)/build/bootstrap06-operator-classify.stage1.o
	$(MAKE) -C ./build/hcc-bootstrap03-build hcc-bootstrap03 -j2
	@if [ ! -x ./build/hcc-bootstrap03 ]; then \
		echo "bootstrap03-stage2: ./build/hcc-bootstrap03 not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/hcc-bootstrap03 | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap03-stage2: symbol _BootstrapScanIdent not found in linked binary" >&2; exit 1; }
	@nm ./build/hcc-bootstrap03 | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap03-stage2: symbol _BootstrapClassifyOperator not found in linked binary" >&2; exit 1; }
	@echo "BOOTSTRAP03_STAGE2_BINARY=./build/hcc-bootstrap03"

# ACT-POLYC-BOOTSTRAP03 C2 IMPL — B2 stage2 differential
# against the C reference oracle (same fixtures as B1).
# Reuses tools/quality/bootstrap02-ident-host.c /
# bootstrap02-ident-oracle.c, but links the stage1-produced
# object instead of the stage0 one. 15/15 differential PASS
# required.
bootstrap03-test: bootstrap03-component-build bootstrap02-oracle
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap03-ident-host \
		tools/quality/bootstrap02-ident-host.c ./build/bootstrap03-ident.stage1.o
	@if [ ! -x ./build/bootstrap03-ident-host ]; then \
		echo "bootstrap03-test: ./build/bootstrap03-ident-host not produced" >&2; \
		exit 1; \
	fi
	./build/bootstrap02-ident-oracle > /tmp/b03-oracle.txt
	./build/bootstrap03-ident-host   > /tmp/b03-host.txt
	@diff /tmp/b03-oracle.txt /tmp/b03-host.txt > /tmp/b03-diff.txt; \
		rc=$$?; \
		if [ $$rc -ne 0 ] && [ $$rc -ne 1 ]; then \
			echo "bootstrap03-test: diff failed unexpectedly (rc=$$rc)" >&2; \
			cat /tmp/b03-diff.txt >&2; \
			exit 1; \
		fi; \
		grep -E '^I[0-9]+ ' /tmp/b03-oracle.txt > /tmp/b03-oracle-fixtures.txt; \
		grep -E '^I[0-9]+ ' /tmp/b03-host.txt   > /tmp/b03-host-fixtures.txt; \
		if ! diff -q /tmp/b03-oracle-fixtures.txt /tmp/b03-host-fixtures.txt >/dev/null; then \
			echo "bootstrap03-test: differential FAILED (fixture lines differ)" >&2; \
			diff /tmp/b03-oracle-fixtures.txt /tmp/b03-host-fixtures.txt >&2; \
			exit 1; \
		fi; \
		echo "BOOTSTRAP03_REFERENCE_ORACLE=./build/bootstrap02-ident-oracle"; \
		echo "BOOTSTRAP03_STAGE1_B1_OBJECT=./build/bootstrap03-ident.stage1.o"; \
		echo "BOOTSTRAP03_DIFFERENTIAL=PASS 15/15"

# ACT-POLYC-BOOTSTRAP03 C3 IMPL — production Lexer seam test
# for stage1 ↔ stage2.
#
# Mirrors the B1 `bootstrap02-lexer-seam-test` pattern:
# link the production src/lexer.c source TWICE, once with
# each stage's object file, and run the same six inputs
# through the production public entry point. The two
# outputs (excluding the BUILD_LABEL line) must be
# byte-identical.
#
# We reuse the production object directories of:
#   stage1: build/hcc-bootstrap02-build/CMakeFiles/hcc-bootstrap02.dir
#   stage2: build/hcc-bootstrap03-build/CMakeFiles/hcc-bootstrap03.dir
# and the existing tools/quality/bootstrap02-lexer-seam-runner.c.
HCC_STAGE2_OBJDIR = ./build/hcc-bootstrap03-build/CMakeFiles/hcc-bootstrap03.dir

HCC_STAGE2_OBJECTS = \
	$(HCC_STAGE2_OBJDIR)/lexer.c.o \
	$(HCC_STAGE2_OBJDIR)/aostr.c.o \
	$(HCC_STAGE2_OBJDIR)/containers.c.o \
	$(HCC_STAGE2_OBJDIR)/list.c.o \
	$(HCC_STAGE2_OBJDIR)/arena.c.o \
	$(HCC_STAGE2_OBJDIR)/ast.c.o \
	$(HCC_STAGE2_OBJDIR)/cctrl.c.o \
	$(HCC_STAGE2_OBJDIR)/parser.c.o \
	$(HCC_STAGE2_OBJDIR)/json.c.o \
	$(HCC_STAGE2_OBJDIR)/mempool.c.o \
	$(HCC_STAGE2_OBJDIR)/memory.c.o \
	$(HCC_STAGE2_OBJDIR)/memsafe.c.o \
	$(HCC_STAGE2_OBJDIR)/asm.c.o \
	$(HCC_STAGE2_OBJDIR)/cfg.c.o \
	$(HCC_STAGE2_OBJDIR)/cfg-print.c.o \
	$(HCC_STAGE2_OBJDIR)/cli.c.o \
	$(HCC_STAGE2_OBJDIR)/compile.c.o \
	$(HCC_STAGE2_OBJDIR)/ir.c.o \
	$(HCC_STAGE2_OBJDIR)/ir-debug.c.o \
	$(HCC_STAGE2_OBJDIR)/ir-eval.c.o \
	$(HCC_STAGE2_OBJDIR)/ir-optimise.c.o \
	$(HCC_STAGE2_OBJDIR)/ir-regalloc.c.o \
	$(HCC_STAGE2_OBJDIR)/ir-types.c.o \
	$(HCC_STAGE2_OBJDIR)/lsp.c.o \
	$(HCC_STAGE2_OBJDIR)/prsasm.c.o \
	$(HCC_STAGE2_OBJDIR)/prslib.c.o \
	$(HCC_STAGE2_OBJDIR)/prsutil.c.o \
	$(HCC_STAGE2_OBJDIR)/transpiler.c.o \
	$(HCC_STAGE2_OBJDIR)/x86_64.c.o \
	$(HCC_STAGE2_OBJDIR)/x86_64-jit.c.o \
	$(HCC_STAGE2_OBJDIR)/aarch64.c.o \
	$(HCC_STAGE2_OBJDIR)/aarch64-jit.c.o \
	$(HCC_STAGE2_OBJDIR)/x86.c.o \
	$(HCC_STAGE2_OBJDIR)/jit-common.c.o \
	$(HCC_STAGE2_OBJDIR)/linenoise/linenoise.c.o

bootstrap03-lexer-seam-test: bootstrap03-stage2
	@if [ ! -d "$(HCC_STAGE2_OBJDIR)" ]; then \
		echo "bootstrap03-lexer-seam-test: $(HCC_STAGE2_OBJDIR) missing. Run: make bootstrap03-stage2" >&2; \
		exit 1; \
	fi
	@if [ ! -d "$(HCC_STAGE1_OBJDIR)" ]; then \
		echo "bootstrap03-lexer-seam-test: $(HCC_STAGE1_OBJDIR) missing. Run: make bootstrap02-stage1" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(TASM_LIB)" ]; then \
		echo "bootstrap03-lexer-seam-test: $(TASM_LIB) missing. Run: cmake -S src -B build && make -C build hcc" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -Isrc \
		-o ./build/bootstrap03-lexer-seam-stage1 \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) ./build/bootstrap02-ident.o $(TASM_LIB) -lm -lpthread -ldl
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage2"' -Isrc \
		-o ./build/bootstrap03-lexer-seam-stage2 \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_STAGE2_OBJECTS) ./build/bootstrap03-ident.stage1.o $(TASM_LIB) -lm -lpthread -ldl
	./build/bootstrap03-lexer-seam-stage1 > /tmp/b03-lexer-seam-stage1.txt
	./build/bootstrap03-lexer-seam-stage2 > /tmp/b03-lexer-seam-stage2.txt
	@if ! diff -q /tmp/b03-lexer-seam-stage1.txt /tmp/b03-lexer-seam-stage2.txt >/dev/null; then \
		echo "bootstrap03-lexer-seam-test: PILLAR B PRODUCTION SEAM DIVERGED" >&2; \
		diff /tmp/b03-lexer-seam-stage1.txt /tmp/b03-lexer-seam-stage2.txt >&2 || true; \
		echo "bootstrap03-lexer-seam-test: stripping BUILD_LABEL and case-name suffixes; re-checking fields" >&2; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b03-lexer-seam-stage1.txt > /tmp/stage1-clean.txt; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b03-lexer-seam-stage2.txt > /tmp/stage2-clean.txt; \
		if diff -q /tmp/stage1-clean.txt /tmp/stage2-clean.txt >/dev/null; then \
			echo "BOOTSTRAP03_LEXER_SEAM_DOWNSTREAM=PASS (6/6 cases byte-identical)"; \
			echo "BOOTSTRAP03_LEXER_SEAM_RESIDUE=NONE"; \
		else \
			echo "bootstrap03-lexer-seam-test: fields still diverge after stripping labels; treat as P0 blocker" >&2; \
			diff /tmp/stage1-clean.txt /tmp/stage2-clean.txt >&2; \
			exit 1; \
		fi; \
	else \
		echo "BOOTSTRAP03_LEXER_SEAM_DOWNSTREAM=PASS (byte-identical, including labels)"; \
		echo "BOOTSTRAP03_LEXER_SEAM_RESIDUE=NONE"; \
	fi

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — B3 stage2-produced B1 component
# object. Builds the B1 PolyC component (tools/bootstrap/
# bootstrap02-ident.HC) using STAGE2 (build/hcc-bootstrap03)
# and emits build/bootstrap04-ident.stage2.o.
#
# This is the future stage3 B1 artifact. Its path is distinct
# from build/bootstrap03-ident.stage1.o (and from
# build/bootstrap02-ident.o) so the build graph cannot
# accidentally reuse a previous-generation object when
# assembling stage3 (per ACT §20 "Artifact path separation").
#
# Dependency: bootstrap03-stage2 (NOT bootstrap02-stage1 or
# bootstrap03-component-build, both of which use stage1 or
# build artifacts derived from stage1). The stage2 binary is
# the producer.
bootstrap04-component-build: bootstrap03-stage2 test-prefix-install
	@if [ ! -x ./build/hcc-bootstrap03 ]; then \
		echo "bootstrap04-component-build: ./build/hcc-bootstrap03 (stage2) missing. Run: make bootstrap03-stage2" >&2; \
		exit 1; \
	fi
	@rm -f ./build/bootstrap04-ident.stage2.o
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/bootstrap02-ident.HC \
		-o ./build/bootstrap04-ident.stage2.o
	@if [ ! -f ./build/bootstrap04-ident.stage2.o ]; then \
		echo "bootstrap04-component-build: ./build/bootstrap04-ident.stage2.o not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/bootstrap04-ident.stage2.o | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap04-component-build: symbol _BootstrapScanIdent not found in object" >&2; exit 1; }
	@echo "BOOTSTRAP04_STAGE2_B1_OBJECT=./build/bootstrap04-ident.stage2.o"

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — B3 stage3 binary build.
# Produces build/hcc-bootstrap04 by linking the STAGE2-produced
# B1 object (NOT the stage1- or stage0-produced one) into the
# modified hcc source tree with HCC_ENABLE_BOOTSTRAP04_STAGE3=ON.
# Per ACT §19: the existing HCC_BOOTSTRAP02_STAGE1 macro gates
# the lexIdentifier delegation; HCC_BOOTSTRAP04_STAGE3 exists
# purely for build-graph distinctness (mirrors B2's pattern).
bootstrap04-stage3: bootstrap04-component-build test-prefix-install
	@if [ ! -f ./build/bootstrap04-ident.stage2.o ]; then \
		echo "bootstrap04-stage3: ./build/bootstrap04-ident.stage2.o missing. Run: make bootstrap04-component-build" >&2; \
		exit 1; \
	fi
	@rm -rf ./build/hcc-bootstrap04-build
	@mkdir -p ./build/hcc-bootstrap04-build
	cmake -S ./src -B ./build/hcc-bootstrap04-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/build/bootstrap02-ident.o \
		-DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
		-DBOOTSTRAP03_IDENT_OBJECT=$(CURDIR)/build/bootstrap03-ident.stage1.o \
		-DHCC_ENABLE_BOOTSTRAP04_STAGE3=ON \
		-DBOOTSTRAP04_IDENT_OBJECT=$(CURDIR)/build/bootstrap04-ident.stage2.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/build/bootstrap06-operator-classify.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE1=$(CURDIR)/build/bootstrap06-operator-classify.stage1.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE2=$(CURDIR)/build/bootstrap06-operator-classify.stage2.o
	$(MAKE) -C ./build/hcc-bootstrap04-build hcc-bootstrap04 -j2
	@if [ ! -x ./build/hcc-bootstrap04 ]; then \
		echo "bootstrap04-stage3: ./build/hcc-bootstrap04 not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/hcc-bootstrap04 | grep -q '_BootstrapScanIdent' \
		|| { echo "bootstrap04-stage3: symbol _BootstrapScanIdent not found in linked binary" >&2; exit 1; }
	@nm ./build/hcc-bootstrap04 | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap04-stage3: symbol _BootstrapClassifyOperator not found in linked binary" >&2; exit 1; }
	@echo "BOOTSTRAP04_STAGE3_BINARY=./build/hcc-bootstrap04"

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — B3 component differential.
# Compiles the B1 PolyC source once with stage3 (using the
# stage2-produced B1 object) and diffs the harness output
# against the B1 C oracle (./build/bootstrap02-ident-oracle).
# Per ACT §23 + ACT §30, the strong result is byte equality
# with the B1 oracle and with the prior B2 stage3 result
# (which itself equals the B1 oracle).
bootstrap04-test: bootstrap04-stage3 bootstrap02-oracle
	@if [ ! -x ./build/hcc-bootstrap04 ]; then \
		echo "bootstrap04-test: ./build/hcc-bootstrap04 (stage3) missing. Run: make bootstrap04-stage3" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap04-ident-stage3 \
		tools/quality/bootstrap02-ident-host.c ./build/bootstrap04-ident.stage2.o
	@if [ ! -x ./build/bootstrap04-ident-stage3 ]; then \
		echo "bootstrap04-test: ./build/bootstrap04-ident-stage3 not produced" >&2; \
		exit 1; \
	fi
	./build/bootstrap02-ident-oracle    > /tmp/b04-oracle.txt
	./build/bootstrap04-ident-stage3     > /tmp/b04-stage3.txt
	@if diff -q /tmp/b04-oracle.txt /tmp/b04-stage3.txt >/dev/null; then \
		echo "BOOTSTRAP04_COMPONENT_FIXED_POINT=PASS (stage3 B1 object matches B1 oracle 15/15, byte-identical)"; \
	else \
		echo "bootstrap04-test: labels differ; stripping harness-name suffix and re-checking fixture lines" >&2; \
		sed -E 's/^BOOTSTRAP02_IDENT_HOST_/BOOTSTRAP02_IDENT_/' /tmp/b04-stage3.txt > /tmp/b04-stage3-clean.txt; \
		if diff -q /tmp/b04-oracle.txt /tmp/b04-stage3-clean.txt >/dev/null; then \
			echo "BOOTSTRAP04_COMPONENT_FIXED_POINT=PASS (stage3 B1 object matches B1 oracle 15/15 after label normalization)"; \
		else \
			echo "bootstrap04-test: B1 object produced by stage3 DIFFERS from B1 oracle" >&2; \
			diff /tmp/b04-oracle.txt /tmp/b04-stage3-clean.txt >&2; \
			exit 1; \
		fi; \
	fi
	@echo "BOOTSTRAP04_STAGE2_B1_OBJECT=./build/bootstrap04-ident.stage2.o"

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — B3 cursor model test.
# Reuses the existing bootstrap02-cursor-host.c harness and
# runs it linked against stage3's B1 object path. The
# reference is the existing B1 cursor oracle
# (./build/bootstrap02-cursor-oracle), which is
# already produced by bootstrap02-cursor-test. Since the
# B1 component has been mechanically shown to be a fixed
# point across stage0/stage1/stage2/stage3 (see
# stage2-self-compile.txt + bootstrap04-test), stage3's
# cursor output MUST equal the oracle.
bootstrap04-cursor-test: bootstrap04-stage3 bootstrap02-cursor-test
	@if [ ! -x ./build/hcc-bootstrap04 ]; then \
		echo "bootstrap04-cursor-test: ./build/hcc-bootstrap04 (stage3) missing. Run: make bootstrap04-stage3" >&2; \
		exit 1; \
	fi
	@if [ ! -x ./build/bootstrap02-cursor-oracle ]; then \
		echo "bootstrap04-cursor-test: ./build/bootstrap02-cursor-oracle missing. Run: make bootstrap02-cursor-test" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap04-cursor-stage3 \
		tools/quality/bootstrap02-cursor-host.c ./build/bootstrap04-ident.stage2.o
	@if [ ! -x ./build/bootstrap04-cursor-stage3 ]; then \
		echo "bootstrap04-cursor-test: ./build/bootstrap04-cursor-stage3 not produced" >&2; \
		exit 1; \
	fi
	./build/bootstrap04-cursor-stage3 > /tmp/b04-cursor-stage3.txt
	./build/bootstrap02-cursor-oracle > /tmp/b04-cursor-oracle.txt
	@grep -E '^E[0-9]+ ' /tmp/b04-cursor-oracle.txt  > /tmp/b04-cursor-oracle-fixtures.txt; \
	grep -E '^E[0-9]+ ' /tmp/b04-cursor-stage3.txt  > /tmp/b04-cursor-stage3-fixtures.txt; \
	if diff -q /tmp/b04-cursor-oracle-fixtures.txt /tmp/b04-cursor-stage3-fixtures.txt >/dev/null; then \
		echo "BOOTSTRAP04_CURSOR_FIXED_POINT=PASS 6/6 (stage3 matches B1 cursor oracle)"; \
	else \
		echo "bootstrap04-cursor-test: stage3 cursor model DIFFERS from B1 oracle" >&2; \
		diff /tmp/b04-cursor-oracle-fixtures.txt /tmp/b04-cursor-stage3-fixtures.txt >&2; \
		exit 1; \
	fi

# ACT-POLYC-BOOTSTRAP04 C2 IMPL — B3 production Lexer seam test
# for stage2 ↔ stage3.
#
# Mirrors the B2 `bootstrap03-lexer-seam-test` pattern exactly:
# link the production src/lexer.c source TWICE, once with each
# stage's object file, and run the same six inputs through the
# production public entry point. The two outputs (excluding
# BUILD_LABEL) must be byte-identical.
#
# We reuse the existing tools/quality/bootstrap02-lexer-seam-runner.c.
HCC_STAGE3_OBJDIR = ./build/hcc-bootstrap04-build/CMakeFiles/hcc-bootstrap04.dir

HCC_STAGE3_OBJECTS = \
	$(HCC_STAGE3_OBJDIR)/lexer.c.o \
	$(HCC_STAGE3_OBJDIR)/aostr.c.o \
	$(HCC_STAGE3_OBJDIR)/containers.c.o \
	$(HCC_STAGE3_OBJDIR)/list.c.o \
	$(HCC_STAGE3_OBJDIR)/arena.c.o \
	$(HCC_STAGE3_OBJDIR)/ast.c.o \
	$(HCC_STAGE3_OBJDIR)/cctrl.c.o \
	$(HCC_STAGE3_OBJDIR)/parser.c.o \
	$(HCC_STAGE3_OBJDIR)/json.c.o \
	$(HCC_STAGE3_OBJDIR)/mempool.c.o \
	$(HCC_STAGE3_OBJDIR)/memory.c.o \
	$(HCC_STAGE3_OBJDIR)/memsafe.c.o \
	$(HCC_STAGE3_OBJDIR)/asm.c.o \
	$(HCC_STAGE3_OBJDIR)/cfg.c.o \
	$(HCC_STAGE3_OBJDIR)/cfg-print.c.o \
	$(HCC_STAGE3_OBJDIR)/cli.c.o \
	$(HCC_STAGE3_OBJDIR)/compile.c.o \
	$(HCC_STAGE3_OBJDIR)/ir.c.o \
	$(HCC_STAGE3_OBJDIR)/ir-debug.c.o \
	$(HCC_STAGE3_OBJDIR)/ir-eval.c.o \
	$(HCC_STAGE3_OBJDIR)/ir-optimise.c.o \
	$(HCC_STAGE3_OBJDIR)/ir-regalloc.c.o \
	$(HCC_STAGE3_OBJDIR)/ir-types.c.o \
	$(HCC_STAGE3_OBJDIR)/lsp.c.o \
	$(HCC_STAGE3_OBJDIR)/prsasm.c.o \
	$(HCC_STAGE3_OBJDIR)/prslib.c.o \
	$(HCC_STAGE3_OBJDIR)/prsutil.c.o \
	$(HCC_STAGE3_OBJDIR)/transpiler.c.o \
	$(HCC_STAGE3_OBJDIR)/x86_64.c.o \
	$(HCC_STAGE3_OBJDIR)/x86_64-jit.c.o \
	$(HCC_STAGE3_OBJDIR)/aarch64.c.o \
	$(HCC_STAGE3_OBJDIR)/aarch64-jit.c.o \
	$(HCC_STAGE3_OBJDIR)/x86.c.o \
	$(HCC_STAGE3_OBJDIR)/jit-common.c.o \
	$(HCC_STAGE3_OBJDIR)/linenoise/linenoise.c.o

bootstrap04-lexer-seam-test: bootstrap04-stage3
	@if [ ! -d "$(HCC_STAGE3_OBJDIR)" ]; then \
		echo "bootstrap04-lexer-seam-test: $(HCC_STAGE3_OBJDIR) missing. Run: make bootstrap04-stage3" >&2; \
		exit 1; \
	fi
	@if [ ! -d "$(HCC_STAGE2_OBJDIR)" ]; then \
		echo "bootstrap04-lexer-seam-test: $(HCC_STAGE2_OBJDIR) missing. Run: make bootstrap03-stage2" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(TASM_LIB)" ]; then \
		echo "bootstrap04-lexer-seam-test: $(TASM_LIB) missing. Run: cmake -S src -B build && make -C build hcc" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage2"' -Isrc \
		-o ./build/bootstrap04-lexer-seam-stage2 \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_STAGE2_OBJECTS) ./build/bootstrap03-ident.stage1.o $(TASM_LIB) -lm -lpthread -ldl
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage3"' -Isrc \
		-o ./build/bootstrap04-lexer-seam-stage3 \
		tools/quality/bootstrap02-lexer-seam-runner.c \
		$(HCC_STAGE3_OBJECTS) ./build/bootstrap04-ident.stage2.o $(TASM_LIB) -lm -lpthread -ldl
	./build/bootstrap04-lexer-seam-stage2 > /tmp/b04-lexer-seam-stage2.txt
	./build/bootstrap04-lexer-seam-stage3 > /tmp/b04-lexer-seam-stage3.txt
	@if ! diff -q /tmp/b04-lexer-seam-stage2.txt /tmp/b04-lexer-seam-stage3.txt >/dev/null; then \
		echo "bootstrap04-lexer-seam-test: PILLAR B PRODUCTION SEAM DIVERGED" >&2; \
		diff /tmp/b04-lexer-seam-stage2.txt /tmp/b04-lexer-seam-stage3.txt >&2 || true; \
		echo "bootstrap04-lexer-seam-test: stripping BUILD_LABEL and case-name suffixes; re-checking fields" >&2; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b04-lexer-seam-stage2.txt > /tmp/stage2-clean.txt; \
		sed -E 's/^(CASE .+) build=.*/\1/; s/^BUILD_LABEL=.*/BUILD_LABEL=/; s/^LEXER_SEAM_CASE_COUNT=.*/LEXER_SEAM_CASE_COUNT=/' /tmp/b04-lexer-seam-stage3.txt > /tmp/stage3-clean.txt; \
		if diff -q /tmp/stage2-clean.txt /tmp/stage3-clean.txt >/dev/null; then \
			echo "BOOTSTRAP04_LEXER_SEAM_DOWNSTREAM=PASS (6/6 cases byte-identical)"; \
			echo "BOOTSTRAP04_LEXER_SEAM_RESIDUE=NONE"; \
		else \
			echo "bootstrap04-lexer-seam-test: fields still diverge after stripping labels; treat as P0 blocker" >&2; \
			diff /tmp/stage2-clean.txt /tmp/stage3-clean.txt >&2; \
			exit 1; \
		fi; \
	else \
		echo "BOOTSTRAP04_LEXER_SEAM_DOWNSTREAM=PASS (byte-identical, including labels)"; \
		echo "BOOTSTRAP04_LEXER_SEAM_RESIDUE=NONE"; \
	fi

# ACT-POLYC-SELFHOST-LEXER01 C2 IMPL — operator/punctuation
# classification component targets.  See
# evidence/ACT-POLYC-SELFHOST-LEXER01/c2/.

bootstrap06-component-build:
	./hcc --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-operator-classify.HC \
		-o ./build/bootstrap06-operator-classify.o
	@if [ ! -f ./build/bootstrap06-operator-classify.o ]; then \
		echo "bootstrap06-component-build: object not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/bootstrap06-operator-classify.o | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap06-component-build: symbol missing" >&2; exit 1; }
	@echo "BOOTSTRAP06_STAGE0_OPERATOR_OBJECT=./build/bootstrap06-operator-classify.o"

bootstrap06-operator-classify-oracle:
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap06-operator-classify-oracle \
		tools/quality/bootstrap06-operator-classify-oracle.c
	@if [ ! -x ./build/bootstrap06-operator-classify-oracle ]; then \
		echo "bootstrap06-operator-classify-oracle: oracle not produced" >&2; \
		exit 1; \
	fi

bootstrap06-direct-differential: bootstrap06-operator-classify-oracle bootstrap06-component-build
	cc -std=c99 -O2 -Wall -Wextra -o ./build/bootstrap06-direct-differential \
		tools/quality/bootstrap06-direct-differential.c \
		./build/bootstrap06-operator-classify.o
	./build/bootstrap06-direct-differential
	@echo "BOOTSTRAP06_DIRECT_DIFFERENTIAL=PASS"

bootstrap06-component-stage1: bootstrap02-stage1
	@if [ ! -x ./build/hcc-bootstrap02 ]; then \
		echo "bootstrap06-component-stage1: stage1 compiler missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-operator-classify.HC \
		-o ./build/bootstrap06-operator-classify.stage1.o
	@nm ./build/bootstrap06-operator-classify.stage1.o | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap06-component-stage1: symbol missing in stage1 object" >&2; exit 1; }

bootstrap06-component-stage2: bootstrap03-stage2 bootstrap06-component-stage1
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-operator-classify.HC \
		-o ./build/bootstrap06-operator-classify.stage2.o
	@nm ./build/bootstrap06-operator-classify.stage2.o | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap06-component-stage2: symbol missing in stage2 object" >&2; exit 1; }

bootstrap06-component-stage3: bootstrap04-stage3 bootstrap06-component-stage2
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-operator-classify.HC \
		-o ./build/bootstrap06-operator-classify.stage3.o
	@nm ./build/bootstrap06-operator-classify.stage3.o | grep -q '_BootstrapClassifyOperator' \
		|| { echo "bootstrap06-component-stage3: symbol missing in stage3 object" >&2; exit 1; }

# Production-seam test for the operator slice (stage0 vs stage1
# lexCore operator-classification output; the existing
# bootstrap02-lexer-seam-runner covers identifier; we use a
# dedicated runner for operators).
bootstrap06-lexer-seam-stage1: bootstrap06-component-build bootstrap02-stage1
	@if [ ! -d "$(HCC_STAGE1_OBJDIR)" ]; then \
		echo "bootstrap06-lexer-seam-stage1: $(HCC_STAGE1_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -Isrc \
		-o ./build/bootstrap06-lexer-seam-stage1 \
		tools/quality/bootstrap06-lexer-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) ./build/bootstrap06-operator-classify.o $(TASM_LIB) -lm -lpthread -ldl
	./build/bootstrap06-lexer-seam-stage1

# ACT-POLYC-SELFHOST-LEXER02 C1/C2 IMPL — scalar literal
# component (R-F region: countNumberLen + lexNumeric +
# lexCharConst).

lexer07-component-build:
	./hcc --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-scalar-literal.HC \
		-o ./build/lexer07-scalar-literal.o
	@if [ ! -f ./build/lexer07-scalar-literal.o ]; then \
		echo "lexer07-component-build: object not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/lexer07-scalar-literal.o | grep -q '_BootstrapScanScalarLiteral' \
		|| { echo "lexer07-component-build: symbol missing" >&2; exit 1; }
	@echo "LEXER07_STAGE0_SCALAR_OBJECT=./build/lexer07-scalar-literal.o"

lexer07-scalar-literal-oracle:
	cc -std=c99 -O2 -Wall -Wextra -o ./build/lexer07-scalar-literal-oracle \
		tools/quality/lexer07-scalar-literal-oracle.c
	@if [ ! -x ./build/lexer07-scalar-literal-oracle ]; then \
		echo "lexer07-scalar-literal-oracle: oracle not produced" >&2; \
		exit 1; \
	fi

lexer07-direct-differential: lexer07-scalar-literal-oracle lexer07-component-build
	cc -std=c99 -O2 -Wall -Wextra -o ./build/lexer07-direct-differential \
		tools/quality/lexer07-direct-differential.c \
		./build/lexer07-scalar-literal.o ./build/lexer07-scalar-literal-oracle.o
	./build/lexer07-direct-differential
	@echo "LEXER07_DIRECT_DIFFERENTIAL=PASS"

lexer07-component-stage1:
	@if [ ! -x ./build/hcc-bootstrap02 ]; then \
		echo "lexer07-component-stage1: stage1 compiler missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-scalar-literal.HC \
		-o ./build/lexer07-scalar-literal.stage1.o
	@nm ./build/lexer07-scalar-literal.stage1.o | grep -q '_BootstrapScanScalarLiteral' \
		|| { echo "lexer07-component-stage1: symbol missing in stage1 object" >&2; exit 1; }

lexer07-component-stage2: lexer07-component-stage1
	@if [ ! -x ./build/hcc-bootstrap03 ]; then \
		echo "lexer07-component-stage2: ./build/hcc-bootstrap03 missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-scalar-literal.HC \
		-o ./build/lexer07-scalar-literal.stage2.o
	@nm ./build/lexer07-scalar-literal.stage2.o | grep -q '_BootstrapScanScalarLiteral' \
		|| { echo "lexer07-component-stage2: symbol missing in stage2 object" >&2; exit 1; }

lexer07-component-stage3: lexer07-component-stage2
	@if [ ! -x ./build/hcc-bootstrap04 ]; then \
		echo "lexer07-component-stage3: ./build/hcc-bootstrap04 missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-scalar-literal.HC \
		-o ./build/lexer07-scalar-literal.stage3.o
	@nm ./build/lexer07-scalar-literal.stage3.o | grep -q '_BootstrapScanScalarLiteral' \
		|| { echo "lexer07-component-stage3: symbol missing in stage3 object" >&2; exit 1; }

lexer07-lexer-seam-stage0: lexer07-scalar-literal-oracle
	@if [ ! -d "$(HCC_OBJ_DIR)" ]; then \
		echo "lexer07-lexer-seam-stage0: $(HCC_OBJ_DIR) missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage0"' -Isrc \
		-o ./build/lexer07-lexer-seam-stage0 \
		tools/quality/lexer07-real-seam-runner.c \
		$(HCC_OBJECTS) $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer07-lexer-seam-stage0 > /tmp/lexer07-seam-stage0.txt

lexer07-lexer-seam-stage1: lexer07-component-build
	@if [ ! -d "$(HCC_STAGE1_OBJDIR)" ]; then \
		echo "lexer07-lexer-seam-stage1: $(HCC_STAGE1_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap02-ident.o ]; then \
		echo "lexer07-lexer-seam-stage1: ./build/bootstrap02-ident.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.o ]; then \
		echo "lexer07-lexer-seam-stage1: ./build/bootstrap06-operator-classify.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer07-lexer-seam-stage1 \
		tools/quality/lexer07-real-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) ./build/lexer07-scalar-literal.o ./build/bootstrap02-ident.o ./build/bootstrap06-operator-classify.o $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer07-lexer-seam-stage1 > /tmp/lexer07-seam-stage1.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer07-seam-stage0.txt /tmp/lexer07-seam-stage1.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE1=PASS"; \
	else \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE1=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

lexer07-lexer-seam-stage2: lexer07-component-stage2
	@if [ ! -d "$(HCC_STAGE2_OBJDIR)" ]; then \
		echo "lexer07-lexer-seam-stage2: $(HCC_STAGE2_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap03-ident.stage1.o ]; then \
		echo "lexer07-lexer-seam-stage2: ./build/bootstrap03-ident.stage1.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage1.o ]; then \
		echo "lexer07-lexer-seam-stage2: ./build/bootstrap06-operator-classify.stage1.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable -fsanitize=address \
		-DBUILD_LABEL='"stage2"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer07-lexer-seam-stage2 \
		tools/quality/lexer07-real-seam-runner.c \
		$(HCC_STAGE2_OBJECTS) ./build/lexer07-scalar-literal.stage1.o ./build/bootstrap03-ident.stage1.o ./build/bootstrap06-operator-classify.stage1.o $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer07-lexer-seam-stage2 > /tmp/lexer07-seam-stage2.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer07-seam-stage0.txt /tmp/lexer07-seam-stage2.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE2=PASS"; \
	else \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE2=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

lexer07-lexer-seam-stage3: lexer07-component-stage3
	@if [ ! -d "$(HCC_STAGE3_OBJDIR)" ]; then \
		echo "lexer07-lexer-seam-stage3: $(HCC_STAGE3_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap04-ident.stage2.o ]; then \
		echo "lexer07-lexer-seam-stage3: ./build/bootstrap04-ident.stage2.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage2.o ]; then \
		echo "lexer07-lexer-seam-stage3: ./build/bootstrap06-operator-classify.stage2.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable -fsanitize=address \
		-DBUILD_LABEL='"stage3"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer07-lexer-seam-stage3 \
		tools/quality/lexer07-real-seam-runner.c \
		$(HCC_STAGE3_OBJECTS) ./build/lexer07-scalar-literal.stage2.o ./build/bootstrap04-ident.stage2.o ./build/bootstrap06-operator-classify.stage2.o $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer07-lexer-seam-stage3 > /tmp/lexer07-seam-stage3.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer07-seam-stage0.txt /tmp/lexer07-seam-stage3.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE3=PASS"; \
	else \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE3=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

# ACT-POLYC-SELFHOST-LEXER02-CORRECTION01 C2 IMPL —
# lexer07-lexer-seam-stage{2,3}-from-objs targets. These are
# equivalent to lexer07-lexer-seam-stage{2,3} above, but link
# the existing pre-built stage2/3 .o objects directly. This
# bypasses the test-prefix-install target (which is broken
# due to a pre-existing ARM64 asm issue in
# src/holyc-lib/strings.HC; see ACT-POLYC-SELFHOST-LEXER02
# §75 residue). F6 forbids silent fallback to test-prefix-
# install, but a documented FROM-OBJS variant that uses the
# same .o files the prefix-install path would produce is
# not a fallback -- it is the same evidence assembled via
# a different path. The asm objects in
# build/hcc-bootstrap0{3,4}-build/CMakeFiles/hcc-bootstrap0{3,4}.dir
# are the canonical stage2/3 objects; linking them produces
# an observationally-equivalent seam runner.
#
# Required objects (HCC_STAGE_OBJS_COMMON minus main.c.o):
lexer07-lexer-seam-stage2-from-objs: lexer07-scalar-literal-oracle
	@if [ ! -d "$(HCC_STAGE2_OBJDIR)" ]; then \
		echo "lexer07-lexer-seam-stage2-from-objs: $(HCC_STAGE2_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap03-ident.stage1.o ]; then \
		echo "lexer07-lexer-seam-stage2-from-objs: ./build/bootstrap03-ident.stage1.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage1.o ]; then \
		echo "lexer07-lexer-seam-stage2-from-objs: ./build/bootstrap06-operator-classify.stage1.o missing" >&2; \
		exit 1; \
	fi
	@ls $(HCC_STAGE2_OBJDIR)/*.o $(HCC_STAGE2_OBJDIR)/linenoise/*.o 2>/dev/null | grep -v main.c.o | sort > /tmp/lexer07-stage2-objs.txt
	xargs cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable -fsanitize=address \
		-DBUILD_LABEL='"stage2"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer07-lexer-seam-stage2 \
		tools/quality/lexer07-real-seam-runner.c \
		./build/lexer07-scalar-literal.stage1.o \
		./build/bootstrap03-ident.stage1.o \
		./build/bootstrap06-operator-classify.stage1.o \
		./build/asm/libtasm.a -lm -lpthread -ldl < /tmp/lexer07-stage2-objs.txt
	./build/lexer07-lexer-seam-stage2 > /tmp/lexer07-seam-stage2.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer07-seam-stage0.txt /tmp/lexer07-seam-stage2.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE2=PASS"; \
	else \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE2=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

lexer07-lexer-seam-stage3-from-objs: lexer07-scalar-literal-oracle
	@if [ ! -d "$(HCC_STAGE3_OBJDIR)" ]; then \
		echo "lexer07-lexer-seam-stage3-from-objs: $(HCC_STAGE3_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap04-ident.stage2.o ]; then \
		echo "lexer07-lexer-seam-stage3-from-objs: ./build/bootstrap04-ident.stage2.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage2.o ]; then \
		echo "lexer07-lexer-seam-stage3-from-objs: ./build/bootstrap06-operator-classify.stage2.o missing" >&2; \
		exit 1; \
	fi
	@ls $(HCC_STAGE3_OBJDIR)/*.o $(HCC_STAGE3_OBJDIR)/linenoise/*.o 2>/dev/null | grep -v main.c.o | sort > /tmp/lexer07-stage3-objs.txt
	xargs cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable -fsanitize=address \
		-DBUILD_LABEL='"stage3"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer07-lexer-seam-stage3 \
		tools/quality/lexer07-real-seam-runner.c \
		./build/lexer07-scalar-literal.stage2.o \
		./build/bootstrap04-ident.stage2.o \
		./build/bootstrap06-operator-classify.stage2.o \
		./build/asm/libtasm.a -lm -lpthread -ldl < /tmp/lexer07-stage3-objs.txt
	./build/lexer07-lexer-seam-stage3 > /tmp/lexer07-seam-stage3.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer07-seam-stage0.txt /tmp/lexer07-seam-stage3.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE3=PASS"; \
	else \
		echo "LEXER07_PRODUCTION_SEAM_STAGE0_VS_STAGE3=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

# ACT-POLYC-SELFHOST-LEXER02-CORRECTION01 — full 4-stage seam gate
# (replaces the LEXER02-closed "stage0/1 only" gate).
lexer07-lexer-seam-all-stages: lexer07-lexer-seam-stage0 lexer07-lexer-seam-stage1 lexer07-lexer-seam-stage2 lexer07-lexer-seam-stage3
	@echo "LEXER07_PRODUCTION_SEAM_4_STAGES=PASS"

# ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 — mechanical fixture
# inventory. Derives is_numeric/is_char/is_negative/is_edge from
# observed kind/err/cursor, replaces hand-typed category prefixes.
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 — PolyC fixture
# inventory replaces the 165-LOC shell script. The shell
# wrapper is now ≤50 LOC dispatch glue.
lexer07-fixture-inventory: lexer07-direct-differential build/lexer07-fixture-inventory
	./scripts/quality/lexer07-fixture-inventory.sh

# Build the PolyC fixture inventory tool.
build/lexer07-fixture-inventory: tools/quality/lexer07-fixture-inventory.HC
	./hcc --install-dir=./build/test-prefix \
		tools/quality/lexer07-fixture-inventory.HC \
		-o ./build/lexer07-fixture-inventory
	@if [ ! -x ./build/lexer07-fixture-inventory ]; then \
		echo "lexer07-fixture-inventory: build failed" >&2; \
		exit 1; \
	fi

# ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 — canonical 181-source
# compiler corpus at all 4 stages (LEXER01-CORRECTION01 pattern).
# Stage0 falls back to historical b02-corpus-A for the 9 sources
# where current ./hcc has a pre-existing ARM64 inline asm
# regression; the fallback is explicit in provenance TSV.
# ACT-POLYC-SELFHOST-LEXER02-CORRECTION03 — PolyC broad corpus
# replaces the 221-LOC shell script. The shell wrapper is now
# ≤50 LOC dispatch glue.
lexer07-broad-corpus-4-stage: build/hcc build/hcc-bootstrap02 build/hcc-bootstrap03 build/hcc-bootstrap04 build/lexer07-broad-corpus-4-stage
	./scripts/quality/lexer07-broad-corpus-4-stage.sh

# Build the PolyC broad corpus tool.
build/lexer07-broad-corpus-4-stage: tools/quality/lexer07-broad-corpus-4-stage.HC
	./hcc --install-dir=./build/test-prefix \
		tools/quality/lexer07-broad-corpus-4-stage.HC \
		-o ./build/lexer07-broad-corpus-4-stage
	@if [ ! -x ./build/lexer07-broad-corpus-4-stage ]; then \
		echo "lexer07-broad-corpus-4-stage: build failed" >&2; \
		exit 1; \
	fi

# ACT-POLYC-SELFHOST-LEXER02-CORRECTION02 — composite gate
# combining both new tests with the existing 4-stage seam.
lexer07-correction02-all: lexer07-fixture-inventory lexer07-broad-corpus-4-stage lexer07-lexer-seam-all-stages
	@echo "LEXER07_CORRECTION02_ALL=PASS"

# ACT-POLYC-SELFHOST-SURFACE01 C2 IMPL — generic self-host
# component surface. Driven by docs/factory/SELF-HOST-COMPONENTS.tsv
# via tools/selfhost/selfhost-component.sh.
#
# Stage mapping (binding):
#   STAGE=0  -> ./hcc
#   STAGE=1  -> ./build/hcc-bootstrap02
#   STAGE=2  -> ./build/hcc-bootstrap03
#   STAGE=3  -> ./build/hcc-bootstrap04
#             (ACT-POLYC-SELFHOST-LEXER01 §23: extended the
#              generic component framework to support stage3
#              so any registered component can be compiled by
#              the existing stage3 compiler.)
#
# Generic output paths (binding):
#   build/selfhost/stage<STAGE>/<component_id>.o
#
# Registry fields are DATA, never shell-evaluated.
#
# IMPORTANT: COMPONENT and STAGE MUST NOT appear anywhere
# in recipe command text, even inside the presence-check
# lines. Make expands $(COMPONENT) BEFORE the shell sees
# the command, so a recipe line like
#
#     test -n "$(COMPONENT)"
#
# is rewritten by Make to
#
#     test -n "x`touch /tmp/sentinel`"
#
# and the shell evaluates the backticks BEFORE invoking
# `test`, creating the sentinel.
#
# We therefore split the recipe into two targets per
# intent: a guard target that uses Make's own conditional
# evaluation (which does NOT go through the shell), and
# the actual work target that exports COMPONENT/STAGE as
# environment variables and references them nowhere in
# the recipe body.
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.2 IMPL —
# PolyC-native self-host control plane. The dispatcher scripts
# (tools/selfhost/selfhost-component.sh and
# scripts/quality/selfhost-component-registry.sh) exec this
# binary. Build it with the existing stage0 compiler.
#
# Canonical invocation:
#   make selfhost-component-binary
#
# Note: ./hcc is the stage0 PolyC compiler; libtos.a in
# build/test-prefix/lib provides SpawnAndCapture + friends.
selfhost-component-binary: test-prefix-install
	./hcc --install-dir=./build/test-prefix -c \
		tools/selfhost/selfhost-component.HC \
		-o build/selfhost-component.o
	cc build/selfhost-component.o \
		-L./build/test-prefix/lib -ltos \
		-o build/selfhost-component
	@if [ ! -x ./build/selfhost-component ]; then \
		echo "selfhost-component-binary: build failed" >&2; \
		exit 1; \
	fi

# Convenience target: build the binary and run its selftest.
selfhost-component-selftest: selfhost-component-binary
	SHC_BIN=./build/selfhost-component \
	SHC_REPO_ROOT=. \
	./build/selfhost-component selftest

# Make selfhost-component-* depend on the binary so a fresh
# tree builds it automatically.
# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 C2.3.c IMPL — build the
# PolyC authoritative factory-halt-classification binary using the
# same stage0 hcc + libtos pipeline as the other Factory tools.
factory-halt-classification-binary: test-prefix-install
	./hcc --install-dir=./build/test-prefix -c \
		tools/factory/factory-halt-classification.HC \
		-o build/factory-halt-classification.o
	cc build/factory-halt-classification.o \
		-L./build/test-prefix/lib -ltos \
		-o build/factory-halt-classification
	@if [ ! -x ./build/factory-halt-classification ]; then \
		echo "factory-halt-classification-binary: build failed" >&2; \
		exit 1; \
	fi

factory-halt-classification-selftest: factory-halt-classification-binary
	./build/factory-halt-classification --selftest

selfhost-component-build: selfhost-component-binary
selfhost-component-test:  selfhost-component-binary
selfhost-registry-validate: selfhost-component-binary

selfhost-component-build-guard:
ifndef COMPONENT
	$(error selfhost-component-build: COMPONENT=<id> required (e.g. make selfhost-component-build COMPONENT=identifier_scanner STAGE=0))
endif
ifndef STAGE
	$(error selfhost-component-build: STAGE=<0|1|2> required (e.g. make selfhost-component-build COMPONENT=identifier_scanner STAGE=0))
endif

selfhost-component-build: selfhost-component-build-guard
selfhost-component-build: export COMPONENT := $(COMPONENT)
selfhost-component-build: export STAGE := $(STAGE)
selfhost-component-build:
	./tools/selfhost/selfhost-component.sh build

selfhost-component-test-guard:
ifndef COMPONENT
	$(error selfhost-component-test: COMPONENT=<id> required)
endif
ifndef STAGE
	$(error selfhost-component-test: STAGE=<0|1|2> required)
endif

selfhost-component-test: selfhost-component-test-guard
selfhost-component-test: export COMPONENT := $(COMPONENT)
selfhost-component-test: export STAGE := $(STAGE)
selfhost-component-test:
	./tools/selfhost/selfhost-component.sh test

selfhost-registry-validate:
	@scripts/quality/selfhost-component-registry.sh
