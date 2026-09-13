ACT-POLYC-SELFHOST-SURFACE01 — C3 — EVIDENCE packet
====================================================

This directory contains the **C3 EVIDENCE packet**.

C3 reconstructs the entire self-host component surface
from a fresh tree, then proves equivalence to the
predecessor's frozen historical surface.

Two reconstructions are run:

  1. Generic-only reconstruction: delete only the
     generic outputs (build/selfhost/**), regenerate
     them through tools/selfhost/selfhost-component.sh,
     and verify byte-equivalence to the predecessor's
     S0/S1/S2 historical artifacts.

  2. Historical reconstruction: rebuild B1/B2/B3 via
     the historical bootstrap0*-stageN targets, prove
     that the historical surfaces still pass, and
     prove that the historical artifacts are byte-equal
     to the generic ones.

C3 also runs the B3 broad-corpus differential (181
sources) and the B3 error corpus (4 fixtures) on the
current tree to confirm B3 conservation.

Files in this packet:

  README.md                          (this file)
  fresh-tree.txt
  registry-validation.txt
  negative-controls.txt
  generic-reconstruction.txt
  generic-provenance.tsv
  historical-reconstruction.txt
  historical-vs-generic.tsv
  identifier-oracle.txt
  cursor-oracle.txt
  lexer-seam.txt
  b3-corpus-matrix.tsv
  b3-corpus-summary.txt
  b3-error-corpus.tsv
  b3-error-summary.txt
  compiler-conservation.txt
  factory-gates.txt
  scope-audit.txt
  patch-hygiene.txt
  c3-required-result.txt
