# ACT-POLYC-BOOTSTRAP01 — C3 EVIDENCE Packet

This directory holds the C3 EVIDENCE pack for
`ACT-POLYC-BOOTSTRAP01` (B0 compiler-shaped bootstrap).

C3 is the fresh-tree evidence protocol (ACT §26) plus
the differential, determinism, source-immutability,
output-boundary, conservation, and factory gates required
by ACT §17..§24.

## Files

| File                              | Purpose                                              |
| --------------------------------- | ---------------------------------------------------- |
| `fresh-build.txt`                 | `make bootstrap01-test` from a clean tree.           |
| `differential-results.txt`        | Full B0 driver run for the frozen fixture matrix.    |
| `deterministic-rerun.txt`         | Per-fixture run-1 vs run-2 evidence.                 |
| `source-immutability.txt`         | Per-fixture source byte-equality proof.              |
| `output-boundary.txt`             | T12/NC7 and NC8 capacity-overflow evidence.          |
| `conservation-gates.txt`          | Predecessor conservation gates + factory gates.      |
| `factory-gates.txt`               | factory-v2 / append-only / closure-status / halt    |
|                                   | classification / shell-loc-gate results.             |
| `gate-push-status.txt`            | gate-push state, classified per ACT §23.             |
| `c3-required-result.txt`          | Required-result block for C3 closure.                |

## Fresh-build protocol

Per ACT §26:

```bash
$ rm -f ./build/bootstrap01-lexer-oracle ./build/bootstrap01-lexer-test
$ rm -f /tmp/b0_lexer /tmp/b0_test /tmp/b0_lexer.ll /tmp/b0_test.ll
$ make test-prefix-install
$ make bootstrap01-test
```

The fresh-build evidence is in `fresh-build.txt` and
ends with `BOOTSTRAP01_CASES=15 BOOTSTRAP01_PASS=15
BOOTSTRAP01_FAIL=0 STATUS=PASS BOOTSTRAP01_REFERENCE_ORACLE=./build/bootstrap01-lexer-oracle`.

## Differential evidence

`differential-results.txt` is the full output of the
PolyC driver against the frozen fixture matrix. Each
`CASE <ID>` line shows:

```text
CASE <ID> sub=<STATUS> count=<N> run2_eq=<yes|no> src_eq=<yes|no> exp_eq=<yes|no>
```

`run2_eq=yes` means run 1 and run 2 produced identical
(kind, start, len, status) tuples.
`src_eq=yes` means the source buffer is byte-identical
before and after the lex run.
`exp_eq=yes` means the run matched the frozen expected
tokens in `oracle-baseline.txt`.

Every fixture line ends with `RESULT=PASS` implicitly
because the BOOTSTRAP01_PASS count equals
BOOTSTRAP01_CASES.

## Reference (REF) vs Subject (SUB) stream equivalence

ACT §17 requires `REFERENCE_STATUS == SUBJECT_STATUS`
and per-token `kind/start/len` equality for every
applicable case. The PolyC subject's SUB output uses
numeric kinds (matching the frozen ABI in
`evidence/ACT-POLYC-BOOTSTRAP01/c1/lexical-contract.txt`).
The C reference oracle's SUB output uses the same
numeric kinds plus kind-name annotations. The two are
equivalent because the numeric kind is the canonical
B0 ABI.

Sample T08 trace:

```text
$ ./build/bootstrap01-lexer-oracle T08 7b613d313b7d X X OK \
      5:0:1 1:1:1 15:2:1 2:3:1 10:4:1 6:5:1 0:6:0
REF T08
  T08  0 LBRACE 0 1
  T08  1 IDENT 1 1
  T08  2 ASSIGN 2 1
  T08  3 INT 3 1
  T08  4 SEMI 4 1
  T08  5 RBRACE 5 1
  T08  6 EOF 6 0
  T08  STATUS=OK
SUB T08
  T08  0 LBRACE 0 1
  T08  1 IDENT 1 1
  T08  2 ASSIGN 2 1
  T08  3 INT 3 1
  T08  4 SEMI 4 1
  T08  5 RBRACE 5 1
  T08  6 EOF 6 0
  T08  STATUS=OK
CASE T08  RESULT=PASS
```

The same T08 SUB output from the PolyC subject
(`/Volumes/.../b0_test evidence/.../bootstrap01-fixtures.tsv`):

```text
T08 0 5 0 1
T08 1 1 1 1
T08 2 15 2 1
T08 3 2 3 1
T08 4 10 4 1
T08 5 6 5 1
T08 6 0 6 0
T08 STATUS=OK
```

The kind numbers (5, 1, 15, 2, 10, 6, 0), start offsets
(0..6), and lengths (1, 1, 1, 1, 1, 1, 0) match exactly.
