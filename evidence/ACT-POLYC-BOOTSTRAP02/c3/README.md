# ACT-POLYC-BOOTSTRAP02 — C3 EVIDENCE

## Title
B1 partial-self-host evidence — fresh stage1
reconstruction, exhaustive eligible-source
stage0/stage1 differential, production lexer
equivalence, self-source compilation, delegation
binding, reproducibility, and conservation.

## Phase
C3 EVIDENCE (parent ACT phase; not a separate ACT).

## Parent state
C1 RED complete; C1 correction closed; C2 IMPL complete;
C2-CORRECTION01/02/03 closed.

## C3 entry HEAD
`6144361e52ed6aa3e400c3fd1145516a668446a7` (parent of
the C3 EVIDENCE commit; the C3 commit is the next
commit on `main`).

## Files

| File                          | Purpose                          |
|-------------------------------|----------------------------------|
| fresh-tree.txt                | Clean-tree protocol (§3)         |
| stage-provenance.txt          | Role + symbol provenance (§4)    |
| symbol-binding.txt            | Static delegation binding (§4)   |
| delegation-witness.txt        | Runtime delegation proof (§5)    |
| corpus-inventory.txt          | 181 .HC sources (§6)             |
| corpus-matrix.tsv             | Per-source result matrix (§7,§8) |
| corpus-matrix-buildA.tsv      | Build-A reproducibility (§19)    |
| corpus-matrix-buildB.tsv      | Build-B reproducibility (§19)    |
| corpus-summary.txt            | Summary counts (§7,§8,§9)        |
| dollar-identifier-slice.txt   | $-identifier binding slice (§10) |
| error-corpus/                 | 4 error fixtures (§15)           |
| error-corpus.tsv              | Error corpus result (§15)        |
| error-corpus-summary.txt      | Error corpus summary (§15)       |
| component-differential.txt    | 15/15 component diff (§11)       |
| component-cursor.txt          | 6/6 component cursor (§12)       |
| production-lexer-seam.txt     | 6/6 production Lexer seam (§13)  |
| token-stream.txt              | Token-stream seam (§14; absent)  |
| stage1-normal-source.txt      | Stage1 compiles ordinary (§16)   |
| stage1-self-source.txt        | Stage1 compiles B1 source (§17)  |
| reproducibility.txt           | Two-clean-builds (§19)           |
| rebuild-A/, rebuild-B/        | Build-A/B reproducibility (§19) |
| compiler-conservation.txt     | Compiler gates (§20)             |
| factory-gates.txt             | Factory gates (§22)              |
| patch-hygiene.txt             | git diff --check (§23)           |
| scope-audit.txt               | Scope discipline (§24,§25,§18)   |
| c3-required-result.txt        | Binding required result (§30)    |

## Bind
`c3-required-result.txt` is the binding summary.
The other files are the supporting evidence.
