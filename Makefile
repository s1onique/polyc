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

.PHONY: all gate-fast gate-push install-hooks llvm-all llvm-spike-test

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

unit-test:
	cd ./src/tests && ../../hcc ./run.HC -o test-runner && ./test-runner && cd ../../

jit-unit-test:
	cd ./src/tests && ../../hcc ./run_jit.HC -o test-runner-jit && ./test-runner-jit && cd ../../

# Hermetic: builds libtos from the tree into a local prefix and
# compiles the (HolyC) harness against it, so the suite tests in-tree
# sources - never whatever happens to be installed in /usr/local.
lsp-test:
	mkdir -p ./build/test-prefix/include ./build/test-prefix/lib
	cp ./src/holyc-lib/tos.HH ./build/test-prefix/include/tos.HH
	cd ./src/holyc-lib && ../../hcc -lib tos --install-dir=$(CURDIR)/build/test-prefix ./all.HC
	cd ./src/tests/lsp && ../../../hcc --install-dir=$(CURDIR)/build/test-prefix ./run_lsp_tests.HC -o lsp-test-runner && ./lsp-test-runner

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
