# ACT-POLYC-TOOLING-MIGRATE-GEP01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01
ACT-Phase: RED

**Title:** First PolyC-native quality harness migration —
replace `llvm-gep01-test.sh` logic with PolyC while preserving
the complete 30-check GEP01 oracle

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Predecessors:**
- ACT-POLYC-TOOLING-RUNTIME01 correction chain — usable / GREEN
- ACT-POLYC-TOOLING-SHELL-INVENTORY01-CORRECTION01 — CLOSED PASS
- ACT-POLYC-LLVM-GEP01 — CLOSED PASS

**Class:** RED → IMPL → EVIDENCE → CLOSE

**Primary production seam:** tooling/test harness only

**Compiler semantic changes:** FORBIDDEN
**Parser/typechecker changes:** FORBIDDEN
**Neutral-IR changes:** FORBIDDEN
**LLVM backend changes:** FORBIDDEN
**ABI changes:** FORBIDDEN
**Factory-doctrine changes:** FORBIDDEN
**New Bash logic >50 LOC:** FORBIDDEN
**Historical evidence mutation:** FORBIDDEN

---

# 0. Mission

Migrate the complete executable logic of:

    scripts/quality/llvm-gep01-test.sh

from Bash into PolyC.

The existing harness is approximately 232 physical LOC and
currently closes with:

    GEP01_PASS=30
    GEP01_FAIL=0
    STATUS=PASS

The migrated harness MUST preserve the same semantic oracle.

The preferred final architecture is:

    make / caller
        ↓
    <=50 LOC compatibility shell wrapper
        ↓
    build/quality/llvm-gep01-test
        ↓
    tools/quality/llvm-gep01-test.HC
        ↓
    src/holyc-lib/tooling.HC
        ↓
    direct argv:
      hcc
      llvm-as
      opt

NO `/bin/sh -c`.
NO shell parsing.
NO migration logic remaining in Bash.

If repository call sites permit eliminating the shell entry
point entirely without widening scope, zero Bash LOC is BETTER.

Success means:

    OLD SHELL LOGIC LOC ≈ 232
    NEW SHELL LOGIC LOC <= 50
    POLYC OWNS THE TEST ORACLE
    GEP01_PASS = 30
    GEP01_FAIL = 0
    STATUS = PASS

and the Track-B board moves to:

    ACT-POLYC-TOOLING-SHELL-BUDGET01

This ACT is the first real shell-debt repayment, not another
tooling-runtime or Factory-doctrine ACT.

---

# 1. Board invariant

This ACT MUST advance the board in one of two mechanically
defined ways.

## PASS path

If the existing TOOLING-RUNTIME01 substrate is sufficient:

    MIGRATE-GEP01 = CLOSED PASS
    llvm-gep01 Bash debt reduced to <=50 LOC
    NEXT = ACT-POLYC-TOOLING-SHELL-BUDGET01

## HALT path

If and only if the complete 30-check migration reveals a
genuinely missing reusable runtime primitive:

    MIGRATE-GEP01 = HALT_TOOLING_RUNTIME_GAP

The HALT packet MUST:

1. name exactly ONE missing primitive;
2. include the smallest reproducer;
3. prove that implementing the primitive locally in the
   harness would duplicate host-tooling logic rather than
   merely be an ordinary test helper;
4. name exactly ONE successor ACT:
      ACT-POLYC-TOOLING-RUNTIME02-<PRIMITIVE>
5. prohibit any Factory/doctrine work.

A vague "migration is hard" HALT is forbidden.

The intention is that the current known substrate should
PASS without this path.



# 2. Frozen baseline (C1 captured)

Before modifying the Bash harness, C1 captured the current
authoritative behavior. The captured files are at:

    evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/

Frozen result:

    LEGACY_RC = 0
    LEGACY_GEP01_PASS = 30
    LEGACY_GEP01_FAIL = 0
    LEGACY_STATUS = PASS
    LEGACY_SHELL_LOC = 232
    LEGACY_ROW_COUNT = 30
    LEGACY_PASS_COUNT = 30
    LEGACY_FAIL_COUNT = 0

The captured test sections remain authoritative:

1. toolchain
2. positive constant-zero fixture — Read0
3. positive constant-nonzero fixture — Read2
4. positive dynamic-index fixture — ReadAt
5. B0 multi-read fixture — TwoDigits
6. LLVM textual GEP structure
7. independent llvm-as
8. independent opt --passes=verify
9. no ptrtoint/inttoptr address arithmetic
10. no unauthorized `getelementptr inbounds`
11. negative non-I8 boundary — ReadI64/i64idx
12. capability status
13. sibling IR_GEP rejection
14. sibling IR_LEA rejection
15. determinism
16. summary

The migration MUST NOT redefine this oracle merely to make
the port convenient.

---

# 3. C1 RED — freeze the legacy oracle (executed)

C1 evidence is at:

    evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c1/

Files captured:

    legacy.stdout.txt          merged stdout+stderr of fresh
                               `bash scripts/quality/
                                llvm-gep01-test.sh` run
    legacy.stderr.txt          (empty, as legacy writes to
                                stdout)
    legacy.rc.txt              process exit code (0)
    legacy-source.txt          verbatim copy of the pre-
                               migration bash source, with
                               a `.txt` suffix so the shell-
                               LOC ratchet does not mistake
                               it for executable script
    legacy-loc.txt             `wc -l` of legacy harness
                               (232)
    legacy-toolchain.txt       hcc, llvm-as, opt version
                               snapshot
    legacy-rows-raw.txt        full output of llvm-cap-table-
                               verifier.py captured for
                               capability-status rows
    oracle-matrix.tsv          exactly 30 logical PASS rows
                               (one per legacy stdout line)
    environment-freeze.txt     HCC / HCC_INSTALL_DIR /
                               LLVM_AS / LLVM_OPT contract
    c1-required-result.txt     machine-readable C1 freeze
                               summary

## C1 row freeze

`oracle-matrix.tsv` contains exactly 30 rows, columns:

    ordinal
    section
    assertion_id
    legacy_result
    observable

Each row maps 1:1 to a PASS line in the captured
`legacy.stdout.txt`; row N observable quotes the legacy
stdout line number for review.

---


---




# 4. Frozen migration architecture

Canonical new implementation:

    tools/quality/llvm-gep01-test.HC

It MUST use:

    #include "../../src/holyc-lib/tooling.HC"

Host operations MUST go through the existing tooling runtime:

    SpawnAndCapture
    TmpFile
    FileExists
    FileRead
    FileWrite
    Contains
    WaitDecode

Local pure helpers are allowed for test-domain logic such as:

    CountSubstring()
    ExpectContains()
    ExpectNotContains()
    ExpectRc()
    ExpectFileEqual()
    VerdictPass()
    VerdictFail()

Those helpers MUST remain local to the harness unless a
mechanical second consumer already exists.

Do NOT expand `tooling.HC` merely to avoid writing a
10-line pure helper.

---

# 5. No-shell-execution invariant

The PolyC harness MUST invoke every external program via
direct argv.

Required tools:

    hcc
    llvm-as
    opt
    python3 (only for llvm-cap-table-verifier.py — host tool,
             not a shell)

Forbidden from the PolyC migration path:

    /bin/sh -c
    sh -c
    bash -c
    system()
    popen()
    System()
    Sh()
    Shlurp()
    construction of a command string that is then reparsed
    by a shell

This inherits TOOLING-RUNTIME01's direct-argv doctrine.

---

# 6. Scratch/evidence isolation

Ordinary execution of the migrated GEP harness MUST NOT write
into any historical GEP01 evidence directory.

In particular, this legacy path:

    evidence/ACT-POLYC-LLVM-GEP01/c3/_tmp

must no longer be the ordinary scratch destination.

Use one of:

    build/quality/llvm-gep01/<unique-run>/
    /tmp/polyc-gep01-<unique>/

All transient:

    .ll
    .bc
    .err
    second-run determinism outputs
    native/runtime scratch

must live there.

On successful completion: scratch artifacts may be removed.
On failure: retaining the scratch directory is permitted if
its path is printed clearly for debugging.

The test must never mutate closed GEP01 evidence.

---

# 7. PolyC verdict model

Use one aggregate verdict object:

    typedef struct {
        I64 pass;
        I64 fail;
    } GepVerdict;

Every one of the 30 frozen assertions MUST invoke exactly one
of:

    GepPass(...)
    GepFail(...)

At the end:

    GEP01_PASS=<pass>
    GEP01_FAIL=<fail>

and:

    if fail == 0:
        STATUS=PASS
        exit 0
    else:
        STATUS=FAIL
        exit 1

Toolchain/configuration unavailability MUST preserve the legacy
distinct setup-failure behaviour (rc=2). Do not silently
convert setup failure into `GEP01_FAIL=1`.

---

# 8. False-GREEN control

The new harness MUST provide a test-only seeded-failure mode:

    --mode=fail

Normal:

    GEP01_PASS=30
    GEP01_FAIL=0
    STATUS=PASS
    rc=0

Seeded failure:

    at least one normal assertion result is forcibly converted
    to FAIL after its observation is obtained

Required:

    GEP01_FAIL >= 1
    STATUS=FAIL
    rc=1

The seeded mode MUST execute production verdict code; it may
not be a separate fake exit path.

---




# 9. Exact GEP01 oracle to preserve

C2 implementation MUST cover the complete C1-frozen 30-row
oracle (rows 01..30 in `c1/oracle-matrix.tsv`).

## Toolchain (row 01)

Prove executable availability / invocability for hcc,
llvm-as, opt through direct process execution.

## Read0 (row 02)

Compile `src/tests/llvm-gep01/read0.HC`; require
`load i8, ptr %` in emitted `.ll`.

## Read2 (row 03)

Compile `src/tests/llvm-gep01/read2.HC`; require
`getelementptr i8, ptr %<n>, i64 2` AND `load i8, ptr %`.

## ReadAt (rows 04, 05)

Compile `src/tests/llvm-gep01/readat.HC`; require

    getelementptr i8, ptr %<n>, i64 %<n>
    load i8, ptr %

and that hcc stderr contains `shape_dependent=N` with N >= 1.

## TwoDigits (row 06)

Compile `src/tests/llvm-gep01/twodigits.HC`; require

    >=2 occurrences of `load i8, ptr %`
    >=1 occurrence of `getelementptr i8`

## LLVM textual GEP structure (rows 07, 08)

readat emitted `.ll` must contain the closure-critical GEP
shape (row 07) and the load-from-GEP address shape (row 08).

## Independent llvm-as (rows 09..12)

Each positive `.ll` (read0, read2, read-at, b0-multiread) must
be accepted by `llvm-as`.

## Independent opt --passes=verify (rows 13..16)

Each `.bc` must be accepted by `opt --passes=verify`.

## Pointer-address arithmetic fence (rows 17..20)

Each positive `.ll` must contain zero `ptrtoint`/`inttoptr`.

## `inbounds` fence (rows 21..24)

Each positive `.ll` must contain zero
`getelementptr inbounds`.

## Non-I8 negative control (row 25)

Compile `src/tests/llvm-gep01/i64idx.HC`. Required:

    rejected
    diagnostic contains
      LLVM_BACKEND_UNSUPPORTED_POINTER.*scale=8
      OR IR_LOAD_DEREF with non-zero disp or scaled-index

No `.ll` success output is allowed for the forbidden shape.

## Capability status (rows 26..28)

Run `python3 scripts/quality/llvm-cap-table-verifier.py`;
require the output to show:

    IR_GEP  ... (REJECTED)
    IR_LEA  ... (REJECTED)
    IR_IADD ... (SUPPORTED)

## Determinism (rows 29, 30)

For each of `src/tests/llvm-gep01/readat.HC` and
`src/tests/llvm-gep01/twodigits.HC`:

    hcc --emit-llvm fixture.1.ll
    hcc --emit-llvm fixture.2.ll
    expect byte-identical outputs

Use PolyC file reads / length + byte comparison. Do not shell
out to `cmp` merely because the old Bash did.

---

# 10. Runtime parity already proven, now extended

TOOLING-RUNTIME01 already proved a five-assertion PolyC slice
for `readat.HC`:

    hcc rc == 0
    contains getelementptr i8
    !contains getelementptr inbounds
    !contains ptrtoint
    !contains inttoptr

MIGRATE-GEP01 MUST expand that slice to the complete 30-row
oracle.

The existing five rows therefore serve as the seed, not as
sufficient closure evidence.

---




# 11. C2 IMPL — dual implementation (deferred to C2 commit)

C2 introduces:

    tools/quality/llvm-gep01-test.HC

and any build wiring strictly necessary to compile it.

During C2:

    old Bash harness remains unchanged and authoritative.

Run BOTH:

    legacy Bash harness
    new PolyC harness

from the same candidate tree and same toolchain.

Capture under:

    evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/c2/

Required files:

    bash.stdout.txt
    bash.stderr.txt
    bash.rc.txt
    polyc.stdout.txt
    polyc.stderr.txt
    polyc.rc.txt
    parity-matrix.tsv
    verdict-negative-control.txt
    scratch-isolation.txt
    direct-argv-audit.txt
    production-delta.txt
    patch-hygiene.txt

## C2 parity rule

PASS requires:

    Bash:
      pass=30 fail=0 status=PASS rc=0

    PolyC:
      pass=30 fail=0 status=PASS rc=0

and every row in C1's `oracle-matrix.tsv` must have a
corresponding PolyC PASS.

Aggregate 30/30 without row correspondence is NOT enough.

Required:

    PARITY_ROWS=30
    PARITY_MATCH=30
    PARITY_MISMATCH=0

---

# 12. Runtime-gap policy

C2 may add pure helpers inside:

    tools/quality/llvm-gep01-test.HC

without opening another ACT.

Examples:

    substring counting
    bytewise buffer comparison
    formatting test row names
    path concatenation
    verdict aggregation

C2 MUST NOT modify:

    src/holyc-lib/tooling.HC
    src/holyc-lib/errno_shim.c
    src/CMakeLists.txt

unless a genuinely reusable missing host primitive is proven.

If such a primitive is required:

    HALT_TOOLING_RUNTIME_GAP

with the one-successor rule from §1.

This avoids silently reopening the already-closed runtime
chain.

---




# 13. C3 CUTOVER — repay the Bash debt (deferred)

C3 occurs only after C2 parity is fully GREEN.

Replace:

    scripts/quality/llvm-gep01-test.sh

with one of these outcomes, in priority order.

## Outcome A — preferred

Delete the shell script entirely.

Wire callers / Makefile directly to the PolyC harness.

Required shell LOC reduction: 232 -> 0.

## Outcome B — compatibility wrapper

Keep the same path but reduce it to <=50 physical LOC.

The wrapper may ONLY:

    set -eu
    locate repository root
    resolve/build the PolyC harness if necessary
    exec the PolyC harness
    forward argv
    forward exit status

It MUST NOT contain:

    GEP assertions
    grep logic
    LLVM textual checks
    fixture loops
    capability interpretation
    pass/fail aggregation
    determinism logic

Required: wrapper LOC <= 50 (target 10-25 LOC).

All substantive test logic MUST live in PolyC.

---

# 14. Wrapper parity (only if Outcome B used)

Wrapper invocation must produce identical rc, GEP01_PASS,
GEP01_FAIL, STATUS to direct PolyC invocation.

---

# 15. No historical evidence mutation

This ACT MUST NOT modify any file under:

    evidence/ACT-POLYC-LLVM-GEP01/
    evidence/ACT-POLYC-TOOLING-RUNTIME01/
    evidence/ACT-POLYC-TOOLING-SHELL-INVENTORY01/

All new evidence belongs under:

    evidence/ACT-POLYC-TOOLING-MIGRATE-GEP01/

The strict F14 successor-packet rule applies.

---

# 16. No SHA-of-self

No ACT document, evidence file, closure summary, or ROADMAP
entry created by this ACT may predict the SHA of the commit
containing it.

---

# 17. Shell-debt accounting

C1 freezes:

    pre_shell_file_count = 27 (per inventory.sh baseline)
    pre_total_shell_loc  = 6131 (per inventory.sh baseline)
    pre_gep_shell_loc    = 232

C3 records:

    post_shell_file_count
    post_total_shell_loc
    post_gep_shell_loc

Required:

    post_gep_shell_loc <= 50
    post_total_shell_loc < pre_total_shell_loc

---

# 18. Shell ratchet

Required: shell-loc-gate = PASS.

No new `.sh` file may exceed 50 LOC.
No unrelated grandfathered shell file may grow.
`llvm-gep01-test.sh` is allowed only to shrink.

---

# 19. Evidence-isolation invariant

The migrated harness must use only scratch space during
ordinary execution. Historical GEP01 evidence MUST remain
untouched.

---

# 20. Build/rebuild contract

Do not depend on a stale PolyC harness binary.

The ordinary GEP target must ensure the executable being run
corresponds to the current:

    tools/quality/llvm-gep01-test.HC
    src/holyc-lib/tooling.HC
    linked libtos

---




# 21. Required conservation gates (deferred to C3/C4)

After C3 cutover, freshly run:

    make clean
    make
    make llvm-all

    llvm-gep01-test (PolyC) -> 30/0 PASS
    llvm-byte-memory01      -> 37/0 PASS
    llvm-intops01           -> 4/0 PASS
    llvm-spike              -> 18/0 PASS (HCC_INSTALL_DIR)
    ir-return-slot-fwd01    -> 6/0 PASS
    llvm-cap-table-verifier -> PASS
    shell-loc-gate          -> PASS
    factory-append-only     -> PASS
    gate-fast               -> PASS

If `harness-evidence-isolation-test` is runnable with the
current host/install prefix: PASS; else
ENVIRONMENTALLY_UNAVAILABLE.

---

# 22. Seeded failure gate (deferred to C3)

After C3 cutover, execute the production entry point in
failure mode.

Required: rc=1, GEP01_FAIL>=1, STATUS=FAIL.

---

# 23. Direct-argv source audit (deferred to C3)

C3 evidence must mechanically inspect the migrated harness.
Required forbidden-count = 0 for:

    "/bin/sh"
    "sh -c"
    "bash -c"
    "system("
    "popen("
    "System("
    "Sh("
    "Shlurp("

except comments that explicitly discuss the prohibition.

---

# 24. Patch hygiene

For EACH new ACT commit:

    git diff --check <parent>..<commit>
      rc=0

Required: newly introduced findings = 0.

---

# 25. Acceptance criteria (executed status noted)

AC01..AC45 are the full set from the migration charter.
Status after C1:

    AC01  Legacy GEP harness baseline is freshly reproduced:
          30/0 PASS, rc=0.                        PASS
    AC02  Legacy harness source is frozen as `.txt`
          evidence; no new executable shell evidence
          file is created.                         PASS
    AC03  C1 freezes exactly 30 logical assertion rows.
                                                  PASS
    AC04  New canonical harness exists as PolyC source.
                                                DEFERRED
    AC05..AC45                                  DEFERRED

---

# 26. HALT taxonomy (carried forward)

HALT_BASELINE_NOT_GREEN
HALT_ORACLE_PARITY_MISMATCH
HALT_TOOLING_RUNTIME_GAP
HALT_VERDICT_CHANNEL_FALSE_GREEN
HALT_EVIDENCE_MUTATION
HALT_STALE_BINARY_FALSE_GREEN
HALT_MIGRATION_NOT_CONSUMED
HALT_SHELL_RATCHET_REGRESSION
HALT_CONSERVATION_GATE_REGRESSION
HALT_SCOPE_EXPANSION_REQUIRED

---

# 27. Explicitly forbidden scope (carried forward)

This ACT MUST NOT:

- modify compiler semantics;
- fix PARSER-TERNARY-HANG01;
- implement Linux tooling-runtime support;
- change rc=127 exec ambiguity;
- change SpawnAndCapture semantics;
- reopen EINTR/poll/waitpid work;
- modify Factory Git identity doctrine;
- implement CLOSE-CARDINALITY01;
- change LLVM GEP semantics;
- widen GEP01 capability;
- rewrite GEP01 fixtures merely to simplify migration;
- migrate another shell harness;
- create SHELL-BUDGET01 early;
- mutate any historical evidence packet;
- "clean up" historical whitespace;
- commit generated test binaries as evidence.

One harness. One migration. One board step.

---

# 28. Commit topology

C1 RED       (this commit) — ACT document + frozen legacy
                       baseline + 30-row oracle matrix +
                       environment freeze + no production
                       changes.
C2 IMPL      (deferred)   — PolyC harness + build wiring +
                       dual-run Bash/PolyC parity +
                       seeded failure proof.
C3 EVIDENCE  (deferred)   — delete Bash harness OR shrink
                       to <=50 LOC + switch canonical
                       callers + conservation gates.
C4 CLOSE     (deferred)   — ROADMAP update + acceptance
                       matrix + residue + final fresh
                       gate run + verdict.

Cardinality-1 CLOSE: exactly ONE commit for this ACT may
carry `ACT-Phase: CLOSE` (and `ACT-Verdict: PASS`).

---

# 29. Commit trailer contract

C1 (this commit):

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01
    ACT-Phase: RED

C2:

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01
    ACT-Phase: IMPL

C3:

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01
    ACT-Phase: EVIDENCE

C4:

    ACT: ACT-POLYC-TOOLING-MIGRATE-GEP01
    ACT-Phase: CLOSE
    ACT-Verdict: PASS

No SHA-of-self fields.

---

# 30. Required closure report (deferred to C4)

Will contain:

    VERDICT
    MIGRATION (LOC counts, paths)
    ORACLE (30/30, parity matrix)
    FALSE-GREEN CONTROL (seeded failure)
    DIRECT ARGV (audit results)
    EVIDENCE ISOLATION (historical GEP01 evidence)
    BUILD FRESHNESS (no stale binaries)
    CONSERVATION (eight gates)
    PATCH HYGIENE (new findings)
    WORKTREE (clean)
    RESIDUE (P0/P1/P2)
    BOARD (next ACT)

---

# 31. Closure rule

PASS only if BOTH:

    FUNCTIONAL_EQUIVALENCE = TRUE
    SHELL_DEBT_REDUCTION   = TRUE

A PolyC harness that merely coexists with the old 232-line
Bash implementation does NOT close this ACT.

---

# 32. Next ACT

On PASS: NEXT = ACT-POLYC-TOOLING-SHELL-BUDGET01.

Do NOT begin SHELL-BUDGET01 in this turn.
HARD STOP after C4 CLOSE.
