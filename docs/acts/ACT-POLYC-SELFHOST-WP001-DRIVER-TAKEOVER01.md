# ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01

Factory-Version: 2
Lifecycle: AUTHORIZATION ONLY -- NOT an execution report or a claim of PASS

**Title:** WP-001 compiler-driver semantic takeover

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** IMPLEMENTATION / SELFHOST / WP-001 / PRODUCTION-SEMANTIC-AUTHORITY

**Predecessor:** ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03

NOTE ON THE PREDECESSOR. CORRECTION03 has a reported independent
`C4_READY=YES` but **no terminal CLOSE**. Its last commit carries
`ACT-Phase: EVIDENCE`. This ACT therefore does NOT inherit a verdict
CORRECTION03 never recorded, does NOT claim CORRECTION03 was closed, and
does NOT reopen the historical governance-reconciliation project. The
Factory-v2 range validator evaluates each ACT's own contiguous range
independently; CORRECTION03's open EVIDENCE phase does not mechanically
block a new, differently-named ACT from opening. That fact is MEASURED,
not assumed -- see `c0/factory-validator-entry.tsv`.

**Affected work package:** WP-001, selected by
ACT-POLYC-SELFHOST-M2-CRITICAL-PATH-REBASE01.

**Production semantic changes:** AUTHORIZED (scoped) -- the remaining
driver-level semantic decisions in `src/main.c` and `src/cli.c`. The
already-migrated artifact-class emission decision is NOT re-opened.

**IR / ABI / LLVM authorization:** SCOPED -- one bounded addition to the
existing PolyC/C driver action seam. No IR, no LLVM backend, no language
semantics.

---

## 0. Mission and binding outcome

Transfer the **remaining** WP-001 compiler-driver semantic authority from
C to the compiled PolyC driver, using a coherent driver subsystem rather
than individually migrated decisions.

The production compiler must continue producing the same artifacts,
diagnostics and runtime behavior.

The primary deliverable is **working PolyC compiler-driver code linked
into the real production compiler**.

---

## 1. The measured gap

At entry, the compiled PolyC driver
(`tools/bootstrap/selfhost-driver-wp001.HC`) owns:

- option recognition (`WpDriverClassifyOption`),
- value location and arity (`WpDriverValueArgIndex`, `WpDriverValueOffset`),
- the CliArgs field selection (`WpDriverOptionField`),
- the whole-argv action selection (`WpDriverSelectAction`),
- the status / error mapping (`WpDriverMapStatus`, `WpDriverDecide`),
- the artifact-class emission decision (`WpDriverSelectedEmission`).

The predecessor `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`
recorded the residual boundary finding:

```text
BR_EMITFILE_EMIT_OBJECT = transferred to PolyC
BR_MAIN_PRINT_TOKENS   = C-owned outside required route
BR_MAIN_COMPILE_TO_AST = SHARED_OR_UNPROVEN
```

The live source shows the residual is WIDER than those two rows:
`main()` in `src/main.c` independently selects the whole-CLI route with
C-owned `if` statements over `args.*` fields, for the
assemble, repl, print-tokens, transpile, print-AST, dump-IR,
dump-IR-pooled, CFG, JIT, emit-LLVM and compile routes.

The decisive MEASUREMENT at entry is that the production `main.c` object
imports `_WpDriverSelectedEmission` but **does not import**
`_WpDriverSelectedAction`. The PolyC whole-argv action is computed and
never consumed, so the route selection remains C-authoritative on the
whole-CLI surface.

---

## 2. Target architecture

```text
             Raw argv / environment
                      |
                      v
             C lexical projection
            (no semantic policy)
                      |
                      v
            Compiled PolyC driver
             option interpretation
             precedence resolution
             compilation planning
             validation/status policy
                      |
                      v
                 DriverPlan
                      |
                      v
              C host executor
              (mechanical only)
```

The intended ownership boundary is that the compiled PolyC component
owns the driver's semantic decisions, and the C host mechanically
executes the plan it is given.

---

## 3. Scope

### Authorized production modifications

- `src/main.c`
- `src/cli.c`
- `src/selfhost-driver-wp001.h` (existing WP-001 driver header)
- `src/selfhost-driver-wp001.c` (existing WP-001 driver adapter)
- `tools/bootstrap/selfhost-driver-wp001.HC`
- `src/CMakeLists.txt`
- `Makefile`

### Authorized verification modifications

- WP-001-specific tests.
- One bounded production differential runner.
- Existing related quality utilities when required.
- This ACT's own evidence.
- Minimal required ACT/HANDOFF/ROADMAP registration.

### forbidden

- No CORRECTION03 evidence beautification or historical rewriting.
- No new governance or forecast ACT.
- No unrelated parser, lexer, optimizer or backend migrations.
- No general-purpose Mach-O validator development.
- No rewriting existing compiler components merely to increase PolyC LOC.
- No new Python, Ansible or external dependencies.
- No artificial subdivision of WP-001 into one ACT per predicate.
- No premature whole-compiler self-hosting claim.

---

## 4. Completion criteria

WP01-WP16 as stated in the mission brief. The hard completion rule is:

```text
WP001_FULL_AUTHORITY=YES
```

permitted only when WP01-WP16 hold. If some driver branches remain
C-authoritative, the exact remaining decisions and their impact must be
reported instead.

---

## 5. Factory execution model

The preferred engineering sequence is RED, IMPL, EVIDENCE, CLOSE.
Additional IMPL commits are permitted for coherent driver groups.

All ACT commits carry valid `ACT:` / `ACT-Phase:` trailers. Git remains
append-only. The still-open CORRECTION03 is NOT claimed as historically
closed.
