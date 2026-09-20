#!/bin/bash
# scripts/quality/lexer09-n02-mutation-runner.sh
#
# ACT-POLYC-SELFHOST-LEXER04-CORRECTION05 dispatch shell.
# Per ACT §22 / §23: this file is ≤20 LOC dispatch-only. The
# substantive work (mutation, compile, link, run, SHA capture) is
# done by the PolyC tool tools/quality/lexer09-n02-mutation-runner.HC.
#
# Uses RELATIVE paths because ./build/hcc-bootstrap02 prepends "./"
# to compiler-supplied output paths, breaking absolute paths.
set -eu
SRC=tools/bootstrap/selfhost-lexer-link.HC
TMP=build/tmp/lexer04-correction05
mkdir -p "$TMP"
exec stdbuf -oL ./build/lexer09-n02-mutation-runner \
  "$SRC" \
  "$TMP/n02-evid.txt" \
  ./build/lexer09-lexer-seam-stage1 \
  tools/quality/lexer09-real-seam-runner.c \
  ./build/hcc-bootstrap02-build/CMakeFiles/hcc-bootstrap02.dir \
  "$TMP/lexer09-seam-stage1.mutated" \
  "$TMP/link.mutated.o" \
  ./build/hcc-bootstrap02 \
  ./build/test-prefix \
  "$TMP/selfhost-lexer-link.MUTATED.HC" \
  "$TMP/selfhost-lexer-link.PRISTINE.HC" \
  "$TMP/pristine-rerun.txt"
