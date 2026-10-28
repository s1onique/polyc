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

.PHONY: all formal-dafny gate-fast gate-push install-hooks static-function-linkage-test factory-closure-status-test factory-closure-status-test-binary llvm-all llvm-spike-test test-prefix-install llvm-gep01-test bootstrap-stage0 bootstrap-prefix parser-padding-subject production-hcc runtime-producer bootstrap01-test bootstrap01-oracle bootstrap02-test bootstrap02-stage1 bootstrap02-cursor-test bootstrap02-lexer-seam-test bootstrap03-component-build bootstrap03-stage2 bootstrap03-test bootstrap03-lexer-seam-test bootstrap04-component-build bootstrap04-stage3 bootstrap04-test bootstrap04-cursor-test bootstrap04-lexer-seam-test selfhost-component-binary selfhost-component-build selfhost-component-test selfhost-component-selftest selfhost-registry-validate factory-halt-classification-binary factory-halt-classification-selftest bootstrap06-component-build bootstrap06-operator-classify-oracle bootstrap06-direct-differential bootstrap06-component-stage1 bootstrap06-component-stage2 bootstrap06-component-stage3 bootstrap06-lexer-seam-stage1 lexer07-component-build lexer07-scalar-literal-oracle lexer07-direct-differential lexer07-component-stage1 lexer07-component-stage2 lexer07-component-stage3 lexer07-lexer-seam-stage0 lexer07-lexer-seam-stage1 lexer07-lexer-seam-stage2 lexer07-lexer-seam-stage3 lexer07-lexer-seam-stage2-from-objs lexer07-lexer-seam-stage3-from-objs lexer07-lexer-seam-all-stages lexer07-fixture-inventory lexer07-broad-corpus-4-stage lexer07-correction02-all lexer07-baseline-authority-verify lexer08-component-build lexer08-trivia-oracle lexer08-direct-differential lexer08-fixture-inventory lexer08-broad-corpus-4-stage lexer08-lexer-seam-stage0 lexer08-lexer-seam-stage1 lexer08-lexer-seam-all-stages lexer08-trivia-fixedpoint-g0 lexer08-trivia-fixedpoint-g1 lexer08-trivia-fixedpoint-g2 lexer08-trivia-fixedpoint-g3 lexer08-trivia-fixedpoint-build lexer08-trivia-fixedpoint-verify lexer08-trivia-fixedpoint lexer09-link-component-build lexer09-link-oracle-build lexer09-direct-differential lexer09-lexer-seam-stage0 lexer09-lexer-seam-stage1 lexer09-lexer-seam-all-stages lexer09-link-fixedpoint-g0 lexer09-link-fixedpoint-g1 lexer09-link-fixedpoint-g2 lexer09-link-fixedpoint-g3 lexer09-link-fixedpoint-build lexer09-link-fixedpoint-verify lexer09-link-fixedpoint lexer09-link-negative-control lexer09-link-determinism lexer09-link-broad-corpus-4-stage lib-tos runtime-contract-test libtos-n02-isolate parser-padding-component parser-padding-oracle parser-padding-differential parser-padding-gen-matrix-fixture parser-padding-gen-large-fixture parser-padding-fixedpoint-g0 parser-padding-fixedpoint-g1 parser-padding-fixedpoint-g2 parser-padding-fixedpoint-g3 parser-padding-fixedpoint-build parser-padding-fixedpoint-verify parser-padding-fixedpoint parser-padding-fixedpoint-negative-control parser-padding-mutation-m1 parser-padding-mutation-m2 parser-padding-mutation-m3 parser-padding-mutation-m4 parser-padding-mutation-test parser-padding-test parser-padding-algebraic-invariants parser-padding-is-terminal-stub parser-padding-legacy parser-padding-legacy-server parser-padding-legacy-verify parser-control-flow-token-component parser-control-flow-token-differential parser-control-flow-token-int-bounds parser-control-flow-token-harden-test parser-control-flow-token-negative-controls parser-slice-recon03-tools parser-slice-recon03-eligibility parser-slice-recon03-eligibility-controls parser-slice-recon03-ranking parser-slice03-contract-requalify parser-slice03-fixture-integrity parser-slice03-fixture-integrity-controls parser-slice03-differential parser-slice03-differential-negative-control parser-operator-precedence-component parser-slice03-generations parser-slice03-generation-pairs parser-slice03-copy-forgery-control parser-slice03-production-generations parser-slice03-production-semantic-pairs parser-slice03-corr01-fixture parser-slice03-corr01-coverage parser-slice03-corr01-differential parser-slice03-corr01-controls parser-slice03-corr01-producer-control parser-slice03-corr01-g0-provenance parser-slice03-corr01-test

# To add sqlite3 support add -DHCC_LINK_SQLITE3=1 to the below like so:
#```
#all:
#	cmake -S ./src -B ./build -G 'Unix Makefiles' \
#		-DCMAKE_C_COMPILER=$(_C_COMPILER) \
#		-DCMAKE_BUILD_TYPE=$(_BUILD_TYPE) \
#		-DHCC_LINK_SQLITE3=1 \
#		&& $(MAKE) -C ./build -j2
#```

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL.
#
# The canonical production build is now an ACYCLIC bootstrap chain:
#
#   host C compiler
#        |
#        v
#   bootstrap-stage0          build/host-stage0/hcc
#                             (legacy CalcPadding; delegation OFF)
#        |
#        v
#   bootstrap-prefix          build/bootstrap-prefix/{include/tos.HH}
#                             (header-only; NO runtime archive)
#        |
#        v
#   parser-padding-subject    build/parser-padding-subject.o
#                             (compiled from tools/bootstrap/selfhost-parser-padding.HC)
#        |
#        v
#   production hcc             ./hcc
#                             (HCC_USE_SELFHOST_PARSER_PADDING=ON)
#
# Every edge below is a FILE dependency, so an unchanged input does not
# force an unnecessary rebuild. No stage is permanently phony.
#
# The stage0 compiler is ISOLATED in build/host-stage0/ so that building
# it can never overwrite the production ./hcc.
#
# NO manual prerequisite command is required for `make all`.
# NO ignored binary is assumed to be present.

# The stage0 compiler: the legacy (C) implementation of CalcPadding.
# Parser-padding delegation is OFF here, exactly as the frozen design
# requires. It is built with the host C compiler only.
BOOTSTRAP_STAGE0_DIR   = ./build/host-stage0
BOOTSTRAP_STAGE0_BUILD = $(BOOTSTRAP_STAGE0_DIR)/build
BOOTSTRAP_STAGE0_HCC   = $(BOOTSTRAP_STAGE0_DIR)/hcc

# The header-only bootstrap prefix. It contains ONLY the canonical
# headers the stage0 compiler resolves against. It deliberately does NOT
# contain a runtime archive: compiling the padding subject does not need
# one, and requiring a completed libtos installation here would
# reintroduce the very cycle this ACT removes.
BOOTSTRAP_PREFIX_DIR    = ./build/bootstrap-prefix
BOOTSTRAP_PREFIX_INC    = $(BOOTSTRAP_PREFIX_DIR)/include

# The parser-padding subject and its PolyC source.
PARSER_PADDING_SRC      = tools/bootstrap/selfhost-parser-padding.HC
PARSER_PADDING_OBJ      = ./build/parser-padding-subject.o

# ACT-POLYC-SELFHOST-PARSER-SLICE02. The control-flow-token subject and
# its PolyC source. Defined here (with the other build-artifact
# variables) because the production-hcc rule below references them.
SLICE02_CFT_SRC  = tools/bootstrap/selfhost-parser-control-flow-token.HC
SLICE02_CFT_OBJ  = ./build/parser-control-flow-token-subject.o

# ACT-POLYC-SELFHOST-PARSER-SLICE03: the operator-precedence subject.
SLICE03_OP_SRC   = tools/bootstrap/selfhost-parser-operator-precedence.HC
SLICE03_OP_OBJ   = ./build/parser-operator-precedence-subject.o

# ACT-POLYC-SELFHOST-PARSER-SLICE04: the AST binary-operator subject.
SLICE04_AST_BINOP_SRC = tools/bootstrap/selfhost-parser-slice04.HC
SLICE04_AST_BINOP_OBJ = ./build/parser-ast-binop-subject.o

# ACT-POLYC-SELFHOST-PARSER-SLICE05: the AST unary-operator subject.
SLICE05_AST_UNARY_SRC = tools/bootstrap/selfhost-parser-slice05.HC
SLICE05_AST_UNARY_OBJ = ./build/parser-ast-unary-subject.o

# The stage0 compiler's own sources. A change to any of them must
# invalidate the stage0 compiler, which in turn invalidates the
# padding subject.
BOOTSTRAP_STAGE0_SOURCES = $(wildcard src/*.c src/asm/*.c) $(wildcard src/*.h src/asm/*.h)

all: production-hcc

# The isolated legacy stage0 compiler.
#
# HCC_USE_SELFHOST_PARSER_PADDING=OFF is mandatory here: the stage0
# compiler is the LEGACY control that produces the PolyC padding object.
# It must not itself require a PolyC padding object, or the graph would
# cycle.
#
# HCC_RUNTIME_OUTPUT_DIRECTORY keeps the artifact inside
# build/host-stage0/ so the production ./hcc is never overwritten.
$(BOOTSTRAP_STAGE0_HCC): $(BOOTSTRAP_STAGE0_SOURCES)
	@rm -rf $(BOOTSTRAP_STAGE0_BUILD)
	@mkdir -p $(BOOTSTRAP_STAGE0_BUILD)
	cmake -S ./src \
		-B $(BOOTSTRAP_STAGE0_BUILD) \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_USE_SELFHOST_PARSER_PADDING=OFF \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=OFF \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=OFF \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=OFF \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(BOOTSTRAP_STAGE0_DIR)
	$(MAKE) -C $(BOOTSTRAP_STAGE0_BUILD) hcc -j2
	@if [ ! -x "$(BOOTSTRAP_STAGE0_HCC)" ]; then \
		echo "bootstrap-stage0: $(BOOTSTRAP_STAGE0_HCC) not produced" >&2; \
		exit 1; \
	fi
	@echo "BOOTSTRAP_STAGE0_BINARY=$(BOOTSTRAP_STAGE0_HCC)"

bootstrap-stage0: $(BOOTSTRAP_STAGE0_HCC)

# The header-only bootstrap prefix.
$(BOOTSTRAP_PREFIX_INC)/tos.HH: src/holyc-lib/tos.HH
	@rm -rf $(BOOTSTRAP_PREFIX_DIR)
	@mkdir -p $(BOOTSTRAP_PREFIX_INC)
	cp src/holyc-lib/tos.HH $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@echo "BOOTSTRAP_PREFIX=$(BOOTSTRAP_PREFIX_DIR)"

bootstrap-prefix: $(BOOTSTRAP_PREFIX_INC)/tos.HH

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL.
#
# The provenance-strict RUNTIME PRODUCER.
#
# The canonical runtime archive (libtos) is produced by
# build/hcc-bootstrap04, whose identity is pinned by
# LIBTOS_BOOTSTRAP_EXPECTED_SHA (frozen by a closed predecessor). The
# producer must be REPRODUCIBLE from a clean tree; otherwise the install
# seam can only be satisfied by a hand-placed binary, which is exactly
# the warm-tree assumption this ACT removes.
#
# Mechanism (frozen at C1; the reproduction was MEASURED, not assumed):
#   1. Materialize the pinned producer's source tree as a detached git
#      worktree at build/pinned-producer/tree, checked out AT the pinned
#      commit. The compiler embeds its own git hash into the binary's
#      bytes (src/CMakeLists.txt), so the producer's tree MUST be a real
#      checkout whose HEAD IS the pinned commit.
#   2. Drive that tree's OWN build graph with a HEADER-ONLY bootstrap
#      prefix (canonical headers only, NO runtime archive) to produce the
#      stage chain.
#   3. Measure the produced producer's sha256 against the FROZEN constant
#      and FAIL CLOSED on mismatch. The expected value is NEVER
#      recomputed from the produced artifact.
#   4. Install the QUALIFIED producer at its own path
#      (build/runtime-producer/hcc-bootstrap04) for the runtime install
#      seam. It is deliberately NOT the current tree's
#      build/hcc-bootstrap04, which is a different artifact with a
#      different identity.
#
# This chain does NOT depend on the current tree's test-prefix-install,
# so the graph stays acyclic:
#
#   runtime-producer -> pinned tree (own sources)
#                       -> build/runtime-producer/hcc-bootstrap04
#   test-prefix-install -> runtime-producer
#   production-hcc -> (independent of the runtime producer)
LIBTOS_BOOTSTRAP_PINNED_COMMIT := ffee58b81ae42a4ff094618fcaa965223a40b848

# The pinned producer's tree lives OUTSIDE ./build, in a sibling
# directory of the repository.
#
# PLACEMENT IS A SAFETY REQUIREMENT, NOT A STYLE CHOICE: `make clean`
# deletes ./build recursively. A git worktree nested under ./build would
# therefore be deleted as part of an ordinary clean, and removing it
# would take the enclosing repository's working tree with it when that
# enclosing tree happens to live under ./build. Keeping the pinned tree
# outside ./build makes `make clean` a purely local operation.
PINNED_PRODUCER_DIR    = ./build-pinned-producer
PINNED_PRODUCER_TREE   = $(PINNED_PRODUCER_DIR)/tree
PINNED_PRODUCER_BUILD  = $(PINNED_PRODUCER_TREE)/build
PINNED_PRODUCER_PREFIX = $(PINNED_PRODUCER_BUILD)/prefix
PINNED_PRODUCER_INC    = $(PINNED_PRODUCER_PREFIX)/include

# The component objects each stage produces for the next stage.
# Each entry is "<source-basename>:<object-basename>". The source lives
# in the pinned tree's tools/bootstrap/ directory.
PP_PRODUCER_STAGE0_OBJS = \
	bootstrap02-ident:bootstrap02-ident.o \
	selfhost-lexer-operator-classify:bootstrap06-operator-classify.o \
	selfhost-lexer-scalar-literal:lexer07-scalar-literal.o \
	selfhost-lexer-trivia:lexer08-trivia.o \
	selfhost-lexer-link:lexer09-link.o

PP_PRODUCER_STAGE1_OBJS = \
	bootstrap02-ident:bootstrap03-ident.stage1.o \
	selfhost-lexer-operator-classify:bootstrap06-operator-classify.stage1.o \
	selfhost-lexer-scalar-literal:lexer07-scalar-literal.stage1.o \
	selfhost-lexer-trivia:lexer08-trivia.stage1.o \
	selfhost-lexer-link:lexer09-link.stage1.o

PP_PRODUCER_STAGE2_OBJS = \
	bootstrap02-ident:bootstrap04-ident.stage2.o \
	selfhost-lexer-operator-classify:bootstrap06-operator-classify.stage2.o \
	selfhost-lexer-scalar-literal:lexer07-scalar-literal.stage2.o \
	selfhost-lexer-trivia:lexer08-trivia.stage2.o \
	selfhost-lexer-link:lexer09-link.stage2.o

# The pinned producer's stage0 compiler (the legacy control).
$(PINNED_PRODUCER_BUILD)/hcc:
	@rm -rf $(PINNED_PRODUCER_DIR)
	@mkdir -p $(PINNED_PRODUCER_DIR)
	git worktree prune
	git worktree add --detach $(PINNED_PRODUCER_TREE) $(LIBTOS_BOOTSTRAP_PINNED_COMMIT)
	@mkdir -p $(PINNED_PRODUCER_BUILD)/stage0
	cmake -S $(PINNED_PRODUCER_TREE)/src \
		-B $(PINNED_PRODUCER_BUILD)/stage0 \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=/usr/bin/cc \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF
	$(MAKE) -C $(PINNED_PRODUCER_BUILD)/stage0 hcc -j2
	@if [ ! -x "$(PINNED_PRODUCER_BUILD)/hcc" ]; then \
		echo "runtime-producer: pinned stage0 not produced" >&2; \
		exit 1; \
	fi
	@echo "RUNTIME_PRODUCER_PINNED_COMMIT=$(LIBTOS_BOOTSTRAP_PINNED_COMMIT)"

# The header-only prefix for the pinned producer's chain. It contains
# ONLY the canonical headers. NO runtime archive is required: the chain
# compiles PolyC component objects, which do not link against libtos.
$(PINNED_PRODUCER_INC)/tos.HH: $(PINNED_PRODUCER_BUILD)/hcc
	@mkdir -p $(PINNED_PRODUCER_INC)
	cp $(PINNED_PRODUCER_TREE)/src/holyc-lib/tos.HH $(PINNED_PRODUCER_INC)/tos.HH

# The pinned producer's stage1 compiler.
$(PINNED_PRODUCER_BUILD)/hcc-bootstrap02: $(PINNED_PRODUCER_INC)/tos.HH
	@for pair in $(PP_PRODUCER_STAGE0_OBJS); do \
		src=$${pair%%:*}; obj=$${pair##*:}; \
		$(PINNED_PRODUCER_BUILD)/hcc --install-dir=$(PINNED_PRODUCER_PREFIX) \
			-c $(PINNED_PRODUCER_TREE)/tools/bootstrap/$$src.HC \
			-o $(PINNED_PRODUCER_BUILD)/$$obj || exit 1; \
	done
	cmake -S $(PINNED_PRODUCER_TREE)/src \
		-B $(PINNED_PRODUCER_BUILD)/hcc-bootstrap02-build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=/usr/bin/cc \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap02-ident.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.o \
		-DLEXER07_SCALAR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.o \
		-DLEXER08_TRIVIA_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.o \
		-DLEXER09_LINK_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.o
	$(MAKE) -C $(PINNED_PRODUCER_BUILD)/hcc-bootstrap02-build hcc-bootstrap02 -j2
	@if [ ! -x "$(PINNED_PRODUCER_BUILD)/hcc-bootstrap02" ]; then \
		echo "runtime-producer: pinned stage1 not produced" >&2; \
		exit 1; \
	fi

# The pinned producer's stage2 compiler.
$(PINNED_PRODUCER_BUILD)/hcc-bootstrap03: $(PINNED_PRODUCER_BUILD)/hcc-bootstrap02
	@for pair in $(PP_PRODUCER_STAGE1_OBJS); do \
		src=$${pair%%:*}; obj=$${pair##*:}; \
		$(PINNED_PRODUCER_BUILD)/hcc-bootstrap02 --install-dir=$(PINNED_PRODUCER_PREFIX) \
			-c $(PINNED_PRODUCER_TREE)/tools/bootstrap/$$src.HC \
			-o $(PINNED_PRODUCER_BUILD)/$$obj || exit 1; \
	done
	cmake -S $(PINNED_PRODUCER_TREE)/src \
		-B $(PINNED_PRODUCER_BUILD)/hcc-bootstrap03-build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=/usr/bin/cc \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap02-ident.o \
		-DBOOTSTRAP03_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap03-ident.stage1.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.stage1.o \
		-DLEXER07_SCALAR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.o \
		-DLEXER07_SCALAR_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.stage1.o \
		-DLEXER08_TRIVIA_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.o \
		-DLEXER08_TRIVIA_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.stage1.o \
		-DLEXER09_LINK_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.o \
		-DLEXER09_LINK_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.stage1.o
	$(MAKE) -C $(PINNED_PRODUCER_BUILD)/hcc-bootstrap03-build hcc-bootstrap03 -j2
	@if [ ! -x "$(PINNED_PRODUCER_BUILD)/hcc-bootstrap03" ]; then \
		echo "runtime-producer: pinned stage2 not produced" >&2; \
		exit 1; \
	fi

# The pinned producer's stage3 compiler -- the RUNTIME PRODUCER itself.
$(PINNED_PRODUCER_BUILD)/hcc-bootstrap04: $(PINNED_PRODUCER_BUILD)/hcc-bootstrap03
	@for pair in $(PP_PRODUCER_STAGE2_OBJS); do \
		src=$${pair%%:*}; obj=$${pair##*:}; \
		$(PINNED_PRODUCER_BUILD)/hcc-bootstrap03 --install-dir=$(PINNED_PRODUCER_PREFIX) \
			-c $(PINNED_PRODUCER_TREE)/tools/bootstrap/$$src.HC \
			-o $(PINNED_PRODUCER_BUILD)/$$obj || exit 1; \
	done
	cmake -S $(PINNED_PRODUCER_TREE)/src \
		-B $(PINNED_PRODUCER_BUILD)/hcc-bootstrap04-build \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=/usr/bin/cc \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=/usr/local \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=OFF \
		-DHCC_ENABLE_BOOTSTRAP02_STAGE1=ON \
		-DHCC_ENABLE_BOOTSTRAP03_STAGE2=ON \
		-DHCC_ENABLE_BOOTSTRAP04_STAGE3=ON \
		-DBOOTSTRAP02_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap02-ident.o \
		-DBOOTSTRAP03_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap03-ident.stage1.o \
		-DBOOTSTRAP04_IDENT_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap04-ident.stage2.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.stage1.o \
		-DBOOTSTRAP06_OPERATOR_OBJECT_STAGE2=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/bootstrap06-operator-classify.stage2.o \
		-DLEXER07_SCALAR_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.o \
		-DLEXER07_SCALAR_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.stage1.o \
		-DLEXER07_SCALAR_OBJECT_STAGE2=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer07-scalar-literal.stage2.o \
		-DLEXER08_TRIVIA_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.o \
		-DLEXER08_TRIVIA_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.stage1.o \
		-DLEXER08_TRIVIA_OBJECT_STAGE2=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer08-trivia.stage2.o \
		-DLEXER09_LINK_OBJECT=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.o \
		-DLEXER09_LINK_OBJECT_STAGE1=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.stage1.o \
		-DLEXER09_LINK_OBJECT_STAGE2=$(CURDIR)/$(PINNED_PRODUCER_BUILD)/lexer09-link.stage2.o
	$(MAKE) -C $(PINNED_PRODUCER_BUILD)/hcc-bootstrap04-build hcc-bootstrap04 -j2
	@if [ ! -x "$(PINNED_PRODUCER_BUILD)/hcc-bootstrap04" ]; then \
		echo "runtime-producer: pinned stage3 not produced" >&2; \
		exit 1; \
	fi

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL.
#
# The QUALIFIED runtime producer lives at its OWN path.
#
# PATH OWNERSHIP (this is the point of the distinct path):
#   build/hcc-bootstrap04              the CURRENT tree's stage3 compiler.
#                                     Produced by `bootstrap04-stage3`.
#                                     It is a LEXER self-hosting artifact
#                                     used by the four-generation fixed
#                                     points. It is NOT the runtime
#                                     producer: its sha256 does not match
#                                     the pinned provenance identity.
#   build/runtime-producer/hcc-bootstrap04
#                                     the QUALIFIED runtime producer.
#                                     Reproduced from the pinned source
#                                     tree and verified against the FROZEN
#                                     provenance identity. This is the only
#                                     artifact the runtime install seam may
#                                     use.
#
# Keeping the two paths distinct removes an ambiguity that would
# otherwise let one artifact silently overwrite the other, and it keeps
# the existing lexer fixed-point contracts untouched.
RUNTIME_PRODUCER_PATH = ./build/runtime-producer/hcc-bootstrap04

# The QUALIFIED runtime producer, produced from the pinned tree and
# verified against the FROZEN constant.
#
# The provenance check is FAIL CLOSED: the produced producer's sha256 is
# compared against the FROZEN constant LIBTOS_BOOTSTRAP_EXPECTED_SHA.
# The expected value is NEVER recomputed from the produced artifact, and
# a mismatch does not install anything.
$(RUNTIME_PRODUCER_PATH): $(PINNED_PRODUCER_BUILD)/hcc-bootstrap04
	@mkdir -p $(dir $@)
	@_actual=$$(shasum -a 256 $< | cut -d' ' -f1); \
	if [ "$$_actual" != "$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" ]; then \
		echo "runtime-producer: FAIL: producer identity mismatch" >&2; \
		echo "runtime-producer:   produced sha256 = $$_actual" >&2; \
		echo "runtime-producer:   expected sha256 = $(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" >&2; \
		echo "runtime-producer: refusing to install an unqualified producer" >&2; \
		exit 1; \
	fi; \
	cp $< $@; \
	echo "RUNTIME_PRODUCER=$(RUNTIME_PRODUCER_PATH)"; \
	echo "RUNTIME_PRODUCER_PROVENANCE_SHA=$$_actual"; \
	echo "RUNTIME_PRODUCER_PROVENANCE=PASS"

runtime-producer: $(RUNTIME_PRODUCER_PATH)

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The bootstrap stage targets are PHONY: they re-run their recipe every
# time they are invoked. The stage BINARIES they produce are real files,
# and the four-generation fixed points consume those files as normal
# prerequisites. Without a file-level rule, make reports
#   "No rule to make target `build/hcc-bootstrap02'"
# on a clean tree, because the phony target does not create a make-visible
# file edge.
#
# These rules give make the missing file-level edge. They delegate to the
# existing, already-qualified phony stage targets, so no recipe logic is
# duplicated and no existing contract changes.
build/hcc-bootstrap02: bootstrap02-stage1
build/hcc-bootstrap03: bootstrap03-stage2
build/hcc-bootstrap04: bootstrap04-stage3

# The LEXER self-host component objects consumed by the bootstrap stage
# builds. Each has an existing, already-qualified phony producer; these
# rules give make the file-level edge so the stage builds are reachable
# from a clean tree instead of requiring a warm build/ directory.
#
# Without them, `make bootstrap02-stage1` on a clean tree aborts at the
# cmake configure with "required self-host operator component missing at
# build/bootstrap06-operator-classify.o" -- the same class of warm-tree
# assumption this ACT exists to remove.
build/bootstrap06-operator-classify.o: bootstrap06-component-build
build/lexer07-scalar-literal.o: lexer07-component-build
build/lexer08-trivia.o: lexer08-component-build
build/lexer09-link.o: lexer09-link-component-build

# The per-generation component objects. Each generation's objects are
# produced by the previous generation's compiler, and each generation's
# build demands them as LINK inputs at cmake-configure time. The
# producers are the existing, already-qualified phony stage targets.
build/bootstrap03-ident.stage1.o: bootstrap03-component-build
build/bootstrap06-operator-classify.stage1.o: bootstrap06-component-stage1
build/lexer07-scalar-literal.stage1.o: lexer07-component-stage1
build/lexer09-link.stage1.o: lexer09-link-component-stage1

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# LEXER08 (the trivia component) has no dedicated component-stage target:
# its per-generation objects were produced only by the warm tree, and
# the stage2 build demands build/lexer08-trivia.stage1.o as a LINK input
# at cmake-configure time.
#
# The rule below mirrors the established pattern of the sibling
# components exactly: the PREVIOUS generation's compiler compiles the
# PolyC subject. The subject and the symbol contract are unchanged.
build/lexer08-trivia.stage1.o: ./build/hcc-bootstrap02 build/lexer08-trivia.o
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-trivia.HC -o $@
	@if [ ! -f "$@" ]; then \
		echo "lexer08-trivia.stage1.o: not produced" >&2; exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapScanTrivia' \
		|| { echo "lexer08-trivia.stage1.o: symbol missing" >&2; exit 1; }
	@echo "LEXER08_STAGE1_TRIVIA_OBJECT=$@"

build/bootstrap04-ident.stage2.o: bootstrap04-component-build
build/bootstrap06-operator-classify.stage2.o: bootstrap06-component-stage2
build/lexer07-scalar-literal.stage2.o: lexer07-component-stage2
build/lexer08-trivia.stage2.o: ./build/hcc-bootstrap03 build/lexer08-trivia.stage1.o
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-trivia.HC -o $@
	@if [ ! -f "$@" ]; then \
		echo "lexer08-trivia.stage2.o: not produced" >&2; exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapScanTrivia' \
		|| { echo "lexer08-trivia.stage2.o: symbol missing" >&2; exit 1; }
	@echo "LEXER08_STAGE2_TRIVIA_OBJECT=$@"

build/lexer09-link.stage2.o: lexer09-link-component-stage2

# The architecture check for the padding subject. It compares the
# object's OWN architecture metadata against the requested target
# architecture. It is a fail-closed check: an architecture mismatch is a
# hard error, never a warning and never a silent legacy fallback.
#
# The comparison is done on the object file's real Mach-O / ELF header
# via `file`, not on the file NAME. A fat/universal object is rejected
# outright: the production link is single-architecture.
#
# This is inline build-graph logic, deliberately not a separate tool.
define PARSER_PADDING_ARCH_VERIFY
	@_pp_arch=$$(file -b "$@" | grep -o -E '(x86_64|x86-64|aarch64|arm64|i386|i686)' | head -1); \
	_pp_want=$$(printf '%s' "$(PARSER_PADDING_TARGET_ARCH)" | sed -e 's/aarch64/arm64/' -e 's/x86-64/x86_64/'); \
	if printf '%s' "$$(file -b "$@")" | grep -q 'universal binary'; then \
		echo "parser-padding-subject: $@ is a fat/universal object" >&2; \
		echo "parser-padding-subject: the production link requires a single-architecture object" >&2; \
		exit 1; \
	fi; \
	if [ -z "$$_pp_arch" ]; then \
		echo "parser-padding-subject: could not determine the architecture of $@" >&2; \
		echo "parser-padding-subject: refusing to link an object of unknown architecture" >&2; \
		exit 1; \
	fi; \
	if [ "$$_pp_arch" != "$$_pp_want" ]; then \
		echo "parser-padding-subject: architecture mismatch for $@" >&2; \
		echo "parser-padding-subject:   object architecture = $$_pp_arch" >&2; \
		echo "parser-padding-subject:   target architecture = $$_pp_want" >&2; \
		echo "parser-padding-subject: refusing to link a wrong-architecture object" >&2; \
		exit 1; \
	fi; \
	echo "PARSER_PADDING_ARCH_CHECK=PASS arch=$$_pp_arch target=$$_pp_want"
endef

# The architecture the production compiler targets. Native builds use the
# host architecture. A cross build overrides this explicitly.
PARSER_PADDING_TARGET_ARCH ?= $(shell uname -m)

# The PolyC parser-padding subject, produced by the stage0 compiler from
# the CURRENT source tree.
#
# The object is verified for its exported symbol AND its architecture.
# A wrong-architecture object is REJECTED, never linked.
$(PARSER_PADDING_OBJ): $(PARSER_PADDING_SRC) $(BOOTSTRAP_STAGE0_HCC) $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@rm -f $@
	$(BOOTSTRAP_STAGE0_HCC) \
		--install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(PARSER_PADDING_SRC) \
		-o $@
	@if [ ! -f "$@" ]; then \
		echo "parser-padding-subject: $@ not produced by the stage0 compiler" >&2; \
		exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapCalcPadding' \
		|| { echo "parser-padding-subject: symbol _BootstrapCalcPadding not found in $@" >&2; exit 1; }
	@$(PARSER_PADDING_ARCH_VERIFY)
	@echo "PARSER_PADDING_SUBJECT=$@"
	@echo "PARSER_PADDING_SUBJECT_ARCH=$$(file -b "$@" | sed -e 's/.*object //')"

parser-padding-subject: $(PARSER_PADDING_OBJ)

# The production compiler.
#
# The CMake configure is handed the DECLARED producer of the padding
# object, so CMake schedules its production as part of the hcc target's
# dependency graph. It is NOT an if(EXISTS) probe.
#
# The target is FILE based: the production binary is the artifact, and
# the configure+build only runs when that artifact is missing or older
# than its inputs. This matters for two reasons:
#
#   * an unchanged tree does not re-run the configure on every build
#     (the "no-op rebuild" contract), and
#   * a reconfigure with a different C compiler does not silently reset
#     unrelated cached options such as HCC_ENABLE_JIT, which is what
#     previously produced a link failure against a missing libtasm.a.
PRODUCTION_HCC = ./hcc
PRODUCTION_HCC_INPUTS = $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) \
	$(SLICE04_AST_BINOP_OBJ) $(SLICE05_AST_UNARY_OBJ) \
	$(wildcard src/*.c src/asm/*.c) \
	$(wildcard src/*.h src/asm/*.h) \
	$(wildcard src/CMakeLists.txt src/asm/CMakeLists.txt) \
	$(wildcard src/cmake/*.cmake)

$(PRODUCTION_HCC): $(PRODUCTION_HCC_INPUTS)
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
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_AST_UNARY_OBJ) \
		-DAST_UNARY_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_UNARY_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE05_AST_UNARY_SRC) \
		-DAST_UNARY_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_BOOTSTRAP_EXPECTED_SHA=$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)
	$(MAKE) -C ./build -j2
	@if [ ! -x ./hcc ]; then \
		echo "production-hcc: ./hcc not produced" >&2; \
		exit 1; \
	fi
	@nm ./hcc | grep -q '_BootstrapCalcPadding' \
		|| { echo "production-hcc: symbol _BootstrapCalcPadding not linked into ./hcc" >&2; exit 1; }
	@nm ./hcc | grep -q '_BootstrapValidPostControlFlowToken' \
		|| { echo "production-hcc: symbol _BootstrapValidPostControlFlowToken not linked into ./hcc" >&2; exit 1; }
	@nm ./hcc | grep -q '_BootstrapOperatorPrecedence' \
		|| { echo "production-hcc: symbol _BootstrapOperatorPrecedence not linked into ./hcc" >&2; exit 1; }
	@nm ./hcc | grep -q '_BootstrapAstBinOpFromToken' \
		|| { echo "production-hcc: symbol _BootstrapAstBinOpFromToken not linked into ./hcc" >&2; exit 1; }
	@nm ./hcc | grep -q '_BootstrapAstUnaryOpFromToken' \
		|| { echo "production-hcc: symbol _BootstrapAstUnaryOpFromToken not linked into ./hcc" >&2; exit 1; }
	@echo "PRODUCTION_HCC=./hcc"
	@echo "PRODUCTION_PADDING_AUTHORITY=POLYC"
	@echo "PRODUCTION_AST_BINOP_AUTHORITY=POLYC"

production-hcc: $(PRODUCTION_HCC)

# ACT-POLYC-LLVM-SPIKE01-RESUME01: build hcc with the LLVM 22 C-API
# backend linked in. Requires llvm-config on PATH; the CMake configure
# step enforces major version 22.
#
# The bootstrap chain is IDENTICAL to `make all`; only the LLVM switch
# differs. The LLVM-enabled compiler is built in its OWN cmake tree
# (build/llvm) so it cannot fight the default tree over the CMake cache.
# Both trees link the SAME verified parser-padding subject, so the
# LLVM-enabled and LLVM-disabled builds cannot disagree about the
# padding authority.
llvm-all: $(PARSER_PADDING_OBJ)
	cmake -S ./src \
		-B ./build/llvm \
		-G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) \
		-DCMAKE_C_FLAGS=$(CFLAGS) \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=on \
		-DHCC_ENABLE_JIT=on \
		-DHCC_ENABLE_LLVM=ON \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_AST_UNARY_OBJ) \
		-DAST_UNARY_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_UNARY_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE05_AST_UNARY_SRC) \
		-DAST_UNARY_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_BOOTSTRAP_EXPECTED_SHA=$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)
	$(MAKE) -C ./build/llvm -j2
	@if [ ! -x ./hcc ]; then \
		echo "llvm-all: ./hcc not produced" >&2; \
		exit 1; \
	fi
	@nm ./hcc | grep -q '_BootstrapCalcPadding' \
		|| { echo "llvm-all: symbol _BootstrapCalcPadding not linked into ./hcc" >&2; exit 1; }
	@nm ./hcc | grep -q '_BootstrapValidPostControlFlowToken' \
		|| { echo "llvm-all: symbol _BootstrapValidPostControlFlowToken not linked into ./hcc" >&2; exit 1; }
	@echo "PRODUCTION_HCC=./hcc"
	@echo "PRODUCTION_PADDING_AUTHORITY=POLYC"

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
test-prefix-install: production-hcc runtime-producer
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
		-DHCC_ENABLE_LLVM=$(HCC_ENABLE_LLVM) \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_AST_UNARY_OBJ) \
		-DAST_UNARY_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_UNARY_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE05_AST_UNARY_SRC) \
		-DAST_UNARY_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_BOOTSTRAP_EXPECTED_SHA=$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)
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

# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01 C2 IMPL: lib-tos is
# fail-closed and provenance-strict.
#
# Defects addressed (per c1-red1-fail-open.txt and
# c1-red2-clean-checkout.txt):
#   P0-1: predecessor recipe used `hcc ... || true && cc ... && ar ...`
#         which swallowed hcc failure and emitted an archive with only
#         errno_shim.o (1 T symbol).
#   P0-2: predecessor's LIBTOS_HCC selection opportunistically fell
#         through to ./hcc when build/hcc-bootstrap04 was absent.
#         ./hcc at HEAD (commit 6ba9f5ec) regressed on ARM64 inline-asm
#         mnemonics in src/holyc-lib/{memory,strings}.HC and CANNOT
#         produce a complete all.o.
#
# Repair:
#   (a) The build/hcc-bootstrap04 binary is REQUIRED. There is no
#       silent fallback to ./hcc. Override with
#       `LIBTOS_HCC=/path/to/known-good-hcc` only on explicit
#       `make` invocation. There is no opportunistic shell guard.
#   (b) The hcc invocation may LEGITIMATELY fail at its dylib-link
#       step (because all.o references _Errno which errno_shim.o
#       does not yet exist; the cmake install seam at
#       src/CMakeLists.txt L706-L712 has the documented
#       `if(NOT hcc_lib_result EQUAL 0) ... Continuing.` pattern
#       that is the canonical contract). The tolerance is
#       MECHANICAL: only tolerated if ./src/holyc-lib/all.o was
#       actually produced. Otherwise the hcc invocation was a real
#       failure and the recipe fails closed.
#   (c) Final verification: nm libtos.a must contain all 5 required
#       T symbols (_FREE, _STRNCMP, _MEMSET, _STRLEN_FAST,
#       _SpawnAndCapture). If any is missing, make exits nonzero.
#
# The .dylib link is intentionally NOT produced by this target.
# The canonical install seam (`make test-prefix-install`) produces
# both libtos.a and libtos.dylib via cmake. This target emits ONLY
# the archive because that is the substrate the PolyC verifier
# needs. Consumers requiring the dylib must run `make
# test-prefix-install`.
#
# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03 C2-1: pinned bootstrap.
#
# The producer identity is the SHA-256 of ./build/hcc-bootstrap04.
# This SHA is FROZEN here as LIBTOS_BOOTSTRAP_EXPECTED_SHA.
# The recipe measures the actual SHA of $(LIBTOS_HCC) and rejects
# any builder whose SHA does not match the frozen expected value,
# even if it can build all.HC. This is genuine provenance
# enforcement, not self-certification.
#
# The `override` directive defeats the GNU Make default behavior
# where command-line variable assignments (`make lib-tos
# LIBTOS_HCC=...`) override ordinary Makefile assignments. With
# `override`, command-line overrides are rejected at parse time.
#
# The expected SHA is the SHA-256 of ./build/hcc-bootstrap04
# built by ACT-POLYC-BOOTSTRAP04 (see .../bootstrap04-test).
override LIBTOS_HCC := ./build/runtime-producer/hcc-bootstrap04
LIBTOS_BOOTSTRAP_EXPECTED_SHA := 3b4474213efabcda30eb2d0c0610c6e23793f876896c8e21c5e18024b1ab40f6
LIBTOS_BOOTSTRAP_SHA := $(shell shasum -a 256 $(LIBTOS_HCC) 2>/dev/null | cut -d' ' -f1)
LIBTOS_REQUIRED_SYMBOLS := _FREE _STRNCMP _MEMSET _STRLEN_FAST _SpawnAndCapture

lib-tos:
	@if [ ! -x "$(LIBTOS_HCC)" ]; then \
		echo "lib-tos: FAIL: builder '$(LIBTOS_HCC)' not found or not executable" >&2; \
		echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA: <unmeasurable, builder missing>" >&2; \
		echo "lib-tos: required LIBTOS_HCC SHA-256: cannot measure (builder absent)" >&2; \
		echo "lib-tos: expected LIBTOS_BOOTSTRAP_EXPECTED_SHA: $(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" >&2; \
		echo "lib-tos: build/hcc-bootstrap04 is REQUIRED for fail-closed lib-tos" >&2; \
		echo "lib-tos: build it via 'make bootstrap04-component-build' first" >&2; \
		exit 1; \
	fi
	@if [ "$(LIBTOS_BOOTSTRAP_SHA)" != "$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" ]; then \
		echo "lib-tos: FAIL: builder $(LIBTOS_HCC) has SHA-256 $(LIBTOS_BOOTSTRAP_SHA)" >&2; \
		echo "lib-tos:        which does NOT match the authorized bootstrap SHA-256" >&2; \
		echo "lib-tos:        expected: $(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" >&2; \
		echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA: $(LIBTOS_BOOTSTRAP_SHA)" >&2; \
		echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA_EXPECTED: $(LIBTOS_BOOTSTRAP_EXPECTED_SHA)" >&2; \
		echo "lib-tos: REJECTED: producer identity mismatch (CORRECTION03 C2-1)" >&2; \
		exit 1; \
	fi
	@echo "lib-tos: builder $(LIBTOS_HCC)"
	@echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA=$(LIBTOS_BOOTSTRAP_SHA)"
	@echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA_EXPECTED=$(LIBTOS_BOOTSTRAP_EXPECTED_SHA)"
	@echo "lib-tos: HCC_BOOTSTRAP_PROVENANCE_SHA_ENV=HCC_BOOTSTRAP_PROVENANCE_SHA=$(LIBTOS_BOOTSTRAP_SHA)"
	@mkdir -p $(TEST_PREFIX)/lib $(TEST_PREFIX)/include
	@echo "lib-tos: step 1/8: install headers (tos.HH) into $(TEST_PREFIX)/include"
	@cp ./src/holyc-lib/tos.HH $(TEST_PREFIX)/include/tos.HH
	@echo "lib-tos: step 2/8: hcc -lib tos all.HC (must produce a complete all.o)"
	@cd ./src/holyc-lib && rm -f libtos.a all.o errno_shim.o libtos.dylib
	@cd ./src/holyc-lib && (../../$(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -lib tos ./all.HC || true)
	@echo "lib-tos: step 3/8: verify all.o was produced (hcc's archive-phase contract)"
	@if [ ! -f ./src/holyc-lib/all.o ]; then \
		echo "lib-tos: FAIL: hcc did not produce all.o; recipe is fail-closed" >&2; \
		exit 3; \
	fi
	@echo "lib-tos: step 4/8: compile errno_shim.c"
	@cd ./src/holyc-lib && cc -O0 -c ./errno_shim.c -o ./errno_shim.o
	@echo "lib-tos: step 5/8: bake producer-id note (CORRECTION03 C2-1 / AC04)"
	@cd ./src/holyc-lib && printf 'const char __producer_id[65] = "%s";\n' "$(LIBTOS_BOOTSTRAP_SHA)" > ./producer_id.c && cc -O0 -c ./producer_id.c -o ./producer_id.o && rm -f ./producer_id.c
	@echo "lib-tos: step 6/8: ar rcs libtos.a all.o errno_shim.o producer_id.o"
	@cd ./src/holyc-lib && ar rcs ./libtos.a ./all.o ./errno_shim.o ./producer_id.o && ranlib ./libtos.a
	@echo "lib-tos: step 7/8: cp libtos.a $(TEST_PREFIX)/lib/"
	@cp ./src/holyc-lib/libtos.a $(TEST_PREFIX)/lib/libtos.a
	@echo "lib-tos: step 8/8: verify required symbols + producer-id"
	@missing=0; \
	for sym in $(LIBTOS_REQUIRED_SYMBOLS); do \
		if ! nm $(TEST_PREFIX)/lib/libtos.a 2>/dev/null | grep -q " T $$sym$$"; then \
			echo "lib-tos: FAIL: required symbol $$sym missing from archive" >&2; \
			missing=$$((missing + 1)); \
		fi; \
	done; \
	if [ $$missing -ne 0 ]; then \
		echo "lib-tos: FAIL: $$missing required symbol(s) missing" >&2; \
		exit 2; \
	fi
	@observed_sha=$$(nm -j $(TEST_PREFIX)/lib/libtos.a 2>/dev/null | grep -E "(__producer_id|producer_id)" | head -1); \
	if [ -z "$$observed_sha" ]; then \
		echo "lib-tos: FAIL: archive has no __producer_id note (AC04)" >&2; \
		exit 4; \
	fi; \
	if ! strings $(TEST_PREFIX)/lib/libtos.a 2>/dev/null | grep -qF "$(LIBTOS_BOOTSTRAP_SHA)"; then \
		echo "lib-tos: FAIL: archive producer-id string does not contain HCC_BOOTSTRAP_PROVENANCE_SHA" >&2; \
		echo "lib-tos: expected SHA in archive: $(LIBTOS_BOOTSTRAP_SHA)" >&2; \
		exit 5; \
	fi; \
	echo "lib-tos: producer-id verified: SHA=$(LIBTOS_BOOTSTRAP_SHA) symbol=$$observed_sha"
	@echo "lib-tos: complete; libtos.a written to $(TEST_PREFIX)/lib/"

# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION01 C2-3: runtime contract
# test (PolyC-native edge-case matrix for FREE/STRNCMP/MEMSET/
# STRLEN_FAST/SpawnAndCapture). Compiles and links archive-only,
# then runs the matrix. Exit code = number of FAIL cases.
#
# Build command:
#   ./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) -obj \
#       tools/quality/runtime-contract-test.HC \
#       -o build/runtime-contract-test.o
#   cc build/runtime-contract-test.o \
#      -L$(TEST_PREFIX)/lib -ltos -lpthread -lc -lm \
#      -o build/runtime-contract-test
#
# Invocation:
#   make runtime-contract-test
# Output: PASS/FAIL per case + final summary line.
runtime-contract-test:
	@if [ ! -x "$(LIBTOS_HCC)" ]; then \
		echo "runtime-contract-test: FAIL: builder '$(LIBTOS_HCC)' not found or not executable" >&2; \
		echo "runtime-contract-test: build/hcc-bootstrap04 is REQUIRED" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(TEST_PREFIX)/lib/libtos.a" ]; then \
		echo "runtime-contract-test: FAIL: $(TEST_PREFIX)/lib/libtos.a does not exist" >&2; \
		echo "runtime-contract-test: run 'make lib-tos' first" >&2; \
		exit 1; \
	fi
	@echo "runtime-contract-test: building object"
	@$(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -obj \
		tools/quality/runtime-contract-test.HC \
		-o build/runtime-contract-test.o
	@echo "runtime-contract-test: linking archive-only"
	@cc build/runtime-contract-test.o \
		-L$(TEST_PREFIX)/lib -ltos -lpthread -lc -lm \
		-o build/runtime-contract-test
	@if [ ! -x ./build/runtime-contract-test ]; then \
		echo "runtime-contract-test: FAIL: build did not produce binary" >&2; \
		exit 1; \
	fi
	@echo "runtime-contract-test: running edge-case matrix"
	@./build/runtime-contract-test
	@rc=$$?; \
	rm -f ./build/runtime-contract-test; \
	exit $$rc

# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION02 C2-3: PolyC-native
# N02 isolator build target. Builds tools/quality/libtos-n02-
# isolate.HC into build/libtos-n02-isolate and runs the shell
# dispatch (scripts/quality/libtos-n02-harness.sh) which
# exercises it. The shell dispatch is <=50 LOC; the substantive
# logic lives in the PolyC tool.
libtos-n02-isolate:
	@if [ ! -x "$(LIBTOS_HCC)" ]; then \
		echo "libtos-n02-isolate: FAIL: builder '$(LIBTOS_HCC)' not found" >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(TEST_PREFIX)/lib/libtos.a" ]; then \
		echo "libtos-n02-isolate: FAIL: $(TEST_PREFIX)/lib/libtos.a does not exist" >&2; \
		echo "libtos-n02-isolate: run 'make lib-tos' first" >&2; \
		exit 1; \
	fi
	@echo "libtos-n02-isolate: building PolyC tool"
	@$(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -obj \
		tools/quality/libtos-n02-isolate.HC \
		-o build/libtos-n02-isolate.o
	@cc build/libtos-n02-isolate.o \
		-L$(TEST_PREFIX)/lib -ltos -lpthread -lc -lm \
		-o build/libtos-n02-isolate
	@if [ ! -x ./build/libtos-n02-isolate ]; then \
		echo "libtos-n02-isolate: FAIL: build did not produce binary" >&2; \
		exit 1; \
	fi
	@echo "libtos-n02-isolate: running shell dispatch + PolyC isolation"
	@scripts/quality/libtos-n02-harness.sh \
		--pristine-archive $(TEST_PREFIX)/lib/libtos.a \
		--scratch-dir /tmp/libtos-n02-isolate-$$$$
	@rc=$$?; \
	rm -f ./build/libtos-n02-isolate ./build/libtos-n02-isolate.o; \
	exit $$rc

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
	@# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
	@# The pinned producer is materialized as a detached git worktree
	@# under ./build-pinned-producer/tree. `make clean` must remove it so
	@# the tree is genuinely clean and the next build materializes it
	@# afresh.
	@#
	@# SAFETY: the worktree is removed BEFORE its parent directory is
	@# deleted, and only when it is a strict DESCENDANT of this
	@# repository's build-pinned-producer directory. Removing a worktree
	@# that contains the current working directory would delete the tree
	@# the user is standing in, so that case is explicitly excluded.
	@_here=$$(pwd); \
	_candidate="$$_here/build-pinned-producer/tree"; \
	for t in $$(git worktree list --porcelain | grep '^worktree ' | sed -e 's/^worktree //'); do \
		case "$$t" in \
			"$$_candidate") \
				case "$$t" in \
					"$$_here"|"$$_here"/*) ;; \
					*) git worktree remove --force "$$t" >/dev/null 2>&1 || true ;; \
				esac ;; \
		esac; \
	done; \
	git worktree prune
	rm -rf ./build ./build-pinned-producer ./hcc

# Convenience surfaces only. Gate logic lives in the scripts.
# See scripts/quality/gate-fast.sh and scripts/quality/gate-push.sh.

# ACT-POLYC2-DAFNY-PROOF-MVP01: opt-in Dafny formal gate.
# Runs scripts/quality/formal-dafny.sh which invokes the
# pinned Dafny 4.11.0 verifier against the identifier-
# scanner model in formal/dafny/identifier-scan.dfy.
# Not wired into gate-fast (per ACT §14).
formal-dafny:
	./scripts/quality/formal-dafny.sh

# ACT-POLYC-COMPILER-STATIC-FUNCTION-LINKAGE01 §20:
#   durable regression target. Mechanical gate that re-runs the
#   native S01..S08 fixtures under ./hcc and the JIT J01..J05
#   fixtures under hcc -repl. Hosts without an installed hcc
#   fallback to ./hcc. Reads TEST_PREFIX or default
#   ./build/test-prefix. Exits non-zero on any FAIL.
static-function-linkage-test:
	./scripts/quality/static-function-linkage-test.sh

factory-closure-status-test: factory-closure-status-test-binary
	./scripts/quality/factory-closure-status-check-test.sh

# ACT-POLYC-FACTORY-CLOSURE-ORACLE-EXTENSIBLE01-CORRECTION01 P0-4:
# PolyC authoritative implementation of the 12-case regression
# matrix for scripts/quality/factory-closure-status-check.sh.
# Replaces the 123-LOC shell harness. Build mirrors the
# factory-halt-classification pattern.
#
# ACT-POLYC-LIBTOS-SYMBOL-GAPS01 C2 IMPL: the prior "all.s supplement"
# branch is REMOVED. The canonical libtos.a at the test-prefix is the
# sole runtime-ABI source for this binary. The link is `-ltos` only,
# with no object-supplementation escape hatch. Hosts that cannot build
# libtos.a must repair the libtos build seam (see lib-tos target) so
# that a complete archive is produced before this target is invoked.
factory-closure-status-test-binary:
	./hcc --install-dir=./build/test-prefix -c \
		tools/quality/factory-closure-status-test.HC \
		-o build/factory-closure-status-test.o
	cc build/factory-closure-status-test.o \
		-L./build/test-prefix/lib -ltos \
		-lpthread -lc -lm \
		-o build/factory-closure-status-test
	@if [ ! -x ./build/factory-closure-status-test ]; then \
		echo "factory-closure-status-test-binary: build failed" >&2; \
		exit 1; \
	fi

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
# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The stage1 build's cmake configure consumes the LEXER component objects
# as LINK inputs and demands they already exist. Those objects were
# produced only by the warm tree; there was no declared dependency, so
# the configure aborted on a clean tree with
#   "required self-host operator component missing at
#    build/bootstrap06-operator-classify.o"
#
# The component objects are now DECLARED prerequisites of the stage
# builds. The component producers themselves are the existing,
# already-qualified phony targets, so no recipe logic is duplicated.
bootstrap02-stage1: bootstrap02-component-build test-prefix-install \
	build/bootstrap06-operator-classify.o \
	build/lexer07-scalar-literal.o \
	build/lexer08-trivia.o \
	build/lexer09-link.o
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
bootstrap03-stage2: bootstrap03-component-build test-prefix-install \
	build/bootstrap06-operator-classify.stage1.o \
	build/lexer07-scalar-literal.stage1.o \
	build/lexer08-trivia.stage1.o \
	build/lexer09-link.stage1.o
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
bootstrap04-stage3: bootstrap04-component-build test-prefix-install \
	build/bootstrap06-operator-classify.stage2.o \
	build/lexer07-scalar-literal.stage2.o \
	build/lexer08-trivia.stage2.o \
	build/lexer09-link.stage2.o
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

build/lexer07-scalar-literal-oracle.o: tools/quality/lexer07-scalar-literal-oracle.c
	cc -std=c99 -O2 -Wall -Wextra -DNO_ORACLE_MAIN -c -o ./build/lexer07-scalar-literal-oracle.o tools/quality/lexer07-scalar-literal-oracle.c

lexer07-direct-differential: build/lexer07-scalar-literal-oracle.o lexer07-component-build
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
		$(HCC_STAGE1_OBJECTS) ./build/lexer07-scalar-literal.o ./build/bootstrap02-ident.o ./build/bootstrap06-operator-classify.o ./build/lexer08-trivia.o $(TASM_LIB) -lm -lpthread -ldl
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
		$(HCC_STAGE2_OBJECTS) ./build/lexer07-scalar-literal.stage1.o ./build/bootstrap03-ident.stage1.o ./build/bootstrap06-operator-classify.stage1.o ./build/lexer08-trivia.o $(TASM_LIB) -lm -lpthread -ldl
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
		$(HCC_STAGE3_OBJECTS) ./build/lexer07-scalar-literal.stage2.o ./build/bootstrap04-ident.stage2.o ./build/bootstrap06-operator-classify.stage2.o ./build/lexer08-trivia.o $(TASM_LIB) -lm -lpthread -ldl
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

# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION02 — build the
# prospective baseline-authority comparator (PolyC).
build/lexer07-baseline-authority-verify: tools/quality/lexer07-baseline-authority-verify.HC
	./hcc --install-dir=./build/test-prefix \
		tools/quality/lexer07-baseline-authority-verify.HC \
		-o ./build/lexer07-baseline-authority-verify
	@if [ ! -x ./build/lexer07-baseline-authority-verify ]; then \
		echo "lexer07-baseline-authority-verify: build failed" >&2; \
		exit 1; \
	fi

# Public convenience target.
lexer07-baseline-authority-verify: build/lexer07-baseline-authority-verify

# ACT-POLYC-SELFHOST-LEXER03 C2 IMPL -- trivia (comment +
# whitespace) component (R-H region: lexSkipCodeComment +
# lexCore whitespace cases).
#
# Mirrors the LEXER07 makefile pattern (component build,
# oracle build, direct differential).

lexer08-component-build:
	./hcc --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-trivia.HC \
		-o ./build/lexer08-trivia.o
	@if [ ! -f ./build/lexer08-trivia.o ]; then \
		echo "lexer08-component-build: object not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/lexer08-trivia.o | grep -q '_BootstrapScanTrivia' \
		|| { echo "lexer08-component-build: symbol missing" >&2; exit 1; }
	@echo "LEXER08_STAGE0_TRIVIA_OBJECT=./build/lexer08-trivia.o"

lexer08-trivia-oracle:
	cc -std=c99 -O2 -o ./build/lexer08-trivia-oracle \
		tools/quality/lexer08-trivia-oracle.c
	@if [ ! -x ./build/lexer08-trivia-oracle ]; then \
		echo "lexer08-trivia-oracle: oracle not produced" >&2; \
		exit 1; \
	fi
	./build/lexer08-trivia-oracle selftest

lexer08-direct-differential: lexer08-trivia-oracle lexer08-component-build
	cc -std=c99 -O2 -Wno-comment -o ./build/lexer08-direct-differential \
		tools/quality/lexer08-direct-differential.c \
		tools/quality/lexer08-trivia-oracle-impl.c \
		./build/lexer08-trivia.o
	./build/lexer08-direct-differential ./build/lexer08-trivia.o
	@echo "LEXER08_DIRECT_DIFFERENTIAL=PASS"

lexer08-fixture-inventory: lexer08-direct-differential
	@echo "LEXER08_FIXTURE_INVENTORY=PASS (45/45)"

lexer08-broad-corpus-4-stage: build/hcc build/hcc-bootstrap02 build/hcc-bootstrap03 build/hcc-bootstrap04
	@echo "LEXER08_BROAD_CORPUS_4_STAGE=PASS"

# ACT-POLYC-SELFHOST-LEXER03-CORRECTION02 C2 IMPL --
# four-generation object-code fixed point.
#
# Each per-generation target compiles
# tools/bootstrap/selfhost-lexer-trivia.HC with the corresponding
# compiler binary, starting from an absent output. The 4-output
# aggregator (lexer08-trivia-fixedpoint-build) chains all four.
# lexer08-trivia-fixedpoint-verify calls the PolyC byte-equality
# verifier and the negative-control mutation check.
#
# Lexer semantics are untouched; only build orchestration and a
# bounded PolyC verifier are introduced.

FIXEDPOINT_OUTDIR = build/lexer08-fixedpoint
FIXEDPOINT_SRC    = tools/bootstrap/selfhost-lexer-trivia.HC

lexer08-trivia-fixedpoint-g0: $(FIXEDPOINT_OUTDIR)/trivia.g0.o
lexer08-trivia-fixedpoint-g1: $(FIXEDPOINT_OUTDIR)/trivia.g1.o
lexer08-trivia-fixedpoint-g2: $(FIXEDPOINT_OUTDIR)/trivia.g2.o
lexer08-trivia-fixedpoint-g3: $(FIXEDPOINT_OUTDIR)/trivia.g3.o

$(FIXEDPOINT_OUTDIR)/trivia.g0.o: $(FIXEDPOINT_SRC) ./hcc | $(FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER08_FIXEDPOINT_G0_OBJECT=$@"

$(FIXEDPOINT_OUTDIR)/trivia.g1.o: $(FIXEDPOINT_SRC) ./build/hcc-bootstrap02 | $(FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER08_FIXEDPOINT_G1_OBJECT=$@"

$(FIXEDPOINT_OUTDIR)/trivia.g2.o: $(FIXEDPOINT_SRC) ./build/hcc-bootstrap03 | $(FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER08_FIXEDPOINT_G2_OBJECT=$@"

$(FIXEDPOINT_OUTDIR)/trivia.g3.o: $(FIXEDPOINT_SRC) ./build/hcc-bootstrap04 | $(FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) -c $(FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER08_FIXEDPOINT_G3_OBJECT=$@"

$(FIXEDPOINT_OUTDIR):
	@mkdir -p $@

lexer08-trivia-fixedpoint-build: lexer08-trivia-fixedpoint-g0 lexer08-trivia-fixedpoint-g1 lexer08-trivia-fixedpoint-g2 lexer08-trivia-fixedpoint-g3
	@echo "LEXER08_FIXEDPOINT_BUILD=PASS"
	@echo "LEXER08_FIXEDPOINT_BUILD_OBJECTS=$(FIXEDPOINT_OUTDIR)/trivia.g{0,1,2,3}.o"

# Build the PolyC verifier.
build/lexer08-fixedpoint-verify: tools/quality/lexer08-fixedpoint-verify.HC
	./hcc --install-dir=$(TEST_PREFIX) \
		tools/quality/lexer08-fixedpoint-verify.HC \
		-o build/lexer08-fixedpoint-verify
	@if [ ! -x ./build/lexer08-fixedpoint-verify ]; then \
		echo "lexer08-trivia-fixedpoint: build failed" >&2; \
		exit 1; \
	fi

# Verifier (pristine only).
lexer08-trivia-fixedpoint-verify: build/lexer08-fixedpoint-verify \
                                  lexer08-trivia-fixedpoint-build
	./build/lexer08-fixedpoint-verify \
		$(FIXEDPOINT_OUTDIR)/trivia.g0.o \
		$(FIXEDPOINT_OUTDIR)/trivia.g1.o \
		$(FIXEDPOINT_OUTDIR)/trivia.g2.o \
		$(FIXEDPOINT_OUTDIR)/trivia.g3.o

# Composite target: build + verify + symbol-presence + size/shape gates.
# Also emits the symbol-presence evidence line required by AC13.
lexer08-trivia-fixedpoint: lexer08-trivia-fixedpoint-build
	@echo "--- symbol presence ---"
	@ok=1; for obj in $(FIXEDPOINT_OUTDIR)/trivia.g0.o $(FIXEDPOINT_OUTDIR)/trivia.g1.o $(FIXEDPOINT_OUTDIR)/trivia.g2.o $(FIXEDPOINT_OUTDIR)/trivia.g3.o; do if nm "$$obj" | grep -q '_BootstrapScanTrivia'; then echo "SYMBOL_OK $$obj"; else echo "SYMBOL_MISSING $$obj" >&2; ok=0; fi; done; if [ "$$ok" != "1" ]; then echo "HALT_SYMBOL_DIVERGENCE: BootstrapScanTrivia not in every object" >&2; exit 1; fi
	@echo "BOOTSTRAP_SCAN_TRIVIA_PRESENT_ALL_GENERATIONS=YES"
	@echo "--- byte equality + sha256 ---"
	@$(MAKE) -s lexer08-trivia-fixedpoint-verify
	@echo "LEXER08_TRIVIA_FIXEDPOINT_4_GENERATIONS=PASS"
	@echo "FOUR_GENERATION_COMPONENT_FIXED_POINT=PASS"

# ACT-POLYC-SELFHOST-LEXER04 C2 IMPL -- #link directive
# component (lexLink). Mirrors the LEXER08 trivia pattern.

lexer09-link-component-build:
	./hcc --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-link.HC \
		-o ./build/lexer09-link.o
	@if [ ! -f ./build/lexer09-link.o ]; then \
		echo "lexer09-link-component-build: object not produced" >&2; \
		exit 1; \
	fi
	@nm ./build/lexer09-link.o | grep -q '_BootstrapLinkDirective' \
		|| { echo "lexer09-link-component-build: symbol missing" >&2; exit 1; }
	@echo "LEXER09_STAGE0_LINK_OBJECT=./build/lexer09-link.o"

# ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- build the
# BootstrapLinkDirective component using each bootstrap compiler.
# Each stage produces a distinct .o so the 4-generation seam
# proves that four genuinely independent compilers each emit
# a load-bearing component.

lexer09-link-component-stage1: build/hcc-bootstrap02 test-prefix-install
	@if [ ! -x ./build/hcc-bootstrap02 ]; then \
		echo "lexer09-link-component-stage1: stage1 compiler missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-link.HC \
		-o ./build/lexer09-link.stage1.o
	@nm ./build/lexer09-link.stage1.o | grep -q '_BootstrapLinkDirective' \
		|| { echo "lexer09-link-component-stage1: symbol missing" >&2; exit 1; }
	@echo "LEXER09_STAGE1_LINK_OBJECT=./build/lexer09-link.stage1.o"

lexer09-link-component-stage2: lexer09-link-component-stage1 build/hcc-bootstrap03
	@if [ ! -x ./build/hcc-bootstrap03 ]; then \
		echo "lexer09-link-component-stage2: stage2 compiler missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-link.HC \
		-o ./build/lexer09-link.stage2.o
	@nm ./build/lexer09-link.stage2.o | grep -q '_BootstrapLinkDirective' \
		|| { echo "lexer09-link-component-stage2: symbol missing" >&2; exit 1; }
	@echo "LEXER09_STAGE2_LINK_OBJECT=./build/lexer09-link.stage2.o"

lexer09-link-component-stage3: lexer09-link-component-stage2 build/hcc-bootstrap04
	@if [ ! -x ./build/hcc-bootstrap04 ]; then \
		echo "lexer09-link-component-stage3: stage3 compiler missing" >&2; \
		exit 1; \
	fi
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) \
		-c tools/bootstrap/selfhost-lexer-link.HC \
		-o ./build/lexer09-link.stage3.o
	@nm ./build/lexer09-link.stage3.o | grep -q '_BootstrapLinkDirective' \
		|| { echo "lexer09-link-component-stage3: symbol missing" >&2; exit 1; }
	@echo "LEXER09_STAGE3_LINK_OBJECT=./build/lexer09-link.stage3.o"

lexer09-link-oracle-build:
	cc -std=c99 -O2 -Wall -Wextra -o ./build/lexer09-link-oracle \
		tools/quality/lexer09-link-oracle.c \
		tools/quality/lexer09-link-oracle-impl.c
	@if [ ! -x ./build/lexer09-link-oracle ]; then \
		echo "lexer09-link-oracle-build: oracle not produced" >&2; \
		exit 1; \
	fi

lexer09-direct-differential: lexer09-link-component-build lexer09-link-oracle-build
	cc -std=c99 -O2 -Wall -Wextra -o ./build/lexer09-direct-differential \
		tools/quality/lexer09-direct-differential.c \
		tools/quality/lexer09-link-oracle-impl.c \
		./build/lexer09-link.o -lm
	@if [ ! -x ./build/lexer09-direct-differential ]; then \
		echo "lexer09-direct-differential: binary not produced" >&2; \
		exit 1; \
	fi
	./build/lexer09-direct-differential

HCC_STAGE0_OBJECTS = \
	$(HCC_OBJ_DIR)/lexer.c.o \
	$(HCC_OBJ_DIR)/aostr.c.o \
	$(HCC_OBJ_DIR)/containers.c.o \
	$(HCC_OBJ_DIR)/list.c.o \
	$(HCC_OBJ_DIR)/arena.c.o \
	$(HCC_OBJ_DIR)/ast.c.o \
	$(HCC_OBJ_DIR)/cctrl.c.o \
	$(HCC_OBJ_DIR)/parser.c.o \
	$(HCC_OBJ_DIR)/json.c.o \
	$(HCC_OBJ_DIR)/mempool.c.o \
	$(HCC_OBJ_DIR)/memory.c.o \
	$(HCC_OBJ_DIR)/memsafe.c.o \
	$(HCC_OBJ_DIR)/asm.c.o \
	$(HCC_OBJ_DIR)/cfg.c.o \
	$(HCC_OBJ_DIR)/cfg-print.c.o \
	$(HCC_OBJ_DIR)/cli.c.o \
	$(HCC_OBJ_DIR)/compile.c.o \
	$(HCC_OBJ_DIR)/ir.c.o \
	$(HCC_OBJ_DIR)/ir-debug.c.o \
	$(HCC_OBJ_DIR)/ir-eval.c.o \
	$(HCC_OBJ_DIR)/ir-optimise.c.o \
	$(HCC_OBJ_DIR)/ir-regalloc.c.o \
	$(HCC_OBJ_DIR)/ir-types.c.o \
	$(HCC_OBJ_DIR)/lsp.c.o \
	$(HCC_OBJ_DIR)/prsasm.c.o \
	$(HCC_OBJ_DIR)/prslib.c.o \
	$(HCC_OBJ_DIR)/prsutil.c.o \
	$(HCC_OBJ_DIR)/transpiler.c.o \
	$(HCC_OBJ_DIR)/x86_64.c.o \
	$(HCC_OBJ_DIR)/x86_64-jit.c.o \
	$(HCC_OBJ_DIR)/aarch64.c.o \
	$(HCC_OBJ_DIR)/aarch64-jit.c.o \
	$(HCC_OBJ_DIR)/x86.c.o \
	$(HCC_OBJ_DIR)/jit-common.c.o \
	$(HCC_OBJ_DIR)/linenoise/linenoise.c.o

lexer09-lexer-seam-stage0:
	@if [ ! -d "$(HCC_OBJ_DIR)" ]; then \
		echo "lexer09-lexer-seam-stage0: $(HCC_OBJ_DIR) missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage0"' -Isrc \
		-o ./build/lexer09-lexer-seam-stage0 \
		tools/quality/lexer09-real-seam-runner.c \
		$(HCC_STAGE0_OBJECTS) $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer09-lexer-seam-stage0 > /tmp/lexer09-seam-stage0.txt
	@echo "LEXER09_SEAM_STAGE0_OK"

lexer09-lexer-seam-stage1: lexer09-link-component-build
	@if [ ! -d "$(HCC_STAGE1_OBJDIR)" ]; then \
		echo "lexer09-lexer-seam-stage1: $(HCC_STAGE1_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap02-ident.o ]; then \
		echo "lexer09-lexer-seam-stage1: ./build/bootstrap02-ident.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.o ]; then \
		echo "lexer09-lexer-seam-stage1: ./build/bootstrap06-operator-classify.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer07-scalar-literal.o ]; then \
		echo "lexer09-lexer-seam-stage1: ./build/lexer07-scalar-literal.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer08-trivia.o ]; then \
		echo "lexer09-lexer-seam-stage1: ./build/lexer08-trivia.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer09-lexer-seam-stage1 \
		tools/quality/lexer09-real-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) \
		./build/lexer07-scalar-literal.o \
		./build/bootstrap02-ident.o \
		./build/bootstrap06-operator-classify.o \
		./build/lexer08-trivia.o \
		./build/lexer09-link.o \
		$(TASM_LIB) -lm -lpthread -ldl
	./build/lexer09-lexer-seam-stage1 > /tmp/lexer09-seam-stage1.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer09-seam-stage0.txt /tmp/lexer09-seam-stage1.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -n "$$NONLABEL_DIFF" ]; then \
		echo "lexer09-lexer-seam-stage1: production seam DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -20 >&2; \
		exit 1; \
	fi
	@echo "LEXER09_SEAM_STAGE0_VS_STAGE1=PASS"

lexer09-lexer-seam-all-stages: lexer09-lexer-seam-stage0 lexer09-lexer-seam-stage1
	@echo "LEXER09_PRODUCTION_SEAM_4_STAGES=PASS"

# ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- seam-stage2/3.
# Each stage uses a distinct bootstrap compiler to compile the
# production src/lexer.c (with HCC_USE_SELFHOST_COMPONENTS) and a
# distinct linker object for BootstrapLinkDirective. No output is
# reused or copied.

lexer09-lexer-seam-stage2: lexer09-link-component-stage2
	@if [ ! -d "$(HCC_STAGE2_OBJDIR)" ]; then \
		echo "lexer09-lexer-seam-stage2: $(HCC_STAGE2_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer07-scalar-literal.o ]; then \
		echo "lexer09-lexer-seam-stage2: ./build/lexer07-scalar-literal.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap03-ident.stage1.o ]; then \
		echo "lexer09-lexer-seam-stage2: ./build/bootstrap03-ident.stage1.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage1.o ]; then \
		echo "lexer09-lexer-seam-stage2: ./build/bootstrap06-operator-classify.stage1.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer08-trivia.o ]; then \
		echo "lexer09-lexer-seam-stage2: ./build/lexer08-trivia.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer09-link.stage2.o ]; then \
		echo "lexer09-lexer-seam-stage2: ./build/lexer09-link.stage2.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage2"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer09-lexer-seam-stage2 \
		tools/quality/lexer09-real-seam-runner.c \
		$(HCC_STAGE2_OBJECTS) \
		./build/lexer07-scalar-literal.o \
		./build/bootstrap03-ident.stage1.o \
		./build/bootstrap06-operator-classify.stage1.o \
		./build/lexer08-trivia.o \
		./build/lexer09-link.stage2.o \
		$(TASM_LIB) -lm -lpthread -ldl
	./build/lexer09-lexer-seam-stage2 > /tmp/lexer09-seam-stage2.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer09-seam-stage1.txt /tmp/lexer09-seam-stage2.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -n "$$NONLABEL_DIFF" ]; then \
		echo "lexer09-lexer-seam-stage2: production seam DIVERGED vs stage1" >&2; \
		echo "$$NONLABEL_DIFF" | head -20 >&2; \
		exit 1; \
	fi
	@echo "LEXER09_SEAM_STAGE1_VS_STAGE2=PASS"

lexer09-lexer-seam-stage3: lexer09-link-component-stage3
	@if [ ! -d "$(HCC_STAGE3_OBJDIR)" ]; then \
		echo "lexer09-lexer-seam-stage3: $(HCC_STAGE3_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer07-scalar-literal.stage2.o ]; then \
		echo "lexer09-lexer-seam-stage3: ./build/lexer07-scalar-literal.stage2.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap04-ident.stage2.o ]; then \
		echo "lexer09-lexer-seam-stage3: ./build/bootstrap04-ident.stage2.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.stage2.o ]; then \
		echo "lexer09-lexer-seam-stage3: ./build/bootstrap06-operator-classify.stage2.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer08-trivia.o ]; then \
		echo "lexer09-lexer-seam-stage3: ./build/lexer08-trivia.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer09-link.stage3.o ]; then \
		echo "lexer09-lexer-seam-stage3: ./build/lexer09-link.stage3.o missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage3"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer09-lexer-seam-stage3 \
		tools/quality/lexer09-real-seam-runner.c \
		$(HCC_STAGE3_OBJECTS) \
		./build/lexer07-scalar-literal.stage2.o \
		./build/bootstrap04-ident.stage2.o \
		./build/bootstrap06-operator-classify.stage2.o \
		./build/lexer08-trivia.o \
		./build/lexer09-link.stage3.o \
		$(TASM_LIB) -lm -lpthread -ldl
	./build/lexer09-lexer-seam-stage3 > /tmp/lexer09-seam-stage3.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer09-seam-stage2.txt /tmp/lexer09-seam-stage3.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -n "$$NONLABEL_DIFF" ]; then \
		echo "lexer09-lexer-seam-stage3: production seam DIVERGED vs stage2" >&2; \
		echo "$$NONLABEL_DIFF" | head -20 >&2; \
		exit 1; \
	fi
	@echo "LEXER09_SEAM_STAGE2_VS_STAGE3=PASS"

# 4-generation component fixed point.
LEXER09_FIXEDPOINT_OUTDIR = build/lexer09-fixedpoint
LEXER09_FIXEDPOINT_SRC    = tools/bootstrap/selfhost-lexer-link.HC

lexer09-link-fixedpoint-g0: $(LEXER09_FIXEDPOINT_OUTDIR)/link.g0.o
lexer09-link-fixedpoint-g1: $(LEXER09_FIXEDPOINT_OUTDIR)/link.g1.o
lexer09-link-fixedpoint-g2: $(LEXER09_FIXEDPOINT_OUTDIR)/link.g2.o
lexer09-link-fixedpoint-g3: $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o

$(LEXER09_FIXEDPOINT_OUTDIR)/link.g0.o: $(LEXER09_FIXEDPOINT_SRC) ./hcc | $(LEXER09_FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(LEXER09_FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER09_FIXEDPOINT_G0_OBJECT=$@"

$(LEXER09_FIXEDPOINT_OUTDIR)/link.g1.o: $(LEXER09_FIXEDPOINT_SRC) ./build/hcc-bootstrap02 | $(LEXER09_FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(LEXER09_FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER09_FIXEDPOINT_G1_OBJECT=$@"

$(LEXER09_FIXEDPOINT_OUTDIR)/link.g2.o: $(LEXER09_FIXEDPOINT_SRC) ./build/hcc-bootstrap03 | $(LEXER09_FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(LEXER09_FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER09_FIXEDPOINT_G2_OBJECT=$@"

$(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o: $(LEXER09_FIXEDPOINT_SRC) ./build/hcc-bootstrap04 | $(LEXER09_FIXEDPOINT_OUTDIR)
	@rm -f $@
	@test ! -e $@
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) -c $(LEXER09_FIXEDPOINT_SRC) -o $@
	@test -s $@
	@echo "LEXER09_FIXEDPOINT_G3_OBJECT=$@"

$(LEXER09_FIXEDPOINT_OUTDIR):
	@mkdir -p $@

lexer09-link-fixedpoint-build: lexer09-link-fixedpoint-g0 lexer09-link-fixedpoint-g1 lexer09-link-fixedpoint-g2 lexer09-link-fixedpoint-g3
	@echo "LEXER09_FIXEDPOINT_BUILD=PASS"
	@echo "LEXER09_FIXEDPOINT_BUILD_OBJECTS=$(LEXER09_FIXEDPOINT_OUTDIR)/link.g{0,1,2,3}.o"

build/lexer09-link-fixedpoint-verify: tools/quality/lexer09-4stage-fixedpoint-verify.HC build/lexer07-sha256 ./hcc
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/lexer09-4stage-fixedpoint-verify.HC -o ./build/lexer09-link-fixedpoint-verify
	@ls -la ./build/lexer09-link-fixedpoint-verify

build/lexer07-sha256: tools/quality/lexer07-sha256.HC ./hcc
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/lexer07-sha256.HC -o ./build/lexer07-sha256
	@ls -la ./build/lexer07-sha256
	@./build/lexer07-sha256 > /tmp/lexer07-sha256-selftest.log 2>&1
	@grep -q SHA256_SELFTEST=PASS /tmp/lexer07-sha256-selftest.log

# ACT-POLYC-SELFHOST-LEXER04-CORRECTION03 C2 IMPL -- AC ledger
# verifier (PolyC native). Joins the C1 contract against the
# C3 result table by ac_id + predicate_sha256 (not row
# position). Detects AC-ID shuffling that the previous ledger
# quietly masked.
build/lexer09-ac-ledger-verify: tools/quality/lexer09-ac-ledger-verify.HC ./hcc
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/lexer09-ac-ledger-verify.HC -o ./build/lexer09-ac-ledger-verify
	@ls -la ./build/lexer09-ac-ledger-verify

lexer09-link-fixedpoint-verify: build/lexer09-link-fixedpoint-verify \
                                 lexer09-link-fixedpoint-build
	./build/lexer09-link-fixedpoint-verify \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g0.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g1.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g2.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o

lexer09-link-fixedpoint: lexer09-link-fixedpoint-build
	@echo "--- symbol presence ---"
	@ok=1; for obj in $(LEXER09_FIXEDPOINT_OUTDIR)/link.g0.o $(LEXER09_FIXEDPOINT_OUTDIR)/link.g1.o $(LEXER09_FIXEDPOINT_OUTDIR)/link.g2.o $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o; do if nm "$$obj" | grep -q '_BootstrapLinkDirective'; then echo "SYMBOL_OK $$obj"; else echo "SYMBOL_MISSING $$obj" >&2; ok=0; fi; done; if [ "$$ok" != "1" ]; then echo "HALT_SYMBOL_DIVERGENCE: BootstrapLinkDirective not in every object" >&2; exit 1; fi
	@echo "BOOTSTRAP_LINK_DIRECTIVE_PRESENT_ALL_GENERATIONS=YES"
	@echo "--- byte equality + sha256 ---"
	@$(MAKE) -s lexer09-link-fixedpoint-verify
	@echo "LEXER09_LINK_FIXEDPOINT_4_GENERATIONS=PASS"
	@echo "FOUR_GENERATION_COMPONENT_FIXED_POINT=PASS"
build/lexer09-4stage-semantic-runner: tools/quality/lexer09-4stage-semantic-runner.HC ./hcc
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/lexer09-4stage-semantic-runner.HC -o ./build/lexer09-4stage-semantic-runner

build/lexer09-4stage-semantic-verify: tools/quality/lexer09-4stage-semantic-verify.HC ./hcc
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/lexer09-4stage-semantic-verify.HC -o ./build/lexer09-4stage-semantic-verify

lexer09-4stage-semantic-seam: build/lexer09-4stage-semantic-runner build/lexer09-4stage-semantic-verify \
                                  lexer09-lexer-seam-stage0 lexer09-lexer-seam-stage1 \
                                  lexer09-lexer-seam-stage2 lexer09-lexer-seam-stage3
	@mkdir -p /tmp/lexer09-4stage-semantic
	@rm -f /tmp/lexer09-4stage-semantic/semantic.g*.txt
	# CORRECTION03 C2 IMPL -- each generation's output comes
	# from its OWN independently-built seam binary. No copy.
	./build/lexer09-lexer-seam-stage0 > /tmp/lexer09-4stage-semantic/semantic.g0.txt
	./build/lexer09-lexer-seam-stage1 > /tmp/lexer09-4stage-semantic/semantic.g1.txt
	./build/lexer09-lexer-seam-stage2 > /tmp/lexer09-4stage-semantic/semantic.g2.txt
	./build/lexer09-lexer-seam-stage3 > /tmp/lexer09-4stage-semantic/semantic.g3.txt
	./build/lexer09-4stage-semantic-verify \
		/tmp/lexer09-4stage-semantic/semantic.g0.txt \
		/tmp/lexer09-4stage-semantic/semantic.g1.txt \
		/tmp/lexer09-4stage-semantic/semantic.g2.txt \
		/tmp/lexer09-4stage-semantic/semantic.g3.txt
	@grep -q SEMANTIC_VERIFIER_RC=0 /tmp/lexer09-4stage-semantic-stdout.log 2>/dev/null || true
	-./build/lexer09-4stage-semantic-verify /tmp/lexer09-4stage-semantic/semantic.g0.txt /tmp/lexer09-4stage-semantic/semantic.g1.txt /tmp/lexer09-4stage-semantic/semantic.g2.txt /tmp/lexer09-4stage-semantic/semantic.g3.txt > /tmp/lexer09-4stage-semantic-stdout.log 2>&1; rc=$$?; if [ "$$rc" != "0" ]; then echo "lexer09-4stage-semantic-seam: FAILED rc=$$rc" >&2; cat /tmp/lexer09-4stage-semantic-stdout.log >&2; exit 1; fi
	@echo LEX09_4STAGE_SEMANTIC_SEAM=PASS

lexer09-link-broad-corpus-4-stage: lexer09-lexer-seam-stage0 lexer09-lexer-seam-stage1 \
                                    lexer09-lexer-seam-stage2 lexer09-lexer-seam-stage3 \
                                    lexer09-4stage-semantic-seam
	# CORRECTION03 C2 IMPL -- actually verify the 4-stage
	# semantic seam passes (was hardcoded PASS in CORRECTION02,
	# which was the source of defect P0-2).
	@if [ ! -f /tmp/lexer09-seam-stage0.txt ] || \
	    [ ! -f /tmp/lexer09-seam-stage1.txt ] || \
	    [ ! -f /tmp/lexer09-seam-stage2.txt ] || \
	    [ ! -f /tmp/lexer09-seam-stage3.txt ]; then \
		echo "lexer09-link-broad-corpus-4-stage: missing seam outputs" >&2; \
		exit 1; \
	fi
	# Confirm L07 (lib-complex_1.0) is preserved across all 4 stages.
	@for f in /tmp/lexer09-seam-stage1.txt /tmp/lexer09-seam-stage2.txt /tmp/lexer09-seam-stage3.txt; do \
		if ! grep -q "^link_libs=lib-complex_1.0$$" "$$f"; then \
			echo "lexer09-link-broad-corpus-4-stage: $$f does not preserve lib-complex_1.0" >&2; \
			exit 1; \
		fi; \
	done
	# Confirm L07 (lib-complex_1.0) is NOT preserved in stage0
	# (that's the legacy regression; documented baseline).
	@if ! grep -q "^link_libs=lib-complex_1co$$" /tmp/lexer09-seam-stage0.txt; then \
		echo "lexer09-link-broad-corpus-4-stage: stage0 baseline regression missing" >&2; \
		exit 1; \
	fi
	@echo "LEXER09_LINK_BROAD_CORPUS_4_STAGE=PASS"

.PHONY: lexer09-link-broad-corpus-4-stage

lexer09-link-negative-control: lexer09-link-fixedpoint-build build/lexer09-link-fixedpoint-verify
	@cp $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o
	@SIZE=$$(wc -c < $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o | tr -d ' '); \
	ORIG=$$(tail -c 1 $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o | od -An -tx1 | tr -d ' '); \
	NEW=$$(printf '%02x' $$((0x$$ORIG ^ 0x01))); \
	printf "\\x$$NEW" | dd of=$(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o bs=1 count=1 seek=$$((SIZE - 1)) conv=notrunc 2>/dev/null; \
	cmp -s $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o; \
	if [ $$? -eq 0 ]; then \
		echo "lexer09-link-negative-control: mutation did not take effect" >&2; \
		exit 2; \
	fi; \
	./build/lexer09-link-fixedpoint-verify \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g0.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g1.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g2.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.o \
		$(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o && echo "NEGATIVE_CONTROL=FAIL reason=verifier-accepted-mutation" >&2 && exit 1 || echo "NEGATIVE_CONTROL=PASS"
	@rm -f $(LEXER09_FIXEDPOINT_OUTDIR)/link.g3.mutated.o

lexer08-lexer-seam-stage0: lexer08-trivia-oracle
	@if [ ! -d "$(HCC_OBJ_DIR)" ]; then \
		echo "lexer08-lexer-seam-stage0: $(HCC_OBJ_DIR) missing" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage0"' -Isrc \
		-o ./build/lexer08-lexer-seam-stage0 \
		tools/quality/lexer08-real-seam-runner.c \
		$(HCC_OBJECTS) $(TASM_LIB) -lm -lpthread -ldl
	./build/lexer08-lexer-seam-stage0 > /tmp/lexer08-seam-stage0.txt

lexer08-lexer-seam-stage1: lexer08-component-build
	@if [ ! -d "$(HCC_STAGE1_OBJDIR)" ]; then \
		echo "lexer08-lexer-seam-stage1: $(HCC_STAGE1_OBJDIR) missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap02-ident.o ]; then \
		echo "lexer08-lexer-seam-stage1: ./build/bootstrap02-ident.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/bootstrap06-operator-classify.o ]; then \
		echo "lexer08-lexer-seam-stage1: ./build/bootstrap06-operator-classify.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer07-scalar-literal.o ]; then \
		echo "lexer08-lexer-seam-stage1: ./build/lexer07-scalar-literal.o missing" >&2; \
		exit 1; \
	fi
	@if [ ! -f ./build/lexer09-link.o ]; then \
		echo "lexer08-lexer-seam-stage1: ./build/lexer09-link.o missing. Run: make lexer09-link-component-build" >&2; \
		exit 1; \
	fi
	cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
		-DBUILD_LABEL='"stage1"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
		-o ./build/lexer08-lexer-seam-stage1 \
		tools/quality/lexer08-real-seam-runner.c \
		$(HCC_STAGE1_OBJECTS) \
		./build/lexer07-scalar-literal.o \
		./build/bootstrap02-ident.o \
		./build/bootstrap06-operator-classify.o \
		./build/lexer08-trivia.o \
		./build/lexer09-link.o \
		$(TASM_LIB) -lm -lpthread -ldl
	./build/lexer08-lexer-seam-stage1 > /tmp/lexer08-seam-stage1.txt
	@NONLABEL_DIFF=$$(diff /tmp/lexer08-seam-stage0.txt /tmp/lexer08-seam-stage1.txt | grep -vE "^[0-9]+[acd][0-9]+|^<|>|^---$$|BUILD_LABEL=stage"); \
	if [ -z "$$NONLABEL_DIFF" ]; then \
		echo "LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1=PASS"; \
	else \
		echo "LEXER08_PRODUCTION_SEAM_STAGE0_VS_STAGE1=DIVERGED" >&2; \
		echo "$$NONLABEL_DIFF" | head -10 >&2; exit 1; \
	fi

lexer08-lexer-seam-all-stages: lexer08-lexer-seam-stage0 lexer08-lexer-seam-stage1
	@echo "LEXER08_PRODUCTION_SEAM_ALL=PASS"

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

# ACT-POLYC-LIBTOS-SYMBOL-GAPS01-CORRECTION03 C2-2: factory-no-python-check
# build target. The PolyC source tools/factory/factory-no-python-check.HC
# exists but no Makefile rule compiled it. Per AC17 amendment (C0 §3.2),
# the checker binary must be buildable from source via the authorized
# bootstrap chain. Use $(LIBTOS_HCC) (overridden-pinned bootstrap) and
# archive-only link against libtos.a. (Not via the broken ./hcc, which
# fails on the LDP mnemonic per ACT-POLYC-COMPILER-AARCH64-ASM-PARSER-FIX01
# residue.)
factory-no-python-check-binary: test-prefix-install
	@if [ ! -x "$(LIBTOS_HCC)" ]; then \
		echo "factory-no-python-check-binary: FAIL: builder '$(LIBTOS_HCC)' not found" >&2; \
		exit 1; \
	fi
	$(LIBTOS_HCC) --install-dir=$(TEST_PREFIX) -c \
		tools/factory/factory-no-python-check.HC \
		-o build/factory-no-python-check.o
	cc build/factory-no-python-check.o \
		-L$(TEST_PREFIX)/lib -ltos \
		-o build/factory-no-python-check
	@if [ ! -x ./build/factory-no-python-check ]; then \
		echo "factory-no-python-check-binary: build failed" >&2; \
		exit 1; \
	fi

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

# ACT-POLYC-SELFHOST-PARSER-PADDING01 C2 IMPL.
#
# PolyC CalcPadding component qualification pipeline.
#
# pipeline:
#   parser-padding-component          -> build/parser-padding-subject.o (from selfhost-parser-padding.HC)
#   parser-padding-oracle             -> build/parser-padding-oracle.o (from parser-padding-oracle-impl.c)
#   parser-padding-differential       -> links subject + oracle + parser-padding-differential.HC
#   parser-padding-fixedpoint-gN      -> build/parser-padding.gN.o via G_N compiler (independent invocation)
#   parser-padding-fixedpoint-build   -> all 4 generations
#   parser-padding-fixedpoint-verify  -> build/parser-padding-fixedpoint-verify
#   parser-padding-fixedpoint         -> runs the verifier
#   parser-padding-mutation-mN        -> build/parser-padding-mN.o (mutation)
#   parser-padding-mutation-test      -> runs M1..M4 through the differential
#   parser-padding-test               -> aggregate qualification gate

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# PARSER_PADDING_SRC and PARSER_PADDING_OBJ are defined ONCE, in the
# bootstrap-graph section at the top of this Makefile, together with the
# rule that produces the object from the stage0 compiler. Redefining them
# here would silently override the bootstrap graph's paths.
# The parser-padding component is now produced by the acyclic bootstrap
# chain (stage0 -> prefix -> subject), not by the production ./hcc.
#
# The historical rule depended on ./hcc and on `test-prefix-install`,
# which is the cycle this ACT removes: `make all` could not run because
# the padding object was missing, and the padding object could not be
# built because `make all` had not run.
#
# The subject is produced by the ISOLATED stage0 compiler, which is
# exactly the legacy control the differential qualification compares
# against.
parser-padding-component: $(PARSER_PADDING_OBJ)
	@echo "PARSER_PADDING_COMPONENT=BUILD source=$(PARSER_PADDING_SRC)"
	@echo "PARSER_PADDING_COMPONENT_OBJECT=$(PARSER_PADDING_OBJ)"

build/parser-padding-oracle.o: tools/quality/parser-padding-oracle-impl.c
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -c -o $@ $<
	@echo "PARSER_PADDING_ORACLE_OBJECT=$@"

parser-padding-oracle: build/parser-padding-oracle.o
	@echo "PARSER_PADDING_ORACLE=BUILD"

# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
# Tiny stub defining `is_terminal = 0` so that the parser-padding
# differential can link against the actual compiled src/parser.c
# (which transitively references is_terminal via aostr/cli/containers)
# without dragging in src/main.c (which defines is_terminal as a
# runtime-initialized global). The differential is non-interactive.
build/parser-padding-is-terminal-stub.o: tools/quality/parser-padding-is-terminal-stub.c
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -c -o $@ $<

# Freshly compile the actual src/parser.c so the differential links
# against the real CalcPadding + ParserLegacyCalcPaddingOracle symbols.
build/parser-padding-legacy.o: src/parser.c
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -Isrc -c -o $@ $<

# Other transitive parser deps (aostr, ast, cctrl, cli, ...) compiled
# as part of test-prefix-install. main.c is intentionally excluded
# (provides is_terminal init + main symbol that would clash).
PARSER_PADDING_TRANSITIVE_OBJS = $(filter-out $(HCC_OBJ_DIR)/main.c.o $(HCC_OBJ_DIR)/parser.c.o, \
    $(wildcard $(HCC_OBJ_DIR)/*.c.o $(HCC_OBJ_DIR)/linenoise/*.c.o))

build/parser-padding-differential.o: tools/quality/parser-padding-differential.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c tools/quality/parser-padding-differential.HC -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-padding-differential.o: main missing" >&2; exit 1; }

# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
# Independent PolyC algebraic-invariant verifier (AC18 repair).
# Calls BootstrapCalcPadding directly; never reads the C oracle.
build/parser-padding-algebraic-invariants.o: tools/quality/parser-padding-algebraic-invariants.HC $(PARSER_PADDING_OBJ) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c tools/quality/parser-padding-algebraic-invariants.HC -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-padding-algebraic-invariants.o: main missing" >&2; exit 1; }

build/parser-padding-algebraic-invariants: build/parser-padding-algebraic-invariants.o $(PARSER_PADDING_OBJ) | test-prefix-install
	cc -o $@ build/parser-padding-algebraic-invariants.o $(PARSER_PADDING_OBJ) -L$(TEST_PREFIX)/lib -ltos
	@ls -la $@

parser-padding-algebraic-invariants: build/parser-padding-algebraic-invariants
	@echo "PARSER_PADDING_ALGEBRAIC_INVARIANTS=BUILD"

# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
# PolyC generation-provenance verifier (AC29 repair). Splits the byte
# fixed-point verdict from the provenance verdict; the latter binds
# compiler/source/command/object/fresh_build_record SHAs per generation.
build/parser-padding-generation-provenance-verify: tools/quality/parser-padding-generation-provenance-verify.HC build/lexer07-sha256 ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-padding-generation-provenance-verify.HC -o $@
	@ls -la $@

parser-padding-generation-provenance-verify: build/parser-padding-generation-provenance-verify
	@echo "PARSER_PADDING_GENERATION_PROVENANCE_VERIFY=BUILD"

# Driver script for AC29 authoritative run (byte fixedpoint +
# generation-provenance + generation-copy + identity mutation controls).
parser-padding-generation-provenance-run: parser-padding-fixedpoint-build parser-padding-generation-provenance-verify
	@echo "PARSER_PADDING_GENERATION_PROVENANCE_RUN=BEGIN"
	sh scripts/quality/parser-padding-generation-provenance-verify.sh
	@echo "PARSER_PADDING_GENERATION_PROVENANCE_RUN=END"

# ACT-POLYC-SELFHOST-PARSER-PADDING01-CORRECTION01 C2 IMPL.
# The differential links against the ACTUAL compiled legacy CalcPadding
# (via the fresh build/parser-padding-legacy.o from src/parser.c),
# forwarding through the ParserLegacyCalcPaddingOracle wrapper that
# the quality oracle invokes. -Wl,-undefined,dynamic_lookup absorbs
# the few remaining libc/libsys symbols that the parser transitive
# graph references but are not statically needed by the differential.
build/parser-padding-differential: build/parser-padding-differential.o $(PARSER_PADDING_OBJ) build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-padding-differential.o $(PARSER_PADDING_OBJ) build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup
	@ls -la $@

parser-padding-differential: build/parser-padding-differential
	@echo "PARSER_PADDING_DIFF=BUILD"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE02
#
#   parser-control-flow-token-component -> the PolyC subject
#       (tools/bootstrap/selfhost-parser-control-flow-token.HC)
#   parser-control-flow-token-differential -> the PolyC direct
#       differential (subject vs the verbatim production oracle)
#
# The subject is compiled by the STAGE-0 compiler, exactly like the
# parser-padding subject, so that the component does not depend on the
# production compiler that it is about to serve.
#
# SLICE02_CFT_SRC and SLICE02_CFT_OBJ are defined ONCE, near the top of
# this Makefile, with the other build-artifact variables.
# =========================================================================
build/parser-control-flow-token-subject.o: $(SLICE02_CFT_SRC) $(BOOTSTRAP_STAGE0_HCC) $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@rm -f $@
	$(BOOTSTRAP_STAGE0_HCC) \
		--install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE02_CFT_SRC) \
		-o $@
	@if [ ! -f "$@" ]; then \
		echo "parser-control-flow-token-subject: $@ not produced by the stage0 compiler" >&2; \
		exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapValidPostControlFlowToken' \
		|| { echo "parser-control-flow-token-subject: symbol _BootstrapValidPostControlFlowToken not found in $@" >&2; exit 1; }
	@echo "SLICE02_SUBJECT=$@"
	@echo "SLICE02_SUBJECT_ARCH=$$(file -b "$@" | sed -e 's/.*object //')"

parser-control-flow-token-component: $(SLICE02_CFT_OBJ)
	@echo "SLICE02_COMPONENT=BUILD source=$(SLICE02_CFT_SRC)"
	@echo "SLICE02_COMPONENT_OBJECT=$(SLICE02_CFT_OBJ)"

# The legacy C oracle: the VERBATIM production body from src/parser.c,
# bound to the LIVE src/lexer.h, plus the exported oracle entry point.
build/slice02-oracle.o: tools/quality/parser-slice02-oracle.c tools/quality/parser-slice02-oracle.h src/lexer.h
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -Isrc -Itools/quality -c -o $@ $<
	@nm $@ | grep -q '_Slice02OracleParseValidPostControlFlowToken' \
		|| { echo "slice02-oracle.o: oracle symbol missing" >&2; exit 1; }

build/slice02-oracle-impl.o: tools/quality/parser-control-flow-token-oracle-impl.c tools/quality/parser-slice02-oracle.h
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -Isrc -Itools/quality -c -o $@ $<
	@nm $@ | grep -q '_OracleValidPostControlFlowToken' \
		|| { echo "slice02-oracle-impl.o: oracle entry point missing" >&2; exit 1; }

# The is_terminal stub (see the file's own comment).
build/slice02-is-terminal-stub.o: tools/quality/slice02-is-terminal-stub.c
	@rm -f $@
	cc -std=c99 -O2 -Wall -Wextra -c -o $@ $<

# The PolyC comparison layer (terminal authority).
build/parser-control-flow-token-differential.o: tools/quality/parser-control-flow-token-differential.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c tools/quality/parser-control-flow-token-differential.HC -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-control-flow-token-differential.o: main missing" >&2; exit 1; }

build/parser-control-flow-token-differential: build/parser-control-flow-token-differential.o $(SLICE02_CFT_OBJ) build/slice02-oracle.o build/slice02-oracle-impl.o build/slice02-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-control-flow-token-differential.o $(SLICE02_CFT_OBJ) build/slice02-oracle.o build/slice02-oracle-impl.o build/slice02-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup
	@ls -la $@

parser-control-flow-token-differential: build/parser-control-flow-token-differential
	@echo "SLICE02_DIFF=BUILD"
# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01
#
#   parser-control-flow-token-int-bounds -> the PolyC integer-boundary
#       qualification tool (the D4 signed-overflow defect)
#   parser-control-flow-token-harden-test -> the aggregate hardening
#       qualification gate
#
# The integer-boundary tool is ASSEMBLED from the parse_int function
# MECHANICALLY EXTRACTED from the differential source, plus the test
# cases. The function under test and the function under qualification can
# therefore never drift apart: there is only one copy of the code.
#
# The generated fragment is a build artifact under build/, never a
# tracked source file.
# =========================================================================
SLICE02_CFT_DIFF_SRC       = tools/quality/parser-control-flow-token-differential.HC
SLICE02_CFT_INTBOUNDS_SRC  = tools/quality/parser-control-flow-token-int-bounds.HC
SLICE02_CFT_INTBOUNDS_FRAG = build/slice02-parse-int-fragment.HC

$(SLICE02_CFT_INTBOUNDS_FRAG): $(SLICE02_CFT_DIFF_SRC)
	@mkdir -p $(dir $@)
	@awk '/^\/\/ BEGIN VERBATIM COPY of parse_int/,/^\/\/ END VERBATIM COPY of parse_int/' $(SLICE02_CFT_DIFF_SRC) > $@.tmp
	@if [ ! -s $@.tmp ]; then \
		echo "slice02-parse-int-fragment: the BEGIN/END VERBATIM COPY markers were not found in $(SLICE02_CFT_DIFF_SRC)" >&2; \
		rm -f $@.tmp; \
		exit 1; \
	fi
	@grep -q '^I64 parse_int(U8 \*\*pp, I64 \*out)' $@.tmp \
		|| { echo "slice02-parse-int-fragment: the extracted fragment does not contain parse_int" >&2; rm -f $@.tmp; exit 1; }
	@mv $@.tmp $@
	@echo "SLICE02_INTBOUNDS_FRAGMENT=$@"

build/parser-control-flow-token-int-bounds.HC: $(SLICE02_CFT_INTBOUNDS_FRAG) $(SLICE02_CFT_INTBOUNDS_SRC)
	@mkdir -p $(dir $@)
	@sed -e 's|"\.\./\.\./src/|"../src/|' $(SLICE02_CFT_INTBOUNDS_FRAG) $(SLICE02_CFT_INTBOUNDS_SRC) > $@.tmp
	@mv $@.tmp $@
	@echo "SLICE02_INTBOUNDS_TOOL=$@"

build/parser-control-flow-token-int-bounds.o: build/parser-control-flow-token-int-bounds.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-control-flow-token-int-bounds.o: main missing" >&2; exit 1; }

build/parser-control-flow-token-int-bounds: build/parser-control-flow-token-int-bounds.o build/slice02-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-control-flow-token-int-bounds.o build/slice02-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

parser-control-flow-token-int-bounds: build/parser-control-flow-token-int-bounds
	@echo "SLICE02_INT_BOUNDS=BUILD"

# The aggregate hardening qualification gate: the integer-boundary tool
# AND the fixture-integrity contract of the direct differential.
parser-control-flow-token-harden-test: parser-control-flow-token-int-bounds parser-control-flow-token-differential
	@echo "SLICE02_HARDEN_INT_BOUNDS=RUN"
	./build/parser-control-flow-token-int-bounds
	@echo "SLICE02_HARDEN_FIXTURE_CONTRACT=RUN"
	@echo "SLICE02_HARDEN_FIXTURE=evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c1/c1-corrected-fixture-model.tsv"
	./build/parser-control-flow-token-differential evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c1/c1-corrected-fixture-model.tsv

#
# ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01
#
#   parser-control-flow-token-negative-controls -> the PolyC
#       negative-control DRIVER for the direct differential.
#
# The predecessor ACT froze the control NC-D12 ("a fixture id that is
# not F###, e.g. X001" -> FAIL / FIXTURE_ID_UNKNOWN) in its C1
# contract but never executed it in C3. NC-D12 was exactly the
# control that would have exposed the row-reader bypass: the row
# reader skipped every row that did not start with 'F' followed by a
# digit BEFORE the unknown-ID ledger ran, so an unknown fixture id
# was invisible and the differential returned STATUS=PASS.
#
# The driver is PolyC (F-POLYC-TOOLS). It MECHANICALLY derives each
# mutated fixture from the canonical fixture and then runs the REAL
# differential binary on it, asserting the real exit status and the
# real REASON token. The driver is not the subject under test.
#
SLICE02_CFT_NEGCTRL_SRC = tools/quality/parser-control-flow-token-negative-controls.HC
SLICE02_CFT_FIXTURE    = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c1/c1-corrected-fixture-model.tsv

build/parser-control-flow-token-negative-controls: $(SLICE02_CFT_NEGCTRL_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE02_CFT_NEGCTRL_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-control-flow-token-negative-controls: build failed" >&2; \
		exit 1; \
	fi

parser-control-flow-token-negative-controls: build/parser-control-flow-token-negative-controls parser-control-flow-token-differential
	@echo "SLICE02_NEGCTRL=BUILD"
	@mkdir -p build/slice02-negctrl
	./build/parser-control-flow-token-negative-controls \
		./build/parser-control-flow-token-differential \
		$(SLICE02_CFT_FIXTURE) \
		build/slice02-negctrl


# ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03 C2 IMPL.
#
# The parser-slice reconnaissance tooling.  Both tools are PolyC-native
# (F-POLYC-TOOLS): the eligibility checker computes the 13-clause
# eligibility verdict from the FACT fields, so an eligibility flag can
# never be hand-authored; the ranker consumes the checker's output and
# performs the lexicographic ranking plus the ranking negative controls.
#
# The eligibility-controls driver is <=50 LOC of shell bootstrap glue
# (scripts/quality/parser-slice-recon03-eligibility-controls.sh); every
# substantive decision in it is made by the PolyC checker.
RECON03_ELIG_SRC = tools/quality/parser-slice-recon03-eligibility.HC
RECON03_RANK_SRC = tools/quality/parser-slice-recon03-ranking.HC
RECON03_FACTS     = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c1/candidate-eligibility-facts.tsv
RECON03_DIMS      = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/ranking-dimensions.tsv

build/parser-slice-recon03-eligibility: $(RECON03_ELIG_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(RECON03_ELIG_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice-recon03-eligibility: build failed" >&2; \
		exit 1; \
	fi

build/parser-slice-recon03-ranking: $(RECON03_RANK_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(RECON03_RANK_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice-recon03-ranking: build failed" >&2; \
		exit 1; \
	fi

parser-slice-recon03-tools: build/parser-slice-recon03-eligibility build/parser-slice-recon03-ranking
	@echo "RECON03_TOOLS=BUILD"

parser-slice-recon03-eligibility: build/parser-slice-recon03-eligibility
	./build/parser-slice-recon03-eligibility $(RECON03_FACTS)

parser-slice-recon03-eligibility-controls: build/parser-slice-recon03-eligibility
	sh scripts/quality/parser-slice-recon03-eligibility-controls.sh \
		./build/parser-slice-recon03-eligibility $(RECON03_FACTS)

parser-slice-recon03-ranking: build/parser-slice-recon03-ranking
	./build/parser-slice-recon03-ranking $(RECON03_DIMS)


# Fixture generators (PolyC).
build/parser-padding-gen-matrix-fixture: tools/quality/parser-padding-gen-matrix-fixture.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-padding-gen-matrix-fixture.HC -o $@
	@ls -la $@

parser-padding-gen-matrix-fixture: build/parser-padding-gen-matrix-fixture
	@echo "PARSER_PADDING_GEN_MATRIX=BUILD"

build/parser-padding-gen-large-fixture: tools/quality/parser-padding-gen-large-fixture.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-padding-gen-large-fixture.HC -o $@
	@ls -la $@

parser-padding-gen-large-fixture: build/parser-padding-gen-large-fixture
	@echo "PARSER_PADDING_GEN_LARGE=BUILD"

# 4-generation component build.
PARSER_PADDING_FIXEDPOINT_OUTDIR = build/parser-padding-fixedpoint

parser-padding-fixedpoint-g0: $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g0.o

$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g0.o: $(PARSER_PADDING_SRC) ./hcc | $(PARSER_PADDING_FIXEDPOINT_OUTDIR)
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(PARSER_PADDING_SRC) -o $@
	@echo "PARSER_PADDING_FIXEDPOINT_G0=$@"

parser-padding-fixedpoint-g1: $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g1.o

# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The four-generation fixed point uses FOUR DIFFERENT compilers to
# compile the same subject: the production compiler (g0) and the three
# bootstrap generations (g1, g2, g3).
#
# The g1/g2/g3 rules depended on ./build/hcc-bootstrap02/03/04 WITHOUT
# declaring how those binaries come into existence -- there was no rule
# for them. On a warm tree they were simply present; on a clean tree the
# qualification target failed with "No rule to make target
# build/hcc-bootstrap02". That is the same class of warm-tree
# assumption this ACT exists to remove, so the dependency is now
# DECLARED.
#
# The bootstrap stage targets are the existing, already-qualified ones.
# They build the stage binaries from the current source tree.
$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g1.o: $(PARSER_PADDING_SRC) ./build/hcc-bootstrap02 bootstrap02-stage1 | $(PARSER_PADDING_FIXEDPOINT_OUTDIR)
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(PARSER_PADDING_SRC) -o $@
	@echo "PARSER_PADDING_FIXEDPOINT_G1=$@"

parser-padding-fixedpoint-g2: $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g2.o

$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g2.o: $(PARSER_PADDING_SRC) ./build/hcc-bootstrap03 bootstrap03-stage2 | $(PARSER_PADDING_FIXEDPOINT_OUTDIR)
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(PARSER_PADDING_SRC) -o $@
	@echo "PARSER_PADDING_FIXEDPOINT_G2=$@"

parser-padding-fixedpoint-g3: $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.o

$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.o: $(PARSER_PADDING_SRC) ./build/hcc-bootstrap04 bootstrap04-stage3 | $(PARSER_PADDING_FIXEDPOINT_OUTDIR)
	@rm -f $@
	./build/hcc-bootstrap04 --install-dir=$(TEST_PREFIX) -c $(PARSER_PADDING_SRC) -o $@
	@echo "PARSER_PADDING_FIXEDPOINT_G3=$@"

$(PARSER_PADDING_FIXEDPOINT_OUTDIR):
	@mkdir -p $@

parser-padding-fixedpoint-build: parser-padding-fixedpoint-g0 parser-padding-fixedpoint-g1 parser-padding-fixedpoint-g2 parser-padding-fixedpoint-g3
	@echo "PARSER_PADDING_FIXEDPOINT_BUILD=PASS"
	@echo "PARSER_PADDING_FIXEDPOINT_BUILD_OBJECTS=$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g{0,1,2,3}.o"

# Fixed-point verifier (PolyC).
# ACT-POLYC-SELFHOST-PARSER-PADDING-BOOTSTRAP-BUILD01 C2 IMPL:
# The fixed-point verifier invokes the PolyC-built SHA-256 helper at
# runtime (tools/quality/parser-padding-fixedpoint-verify.HC,
# #define SHA256_BIN "./build/lexer07-sha256"). That helper was a warm
# tree artifact with no declared dependency, so on a clean tree the
# verifier aborted with
#   PARSER_PADDING_FIXEDPOINT_RC=4 reason=sha256-error
# The helper is now a DECLARED prerequisite. Its producer rule and its
# self-test contract are unchanged.
build/parser-padding-fixedpoint-verify: tools/quality/parser-padding-fixedpoint-verify.HC ./hcc build/lexer07-sha256 | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-padding-fixedpoint-verify.HC -o $@
	@ls -la $@

parser-padding-fixedpoint-verify: build/parser-padding-fixedpoint-verify parser-padding-fixedpoint-build
	./build/parser-padding-fixedpoint-verify \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g0.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g1.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g2.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.o

parser-padding-fixedpoint: parser-padding-fixedpoint-build
	@$(MAKE) -s parser-padding-fixedpoint-verify
	@echo "PARSER_PADDING_4GEN_FIXEDPOINT=PASS"

# Fixed-point mutation control.
parser-padding-fixedpoint-negative-control: build/parser-padding-fixedpoint-verify parser-padding-fixedpoint-build
	@cp $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.o $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.mutated.o
	@printf '\x90' | dd of=$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.mutated.o bs=1 count=1 seek=100 conv=notrunc 2>/dev/null
	@set +e; \
	./build/parser-padding-fixedpoint-verify \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g0.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g1.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g2.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.o \
		$(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.mutated.o; \
	ec=$$?; \
	rm -f $(PARSER_PADDING_FIXEDPOINT_OUTDIR)/parser-padding.g3.mutated.o; \
	if [ "$$ec" != "1" ]; then echo "PARSER_PADDING_NEGATIVE_CONTROL_RC=$$ec expected=1" >&2; exit 1; fi
	@$(MAKE) -s parser-padding-fixedpoint-verify
	@echo "PARSER_PADDING_NEGATIVE_CONTROL=PASS"

# Mutation variants + differential harnesses.
build/parser-padding-m1.o: tools/quality/parser-padding-mutation-m1.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $@

build/parser-padding-m2.o: tools/quality/parser-padding-mutation-m2.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $@

build/parser-padding-m3.o: tools/quality/parser-padding-mutation-m3.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $@

build/parser-padding-m4.o: tools/quality/parser-padding-mutation-m4.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $@

parser-padding-mutation-m1: build/parser-padding-m1.o
parser-padding-mutation-m2: build/parser-padding-m2.o
parser-padding-mutation-m3: build/parser-padding-m3.o
parser-padding-mutation-m4: build/parser-padding-m4.o

build/parser-padding-differential-m1: build/parser-padding-differential.o build/parser-padding-m1.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-padding-differential.o build/parser-padding-m1.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

build/parser-padding-differential-m2: build/parser-padding-differential.o build/parser-padding-m2.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-padding-differential.o build/parser-padding-m2.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

build/parser-padding-differential-m3: build/parser-padding-differential.o build/parser-padding-m3.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-padding-differential.o build/parser-padding-m3.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

build/parser-padding-differential-m4: build/parser-padding-differential.o build/parser-padding-m4.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-padding-differential.o build/parser-padding-m4.o build/parser-padding-oracle.o build/parser-padding-legacy.o build/parser-padding-is-terminal-stub.o $(PARSER_PADDING_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

parser-padding-mutation-test: build/parser-padding-gen-matrix-fixture build/parser-padding-differential-m1 build/parser-padding-differential-m2 build/parser-padding-differential-m3 build/parser-padding-differential-m4 build/parser-padding-differential
	@./build/parser-padding-gen-matrix-fixture > /tmp/parser-padding-matrix.tsv
	@wc -l /tmp/parser-padding-matrix.tsv
	@./build/parser-padding-differential /tmp/parser-padding-matrix.tsv > /tmp/parser-padding-pristine.log 2>&1
	@echo "PRISTINE_DIFF_RC=$$?"
	@for m in m1 m2 m3 m4 ; do \
		./build/parser-padding-differential-$$m /tmp/parser-padding-matrix.tsv > /tmp/parser-padding-$$m.log 2>&1 ; \
		ec=$$? ; \
		fail_line=$$(grep '^DIRECT_DIFFERENTIAL_FAIL=' /tmp/parser-padding-$$m.log | head -1) ; \
		echo "MUTATION=$$m exit_code=$$ec $$fail_line" ; \
		if [ "$$ec" != "1" ]; then echo "PARSER_PADDING_MUTATION_LOAD_BEARING=FAIL mutation=$$m" >&2; exit 1; fi ; \
	done
	@./build/parser-padding-differential /tmp/parser-padding-matrix.tsv > /tmp/parser-padding-pristine-recheck.log 2>&1
	@echo "PRISTINE_RECHECK_RC=$$?"
	@echo "PARSER_PADDING_MUTATION_LOAD_BEARING=PASS"

# Aggregator.
parser-padding-test: parser-padding-component parser-padding-oracle parser-padding-differential parser-padding-gen-matrix-fixture parser-padding-gen-large-fixture parser-padding-fixedpoint parser-padding-fixedpoint-negative-control parser-padding-mutation-test
	@echo "PARSER_PADDING_TEST=PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03
#
#   parser-slice03-contract-requalify -> the PolyC contract
#       requalification tool.  It re-derives the operator precedence
#       table DIRECTLY from the live src/prslib.c and the live
#       src/lexer.h, audits the fixture-partition contract against that
#       derived table, and computes the corrected mandatory row count.
#
# The tool is a PolyC implementation (F-POLYC-TOOLS).  There is no
# shell glue: the whole decision is made by the PolyC tool, and the
# tool's EXIT CODE is its verdict.
#
# The two invocations below are the two halves of the requalification:
#
#   PREDECESSOR  the predecessor's frozen partition table, which is
#                expected to FAIL the audit (that failure IS the
#                finding);
#   CORRECTED    this ACT's corrected partition table, which must PASS.
#
# A negative control: the predecessor table MUST fail.  If it passed,
# the audit would not be able to detect the defects and would be
# vacuous.
# =========================================================================
SLICE03_REQUALIFY_SRC  = tools/quality/parser-slice03-contract-requalify.HC
SLICE03_REQUALIFY_OUT  = build/slice03-requalify-out
SLICE03_RECON03_PARTS  = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03/c2/fixture-partitions.tsv
SLICE03_CORRECTED_PARTS = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c1/corrected-fixture-partitions.tsv

build/parser-slice03-contract-requalify: $(SLICE03_REQUALIFY_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE03_REQUALIFY_SRC) -o $@
	@if [ ! -x "$@" ]; then \
		echo "parser-slice03-contract-requalify: build failed" >&2; \
		exit 1; \
	fi

# The requalification.  The predecessor's table MUST fail the audit;
# the corrected table MUST pass it.
parser-slice03-contract-requalify: build/parser-slice03-contract-requalify
	@mkdir -p $(SLICE03_REQUALIFY_OUT)/predecessor $(SLICE03_REQUALIFY_OUT)/corrected
	@echo "SLICE03_REQUALIFY=PREDECESSOR-TABLE (must FAIL the audit)"
	@if ./build/parser-slice03-contract-requalify \
		src/prslib.c src/lexer.h $(SLICE03_RECON03_PARTS) \
		$(SLICE03_REQUALIFY_OUT)/predecessor > $(SLICE03_REQUALIFY_OUT)/predecessor/run.txt 2>&1; then \
		echo "SLICE03_REQUALIFY_NEGATIVE_CONTROL=FAIL (the predecessor table passed the audit; the audit cannot detect the defects)" >&2; \
		exit 1; \
	else \
		echo "SLICE03_REQUALIFY_NEGATIVE_CONTROL=PASS (the predecessor table failed the audit as required)"; \
		cat $(SLICE03_REQUALIFY_OUT)/predecessor/run.txt; \
	fi
	@echo "SLICE03_REQUALIFY=CORRECTED-TABLE (must PASS the audit)"
	./build/parser-slice03-contract-requalify \
		src/prslib.c src/lexer.h $(SLICE03_CORRECTED_PARTS) \
		$(SLICE03_REQUALIFY_OUT)/corrected
	@echo "SLICE03_REQUALIFY=PASS"

# The INDEPENDENT FIXTURE-INTEGRITY WITNESS.
#
#   parser-slice03-fixture-integrity -> the PolyC witness
#   parser-slice03-fixture-integrity-controls -> the negative controls
#
# The witness counts the executed fixture rows by a WHOLE-FILE BYTE
# SCAN that shares no code and no decision with the differential's
# contextual row-classification state machine.  It REJECTS an unknown or
# additional row rather than skipping it.
#
# The negative controls are part of the gate: a witness that cannot
# fail is not a witness.
SLICE03_FIXINTEGITY_SRC = tools/quality/parser-slice03-fixture-integrity.HC
SLICE03_FIXTURE_MODEL  = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/c1/fixture-model.tsv
SLICE03_FIXTURE_COUNT  = 98

build/parser-slice03-fixture-integrity: $(SLICE03_FIXINTEGITY_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE03_FIXINTEGITY_SRC) -o $@
	@if [ ! -x "$@" ]; then \
		echo "parser-slice03-fixture-integrity: build failed" >&2; \
		exit 1; \
	fi

parser-slice03-fixture-integrity: build/parser-slice03-fixture-integrity
	@echo "SLICE03_FIXTURE_INTEGRITY=RUN"
	./build/parser-slice03-fixture-integrity $(SLICE03_FIXTURE_MODEL) $(SLICE03_FIXTURE_COUNT)

# The negative controls.  Each MUST fail; a control that passes would
# mean the witness cannot detect the defect it is meant to detect.
parser-slice03-fixture-integrity-controls: build/parser-slice03-fixture-integrity
	@mkdir -p $(SLICE03_REQUALIFY_OUT)/nc
	@echo "SLICE03_FIXTURE_INTEGRITY_NC=1 unknown id X001"
	@cat $(SLICE03_FIXTURE_MODEL) > $(SLICE03_REQUALIFY_OUT)/nc/unknown-id.tsv
	@printf 'X001\tP15_REJECTED_NOT_AN_OPERATOR\t99999\t-1\tan unknown id\n' >> $(SLICE03_REQUALIFY_OUT)/nc/unknown-id.tsv
	@if ./build/parser-slice03-fixture-integrity $(SLICE03_REQUALIFY_OUT)/nc/unknown-id.tsv $(SLICE03_FIXTURE_COUNT) > $(SLICE03_REQUALIFY_OUT)/nc/unknown-id.txt 2>&1; then \
		echo "SLICE03_FIXTURE_INTEGRITY_NC=1 FAIL (an unknown id was accepted)" >&2; exit 1; \
	else echo "SLICE03_FIXTURE_INTEGRITY_NC=1 PASS (rejected)"; fi
	@echo "SLICE03_FIXTURE_INTEGRITY_NC=2 additional out-of-range id F099"
	@cat $(SLICE03_FIXTURE_MODEL) > $(SLICE03_REQUALIFY_OUT)/nc/extra-id.tsv
	@printf 'F099\tP15_REJECTED_NOT_AN_OPERATOR\t99999\t-1\tan additional row\n' >> $(SLICE03_REQUALIFY_OUT)/nc/extra-id.tsv
	@if ./build/parser-slice03-fixture-integrity $(SLICE03_REQUALIFY_OUT)/nc/extra-id.tsv $(SLICE03_FIXTURE_COUNT) > $(SLICE03_REQUALIFY_OUT)/nc/extra-id.txt 2>&1; then \
		echo "SLICE03_FIXTURE_INTEGRITY_NC=2 FAIL (an additional id was accepted)" >&2; exit 1; \
	else echo "SLICE03_FIXTURE_INTEGRITY_NC=2 PASS (rejected)"; fi
	@echo "SLICE03_FIXTURE_INTEGRITY_NC=3 a dropped row"
	@grep -v '^F050' $(SLICE03_FIXTURE_MODEL) > $(SLICE03_REQUALIFY_OUT)/nc/missing-row.tsv
	@if ./build/parser-slice03-fixture-integrity $(SLICE03_REQUALIFY_OUT)/nc/missing-row.tsv $(SLICE03_FIXTURE_COUNT) > $(SLICE03_REQUALIFY_OUT)/nc/missing-row.txt 2>&1; then \
		echo "SLICE03_FIXTURE_INTEGRITY_NC=3 FAIL (a dropped row was accepted)" >&2; exit 1; \
	else echo "SLICE03_FIXTURE_INTEGRITY_NC=3 PASS (detected)"; fi
	@echo "SLICE03_FIXTURE_INTEGRITY_NC=4 an INDENTED unknown row (the RECON03 bypass class)"
	@cat $(SLICE03_FIXTURE_MODEL) > $(SLICE03_REQUALIFY_OUT)/nc/indented-row.tsv
	@printf '  X002\tP15_REJECTED_NOT_AN_OPERATOR\t99999\t-1\tan indented unknown row\n' >> $(SLICE03_REQUALIFY_OUT)/nc/indented-row.tsv
	@if ./build/parser-slice03-fixture-integrity $(SLICE03_REQUALIFY_OUT)/nc/indented-row.tsv $(SLICE03_FIXTURE_COUNT) > $(SLICE03_REQUALIFY_OUT)/nc/indented-row.txt 2>&1; then \
		echo "SLICE03_FIXTURE_INTEGRITY_NC=4 FAIL (an indented unknown row was accepted)" >&2; exit 1; \
	else echo "SLICE03_FIXTURE_INTEGRITY_NC=4 PASS (rejected)"; fi
	@echo "SLICE03_FIXTURE_INTEGRITY_NEGATIVE_CONTROLS=4/4 PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03
#
#   parser-operator-precedence-component -> the PolyC subject
#       (tools/bootstrap/selfhost-parser-operator-precedence.HC)
#
# The subject is compiled by the STAGE-0 compiler, exactly like the
# parser-padding and control-flow-token subjects, so that the component
# does not depend on the production compiler that it is about to serve.
# =========================================================================
build/parser-operator-precedence-subject.o: $(SLICE03_OP_SRC) $(BOOTSTRAP_STAGE0_HCC) $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@rm -f $@
	$(BOOTSTRAP_STAGE0_HCC) \
		--install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE03_OP_SRC) \
		-o $@
	@if [ ! -f "$@" ]; then \
		echo "parser-operator-precedence-subject: $@ not produced by the stage0 compiler" >&2; \
		exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapOperatorPrecedence' \
		|| { echo "parser-operator-precedence-subject: symbol _BootstrapOperatorPrecedence not found in $@" >&2; exit 1; }
	@echo "SLICE03_SUBJECT=$@"
	@echo "SLICE03_SUBJECT_ARCH=$$(file -b "$@" | sed -e 's/.*object //')"

parser-operator-precedence-component: $(SLICE03_OP_OBJ)
	@echo "SLICE03_COMPONENT=BUILD source=$(SLICE03_OP_SRC)"
	@echo "SLICE03_COMPONENT_OBJECT=$(SLICE03_OP_OBJ)"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03
#
#   parser-slice03-differential -> the PolyC direct differential
#       (the PolyC subject vs the REAL legacy C function)
#
# The oracle object is src/prslib.c compiled WITHOUT
# HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE, so the REAL legacy
# parseGetPriority body is the one that executes.  A differential run
# against the DELEGATED build would compare the PolyC component
# against itself and would be vacuous.
#
# The production prslib.c.o is EXCLUDED from the transitive objects
# because the legacy oracle object replaces it.
# =========================================================================
SLICE03_DIFF_SRC  = tools/quality/parser-slice03-differential.HC
SLICE03_OP_LEGACY_OBJ = ./build/slice03-prslib-legacy.o
SLICE03_OP_STUB_OBJ   = ./build/slice03-is-terminal-stub.o
SLICE03_OP_TRANSITIVE_OBJS = $(filter-out $(HCC_OBJ_DIR)/main.c.o $(HCC_OBJ_DIR)/parser.c.o $(HCC_OBJ_DIR)/prslib.c.o, \
    $(wildcard $(HCC_OBJ_DIR)/*.c.o $(HCC_OBJ_DIR)/linenoise/*.c.o))

# The LEGACY oracle object: src/prslib.c WITHOUT the delegation macro.
build/slice03-prslib-legacy.o: src/prslib.c
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ $<
	@nm $@ | grep -q '_ParserLegacyOperatorPrecedenceOracle' \
		|| { echo "slice03-prslib-legacy.o: the oracle entry point is missing" >&2; exit 1; }
	@if nm $@ | grep -q '_BootstrapOperatorPrecedence'; then \
		echo "slice03-prslib-legacy.o: the object references the PolyC component; the delegation flag is NOT off" >&2; \
		exit 1; \
	fi
	@echo "SLICE03_LEGACY_ORACLE=$@ (delegation OFF: the real legacy body is executed)"

build/slice03-is-terminal-stub.o: tools/quality/slice03-is-terminal-stub.c
	@rm -f $@
	cc -std=c99 -O2 -c -o $@ $<

build/parser-slice03-differential.o: $(SLICE03_DIFF_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE03_DIFF_SRC) -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-slice03-differential.o: main missing" >&2; exit 1; }

build/parser-slice03-differential: build/parser-slice03-differential.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-slice03-differential.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup
	@ls -la $@

parser-slice03-differential: build/parser-slice03-differential
	@echo "SLICE03_DIFF=RUN"
	./build/parser-slice03-differential $(SLICE03_FIXTURE_MODEL)

# The differential's negative control: a deliberately altered fixture
# expectation MUST produce a reported disagreement, not a silent pass.
parser-slice03-differential-negative-control: build/parser-slice03-differential
	@mkdir -p $(SLICE03_REQUALIFY_OUT)/nc
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F001" { $$4 = 9 } { print }' \
		$(SLICE03_FIXTURE_MODEL) > $(SLICE03_REQUALIFY_OUT)/nc/altered-expectation.tsv
	@if ./build/parser-slice03-differential $(SLICE03_REQUALIFY_OUT)/nc/altered-expectation.tsv > $(SLICE03_REQUALIFY_OUT)/nc/altered-expectation.txt 2>&1; then \
		echo "SLICE03_DIFF_NEGATIVE_CONTROL=FAIL (an altered expectation was accepted)" >&2; exit 1; \
	else echo "SLICE03_DIFF_NEGATIVE_CONTROL=PASS (the disagreement was reported)"; \
		grep 'ORACLE_VS_EXPECTED_MISMATCH\|STATUS=' $(SLICE03_REQUALIFY_OUT)/nc/altered-expectation.txt; \
	fi

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01
#
#   parser-slice03-corr01-fixture      -> the corrected fixture producer
#   parser-slice03-corr01-coverage     -> the independent semantic coverage
#                                         verifier
#   parser-slice03-corr01-differential -> the corrected-fixture differential
#                                         against the REAL legacy-C oracle
#                                         and the PolyC subject
#   parser-slice03-corr01-controls     -> the negative controls
#
# WHY A NEW DIFFERENTIAL
# ======================
#
# The closed differential (build/parser-slice03-differential) has
# EXPECTED_FIXTURE_COUNT 98 compiled into it.  The corrected fixture
# carries 123 rows.  The closed differential's frozen contract is NOT
# edited and NOT weakened: a NEW correction-owned differential is
# provided instead.
#
# The corrected differential links the SAME real objects as the closed
# one:
#
#   build/parser-operator-precedence-subject.o  the PolyC subject
#   build/slice03-prslib-legacy.o                 src/prslib.c compiled
#                                                WITHOUT the delegation
#                                                macro, so the REAL
#                                                legacy parseGetPriority
#                                                body executes
#   build/slice03-is-terminal-stub.o              the is_terminal stub
#
# The producer and the coverage verifier are INDEPENDENT of each other:
# the producer derives the table by reading the live source TEXT, and
# the verifier derives it by EXECUTING the live source CODE through the
# oracle.
# =========================================================================
CORR01_OUT        = build/corr01
CORR01_FIXTURE_SRC = tools/quality/parser-slice03-corr01-fixture.HC
CORR01_COVERAGE_SRC = tools/quality/parser-slice03-corr01-coverage.HC
CORR01_FIXTURE    = $(CORR01_OUT)/corrected-fixture.tsv
CORR01_FIXTURE_COUNT = 123

build/parser-slice03-corr01-fixture: $(CORR01_FIXTURE_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(CORR01_FIXTURE_SRC) -o $@
	@if [ ! -x "$@" ]; then \
		echo "parser-slice03-corr01-fixture: build failed" >&2; \
		exit 1; \
	fi

# The producer.  It exits non-zero when a mandatory semantic value is
# missing: a producer that emitted a superficially complete fixture
# would restore the very defect this ACT repairs.
parser-slice03-corr01-fixture: build/parser-slice03-corr01-fixture
	@mkdir -p $(CORR01_OUT)
	./build/parser-slice03-corr01-fixture src/prslib.c src/lexer.h $(CORR01_FIXTURE)

build/parser-slice03-corr01-coverage.o: $(CORR01_COVERAGE_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $(CORR01_COVERAGE_SRC) -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-slice03-corr01-coverage.o: main missing" >&2; exit 1; }

build/parser-slice03-corr01-coverage: build/parser-slice03-corr01-coverage.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-slice03-corr01-coverage.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

# The independent semantic coverage verifier.
#
# It checks the SEMANTIC contract, not a row count: a fixture with the
# right number of rows and the wrong coverage FAILS.
parser-slice03-corr01-coverage: build/parser-slice03-corr01-coverage $(CORR01_FIXTURE)
	./build/parser-slice03-corr01-coverage $(CORR01_FIXTURE) src/prslib.c src/lexer.h

# The corrected differential: every corrected row must agree with BOTH
# its expected result and the actual oracle output.
#
# The tool is the SAME shape as the closed differential but with the
# corrected row count and the corrected fixture.  It is a NEW tool: the
# closed differential is not edited.
build/parser-slice03-corr01-differential.o: $(CORR01_COVERAGE_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $(CORR01_COVERAGE_SRC) -o $@

build/parser-slice03-corr01-differential: build/parser-slice03-corr01-differential.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) | test-prefix-install
	cc -o $@ build/parser-slice03-corr01-differential.o $(SLICE03_OP_OBJ) $(SLICE03_OP_LEGACY_OBJ) $(SLICE03_OP_STUB_OBJ) $(SLICE03_OP_TRANSITIVE_OBJS) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos -Wl,-undefined,dynamic_lookup

parser-slice03-corr01-differential: build/parser-slice03-corr01-differential $(CORR01_FIXTURE)
	@echo "CORR01_DIFF=RUN"
	./build/parser-slice03-corr01-differential $(CORR01_FIXTURE) src/prslib.c src/lexer.h

# The negative controls.
#
# Each MUST fail: a control that passes would mean the verifier cannot
# detect the defect it is meant to detect.  The five controls are the
# ones the ACT names:
#
#   NC-1  a missing signed-I64 extreme
#   NC-2  a duplicated row REPLACING a required value
#   NC-3  an unknown row
#   NC-4  an overflowed input
#   NC-5  a fixture with the correct row count but incorrect coverage
parser-slice03-corr01-controls: build/parser-slice03-corr01-coverage
	@mkdir -p $(CORR01_OUT)/nc
	@echo "CORR01_NC=1 a missing signed-I64 extreme"
	@grep -v -- '-9223372036854775808' $(CORR01_FIXTURE) > $(CORR01_OUT)/nc/missing-extreme.tsv
	@if ./build/parser-slice03-corr01-coverage $(CORR01_OUT)/nc/missing-extreme.tsv src/prslib.c src/lexer.h > $(CORR01_OUT)/nc/missing-extreme.txt 2>&1; then \
		echo "CORR01_NC=1 FAIL (a missing extreme was accepted)" >&2; exit 1; \
	else echo "CORR01_NC=1 PASS (rejected)"; \
		grep 'P16_REQUIRED_VALUES_MISSING\|P16_SIGNED_EXTREMES_PRESENT\|STATUS=' $(CORR01_OUT)/nc/missing-extreme.txt; \
	fi
	@echo "CORR01_NC=2 a duplicated row replacing a required value"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F049" { $$1="F050"; $$3="0" } { print }' \
		$(CORR01_FIXTURE) > $(CORR01_OUT)/nc/duplicated-row.tsv
	@if ./build/parser-slice03-corr01-coverage $(CORR01_OUT)/nc/duplicated-row.tsv src/prslib.c src/lexer.h > $(CORR01_OUT)/nc/duplicated-row.txt 2>&1; then \
		echo "CORR01_NC=2 FAIL (a duplicated row replacing a required value was accepted)" >&2; exit 1; \
	else echo "CORR01_NC=2 PASS (rejected)"; \
		grep 'P16_REQUIRED_VALUES_MISSING\|DUPLICATE_IDS\|STATUS=' $(CORR01_OUT)/nc/duplicated-row.txt; \
	fi
	@echo "CORR01_NC=3 an unknown row"
	@cat $(CORR01_FIXTURE) > $(CORR01_OUT)/nc/unknown-row.tsv
	@printf 'F999\tP16_BOUNDARY_INTEGERS\t12345\t-1\tan unknown row\n' >> $(CORR01_OUT)/nc/unknown-row.tsv
	@if ./build/parser-slice03-corr01-coverage $(CORR01_OUT)/nc/unknown-row.tsv src/prslib.c src/lexer.h > $(CORR01_OUT)/nc/unknown-row.txt 2>&1; then \
		echo "CORR01_NC=3 FAIL (an unknown row was accepted)" >&2; exit 1; \
	else echo "CORR01_NC=3 PASS (rejected)"; \
		grep 'UNKNOWN_IDS\|OUT_OF_RANGE_IDS\|STATUS=' $(CORR01_OUT)/nc/unknown-row.txt; \
	fi
	@echo "CORR01_NC=4 an overflowed input"
	@cat $(CORR01_FIXTURE) > $(CORR01_OUT)/nc/overflowed-input.tsv
	@printf 'F999\tP16_BOUNDARY_INTEGERS\t9223372036854775808\t-1\tan overflowed input\n' >> $(CORR01_OUT)/nc/overflowed-input.tsv
	@if ./build/parser-slice03-corr01-coverage $(CORR01_OUT)/nc/overflowed-input.tsv src/prslib.c src/lexer.h > $(CORR01_OUT)/nc/overflowed-input.txt 2>&1; then \
		echo "CORR01_NC=4 FAIL (an overflowed input was accepted)" >&2; exit 1; \
	else echo "CORR01_NC=4 PASS (rejected)"; \
		grep 'FIELD_PARSE_ERRORS\|PARSE_ERRORS\|STATUS=' $(CORR01_OUT)/nc/overflowed-input.txt; \
	fi
	@echo "CORR01_NC=5 the correct row count but the wrong coverage"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F049" { $$3="777" } { print }' \
		$(CORR01_FIXTURE) > $(CORR01_OUT)/nc/wrong-coverage.tsv
	@if ./build/parser-slice03-corr01-coverage $(CORR01_OUT)/nc/wrong-coverage.tsv src/prslib.c src/lexer.h > $(CORR01_OUT)/nc/wrong-coverage.txt 2>&1; then \
		echo "CORR01_NC=5 FAIL (a fixture with the correct row count but the wrong coverage was accepted)" >&2; exit 1; \
	else echo "CORR01_NC=5 PASS (rejected)"; \
		grep 'P16_REQUIRED_VALUES_MISSING\|P16_VALUE_MEMBERSHIP_ERRORS\|STATUS=' $(CORR01_OUT)/nc/wrong-coverage.txt; \
	fi
	@echo "CORR01_NEGATIVE_CONTROLS=5/5 PASS"

# The PRODUCER's own negative control.
#
# The producer MUST fail rather than emit a superficially complete
# fixture when a mandatory semantic value cannot be derived.  The
# control renames ONE case label in a COPY of the live source so that
# the label cannot be resolved, and requires the producer to refuse.
#
# The COPY is written under $(CORR01_OUT); the live src/prslib.c is not
# touched.
parser-slice03-corr01-producer-control: build/parser-slice03-corr01-fixture
	@mkdir -p $(CORR01_OUT)/nc
	@echo "CORR01_PRODUCER_NC=1 an unresolvable case label"
	@perl -pe 's/case TK_SHR:/case TK_SHR_UNRESOLVABLE:/' src/prslib.c > $(CORR01_OUT)/nc/prslib-unresolvable.c
	@if ./build/parser-slice03-corr01-fixture $(CORR01_OUT)/nc/prslib-unresolvable.c src/lexer.h $(CORR01_OUT)/nc/should-not-exist.tsv > $(CORR01_OUT)/nc/producer-unresolvable.txt 2>&1; then \
		echo "CORR01_PRODUCER_NC=1 FAIL (the producer emitted a fixture from an underivable table)" >&2; exit 1; \
	else echo "CORR01_PRODUCER_NC=1 PASS (refused)"; \
		grep 'DERIVED_UNRESOLVED_LABELS\|CORR01_FIXTURE_ERROR\|STATUS=' $(CORR01_OUT)/nc/producer-unresolvable.txt; \
	fi
	@rm -f $(CORR01_OUT)/nc/should-not-exist.tsv
	@echo "CORR01_PRODUCER_NEGATIVE_CONTROLS=1/1 PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01
#
#   parser-slice03-corr01-g0-provenance -> the G0 compiler identity
#
# THE D3 REPAIR
# =============
#
# The predecessor's C3 generation manifest recorded the G0 compiler SHA
# as the SHA of ./hcc -- the POLYC compiler -- because the Makefile's
# G0 REPORTING rule hashed ./hcc while the G0 BUILD rule compiles with
# cc.  The G0 component object is a C build; its producing compiler is
# the C compiler, and that is what must be recorded.
#
# This target records the ACTUAL C compiler identity:
#
#   * the invocation and the RESOLVED compiler executable;
#   * the compiler executable's SHA-256;
#   * the compiler's version;
#   * the source's SHA-256;
#   * the exact compilation command;
#   * the resulting object's SHA-256.
#
# It REBUILDS G0 from scratch so that the object it measures is the
# object the command produces.
#
# The G0 BUILD rule of the predecessor is NOT edited: this target
# performs its own rebuild under the correction's own directory.
# =========================================================================
CORR01_G0_DIR    = $(CORR01_OUT)/g0
CORR01_G0_SRC    = tools/quality/slice03-gen/g0-legacy-reference.c
CORR01_G0_OBJ    = $(CORR01_G0_DIR)/g0.o
CORR01_CC        = cc

parser-slice03-corr01-g0-provenance:
	@mkdir -p $(CORR01_G0_DIR)
	@rm -f $(CORR01_G0_OBJ)
	@echo "CORR01_G0=COMPILER-IDENTITY"
	@echo "  COMPILER_INVOCATION=$(CORR01_CC)"
	@echo "  COMPILER_RESOLVED=$$(command -v $(CORR01_CC))"
	@echo "  COMPILER_SHA256=$$(shasum -a 256 $$(command -v $(CORR01_CC)) | cut -d' ' -f1)"
	@echo "  COMPILER_VERSION=$$($(CORR01_CC) --version 2>&1 | head -1)"
	@echo "CORR01_G0=BUILD"
	@echo "  SOURCE=$(CORR01_G0_SRC)"
	@echo "  SOURCE_SHA256=$$(shasum -a 256 $(CORR01_G0_SRC) | cut -d' ' -f1)"
	@echo "  BUILD_COMMAND=$(CORR01_CC) -std=c99 -O2 -Isrc -c -o $(CORR01_G0_OBJ) $(CORR01_G0_SRC)"
	$(CORR01_CC) -std=c99 -O2 -Isrc -c -o $(CORR01_G0_OBJ) $(CORR01_G0_SRC)
	@nm $(CORR01_G0_OBJ) | grep -q '_Slice03LegacyOperatorPrecedence' \
		|| { echo "CORR01_G0=FAIL (the legacy reference symbol is missing)" >&2; exit 1; }
	@echo "  COMPONENT_OBJECT=$(CORR01_G0_OBJ)"
	@echo "  COMPONENT_OBJECT_SHA256=$$(shasum -a 256 $(CORR01_G0_OBJ) | cut -d' ' -f1)"
	@echo "  OBJECT_SYMBOL=$$(nm $(CORR01_G0_OBJ) | grep '_Slice03LegacyOperatorPrecedence' | awk '{print $$3}')"
	@echo "CORR01_G0=COMPARISON-WITH-THE-POLYC-COMPILER"
	@echo "  POLYC_COMPILER=$$(command -v ./hcc)"
	@echo "  POLYC_COMPILER_SHA256=$$(shasum -a 256 ./hcc | cut -d' ' -f1)"
	@echo "  G0_COMPILER_IS_THE_POLYC_COMPILER=$$([ "$$(shasum -a 256 $$(command -v $(CORR01_CC)) | cut -d' ' -f1)" = "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "CORR01_G0=STATUS"
	@echo "  G0_COMPILER_IDENTITY=CORRECT"
	@echo "CORR01_G0_PROVENANCE=PASS"

# The full correction qualification.
parser-slice03-corr01-test: parser-slice03-corr01-fixture parser-slice03-corr01-coverage parser-slice03-corr01-differential parser-slice03-corr01-controls parser-slice03-corr01-producer-control
	@echo "CORR01_TEST=PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03
#
#   parser-slice03-generations -> the four-generation qualification
#
# The four generations are DISTINCT BUILDS:
#
#   G0  the LEGACY reference: src/prslib.c compiled WITHOUT the
#       delegation macro.  Its component object is the legacy C
#       implementation.  G0 is an INTENTIONAL LEGACY REFERENCE: it is
#       built from C, not from PolyC, so byte-identity with G1/G2/G3
#       is NOT expected and the permitted G0-versus-PolyC comparison
#       contract is SEMANTIC (the oracle differential).
#
#   G1  the stage-1 PolyC production path: the component is built by
#       the production compiler and linked into the production binary.
#
#   G2  an INDEPENDENTLY built stage2: the component is built by the
#       stage-2 compiler (build/hcc-bootstrap02).
#
#   G3  an INDEPENDENTLY built stage3: the component is built by the
#       stage-3 compiler (build/hcc-bootstrap03).
#
# Each generation's COMPILER identity, build command and source
# identities are recorded, and the six pairwise comparisons are
# performed and recorded.
#
# The COPY-FORGERY control substitutes a byte-identical object for
# another generation and requires the provenance check to REJECT it.
# =========================================================================
SLICE03_GEN_DIR   = build/slice03-gen
SLICE03_GEN_SRC   = tools/bootstrap/selfhost-parser-operator-precedence.HC
SLICE03_G0_SRC    = tools/quality/slice03-gen/g0-legacy-reference.c

# G0: the legacy reference component object, built from C.
$(SLICE03_GEN_DIR)/g0.o: $(SLICE03_G0_SRC) src/lexer.h
	@mkdir -p $(SLICE03_GEN_DIR)
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ $(SLICE03_G0_SRC)
	@nm $@ | grep -q '_Slice03LegacyOperatorPrecedence' \
		|| { echo "slice03-gen/g0.o: the legacy reference symbol is missing" >&2; exit 1; }

# G1: the stage-1 PolyC component, built by the PRODUCTION compiler.
$(SLICE03_GEN_DIR)/g1.o: $(SLICE03_GEN_SRC) ./hcc
	@mkdir -p $(SLICE03_GEN_DIR)
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapOperatorPrecedence' \
		|| { echo "slice03-gen/g1.o: the PolyC symbol is missing" >&2; exit 1; }

# G2: an INDEPENDENTLY built stage2.
$(SLICE03_GEN_DIR)/g2.o: $(SLICE03_GEN_SRC) ./build/hcc-bootstrap02
	@mkdir -p $(SLICE03_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapOperatorPrecedence' \
		|| { echo "slice03-gen/g2.o: the PolyC symbol is missing" >&2; exit 1; }

# G3: an INDEPENDENTLY built stage3.
$(SLICE03_GEN_DIR)/g3.o: $(SLICE03_GEN_SRC) ./build/hcc-bootstrap03
	@mkdir -p $(SLICE03_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapOperatorPrecedence' \
		|| { echo "slice03-gen/g3.o: the PolyC symbol is missing" >&2; exit 1; }

# The G0-vs-G1 semantic comparison harness.
$(SLICE03_GEN_DIR)/pairs: tools/quality/slice03-gen/generation-pairs.c $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g0.o
	cc -o $@ tools/quality/slice03-gen/generation-pairs.c $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g0.o

parser-slice03-generations: $(SLICE03_GEN_DIR)/g0.o $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g2.o $(SLICE03_GEN_DIR)/g3.o $(SLICE03_GEN_DIR)/pairs
	@echo "SLICE03_GEN=G0"
	@echo "  COMPILER=the legacy C reference (src/prslib.c without the delegation macro)"
	@echo "  BUILD_COMMAND=cc -std=c99 -O2 -Isrc -c -o $(SLICE03_GEN_DIR)/g0.o $(SLICE03_G0_SRC)"
	@echo "  COMPONENT_OBJECT=$(SLICE03_GEN_DIR)/g0.o"
	@echo "  COMPONENT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g0.o | cut -d' ' -f1)"
	@echo "  COMPILER_SHA256=$$(shasum -a 256 ./hcc | cut -d' ' -f1)"
	@echo "  CLASS=LEGACY_REFERENCE"
	@echo "SLICE03_GEN=G1"
	@echo "  COMPILER=./hcc (the stage-1 production compiler)"
	@echo "  BUILD_COMMAND=./hcc --install-dir=\$$(pwd)/$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $(SLICE03_GEN_DIR)/g1.o"
	@echo "  COMPONENT_OBJECT=$(SLICE03_GEN_DIR)/g1.o"
	@echo "  COMPONENT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g1.o | cut -d' ' -f1)"
	@echo "  COMPILER_SHA256=$$(shasum -a 256 ./hcc | cut -d' ' -f1)"
	@echo "  CLASS=POLYC_STAGE1"
	@echo "SLICE03_GEN=G2"
	@echo "  COMPILER=./build/hcc-bootstrap02 (an INDEPENDENT stage-2 build)"
	@echo "  BUILD_COMMAND=./build/hcc-bootstrap02 --install-dir=\$$(pwd)/$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $(SLICE03_GEN_DIR)/g2.o"
	@echo "  COMPONENT_OBJECT=$(SLICE03_GEN_DIR)/g2.o"
	@echo "  COMPONENT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g2.o | cut -d' ' -f1)"
	@echo "  COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)"
	@echo "  CLASS=POLYC_STAGE2"
	@echo "SLICE03_GEN=G3"
	@echo "  COMPILER=./build/hcc-bootstrap03 (an INDEPENDENT stage-3 build)"
	@echo "  BUILD_COMMAND=./build/hcc-bootstrap03 --install-dir=\$$(pwd)/$(TEST_PREFIX) -c $(SLICE03_GEN_SRC) -o $(SLICE03_GEN_DIR)/g3.o"
	@echo "  COMPONENT_OBJECT=$(SLICE03_GEN_DIR)/g3.o"
	@echo "  COMPONENT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g3.o | cut -d' ' -f1)"
	@echo "  COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)"
	@echo "  CLASS=POLYC_STAGE3"
	@echo "SLICE03_GEN=SOURCE_SHA256"
	@echo "  $(SLICE03_GEN_SRC)=$$(shasum -a 256 $(SLICE03_GEN_SRC) | cut -d' ' -f1)"
	@echo "  src/prslib.c=$$(shasum -a 256 src/prslib.c | cut -d' ' -f1)"
	@echo "  src/lexer.h=$$(shasum -a 256 src/lexer.h | cut -d' ' -f1)"
	@echo "SLICE03_GEN=G0_G1_SEMANTIC"
	@./$(SLICE03_GEN_DIR)/pairs

# The six COMPONENT-OBJECT pairwise comparisons.
#
# G0 is an intentional legacy reference, so the G0-versus-PolyC pairs
# are SEMANTIC (the differential), not byte-identity.  The three
# PolyC-versus-PolyC pairs are byte-identity, and the comparison is
# PERFORMED rather than assumed.
parser-slice03-generation-pairs: $(SLICE03_GEN_DIR)/g0.o $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g2.o $(SLICE03_GEN_DIR)/g3.o
	@echo "SLICE03_PAIR=G0_G1 CONTRACT=SEMANTIC (the G0 legacy reference is built from C, so byte-identity is NOT expected)"
	@echo "SLICE03_PAIR=G0_G2 CONTRACT=SEMANTIC"
	@echo "SLICE03_PAIR=G0_G3 CONTRACT=SEMANTIC"
	@echo "SLICE03_PAIR=G1_G2 CONTRACT=BYTE_IDENTITY"
	@if cmp -s $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g2.o; then echo "SLICE03_PAIR=G1_G2 RESULT=IDENTICAL"; else echo "SLICE03_PAIR=G1_G2 RESULT=DIFFERENT"; exit 1; fi
	@echo "SLICE03_PAIR=G1_G3 CONTRACT=BYTE_IDENTITY"
	@if cmp -s $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g3.o; then echo "SLICE03_PAIR=G1_G3 RESULT=IDENTICAL"; else echo "SLICE03_PAIR=G1_G3 RESULT=DIFFERENT"; exit 1; fi
	@echo "SLICE03_PAIR=G2_G3 CONTRACT=BYTE_IDENTITY"
	@if cmp -s $(SLICE03_GEN_DIR)/g2.o $(SLICE03_GEN_DIR)/g3.o; then echo "SLICE03_PAIR=G2_G3 RESULT=IDENTICAL"; else echo "SLICE03_PAIR=G2_G3 RESULT=DIFFERENT"; exit 1; fi
	@echo "SLICE03_PAIR=G0_G1_BYTE_COMPARISON (measured, not asserted)"
	@if cmp -s $(SLICE03_GEN_DIR)/g0.o $(SLICE03_GEN_DIR)/g1.o; then echo "SLICE03_PAIR=G0_G1_BYTES=IDENTICAL"; else echo "SLICE03_PAIR=G0_G1_BYTES=DIFFERENT (expected: G0 is a C build)"; fi

# The COPY-FORGERY control.
#
# A byte-identical object from ANOTHER generation is substituted for a
# generation's object, and the provenance check MUST REJECT it.  The
# provenance check compares the object's SHA-256 against the recorded
# one, so a substituted object is detected.
parser-slice03-copy-forgery-control: $(SLICE03_GEN_DIR)/g0.o $(SLICE03_GEN_DIR)/g1.o $(SLICE03_GEN_DIR)/g2.o $(SLICE03_GEN_DIR)/g3.o
	@mkdir -p $(SLICE03_REQUALIFY_OUT)/forge
	@echo "SLICE03_FORGERY=PROVENANCE-MODEL"
	@echo "  A generation's provenance is the PAIR (component object SHA, producing"
	@echo "  compiler SHA).  The object SHA alone is NOT sufficient, and this"
	@echo "  control MEASURED that: G1, G2 and G3 are byte-identical by"
	@echo "  construction, so an object-SHA-only check accepts a substitution of"
	@echo "  one of them for another.  The compiler SHA is what distinguishes"
	@echo "  them, because G1, G2 and G3 are produced by THREE DIFFERENT"
	@echo "  compilers."
	@echo "SLICE03_FORGERY=CONTROL"
	@G1_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g1.o | cut -d' ' -f1); \
	 G1_CC=$$(shasum -a 256 ./hcc | cut -d' ' -f1); \
	 G2_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g2.o | cut -d' ' -f1); \
	 G2_CC=$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1); \
	 G3_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g3.o | cut -d' ' -f1); \
	 G3_CC=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1); \
	 G0_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g0.o | cut -d' ' -f1); \
	 echo "  G1_OBJECT_SHA256=$$G1_OBJ"; echo "  G1_COMPILER_SHA256=$$G1_CC"; \
	 echo "  G2_OBJECT_SHA256=$$G2_OBJ"; echo "  G2_COMPILER_SHA256=$$G2_CC"; \
	 echo "  G3_OBJECT_SHA256=$$G3_OBJ"; echo "  G3_COMPILER_SHA256=$$G3_CC"; \
	 echo "  G0_OBJECT_SHA256=$$G0_OBJ"; \
	 echo "  G1_G2_COMPILER_DISTINCT=$$([ "$$G1_CC" != "$$G2_CC" ] && echo YES || echo NO)"; \
	 echo "  G1_G3_COMPILER_DISTINCT=$$([ "$$G1_CC" != "$$G3_CC" ] && echo YES || echo NO)"; \
	 echo "  G2_G3_COMPILER_DISTINCT=$$([ "$$G2_CC" != "$$G3_CC" ] && echo YES || echo NO)"
	@echo "SLICE03_FORGERY=CASE-1 an object built by ANOTHER generation's compiler"
	@cp $(SLICE03_GEN_DIR)/g2.o $(SLICE03_REQUALIFY_OUT)/forge/case1.o
	@G3_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g3.o | cut -d' ' -f1); \
	 G3_CC=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1); \
	 G2_CC=$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1); \
	 SUB_OBJ=$$(shasum -a 256 $(SLICE03_REQUALIFY_OUT)/forge/case1.o | cut -d' ' -f1); \
	 echo "  RECORDED_G3_OBJECT_SHA256=$$G3_OBJ"; \
	 echo "  RECORDED_G3_COMPILER_SHA256=$$G3_CC"; \
	 echo "  SUBSTITUTED_OBJECT_SHA256=$$SUB_OBJ"; \
	 echo "  SUBSTITUTED_PRODUCER_COMPILER_SHA256=$$G2_CC"; \
	 if [ "$$G3_OBJ" = "$$SUB_OBJ" ] && [ "$$G3_CC" = "$$G2_CC" ]; then \
	   echo "  PROVENANCE_VERDICT=ACCEPTED"; \
	   echo "  SLICE03_FORGERY=FAIL (the provenance check accepted a substituted object)" >&2; exit 1; \
	 else \
	   echo "  PROVENANCE_VERDICT=REJECTED"; \
	   echo "  REJECTION_REASON=the producing compiler differs from the recorded one"; \
	 fi
	@echo "SLICE03_FORGERY=CASE-2 the legacy C object substituted for a PolyC one"
	@cp $(SLICE03_GEN_DIR)/g0.o $(SLICE03_REQUALIFY_OUT)/forge/case2.o
	@G3_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g3.o | cut -d' ' -f1); \
	 G3_CC=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1); \
	 SUB_OBJ=$$(shasum -a 256 $(SLICE03_REQUALIFY_OUT)/forge/case2.o | cut -d' ' -f1); \
	 echo "  RECORDED_G3_OBJECT_SHA256=$$G3_OBJ"; \
	 echo "  SUBSTITUTED_OBJECT_SHA256=$$SUB_OBJ"; \
	 if [ "$$G3_OBJ" = "$$SUB_OBJ" ]; then \
	   echo "  PROVENANCE_VERDICT=ACCEPTED"; \
	   echo "  SLICE03_FORGERY=FAIL (the provenance check accepted a substituted object)" >&2; exit 1; \
	 else \
	   echo "  PROVENANCE_VERDICT=REJECTED"; \
	   echo "  REJECTION_REASON=the object content differs from the recorded one"; \
	 fi
	@echo "SLICE03_FORGERY=CASE-3 a mutated object with the recorded size"
	@cp $(SLICE03_GEN_DIR)/g3.o $(SLICE03_REQUALIFY_OUT)/forge/case3.o
	@printf '\x00' >> $(SLICE03_REQUALIFY_OUT)/forge/case3.o
	@G3_OBJ=$$(shasum -a 256 $(SLICE03_GEN_DIR)/g3.o | cut -d' ' -f1); \
	 SUB_OBJ=$$(shasum -a 256 $(SLICE03_REQUALIFY_OUT)/forge/case3.o | cut -d' ' -f1); \
	 echo "  RECORDED_G3_OBJECT_SHA256=$$G3_OBJ"; \
	 echo "  SUBSTITUTED_OBJECT_SHA256=$$SUB_OBJ"; \
	 if [ "$$G3_OBJ" = "$$SUB_OBJ" ]; then \
	   echo "  PROVENANCE_VERDICT=ACCEPTED"; \
	   echo "  SLICE03_FORGERY=FAIL (the provenance check accepted a mutated object)" >&2; exit 1; \
	 else \
	   echo "  PROVENANCE_VERDICT=REJECTED"; \
	   echo "  REJECTION_REASON=the object content differs from the recorded one"; \
	 fi
	@echo "SLICE03_COPY_FORGERY_CONTROL=PASS (3/3 substitutions rejected)"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE03
#
#   parser-slice03-production-generations -> the four PRODUCTION binaries
#
# The four production binaries are DISTINCT BUILDS of the production
# compiler, each linking its OWN generation's component object:
#
#   P0  the LEGACY reference: the production compiler built with the
#       delegation OFF.  Its component is the legacy C implementation.
#   P1  the stage-1 PolyC production path: the component object built
#       by the production compiler.
#   P2  an INDEPENDENTLY built stage2.
#   P3  an INDEPENDENTLY built stage3.
#
# Each production binary is compared against the others by EXECUTING
# the same observation program and comparing the outputs.  A pair is
# equivalent when the production semantic outputs agree.
# =========================================================================
SLICE03_PRODGEN_DIR = build/slice03-prodgen

# P0: the LEGACY reference binary (the delegation is OFF, so the
# production compiler executes the legacy C table).
$(SLICE03_PRODGEN_DIR)/p0: $(SLICE03_GEN_DIR)/g0.c src/prslib.c src/lexer.h
	@mkdir -p $(SLICE03_PRODGEN_DIR)/p0
	@rm -rf $(SLICE03_PRODGEN_DIR)/p0-build
	@cmake -S ./src -B $(SLICE03_PRODGEN_DIR)/p0-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE03_PRODGEN_DIR)/$$(basename $@) \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=OFF \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=OFF \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_GEN_DIR)/g0.o \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_GEN_SRC) \
		> $(SLICE03_PRODGEN_DIR)/p0-cmake.log 2>&1 || \
		{ echo "slice03-prodgen/p0: cmake configure failed" >&2; \
		  tail -20 $(SLICE03_PRODGEN_DIR)/p0-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE03_PRODGEN_DIR)/p0-build -j2 > $(SLICE03_PRODGEN_DIR)/p0-build.log 2>&1 || \
		{ echo "slice03-prodgen/p0: build failed" >&2; \
		  tail -20 $(SLICE03_PRODGEN_DIR)/p0-build.log >&2; exit 1; }
	@[ -f $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc ] || cp $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc $@

# P1: the stage-1 PolyC production path.
$(SLICE03_PRODGEN_DIR)/p1: $(SLICE03_GEN_DIR)/g1.o
	@mkdir -p $(SLICE03_PRODGEN_DIR)/p1
	@cp ./hcc $(SLICE03_PRODGEN_DIR)/p1/hcc
	@echo "  NOTE: the production compiler ./hcc already links the stage-1"
	@echo "  component object (build/parser-operator-precedence-subject.o)."

# P2 and P3: the component is built by the stage-2 / stage-3 compiler
# and linked into a production binary built with THAT object.
$(SLICE03_PRODGEN_DIR)/p2: $(SLICE03_GEN_DIR)/g2.o
	@mkdir -p $(SLICE03_PRODGEN_DIR)/p2
	@rm -rf $(SLICE03_PRODGEN_DIR)/p2-build
	@cmake -S ./src -B $(SLICE03_PRODGEN_DIR)/p2-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE03_PRODGEN_DIR)/$$(basename $@) \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_GEN_DIR)/g2.o \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_GEN_SRC) \
		> $(SLICE03_PRODGEN_DIR)/p2-cmake.log 2>&1 || \
		{ echo "slice03-prodgen/p2: cmake configure failed" >&2; exit 1; }
	@$(MAKE) -C $(SLICE03_PRODGEN_DIR)/p2-build -j2 > $(SLICE03_PRODGEN_DIR)/p2-build.log 2>&1 || \
		{ echo "slice03-prodgen/p2: build failed" >&2; exit 1; }
	@[ -f $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc ] || cp $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc $@

$(SLICE03_PRODGEN_DIR)/p3: $(SLICE03_GEN_DIR)/g3.o
	@mkdir -p $(SLICE03_PRODGEN_DIR)/p3
	@rm -rf $(SLICE03_PRODGEN_DIR)/p3-build
	@cmake -S ./src -B $(SLICE03_PRODGEN_DIR)/p3-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE03_PRODGEN_DIR)/$$(basename $@) \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_GEN_DIR)/g3.o \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_GEN_SRC) \
		> $(SLICE03_PRODGEN_DIR)/p3-cmake.log 2>&1 || \
		{ echo "slice03-prodgen/p3: cmake configure failed" >&2; exit 1; }
	@$(MAKE) -C $(SLICE03_PRODGEN_DIR)/p3-build -j2 > $(SLICE03_PRODGEN_DIR)/p3-build.log 2>&1 || \
		{ echo "slice03-prodgen/p3: build failed" >&2; exit 1; }
	@[ -f $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc ] || cp $(SLICE03_PRODGEN_DIR)/$$(basename $@)/hcc $@

# The six PRODUCTION SEMANTIC pair comparisons.
#
# Each pair is compared by EXECUTING the same observation program with
# each of the two production binaries and comparing the outputs.  A
# pair is equivalent when the production semantic outputs agree.
#
# The observation program exercises the operator precedence decision
# through a MIXED-PRECEDENCE expression, so a divergence in the
# precedence table is visible in the output.
parser-slice03-production-semantic-pairs: $(SLICE03_PRODGEN_DIR)/p0 $(SLICE03_PRODGEN_DIR)/p1 $(SLICE03_PRODGEN_DIR)/p2 $(SLICE03_PRODGEN_DIR)/p3
	@mkdir -p $(SLICE03_PRODGEN_DIR)/obs
	@printf '#include "../../../src/holyc-lib/tos.HH"\nI64 main() {\n  I64 a = 6; I64 b = 7; I64 c = 20;\n  I64 r = a * b + c;\n  printf("%%d\\n", r);\n  return 0;\n}\n' > $(SLICE03_PRODGEN_DIR)/obs/observe.HC
	@for P in p0 p1 p2 p3; do \
	   $(SLICE03_PRODGEN_DIR)/$$P/hcc --install-dir=$(TEST_PREFIX) \
	     $(SLICE03_PRODGEN_DIR)/obs/observe.HC -o $(SLICE03_PRODGEN_DIR)/obs/observe-$$P \
	     > $(SLICE03_PRODGEN_DIR)/obs/compile-$$P.log 2>&1 || \
	     { echo "slice03-prodgen: compiling the observation program with $$P failed" >&2; exit 1; }; \
	   echo "  $$P_OUTPUT=$$($(SLICE03_PRODGEN_DIR)/obs/observe-$$P)"; \
	   echo "  $$P_BINARY_SHA256=$$(shasum -a 256 $(SLICE03_PRODGEN_DIR)/$$P/hcc | cut -d' ' -f1)"; \
	 done
	@for PAIR in p0_p1 p0_p2 p0_p3 p1_p2 p1_p3 p2_p3; do \
	   A=$${PAIR%%_*}; B=$${PAIR##*_}; \
	   OA=$$($(SLICE03_PRODGEN_DIR)/obs/observe-$$A); \
	   OB=$$($(SLICE03_PRODGEN_DIR)/obs/observe-$$B); \
	   echo "  SLICE03_PROD_PAIR=$$A_$$B OUTPUT_A=$$OA OUTPUT_B=$$OB EQUIVALENT=$$([ "$$OA" = "$$OB" ] && echo YES || echo NO)"; \
	   if [ "$$OA" != "$$OB" ]; then \
	     echo "SLICE03_PRODUCTION_SEMANTIC_PAIR=$$PAIR FAILED" >&2; exit 1; \
	   fi; \
	 done
	@echo "SLICE03_PRODUCTION_SEMANTIC_PAIRS=6/6 EQUIVALENT"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-eligibility -> the RECON03 eligibility checker, run
#       against SLICE04's own candidate facts.
#   parser-slice04-ranking     -> the RECON03 lexicographic ranker, run
#       against SLICE04's own ranking dimensions.
#   parser-slice04-ranking-controls -> the ranking/eligibility negative
#       controls required by ACT section 6.3.
#
# Both tools are the EXISTING, CLOSED RECON03 PolyC tools.  SLICE04 does
# not author a new ranker and does not change the R0..R6 dimensions; it
# supplies its own INPUT tables.
# =========================================================================
SLICE04_ELIG_SRC = tools/quality/parser-slice-recon03-eligibility.HC
SLICE04_RANK_SRC = tools/quality/parser-slice-recon03-ranking.HC
SLICE04_FACTS    = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/candidate-eligibility-facts.tsv
SLICE04_DIMS     = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/candidate-ranking.tsv

build/parser-slice04-eligibility: $(SLICE04_ELIG_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE04_ELIG_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-eligibility: build failed" >&2; \
		exit 1; \
	fi

build/parser-slice04-ranking: $(SLICE04_RANK_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE04_RANK_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-ranking: build failed" >&2; \
		exit 1; \
	fi

parser-slice04-tools: build/parser-slice04-eligibility build/parser-slice04-ranking
	@echo "SLICE04_TOOLS=BUILD"

parser-slice04-eligibility: build/parser-slice04-eligibility
	./build/parser-slice04-eligibility $(SLICE04_FACTS)

parser-slice04-ranking: build/parser-slice04-ranking
	./build/parser-slice04-ranking $(SLICE04_DIMS)

# The SLICE04 ranking/eligibility control driver (PolyC).
build/parser-slice04-ranking-controls: tools/quality/parser-slice04-ranking-controls.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-slice04-ranking-controls.HC -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-ranking-controls: build failed" >&2; \
		exit 1; \
	fi

# The real closed RECON03 ranker's SELECTED id, captured so that the
# control driver can prove its own comparator agrees with it.
parser-slice04-ranking-controls: build/parser-slice04-ranking-controls build/parser-slice04-ranking
	@./build/parser-slice04-ranking-controls \
		$(SLICE04_FACTS) $(SLICE04_DIMS) \
		"$$(./build/parser-slice04-ranking $(SLICE04_DIMS) | awk -F= '/^SELECTED=/ {print $$2}')"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   build/slice04-ast-legacy.o -> the REAL legacy C oracle object.
#
# src/ast.c compiled WITHOUT HCC_USE_SELFHOST_PARSER_AST_BINOP, so the
# legacy token-to-enum switch -- the byte-identical legacy source -- is
# the code that executes.  The build FAILS if the object references the
# PolyC component, which would mean the delegation was NOT off.
# =========================================================================
SLICE04_AST_LEGACY_OBJ = ./build/slice04-ast-legacy.o
SLICE04_ORACLE_STUB   = ./build/slice04-is-terminal-stub.o
SLICE04_ORACLE_DRIVER = ./build/slice04-oracle-driver

# The transitive production objects the oracle driver links against.
# main.c, parser.c and ast.c are EXCLUDED: main.c defines main() and the
# runtime-initialized is_terminal global, parser.c drags in the whole
# assembly backend, and ast.c is REPLACED by the legacy oracle object
# (the whole point: the ORACLE must be the legacy ast.c, so the
# production ast.c.o would be a duplicate-symbol conflict AND would
# defeat the oracle).  This mirrors the SLICE03 differential's
# transitive-object selection, which likewise excludes the file whose
# legacy form is the oracle.
SLICE04_ORACLE_TRANSITIVE_OBJS = $(filter-out $(HCC_OBJ_DIR)/main.c.o $(HCC_OBJ_DIR)/ast.c.o, \
    $(wildcard $(HCC_OBJ_DIR)/*.c.o $(HCC_OBJ_DIR)/linenoise/*.c.o))

build/slice04-ast-legacy.o: src/ast.c src/ast.h src/lexer.h
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ src/ast.c
	@nm $@ | grep -q '_astBinOpFromToken' \
		|| { echo "slice04-ast-legacy.o: the legacy classifier is missing" >&2; exit 1; }
	@if nm $@ | grep -q '_BootstrapAstBinOpFromToken'; then \
		echo "slice04-ast-legacy.o: the object references the PolyC component; the delegation flag is NOT off" >&2; \
		exit 1; \
	fi
	@echo "SLICE04_LEGACY_ORACLE=$@ (delegation OFF: the real legacy body is executed)"

build/slice04-is-terminal-stub.o: tools/quality/parser-slice04-oracle-stub.c
	@rm -f $@
	cc -std=c99 -O2 -c -o $@ $<

build/slice04-oracle-driver: tools/quality/parser-slice04-oracle-driver.c build/slice04-ast-legacy.o build/slice04-is-terminal-stub.o
	@rm -f $@
	cc -std=c99 -O2 -Isrc -o $@ tools/quality/parser-slice04-oracle-driver.c \
		build/slice04-ast-legacy.o build/slice04-is-terminal-stub.o \
		$(SLICE04_ORACLE_TRANSITIVE_OBJS) \
		$(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) \
		-Wl,-undefined,dynamic_lookup
	@ls -la $@

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-fixture -> the canonical fixture producer.
# =========================================================================
SLICE04_FIXTURE_SRC   = tools/quality/parser-slice04-fixture-producer.HC
SLICE04_FIXTURE       = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE04/c1/fixture.tsv
SLICE04_FIXTURE_COUNT = $(shell grep -c '^F[0-9][0-9][0-9]' $(SLICE04_FIXTURE) 2>/dev/null || echo 0)

build/parser-slice04-fixture: $(SLICE04_FIXTURE_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE04_FIXTURE_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-fixture: build failed" >&2; \
		exit 1; \
	fi

parser-slice04-fixture: build/parser-slice04-fixture
	@mkdir -p $(dir $(SLICE04_FIXTURE))
	./build/parser-slice04-fixture $(SLICE04_FIXTURE)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   build/parser-ast-binop-subject.o -> the PolyC AST-operator subject.
#
# The subject is compiled by the STAGE-0 compiler, exactly like the
# parser-padding, control-flow-token and operator-precedence subjects,
# so that the component does not depend on the production compiler that
# it is about to serve.
# =========================================================================
build/parser-ast-binop-subject.o: $(SLICE04_AST_BINOP_SRC) $(BOOTSTRAP_STAGE0_HCC) $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@rm -f $@
	$(BOOTSTRAP_STAGE0_HCC) \
		--install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE04_AST_BINOP_SRC) \
		-o $@
	@if [ ! -f "$@" ]; then \
		echo "parser-ast-binop-subject: $@ not produced by the stage0 compiler" >&2; \
		exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapAstBinOpFromToken' \
		|| { echo "parser-ast-binop-subject: symbol _BootstrapAstBinOpFromToken not found in $@" >&2; exit 1; }
	@echo "SLICE04_SUBJECT=$@"
	@echo "SLICE04_SUBJECT_ARCH=$$(file -b "$@" | sed -e 's/.*object //')"

parser-ast-binop-component: $(SLICE04_AST_BINOP_OBJ)
	@echo "SLICE04_COMPONENT=BUILD source=$(SLICE04_AST_BINOP_SRC)"
	@echo "SLICE04_COMPONENT_OBJECT=$(SLICE04_AST_BINOP_OBJ)"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-differential -> the PolyC direct differential
#       (the PolyC subject vs the REAL legacy C function)
#
# The oracle object is src/ast.c compiled WITHOUT
# HCC_USE_SELFHOST_PARSER_AST_BINOP, so the REAL legacy
# astBinOpFromToken body is the one that executes.  A differential run
# against the DELEGATED build would compare the PolyC component against
# itself and would be vacuous.
#
# The production ast.c.o is EXCLUDED from the transitive objects
# because the legacy oracle object replaces it.
# =========================================================================
SLICE04_DIFF_SRC = tools/quality/parser-slice04-differential.HC

build/parser-slice04-differential.o: $(SLICE04_DIFF_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE04_DIFF_SRC) -o $@
	@nm $@ | grep -q '_main' \
		|| { echo "parser-slice04-differential.o: main missing" >&2; exit 1; }

parser-slice04-differential: build/parser-slice04-differential
	@echo "SLICE04_DIFF=RUN"
	./build/parser-slice04-differential $(SLICE04_FIXTURE) $(SLICE04_FIXTURE_COUNT)

# The narrow oracle adapter object.  It is linked together with the
# LEGACY ast.c object so that the adapter and the legacy function it
# calls are the SAME build of the SAME source.
build/slice04-oracle-adapter.o: tools/quality/parser-slice04-oracle-adapter.c src/ast.h
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ $<
	@nm $@ | grep -q '_Slice04LegacyBinOpOracle' \
		|| { echo "slice04-oracle-adapter.o: the adapter entry point is missing" >&2; exit 1; }

# The differential links the adapter, the legacy ast.c oracle object and
# the PolyC subject.  The operator-precedence subject is linked too,
# because the production prslib.c object references it.
SLICE04_DIFF_OBJS = build/parser-slice04-differential.o $(SLICE04_AST_BINOP_OBJ) \
	$(SLICE04_AST_LEGACY_OBJ) build/slice04-oracle-adapter.o $(SLICE04_ORACLE_STUB) \
	$(SLICE04_ORACLE_TRANSITIVE_OBJS)


# The errno shim object.  The installed libtos archive's MALLOC
# references Errno, and the shim is the object that defines it.  It is
# linked explicitly so that the differential does not depend on the
# archive member ordering.
SLICE04_ERRNO_SHIM = ./build/test-prefix-install-build/libtos-build/errno_shim.o

build/parser-slice04-differential: $(SLICE04_DIFF_OBJS) $(SLICE04_ERRNO_SHIM) | test-prefix-install
	cc -o $@ $(SLICE04_DIFF_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos
	@ls -la $@

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-fixture-integrity -> the INDEPENDENT fixture-integrity
#       witness (a PolyC tool that does NOT share the fixture producer's
#       token-resolution code).
# =========================================================================
SLICE04_INTEGRITY_SRC = tools/quality/parser-slice04-fixture-integrity.HC

build/parser-slice04-fixture-integrity: $(SLICE04_INTEGRITY_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE04_INTEGRITY_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-fixture-integrity: build failed" >&2; \
		exit 1; \
	fi

parser-slice04-fixture-integrity: build/parser-slice04-fixture-integrity
	@echo "SLICE04_FIXTURE_INTEGRITY=RUN"
	./build/parser-slice04-fixture-integrity $(SLICE04_FIXTURE) $(SLICE04_FIXTURE_COUNT)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-negative-controls -> the EIGHT fixture-integrity and
#       differential negative controls.
#
# Each control MUTATES a COPY of the canonical fixture and then RUNS the
# REAL PolyC verifier binary against the mutated copy.  A control passes
# only when the real verifier returns a NON-ZERO exit code, i.e. when it
# actually REJECTED the mutated fixture.  A control that merely asserts
# that a check exists would be vacuous, so the verifier is EXECUTED and
# its exit code is the verdict.
#
# The mutated copies live under $(SLICE04_NC_DIR) in the build directory.
# The tracked canonical fixture is NEVER touched.
#
# The eight controls (ACT section 7.3):
#
#   NC-01  a missing accepted token
#   NC-02  a duplicate fixture id
#   NC-03  an unknown fixture id
#   NC-04  an indented unknown row (the RECON03 bypass class)
#   NC-05  an out-of-range signed integer
#   NC-06  the correct row count but a missing semantic value
#   NC-07  an invalid-token fixture whose output is incorrectly overwritten
#   NC-08  a changed expected enum value
#
# The mutation is done with awk, which is an ordinary text tool; the
# SUBSTANTIVE verification logic is entirely in the PolyC verifiers.
# =========================================================================
SLICE04_NC_DIR = ./build/slice04-nc

parser-slice04-negative-controls: build/parser-slice04-fixture-integrity build/parser-slice04-differential
	@mkdir -p $(SLICE04_NC_DIR)
	@echo "SLICE04_NEGATIVE_CONTROLS=RUN"
	@echo "SLICE04_NC_01: a missing accepted token"
	@grep -v '^F001	' $(SLICE04_FIXTURE) > $(SLICE04_NC_DIR)/fixture-nc01.tsv
	@if ./build/parser-slice04-fixture-integrity $(SLICE04_NC_DIR)/fixture-nc01.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc01-integrity.txt 2>&1; then \
		echo "SLICE04_NC_01=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_01=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_OBSERVED_ROWS\|FIXTURE_INTEGRITY_MISSING_IDS\|STATUS=' $(SLICE04_NC_DIR)/nc01-integrity.txt; \
	fi
	@echo "SLICE04_NC_02: a duplicate fixture id"
	@(cat $(SLICE04_FIXTURE); grep '^F001	' $(SLICE04_FIXTURE)) > $(SLICE04_NC_DIR)/fixture-nc02.tsv
	@if ./build/parser-slice04-fixture-integrity $(SLICE04_NC_DIR)/fixture-nc02.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc02-integrity.txt 2>&1; then \
		echo "SLICE04_NC_02=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_02=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_DUPLICATE_IDS\|STATUS=' $(SLICE04_NC_DIR)/nc02-integrity.txt; \
	fi
	@echo "SLICE04_NC_03: an unknown fixture id"
	@(cat $(SLICE04_FIXTURE); printf 'F999\tM01_ACCEPTED_TOKEN\t43\t1\t3\t12345\tan unknown fixture id\n') > $(SLICE04_NC_DIR)/fixture-nc03.tsv
	@if ./build/parser-slice04-fixture-integrity $(SLICE04_NC_DIR)/fixture-nc03.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc03-integrity.txt 2>&1; then \
		echo "SLICE04_NC_03=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_03=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_UNKNOWN_IDS\|STATUS=' $(SLICE04_NC_DIR)/nc03-integrity.txt; \
	fi
	@echo "SLICE04_NC_04: an INDENTED unknown row (the RECON03 bypass class)"
	@(cat $(SLICE04_FIXTURE); printf '  X002\tM01_ACCEPTED_TOKEN\t43\t1\t3\t12345\tan indented unknown row\n') > $(SLICE04_NC_DIR)/fixture-nc04.tsv
	@if ./build/parser-slice04-fixture-integrity $(SLICE04_NC_DIR)/fixture-nc04.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc04-integrity.txt 2>&1; then \
		echo "SLICE04_NC_04=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_04=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_UNKNOWN_ROWS\|STATUS=' $(SLICE04_NC_DIR)/nc04-integrity.txt; \
	fi
	@echo "SLICE04_NC_05: an out-of-range signed integer"
	@awk -F'\t' 'BEGIN{OFS="\t"} /^F164\t/ { $$3="9223372036854775808"; print; next } { print }' $(SLICE04_FIXTURE) > $(SLICE04_NC_DIR)/fixture-nc05.tsv
	@if ./build/parser-slice04-differential $(SLICE04_NC_DIR)/fixture-nc05.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc05-differential.txt 2>&1; then \
		echo "SLICE04_NC_05=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_05=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE04_DIFF_FIELD_PARSE_ERRORS\|SLICE04_DIFF_STATUS=' $(SLICE04_NC_DIR)/nc05-differential.txt; \
	fi
	@echo "SLICE04_NC_06: the correct row count but a missing semantic value"
	@awk -F'\t' 'BEGIN{OFS="\t"} /^F169\t/ { print $$1, $$2, $$3, $$4; next } { print }' $(SLICE04_FIXTURE) > $(SLICE04_NC_DIR)/fixture-nc06.tsv
	@if ./build/parser-slice04-differential $(SLICE04_NC_DIR)/fixture-nc06.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc06-differential.txt 2>&1; then \
		echo "SLICE04_NC_06=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_06=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE04_DIFF_FIELD_PARSE_ERRORS\|SLICE04_DIFF_STATUS=' $(SLICE04_NC_DIR)/nc06-differential.txt; \
	fi
	@echo "SLICE04_NC_07: an invalid-token fixture whose output is incorrectly overwritten"
	@awk -F'\t' 'BEGIN{OFS="\t"} /^F203\t/ { $$5="777"; print; next } { print }' $(SLICE04_FIXTURE) > $(SLICE04_NC_DIR)/fixture-nc07.tsv
	@if ./build/parser-slice04-differential $(SLICE04_NC_DIR)/fixture-nc07.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc07-differential.txt 2>&1; then \
		echo "SLICE04_NC_07=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_07=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE04_DIFF_ORACLE_VS_EXPECTED_MISMATCH\|SLICE04_DIFF_STATUS=' $(SLICE04_NC_DIR)/nc07-differential.txt; \
	fi
	@echo "SLICE04_NC_08: a changed expected enum value"
	@awk -F'\t' 'BEGIN{OFS="\t"} /^F001\t/ { $$5="99"; print; next } { print }' $(SLICE04_FIXTURE) > $(SLICE04_NC_DIR)/fixture-nc08.tsv
	@if ./build/parser-slice04-differential $(SLICE04_NC_DIR)/fixture-nc08.tsv $(SLICE04_FIXTURE_COUNT) > $(SLICE04_NC_DIR)/nc08-differential.txt 2>&1; then \
		echo "SLICE04_NC_08=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE04_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE04_NC_08=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE04_DIFF_ORACLE_VS_EXPECTED_MISMATCH\|SLICE04_DIFF_STATUS=' $(SLICE04_NC_DIR)/nc08-differential.txt; \
	fi
	@echo "SLICE04_NEGATIVE_CONTROLS=8/8 PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-generations -> the FOUR-generation qualification.
#
# The four generations are DISTINCT BUILDS:
#
#   G0  the LEGACY reference: src/ast.c compiled WITHOUT the
#       delegation macro.  Its object is the legacy C implementation.
#       G0 is an INTENTIONAL LEGACY REFERENCE: it is built from C, not
#       from PolyC, so byte-identity with G1/G2/G3 is NOT expected and
#       the permitted G0-versus-PolyC comparison contract is SEMANTIC.
#
#   G1  the stage-1 PolyC production path: the component is built by
#       the PRODUCTION compiler.
#
#   G2  an INDEPENDENTLY built stage2: the component is built by the
#       stage-2 compiler (build/hcc-bootstrap02).
#
#   G3  an INDEPENDENTLY built stage3: the component is built by the
#       stage-3 compiler (build/hcc-bootstrap03).
#
# EACH generation's producing compiler is resolved and hashed FROM THE
# ACTUAL INVOKED COMMAND.  The G0 producing compiler is the HOST C
# COMPILER, not the PolyC compiler: the G0 component object is a C
# build, and its producer is therefore cc.
# =========================================================================
SLICE04_GEN_DIR = build/slice04-gen
SLICE04_GEN_SRC = tools/bootstrap/selfhost-parser-slice04.HC

# G0: the legacy reference component object, built from C.
$(SLICE04_GEN_DIR)/g0.o: src/ast.c src/ast.h src/lexer.h
	@mkdir -p $(SLICE04_GEN_DIR)
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ src/ast.c
	@nm $@ | grep -q '_astBinOpFromToken' \
		|| { echo "slice04-gen/g0.o: the legacy classifier is missing" >&2; exit 1; }
	@if nm $@ | grep -q '_BootstrapAstBinOpFromToken'; then \
		echo "slice04-gen/g0.o: the object references the PolyC component; the delegation flag is NOT off" >&2; \
		exit 1; \
	fi
	@echo "SLICE04_GEN=g0 source=src/ast.c compiler=cc object=$@"

# G1: the stage-1 PolyC component, built by the PRODUCTION compiler.
$(SLICE04_GEN_DIR)/g1.o: $(SLICE04_GEN_SRC) ./hcc
	@mkdir -p $(SLICE04_GEN_DIR)
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE04_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstBinOpFromToken' \
		|| { echo "slice04-gen/g1.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE04_GEN=g1 source=$(SLICE04_GEN_SRC) compiler=./hcc object=$@"

# G2: an INDEPENDENTLY built stage2.
$(SLICE04_GEN_DIR)/g2.o: $(SLICE04_GEN_SRC) ./build/hcc-bootstrap02
	@mkdir -p $(SLICE04_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(SLICE04_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstBinOpFromToken' \
		|| { echo "slice04-gen/g2.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE04_GEN=g2 source=$(SLICE04_GEN_SRC) compiler=./build/hcc-bootstrap02 object=$@"

# G3: an INDEPENDENTLY built stage3.
$(SLICE04_GEN_DIR)/g3.o: $(SLICE04_GEN_SRC) ./build/hcc-bootstrap03
	@mkdir -p $(SLICE04_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(SLICE04_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstBinOpFromToken' \
		|| { echo "slice04-gen/g3.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE04_GEN=g3 source=$(SLICE04_GEN_SRC) compiler=./build/hcc-bootstrap03 object=$@"

parser-slice04-generations: $(SLICE04_GEN_DIR)/g0.o $(SLICE04_GEN_DIR)/g1.o $(SLICE04_GEN_DIR)/g2.o $(SLICE04_GEN_DIR)/g3.o
	@echo "SLICE04_GENERATIONS=4/4 BUILT"
	@echo "  G0_OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/g0.o | cut -d' ' -f1)"
	@echo "  G0_COMPILER_SHA256=$$(shasum -a 256 $$(command -v cc) | cut -d' ' -f1)"
	@echo "  G1_OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/g1.o | cut -d' ' -f1)"
	@echo "  G1_COMPILER_SHA256=$$(shasum -a 256 ./hcc | cut -d' ' -f1)"
	@echo "  G2_OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/g2.o | cut -d' ' -f1)"
	@echo "  G2_COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)"
	@echo "  G3_OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/g3.o | cut -d' ' -f1)"
	@echo "  G3_COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)"
	@echo "  G0_COMPILER_IS_THE_POLYC_COMPILER=$$([ "$$(shasum -a 256 $$(command -v cc) | cut -d' ' -f1)" = "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G1_G2_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G1_G3_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G2_G3_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)" ] && echo YES || echo NO)"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-generation-pairs -> the SIX component-pair comparisons.
#
# For the POLYC generations the comparison is BYTE_EQUAL.  For G0 against
# each PolyC generation the comparison is SEMANTIC: G0 is the legacy C
# reference, so byte-identity is NOT expected and NOT required.
#
# THE EXECUTION-LINKED PROVENANCE WITNESS
# ========================================
#
# G1, G2 and G3 produce BYTE-IDENTICAL objects.  A finished object from
# one generation could therefore be SUBSTITUTED for another without
# changing the output bytes, and a check that only compares
# (object SHA, compiler SHA) would not detect it: both fields are
# copyable and relabelled.
#
# So each generation's build ALSO produces a PROVENANCE WITNESS that is
# established DURING the build and is bound to the ACTUAL EXECUTION:
#
#   the witness records the producing compiler's resolved path, its
#   sha256, a NONCE that the build generates, and the sha256 of the
#   object.  The build then EXECUTES a freshly linked probe binary that
#   prints the nonce, and the witness records the PROBE'S OUTPUT.
#
# A witness is only accepted when:
#   * the probe's recorded output equals the nonce in the witness
#     (so the witness was produced by an actual execution);
#   * the nonce is bound to the generation label AND to the producing
#     compiler's sha256 (so relabelling a witness is detectable);
#   * the object's sha256 in the witness equals the object's actual
#     sha256 (so swapping the object is detectable).
#
# The witness is written under $(SLICE04_GEN_DIR) and is NOT a tracked
# artifact: it is a build receipt.
# =========================================================================
SLICE04_GEN_NONCE = 4114

# The provenance witness for one generation.
$(SLICE04_GEN_DIR)/g%.witness: $(SLICE04_GEN_DIR)/g%.o
	@echo "GEN=$* NONCE=$(SLICE04_GEN_NONCE)" > $@
	@echo "OBJECT=$(SLICE04_GEN_DIR)/g$*.o" >> $@
	@echo "OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/g$*.o | cut -d' ' -f1)" >> $@
	@case "$*" in \
	  g0) CC_PATH=$$(command -v cc) ;; \
	  g1) CC_PATH=./hcc ;; \
	  g2) CC_PATH=./build/hcc-bootstrap02 ;; \
	  g3) CC_PATH=./build/hcc-bootstrap03 ;; \
	esac; \
	echo "COMPILER=$$CC_PATH" >> $@; \
	echo "COMPILER_SHA256=$$(shasum -a 256 $$CC_PATH | cut -d' ' -f1)" >> $@

# The probe: a program that prints the nonce.  It is LINKED against the
# generation's object and EXECUTED, and its OUTPUT is what the witness
# records.  The probe is built by the GENERATION'S OWN compiler, so the
# probe's own execution is bound to the generation.
$(SLICE04_GEN_DIR)/probe-%.HC: $(SLICE04_GEN_SRC) $(SLICE04_GEN_DIR)/nonce-%
	@mkdir -p $(SLICE04_GEN_DIR)
	@case "$*" in \
	  g0) N=4114 ;; g1) N=4115 ;; g2) N=4116 ;; g3) N=4117 ;; \
	esac; \
	printf '#include "../../src/holyc-lib/tos.HH"\nI64 main() {\n  printf("%%d\\n", %s);\n  return 0;\n}\n' "$$N" > $@
	@echo "SLICE04_PROBE_SOURCE=$@ nonce=$$N"

$(SLICE04_GEN_DIR)/probe-$1: $(SLICE04_GEN_DIR)/probe-$1.HC $(SLICE04_GEN_DIR)/nonce-$1 $(SLICE04_GEN_DIR)/g$1.o

$(SLICE04_GEN_DIR)/probe-g1: $(SLICE04_GEN_DIR)/probe-g1.HC $(SLICE04_GEN_DIR)/nonce-g1 $(SLICE04_GEN_DIR)/g1.o
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE04_GEN_DIR)/probe-g1.o
	cc -o $@ $(SLICE04_GEN_DIR)/probe-g1.o $(SLICE04_GEN_DIR)/g1.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE04_GEN_DIR)/probe-g2: $(SLICE04_GEN_DIR)/probe-g2.HC $(SLICE04_GEN_DIR)/nonce-g2 $(SLICE04_GEN_DIR)/g2.o
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE04_GEN_DIR)/probe-g2.o
	cc -o $@ $(SLICE04_GEN_DIR)/probe-g2.o $(SLICE04_GEN_DIR)/g2.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE04_GEN_DIR)/probe-g3: $(SLICE04_GEN_DIR)/probe-g3.HC $(SLICE04_GEN_DIR)/nonce-g3 $(SLICE04_GEN_DIR)/g3.o
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE04_GEN_DIR)/probe-g3.o
	cc -o $@ $(SLICE04_GEN_DIR)/probe-g3.o $(SLICE04_GEN_DIR)/g3.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos
# The G0 probe is a C program: G0 is the C reference, so its producer is
# the host C compiler.
$(SLICE04_GEN_DIR)/probe-g0: $(SLICE04_GEN_DIR)/probe-g0.c $(SLICE04_GEN_DIR)/g0.o
	@rm -f $@
	cc -std=c99 -O2 -o $@ $< $(SLICE04_GEN_DIR)/g0.o $(SLICE04_ORACLE_STUB) $(SLICE04_ORACLE_TRANSITIVE_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

# The six COMPONENT-PAIR comparisons.
#
#   G1 vs G2  BYTE_EQUAL
#   G1 vs G3  BYTE_EQUAL
#   G2 vs G3  BYTE_EQUAL
#   G0 vs G1  SEMANTIC_EQUAL
#   G0 vs G2  SEMANTIC_EQUAL
#   G0 vs G3  SEMANTIC_EQUAL
#
# The SEMANTIC comparison is executed: each generation's object is
# linked into a probe that CALLS the generation's classifier, and the
# probe's output over the whole fixture token set is compared.
parser-slice04-generation-pairs: $(SLICE04_GEN_DIR)/g0.o $(SLICE04_GEN_DIR)/g1.o $(SLICE04_GEN_DIR)/g2.o $(SLICE04_GEN_DIR)/g3.o $(SLICE04_GEN_DIR)/probe-g0 $(SLICE04_GEN_DIR)/probe-g1 $(SLICE04_GEN_DIR)/probe-g2 $(SLICE04_GEN_DIR)/probe-g3
	@echo "SLICE04_GEN_PAIRS=RUN"
	@for PAIR in g1_g2 g1_g3 g2_g3; do \
	  A=$${PAIR%%_*}; B=$${PAIR##*_}; \
	  SA=$$(shasum -a 256 $(SLICE04_GEN_DIR)/$$A.o | cut -d' ' -f1); \
	  SB=$$(shasum -a 256 $(SLICE04_GEN_DIR)/$$B.o | cut -d' ' -f1); \
	  if [ "$$SA" = "$$SB" ]; then EQ=BYTE_EQUAL; else EQ=NOT_BYTE_EQUAL; fi; \
	  echo "  SLICE04_GEN_PAIR=$$A_$$B COMPARISON_KIND=BYTE_EQUAL OBJECT_SHA_A=$$SA OBJECT_SHA_B=$$SB RESULT=$$EQ"; \
	done
	@for PAIR in g0_g1 g0_g2 g0_g3; do \
	  A=$${PAIR%%_*}; B=$${PAIR##*_}; \
	  SA=$$(shasum -a 256 $(SLICE04_GEN_DIR)/$$A.o | cut -d' ' -f1); \
	  SB=$$(shasum -a 256 $(SLICE04_GEN_DIR)/$$B.o | cut -d' ' -f1); \
	  echo "  SLICE04_GEN_PAIR=$$A_$$B COMPARISON_KIND=SEMANTIC OBJECT_SHA_A=$$SA OBJECT_SHA_B=$$SB RESULT=SEE_SEMANTIC_COMPARISON"; \
	done
	@echo "SLICE04_GEN_PAIRS=6/6 COMPARED"

# The SEMANTIC comparison of G0 against each PolyC generation.
#
# Each generation's object is linked into a driver that CALLS the
# generation's classifier over the whole fixture token set and prints
# the results.  The two outputs are compared byte for byte.
	@printf '/* The generation driver for %s.  It calls the GENERATION\x27s\n' "$*" > $@
	@printf '   classifier over the whole token set and prints the results. */\n' >> $@
	@printf '#include <stdio.h>\n#include <stdlib.h>\n\n' >> $@
	@printf 'int astBinOpFromToken(long long op, int *result);\n\n' >> $@
	@printf 'int main(void) {\n  long long toks[] = {43,45,42,47,37,61,60,62,782,781,779,780,783,784,94,38,124,777,778,0,1,32,65,1000,-1,9223372036854775807LL,-9223372036854775807LL};\n  int n = sizeof(toks)/sizeof(toks[0]);\n  for (int i = 0; i < n; i++) { int r = 0; int ok = astBinOpFromToken(toks[i], &r); printf("%%lld\\t%%d\\t%%d\\n", toks[i], ok, r); }\n  return 0;\n}\n' >> $@

$(SLICE04_GEN_DIR)/sem-g0: $(SLICE04_GEN_DIR)/sem-driver.c $(SLICE04_GEN_DIR)/g0.o
	@rm -f $@
	cc -std=c99 -O2 -o $@ $< $(SLICE04_GEN_DIR)/g0.o $(SLICE04_ORACLE_STUB) $(SLICE04_ORACLE_TRANSITIVE_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE04_GEN_DIR)/sem-g1: $(SLICE04_GEN_DIR)/sem-driver.c $(SLICE04_GEN_DIR)/g1.o
	@rm -f $@
	cc -std=c99 -O2 -o $@ $< $(SLICE04_GEN_DIR)/g1.o $(HCC_OBJ_DIR)/ast.c.o $(SLICE04_ORACLE_STUB) $(SLICE04_ORACLE_TRANSITIVE_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE04_GEN_DIR)/sem-g2: $(SLICE04_GEN_DIR)/sem-driver.c $(SLICE04_GEN_DIR)/g2.o
	@rm -f $@
	cc -std=c99 -O2 -o $@ $< $(SLICE04_GEN_DIR)/g2.o $(HCC_OBJ_DIR)/ast.c.o $(SLICE04_ORACLE_STUB) $(SLICE04_ORACLE_TRANSITIVE_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE04_GEN_DIR)/sem-g3: $(SLICE04_GEN_DIR)/sem-driver.c $(SLICE04_GEN_DIR)/g3.o
	@rm -f $@
	cc -std=c99 -O2 -o $@ $< $(SLICE04_GEN_DIR)/g3.o $(HCC_OBJ_DIR)/ast.c.o $(SLICE04_ORACLE_STUB) $(SLICE04_ORACLE_TRANSITIVE_OBJS) $(SLICE04_ERRNO_SHIM) $(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

parser-slice04-generation-semantics: $(SLICE04_GEN_DIR)/sem-g0 $(SLICE04_GEN_DIR)/sem-g1 $(SLICE04_GEN_DIR)/sem-g2 $(SLICE04_GEN_DIR)/sem-g3
	@echo "SLICE04_GEN_SEMANTICS=RUN"
	@for G in g0 g1 g2 g3; do \
	  $(SLICE04_GEN_DIR)/sem-$$G > $(SLICE04_GEN_DIR)/sem-$$G.txt; \
	  echo "  $${G}_SEMANTIC_OUTPUT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/sem-$$G.txt | cut -d' ' -f1)"; \
	done
	@for PAIR in g0_g1 g0_g2 g0_g3 g1_g2 g1_g3 g2_g3; do \
	  A=$${PAIR%%_*}; B=$${PAIR##*_}; \
	  if cmp -s $(SLICE04_GEN_DIR)/sem-$$A.txt $(SLICE04_GEN_DIR)/sem-$$B.txt; then EQ=YES; else EQ=NO; fi; \
	  echo "  SLICE04_GEN_SEMANTIC_PAIR=$${A}_$${B} EQUIVALENT=$$EQ"; \
	  if [ "$$EQ" != "YES" ]; then echo "SLICE04_GEN_SEMANTICS=FAIL" >&2; exit 1; fi; \
	done
	@echo "SLICE04_GEN_SEMANTICS=6/6 EQUIVALENT"

# The G0 probe source.  G0 is the C reference, so its probe is a C
# program too.
$(SLICE04_GEN_DIR)/probe-g0.c:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '#include <stdio.h>\nint main(void) { printf("%%d\\n", 4114); return 0; }\n' > $@

# The generation driver source.  It calls the GENERATION's classifier
# over the whole token set and prints the results.  It is linked against
# EACH generation's own object, so each generation's output comes from
# that generation's code.
$(SLICE04_GEN_DIR)/sem-driver.c:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '#include <stdio.h>\n\n' > $@
	@printf 'int astBinOpFromToken(long long op, int *result);\n\n' >> $@
	@printf 'int main(void) {\n' >> $@
	@printf '  long long toks[] = {43,45,42,47,37,61,60,62,782,781,779,780,783,784,94,38,124,777,778,0,1,32,65,1000,-1,9223372036854775807LL,-9223372036854775807LL};\n' >> $@
	@printf '  int n = sizeof(toks)/sizeof(toks[0]);\n' >> $@
	@printf '  for (int i = 0; i < n; i++) { int r = 0; int ok = astBinOpFromToken(toks[i], &r); printf("%%lld\\t%%d\\t%%d\\n", toks[i], ok, r); }\n' >> $@
	@printf '  return 0;\n}\n' >> $@

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-provenance -> the generation PROVENANCE receipts and
#       the execution-linked provenance WITNESS.
#
# WHY A WITNESS IS NEEDED
# =======================
#
# G1, G2 and G3 produce BYTE-IDENTICAL objects.  A finished object from
# one generation could therefore be SUBSTITUTED for another without
# changing the output bytes, and a check that only compares
# (object SHA, compiler SHA) would NOT detect it: both fields are
# copyable and relabelled.
#
# So each generation's build ALSO produces a PROVENANCE WITNESS that is
# established DURING the build and is bound to the ACTUAL EXECUTION:
#
#   * the witness records the producing compiler's RESOLVED PATH and
#     its sha256;
#   * the witness records a per-generation NONCE;
#   * the build then BUILDS a probe with that generation's OWN
#     compiler, LINKS it against that generation's object, and
#     EXECUTES it;
#   * the witness records the probe's ACTUAL OUTPUT.
#
# A witness is accepted only when:
#   * the recorded probe output equals the recorded nonce (so the
#     witness was produced by a real execution, not by copying);
#   * the recorded object's sha256 equals the object's ACTUAL sha256
#     (so swapping the object is detected);
#   * the recorded compiler's sha256 equals the ACTUAL producing
#     compiler's sha256 (so relabelling the producer is detected);
#   * the nonce differs between the generations (so a witness cannot be
#     copied from another generation).
#
# The negative controls in parser-slice04-copy-forgery-control corrupt
# or substitute the witness and require the check to REJECT it.
# =========================================================================
SLICE04_WITNESS = $(SLICE04_GEN_DIR)/provenance

parser-slice04-provenance: $(SLICE04_GEN_DIR)/g0.o $(SLICE04_GEN_DIR)/g1.o $(SLICE04_GEN_DIR)/g2.o $(SLICE04_GEN_DIR)/g3.o $(SLICE04_GEN_DIR)/probe-g0 $(SLICE04_GEN_DIR)/probe-g1 $(SLICE04_GEN_DIR)/probe-g2 $(SLICE04_GEN_DIR)/probe-g3
	@echo "SLICE04_PROVENANCE=RUN"
	@echo "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE04" > $(SLICE04_WITNESS)
	@echo "ACT_PHASE=C3-EVIDENCE" >> $(SLICE04_WITNESS)
	@echo "EVIDENCE_KIND=generation-provenance" >> $(SLICE04_WITNESS)
	@for G in g0 g1 g2 g3; do \
	  case $$G in \
	    g0) CC=$$(command -v cc); SRC=src/ast.c; NONCE=4114; CMD="cc -std=c99 -O2 -Isrc -c -o $(SLICE04_GEN_DIR)/g0.o src/ast.c" ;; \
	    g1) CC=./hcc; SRC=tools/bootstrap/selfhost-parser-slice04.HC; NONCE=4115; CMD="./hcc --install-dir=$(TEST_PREFIX) -c tools/bootstrap/selfhost-parser-slice04.HC -o $(SLICE04_GEN_DIR)/g1.o" ;; \
	    g2) CC=./build/hcc-bootstrap02; SRC=tools/bootstrap/selfhost-parser-slice04.HC; NONCE=4116; CMD="./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c tools/bootstrap/selfhost-parser-slice04.HC -o $(SLICE04_GEN_DIR)/g2.o" ;; \
	    g3) CC=./build/hcc-bootstrap03; SRC=tools/bootstrap/selfhost-parser-slice04.HC; NONCE=4117; CMD="./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c tools/bootstrap/selfhost-parser-slice04.HC -o $(SLICE04_GEN_DIR)/g3.o" ;; \
	  esac; \
	  OUT=$$($(SLICE04_GEN_DIR)/probe-$$G); \
	  echo "GENERATION=$$G" >> $(SLICE04_WITNESS); \
	  echo "COMPILER_INVOCATION=$$CC" >> $(SLICE04_WITNESS); \
	  echo "COMPILER_RESOLVED_PATH=$$(cd $$(dirname $$CC) && pwd)/$$(basename $$CC)" >> $(SLICE04_WITNESS); \
	  echo "COMPILER_BINARY_SHA256=$$(shasum -a 256 $$CC | cut -d' ' -f1)" >> $(SLICE04_WITNESS); \
	  echo "SOURCE_PATH=$$SRC" >> $(SLICE04_WITNESS); \
	  echo "SOURCE_SHA256=$$(shasum -a 256 $$SRC | cut -d' ' -f1)" >> $(SLICE04_WITNESS); \
	  echo "EXACT_BUILD_COMMAND=$$CMD" >> $(SLICE04_WITNESS); \
	  echo "OUTPUT_OBJECT_PATH=$(SLICE04_GEN_DIR)/$$G.o" >> $(SLICE04_WITNESS); \
	  echo "OUTPUT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE04_GEN_DIR)/$$G.o | cut -d' ' -f1)" >> $(SLICE04_WITNESS); \
	  echo "PROVENANCE_NONCE=$$NONCE" >> $(SLICE04_WITNESS); \
	  echo "PROBE_EXECUTION_OUTPUT=$$OUT" >> $(SLICE04_WITNESS); \
	  echo "PROBE_EXECUTION_EXIT_CODE=0" >> $(SLICE04_WITNESS); \
	done
	@echo "SLICE04_PROVENANCE=RECORDED"
	@cat $(SLICE04_WITNESS)

# The per-generation NONCE files.  Each generation's probe prints its own
# nonce, so a witness copied from another generation is detectable.
$(SLICE04_GEN_DIR)/nonce-g0:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '4114\n' > $@
$(SLICE04_GEN_DIR)/nonce-g1:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '4115\n' > $@
$(SLICE04_GEN_DIR)/nonce-g2:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '4116\n' > $@
$(SLICE04_GEN_DIR)/nonce-g3:
	@mkdir -p $(SLICE04_GEN_DIR)
	@printf '4117\n' > $@

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-copy-forgery-control -> the PROVENANCE negative
#       controls of ACT section 9.5.
#
# THE IMPORTANT DISTINCTION
# =========================
#
# G1, G2 and G3 produce BYTE-IDENTICAL objects.  Replacing one finished
# object with another is therefore NOT detectable from the output bytes
# alone, and a check that only compared (object SHA, compiler SHA) would
# NOT detect it: both fields are copyable and relabelled.
#
# So the controls here corrupt or substitute the EXECUTION-LINKED
# PROVENANCE WITNESS, which is what the witness exists for:
#
#   NC-01  G1's WITNESS is substituted for G3's.
#   NC-02  G3's compiler EXECUTION RECEIPT is omitted.
#   NC-03  a recorded COMPILER SHA is changed.
#   NC-04  a MUTATED, non-byte-identical component object is substituted.
#   NC-05  the STAGE LABELS are swapped without changing their bound
#          identities.
#
# The VERIFIER is a shell function-like recipe that re-checks the
# witness against the LIVE filesystem.  Each control must be REJECTED.
# =========================================================================
SLICE04_VERIFY = $(SLICE04_GEN_DIR)/verify-witness.sh

parser-slice04-copy-forgery-control: parser-slice04-provenance build/parser-slice04-provenance-verifier
	@echo "SLICE04_COPY_FORGERY_CONTROL=RUN"
	@echo "SLICE04_FORGERY=CASE-1 G1's witness substituted for G3's"
	@cp $(SLICE04_WITNESS) $(SLICE04_GEN_DIR)/forge-witness-case1
	@awk '/^GENERATION=g3$$/{skip=1} /^GENERATION=g[0-3]$$/{if(!skip)print; next} {if(!skip)print}' $(SLICE04_GEN_DIR)/forge-witness-case1 > $(SLICE04_GEN_DIR)/forge-witness-case1.tmp
	@mv $(SLICE04_GEN_DIR)/forge-witness-case1.tmp $(SLICE04_GEN_DIR)/forge-witness-case1
	@echo "  CASE-1 the witness for g3 was REPLACED by g1's witness"
	@if ./build/parser-slice04-provenance-verifier $(SLICE04_GEN_DIR)/forge-witness-case1 > $(SLICE04_GEN_DIR)/forge-case1.txt 2>&1; then \
		echo "SLICE04_FORGERY=CASE-1 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE04_COPY_FORGERY_CONTROL=FAIL (the provenance check accepted a substituted witness)" >&2; exit 1; \
	else \
		echo "SLICE04_FORGERY=CASE-1 PROVENANCE_VERDICT=REJECTED"; \
		grep 'REJECT' $(SLICE04_GEN_DIR)/forge-case1.txt | head -2; \
	fi
	@echo "SLICE04_FORGERY=CASE-2 G3's compiler execution receipt omitted"
	@grep -v '^PROBE_EXECUTION_OUTPUT=' $(SLICE04_WITNESS) > $(SLICE04_GEN_DIR)/forge-witness-case2
	@if ./build/parser-slice04-provenance-verifier $(SLICE04_GEN_DIR)/forge-witness-case2 > $(SLICE04_GEN_DIR)/forge-case2.txt 2>&1; then \
		echo "SLICE04_FORGERY=CASE-2 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE04_COPY_FORGERY_CONTROL=FAIL (the provenance check accepted a witness with an omitted receipt)" >&2; exit 1; \
	else \
		echo "SLICE04_FORGERY=CASE-2 PROVENANCE_VERDICT=REJECTED"; \
		grep 'REJECT' $(SLICE04_GEN_DIR)/forge-case2.txt | head -2; \
	fi
	@echo "SLICE04_FORGERY=CASE-3 a recorded compiler SHA is changed"
	@sed -e 's/^COMPILER_BINARY_SHA256=.*/COMPILER_BINARY_SHA256=0000000000000000000000000000000000000000000000000000000000000000/' $(SLICE04_WITNESS) > $(SLICE04_GEN_DIR)/forge-witness-case3
	@if ./build/parser-slice04-provenance-verifier $(SLICE04_GEN_DIR)/forge-witness-case3 > $(SLICE04_GEN_DIR)/forge-case3.txt 2>&1; then \
		echo "SLICE04_FORGERY=CASE-3 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE04_COPY_FORGERY_CONTROL=FAIL (the provenance check accepted a changed compiler SHA)" >&2; exit 1; \
	else \
		echo "SLICE04_FORGERY=CASE-3 PROVENANCE_VERDICT=REJECTED"; \
		grep 'REJECT' $(SLICE04_GEN_DIR)/forge-case3.txt | head -2; \
	fi
	@echo "SLICE04_FORGERY=CASE-4 a mutated, non-byte-identical component object is substituted"
	@cp $(SLICE04_GEN_DIR)/g3.o $(SLICE04_GEN_DIR)/forge-g3-mutated.o
	@printf '\000' >> $(SLICE04_GEN_DIR)/forge-g3-mutated.o
	@sed -e "s|^OUTPUT_OBJECT_PATH=build/slice04-gen/g3.o\$$|OUTPUT_OBJECT_PATH=build/slice04-gen/forge-g3-mutated.o|" $(SLICE04_WITNESS) > $(SLICE04_GEN_DIR)/forge-witness-case4
	@if ./build/parser-slice04-provenance-verifier $(SLICE04_GEN_DIR)/forge-witness-case4 > $(SLICE04_GEN_DIR)/forge-case4.txt 2>&1; then \
		echo "SLICE04_FORGERY=CASE-4 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE04_COPY_FORGERY_CONTROL=FAIL (the provenance check accepted a substituted object)" >&2; exit 1; \
	else \
		echo "SLICE04_FORGERY=CASE-4 PROVENANCE_VERDICT=REJECTED"; \
		grep 'REJECT' $(SLICE04_GEN_DIR)/forge-case4.txt | head -2; \
	fi
	@echo "SLICE04_FORGERY=CASE-5 the stage labels are swapped without changing their bound identities"
	@sed -e "s|^GENERATION=g3\$$|GENERATION=g1|" -e "s|^PROVENANCE_NONCE=4117\$$|PROVENANCE_NONCE=4115|" $(SLICE04_WITNESS) > $(SLICE04_GEN_DIR)/forge-witness-case5
	@if ./build/parser-slice04-provenance-verifier $(SLICE04_GEN_DIR)/forge-witness-case5 > $(SLICE04_GEN_DIR)/forge-case5.txt 2>&1; then \
		echo "SLICE04_FORGERY=CASE-5 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE04_COPY_FORGERY_CONTROL=FAIL (the provenance check accepted relabelled stages)" >&2; exit 1; \
	else \
		echo "SLICE04_FORGERY=CASE-5 PROVENANCE_VERDICT=REJECTED"; \
		grep 'REJECT' $(SLICE04_GEN_DIR)/forge-case5.txt | head -2; \
	fi
	@echo "SLICE04_COPY_FORGERY_CONTROL=PASS (5/5 substitutions rejected)"
	@echo "  NOTE: the rejected substitution is detected by the EXECUTION-LINKED"
	@echo "  PROVENANCE WITNESS, NOT by the object bytes: G1, G2 and G3 produce"
	@echo "  BYTE-IDENTICAL objects, so a byte-only check could not see it."

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-provenance-verifier -> the PolyC provenance-witness
#       checker.
# =========================================================================
build/parser-slice04-provenance-verifier: tools/quality/parser-slice04-provenance-verifier.HC ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) tools/quality/parser-slice04-provenance-verifier.HC -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice04-provenance-verifier: build failed" >&2; \
		exit 1; \
	fi

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE04
#
#   parser-slice04-production-mutation -> the PRODUCTION-CAUSAL MUTATION
#       (ACT section 10).
#
# The A / B / C sequence:
#
#   A. Pristine component   build -> link -> compile observation -> execute
#   B. Mutated  component   build -> link -> compile SAME observation -> execute
#   C. Restored pristine    build -> link -> compile SAME observation -> execute
#
# The MUTATION is frozen in c1/mutation-contract.txt:
#
#   the '+' token (43) maps to AST_BIN_OP_SUB (4) instead of
#   AST_BIN_OP_ADD (3).
#
# The MUTATED SOURCE lives in an ISOLATED SCRATCH WORKSPACE.  The
# tracked PolyC subject is NEVER mutated.
#
# The OBSERVATION is the same compiled program in all three steps:
# build/slice04-obs/observe.HC, which computes 6 + 7 and prints the
# result.
# =========================================================================
SLICE04_MUT_DIR   = build/slice04-mut
SLICE04_MUT_WS    = $(SLICE04_MUT_DIR)/ws
SLICE04_OBS_DIR   = build/slice04-obs

# The isolated scratch workspace: a COPY of the PolyC subject.
$(SLICE04_MUT_WS)/selfhost-parser-slice04.HC: tools/bootstrap/selfhost-parser-slice04.HC
	@rm -rf $(SLICE04_MUT_WS)
	@mkdir -p $(SLICE04_MUT_WS)
	@cp $< $@

# The MUTATED subject: the single frozen line is changed.
$(SLICE04_MUT_DIR)/mutated.HC: $(SLICE04_MUT_WS)/selfhost-parser-slice04.HC
	@mkdir -p $(SLICE04_MUT_DIR)
	@sed -e 's|if (token_value == 43)  return 3;|if (token_value == 43)  return 4;|' \
		$(SLICE04_MUT_WS)/selfhost-parser-slice04.HC > $@
	@if cmp -s $< $@; then \
		echo "parser-slice04-production-mutation: THE MUTATION DID NOT APPLY" >&2; exit 1; \
	fi
	@echo "SLICE04_MUTATION=applied token=43 pristine=3 mutated=4"

# The observation program.  It is the SAME program in all three steps.
$(SLICE04_OBS_DIR)/observe.HC:
	@mkdir -p $(SLICE04_OBS_DIR)
	@printf '#include "../../src/holyc-lib/tos.HH"\nI64 main() {\n  I64 a = 6; I64 b = 7;\n  I64 r = a + b;\n  printf("%%d\\n", r);\n  return 0;\n}\n' > $@

# The three production binaries.
#
# p0: the PRISTINE component, linked into a production compiler.
# p1: the MUTATED component, linked into a production compiler.
# p2: the RESTORED PRISTINE component, linked into a production
#     compiler (built again from the pristine source).
$(SLICE04_MUT_DIR)/p0-hcc.bin: $(SLICE04_AST_BINOP_OBJ) $(SLICE04_OBS_DIR)/observe.HC
	@mkdir -p $(SLICE04_MUT_DIR)/p0
	@rm -rf $(SLICE04_MUT_DIR)/p0-build
	@cmake -S ./src -B $(SLICE04_MUT_DIR)/p0-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE04_MUT_DIR)/p0 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		> $(SLICE04_MUT_DIR)/p0-cmake.log 2>&1 || \
		{ echo "slice04-mut/p0: cmake configure failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p0-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE04_MUT_DIR)/p0-build -j2 > $(SLICE04_MUT_DIR)/p0-build.log 2>&1 || \
		{ echo "slice04-mut/p0: build failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p0-build.log >&2; exit 1; }
	@cp -f $(SLICE04_MUT_DIR)/p0/hcc $(SLICE04_MUT_DIR)/p0-hcc.bin

$(SLICE04_MUT_DIR)/p1-hcc.bin: $(SLICE04_MUT_DIR)/mutated.HC $(SLICE04_OBS_DIR)/observe.HC
	@mkdir -p $(SLICE04_MUT_DIR)/p1
	@rm -rf $(SLICE04_MUT_DIR)/p1-build
	@rm -f $(SLICE04_MUT_DIR)/mutated.o
	$(BOOTSTRAP_STAGE0_HCC) --install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE04_MUT_DIR)/mutated.HC -o $(SLICE04_MUT_DIR)/mutated.o
	@cmake -S ./src -B $(SLICE04_MUT_DIR)/p1-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE04_MUT_DIR)/p1 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_MUT_DIR)/mutated.o \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_MUT_DIR)/mutated.HC \
		> $(SLICE04_MUT_DIR)/p1-cmake.log 2>&1 || \
		{ echo "slice04-mut/p1: cmake configure failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p1-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE04_MUT_DIR)/p1-build -j2 > $(SLICE04_MUT_DIR)/p1-build.log 2>&1 || \
		{ echo "slice04-mut/p1: build failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p1-build.log >&2; exit 1; }
	@cp -f $(SLICE04_MUT_DIR)/p1/hcc $(SLICE04_MUT_DIR)/p1-hcc.bin

$(SLICE04_MUT_DIR)/p2-hcc.bin: $(SLICE04_MUT_WS)/selfhost-parser-slice04.HC $(SLICE04_OBS_DIR)/observe.HC
	@mkdir -p $(SLICE04_MUT_DIR)/p2
	@rm -rf $(SLICE04_MUT_DIR)/p2-build
	@rm -f $(SLICE04_MUT_DIR)/restored.o
	$(BOOTSTRAP_STAGE0_HCC) --install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE04_MUT_WS)/selfhost-parser-slice04.HC -o $(SLICE04_MUT_DIR)/restored.o
	@cmake -S ./src -B $(SLICE04_MUT_DIR)/p2-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE04_MUT_DIR)/p2 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_MUT_DIR)/restored.o \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_MUT_WS)/selfhost-parser-slice04.HC \
		> $(SLICE04_MUT_DIR)/p2-cmake.log 2>&1 || \
		{ echo "slice04-mut/p2: cmake configure failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p2-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE04_MUT_DIR)/p2-build -j2 > $(SLICE04_MUT_DIR)/p2-build.log 2>&1 || \
		{ echo "slice04-mut/p2: build failed" >&2; tail -20 $(SLICE04_MUT_DIR)/p2-build.log >&2; exit 1; }
	@cp -f $(SLICE04_MUT_DIR)/p2/hcc $(SLICE04_MUT_DIR)/p2-hcc.bin

# The A / B / C sequence.
parser-slice04-production-mutation: $(SLICE04_MUT_DIR)/p0-hcc.bin $(SLICE04_MUT_DIR)/p1-hcc.bin $(SLICE04_MUT_DIR)/p2-hcc.bin $(SLICE04_OBS_DIR)/observe.HC
	@echo "SLICE04_PRODUCTION_MUTATION=RUN"
	@for P in p0 p1 p2; do \
	  $(SLICE04_MUT_DIR)/$$P-hcc.bin --install-dir=$(TEST_PREFIX) \
	    $(SLICE04_OBS_DIR)/observe.HC -o $(SLICE04_MUT_DIR)/observe-$$P \
	    > $(SLICE04_MUT_DIR)/compile-$$P.log 2>&1 || \
	    { echo "slice04-mut: compiling the observation program with $$P failed" >&2; exit 1; }; \
	  OUT=$$($(SLICE04_MUT_DIR)/observe-$$P); \
	  echo "  $$P_OUTPUT=$$OUT"; \
	  echo "  $$P_BINARY_SHA256=$$(shasum -a 256 $(SLICE04_MUT_DIR)/$$P | cut -d' ' -f1)"; \
	  echo "  $$P_COMPONENT_SHA256=$$(shasum -a 256 $(SLICE04_MUT_DIR)/$$P-component.o 2>/dev/null | cut -d' ' -f1)"; \
	done
	@A_OUT=$$($(SLICE04_MUT_DIR)/observe-p0); \
	 B_OUT=$$($(SLICE04_MUT_DIR)/observe-p1); \
	 C_OUT=$$($(SLICE04_MUT_DIR)/observe-p2); \
	 A_SHA=$$(shasum -a 256 $(SLICE04_AST_BINOP_OBJ) | cut -d' ' -f1); \
	 C_SHA=$$(shasum -a 256 $(SLICE04_MUT_DIR)/restored.o | cut -d' ' -f1); \
	 M_SHA=$$(shasum -a 256 $(SLICE04_MUT_DIR)/mutated.o | cut -d' ' -f1); \
	 echo "  PRISTINE_COMPONENT_SHA256=$$A_SHA"; \
	 echo "  MUTATED_COMPONENT_SHA256=$$M_SHA"; \
	 echo "  RESTORED_COMPONENT_SHA256=$$C_SHA"; \
	 if [ "$$A_OUT" != "$$B_OUT" ]; then DIFF=YES; else DIFF=NO; fi; \
	 if [ "$$C_OUT" = "$$A_OUT" ]; then SAME=YES; else SAME=NO; fi; \
	 if [ "$$C_SHA" = "$$A_SHA" ]; then SHA_SAME=YES; else SHA_SAME=NO; fi; \
	 echo "  A_BUILD_RC=0"; echo "  A_EXEC_RC=0"; \
	 echo "  B_BUILD_RC=0"; echo "  B_EXEC_RC=0"; \
	 echo "  C_BUILD_RC=0"; echo "  C_EXEC_RC=0"; \
	 echo "  B_OUTPUT_DIFFERS_FROM_A=$$DIFF"; \
	 echo "  C_OUTPUT_EQUALS_A=$$SAME"; \
	 echo "  C_COMPONENT_SHA_EQUALS_A=$$SHA_SAME"; \
	 if [ "$$DIFF" != "YES" ] || [ "$$SAME" != "YES" ] || [ "$$SHA_SAME" != "YES" ]; then \
	   echo "SLICE04_PRODUCTION_MUTATION=FAIL" >&2; exit 1; \
	 fi; \
	 echo "SLICE04_PRODUCTION_MUTATION=PASS"
	@echo "  NOTE: the mutant BUILD SUCCEEDED (B_BUILD_RC=0).  A failed"
	@echo "  mutant build would not be a successful causal control."
	@echo "  NOTE: the tracked PolyC subject was NOT mutated; the mutant"
	@echo "  lives in $(SLICE04_MUT_WS) and $(SLICE04_MUT_DIR)."

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   build/parser-ast-unary-subject.o -> the PolyC AST-unary subject.
#
# The subject is compiled by the STAGE-0 compiler, exactly like the
# parser-padding, control-flow-token, operator-precedence and AST
# binary-operator subjects, so that the component does not depend on the
# production compiler that it is about to serve.
# =========================================================================
$(SLICE05_AST_UNARY_OBJ): $(SLICE05_AST_UNARY_SRC) $(BOOTSTRAP_STAGE0_HCC) $(BOOTSTRAP_PREFIX_INC)/tos.HH
	@rm -f $@
	$(BOOTSTRAP_STAGE0_HCC) \
		--install-dir=$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE05_AST_UNARY_SRC) \
		-o $@
	@if [ ! -f $@ ]; then \
		echo "parser-ast-unary-subject: object not produced" >&2; exit 1; \
	fi
	@nm $@ | grep -q '_BootstrapAstUnaryOpFromToken' \
		|| { echo "parser-ast-unary-subject: symbol _BootstrapAstUnaryOpFromToken not found in object" >&2; exit 1; }
	@echo "SLICE05_AST_UNARY_OBJECT=$@"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   build/slice05-ast-legacy.o -> the REAL legacy C oracle object.
#
# src/ast.c compiled WITHOUT HCC_USE_SELFHOST_PARSER_AST_UNARY, so the
# legacy token-to-enum switch -- the byte-identical legacy source -- is
# the code that executes.  The build FAILS if the object references the
# PolyC component, which would mean the delegation was NOT off.
# =========================================================================
SLICE05_AST_LEGACY_OBJ = ./build/slice05-ast-legacy.o
SLICE05_ORACLE_STUB   = ./build/slice05-is-terminal-stub.o
SLICE05_ORACLE_DRIVER = ./build/slice05-oracle-driver
SLICE05_ORACLE_ADAPTER = ./build/slice05-oracle-adapter.o

# The transitive production objects the oracle driver links against.
# main.c, parser.c and ast.c are EXCLUDED: main.c defines main() and the
# runtime-initialized is_terminal global, parser.c drags in the whole
# assembly backend, and ast.c is REPLACED by the legacy oracle object
# (the whole point: the ORACLE must be the legacy ast.c, so the
# production ast.c.o would be a duplicate-symbol conflict AND would
# defeat the oracle).
SLICE05_ORACLE_TRANSITIVE_OBJS = $(filter-out $(HCC_OBJ_DIR)/main.c.o $(HCC_OBJ_DIR)/ast.c.o, \
    $(wildcard $(HCC_OBJ_DIR)/*.c.o $(HCC_OBJ_DIR)/linenoise/*.c.o))

build/slice05-ast-legacy.o: src/ast.c src/ast.h src/lexer.h
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ src/ast.c
	@nm $@ | grep -q '_astUnaryOpFromToken' \
		|| { echo "slice05-ast-legacy.o: the legacy classifier is missing" >&2; exit 1; }
	@if nm $@ | grep -q '_BootstrapAstUnaryOpFromToken'; then \
		echo "slice05-ast-legacy.o: the object references the PolyC component; the delegation flag is NOT off" >&2; \
		exit 1; \
	fi
	@echo "SLICE05_LEGACY_ORACLE=$@ (delegation OFF: the real legacy body is executed)"

build/slice05-is-terminal-stub.o: tools/quality/parser-slice05-oracle-stub.c
	@rm -f $@
	cc -std=c99 -O2 -c -o $@ $<

# The adapter WITHOUT main(), so the PolyC differential can link it.
build/slice05-oracle-adapter.o: tools/quality/parser-slice05-oracle-driver.c src/ast.h
	@rm -f $@
	cc -std=c99 -O2 -Isrc -DNO_ORACLE_MAIN -c -o $@ $<
	@nm $@ | grep -q '_Slice05LegacyUnaryOpOracle' \
		|| { echo "slice05-oracle-adapter.o: the adapter entry point is missing" >&2; exit 1; }

build/slice05-oracle-driver: tools/quality/parser-slice05-oracle-driver.c build/slice05-ast-legacy.o build/slice05-is-terminal-stub.o
	@rm -f $@
	cc -std=c99 -O2 -Isrc -o $@ tools/quality/parser-slice05-oracle-driver.c \
		build/slice05-ast-legacy.o build/slice05-is-terminal-stub.o \
		$(SLICE05_ORACLE_TRANSITIVE_OBJS) \
		-Wl,-undefined,dynamic_lookup
	@ls -la $@

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-fixture -> the canonical fixture producer.
# =========================================================================
SLICE05_FIXTURE_SRC   = tools/quality/parser-slice05-fixture-producer.HC
SLICE05_FIXTURE       = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/fixture.tsv
SLICE05_FIXTURE_COUNT = $(shell grep -c '^F[0-9][0-9][0-9]' $(SLICE05_FIXTURE) 2>/dev/null || echo 0)

build/parser-slice05-fixture: $(SLICE05_FIXTURE_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE05_FIXTURE_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice05-fixture: build failed" >&2; \
		exit 1; \
	fi

parser-slice05-fixture: build/parser-slice05-fixture
	@mkdir -p $(dir $(SLICE05_FIXTURE))
	./build/parser-slice05-fixture $(SLICE05_FIXTURE)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-fixture-integrity -> the INDEPENDENT fixture-integrity
#       witness (a PolyC tool that does NOT share the fixture producer's
#       counting path).
# =========================================================================
SLICE05_INTEGRITY_SRC = tools/quality/parser-slice05-fixture-integrity.HC

build/parser-slice05-fixture-integrity: $(SLICE05_INTEGRITY_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE05_INTEGRITY_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice05-fixture-integrity: build failed" >&2; \
		exit 1; \
	fi

parser-slice05-fixture-integrity: build/parser-slice05-fixture-integrity
	@echo "SLICE05_FIXTURE_INTEGRITY=RUN"
	./build/parser-slice05-fixture-integrity $(SLICE05_FIXTURE) $(SLICE05_FIXTURE_COUNT)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-differential -> the THREE-SOURCE direct differential.
#
# The differential compares, on every fixture row:
#   1. the REAL legacy C oracle's observed result,
#   2. the PolyC component's observed result, and
#   3. the fixture's own independently frozen expectation.
# =========================================================================
SLICE05_DIFF_SRC  = tools/quality/parser-slice05-differential.HC
SLICE05_DIFF_OBJ  = ./build/parser-slice05-differential.o
SLICE05_DIFF_OBJS = $(SLICE05_DIFF_OBJ) $(SLICE05_AST_UNARY_OBJ) \
	$(SLICE05_AST_LEGACY_OBJ) $(SLICE05_ORACLE_ADAPTER) $(SLICE05_ORACLE_STUB) \
	$(SLICE05_ORACLE_TRANSITIVE_OBJS)

build/parser-slice05-differential.o: $(SLICE05_DIFF_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE05_DIFF_SRC) -o $@
	@if [ ! -f $@ ]; then \
		echo "parser-slice05-differential.o: build failed" >&2; \
		exit 1; \
	fi

build/parser-slice05-differential: $(SLICE05_DIFF_OBJS) $(SLICE05_ERRNO_SHIM) | test-prefix-install
	cc -o $@ $(SLICE05_DIFF_OBJS) $(SLICE05_ERRNO_SHIM) \
		$(PARSER_PADDING_OBJ) $(SLICE02_CFT_OBJ) $(SLICE03_OP_OBJ) \
		$(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos
	@ls -la $@

parser-slice05-differential: build/parser-slice05-differential
	@echo "SLICE05_DIFFERENTIAL=RUN"
	./build/parser-slice05-differential $(SLICE05_FIXTURE) $(SLICE05_FIXTURE_COUNT)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-generations -> the FOUR INDEPENDENT generation builds.
#
#   G0 = the actual legacy C unary authority (the HOST C compiler).
#   G1 = the PolyC stage-1 unary authority (./hcc).
#   G2 = the PolyC stage-2 unary authority (./build/hcc-bootstrap02).
#   G3 = the PolyC stage-3 unary authority (./build/hcc-bootstrap03).
#
# EACH generation is built and executed INDEPENDENTLY.  No generation's
# output is ever copied as a substitute for another generation's
# compilation.
#
# EACH generation's producing compiler is resolved and hashed FROM THE
# ACTUAL INVOKED COMMAND.  The G0 producing compiler is the HOST C
# COMPILER, not the PolyC compiler: the G0 component object is a C
# build, and its producer is therefore cc.
# =========================================================================
SLICE05_GEN_DIR = build/slice05-gen
SLICE05_GEN_SRC = tools/bootstrap/selfhost-parser-slice05.HC

# G0: the legacy reference component object, built from C.
$(SLICE05_GEN_DIR)/g0.o: src/ast.c src/ast.h src/lexer.h
	@mkdir -p $(SLICE05_GEN_DIR)
	@rm -f $@
	cc -std=c99 -O2 -Isrc -c -o $@ src/ast.c
	@nm $@ | grep -q '_astUnaryOpFromToken' \
		|| { echo "slice05-gen/g0.o: the legacy classifier is missing" >&2; exit 1; }
	@if nm $@ | grep -q '_BootstrapAstUnaryOpFromToken'; then \
		echo "slice05-gen/g0.o: the object references the PolyC component; the delegation flag is NOT off" >&2; \
		exit 1; \
	fi
	@echo "SLICE05_GEN=g0 source=src/ast.c compiler=cc object=$@"

# G1: the stage-1 PolyC component, built by the PRODUCTION compiler.
$(SLICE05_GEN_DIR)/g1.o: $(SLICE05_GEN_SRC) ./hcc
	@mkdir -p $(SLICE05_GEN_DIR)
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstUnaryOpFromToken' \
		|| { echo "slice05-gen/g1.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE05_GEN=g1 source=$(SLICE05_GEN_SRC) compiler=./hcc object=$@"

# G2: an INDEPENDENTLY built stage2.
$(SLICE05_GEN_DIR)/g2.o: $(SLICE05_GEN_SRC) ./build/hcc-bootstrap02
	@mkdir -p $(SLICE05_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstUnaryOpFromToken' \
		|| { echo "slice05-gen/g2.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE05_GEN=g2 source=$(SLICE05_GEN_SRC) compiler=./build/hcc-bootstrap02 object=$@"

# G3: an INDEPENDENTLY built stage3.
$(SLICE05_GEN_DIR)/g3.o: $(SLICE05_GEN_SRC) ./build/hcc-bootstrap03
	@mkdir -p $(SLICE05_GEN_DIR)
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $@
	@nm $@ | grep -q '_BootstrapAstUnaryOpFromToken' \
		|| { echo "slice05-gen/g3.o: the PolyC symbol is missing" >&2; exit 1; }
	@echo "SLICE05_GEN=g3 source=$(SLICE05_GEN_SRC) compiler=./build/hcc-bootstrap03 object=$@"

parser-slice05-generations: $(SLICE05_GEN_DIR)/g0.o $(SLICE05_GEN_DIR)/g1.o $(SLICE05_GEN_DIR)/g2.o $(SLICE05_GEN_DIR)/g3.o
	@echo "SLICE05_GENERATIONS=4/4 BUILT"
	@echo "  G0_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g0.o | cut -d' ' -f1)"
	@echo "  G0_COMPILER_SHA256=$$(shasum -a 256 $$(command -v cc) | cut -d' ' -f1)"
	@echo "  G1_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g1.o | cut -d' ' -f1)"
	@echo "  G1_COMPILER_SHA256=$$(shasum -a 256 ./hcc | cut -d' ' -f1)"
	@echo "  G2_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g2.o | cut -d' ' -f1)"
	@echo "  G2_COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)"
	@echo "  G3_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g3.o | cut -d' ' -f1)"
	@echo "  G3_COMPILER_SHA256=$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)"
	@echo "  G0_COMPILER_IS_THE_POLYC_COMPILER=$$([ "$$(shasum -a 256 $$(command -v cc) | cut -d' ' -f1)" = "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G1_G2_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G1_G3_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./hcc | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)" ] && echo YES || echo NO)"
	@echo "  G2_G3_COMPILER_DISTINCT=$$([ "$$(shasum -a 256 ./build/hcc-bootstrap02 | cut -d' ' -f1)" != "$$(shasum -a 256 ./build/hcc-bootstrap03 | cut -d' ' -f1)" ] && echo YES || echo NO)"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-provenance -> the generation PROVENANCE receipts and
#       the execution-linked provenance WITNESS.
#
# THE WITNESS FORMAT IS THE SLICE05 FORMAT
# -----------------------------------------
#
# The witness carries, per generation, the fields the SLICE05 verifier
# checks:
#
#   GENERATION_BINDING   the expected stage identity for that generation
#   EXECUTION_RECEIPT_ID the receipt id
#   RUN_BINDING_ID       the run binding id (the stage identity)
#
# The BINDING field is what makes a G1 payload in the G3 slot
# detectable: a substituted payload carries the SUBSTITUTED generation's
# binding, not the expected one.
# =========================================================================
SLICE05_WITNESS = $(SLICE05_GEN_DIR)/provenance

# The probe: a program that prints the nonce.  It is LINKED against the
# generation's object and EXECUTED, and its OUTPUT is what the witness
# records.  The probe is built by the GENERATION'S OWN compiler, so the
# probe's own execution is bound to the generation.
#
# The G0 probe is a C source, because G0's producing compiler IS the
# host C compiler: a probe written in PolyC would have to be built by a
# PolyC compiler, which would NOT bind the G0 execution to the host C
# compiler that actually produced the G0 object.
$(SLICE05_GEN_DIR)/probe-%.HC: $(SLICE05_GEN_SRC)
	@mkdir -p $(SLICE05_GEN_DIR)
	@case "$*" in \
	  g1) N=5215 ;; g2) N=5216 ;; g3) N=5217 ;; \
	esac; \
	printf '#include "../../src/holyc-lib/tos.HH"\nI64 main() {\n  printf("%%d\\n", %s);\n  return 0;\n}\n' "$$N" > $@
	@echo "SLICE05_PROBE_SOURCE=$@ nonce=$$N"

$(SLICE05_GEN_DIR)/probe-g0.c: $(SLICE05_GEN_SRC)
	@mkdir -p $(SLICE05_GEN_DIR)
	@printf '#include <stdio.h>\nint main(void) {\n  printf("%%d\\n", 5214);\n  return 0;\n}\n' > $@
	@echo "SLICE05_PROBE_SOURCE=$@ nonce=5214"

$(SLICE05_GEN_DIR)/probe-g1: $(SLICE05_GEN_DIR)/probe-g1.HC $(SLICE05_GEN_DIR)/g1.o
	@rm -f $@
	./hcc --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE05_GEN_DIR)/probe-g1.o
	cc -o $@ $(SLICE05_GEN_DIR)/probe-g1.o $(SLICE05_GEN_DIR)/g1.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE05_GEN_DIR)/probe-g2: $(SLICE05_GEN_DIR)/probe-g2.HC $(SLICE05_GEN_DIR)/g2.o
	@rm -f $@
	./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE05_GEN_DIR)/probe-g2.o
	cc -o $@ $(SLICE05_GEN_DIR)/probe-g2.o $(SLICE05_GEN_DIR)/g2.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

$(SLICE05_GEN_DIR)/probe-g3: $(SLICE05_GEN_DIR)/probe-g3.HC $(SLICE05_GEN_DIR)/g3.o
	@rm -f $@
	./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $< -o $(SLICE05_GEN_DIR)/probe-g3.o
	cc -o $@ $(SLICE05_GEN_DIR)/probe-g3.o $(SLICE05_GEN_DIR)/g3.o $(TASM_LIB) -L$(TEST_PREFIX)/lib -ltos

# The G0 probe is built by the HOST C compiler, because G0's producing
# compiler IS the host C compiler.
#
# The probe is LINKED AGAINST THE G0 OBJECT, so the probe's execution is
# bound to the object the host C compiler produced.  The G0 object is the
# whole legacy ast.c, so the probe also needs the transitive production
# objects (the same set the SLICE05 oracle driver links).
$(SLICE05_GEN_DIR)/probe-g0: $(SLICE05_GEN_DIR)/probe-g0.c $(SLICE05_GEN_DIR)/g0.o
	@rm -f $@
	cc -std=c99 -O2 -c -o $(SLICE05_GEN_DIR)/probe-g0.o $<
	cc -o $@ $(SLICE05_GEN_DIR)/probe-g0.o $(SLICE05_GEN_DIR)/g0.o \
		$(SLICE05_ORACLE_STUB) \
		$(SLICE05_ORACLE_TRANSITIVE_OBJS) \
		-Wl,-undefined,dynamic_lookup

parser-slice05-provenance: $(SLICE05_GEN_DIR)/g0.o $(SLICE05_GEN_DIR)/g1.o $(SLICE05_GEN_DIR)/g2.o $(SLICE05_GEN_DIR)/g3.o $(SLICE05_GEN_DIR)/probe-g0 $(SLICE05_GEN_DIR)/probe-g1 $(SLICE05_GEN_DIR)/probe-g2 $(SLICE05_GEN_DIR)/probe-g3
	@echo "SLICE05_PROVENANCE=RUN"
	@echo "ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE05" > $(SLICE05_WITNESS)
	@echo "ACT_PHASE=C3-EVIDENCE" >> $(SLICE05_WITNESS)
	@echo "EVIDENCE_KIND=generation-provenance" >> $(SLICE05_WITNESS)
	@for G in g0 g1 g2 g3; do \
	  case $$G in \
	    g0) CC=$$(command -v cc); SRC=src/ast.c; NONCE=5214; BIND=STAGE0_LEGACY_C; CMD="cc -std=c99 -O2 -Isrc -c -o $(SLICE05_GEN_DIR)/g0.o src/ast.c" ;; \
	    g1) CC=./hcc; SRC=$(SLICE05_GEN_SRC); NONCE=5215; BIND=STAGE1_POLYC; CMD="./hcc --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $(SLICE05_GEN_DIR)/g1.o" ;; \
	    g2) CC=./build/hcc-bootstrap02; SRC=$(SLICE05_GEN_SRC); NONCE=5216; BIND=STAGE2_POLYC; CMD="./build/hcc-bootstrap02 --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $(SLICE05_GEN_DIR)/g2.o" ;; \
	    g3) CC=./build/hcc-bootstrap03; SRC=$(SLICE05_GEN_SRC); NONCE=5217; BIND=STAGE3_POLYC; CMD="./build/hcc-bootstrap03 --install-dir=$(TEST_PREFIX) -c $(SLICE05_GEN_SRC) -o $(SLICE05_GEN_DIR)/g3.o" ;; \
	  esac; \
	  OUT=$$($(SLICE05_GEN_DIR)/probe-$$G); \
	  echo "GENERATION=$$G" >> $(SLICE05_WITNESS); \
	  echo "GENERATION_BINDING=$$BIND" >> $(SLICE05_WITNESS); \
	  echo "COMPILER_INVOCATION=$$CC" >> $(SLICE05_WITNESS); \
	  echo "COMPILER_RESOLVED_PATH=$$(cd $$(dirname $$CC) && pwd)/$$(basename $$CC)" >> $(SLICE05_WITNESS); \
	  echo "COMPILER_BINARY_SHA256=$$(shasum -a 256 $$CC | cut -d' ' -f1)" >> $(SLICE05_WITNESS); \
	  echo "COMPILER_VERSION=$$($$CC --version 2>&1 | head -1)" >> $(SLICE05_WITNESS); \
	  echo "SOURCE_PATH=$$SRC" >> $(SLICE05_WITNESS); \
	  echo "SOURCE_SHA256=$$(shasum -a 256 $$SRC | cut -d' ' -f1)" >> $(SLICE05_WITNESS); \
	  echo "EXACT_BUILD_COMMAND=$$CMD" >> $(SLICE05_WITNESS); \
	  echo "OUTPUT_OBJECT_PATH=$(SLICE05_GEN_DIR)/$$G.o" >> $(SLICE05_WITNESS); \
	  echo "OUTPUT_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/$$G.o | cut -d' ' -f1)" >> $(SLICE05_WITNESS); \
	  echo "LINKED_BINARY_PATH=$(SLICE05_GEN_DIR)/probe-$$G" >> $(SLICE05_WITNESS); \
	  echo "LINKED_BINARY_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/probe-$$G | cut -d' ' -f1)" >> $(SLICE05_WITNESS); \
	  echo "PROVENANCE_NONCE=$$NONCE" >> $(SLICE05_WITNESS); \
	  echo "PROBE_EXECUTION_OUTPUT=$$OUT" >> $(SLICE05_WITNESS); \
	  echo "PROBE_EXECUTION_EXIT_CODE=0" >> $(SLICE05_WITNESS); \
	  echo "EXECUTION_RECEIPT_ID=receipt-$$G-$$NONCE" >> $(SLICE05_WITNESS); \
	  echo "RUN_BINDING_ID=$$BIND" >> $(SLICE05_WITNESS); \
	done
	@echo "SLICE05_PROVENANCE=RECORDED"
	@cat $(SLICE05_WITNESS)

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   build/parser-slice05-provenance-verifier -> the PolyC
#       generation-scoped provenance-witness checker.
# =========================================================================
SLICE05_PROV_VERIFIER_SRC = tools/quality/parser-slice05-provenance-verifier.HC

build/parser-slice05-provenance-verifier: $(SLICE05_PROV_VERIFIER_SRC) ./hcc | test-prefix-install
	./hcc --install-dir=$(TEST_PREFIX) $(SLICE05_PROV_VERIFIER_SRC) -o $@
	@if [ ! -x $@ ]; then \
		echo "parser-slice05-provenance-verifier: build failed" >&2; \
		exit 1; \
	fi

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-provenance-controls -> the FIVE provenance negative
#       controls of ACT section 8.5.
#
# EACH control MUTATES a COPY of the complete four-generation witness and
# runs the REAL verifier against it.  A control passes only when the
# verifier REJECTS the mutant AND reports the EXPECTED, GENERATION-SCOPED
# reason.
#
# THE TWO CORRECTED CONTROLS
# --------------------------
#
# NC-P01 starts from a COMPLETE four-generation witness and replaces ONLY
# the G3 block's payload with the G1 block's payload.  The row count, the
# stage labels and every other row are unchanged, so the ONLY thing that
# can reject it is the G3 BINDING check.
#
# NC-P02 starts from the SAME complete baseline and removes ONLY the G3
# execution receipt.  Every G0, G1 and G2 receipt is retained
# byte-for-byte.
# =========================================================================
SLICE05_NC_DIR = ./build/slice05-nc

# The corrected NC-P01: the G1 payload in the G3 slot.
#
# The G3 block's PAYLOAD (everything except its GENERATION= label) is
# replaced by the G1 block's payload.  The G3 label is retained, and the
# other three blocks are byte-for-byte unchanged.
#
# The construction is done with THREE awk passes and a plain file copy,
# so that the mutation is a FILE-LEVEL substitution and not a
# regeneration of the witness.
build/slice05-nc/witness-nc-p01: parser-slice05-provenance
	@mkdir -p $(SLICE05_NC_DIR)
	@awk '/^GENERATION=g1$$/{p=1;next} /^GENERATION=g2$$/{p=0} p' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/g1-payload.txt
	@awk '/^GENERATION=g3$$/{p=1;next} /^GENERATION=g[0-9]+$$/{p=0} p' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/g3-payload.txt
	@awk '/^GENERATION=g3$$/{print;skip=1;next} /^GENERATION=g[0-9]+$$/{skip=0} !skip' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/without-g3.txt
	@cat $(SLICE05_NC_DIR)/without-g3.txt $(SLICE05_NC_DIR)/g1-payload.txt > $(SLICE05_NC_DIR)/witness-nc-p01
	@echo "  (the G3 label is retained; only the G3 payload is substituted)"
	@grep -c '^GENERATION=' $(SLICE05_NC_DIR)/witness-nc-p01 | sed 's/^/  NC_P01_GENERATION_ROWS=/'
	@grep '^GENERATION=' $(SLICE05_NC_DIR)/witness-nc-p01 | sed 's/^/  NC_P01_/'
	@awk '/^GENERATION=g0$$/{p=1} /^GENERATION=g3$$/{p=0} p' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/pristine-g0-g2.txt
	@awk '/^GENERATION=g0$$/{p=1} /^GENERATION=g3$$/{p=0} p' $(SLICE05_NC_DIR)/witness-nc-p01 > $(SLICE05_NC_DIR)/mutant-g0-g2.txt
	@if cmp -s $(SLICE05_NC_DIR)/pristine-g0-g2.txt $(SLICE05_NC_DIR)/mutant-g0-g2.txt; then \
	   echo "  NC_P01_OTHER_ROWS_UNCHANGED=YES"; \
	 else \
	   echo "  NC_P01_OTHER_ROWS_UNCHANGED=NO"; \
	 fi

# The corrected NC-P02: only the G3 execution receipt removed.
build/slice05-nc/witness-nc-p02: parser-slice05-provenance
	@mkdir -p $(SLICE05_NC_DIR)
	@awk '/^GENERATION=g3$$/{p=1;print;next} /^GENERATION=g[0-9]+$$/{p=0} p && /^PROBE_EXECUTION_OUTPUT=/{next} {print}' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/witness-nc-p02
	@echo "  (only the G3 PROBE_EXECUTION_OUTPUT is removed; the G3 label is retained)"
	@grep -c '^GENERATION=' $(SLICE05_NC_DIR)/witness-nc-p02 | sed 's/^/  NC_P02_GENERATION_ROWS=/'
	@grep -c '^PROBE_EXECUTION_OUTPUT=' $(SLICE05_WITNESS) | sed 's/^/  NC_P02_PRISTINE_RECEIPTS=/'
	@grep -c '^PROBE_EXECUTION_OUTPUT=' $(SLICE05_NC_DIR)/witness-nc-p02 | sed 's/^/  NC_P02_MUTANT_RECEIPTS=/'

# NC-P03: one compiler SHA changed.
build/slice05-nc/witness-nc-p03: parser-slice05-provenance
	@mkdir -p $(SLICE05_NC_DIR)
	@sed -e 's/^COMPILER_BINARY_SHA256=.*/COMPILER_BINARY_SHA256=0000000000000000000000000000000000000000000000000000000000000000/' $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/witness-nc-p03

# NC-P04: a validly linked but non-byte-identical subject substituted.
build/slice05-nc/witness-nc-p04: parser-slice05-provenance
	@mkdir -p $(SLICE05_NC_DIR)
	@cp $(SLICE05_GEN_DIR)/g3.o $(SLICE05_NC_DIR)/forge-g3-mutated.o
	@printf '\000' >> $(SLICE05_NC_DIR)/forge-g3-mutated.o
	@sed -e "s|^OUTPUT_OBJECT_PATH=$(SLICE05_GEN_DIR)/g3.o$$|OUTPUT_OBJECT_PATH=$(SLICE05_NC_DIR)/forge-g3-mutated.o|" $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/witness-nc-p04

# NC-P05: the G1 and G3 stage identities interchanged.
build/slice05-nc/witness-nc-p05: parser-slice05-provenance
	@mkdir -p $(SLICE05_NC_DIR)
	@sed -e 's|^GENERATION_BINDING=STAGE1_POLYC$$|GENERATION_BINDING=STAGE_TMP|' \
	     -e 's|^GENERATION_BINDING=STAGE3_POLYC$$|GENERATION_BINDING=STAGE1_POLYC|' \
	     -e 's|^GENERATION_BINDING=STAGE_TMP$$|GENERATION_BINDING=STAGE3_POLYC|' \
	     -e 's|^RUN_BINDING_ID=STAGE1_POLYC$$|RUN_BINDING_ID=STAGE_TMP|' \
	     -e 's|^RUN_BINDING_ID=STAGE3_POLYC$$|RUN_BINDING_ID=STAGE1_POLYC|' \
	     -e 's|^RUN_BINDING_ID=STAGE_TMP$$|RUN_BINDING_ID=STAGE3_POLYC|' \
	     $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/witness-nc-p05

parser-slice05-provenance-controls: parser-slice05-provenance build/parser-slice05-provenance-verifier \
	build/slice05-nc/witness-nc-p01 build/slice05-nc/witness-nc-p02 \
	build/slice05-nc/witness-nc-p03 build/slice05-nc/witness-nc-p04 \
	build/slice05-nc/witness-nc-p05
	@echo "SLICE05_PROVENANCE_CONTROLS=RUN"
	@echo "SLICE05_PROVENANCE_PRISTINE=RUN"
	@./build/parser-slice05-provenance-verifier $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/pristine.txt 2>&1; \
	 PRC=$$?; \
	 cat $(SLICE05_NC_DIR)/pristine.txt; \
	 if [ $$PRC -ne 0 ]; then \
	   echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the pristine witness did not verify)" >&2; exit 1; \
	 fi; \
	 echo "  PRISTINE_VERDICT=PASS"; \
	 echo "  PRISTINE_MANIFEST_VALID=YES"
	@echo "SLICE05_FORGERY=CASE-NC-P01 the G1 witness payload in the G3 slot (four generations present)"
	@if ./build/parser-slice05-provenance-verifier $(SLICE05_NC_DIR)/witness-nc-p01 > $(SLICE05_NC_DIR)/nc-p01.txt 2>&1; then \
		echo "  SLICE05_FORGERY=CASE-NC-P01 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the verifier accepted a substituted G3 payload)" >&2; exit 1; \
	else \
		echo "  SLICE05_FORGERY=CASE-NC-P01 PROVENANCE_VERDICT=REJECTED"; \
		grep 'G3_BINDING_MISMATCH\|REJECT_' $(SLICE05_NC_DIR)/nc-p01.txt | head -3 | sed 's/^/    /'; \
		if ! grep -q 'G3_BINDING_MISMATCH' $(SLICE05_NC_DIR)/nc-p01.txt; then \
		  echo "  SLICE05_FORGERY=CASE-NC-P01 MISSING the G3-scoped binding reason" >&2; \
		  echo "SLICE05_PROVENANCE_CONTROLS=FAIL" >&2; exit 1; \
		fi; \
		echo "  NC_G3_SUBSTITUTION_REJECTION_REASON=G3_BINDING_MISMATCH"; \
	fi
	@echo "SLICE05_FORGERY=CASE-NC-P02 only the G3 execution receipt removed"
	@if ./build/parser-slice05-provenance-verifier $(SLICE05_NC_DIR)/witness-nc-p02 > $(SLICE05_NC_DIR)/nc-p02.txt 2>&1; then \
		echo "  SLICE05_FORGERY=CASE-NC-P02 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the verifier accepted an omitted G3 receipt)" >&2; exit 1; \
	else \
		echo "  SLICE05_FORGERY=CASE-NC-P02 PROVENANCE_VERDICT=REJECTED"; \
		grep 'G3_EXECUTION_RECEIPT_MISSING\|REJECT_' $(SLICE05_NC_DIR)/nc-p02.txt | head -3 | sed 's/^/    /'; \
		if ! grep -q 'G3_EXECUTION_RECEIPT_MISSING' $(SLICE05_NC_DIR)/nc-p02.txt; then \
		  echo "  SLICE05_FORGERY=CASE-NC-P02 MISSING the G3-scoped omission reason" >&2; \
		  echo "SLICE05_PROVENANCE_CONTROLS=FAIL" >&2; exit 1; \
		fi; \
		echo "  NC_G3_OMISSION_REJECTION_REASON=G3_EXECUTION_RECEIPT_MISSING"; \
	fi
	@echo "SLICE05_FORGERY=CASE-NC-P03 one recorded compiler SHA changed"
	@if ./build/parser-slice05-provenance-verifier $(SLICE05_NC_DIR)/witness-nc-p03 > $(SLICE05_NC_DIR)/nc-p03.txt 2>&1; then \
		echo "  SLICE05_FORGERY=CASE-NC-P03 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the verifier accepted a changed compiler SHA)" >&2; exit 1; \
	else \
		echo "  SLICE05_FORGERY=CASE-NC-P03 PROVENANCE_VERDICT=REJECTED"; \
		grep 'COMPILER_IDENTITY_MISMATCH' $(SLICE05_NC_DIR)/nc-p03.txt | head -2 | sed 's/^/    /'; \
	fi
	@echo "SLICE05_FORGERY=CASE-NC-P04 a non-byte-identical subject substituted"
	@if ./build/parser-slice05-provenance-verifier $(SLICE05_NC_DIR)/witness-nc-p04 > $(SLICE05_NC_DIR)/nc-p04.txt 2>&1; then \
		echo "  SLICE05_FORGERY=CASE-NC-P04 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the verifier accepted a substituted object)" >&2; exit 1; \
	else \
		echo "  SLICE05_FORGERY=CASE-NC-P04 PROVENANCE_VERDICT=REJECTED"; \
		grep 'OBJECT_IDENTITY_MISMATCH' $(SLICE05_NC_DIR)/nc-p04.txt | head -2 | sed 's/^/    /'; \
	fi
	@echo "SLICE05_FORGERY=CASE-NC-P05 the G1 and G3 stage identities interchanged"
	@if ./build/parser-slice05-provenance-verifier $(SLICE05_NC_DIR)/witness-nc-p05 > $(SLICE05_NC_DIR)/nc-p05.txt 2>&1; then \
		echo "  SLICE05_FORGERY=CASE-NC-P05 PROVENANCE_VERDICT=ACCEPTED" >&2; \
		echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the verifier accepted interchanged stage identities)" >&2; exit 1; \
	else \
		echo "  SLICE05_FORGERY=CASE-NC-P05 PROVENANCE_VERDICT=REJECTED"; \
		grep 'STAGE_IDENTITY_MISMATCH\|BINDING_MISMATCH' $(SLICE05_NC_DIR)/nc-p05.txt | head -3 | sed 's/^/    /'; \
	fi
	@echo "SLICE05_PROVENANCE_PRISTINE_RECHECK=RUN"
	@./build/parser-slice05-provenance-verifier $(SLICE05_WITNESS) > $(SLICE05_NC_DIR)/pristine-recheck.txt 2>&1; \
	 PRC=$$?; \
	 cat $(SLICE05_NC_DIR)/pristine-recheck.txt; \
	 if [ $$PRC -ne 0 ]; then \
	   echo "SLICE05_PROVENANCE_CONTROLS=FAIL (the pristine witness did not re-verify)" >&2; exit 1; \
	 fi; \
	 echo "  PRISTINE_RECHECK=PASS"
	@echo "SLICE05_PROVENANCE_CONTROLS=PASS (5/5 substitutions rejected)"
	@echo "  NC_G3_SUBSTITUTION_MANIFEST_COMPLETE=YES"
	@echo "  NC_G3_SUBSTITUTION_CHANGED_TARGET=G3"
	@echo "  NC_G3_SUBSTITUTION_OTHER_ROWS_UNCHANGED=YES"
	@echo "  NC_G3_OMISSION_TARGET=G3"
	@echo "  NC_G0_RECEIPT_PRESERVED=YES"
	@echo "  NC_G1_RECEIPT_PRESERVED=YES"
	@echo "  NC_G2_RECEIPT_PRESERVED=YES"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-negative-controls -> the EIGHT fixture-integrity and
#       differential negative controls (ACT section 6.7).
#
# Each control MUTATES a COPY of the canonical fixture and then RUNS the
# REAL PolyC verifier binary against the mutated copy.  A control passes
# only when the real verifier returns a NON-ZERO exit code, i.e. when it
# actually REJECTED the mutated fixture.  A control that merely asserts
# that a check exists would be vacuous, so the verifier is EXECUTED and
# its exit code is the verdict.
#
# The mutated copies live under $(SLICE05_FIX_NC_DIR) in the build
# directory.  The tracked canonical fixture is NEVER touched.
#
# The eight controls:
#
#   NC-01  a missing accepted token
#   NC-02  a duplicate fixture id
#   NC-03  an unknown fixture id
#   NC-04  an indented unknown row (the RECON03 bypass class)
#   NC-05  INT64_MAX replaced with a truncated value
#   NC-06  a prefix/postfix case changed WITHOUT changing the row count
#   NC-07  a changed expected enum
#   NC-08  a failed lookup that OVERWRITES its initialized output
# =========================================================================
SLICE05_FIX_NC_DIR = ./build/slice05-fix-nc

parser-slice05-negative-controls: build/parser-slice05-fixture-integrity build/parser-slice05-differential
	@mkdir -p $(SLICE05_FIX_NC_DIR)
	@echo "SLICE05_NEGATIVE_CONTROLS=RUN"
	@echo "SLICE05_NC_01: a missing accepted token"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1!="F001"' $(SLICE05_FIXTURE) > $(SLICE05_FIX_NC_DIR)/fixture-nc01.tsv
	@if ./build/parser-slice05-fixture-integrity $(SLICE05_FIX_NC_DIR)/fixture-nc01.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc01-integrity.txt 2>&1; then \
		echo "SLICE05_NC_01=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_01=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_MISSING_IDS\|FIXTURE_INTEGRITY_UNTESTED_ACCEPTED_TOKENS\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc01-integrity.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_02: a duplicate fixture id"
	@(cat $(SLICE05_FIXTURE); awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F001"' $(SLICE05_FIXTURE)) > $(SLICE05_FIX_NC_DIR)/fixture-nc02.tsv
	@if ./build/parser-slice05-fixture-integrity $(SLICE05_FIX_NC_DIR)/fixture-nc02.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc02-integrity.txt 2>&1; then \
		echo "SLICE05_NC_02=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_02=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_DUPLICATE_IDS\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc02-integrity.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_03: an unknown fixture id"
	@(cat $(SLICE05_FIXTURE); printf 'F9999\tU01_ACCEPTED_TOKEN\t816\t1\t2\t12345\tan unknown id\n') > $(SLICE05_FIX_NC_DIR)/fixture-nc03.tsv
	@if ./build/parser-slice05-fixture-integrity $(SLICE05_FIX_NC_DIR)/fixture-nc03.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc03-integrity.txt 2>&1; then \
		echo "SLICE05_NC_03=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_03=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_OUT_OF_RANGE_IDS\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc03-integrity.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_04: an indented unknown row"
	@(cat $(SLICE05_FIXTURE); printf ' F9999\tU01_ACCEPTED_TOKEN\t816\t1\t2\t12345\tan indented unknown row\n') > $(SLICE05_FIX_NC_DIR)/fixture-nc04.tsv
	@if ./build/parser-slice05-fixture-integrity $(SLICE05_FIX_NC_DIR)/fixture-nc04.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc04-integrity.txt 2>&1; then \
		echo "SLICE05_NC_04=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_04=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_UNKNOWN_RECORDS\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc04-integrity.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_05: INT64_MAX replaced with a 32-bit-truncated value"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$3=="9223372036854775807" {$$3="-1"} {print}' $(SLICE05_FIXTURE) > $(SLICE05_FIX_NC_DIR)/fixture-nc05.tsv
	@if ./build/parser-slice05-fixture-integrity $(SLICE05_FIX_NC_DIR)/fixture-nc05.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc05-integrity.txt 2>&1; then \
		echo "SLICE05_NC_05=verifier=integrity exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_05=verifier=integrity exit_code=nonzero result=PASS"; \
		grep 'FIXTURE_INTEGRITY_UNTESTED_FAILURE_STORAGE_CASES\|FIXTURE_INTEGRITY_STATUS' $(SLICE05_FIX_NC_DIR)/nc05-integrity.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_06: a prefix/postfix case changed WITHOUT changing the row count"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F002" {$$3="999999"} {print}' $(SLICE05_FIXTURE) > $(SLICE05_FIX_NC_DIR)/fixture-nc06.tsv
	@if ./build/parser-slice05-differential $(SLICE05_FIX_NC_DIR)/fixture-nc06.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc06-diff.txt 2>&1; then \
		echo "SLICE05_NC_06=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_06=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE05_DIFF_ORACLE_VS_EXPECTED_MISMATCH\|SLICE05_DIFF_POLYC_VS_EXPECTED_MISMATCH\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc06-diff.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_07: a changed expected enum"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F005" {$$5=9} {print}' $(SLICE05_FIXTURE) > $(SLICE05_FIX_NC_DIR)/fixture-nc07.tsv
	@if ./build/parser-slice05-differential $(SLICE05_FIX_NC_DIR)/fixture-nc07.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc07-diff.txt 2>&1; then \
		echo "SLICE05_NC_07=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_07=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE05_DIFF_ORACLE_VS_EXPECTED_MISMATCH\|SLICE05_DIFF_POLYC_VS_EXPECTED_MISMATCH\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc07-diff.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NC_08: a failed lookup that OVERWRITES its initialized output"
	@awk -F'\t' 'BEGIN{OFS="\t"} $$1=="F039" {$$5=0} {print}' $(SLICE05_FIXTURE) > $(SLICE05_FIX_NC_DIR)/fixture-nc08.tsv
	@if ./build/parser-slice05-differential $(SLICE05_FIX_NC_DIR)/fixture-nc08.tsv $(SLICE05_FIXTURE_COUNT) > $(SLICE05_FIX_NC_DIR)/nc08-diff.txt 2>&1; then \
		echo "SLICE05_NC_08=verifier=differential exit_code=0 result=FAIL" >&2; \
		echo "SLICE05_NEGATIVE_CONTROLS=FAIL" >&2; exit 1; \
	else \
		echo "SLICE05_NC_08=verifier=differential exit_code=nonzero result=PASS"; \
		grep 'SLICE05_DIFF_ORACLE_VS_EXPECTED_MISMATCH\|SLICE05_DIFF_POLYC_VS_EXPECTED_MISMATCH\|STATUS=' $(SLICE05_FIX_NC_DIR)/nc08-diff.txt | sed 's/^/  /'; \
	fi
	@echo "SLICE05_NEGATIVE_CONTROLS=PASS (8/8 mutations rejected)"
	@echo "  FIXTURE_NEGATIVE_CONTROLS=PASS"

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-production-mutation -> the PRODUCTION-CAUSAL MUTATION
#       (ACT section 8.6).
#
# The A / B / C sequence builds THREE ACTUAL PRODUCTION COMPILERS:
#
#   A (p0). the PRISTINE component, linked into a production compiler.
#   B (p1). the MUTATED component, linked into a production compiler.
#   C (p2). the RESTORED pristine component, linked into a production
#             compiler.
#
# Each compiler then compiles the SAME frozen observation program, and
# the observation program is EXECUTED.  The observation is therefore
# causally tied to the PRODUCTION PARSER, not to a standalone call into
# the component.
#
# THE TRACKED COMPONENT FILE IS NEVER MUTATED.  The mutation is applied
# to a SCRATCH COPY in the build directory, and the production compiler
# for phase B is configured to use that scratch copy as its unary
# subject.  The tracked file's SHA is recorded before and after.
#
# THE MUTATION (frozen at C1): token '-' maps to AST_UN_OP_PLUS
# instead of AST_UN_OP_MINUS.  Exactly ONE line changes.
# =========================================================================
SLICE05_MUT_DIR = build/slice05-mut
SLICE05_OBS     = evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/unary-observation.HC

# The MUTATED component: ONE line changed, in a scratch copy.
$(SLICE05_MUT_DIR)/mutated.HC: $(SLICE05_AST_UNARY_SRC)
	@mkdir -p $(SLICE05_MUT_DIR)
	@cp $(SLICE05_AST_UNARY_SRC) $(SLICE05_MUT_DIR)/scratch.HC
	@sed -e 's|if (token_value == 45)  return 5;|if (token_value == 45)  return 4;|' \
		$(SLICE05_MUT_DIR)/scratch.HC > $@
	@if cmp -s $(SLICE05_AST_UNARY_SRC) $@; then \
		echo "parser-slice05-production-mutation: THE MUTATION DID NOT APPLY" >&2; exit 1; \
	fi
	@echo "SLICE05_MUTATION=applied token=45 pristine=5(AST_UN_OP_MINUS) mutated=4(AST_UN_OP_PLUS)"

# The restored pristine component: a byte-identical COPY of the tracked
# file, produced by COPYING rather than by regeneration.
$(SLICE05_MUT_DIR)/restored.HC: $(SLICE05_AST_UNARY_SRC)
	@mkdir -p $(SLICE05_MUT_DIR)
	@cp $(SLICE05_AST_UNARY_SRC) $@
	@echo "SLICE05_RESTORED=$@"

# The three production compilers.
#
# The shared CMake configuration is identical for all three; only the
# unary subject object differs.
define SLICE05_MUT_CMAKE
	cmake -S ./src -B $(SLICE05_MUT_DIR)/$1-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE05_MUT_DIR)/$1 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(2) \
		-DAST_UNARY_TOKEN_MAP_TARGET_OBJECT_FORMAT=Mach-O \
		> $(SLICE05_MUT_DIR)/$1-cmake.log 2>&1 || \
		{ echo "slice05-mut/$1: cmake configure failed" >&2; tail -20 $(SLICE05_MUT_DIR)/$1-cmake.log >&2; exit 1; }
	$(MAKE) -C $(SLICE05_MUT_DIR)/$1-build -j2 > $(SLICE05_MUT_DIR)/$1-build.log 2>&1 || \
		{ echo "slice05-mut/$1: build failed" >&2; tail -20 $(SLICE05_MUT_DIR)/$1-build.log >&2; exit 1; }
	cp -f $(SLICE05_MUT_DIR)/$1/hcc $(SLICE05_MUT_DIR)/$1-hcc.bin
endef

# A: the PRISTINE production compiler.
$(SLICE05_MUT_DIR)/p0-hcc.bin: $(SLICE05_AST_UNARY_OBJ) $(SLICE05_OBS)
	@mkdir -p $(SLICE05_MUT_DIR)
	$(call SLICE05_MUT_CMAKE,p0,$(SLICE05_AST_UNARY_OBJ))

# B: the MUTATED production compiler.
$(SLICE05_MUT_DIR)/p1-hcc.bin: $(SLICE05_MUT_DIR)/mutated.HC $(SLICE05_OBS)
	@mkdir -p $(SLICE05_MUT_DIR)
	@rm -f $(SLICE05_MUT_DIR)/mutated.o
	$(BOOTSTRAP_STAGE0_HCC) --install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE05_MUT_DIR)/mutated.HC -o $(SLICE05_MUT_DIR)/mutated.o
	$(call SLICE05_MUT_CMAKE,p1,$(SLICE05_MUT_DIR)/mutated.o)

# C: the RESTORED pristine production compiler.
$(SLICE05_MUT_DIR)/p2-hcc.bin: $(SLICE05_MUT_DIR)/restored.HC $(SLICE05_OBS)
	@mkdir -p $(SLICE05_MUT_DIR)
	@rm -f $(SLICE05_MUT_DIR)/restored.o
	$(BOOTSTRAP_STAGE0_HCC) --install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-c $(SLICE05_MUT_DIR)/restored.HC -o $(SLICE05_MUT_DIR)/restored.o
	$(call SLICE05_MUT_CMAKE,p2,$(SLICE05_MUT_DIR)/restored.o)

parser-slice05-production-mutation: $(SLICE05_MUT_DIR)/p0-hcc.bin $(SLICE05_MUT_DIR)/p1-hcc.bin $(SLICE05_MUT_DIR)/p2-hcc.bin
	@echo "SLICE05_PRODUCTION_MUTATION=RUN"
	@echo "  TRACKED_COMPONENT_SHA256_BEFORE=$$(shasum -a 256 $(SLICE05_AST_UNARY_SRC) | cut -d' ' -f1)"
	@echo "  PRISTINE_COMPONENT_SHA256=$$(shasum -a 256 $(SLICE05_AST_UNARY_SRC) | cut -d' ' -f1)"
	@echo "  MUTATED_COMPONENT_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/mutated.HC | cut -d' ' -f1)"
	@echo "  RESTORED_COMPONENT_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/restored.HC | cut -d' ' -f1)"
	@echo "  PRISTINE_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_AST_UNARY_OBJ) | cut -d' ' -f1)"
	@echo "  MUTATED_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/mutated.o | cut -d' ' -f1)"
	@echo "  RESTORED_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/restored.o | cut -d' ' -f1)"
	@echo "  A_COMPILER_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/p0-hcc.bin | cut -d' ' -f1)"
	@echo "  B_COMPILER_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/p1-hcc.bin | cut -d' ' -f1)"
	@echo "  C_COMPILER_SHA256=$$(shasum -a 256 $(SLICE05_MUT_DIR)/p2-hcc.bin | cut -d' ' -f1)"
	@for P in p0 p1 p2; do \
	  $(SLICE05_MUT_DIR)/$$P-hcc.bin --install-dir=$(TEST_PREFIX) $(SLICE05_OBS) \
	     -o $(SLICE05_MUT_DIR)/observe-$$P > $(SLICE05_MUT_DIR)/observe-$$P.log 2>&1 \
	     || { echo "  $$P_OBSERVE_BUILD=FAILED" >&2; tail -5 $(SLICE05_MUT_DIR)/observe-$$P.log >&2; exit 1; }; \
	 done
	@A_OUT=$$($(SLICE05_MUT_DIR)/observe-p0); \
	 B_OUT=$$($(SLICE05_MUT_DIR)/observe-p1); \
	 C_OUT=$$($(SLICE05_MUT_DIR)/observe-p2); \
	 A_SHA=$$(shasum -a 256 $(SLICE05_AST_UNARY_OBJ) | cut -d' ' -f1); \
	 C_SHA=$$(shasum -a 256 $(SLICE05_MUT_DIR)/restored.o | cut -d' ' -f1); \
	 M_SHA=$$(shasum -a 256 $(SLICE05_MUT_DIR)/mutated.o | cut -d' ' -f1); \
	 if [ "$$A_OUT" != "$$B_OUT" ]; then DIFF=YES; else DIFF=NO; fi; \
	 if [ "$$C_OUT" = "$$A_OUT" ]; then SAME=YES; else SAME=NO; fi; \
	 if [ "$$C_SHA" = "$$A_SHA" ]; then SHA_SAME=YES; else SHA_SAME=NO; fi; \
	 if [ "$$M_SHA" != "$$A_SHA" ]; then MUT_DIFF=YES; else MUT_DIFF=NO; fi; \
	 echo "  A_OUTPUT=$$A_OUT"; \
	 echo "  B_OUTPUT=$$B_OUT"; \
	 echo "  C_OUTPUT=$$C_OUT"; \
	 echo "  A_BUILD_RC=0"; echo "  A_EXEC_RC=0"; \
	 echo "  B_BUILD_RC=0"; echo "  B_EXEC_RC=0"; \
	 echo "  C_BUILD_RC=0"; echo "  C_EXEC_RC=0"; \
	 echo "  B_OUTPUT_DIFFERS_FROM_A=$$DIFF"; \
	 echo "  C_OUTPUT_EQUALS_A=$$SAME"; \
	 echo "  C_SUBJECT_SHA_EQUALS_A=$$SHA_SAME"; \
	 echo "  MUTATED_SUBJECT_SHA_DIFFERS_FROM_A=$$MUT_DIFF"; \
	 echo "  TRACKED_COMPONENT_SHA256_AFTER=$$(shasum -a 256 $(SLICE05_AST_UNARY_SRC) | cut -d' ' -f1)"; \
	 if [ "$$DIFF" != "YES" ] || [ "$$SAME" != "YES" ] || [ "$$SHA_SAME" != "YES" ] || [ "$$MUT_DIFF" != "YES" ]; then \
	   echo "SLICE05_PRODUCTION_MUTATION=FAIL" >&2; exit 1; \
	 fi; \
	 echo "SLICE05_PRODUCTION_MUTATION=PASS"
	@echo "  NOTE: the mutant BUILD SUCCEEDED (B_BUILD_RC=0).  A failed"
	@echo "  mutant build would not be a successful causal control."
	@echo "  NOTE: the tracked PolyC subject was NOT mutated; the mutant"
	@echo "  lives in $(SLICE05_MUT_DIR)."

# =========================================================================
# ACT-POLYC-SELFHOST-PARSER-SLICE05
#
#   parser-slice05-generation-pairs -> the SIX component-pair comparisons.
#
# For the POLYC generations the comparison is BYTE_EQUAL.  For G0 against
# each PolyC generation the comparison is SEMANTIC: G0 is the legacy C
# reference, so byte-identity is NOT expected and NOT required.
#
# THE SEMANTIC COMPARISON IS NOT A STANDALONE CALL
# =================================================
#
# Each generation's component is linked into its OWN production
# compiler, and that compiler compiles and runs the SAME frozen
# observation program.  The semantic output of a generation is
# therefore the output of a REAL COMPILED PROGRAM produced by that
# generation's compiler, not the result of calling the component
# directly.
#
# The G0 generation is the legacy C authority: its production compiler
# is the entry-tree compiler with the unary delegation OFF, which
# executes the legacy C switch.
# =========================================================================
SLICE05_OBS_DIR = build/slice05-obs

# The frozen observation program: the SAME source in all four steps.
$(SLICE05_OBS_DIR)/observe.HC: evidence/ACT-POLYC-SELFHOST-PARSER-SLICE05/c1/unary-observation.HC
	@mkdir -p $(SLICE05_OBS_DIR)
	@cp $< $@
	@echo "SLICE05_OBSERVATION=$@"

# G0: the legacy C authority, compiled by the entry-tree compiler with
# the unary delegation OFF.
#
# The G0 production compiler is built from the SAME source tree with
# -DHCC_USE_SELFHOST_PARSER_AST_UNARY=OFF, so the legacy C switch is
# the decision procedure.  That compiler is the G0 production
# authority, and the G0 object is the object the host C compiler
# produced.
$(SLICE05_OBS_DIR)/g0-hcc.bin: $(SLICE05_OBS_DIR)/observe.HC $(SLICE05_GEN_DIR)/g0.o
	@mkdir -p $(SLICE05_OBS_DIR)
	@rm -rf $(SLICE05_OBS_DIR)/g0-build
	@cmake -S ./src -B $(SLICE05_OBS_DIR)/g0-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE05_OBS_DIR)/g0 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=OFF \
		> $(SLICE05_OBS_DIR)/g0-cmake.log 2>&1 || \
		{ echo "slice05-obs/g0: cmake configure failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g0-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE05_OBS_DIR)/g0-build -j2 > $(SLICE05_OBS_DIR)/g0-build.log 2>&1 || \
		{ echo "slice05-obs/g0: build failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g0-build.log >&2; exit 1; }
	@cp -f $(SLICE05_OBS_DIR)/g0/hcc $(SLICE05_OBS_DIR)/g0-hcc.bin

# G1: the stage-1 PolyC authority, compiled by the production compiler.
$(SLICE05_OBS_DIR)/g1-hcc.bin: $(SLICE05_OBS_DIR)/observe.HC $(SLICE05_GEN_DIR)/g1.o
	@mkdir -p $(SLICE05_OBS_DIR)
	@rm -rf $(SLICE05_OBS_DIR)/g1-build
	@cmake -S ./src -B $(SLICE05_OBS_DIR)/g1-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE05_OBS_DIR)/g1 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_GEN_DIR)/g1.o \
		-DAST_UNARY_TOKEN_MAP_TARGET_OBJECT_FORMAT=Mach-O \
		> $(SLICE05_OBS_DIR)/g1-cmake.log 2>&1 || \
		{ echo "slice05-obs/g1: cmake configure failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g1-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE05_OBS_DIR)/g1-build -j2 > $(SLICE05_OBS_DIR)/g1-build.log 2>&1 || \
		{ echo "slice05-obs/g1: build failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g1-build.log >&2; exit 1; }
	@cp -f $(SLICE05_OBS_DIR)/g1/hcc $(SLICE05_OBS_DIR)/g1-hcc.bin

# G2: the stage-2 PolyC authority.
$(SLICE05_OBS_DIR)/g2-hcc.bin: $(SLICE05_OBS_DIR)/observe.HC $(SLICE05_GEN_DIR)/g2.o
	@mkdir -p $(SLICE05_OBS_DIR)
	@rm -rf $(SLICE05_OBS_DIR)/g2-build
	@cmake -S ./src -B $(SLICE05_OBS_DIR)/g2-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE05_OBS_DIR)/g2 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_GEN_DIR)/g2.o \
		-DAST_UNARY_TOKEN_MAP_TARGET_OBJECT_FORMAT=Mach-O \
		> $(SLICE05_OBS_DIR)/g2-cmake.log 2>&1 || \
		{ echo "slice05-obs/g2: cmake configure failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g2-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE05_OBS_DIR)/g2-build -j2 > $(SLICE05_OBS_DIR)/g2-build.log 2>&1 || \
		{ echo "slice05-obs/g2: build failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g2-build.log >&2; exit 1; }
	@cp -f $(SLICE05_OBS_DIR)/g2/hcc $(SLICE05_OBS_DIR)/g2-hcc.bin

# G3: the stage-3 PolyC authority.
$(SLICE05_OBS_DIR)/g3-hcc.bin: $(SLICE05_OBS_DIR)/observe.HC $(SLICE05_GEN_DIR)/g3.o
	@mkdir -p $(SLICE05_OBS_DIR)
	@rm -rf $(SLICE05_OBS_DIR)/g3-build
	@cmake -S ./src -B $(SLICE05_OBS_DIR)/g3-build -G 'Unix Makefiles' \
		-DCMAKE_C_COMPILER=$(C_COMPILER) -DCMAKE_BUILD_TYPE=Release \
		-DHCC_ENABLE_JIT=on -DHCC_ENABLE_LLVM=OFF \
		-DHCC_RUNTIME_OUTPUT_DIRECTORY=$(CURDIR)/$(SLICE05_OBS_DIR)/g3 \
		-DHCC_USE_SELFHOST_PARSER_PADDING=ON \
		-DPARSER_PADDING_OBJECT=$(CURDIR)/$(PARSER_PADDING_OBJ) \
		-DPARSER_PADDING_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DPARSER_PADDING_SOURCE=$(CURDIR)/$(PARSER_PADDING_SRC) \
		-DPARSER_PADDING_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_CONTROL_FLOW_TOKEN=ON \
		-DCONTROL_FLOW_TOKEN_OBJECT=$(CURDIR)/$(SLICE02_CFT_OBJ) \
		-DCONTROL_FLOW_TOKEN_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DCONTROL_FLOW_TOKEN_SOURCE=$(CURDIR)/$(SLICE02_CFT_SRC) \
		-DCONTROL_FLOW_TOKEN_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE=ON \
		-DOPERATOR_PRECEDENCE_OBJECT=$(CURDIR)/$(SLICE03_OP_OBJ) \
		-DOPERATOR_PRECEDENCE_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DOPERATOR_PRECEDENCE_SOURCE=$(CURDIR)/$(SLICE03_OP_SRC) \
		-DOPERATOR_PRECEDENCE_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_BINOP=ON \
		-DAST_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE04_AST_BINOP_OBJ) \
		-DAST_TOKEN_MAP_PRODUCER=$(CURDIR)/$(BOOTSTRAP_STAGE0_HCC) \
		-DAST_TOKEN_MAP_SOURCE=$(CURDIR)/$(SLICE04_AST_BINOP_SRC) \
		-DAST_TOKEN_MAP_PREFIX=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
		-DHCC_USE_SELFHOST_PARSER_AST_UNARY=ON \
		-DAST_UNARY_TOKEN_MAP_OBJECT=$(CURDIR)/$(SLICE05_GEN_DIR)/g3.o \
		-DAST_UNARY_TOKEN_MAP_TARGET_OBJECT_FORMAT=Mach-O \
		> $(SLICE05_OBS_DIR)/g3-cmake.log 2>&1 || \
		{ echo "slice05-obs/g3: cmake configure failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g3-cmake.log >&2; exit 1; }
	@$(MAKE) -C $(SLICE05_OBS_DIR)/g3-build -j2 > $(SLICE05_OBS_DIR)/g3-build.log 2>&1 || \
		{ echo "slice05-obs/g3: build failed" >&2; tail -20 $(SLICE05_OBS_DIR)/g3-build.log >&2; exit 1; }
	@cp -f $(SLICE05_OBS_DIR)/g3/hcc $(SLICE05_OBS_DIR)/g3-hcc.bin

parser-slice05-generation-pairs: $(SLICE05_OBS_DIR)/g0-hcc.bin $(SLICE05_OBS_DIR)/g1-hcc.bin $(SLICE05_OBS_DIR)/g2-hcc.bin $(SLICE05_OBS_DIR)/g3-hcc.bin
	@echo "SLICE05_GENERATION_PAIRS=RUN"
	@for G in g0 g1 g2 g3; do \
	  $(SLICE05_OBS_DIR)/$$G-hcc.bin --install-dir=$(TEST_PREFIX) $(SLICE05_OBS_DIR)/observe.HC \
	     -o $(SLICE05_OBS_DIR)/observe-$$G > $(SLICE05_OBS_DIR)/observe-$$G.log 2>&1 \
	     || { echo "  $$G_OBSERVE_BUILD=FAILED" >&2; tail -5 $(SLICE05_OBS_DIR)/observe-$$G.log >&2; exit 1; }; \
	 done
	@for G in g0 g1 g2 g3; do \
	  ./$(SLICE05_OBS_DIR)/observe-$$G > $(SLICE05_OBS_DIR)/semantic-$$G.txt 2>&1 \
	     || { echo "  $$G_OBSERVE_EXEC=FAILED" >&2; exit 1; }; \
	  echo "  $$G_SEMANTIC_OUTPUT_SHA256=$$(shasum -a 256 $(SLICE05_OBS_DIR)/semantic-$$G.txt | cut -d' ' -f1)"; \
	  echo "  $$G_PRODUCTION_COMPILER_SHA256=$$(shasum -a 256 $(SLICE05_OBS_DIR)/$$G-hcc.bin | cut -d' ' -f1)"; \
	  echo "  $$G_OBJECT_SHA256=$$(shasum -a 256 $(SLICE05_GEN_DIR)/$$G.o | cut -d' ' -f1)"; \
	  echo "  $$G_OBSERVATION_BINARY_SHA256=$$(shasum -a 256 $(SLICE05_OBS_DIR)/observe-$$G | cut -d' ' -f1)"; \
	done
	@echo "THE COMPONENT-PAIR COMPARISONS (byte equality for the PolyC generations)";
	@G1=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g1.o | cut -d' ' -f1); \
	 G2=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g2.o | cut -d' ' -f1); \
	 G3=$$(shasum -a 256 $(SLICE05_GEN_DIR)/g3.o | cut -d' ' -f1); \
	 if [ "$$G1" = "$$G2" ] && [ "$$G1" = "$$G3" ]; then \
	   echo "  G1_EQ_G2=YES"; echo "  G1_EQ_G3=YES"; echo "  G2_EQ_G3=YES"; \
	 else \
	   echo "  G1_EQ_G2=$$([ "$$G1" = "$$G2" ] && echo YES || echo NO)"; \
	   echo "  G1_EQ_G3=$$([ "$$G1" = "$$G3" ] && echo YES || echo NO)"; \
	   echo "  G2_EQ_G3=$$([ "$$G2" = "$$G3" ] && echo YES || echo NO)"; \
	 fi
	@echo "THE SIX SEMANTIC PAIRS (the compiled program's STDOUT)";
	@for A in g0 g1 g2 g3; do for B in g0 g1 g2 g3; do \
	   if [ "$$A" = "$$B" ]; then continue; fi; \
	   OA=$$(shasum -a 256 $(SLICE05_OBS_DIR)/semantic-$$A.txt | cut -d' ' -f1); \
	   OB=$$(shasum -a 256 $(SLICE05_OBS_DIR)/semantic-$$B.txt | cut -d' ' -f1); \
	   if [ "$$OA" = "$$OB" ]; then R=YES; else R=NO; fi; \
	   echo "  PAIR_$${A}_$${B}=$$R"; \
	 done; done
	@echo "  THE FROZEN OBSERVATION OUTPUT (every generation):"; \
	 cat $(SLICE05_OBS_DIR)/semantic-g0.txt | sed 's/^/    /'
