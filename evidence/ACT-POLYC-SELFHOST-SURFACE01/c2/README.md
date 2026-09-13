ACT-POLYC-SELFHOST-SURFACE01 — C2 — IMPL evidence packet
=========================================================

This directory contains the **C2 IMPL evidence packet**.

C2 implements the generic self-host component registry
and build/provenance/test surface per ACT §7-§15, while
preserving the existing compiler source-semantic selector
(`HCC_BOOTSTRAP02_STAGE1` in `src/lexer.c::lexIdentifier`)
exactly as the predecessor closed it.

Files in this packet:

  README.md                           (this file)
  implementation-delta.txt
  registry.txt
  registry-validation.txt
  registry-negative-controls.txt
  stage0-build.txt
  stage1-build.txt
  stage2-build.txt
  generic-provenance.tsv
  symbol-validation.txt
  component-test.txt
  cursor-test.txt
  lexer-seam-test.txt
  historical-targets.txt
  historical-vs-generic.tsv
  scope-audit.txt
  factory-gates.txt
  c2-required-result.txt
