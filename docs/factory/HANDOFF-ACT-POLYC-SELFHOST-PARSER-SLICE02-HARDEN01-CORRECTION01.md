# ACT Closure Handoff — ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01

**Title:** The two bounded qualification gaps found in the review of
`ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01` are closed

**Predecessor:** `ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01` (closed `PASS`)

**Predecessor effective disposition:** `PASS_WITH_NONBLOCKING_RESIDUE`
(the predecessor's PASS is narrowed, not reversed)

**Successor:** `ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`

---

```text
ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01

IDENTITY
ENTRY_HEAD=4113123fbc766d966244d0d22d5d088247d79a48
FINAL_HEAD=<the CLOSE commit; Git owns this identity, it is not claimed here>
WORKTREE_STATUS=CLEAN

RED
Two REDs, both reproduced against the REAL seam, neither a mock.

P0 -- the unknown-fixture-ID bypass.
  The predecessor's direct differential decided whether a line was a
  fixture row with a NEGATIVE test:

      if (line[0] != 'F') continue;
      if (line[1] < '0' || line[1] > '9') continue;

  Every line failing that test was skipped BEFORE the unknown-ID
  ledger ran, so an unknown id such as "X001" was invisible: it never
  incremented unknown_ids and never incremented total. Measured
  against the real differential built by the production compiler, a
  fixture holding the 42 canonical rows PLUS an "X001" row returned
  STATUS=PASS with UNKNOWN_IDS=0 and OBSERVED_FIXTURE_COUNT=42.
  The same held for a "Z999" row.

  The predecessor's own C1 contract specified this control as NC-D12
  ("a fixture id that is not F### (e.g. X001)" -> FAIL /
  FIXTURE_ID_UNKNOWN). Its C3 negative-control evidence recorded
  NC-D1..NC-D7, NC-D9 and NC-D11 -- NC-D12 was ABSENT. It is now
  executed, and it fails as the contract requires.

  RED witness: evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-
  CORRECTION01/c0/red-reproduction.txt

P1 -- the wrong conservation test population.
  The predecessor's c3/lexer07-conservation.txt recorded the LSP
  suite (43/43) as the LEXER07 conservation evidence. The LSP suite
  and the LEXER07 four-generation broad corpus are different test
  populations; the broad corpus is the one governed by
  docs/factory/LEXER07-BASELINE-AUTHORITY.tsv, whose frozen
  prospective baseline records 21 known failures.

  RED witness: evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-
  CORRECTION01/c0/red-reproduction.txt

IMPLEMENTATION
P0 -- tools/quality/parser-control-flow-token-differential.HC
  The row reader now uses a POSITIVE recognition test. A line is
  skipped ONLY when it is an explicitly recognized comment ('#') or
  metadata row: a KEY=VALUE line whose '=' is in the FIRST field, or
  an indented continuation of the metadata block. Every other line is
  a DATA row and is validated, so an unknown id reaches the unknown-ID
  ledger and is reported with the reason token FIXTURE_ID_UNKNOWN.
  The '=' test is scoped to the first field because a data row's
  rationale may legitimately contain '=' ("tok == NULL returns 0; ...").

  Two reason tokens were made specific so that the predecessor's own
  C1 contract holds: a schema-invalid row is FIXTURE_SCHEMA_INVALID,
  not the FIXTURE_ID_SET_INCOMPLETE or FIXTURE_COUNT_MISMATCH that the
  predecessor's C3 evidence recorded. The schema condition uses a
  dedicated field_parse_errors counter, because the aggregate
  parse_errors also counts a missing id and a duplicate id, and a
  duplicate id is not a schema failure.

P0 -- tools/quality/parser-control-flow-token-negative-controls.HC
  A NEW PolyC negative-control DRIVER. It derives each mutated
  fixture mechanically from the canonical fixture and runs the REAL
  differential binary on it, asserting the real exit status and the
  real REASON token. It is not the subject under test: when it reports
  OK, the real differential emitted that token.

P1 -- evidence only.
  The canonical LEXER07 four-generation broad corpus was EXECUTED, and
  both the baseline failure set and the observed failure set are
  recorded. No production code was changed for this gap.

GATES
BUILD=PASS
TARGETED=PASS (the differential and the 16-control driver)
UNIT=PASS
JIT=PASS
LSP=PASS
LEXER07_BROAD_CORPUS=EXECUTED (181 sources x 4 stages)
DIFF_CHECK=PASS

SCOPE
FILES_CHANGED=
  Makefile
  docs/acts/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.md
  docs/factory/HANDOFF-ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01.md
  evidence/ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01-CORRECTION01/**
  tools/quality/parser-control-flow-token-differential.HC
  tools/quality/parser-control-flow-token-negative-controls.HC
DIFF_CHECK=PASS (git diff --check over the committed range)
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO

PRODUCTION_AUTHORITY
CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY=POLYC
LEGACY_C_PRODUCTION_AUTHORITY=RETIRED
BootstrapValidPostControlFlowToken=LOAD_BEARING
PRODUCTION_SEMANTIC_DELTA=0
  (git diff over src/ and tools/bootstrap/ is EMPTY: the production
   compiler, the parser, the lexer, the AST representation and the
   whole bootstrap chain are untouched.)

CONSERVATION
LEXER07_BASELINE_FAILURE_COUNT=21
LEXER07_OBSERVED_FAILURE_COUNT=15
LEXER07_NEW_FAILURE_IDENTITIES=0
LEXER07_REMOVED_PASS_IDENTITIES=0
LEXER07_NEW_DIVERGENCES=0
LEXER07_HISTORICAL_FAILURES_RELABELLED_AS_PASS=NO
LEXER07_REGISTRY_SHA256=040fb7354dd62f2001f167e2dd083be3f5bcb013e97c1cf3e16468c7ae8678bb
LEXER07_REGISTRY_UNCHANGED=YES


RESIDUE
P0=NONE
P1=NONE
P2=
  - RESIDUE_R1 -- the reason-token drift the reviewer noted: the
    predecessor's C1 specifies REJECT_WEAK_SYMBOL while its C3 reports
    REJECT_SYMBOL_NAME_MISMATCH. The weak object IS correctly rejected,
    so the safety property holds. NOT repaired: repairing it would
    require mutating the CLOSED predecessor's frozen C1 contract,
    which F14 forbids, and the review explicitly declined to spend
    effort on the predecessor's historical prose.
  - RESIDUE_R2 -- the `make lexer07-broad-corpus-4-stage` target
    rebuilds the four stage compilers and then runs the corpus, so a
    corpus run launched through it can observe a compiler mid-rewrite
    (measured: two corrupted measurements, FAIL_S0=181 and FAIL_S0=43,
    neither reproducing on a stable tree). The cause is that hcc writes
    its assembly to the FIXED path /tmp/holyc-asm.s. NOT repaired: the
    target's build ordering is outside the bounded scope of this
    correction. The recorded P1 measurement was taken by invoking the
    same PolyC tool with the same canonical inventory on a stable tree.

NEXT_ACT=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03
```

---

## What this ACT did and did not do

It closed exactly the two findings the review raised, and it closed them
at the level the review asked for: the unknown-fixture-ID bypass is now
a source-level impossibility rather than a missing test, and the
LEXER07 conservation claim now rests on an executed broad corpus whose
failure identities were compared, source by source, against the
canonical baseline registry.

It did not reopen the predecessor's five-commit history, did not rewrite
the predecessor's prose or evidence, did not touch the production PolyC
component or its delegation, and did not change any parser, lexer, LLVM
or AST semantics.

It also did not repair the two residual items above. Both are recorded
with the reason they were left, and neither affects the safety property
either one protects.

The review's recommended disposition was:

```text
SLICE02_HARDEN01_ENGINEERING = GREEN
SLICE02_HARDEN01_CLOSURE     = HOLD_QUALIFICATION
SLICE02_PRODUCTION_AUTHORITY = POLYC
```

The qualification hold is now discharged: the unknown extra fixture row
is rejected, the LEXER07 broad corpus has been executed, and the
production authority is unchanged. The next priority remains
`ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03`, which is NOT opened here and
whose winner is NOT preselected here.

---

## 10. Verdict

VERDICT

---

PASS
