# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION ONLY -- NOT an execution report or a claim of PASS

**Class:** SELFHOST / WP-001 / PRODUCTION-SEMANTIC-AUTHORITY / BOUNDED CORRECTION

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessor:** ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01-CORRECTION01
(with external receipt and the subsequent ordinary outcome commit)

**Affected work package:** WP-001, selected by
ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01
(`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`)

**Production semantic changes:** AUTHORIZED (scoped) -- the emission-action
decision on the required compiler-producing route moves from C to the
compiled PolyC driver.

**IR / ABI / LLVM authorization:** SCOPED -- a PolyC/C action ABI is
authorized for the emission action only. No IR, no LLVM backend, no
language semantics.

---

## 0. Mission and binding outcome

A read-only qualification and a subsequent independent Codex review found
that production `src/main.c::emitFile` still branches on
`args->emit_object`. On the required `hcc --install-dir=X -c input.HC -o
out.o` route, changing that C decision changes the artifact class
(Mach-O object versus executable). `WpDriverSelectedAction()` is exported
from the compiled PolyC driver but has no proven production callsite. The
existing object verifier establishes symbol presence, not consumption of
the decision. These are the source-backed premises to reverify at C0, not
permanent line-number assumptions.

Implement precisely the missing causal transfer: the compiled PolyC driver
must choose what emission action is requested; retained C may execute that
already-chosen action through the existing compiler engine, but may not
independently choose object versus executable from argv,
`CliArgs.emit_object`, a parallel option table, or a default C policy. The
actual compiler must emit the same artifacts and diagnostics as the
independent C-driver oracle for the frozen route and adjacent, observable
cases.

### 0.1 Distinct completion claims

| Claim | Required disposition |
|---|---|
| `CORRECTION_TECHNICAL_PASS` | Real selector-ON production compiler consumes the PolyC-selected action; causal and dormancy tests pass. |
| `WP001_REQUIRED_ROUTE_POLYC_OWNED` | YES only if every decision on the frozen required compiler-producing route is accounted for and no C semantic remainder survives that route. |
| `WP001_WHOLE_CLI_POLYC_OWNED` | NOT CLAIMED. `print_tokens`, `compile_to_ast`, and the `-o-`/`-S` C guard remain explicitly open unless independently proven mechanical/off-route. |
| `WP001_HISTORICAL_AC_RECONCILED` | NO. The earlier 32-alternate-witness claim was challenged; do not silently repair or endorse it here. |
| `P0_COMPLETE`, `M1_COMPLETE`, `M2_COMPLETE` | NO. The compiler remains hybrid even with a complete PolyC-authored driver. |
| `PRODUCTION_POLYC_AUTHORITIES_FINAL` | Count independently causal distinct authorities. Completing a previously counted driver authority does not automatically add one more to the reported baseline of 16. |

A pass for the new technical transfer is not retrospective certification of
older Factory evidence. If a C policy decision on the required route
remains active, `WP001_REQUIRED_ROUTE_POLYC_OWNED=NO` and technical PASS
is forbidden.

### 0.2 Terminal outcomes

- `PASS_REQUIRED_ROUTE_POLYC_ACTION_AUTHORITY` -- all new
  technical/factory obligations met; existing whole-CLI/evidence debts
  disclosed without relabelling.
- `HALT_ENTRY_OR_FROZEN_CONTRACT` -- HEAD, tree, doctrine, historical
  scope, or ABI is inconsistent.
- `HALT_SELECTED_ACTION_NOT_EXPOSABLE` -- the selected action cannot be
  safely consumed across the real PolyC/C ABI.
- `HALT_REQUIRED_ROUTE_RETAINS_C_SEMANTIC_OWNER` -- other required-route C
  policy remains after the proposed correction.
- `HALT_C_ORACLE_CONTAMINATED` -- selector-OFF oracle has the new action
  path or otherwise ceases to be independent.
- `HALT_OUTPUT_OR_SEMANTIC_DIFFERENTIAL` -- output kind, object, error or
  status differs beyond frozen normalization.
- `HALT_CAUSAL_OR_DORMANCY_UNPROVEN` -- old C policy still load-bearing or
  PolyC action is decorative.
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
Factory-v2 checker sources, `docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01.md`,
its `CORRECTION01..04`, the original boundary qualification and its
`CORRECTION01`, all HANDOFFs, and the WP-001 selected-successor contract
at
`evidence/ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01/c2/selected-successor-contract.md`.

Also read the actual `src/main.c`, `src/cli.c`, `src/cli.h`,
`src/selfhost-driver-wp001.{c,h}`, `tools/bootstrap/selfhost-driver-wp001.HC`,
`src/CMakeLists.txt`, the object verifier, and the `Makefile`. Recompute
source/object ranges and byte digests, not the line numbers printed in the
independent review. When the source or frozen contract contradicts this
document, HALT before editing; do not invent an ABI or widen a frozen
source boundary.

The review's Git source is independent and useful, but it did not rerun the
actual production builds, the 14-case mutation corpus, or the external
receipt. Those are mandatory new tests in this ACT.

### 0.4 Authorized tracked edits

```text
src/main.c                                             # emitFile / bounded action consumption / necessary nearby call path
src/cli.c                                              # only if necessary to transport already-selected action
src/cli.h                                              # only if strictly required by real ABI
src/selfhost-driver-wp001.c                            # mechanical bridge only; no duplicate semantic policy
src/selfhost-driver-wp001.h                            # ABI declaration, status-domain and lifetime only
tools/bootstrap/selfhost-driver-wp001.HC               # existing PolyC action decision and bounded export
tools/quality/driver-required-route-correction01-*.HC  # new PolyC verifier / control tools
src/CMakeLists.txt                                     # only if a verified build/ABI dependency requires it
src/cmake/VerifyDriverWp001Object.cmake                 # extend verified consumption checks, not weaken them
Makefile                                               # only bounded subject/test dependencies

tests/driver-wp001/**                                  # additive canonical tests if conforming to repo test layout

docs/acts/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01.md
docs/factory/act-handoff-map.tsv                       # exactly one append-only entry
docs/ROADMAP.md                                        # exactly one bounded append-only section
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01/**
```

Any new test outside `tests/driver-wp001/**` needs a documented existing
framework convention and an explicit pre-edit proof that it is covered by
this ACT. Forbidden: other production subsystems (`src/parser.c`, AST, IR,
codegen, lexer), other bootstrap components, prior ACT/HANDOFF/evidence,
canonical gate relaxation, new Python, third-party dependencies, and
history rewriting. A real, independently justified compiler ABI blocker
requires HALT or a separately authorized ACT, not an unrelated fix.

All mutations must occur in disposable detached worktrees with isolated
build directories. Serialize compiler invocations because
`/tmp/holyc-asm.s` and parallel object-production races remain open.

## 1. Factory-v2 lifecycle and history discipline

PASS-path exactly five linear, separately committed phases:

```text
C0 RED  ->  C1 EVIDENCE  ->  C2 IMPL  ->  C3 EVIDENCE  ->  C4 CLOSE
```

Commit C1's frozen ABI, fixtures and RED witnesses before any C2
production change. Every commit message must contain the exact ACT id and
a canonical Git trailer block, separated from the body by a blank line.
Validate via the repository's real `factory-v2-commit-msg-check.sh` before
committing; read back each committed message with `git show -s
--format=%B` and parse it with `git interpret-trailers --parse`. Do not use
subjects as a substitute for trailers.

```text
ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01 C2: IMPL

Transfer object-action ownership to the compiled PolyC driver.

ACT: ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01
ACT-Phase: IMPL
```

The unique fifth CLOSE includes `ACT-Verdict: PASS` (or the doctrinal
HALT sequence and verdict). Do not commit a future external terminality
outcome in the CLOSE tree. Commit only a `terminality-plan.txt` and a
C3/C4 ledger with `AC50=DEFERRED`. After CLOSE, run read-only external
verification and store its receipt outside the repository, bound to CLOSE
SHA/TREE. No second CLOSE, no post-CLOSE ACT-identified commit, no
backdated receipt. Prefer no tracked commits after CLOSE at all; if any
later ordinary record is explicitly permitted, report its presence
separately from the ACT terminal state.

External terminality failure is an actual failure; report it and request a
new, independently authorized correction instead of continuing the closed
ACT.

## 2. C0 -- RED: identity, exact counterfactual, frozen obligations

### 2.1 Exact entry, conservation, source freeze

Capture commands, stdout/stderr, exit codes, binary SHA and Git OIDs:

```sh
git branch --show-current
git rev-parse HEAD 'HEAD^{tree}'
git status --porcelain=v1
git replace -l
git worktree list --porcelain
git log -12 --format='%H %P%n%B'
git ls-tree -r HEAD -- src/main.c src/cli.c src/cli.h \
  src/selfhost-driver-wp001.c src/selfhost-driver-wp001.h \
  tools/bootstrap/selfhost-driver-wp001.HC
```

Require exact main, HEAD `33f93347277c6ce242a93b71ab5f0123ccaea4e5`,
tree `d34300d54de1f3c9f51c41702571a3a19a37739b`, clean classified
tree/index, no replace refs. Record existing worktrees; remove only
ACT-owned worktrees later. Confirm historical immutable ACT ranges, the
latest ordinary post-CLOSE commit, and distinguish the external receipt's
claim from any committed prospective assertion. Do not need to
re-adjudicate the historical 50 ACs in this technical correction.

Rebuild and source/object/link prove the 16 reported authorities;
separate 15 predecessors from the one driver authority. Freeze the exact
original C branch, caller/import path, `WpDriverSelectedAction()` symbol
and its live callers (or absence), plus the true CMake production link
line. Capture the entry compiler's actual `--install-dir`, test-prefix and
target flags.

Re-measure the 376/376 parser baseline over 90 test blocks and ordered MD5
`b6f117eb1386ca80f81bc06226e2a741`; three direct lexer suites 89/89,
45/45, 23/23. The LEXER07 broad 15 failure identities, 67 cross-target
prefix observations and 12 historical F-NO-PYTHON paths must be remeasured
if possible or clearly `NOT_REMEASURED`/`FAIL_KNOWN_BASELINE` -- never
silently converted to PASS. F-POLYC-TOOLS remains UNAVAILABLE unless a
real authoritative checker has landed.

### 2.2 Reproduce the two decisive source-level findings

On a real production CMake build, not an ad-hoc `cc` link, execute the
original C-only and selector-ON compiler with identical inputs.
Reproduce, or explicitly disprove with evidence:

1. `BR_EMITFILE_EMIT_OBJECT`: `emitFile` changes object-versus-executable
   output based on C `args->emit_object`; an isolated C mutation changes
   the artifact class.
2. `WpDriverSelectedAction()` is exported but not consumed by the actual
   object emission path; symbol definition/relocation alone is not enough.

For the compile-object witness, use a fixture whose `-c input.HC -o out.o`
produces a real inspectable Mach-O/ELF target object. Verify magic/type,
`_main`/target symbol as appropriate, expected link/execution where
applicable, status, stdout/stderr, and output side effects. Also exercise
a discriminating not-`-c` baseline that takes the executable or other
alternate emission path that G0 actually supports. Do not invent
unsupported flags. For negative cases include unknown option, missing `-o`
value, unreadable input and unusable output/prefix if reproduced by G0.

### 2.3 Five deliberately failing claims (real REDs)

Freeze a RED contract before edits. Each detector must run a pristine ->
adverse -> restored cycle against genuine source/object/evidence state,
with distinct reason-specific failure:

| RED ID | Adverse premise | Detector reason |
|---|---|---|
| `R01_UNUSED_ACTION` | New PolyC action exists but production never consumes it | `POLYC_ACTION_NOT_CONSUMED` |
| `R02_C_EMISSION_POLICY` | C `emit_object` still decides output class in selector-ON | `C_REQUIRED_ROUTE_DECISION_ACTIVE` |
| `R03_FAKE_OBJECT` | A green compiler invocation writes an executable where an object was required | `EMITTED_ARTIFACT_CLASS_MISMATCH` |
| `R04_ORACLE_LEAK` | Selector-OFF imports the new action/bridge or delegates to PolyC | `C_DRIVER_ORACLE_CONTAMINATED` |
| `R05_BACKDATED_RECEIPT` | A tracked CLOSE-tree file claims the result of a future probe | `TERMINALITY_CHRONOLOGY_UNPROVEN` |

Execute actual adverse experiments. A synthetic string claiming these
failure reasons is not evidence. Freeze 50 AC IDs and 24 NC IDs,
including their specific intended detector and state-restoration
requirements. No C2 edit until C0 RED and source identity are committed;
otherwise HALT.

## 3. C1 -- EVIDENCE: freeze executable action ABI and C-only oracle

### 3.1 Freeze the actual ownership boundary

Derive a per-branch ledger from live source and executable traces for
`main`, `emitFile`, `cliParseArgsPolyC`, host bridge and driver.
Distinguish:

- `REQUIRED_ROUTE_SEMANTIC`: decision that can change the required
  `--install-dir ... -c ... -o ...` compilation route.
- `MECHANICAL_EXECUTION`: translating an already validated PolyC action
  token into an engine invocation, with no independent policy.
- `WHOLE_CLI_OFF_ROUTE`: e.g. `print_tokens` and the `-o-`/`-S` guard,
  excluded from the required route but still owned by C.
- `SHARED_OR_UNPROVEN`: e.g. `compile_to_ast` until separately traced.
- `DORMANT_OR_EXCLUDED`: source present but unreachable from the
  production path.

Rejoin the historical 32 WP-001 rows by original IDs. Do not claim their
entire count migrated, nor that two branch records are the exhaustive
whole-CLI C remainder. Codex independently identified the C `-o-`/`-S`
guard as an additional global semantic decision. Record it in the
read-only global inventory; do not modify it here.

### 3.2 An actual, observable PolyC/C action contract

Read the existing `WpDriverSelectedAction()` signature, enum values, host
call conventions, and the current CLI parse/request ABI. Freeze an ABI
that transports a validated action selected by PolyC to the real emission
call. Permitted patterns, subject to real compiler support, are:

1. A typed/checked scalar action or immutable action record generated by
   PolyC and consumed by a mechanical C executor; or
2. A bounded host-owned result cell written by PolyC with explicit status,
   generation/domain and ownership checks.

Do not create a second C flag parser, or convert `args->emit_object` back
into a C-selected policy token. If C must branch mechanically on a
PolyC-provided action (`COMPILE_OBJECT` vs `EMIT_EXECUTABLE`), prove that
this is solely translation of the selected plan to a platform command; it
must not independently infer action from argv, `args->emit_object` or its
own defaults.

The contract must separately represent valid zero-valued actions,
unknown/invalid action, absent request, error and success. Check lifetime,
alignment, ABI symbol names, borrowed memory and status propagation. Forbid
unchecked `void*`, use-after-lifetime, cross-PolyC-frame `longjmp`,
hidden shared mutable request state or unobserved fallback. Prove action
source identity by relocation and function-level call chain on the actual
linked `hcc`.

If the requested action cannot be conveyed using the frozen ABI without a
new unsupported language facility or nonmechanical C semantics,
`HALT_SELECTED_ACTION_NOT_EXPOSABLE`. Do not add a decorative wrapper
export.

### 3.3 Independent G0 and producer provenance

Produce a genuine selector-OFF C-driver oracle from the entry's C
semantics, with the new action symbols absent from link inputs, imports,
symbol table and execution path. The existing 15 other PolyC authorities
may remain in G0: C-only here means driver C-only, not whole compiler
C-only.

Freeze the actual same-source PolyC action generation plan for G1/G2/G3
from independently hashed compiler executables where available. If a
requested generation is an alias, mark `PRODUCER_ALIAS` and HALT on an
obligatory independent-producer claim. Compare semantic streams across all
12 ordered pairs; object hashes are separately compared only where exact
bytes should match. G0 C compiler object and PolyC subject need not be
byte-identical.

Freeze the comparator on argv, exit, stdout/stderr (only documented
normalization), emitted artifact class, target architecture, key object
sections/symbols, and execution behavior. Use precomputed case IDs and
actual fixture content digests, not case-specific expectations handwritten
after seeing C2 outputs. Prove comparator sensitivity by altering output
class, exit code, stderr, and artifact content individually.

### 3.4 Predeclare causal experiments and abstention rules

Freeze at least these distinct C3 experiments:

- `M-POLYC-ACTION-01`: alter one selected action mapping in the PolyC
  source only; rebuild the whole production compiler; observe the requested
  artifact class change or an explicitly predicted fail-closed rejection.
- `M-POLYC-STATUS-02`: alter a separately existing PolyC-controlled
  status/error mapping; observe status/stderr without altering unrelated
  action cases. This tests conservation of the driver, not a new
  authority-count increment.
- `M-C-LEGACY-03`: alter the historical C `args->emit_object` decision in
  a selector-OFF worktree, prove it is live and changes artifact class;
  repeat the same C mutation in selector-ON and prove the old decision is
  dormant/non-authoritative.
- `M-POLYC-POISON-04`: remove, corrupt or stub the action subject; the ON
  build must fail closed or actual compile behavior must fail as expected,
  never silently use old C decisions.

Require independent real builds, distinct source and object hashes, exact
mutation byte ranges, linked-binary provenance, no mutation in unrelated
semantic functions, and restoration. If the chosen PolyC action mutation
is causally decorative, HALT; if ON still changes when the legacy C
decision is mutated, HALT.

### 3.5 C1 completion

Commit C1's actual source ranges/hashes, ABI, G0 build manifest, producer
DAG, frozen fixture cases, comparator, status-domain matrix, causal plan,
and authority ledger as the second ACT commit with exact trailers. Never
reconstruct a purported C1 freeze at C3. If this evidence cannot be bound
to the real entry source, HALT before C2.

## 4. C2 -- IMPL: transfer action authority, not merely the field

Implement the minimum production change permitted by C1:

1. Make the production emission call consume `WpDriverSelectedAction()` (or
   an explicitly qualified equivalent PolyC-produced action). Independently
   confirm the selector's effect reaches the emission call; an unused
   export or a call in only an unrelated path is insufficient.
2. Remove the C policy predicate that independently chooses output class
   on the required route. The selector-OFF oracle may retain legacy
   `args->emit_object` logic for genuine C-driver G0; the selector-ON
   compilation path must not use it to select the emitted artifact.
3. Retain C as a mechanical executor of the action already selected by
   PolyC and the existing C compilation engine for this P0 precursor.
   Preserve diagnostics, temp-file handling, target options, recovery,
   ownership and error propagation. Do not alter parser/AST/type/IR/backend
   semantics.
4. Do not change `print_tokens`, the `-o-`/`-S` C guard or the
   `compile_to_ast` path unless C1 proves one is on the required route and
   a bounded change is explicitly within this ACT's authorized boundary.
   Otherwise HALT and report the remaining required-route C semantic owner.
   Whole-CLI completion is not in scope.
5. Extend the existing production-object verifier to check call-site
   consumption and, where necessary, function-scoped disassembly and
   relocation provenance. Verify the link cannot succeed with a
   missing/stale subject, wrong selector, duplicated action source or
   fallback C policy. An `nm` definition check alone does not count.
6. Keep Make and CMake generated-object dependencies correct and
   fail-closed. Because GNU Make expands ordinary prerequisites when
   reading rules, define producer/prerequisite variables before their
   consuming rules; audit the actual expanded build graph. Avoid duplicate
   output-producing rules that race in parallel.
7. Add canonical test fixtures for the positive object route, a
   discriminating alternate emission route and relevant negative
   argument/status cases, under the authorized test path.

Build both C-only oracle and selector-ON production compiler with the real
CMake/Make configuration and a populated hermetic installation prefix.
Inspect artifact types through `file` and the target's object tools
(`otool`, `llvm-readobj`, `readelf` as appropriate); do not infer type from
filename or an exit code. A `.o` path containing an executable is failure
even if the command exited zero.

C2 exit is provisional: the new path builds, imports the PolyC decision and
produces a valid object, but no terminal PASS until C3 controls and
external C4 receipt.

## 5. C3 -- EVIDENCE: independent proof of semantic transfer

### 5.1 Exact observable counterfactual matrix

Execute, with explicit fixture IDs and SHA-bound binaries:

| Program | Source condition | Expected observation |
|---|---|---|
| G0 pristine | Legacy C driver | Correct `-c` object and alternate output baseline |
| ON pristine | PolyC action | Byte-equal or semantically equivalent artifact to G0; identical declared CLI semantics |
| ON PolyC action mutant | PolyC rule changed, C untouched | Object-vs-executable outcome changes or correctly predicted fail-closed refusal |
| G0 C decision mutant | `args->emit_object` predicate changed | Artifact class changes; legacy C rule proven live in oracle |
| ON same C decision mutant | C legacy rule changed, PolyC unchanged | Output and ON caller's semantic path unchanged; legacy rule dormant |
| ON subject absent/poisoned | Missing or invalid PolyC action | Build fails or runtime rejects; no C fallback |
| Restored | Both source edits removed | Source/object and semantic outcomes restored to original, with environment-dependent binary hash differences labelled honestly |

Use successful compiler rebuilds for mutants wherever the causal claim
depends on runtime behavior; build failure alone is not a substitute.
Distinguish the same source mutated under selector ON/OFF and prove
isolation with real Git blobs and actual object digests. Do not report an
expected mutation diff as the compiled diff without checking the bytes used
in the build.

### 5.2 Generation comparisons, scope, accounting

Run G0/G1/G2/G3 through the source-derived CLI fixture set; require
12/12 ordered pairwise semantic comparisons to agree, independently
recomputed by a different implementation. Keep producer identities and
object identity roster distinct.

Recompute every required-route branch using function-scoped
source/IR/object/control-flow plus counterfactuals; classify each
remaining C branch `MECHANICAL`, `C_SEMANTIC`, `OFF_ROUTE`, `UNPROVEN`.
Any active required-route `C_SEMANTIC` or `UNPROVEN` forbids
required-route PASS. Report `compile_to_ast` separately, not silently
waived.

Rejoin all 32 historical driver rows, preserving original IDs; split
retained C semantics by required route versus whole CLI. Count distinct new
authorities only where a new independently attributable decision is
demonstrated. If this ACT merely completes the existing one WP-001
authority, report `NEW_AUTHORITY_COUNT_DELTA=0` with the baseline 16
unchanged. Do not turn one decision split across functions into artificial
additional authorities.

Cost accounting must include the parent, `CORRECTION01-04`, the original
boundary qualification, its correction, and this ACT as distinct actual
identities. Distinguish ACT identities consumed from valid Factory
terminal lifecycles and from implementation-only ACT cost. Reprice WP-001
transparently; do not silently retain 2/3/5 as observed completion cost.

### 5.3 Conserved baselines and gate execution

Require parser 376/376 with identical ordered MD5, all direct lexers, real
target-prefix configuration, gate-fast and serialized gate-push (all seven
checks: build/install/gep01/aot/jit/lsp/diff-check). F-NO-PYTHON must
show its 12 exact pre-existing IDs and zero new, or explicitly report
inability to measure. F-POLYC-TOOLS is UNAVAILABLE until its canonical
checker is landed. Known broad LEXER07 failures and cross-target prefix
failures must not be reported PASS without a fresh all-green run.

Prove F14 historical evidence byte identity, append-only 11/11, current
closure-status, exact canonical Factory-v2 phase range and trailer
validation, one authorized handoff-map append, no change to unrelated
source/tests, no unclassified tool residue and no ACT-owned worktrees left
behind.

### 5.4 Controls and ledger

Execute all 24 frozen NCs (section 8) with pristine SILENT -> targeted
adverse exact reason -> byte-restored SILENT. Independent witness must read
source evidence and recompute claims -- not simply trust
`binding_carries`, `binding_phase_valid`, `PASS`, or a synthetic reason
string from the subject verifier.

At C3 require AC01..AC47 PASS, AC48 and AC49 NOT_RUN (C4-only), and AC50
DEFERRED; all statuses must carry evidence paths or explicit phase-based
deferral. At C4 AC48 and AC49 may become PASS after their own obligations
execute, while AC50 remains DEFERRED until the external probe. There may
be no unsupported PASS. Run anti-selftests for unknown/duplicate/missing
AC IDs, wrong-phase evidence, forged subject hash, comparator masking,
fake terminality and omitted negative control. Historical AC evidence
defects remain a separate open item, not repaired by reusing this ACT's own
ledger.

## 6. C4 -- CLOSE and external terminality

Write only an accurate HANDOFF, roadmap append, one handoff-map entry,
exact produced authority/boundary ledger and an explicitly prospective
`c4/terminality-plan.txt`. Create one terminal CLOSE with correct
parseable trailers. Do not commit the external receipt or its asserted
result in advance.

After that unique CLOSE, run an external read-only probe, stored outside
the repository, with SHA and exact CLOSE HEAD/TREE binding. Probe must
independently verify:

1. five phase commits with valid trailers and exactly one CLOSE;
2. zero descendants carrying the same ACT id, zero tracked continuation
   unless distinctly classified;
3. selector-ON action actually consumed by `emitFile` on the required route;
4. C-only oracle contamination absent;
5. PolyC action mutation changed the artifact and legacy C decision
   mutation does not affect ON;
6. real object/executable differential conserved;
7. 16 baseline PolyC authorities conserved, actual delta not inflated;
8. 32 historical driver rows reconciled and route/global remainder counts
   distinct;
9. 24 NC, 50 AC with AC50 discharged by this receipt, not a committed
   forecast;
10. gates, F14, append-only and worktree/index hygiene PASS;
11. historical 50-AC correction unresolved and `-o-`/`-S` policy retained
    as explicit debt;
12. no push, no replace refs, no ACT-owned worktrees remaining.

If any fails, do not append a new ACT CLOSE or recast a failed receipt as
green. Report terminality failure with the external receipt and request a
separate forward-only correction. The original WP-001 family verdicts and
evidence remain immutable regardless of this ACT's outcome.

## 7. Required evidence and integration artifacts

```text
evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01/
  c0/
    entry-identity-and-history.tsv
    predecessor-and-codex-finding-crosswalk.tsv
    live-emitfile-main-driver-source-ranges.tsv
    real-cmake-build-object-link-baseline.tsv
    baseline-16-authorities.tsv
    32-row-and-required-route-branch-baseline.tsv
    test-prefix-and-conservation-baseline.tsv
    five-red-executions.tsv
    frozen-ac01-ac50.tsv
    frozen-nc01-nc24.tsv
  c1/
    selected-action-abi-and-domain.md
    output-request-ownership-and-lifetime.tsv
    required-route-branch-ownership-contract.tsv
    c-only-g0-build-and-link-provenance.tsv
    four-generation-producer-dag.tsv
    source-derived-argv-and-artifact-fixtures.tsv
    semantic-comparator-and-ordered-pair-roster.tsv
    mutation-and-dormancy-frozen-contract.tsv
  c2/
    production-action-consumption.tsv
    main-emitfile-disassembly-and-relocations.tsv
    selector-on-off-and-fail-closed-builds.tsv
    real-output-artifact-inspection.tsv
  c3/
    polyc-action-mutation.tsv
    polyc-status-mutation.tsv
    legacy-c-mutation-off-on.tsv
    poisoned-or-absent-subject.tsv
    generation-matrix-and-12-pairs.tsv
    comparator-adverse-selftests.tsv
    32-row-and-branch-reconciliation.tsv
    revised-wp001-actual-cost.tsv
    negative-control-executions.tsv
    independent-control-witness.tsv
    conservation-and-gates.tsv
    acceptance-ledger-ac01-ac50.tsv
    f14-and-factory-verification.tsv
  c4/
    terminality-plan.txt
```

The exact file list can be extended only inside this ACT's evidence
namespace, with provenance and a manifest. The external post-CLOSE receipt
resides outside the repository.

## 8. Negative controls NC01..NC24 -- frozen and reason-specific

Each control must execute a real adverse change in a disposable copy or
build and trigger only its named detector, with pristine and restored state
silent. For controls concerning Git metadata or receipts, use isolated
Git-object/fixture copies; never corrupt authoritative history.

| ID | Adverse change | Required detector reason |
|---|---|---|
| `NC01` | Wrong entry HEAD or TREE | `ENTRY_IDENTITY_MISMATCH` |
| `NC02` | Tamper with frozen WP-001 source/ABI contract | `FROZEN_CONTRACT_CHANGED` |
| `NC03` | Drop or duplicate a historical driver row ID | `DRIVER_ROW_ROSTER_MISMATCH` |
| `NC04` | Claim 17 authorities from unchanged 16-baseline decisions | `AUTHORITY_DOUBLE_COUNT` |
| `NC05` | `WpDriverSelectedAction` defined but unconsumed in production | `POLYC_ACTION_NOT_CONSUMED` |
| `NC06` | Restore the `emit_object` C policy in selector ON | `LEGACY_C_REQUIRED_ROUTE_POLICY_ACTIVE` |
| `NC07` | Selector OFF imports or calls the new action path | `G0_ORACLE_POLYC_CONTAMINATION` |
| `NC08` | Poison driver subject but allow fallback to C | `POLYC_DRIVER_FALLBACK_NOT_CLOSED` |
| `NC09` | Remove generated-object prerequisite from effective Make graph | `GENERATED_SUBJECT_PREREQUISITE_MISSING` |
| `NC10` | Lose CMake action selector/configuration flag | `CONFIGURATION_SELECTOR_NOT_APPLIED` |
| `NC11` | Alias G1/G2/G3 executables but claim distinct producers | `PRODUCER_ALIAS_FALSE_INDEPENDENCE` |
| `NC12` | Change emitted object to executable while retaining `.o` suffix | `ARTIFACT_KIND_MISMATCH` |
| `NC13` | Treat invalid action token as valid zero-valued action | `ACTION_STATUS_DOMAIN_COLLISION` |
| `NC14` | Accept stale/wrong-domain argv/action lifetime | `DRIVER_ABI_LIFETIME_BREACH` |
| `NC15` | Cross a PolyC stack frame with C `longjmp` | `RECOVERY_BOUNDARY_BREACH` |
| `NC16` | Delete the non-`-c` discriminator | `ALTERNATE_ACTION_CASE_MISSING` |
| `NC17` | PolyC mutation produces no live artifact/status effect | `POLYC_ACTION_CAUSAL_DORMANT` |
| `NC18` | Legacy C mutation still changes ON output | `LEGACY_C_POLICY_NOT_DORMANT` |
| `NC19` | Comparator ignores changed artifact class | `COMPARATOR_ARTIFACT_INSENSITIVE` |
| `NC20` | Comparator ignores changed stderr/exit status | `COMPARATOR_DIAGNOSTIC_INSENSITIVE` |
| `NC21` | Hidden C policy on required route labelled MECHANICAL | `C_POLICY_MISCLASSIFIED_AS_GLUE` |
| `NC22` | Whole-CLI `-o-`/`-S` guard omitted but claim exhaustive global inventory | `WHOLE_CLI_REMAINDER_UNDERCOUNT` |
| `NC23` | Trust a precomputed `binding_phase_valid` despite a later-phase witness | `EVIDENCE_PHASE_SELF_ATTESTATION` |
| `NC24` | Fabricate AC50 PASS in CLOSE before external receipt | `TERMINALITY_PREDECLARED_PASS` |

C3 must record for each ID: named adverse bytes/record, detector binary
SHA, exact stdout/stderr and exit, reason, pristine/adverse/restored
statuses, restoration SHA, and an independent recomputation of the
underlying invariant. A single generic FAIL token does not discharge a
control.

## 9. Mandatory acceptance criteria AC01..AC50

Every AC has an immutable stable ID and a concrete source, build or
execution witness. Exactly 50 unique rows. At C3, AC01-AC47 must PASS,
AC48-AC49 must be honestly `NOT_RUN` pending C4, and AC50 must be
`DEFERRED`. At C4, AC48-AC49 must PASS, while AC50 remains `DEFERRED`;
AC50 becomes PASS only after the external receipt. If an obligation is
logically impossible or unsupported, HALT -- do not mark it PASS using a
fabricated witness.

| ID | Phase | Mandatory predicate |
|---|---|---|
| `AC01` | C0 | Exact pinned branch/HEAD/TREE, clean classified state, zero replace refs. |
| `AC02` | C0 | Full WP-001 successor and Factory doctrine reread from immutable Git bytes. |
| `AC03` | C0 | Previous 16 live authorities independently reverified from production objects/link. |
| `AC04` | C0 | Exact source/body/digest of C `emitFile` and PolyC selected action frozen. |
| `AC05` | C0 | Historical 32 driver rows preserved with explicit required-route/global scope. |
| `AC06` | C0 | Real CMake-built G0 and ON entry executables with verified link configuration. |
| `AC07` | C0 | Real object-producing compile witness and alternate-output discriminator executed. |
| `AC08` | C0 | Legacy `args->emit_object` causality reproduced or source discrepancy HALTed. |
| `AC09` | C0 | Five REDs executed with exact intended detection and restoration. |
| `AC10` | C0 | Original parser/lexer/broad non-green baselines explicitly classified. |
| `AC11` | C1 | C1 selected-action ABI compiled and runtime-tested across PolyC/C. |
| `AC12` | C1 | Action enum/domain distinguishes valid zero, absent, unknown and errors. |
| `AC13` | C1 | PolyC-selected action is causally distinct from C `emit_object` request field. |
| `AC14` | C1 | Mechanical C executor duties enumerated without duplicated output-selection policy. |
| `AC15` | C1 | Host request/argv ownership and lifetime proven with adverse tests. |
| `AC16` | C1 | No unsafe cross-frame recovery or undocumented mutable host state. |
| `AC17` | C1 | Genuine selector-OFF C-only driver oracle excludes the action subject. |
| `AC18` | C1 | Actual G0-G3 producer binary identities and target flags frozen. |
| `AC19` | C1 | Source-derived positive and negative CLI fixtures with explicit artifact types. |
| `AC20` | C1 | Twelve ordered generation comparisons and comparator normalization frozen. |
| `AC21` | C1 | Comparator sensitivity proven for object/executable, status, stderr and content. |
| `AC22` | C1 | Four causal/dormancy/poison experiments frozen with distinct sources and outcomes. |
| `AC23` | C1 | Required-route ownership table identifies every reachable C policy branch. |
| `AC24` | C1 | All C1 evidence committed before any production implementation. |
| `AC25` | C2 | Production `emitFile` consumes a PolyC-selected action on the required route. |
| `AC26` | C2 | C no longer independently interprets `args->emit_object` on selector ON. |
| `AC27` | C2 | Retained C executor is source- and object-proven mechanical only. |
| `AC28` | C2 | Selector-OFF still reproduces the genuine original C-driver behavior. |
| `AC29` | C2 | Production object/link/callsite verification proves actual action consumption. |
| `AC30` | C2 | Missing/stale/incorrect subject or selector fails build closed. |
| `AC31` | C2 | Required `-c` fixture emits a valid inspected target object. |
| `AC32` | C2 | Discriminating alternate fixture emits the expected alternate artifact. |
| `AC33` | C2 | Existing 16 authorities stay linked, live and conserved. |
| `AC34` | C3 | Twelve ordered G0-G3 semantic comparisons have zero unexplained differences. |
| `AC35` | C3 | Producer/source/object hashes independently joined and qualified. |
| `AC36` | C3 | PolyC action mutation changes real production compiler behavior as predicted. |
| `AC37` | C3 | Legacy C decision mutation is live in G0 and dormant in ON. |
| `AC38` | C3 | Poison/removal of PolyC subject proves fail-closed production dependence. |
| `AC39` | C3 | Mutations are independently scoped and source/object restored honestly. |
| `AC40` | C3 | All required-route branches classified; no C semantic or unproven remainder. |
| `AC41` | C3 | Whole-CLI retained C decisions reported separately without false completion. |
| `AC42` | C3 | All 32 historical rows reconciled, no fictional authority delta. |
| `AC43` | C3 | WP-001 full ACT identity cost and Factory-valid lifecycle count distinct. |
| `AC44` | C3 | Canonical new driver regression tests execute and cover both output classes. |
| `AC45` | C3 | 24/24 reason-specific negative controls and verifier anti-controls sensitive. |
| `AC46` | C3 | Parser and direct lexer identities conserved; historical non-greens honest. |
| `AC47` | C3 | gate-fast, serialized gate-push, append-only and F14 pass. |
| `AC48` | C4 | Unique terminal CLOSE, five correctly trailered phase commits, no ACT continuation. |
| `AC49` | C4 | HANDOFF/map/roadmap accurately distinguish route PASS, global remainder and historical AC debt; no pre-recorded receipt. |
| `AC50` | POST-CLOSE | Independent read-only external receipt binds CLOSE HEAD/TREE, discharges final ACT terminality and confirms zero push/replace refs/worktrees. |

Potential contract conflict: the original WP-001 ACT's AC49/AC50 labels had
a self-referential chronological structure (a prospective external receipt
in a C4 criterion). This correction's ledger is independent and uses
`AC50=POST-CLOSE`. The old numbering and adjudications remain immutable; do
not silently claim this new ledger repairs the historical one.

## 10. Explicit residue, successor and reporting constraints

A correctly completed required-route correction must not conceal any of
the following:

- `src/main.c::main` `print_tokens` -- independently C-owned off the
  required compile route.
- `src/main.c` `compile_to_ast` -- shared decision / insufficient
  separation, pending a separate source/object trace.
- `src/cli.c::cliParseArgsPolyC` `-o-`/`-S` incompatibility guard -- C
  policy on a whole-CLI path, omitted from the earlier global inventory.
- Historical boundary-qualification `CORRECTION01`: 32 alternate-witness
  proofs are not independently established; at least four cited candidates
  violate the frozen phase rule (AC01, AC03, AC04, AC09). The current ACT
  must not borrow their self-attestation flags.
- Historical predicate drift count of nine is a lexical screen unless
  semantically adjudicated; do not label it nine proven semantic drifts.
- Five WP-001 family ACT identities were spent (parent plus four
  corrections), but not all were valid completed Factory lifecycles; add
  qualifications and subsequent qualification ACT costs.
- Twelve historical F-NO-PYTHON violations, unavailable F-POLYC-TOOLS
  checker, historical broad LEXER07 failures, cross-target environment
  prefix, shared assembler temporary race and parallel Make race.

The proposed separate evidence successor, not authorized here, is:

`ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-EVIDENCE-CORRECTION02` -- independently
re-adjudicate the 50 historical criteria against immutable phase-specific
evidence and extend the whole-CLI ownership inventory. Do not start it
under this ACT. Likewise WP-002 is not authorized until WP-001's
required-route completion and governing evidence criteria have been
qualified.

Final rule: A PASS requires genuine PolyC semantic authority over emission
action, not a decorative symbol, not mere consumption of a pre-existing C
flag, and not a green test suite with the wrong artifact type. The
retained C engine is allowed for the P0 precursor but must be
transparently named `C_SEMANTIC_ENGINE_RETAINED`; M2 is not achieved.

## 11. Methodological references (nonbinding)

- Git commit trailers: <https://git-scm.com/docs/git-interpret-trailers>
- Git worktree isolation: <https://git-scm.com/docs/git-worktree>
- GNU Make read-time prerequisite expansion: <https://www.gnu.org/software/make/manual/html_node/Reading-Makefiles.html>
- CMake generated output dependencies: <https://cmake.org/cmake/help/latest/command/add_custom_command.html>

Repository source and Factory doctrine, not external documentation,
govern the final technical and historical obligations.
