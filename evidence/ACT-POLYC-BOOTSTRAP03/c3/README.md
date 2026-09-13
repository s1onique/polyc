ACT-POLYC-BOOTSTRAP03 — C3 — EVIDENCE packet README
==================================================

C3 is the B2 PROOF. It establishes:

```text
- provenance
- binding
- self-host loop closure
- broad equivalence stage1 ↔ stage2
- error equivalence stage1 ↔ stage2
- self-source equivalence (stage2 compiles B1)
- reproducibility (Build A == Build B)
- B0/B1/Factory conservation
```

## Files

```text
fresh-tree.txt                         Entry identity at C3
stage-provenance.txt                   Stage0/Stage1/Stage2 identity
artifact-provenance.txt                Strong provenance witness
stage2-symbol-binding.txt              nm + otool binding evidence
stage2-delegation-witness.txt          Disassembly delegation
component-stage0-stage1-stage2.txt     3-stage B1 object comparison
production-lexer-stage1-stage2.txt     Production lexer seam (stage1 vs stage2)

corpus-inventory.txt                   Regenerated inventory (181 sources)
corpus-matrix-buildA.tsv               Build A
corpus-matrix-buildB.tsv               Build B
corpus-matrix-stage1-stage2.tsv        Canonical = Build A
corpus-summary.txt                     Per-class counts + divergence
dollar-identifier-slice.txt            Binding slice: $-identifiers

error-corpus.tsv                       4-fixture stage1↔stage2 differential
error-corpus-summary.txt               Aggregate

stage2-normal-source.txt               B2 normal-source slice
stage2-self-source.txt                 Stage2 compiles B1 (self-source)

reproducibility.txt                    Build A == Build B
compiler-conservation.txt              B0/B1/Factory conservation
factory-gates.txt                      Factory gate run
patch-hygiene.txt                      git diff --check
scope-audit.txt                        B1 semantic / scope audit
c3-required-result.txt                 Required result block
```

## Required-result binding summary

```text
FIRST_SELF_HOST                       = PASS
STAGE1_STAGE2_CORPUS_EQ               = PASS
STAGE2_USES_B1_COMPONENT              = PASS
STAGE2_COMPILES_B1_SOURCE             = PASS
REPRODUCIBILITY                       = PASS
B0_CONSERVATION                       = PASS  15/15
B1_CONSERVATION                       = PASS
```

No binary evidence committed. No prior-evidence mutation.
