# ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 — C3 EVIDENCE

**Phase:** C3 EVIDENCE
**Status:** the C3 exit gate is met. AC01..AC47 PASS, AC48 and AC49 are
C4 phases that have not run yet, AC50 is DEFERRED by construction.

## What was measured

### The four-generation matrix and the twelve ordered pairs

Four REAL executables, each built and executed:

| generation | what it is | driver symbols |
|---|---|---|
| G0 | the pure C-driver oracle, from the pinned entry commit, selector OFF | 0 |
| G1 | the driver compiled by the C-rooted stage0 | 19 |
| G2 | the driver compiled by the current `./hcc` | 19 |
| G3 | the driver compiled by the qualified bootstrap04 | 22 |

**Roster A (object identity):** G1 and G2 are BYTE-IDENTICAL — they are
the same compiler generation reached through two producer executables.
G3 differs, and the difference is observable in the exported symbol
roster.

**Roster B (semantic-stream equivalence):** all TWELVE ordered pairs
agree over the frozen fourteen-case corpus. 168 comparisons, **0
mismatches**. The six pairs that involve G0 needed the one predeclared
`ENVIRONMENT_EXPLAINED` normalization (the `commit-hash:` line); the
six pairs among G1/G2/G3 needed none.

### The causality, in both directions

**The driver MATTERS.** Poisoning the PolyC driver subject with an
object that exports the right symbol names but decides nothing makes
**all fourteen** corpus cases crash. The production route genuinely
reads the driver.

**The C path does NOT matter.** Each of the three DORMANT rows
(`cliParseAssign`, `cliParseInt`, `cliParseBoolean`) was mutated in
place in `src/cli.c`, the compiler was rebuilt, the corpus was
re-executed, and `src/cli.c` was restored and verified byte-identical
by SHA-256. **0 of 14 cases changed** for each.

**There is no fallback.** Removing the driver object fails the
CONFIGURE step with `REJECT_MISSING_DRIVER_SUBJECT`. The legacy C
parser is not merely unused in the production build — it is **not
compiled at all**.

### The three PolyC sites are load-bearing

Each mutation was applied to a COPY of the driver source, the driver
subject was recompiled by the real production compiler, a fresh
production compiler was linked against it, and the corpus was
re-executed.

| mutation | function | changed cases | effect |
|---|---|---|---|
| M1_FLAG_ARITY | `WpDriverOptMatches` | 8 | options stop matching |
| M2_ACTION_DISPATCH | `WpDriverOptionAction` | 4 | the compile action is lost |
| M3_STATUS_PROPAGATION | `WpDriverMapStatus` | 3 | the failure reported changes |

Each changes exactly ONE source line, in a DISTINCT function, in a
DISTINCT decision group, and no two produce the same set of changed
cases.

### The twenty-four negative controls

Every control ran PRISTINE → ADVERSE → RESTORED. The detector is a
COMPILED PolyC program that re-derives each fact from the primary
material. An INDEPENDENT POSIX/Git witness, sharing no code with it,
reaches the same verdict on all 24.

**24 of 24** rejected with their own exact reason token; **24 of 24**
restored byte-identical; **24 of 24** agree between the two witnesses.

### The 32-row reconciliation

13 MIGRATED, 16 RETAINED, 3 DORMANT — matching the C0 census row for
row. The historical 32 is a REVIEW ROSTER, not 32 migrated decisions.
**ONE** new production PolyC authority is added, not thirteen: the
thirteen migrated rows are decisions inside ONE compiled subject.

### Conservation

The parser is 376 of 376 assertions over 90 blocks with the ordered
sequence MD5 `b6f117eb1386ca80f81bc06226e2a741`, byte-identical to
the historical identity. The direct lexers are 89/89, 45/45 and
23/23. F-NO-PYTHON honestly fails at the same 12 paths with zero new
violations. F-POLYC-TOOLS is honestly `UNAVAILABLE`. gate-fast and
gate-push PASS. The append-only suite is 11/11. The closure-status
check is 61/61. The predecessor's evidence is byte-identical.

## Two findings that changed the work

**A real defect in the C1 contract.** The C1-frozen M3 mutation target
named a construct that is not on the causal path, and the action
dispatch was decorative. Both were found by EXECUTION at C3 and
corrected under
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION01`. The parent
ACT's committed C1 evidence was not edited (F14).

**A real defect in the C2 build graph.** The C host bridge was in the
global CMake `SOURCES` list, which put five `_WpDriverHost*` symbols
into the selector-OFF oracle and violated ACT section 3.1. It is now
linked only inside the selector branch.

## An environment precondition, recorded not hidden

The historical parser command compiles each test file with a bare
`../../hcc`, which resolves the builtin header at the compile-time
`INSTALL_PREFIX` `/usr/local/include/tos.HH`. That path does not exist
on this machine and cannot be created. This is NOT a regression: the
SAME command against the UNMODIFIED G0 oracle fails identically. The
baseline was re-measured under a hermetic equivalent in which the
compiler under test is built with `-DCMAKE_INSTALL_PREFIX` pointing at
the SAME test prefix, so the SAME 56333-byte `tos.HH` is resolved
through the prefix. Both the G0 oracle and the migrated compiler were
measured under the SAME conditions.

## The evidence in this directory

| file | what it holds |
|---|---|
| `generation-matrix-and-12-pairs.tsv` | the four generations and the twelve ordered pairs, both rosters |
| `causality-and-poisoning.tsv` | the poisoning experiment, the dormancy mutants and the comparator's sensitivity |
| `driver-32-row-reconciliation.tsv` | the 32 rows with the ACT's required per-row columns |
| `nc01-nc24-executions.tsv` | the twenty-four controls, three phases each |
| `nc01-nc24-independent-witness.tsv` | the independent POSIX/Git witness |
| `c3-conservation-and-gates.tsv` | the re-measured baselines and the gates |
| `acceptance-ledger-ac01-ac50.tsv` | the acceptance ledger |
