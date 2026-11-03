# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02

Factory-Version: 2
Lifecycle: AUTHORIZATION ONLY -- NOT an execution report or a claim of PASS

**Class:** SELFHOST / WP-001 / PRODUCTION-SEMANTIC-AUTHORITY / BOUNDED CORRECTION

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01
(with its terminal CLOSE and the subsequent ordinary outcome commit)

**Affected work package:** WP-001, selected by
ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01
(`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`)

**Production semantic changes:** AUTHORIZED (scoped) -- the PRECEDENCE of
the PolyC-selected status over C-owned policies on the required
compiler-producing route. The artifact-class decision itself is NOT
re-opened.

**IR / ABI / LLVM authorization:** SCOPED -- one additional status-domain
member in the existing PolyC/C action-status ABI. No IR, no LLVM backend,
no language semantics.

---

## 0. Mission and binding outcome

`ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01` moved the
artifact-class decision on the required route from C to the compiled PolyC
driver and proved **consumption** (the production object imports the
accessor, the linked binary calls it from inside the emission function)
and **dormancy** (mutating the legacy C `args->emit_object` decision
leaves the selector-ON output byte-identical).

It did **not** prove **PRECEDENCE**. The predecessor's own C1 branch
ledger records that `src/cli.c` carries a whole-CLI `-o-`/`-S`
compatibility guard that is C-owned, and its C source comment at
`src/cli.c:738-751` claims that "the remaining checks are the PolyC
driver's decision, read back through the PolyC-selected status". That
claim is **false for the first of those checks**: the `-o-`/`-S` guard at
`src/cli.c:755` fires **unconditionally**, before and WITHOUT consulting
the PolyC-selected `status`, and the PolyC status domain has **no member**
for the condition it decides.

The consequence is observable: an argv whose PolyC-selected status is
`WP_STATUS_USAGE` reports a **C-owned** diagnostic instead of the
PolyC-selected one. The PolyC decision is therefore **not authoritative**
on that path, even though the emission-action decision is.

Implement precisely the missing transfer of precedence: on the required
compiler-producing route, the **PolyC-selected status must take
precedence over every C-owned policy**, and no C policy may fire when the
PolyC driver selected a different status. Then **MEASURE** -- do not
assume -- the residual required-route C semantic remainder and the
whole-CLI remainder.

### 0.1 Distinct completion claims

| Claim | Required disposition |
|---|---|
| `PASS_PRECEDENCE_RESTORED_WITH_ROUTE_REMAINDER` | Precedence restored and proven; a residual required-route C semantic remainder is MEASURED, named, and retained as `C_SEMANTIC_ENGINE_RETAINED` or classified and disclosed. |
| `PASS_REQUIRED_ROUTE_QUALIFIED` | Precedence restored AND the measured required-route C semantic remainder is ZERO. |
| `WP001_REQUIRED_ROUTE_POLYC_OWNED` | YES only if precedence is restored AND no C semantic remainder survives that route. |
| `WP001_WHOLE_CLI_POLYC_OWNED` | NOT CLAIMED. `print_tokens`, `compile_to_ast` and the whole-CLI remainder remain explicitly open unless independently proven off-route. |
| `WP001_HISTORICAL_AC_RECONCILED` | NO. The predecessor's historical debt is CONSERVED verbatim, not repaired and not endorsed. |
| `P0_COMPLETE`, `M1_COMPLETE`, `M2_COMPLETE` | NO. The compiler remains hybrid even with a complete PolyC-authored driver. |
| `PRODUCTION_POLYC_AUTHORITIES_FINAL` | Count independently causal distinct authorities. This ACT adds a STATUS decision, not a new emission decision; the reported baseline of 16 does not automatically grow. |

A pass for precedence is not retrospective certification of older Factory
evidence. If a C-owned policy can still preempt the PolyC-selected status
on the required route, `WP001_REQUIRED_ROUTE_POLYC_OWNED=NO` and
`PASS_PRECEDENCE_RESTORED_WITH_ROUTE_REMAINDER` is forbidden.

### 0.2 Terminal outcomes

- `PASS_PRECEDENCE_RESTORED_WITH_ROUTE_REMAINDER` -- precedence restored
  and proven; the residual required-route C semantic remainder is
  measured and disclosed.
- `PASS_REQUIRED_ROUTE_QUALIFIED` -- precedence restored and the measured
  required-route remainder is zero.
- `HALT_ENTRY_OR_FROZEN_CONTRACT` -- HEAD, tree, doctrine, historical
  scope, or ABI is inconsistent.
- `HALT_SELECTED_ACTION_NOT_EXPOSABLE` -- the selected status cannot be
  safely consumed across the real PolyC/C ABI.
- `HALT_PRECEDENCE_NOT_RESTORABLE` -- a C-owned policy still preempts
  the PolyC-selected status on the required route after the correction.
- `HALT_REQUIRED_ROUTE_RETAINS_C_SEMANTIC_OWNER` -- other required-route C
  policy remains after the proposed correction and cannot be classified.
- `HALT_C_ORACLE_CONTAMINATED` -- the selector-OFF oracle has the new
  status path or otherwise ceases to be independent.
- `HALT_OUTPUT_OR_SEMANTIC_DIFFERENTIAL` -- output kind, object, error
  or status differs beyond frozen normalization.
- `HALT_CAUSAL_OR_DORMANCY_UNPROVEN` -- the old C policy is still
  load-bearing or the PolyC status is decorative.
- `HALT_BUILD_OR_PRODUCER_PROVENANCE` -- missing subject, stale object,
  aliased generation, or unsafe parallel build.
- `HALT_CONTROLS_OR_LEDGER` -- adverse controls, evidence provenance, or
  AC reconciliation fails.
- `HALT_CONSERVATION_OR_FACTORY` -- tests, gates, Factory range,
  append-only, or terminality fail.

A HALT must preserve precise failed witnesses. No partial implementation
PASS and no opportunistic next-ACT implementation.

### 0.3 Source and governance precedence

At C0, read actual Git bytes, including `AGENTS.md`,
`docs/factory/DOCTRINE.md`, `docs/factory/GIT-METADATA.md`, canonical
Factory-v2 checker sources, the predecessor ACT
`ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01` and its HANDOFF,
the original boundary qualification and its `CORRECTION01`, and the
WP-001 selected-successor contract at
`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`.

Also read the actual `src/main.c`, `src/cli.c`, `src/cli.h`,
`src/compile.c`, `src/selfhost-driver-wp001.{c,h}`,
`tools/bootstrap/selfhost-driver-wp001.HC`, `src/CMakeLists.txt`, the
object verifier, and the `Makefile`. Recompute source/object ranges and
byte digests, not line numbers printed by an earlier review. When the
source or frozen contract contradicts this document, HALT before editing;
do not invent an ABI or widen a frozen source boundary.

### 0.4 Authorized tracked edits

```text
src/cli.c                                              # the precedence fix: the C policy consults the PolyC-selected status
src/cli.h                                              # only if strictly required by a real ABI declaration
tools/bootstrap/selfhost-driver-wp001.HC               # one additional status-domain member; the precedence decision
tools/quality/driver-required-route-correction02-*.HC  # new PolyC verifier / control tools
tests/driver-wp001/required-route/                     # frozen fixtures for the new precedence cases
Makefile                                               # the canonical test target
src/CMakeLists.txt                                     # only if a verified build/ABI dependency requires it
docs/acts/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.md
docs/factory/act-handoff-map.tsv
docs/ROADMAP.md
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02/
```

### 0.5 Explicitly forbidden

- Any change to the artifact-class decision that the predecessor moved to
  PolyC. It is FROZEN and must be CONSERVED.
- Any change to `src/main.c`'s emission translation table.
- Any change to parser, AST, type, IR, backend or language semantics.
- Any change to the `-o-`/`-S` **diagnostic text** or its exit status.
  Only its **precedence** changes: it must fire when, and only when, the
  PolyC driver selects it.
- Any change to the selector-OFF oracle's legacy policy.
- Any repair of the predecessor's historical debt. That debt is
  CONSERVED, not fixed, by this ACT.
- Any dependency addition. No network access. No Python.

---

## 1. The decisive finding, and why the predecessor's claim was insufficient

`ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01` proved that the
production emission function **consumes** the PolyC-selected emission
code and that the legacy C `args->emit_object` read is **dormant** on the
selector-ON required route.

Consumption plus dormancy does not establish precedence. Precedence is
the property that **no other decision can override or preempt the
PolyC-selected one**. The predecessor did not test it, and the code
contradicts the predecessor's own source comment.

### 1.1 The defect, as it stands in the committed source

`src/cli.c`, function `cliParseArgsPolyC`, the selector-ON region:

```c
    long long status = WpDriverDecide();

    /* 1. `-o-` may only be used together with `-S`. */
    if (args->to_stdout && !args->assemble_only) {
        cliPanic("`-o-` can only be used in conjunction with `-S` for "
                 "printing assembly to stdout\n");
    }

    /* 2. The collected unknown arguments are reported. ... */
    if (status == WP_DRIVER_STATUS_USAGE) { ... }
```

The comment immediately above this block states that "the remaining
checks are the PolyC driver's decision, read back through the
PolyC-selected status", and that "the order among them is the driver's
decision too: the status is a single value, and the C side tests it in
the live order". Check 1 does neither. It reads two C-owned fields
(`args->to_stdout`, `args->assemble_only`), it does **not** consult
`status`, and it fires **before** the status is ever consulted.

The PolyC status domain has **no member** for this condition:

```text
WP_STATUS_OK / USAGE / COMPILE / ARITY / NO_INPUT / ENGINE
```

There is no `WP_STATUS_*` that means "the `-o-` output target requires
`-S`". The driver therefore cannot express the decision, and the C side
makes it on its own. That is a **C semantic owner on the required route**.

### 1.2 The observable consequence

With the driver selector ON, the same argv that yields the PolyC-selected
`WP_STATUS_USAGE` reports two different diagnostics depending only on
whether the C-owned `-o-` guard happens to be satisfied:

| argv | PolyC-selected status | Reported diagnostic | Decided by |
|---|---|---|---|
| `-c src.HC -o out.o --bogus-option` | `USAGE` | `Unknown commandline options: --bogus-option` | PolyC |
| `-S src.HC -o- --bogus-option` | `USAGE` | `Unknown commandline options: --bogus-option` | PolyC |
| `-c src.HC -o- --bogus-option` | `USAGE` | `` `-o-` can only be used in conjunction with `-S` `` | **C -- PREEMPTS** |

The third row is the defect. The PolyC driver made a decision; a C-owned
policy reported instead.

### 1.3 The bound correction

The precondition is a C-owned policy that fires without consulting the
PolyC-selected status, on a path the PolyC status domain cannot express.
The correction is to give the driver the **missing status member**, make
the driver **decide** the condition, and make the C side perform the
diagnostic **only** when the PolyC-selected status selects it.

The **precedence order** among the mutually-exclusive CLI checks becomes
a driver decision too, because a single status value can only carry one
outcome. The driver already owns the arity-before-usage order
(`WpDriverMapStatus`); the `-o-` condition joins that same ordering.

---

## 2. What MUST be measured, not assumed

The predecessor left `BR_MAIN_COMPILE_TO_AST` classified
`SHARED_OR_UNPROVEN` and said the "policy/fault-gate separation is not
established". This ACT does not repair that by assertion. It **measures**
the required-route C semantic remainder, branch by branch, from the real
production source and the real production objects.

Each required-route branch is classified by ONE of:

| Class | Meaning |
|---|---|
| `POLYC_SEMANTIC_OWNER` | The compiled PolyC driver decides it; the C side only executes it. |
| `MECHANICAL_EXECUTION` | The C side translates an already-validated PolyC decision into an engine invocation, with no independent policy. |
| `C_SEMANTIC_ENGINE_RETAINED` | The retained C **compiler engine** (parser, AST, IR, backend) performs its own internal fault handling. It does not choose the route. This is the explicitly named, explicitly permitted P0 precursor. |
| `C_SEMANTIC_OWNER` | A C policy decides something the route depends on. MUST be zero for a required-route qualification. |
| `WHOLE_CLI_OFF_ROUTE` | C-owned, but the flag is absent on the required route, so the branch is not taken there. |
| `SHARED_OR_UNPROVEN` | Separation not established. MUST be zero for a required-route qualification. |

`REQUIRED_ROUTE_C_SEMANTIC_REMAINDER` is the **count** of
`C_SEMANTIC_OWNER` plus `SHARED_OR_UNPROVEN` rows in the required-route
branch ledger, and it is reported as a **measurement**, not a target. The
verdict is selected by the measured value, not by the intent.

### 2.1 What the defect was NOT

It is worth stating what the defect was **not**, because the bound
correction depends on it.

The defect was **not** that the wrong diagnostic was printed. The legacy
C CLI printed the `-o-` diagnostic for an argv that also carried an
unknown argument, and the legacy C CLI was self-consistent about it.

The defect was that a **C-owned policy** printed it. The C side read
`args->to_stdout` and `args->assemble_only` and fired on its own
authority, while the PolyC driver -- which had already selected a
status for that argv -- was not consulted. The correction moves the
**authority** and leaves the **observable behaviour** alone.

A correction that moved the authority AND changed a diagnostic would be
a worse outcome: it would break an argv that used to work. The ACT
therefore does not require one, and the C3 phase **measures** the
behavioural delta rather than asserting it.

### 2.2 The C1 prediction, and the measurement that refuted it

The C1 freeze predicted **exactly one** intended behavioural delta: the
argv carrying the `-o-` condition *and* an unknown argument would
change its reported diagnostic from the `-o-` text to the USAGE text.

The C2 measurement **refutes** that prediction. The measured
behavioural delta is **ZERO**.

The reason is instructive. The C1 freeze placed the new status member
in precedence position 2 -- between `ARITY` and `USAGE` -- in order to
reproduce the legacy CLI's own check order. That order is correct, and
it is what makes the delta zero: the driver selects `TO_STDOUT` for
that argv, and the reported diagnostic is the `-o-` one, exactly as
before. What changed is *who decided*, not *what was said*.

The decisive measurement is that the **legacy G0 oracle**, which never
had the correction, satisfies the **same** frozen contract as the
corrected selector-ON build. If the correction had changed an
observable behaviour, the legacy oracle would fail that contract.

The C1 freeze is immutable historical evidence of what was predicted
(F14). It is **not** rewritten. The C2 evidence records the
refutation.

---

## 3. The G0 C-only oracle

The G0 oracle is the selector-OFF production build: the pure C driver.
It is the independent reference for what the legacy C CLI did.

`G0_C_ONLY` is **PROVEN** only when, against the real G0 binary:

- its symbol table carries **zero** `WpDriver*` symbols;
- its relocations carry **zero** references to the PolyC driver subject;
- it contains **no** trace of the new status-domain member's decision
  path;
- its observable behaviour on the frozen fixtures is the **legacy**
  behaviour, so the differential against the selector-ON build is
  meaningful.

The oracle is never rebuilt with the selector ON and never shares an
object file with the selector-ON build.

---

## 4. Phases

The Factory v2 phase sequence for this ACT is exactly:

```text
RED, EVIDENCE, IMPL, EVIDENCE, CLOSE
```

Five commits, one per phase, each carrying the correct trailers. The
unique terminal CLOSE carries the only `ACT-Verdict` trailer.

### 4.1 C0 -- RED

The principal RED is the **precedence** defect, reproduced against a REAL
production build, not a synthetic mock:

- `R01_PRECEDENCE_PREEMPTED` -- the C-owned `-o-` policy fires while the
  PolyC-selected status is `USAGE`, and the reported diagnostic is the C
  one. Reproduced on a freshly built selector-ON compiler.
- `R02_POLYC_STATUS_DOMAIN_INCOMPLETE` -- the PolyC status domain has no
  member for the `-o-`/`-S` condition, so the C side must decide it.
- `R03_ROUTE_REMAINDER_UNMEASURED` -- the required-route branch ledger has
  no measured remainder, and `BR_MAIN_COMPILE_TO_AST` is still
  `SHARED_OR_UNPROVEN`.
- `R04_G0_ORACLE_INDEPENDENCE_UNPROVEN` -- the G0 oracle's independence
  is not established against the real binary.
- `R05_HISTORICAL_DEBT_UNCONSERVE` -- the predecessor's historical
  partition and its NC17 non-firing are not bound into a frozen roster.

Each RED must be a REAL failing witness against the real seam. If a RED
cannot be reproduced, `HALT_RED_NOT_REPRODUCED`; do not implement the
imagined fix.

### 4.2 C1 -- EVIDENCE

Freeze, from the real entry source:

- the exact source ranges and SHA-256 digests of `src/cli.c`'s
  selector-ON region, of `tools/bootstrap/selfhost-driver-wp001.HC`'s
  status mapping, and of `src/main.c`'s emission function;
- the frozen **status-domain extension**: the new member's name, its
  numeric value, its DISJOINTNESS from the existing status, action and
  emission domains, and its **precedence position** relative to
  `WP_STATUS_ARITY` and `WP_STATUS_USAGE`;
- the **precedence contract**: the exact order in which the driver
  resolves the mutually-exclusive CLI checks, and the exact diagnostic
  text and exit status for each;
- the **required-route branch ledger**, with the classification of EVERY
  branch the required route reaches, and the measurement rules;
- the **G0 independence contract**: the exact symbol/relocation/behavior
  checks;
- the **fixture roster**: the required route, the alternate routes, the
  precedence discriminators, and the negative cases;
- the **comparator**: the full field set (artifact class, exit status,
  stdout digest, stderr text) and the frozen normalization;
- the **causal/dormancy experiment plan**: the exact mutation byte
  ranges, the exact predicates and the exact expected observations;
- the **AC01..AC50** roster and the **NC01..NC24** roster with their
  EXACT reason tokens;
- the **historical debt roster**: the predecessor's three acceptance
  ledgers with their **MEASURED** status partitions (`10/39/1`,
  `47/2/1`, `49/0/1`) and its NC17 non-firing, frozen for conservation.

### 4.3 C2 -- IMPL

Implement the minimum production change permitted by C1:

1. Add ONE status-domain member to the PolyC driver for the `-o-`/`-S`
   condition, with a value DISJOINT from every existing status, action
   and emission code.
2. Make the PolyC driver **decide** the condition and place it in the
   frozen precedence position.
3. Change the C side so that the `-o-`/`-S` diagnostic fires **only**
   when the PolyC-selected status is that new member. No C-owned policy
   may fire on a status that selects something else.
4. Preserve the diagnostic text and the exit status exactly. The
   observable behaviour for every currently-firing argv is unchanged;
   only the case where a C policy preempted the PolyC status changes,
   and it changes to the PolyC-selected outcome.
5. Do not touch `src/main.c`, the artifact-class decision, the emission
   translation table, the parser, the AST, the IR, the backend or the
   language semantics.
6. Extend the production verifier to check that the C side's status
   dispatch is exhaustive over the frozen status domain, so a new status
   member cannot be silently ignored.
7. Keep Make and CMake generated-object dependencies correct and
   fail-closed. Define producer/prerequisite variables before their
   consuming rules.
8. Add canonical test fixtures for the precedence discriminators under
   the authorized test path, and a canonical Make target.

### 4.4 C3 -- EVIDENCE

Execute, against real builds:

- the **G0 C-only independence** proof;
- the **precedence conservation** proof: for the frozen fixture set, the
  selector-ON compiler's observed status equals the PolyC-selected
  status, and no C policy fires on a status that selects something else;
- the **PolyC precedence is causal**: mutating the driver's precedence
  decision changes the reported diagnostic;
- the **C legacy dormancy**: mutating the legacy C `-o-` policy leaves
  the selector-ON output byte-identical, while the G0 oracle's output
  changes;
- the **invalid action fails closed**: an out-of-domain status produces
  no artifact and no fallback;
- the **four-generation producer DAG**: G0 plus three distinct PolyC
  producers, with DISTINCT producer identities and NO alias;
- the **ordered pairwise matrix**: `4 x 3 = 12` ordered comparisons over
  the FULL comparator field set;
- the **24 negative controls**, each firing its OWN EXACT reason token;
- the **required-route and whole-CLI remainder measurement**;
- the **historical debt conservation**: the predecessor's AC partition
  and its NC17 non-firing are unchanged;
- the **conservation and gates**: the parser suite, the assertion MD5,
  the lexer differentials, the 16 production authorities, `gate-fast`,
  `gate-push`, the append-only suite, the Factory v2 suite, `F-NO-PYTHON`
  and `F14`.

### 4.5 C4 -- CLOSE

The unique terminal CLOSE. It carries the only `ACT-Verdict` trailer, a
HANDOFF, a handoff-map entry, a ROADMAP entry, the final acceptance
ledger and the terminality PLAN. It does not pre-record a receipt.

---

## 5. Acceptance criteria

| ID | Phase | Criterion |
|---|---|---|
| `AC01` | C0 | Exact pinned branch/HEAD/TREE, clean classified state, zero replace refs. |
| `AC02` | C0 | The predecessor ACT, HANDOFF, Factory doctrine and the WP-001 successor contract reread from immutable Git bytes. |
| `AC03` | C0 | The predecessor's 16 live authorities independently reverified from production objects and the link line. |
| `AC04` | C0 | Exact source/body/digest of `src/cli.c`'s selector-ON region, the driver's status mapping and `src/main.c`'s emission function frozen. |
| `AC05` | C0 | The predecessor's branch ledger and 32 historical driver rows preserved as historical evidence. |
| `AC06` | C0 | Real CMake-built G0 and selector-ON entry executables with verified link configuration. |
| `AC07` | C0 | Real object-producing compile witness and alternate-output discriminator executed. |
| `AC08` | C0 | The precedence defect reproduced against a REAL production build with the exact diagnostic texts. |
| `AC09` | C0 | The PolyC status domain's incompleteness proven from the real driver source. |
| `AC10` | C0 | The five REDs executed as real PRISTINE -> ADVERSE cycles with distinct reason tokens. |
| `AC11` | C0 | The historical debt roster (AC partition and NC17) frozen. |
| `AC12` | C1 | The status-domain extension frozen with disjointness proven. |
| `AC13` | C1 | The precedence contract frozen: order, diagnostic text, exit status. |
| `AC14` | C1 | The required-route branch ledger frozen with the measurement rules. |
| `AC15` | C1 | The G0 independence contract frozen. |
| `AC16` | C1 | The fixture roster frozen, including the precedence discriminators. |
| `AC17` | C1 | The full comparator field set and normalization frozen. |
| `AC18` | C1 | The four causal/dormancy/fail-closed experiment plans frozen with exact byte ranges. |
| `AC19` | C1 | The four-generation producer DAG plan frozen. |
| `AC20` | C1 | The AC01..AC50 roster frozen. |
| `AC21` | C1 | The NC01..NC24 roster frozen with exact reason tokens. |
| `AC22` | C2 | The new status member added to the PolyC driver with a disjoint value. |
| `AC23` | C2 | The driver decides the condition in the frozen precedence position. |
| `AC24` | C2 | The C side consults the PolyC-selected status and no C policy fires on another status. |
| `AC25` | C2 | The diagnostic text and exit status preserved exactly for every currently-firing argv. |
| `AC26` | C2 | `src/main.c`, the artifact-class decision and the emission translation table UNCHANGED. |
| `AC27` | C2 | The parser, AST, IR, backend and language semantics UNCHANGED. |
| `AC28` | C2 | The production verifier checks that the status dispatch is exhaustive. |
| `AC29` | C2 | The build graph is fail-closed and the generated-object dependencies are correct. |
| `AC30` | C2 | Canonical fixtures added for the precedence discriminators and a canonical Make target. |
| `AC31` | C2 | No new dependency; no Python; no network. |
| `AC32` | C3 | `G0_C_ONLY` PROVEN: zero driver symbols, zero relocations, zero new-status trace, legacy behaviour preserved. |
| `AC33` | C3 | The precedence conservation measured over the full fixture set. |
| `AC34` | C3 | The PolyC precedence is CAUSAL: mutating it changes the diagnostic. |
| `AC35` | C3 | The legacy C policy is DORMANT on the selector-ON build and LIVE on the G0 oracle. |
| `AC36` | C3 | An invalid status FAILS CLOSED: no artifact, no fallback. |
| `AC37` | C3 | The four-generation producer DAG measured with 4 distinct producers and no alias. |
| `AC38` | C3 | The 12 ordered pairwise comparisons measured over the FULL comparator field set. |
| `AC39` | C3 | The required-route C semantic remainder MEASURED and reported. |
| `AC40` | C3 | The whole-CLI remainder MEASURED and reported. |
| `AC41` | C3 | 24/24 negative controls fire their own exact reason tokens. |
| `AC42` | C3 | The predecessor's historical AC partition and NC17 non-firing are CONSERVED unchanged. |
| `AC43` | C3 | The predecessor's 16 production authorities are conserved; the delta is measured. |
| `AC44` | C3 | The canonical new driver regression tests execute and cover every output class. |
| `AC45` | C3 | The parser and direct lexer identities conserved; historical non-greens honest. |
| `AC46` | C3 | `gate-fast`, serialized `gate-push`, append-only and F14 pass. |
| `AC47` | C4 | Unique terminal CLOSE, five correctly trailered phase commits, no ACT continuation. |
| `AC48` | C4 | HANDOFF/map/roadmap accurately distinguish the precedence PASS, the route remainder, the whole-CLI remainder and the historical debt; no pre-recorded receipt. |
| `AC49` | C4 | The acceptance ledger is complete with no unsupported PASS. |
| `AC50` | POST-CLOSE | An independent read-only external receipt binds the CLOSE HEAD/TREE, discharges the final ACT terminality and confirms zero push/replace refs/worktrees. |

The predecessor's `AC50` was also a POST-CLOSE criterion. This ledger is
independent and does not repair the predecessor's ledger; the
predecessor's adjudications remain immutable historical evidence.

---

## 6. The historical debt this ACT must CONSERVE

The predecessor's own tree records:

- its acceptance criteria in **THREE** committed ledgers of 50 rows each
  (the C0 frozen roster, the C3 ledger and the C4 final ledger), whose
  recomputed status partitions are **10/39/1**, **47/2/1** and
  **49/0/1** respectively (PASS / NOT_RUN / DEFERRED), and
- its negative-control result **23/24**, where `NC17` correctly did NOT
  fire because its subject is PROVEN LIVE.

Both are **historical facts about the predecessor's tree**. This ACT:

- does NOT repair them,
- does NOT endorse them,
- does NOT re-adjudicate the predecessor's 50 criteria,
- and **MUST** show them UNCHANGED in the conservation evidence.

A four-way partition of the predecessor's acceptance criteria into
`29 / 10 / 10 / 1` was requested. **No such partition exists.** The
whole Git history was searched for it over 1833 commits with no match,
and the three recomputed partitions above are the only ones the
predecessor's evidence carries. The requested figure is recorded as a
**REFUTED HYPOTHESIS**, and the conserved value is the **MEASURED** one
(`docs/factory/DOCTRINE.md` §22 source-of-truth hierarchy: executable
source and fresh observations outrank prompt prose).

The proposed separate evidence successor, not authorized here, is:

`ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-EVIDENCE-CORRECTION01` --
independently re-adjudicate the predecessor's 50 historical criteria
against immutable phase-specific evidence. Do not start it under this
ACT.

---

## 7. Final rule

A PASS requires genuine **precedence** of the PolyC-selected decision
over every C-owned policy on the required route -- not a decorative
export, not mere consumption of a pre-existing C flag, and not a green
test suite with the wrong artifact type. The retained C engine is
allowed for the P0 precursor but must be transparently named
`C_SEMANTIC_ENGINE_RETAINED`. M2 is not achieved.

Repository source and Factory doctrine, not external documentation,
govern the final technical and historical obligations.
