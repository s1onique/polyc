ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01 — C1 evidence packet
============================================================

Class:    BOOTSTRAP / GOVERNANCE / CONTRACT-CORRECTION
Factory:  v2
Phase:    C1 RED (this correction ACT's own evidence)
Branch:   main
HEAD at correction entry: db038e9553133b5dc1c1d639e41f3c6306888f70
Predecessor (closed C1):
  aa29e16 ACT-POLYC-BOOTSTRAP02 — C1 RED packet
  db038e9 ACT-POLYC-BOOTSTRAP02 — C1 hygiene: trim trailing blank line

Mission
-------

Repair three C1 defects in the predecessor ACT's
governance without touching the discovered production
contract or B0 semantics, and bound the `ctype`
non-ASCII equivalence claim:

  P0 — `IDENTIFIER_GRAMMAR_EQUIVALENT = YES` is replaced
       by `IDENTIFIER_GRAMMAR_GATE = PASS`. The corrected
       gate requires `production frozen ∧ B0 preserved
       ∧ B0 vs production difference documented ∧ B1 ==
       production`, none of which is false here.

  P1 — `identifier-contract.txt` is updated to declare
       `B1_IDENTIFIER_CHARACTER_DOMAIN = ASCII` and to
       not claim non-ASCII `ctype` equivalence.

  P2 — `legacy-ident-oracle.tsv` reframes the oracle as a
       `REFERENCE_MODEL` rather than a "verbatim C99
       transcription".

The substantive B1 technical direction is preserved:
B1 component (`bootstrap02-ident.HC`) implements
production grammar (NOT B0 grammar), is a deliberately
separate file, and B0 remains bit-identical.

Files (this correction ACT)
---------------------------

  README.md                          this file
  defect-classification.txt          P0/P1/P2 enumeration
  corrected-grammar-gate.txt         the new C1 → C2 gate
  corrected-ctype-claim.txt          ASCII-domain binding
  corrected-oracle-role.txt          oracle evidentiary role
  required-result.txt                binding result block

Files modified in predecessor C1
--------------------------------

  evidence/ACT-POLYC-BOOTSTRAP02/c1/README.md
  evidence/ACT-POLYC-BOOTSTRAP02/c1/identifier-contract.txt
  evidence/ACT-POLYC-BOOTSTRAP02/c1/legacy-ident-oracle.tsv
  evidence/ACT-POLYC-BOOTSTRAP02/c1/c1-required-result.txt

Cross-references
----------------

  Predecessor ACT:         docs/acts/ACT-POLYC-BOOTSTRAP02.md
  This correction ACT:     docs/acts/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01.md
  Predecessor C1 evidence: evidence/ACT-POLYC-BOOTSTRAP02/c1/
  B0 closure:              docs/acts/ACT-POLYC-BOOTSTRAP01.md
                           docs/acts/ACT-POLYC-BOOTSTRAP01-CORRECTION01.md
  Production lexer:        src/lexer.c (lexIdentifier @ line 873)

What this correction ACT does NOT do
------------------------------------

- does NOT modify src/lexer.c, src/lexer.h, src/CMakeLists.txt
- does NOT introduce any new PolyC component yet (C2's job)
- does NOT introduce any stage1 build target yet (C2's job)
- does NOT touch parser/AST/IR/backend/runtime
- does NOT push to origin/main
- does NOT change B0 grammar or B0 ABI
