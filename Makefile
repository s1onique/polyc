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

.PHONY: all gate-fast gate-push install-hooks llvm-all llvm-spike-test test-prefix-install llvm-gep01-test

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
	@# Hermetic-prefix-local: drop the unversioned libtos.dylib
	@# symlink so `-ltos` resolves to the static archive (see comment
	@# above). Idempotent; no-op if the symlink does not exist.
	@rm -f $(TEST_PREFIX)/lib/libtos.dylib
	@if [ ! -f $(TEST_PREFIX)/lib/libtos.a ] || \
	    [ ! -f $(TEST_PREFIX)/lib/libtos.0.0.1.dylib ]; then \
		echo "test-prefix-install: canonical install did not produce libtos.{a,0.0.1.dylib}" >&2; \
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

gate-fast:
	./scripts/quality/gate-fast.sh

gate-push:
	./scripts/quality/gate-push.sh HEAD

install-hooks:
	./scripts/install-git-hooks.sh
