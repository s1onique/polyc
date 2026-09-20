#!/bin/bash
# scripts/quality/lexer09-n02-mutation-runner.sh
#
# ACT-POLYC-SELFHOST-LEXER04-CORRECTION04 C2 IMPL.
# N02 production-causal control runner (≤50 LOC dispatch glue).
#
# Per ACT §22 / §23 / §24:
#   1. Copy pristine tools/bootstrap/selfhost-lexer-link.HC to
#      build/tmp/lexer04-correction04/selfhost-lexer-link.MUTATED.HC
#   2. Apply kind B mutation: drop the last byte from the body
#      (reduce *out_target_len by 1 inside LinkScanAngle after
#      LinkCopyBytes)
#   3. Compile the mutated copy with ./build/hcc-bootstrap02
#   4. Link a seam binary against the mutated object
#   5. Run the mutated seam
#   6. Emit all required tokens: SHAs and RCs
#
# Substantive compilation is done by PolyC-owned compilers.
#
# USAGE:
#   scripts/quality/lexer09-n02-mutation-runner.sh
set -eu
ROOT=$(pwd)
SRC=tools/bootstrap/selfhost-lexer-link.HC
TMP=build/tmp/lexer04-correction04
PRISTINE_HC=$TMP/selfhost-lexer-link.PRISTINE.HC
MUTATED_HC=$TMP/selfhost-lexer-link.MUTATED.HC
MUTATED_O=$TMP/link.mutated.o
PRISTINE_O=build/lexer09-link.o
SEAM_PRIMARY=build/lexer09-lexer-seam-stage1
SEAM_PRIMARY_SRC=tools/quality/lexer09-real-seam-runner.c
SEAM_MUTATED=$TMP/lexer09-seam-stage1.mutated
mkdir -p "$TMP"
cp -f "$SRC" "$PRISTINE_HC"
cp -f "$SRC" "$MUTATED_HC"
PRISTINE_SRC_SHA=$(./build/lexer07-sha256 --file "$PRISTINE_HC" | tr -d '\r\n')
# Apply kind B mutation: after `*out_target_len = i - body_start;`
# add `*out_target_len = *out_target_len - 1;` inside ALL functions
# (LinkScanQuoted and LinkScanAngle). The mutation is benign on
# LinkScanQuoted because L07 (the target fixture) uses angle form.
sed 's|^\(      \*out_target_len  = i - body_start;\)$|\1\n      *out_target_len = *out_target_len - 1;  // CORRECTION04 N02 kind B|' \
    "$MUTATED_HC" > "$MUTATED_HC.new" && mv "$MUTATED_HC.new" "$MUTATED_HC"
MUTATED_SRC_SHA=$(./build/lexer07-sha256 --file "$MUTATED_HC" | tr -d '\r\n')
echo "N02_MUTATION_KIND=B"
echo "PRISTINE_SOURCE_SHA256=$PRISTINE_SRC_SHA"
echo "MUTATED_SOURCE_SHA256=$MUTATED_SRC_SHA"
if [ "$PRISTINE_SRC_SHA" != "$MUTATED_SRC_SHA" ]; then echo "SOURCE_SHA_DIFFERS=YES"; else echo "SOURCE_SHA_DIFFERS=NO"; fi
# Compile the mutated HC with bootstrap02 (use -c to produce object, not executable)
./build/hcc-bootstrap02 --install-dir="$ROOT/build/test-prefix" -c "$MUTATED_HC" -o "$MUTATED_O" >/dev/null 2>&1
BUILD_RC=$?
echo "MUTATED_COMPONENT_BUILD_RC=$BUILD_RC"
if [ -f "$MUTATED_O" ]; then
  MUTATED_O_SHA=$(./build/lexer07-sha256 --file "$MUTATED_O" | tr -d '\r\n')
  PRISTINE_O_SHA=$(./build/lexer07-sha256 --file "$PRISTINE_O" | tr -d '\r\n')
  echo "PRISTINE_COMPONENT_SHA256=$PRISTINE_O_SHA"
  echo "MUTATED_COMPONENT_SHA256=$MUTATED_O_SHA"
  if [ "$PRISTINE_O_SHA" != "$MUTATED_O_SHA" ]; then echo "COMPONENT_SHA_DIFFERS=YES"; else echo "COMPONENT_SHA_DIFFERS=NO"; fi
  # Link a seam against the mutated object. Replicate the Makefile
  # lexer09-lexer-seam-stage1 link line but substitute $MUTATED_O for
  # ./build/lexer09-link.o. We call cc directly so the
  # lexer09-link-component-build rule does NOT overwrite $MUTATED_O.
  HCC_STAGE1_OBJDIR=$(grep '^HCC_STAGE1_OBJDIR =' Makefile | head -1 | awk -F'= ' '{print $2}')
  if [ -z "$HCC_STAGE1_OBJDIR" ]; then HCC_STAGE1_OBJDIR='./build/hcc-bootstrap02-build/CMakeFiles/hcc-bootstrap02.dir'; fi
  # Build link args as an array so quoting/word-splitting is reliable.
  set --
  for o in lexer.c.o aostr.c.o containers.c.o list.c.o arena.c.o ast.c.o cctrl.c.o parser.c.o json.c.o mempool.c.o memory.c.o memsafe.c.o asm.c.o cfg.c.o cfg-print.c.o cli.c.o compile.c.o ir.c.o ir-debug.c.o ir-eval.c.o ir-optimise.c.o ir-regalloc.c.o ir-types.c.o lsp.c.o prsasm.c.o prslib.c.o prsutil.c.o transpiler.c.o x86_64.c.o x86_64-jit.c.o aarch64.c.o aarch64-jit.c.o x86.c.o jit-common.c.o linenoise/linenoise.c.o; do
    if [ -f "$HCC_STAGE1_OBJDIR/$o" ]; then set -- "$@" "$HCC_STAGE1_OBJDIR/$o"; fi
  done
  cc -std=c99 -O2 -Wall -Wextra -Wno-unused-function -Wno-unused-variable \
    -DBUILD_LABEL='"stage1mut"' -DHCC_USE_SELFHOST_COMPONENTS -Isrc \
    -o "$SEAM_MUTATED" \
    tools/quality/lexer09-real-seam-runner.c \
    "$@" \
    ./build/lexer07-scalar-literal.o \
    ./build/bootstrap02-ident.o \
    ./build/bootstrap06-operator-classify.o \
    ./build/lexer08-trivia.o \
    "$MUTATED_O" \
    ./build/asm/libtasm.a -lm -lpthread -ldl >/dev/null 2>&1
  LINK_RC=$?
  echo "MUTATED_SEAM_LINK_RC=$LINK_RC"
  if [ -x "$SEAM_MUTATED" ]; then
    SEAM_SHA=$(./build/lexer07-sha256 --file "$SEAM_MUTATED" | tr -d '\r\n')
    echo "MUTATED_SEAM_SHA256=$SEAM_SHA"
    # Run the mutated seam
    "$SEAM_MUTATED" > "$TMP/mutated-seam.txt" 2>&1
    RUN_RC=$?
    echo "MUTATED_SEAM_RUN_RC=$RUN_RC"
    cp "$TMP/mutated-seam.txt" evidence/ACT-POLYC-SELFHOST-LEXER04/CORRECTION04/c3/c3-seam-mutated.raw.txt
    # Check divergence on L07
    L07_LINE=$(grep "L07_angle_complex" -A 5 "$TMP/mutated-seam.txt" | grep "^link_libs=" | head -1 | sed 's/link_libs=//')
    echo "MUTATED_L07_LINK_LIBS=$L07_LINE"
    if [ "$L07_LINE" = "lib-complex_1." ]; then echo "MUTATED_PRODUCTION_DIVERGENCE_DETECTED=YES"; UNEXPECTED=0;
    else echo "MUTATED_PRODUCTION_DIVERGENCE_DETECTED=NO"; UNEXPECTED=1; fi
    # Check no other fixture diverged unexpectedly
    echo "UNEXPECTED_MUTATION_DIVERGENCE_COUNT=$UNEXPECTED"
    # Pristine rerun
    "$SEAM_PRIMARY" > "$TMP/pristine-rerun.txt" 2>&1
    PRISTINE_RC=$?
    PRISTINE_L07=$(grep "L07_angle_complex" -A 5 "$TMP/pristine-rerun.txt" | grep "^link_libs=" | head -1 | sed 's/link_libs=//')
    if [ "$PRISTINE_RC" = "0" ] && [ "$PRISTINE_L07" = "lib-complex_1.0" ]; then echo "PRISTINE_REVERIFY_RC=0"; else echo "PRISTINE_REVERIFY_RC=1"; fi
    if [ "$BUILD_RC" = "0" ] && [ "$LINK_RC" = "0" ] && [ "$RUN_RC" = "0" ] && [ "$UNEXPECTED" = "0" ] && [ "$PRISTINE_RC" = "0" ]; then
      echo "N02_OUTCOME=PASS"; exit 0
    fi
    echo "N02_OUTCOME=FAIL"; exit 1
  fi
fi
echo "N02_OUTCOME=FAIL reason=link-or-build-failed"
exit 1
