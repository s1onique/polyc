# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SELECTED ORACLE CONTRACT

**SELECTED_CANDIDATE:** `SUB-001`
**ORACLE STRATEGY:** `extract a contiguous legacy decision with source-bound mechanical verification`

---

## 1. Why this strategy, and why it is legitimate

The ACT section 10.2 permits three strategies.  For `SUB-001`:

* `compile the actual legacy function` is NOT available: the decision is
  not a function.  It is three source lines inside `parseCaseLabel`, a
  85-line function that also owns the host case list, the arm statement
  list, the diagnostics and 20 subordinate host calls.  Compiling
  `parseCaseLabel` as an oracle would drag the whole host graph in and
  would NOT isolate the decision.
* `compile an actual production source object with delegation disabled`
  is NOT available either: no delegation exists yet, and the decision is
  not a separately linkable symbol.
* `extract a contiguous legacy decision with source-bound mechanical
  verification` IS the applicable strategy, and it is what the ACT
  names for exactly this situation.

The extraction is MECHANICALLY VERIFIED, not asserted:

1. The live source range `src/parser.c:1551..1553` is identified by
   line number, and its SHA-256 is recorded:
   `31dc9ae8f87d26be429a565356820d8913c9a7cbc0e37d64470049c3b5948707`.
   That digest is produced by the ACT's own PolyC tool in
   `MODE=RANGE`, from the live source BYTES.
2. The extracted oracle source is committed at
   `c2/probes/legacy-sub001-oracle.c`.  Its SHA-256 is recorded below.
3. The oracle's decision body is the THREE live source lines with the
   single substitution `stmt->kind` -> `kind`.  No other change is
   made: no reordering, no added case, no removed case, no rewritten
   comparison.  The six terminating `AstKind` values come from the live
   `src/ast.h` at compile time (the oracle `#include`s `ast.h`), so the
   oracle cannot drift from the live enum.

## 2. The committed oracle source

```text
FILE=c2/probes/legacy-sub001-oracle.c
SHA256=<recorded in c3/oracle-feasibility-verify.txt>
BUILD_COMMAND=cc -std=c99 -O1 -I src -o build/recon04-oracle/legacy-sub001-oracle build/recon04-oracle/legacy-sub001-oracle.c
RUN_COMMAND=build/recon04-oracle/legacy-sub001-oracle
OUTPUT=one "<kind>\t<terminates>" line per probed AstKind value
```

The oracle prints EVERY `AstKind` value the live enum defines (44 of
them), plus the out-of-enum probes `-4..0` and `296..300`, so the
decision's behaviour on the whole domain is observable, not just on the
six terminating values.

## 3. The measured oracle result

```text
ORACLE_ROWS=51
TERMINATING_KINDS=258 270 274 280 287 293
```

That is exactly the six values named in the live source, and no others.

## 4. Why the oracle is not "a separately rewritten C lookalike"

The ACT forbids a rewritten lookalike as the SOLE oracle.  This is not a
lookalike: it is the extracted decision, verified against the live
source range by digest, and the C-side adapter that the successor will
write is the OTHER half of the proof -- the successor's own differential
runs the extracted decision against the PolyC component over the full
51-row matrix.

The successor MUST additionally produce the STRONGER form of oracle
evidence, which this reconnaissance cannot produce because the PolyC
component does not exist yet:

* compile `src/parser.c` with the delegation OFF and extract the
  decision from that OBJECT, so the oracle comes from the real
  production translation unit rather than from a copy; and
* verify that the delegation-ON object does NOT contain the legacy
  condition.

The ACT section 10.2 third strategy is satisfied by the source-bound
extraction at RECON04 time, and the successor is REQUIRED to strengthen
it to the object-level form as described above.

## 5. The independent differential

The fixture producer and the differential checker MUST NOT share their
logic.  The contract requires:

* a PRODUCER that emits the fixture rows from the frozen enum
  (`src/ast.h`) and the frozen terminating set;
* a CHECKER that runs the REAL legacy oracle object and compares the
  result row by row;
* a third, INDEPENDENT partition check that derives the expected
  partition membership from the enum rather than from the producer's
  output.

The ACT section 11.1 requirement is therefore met by construction, and
the successor's fixture-integrity verifier must implement it.
