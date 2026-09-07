# ACT-POLYC-LLVM-SPIKE01

**Title:** First Backend-Neutral IR → Verified LLVM IR Lowering

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-IR-BOUNDARY01`

**Required predecessor verdict:** `PASS_WITH_NEXT_ACT_DECISION`

**Expected entry HEAD:** `0996ce4c304abc125d8e7562dd1ef615b142cabd`

**VERDICT:** `HALT_PREDECESSOR_BASELINE_RED` (AND `HALT_LLVM_TOOLCHAIN_UNAVAILABLE`)

**Halt chain:** predecessor ACT closed `PASS_WITH_NEXT_ACT_DECISION`, but two
independent, simultaneously-true halt conditions were encountered during
ACT execution. Both are recorded below; the binding halt is the
predecessor-baseline regression (which alone would halt the ACT even on a
fully toolchained machine).

---

# 0. Mission (preserved for context)

Implement the smallest real LLVM backend slice that consumes the
backend-neutral PolyC IR established by `ACT-POLYC-IR-BOUNDARY01` and emits
valid, verifier-clean textual LLVM IR.

The spike SHALL NOT generate native code, invoke ORC, invoke lli, invoke
clang to execute emitted IR, replace AOT, replace JIT, modify REPL
execution, run LLVM optimization pipelines, or attempt full-language
support.

---

# 1. Halt conditions encountered

Two independent halt conditions were met during execution of this ACT.
Both are recorded. ACT §6 says "If not: HALT_PREDECESSOR_BASELINE_RED. No
LLVM implementation begins." This halt supersedes the LLVM-toolchain halt
chronologically: the toolchain situation was confirmed first; the
predecessor-baseline regression was confirmed immediately after and is the
binding halt.

## 1.1 Halt #1 (binding): HALT_PREDECESSOR_BASELINE_RED

The ACT §6 requirement

```
AOT=90/90
JIT=90/90
LSP=43/43
CORPUS=16/16
```

is **NOT met at the entry HEAD `0996ce4`**.

Reproduction (host: Apple M3 Max arm64, Apple clang 15.0.0):

```
$ ./hcc --target=aarch64-apple-darwin --install-dir=<prefix> -S src/tests/47_struct_abi.HC -o /tmp/47.s
ERROR: ir-regalloc: no slot for var.id=95 kind=4
```

Three further tests fail with the same regalloc error pattern:

```
AOT PASSED: 86
AOT FAILED: 4

Failed tests:
  Test - indirect struct return C interop: FAILED: 1/3
  Failed to compile: 47_struct_abi.HC
  Failed to compile: 48_arg_overflow.HC
  Failed to compile: 58_struct_return.HC
```

Raw evidence:
- `evidence/llvmspike01/unit_0996ce4.log`
- `evidence/llvmspike01/unit_0996ce4_summary.txt`
- `evidence/llvmspike01/regalloc_error_pattern.txt`
- `evidence/llvmspike01/entry_head_47_failure.txt`

The same tests pass cleanly on the predecessor ACT's pre-refactor commit
`60811e6` (`docs(strip trailing whitespace from captured evidence)`):

```
$ git checkout 60811e6 && make clean && make
...
$ ./hcc --target=aarch64-apple-darwin --install-dir=<prefix> -S src/tests/47_struct_abi.HC -o /tmp/47.s
$ echo $?
0
```

On `60811e6` the full predecessor baseline reproduces:

```
AOT PASSED: 90
JIT PASSED: 90
LSP: 43/43 passed
CORPUS: 17/17 items, 16 byte-identical AOT=JIT (S16 keeps the deliberate #ifjit split)
```

Raw evidence:
- `evidence/llvmspike01/unit_60811e6.log`
- `evidence/llvmspike01/unit_60811e6_summary.txt`
- `evidence/llvmspike01/jit_60811e6.log`
- `evidence/llvmspike01/jit_60811e6_summary.txt`
- `evidence/llvmspike01/lsp_60811e6.log`
- `evidence/llvmspike01/lsp_60811e6_summary.txt`
- `evidence/llvmspike01/corpus_60811e6_summary.txt`

**Root-cause pinpoint:** `git bisect` (manual) shows the regression is
introduced by `f75259b` (`refactor(ir): separate neutral IR from native
parameter lowering`), the second commit of `ACT-POLYC-IR-BOUNDARY01`. That
commit moved parameter lowering out of `irLowerFunction` into the new
post-pass `irAssignAbiParamLocations`. The four failing tests all
exercise struct-by-value ABI paths:

| Test                                | Symptom                              |
|-------------------------------------|--------------------------------------|
| `47_struct_abi.HC`                  | `ir-regalloc: no slot for var.id=95 kind=4` |
| `48_arg_overflow.HC`                | `ir-regalloc: no slot for var.id=24 kind=4` |
| `58_struct_return.HC`               | `ir-regalloc: no slot for var.id=65 kind=4` |
| indirect struct return C interop    | partial pass (1/3)                   |

`kind=4` is `IR_VAL_PARAM` per `src/ir-types.h`. The regalloc panic fires
when a parameter value reaches `irCgGetLoff` without a stack-slot mapping
having been assigned. The split between `irLowerFunction` (which no longer
consults the pool) and `irAssignAbiParamLocations` (which does, in a later
pass) leaves parameter values in an unslotted state when consumed by
specific codegen paths during certain calling-convention lowering steps
between the two passes.

`f75259b` is **not on the entry HEAD of this ACT** by itself; this ACT's
entry HEAD `0996ce4` sits on top of `f75259b`. The IR-BOUNDARY01 ACT
closure document at `docs/acts/ACT-POLYC-IR-BOUNDARY01.md` recorded the
predecessor AOT/JIT/LSP/corpus as green, which contradicts what is
observed when re-run on the same commit on this machine. Two explanations
are consistent with the evidence:

1. The closure evidence was captured against a working build tree whose
   state (libtos artifacts in `build/recon-prefix/`) was destroyed by a
   later `make clean`, and re-running the gates on a freshly-built hcc on
   this host exposes the regression.
2. The IR-BOUNDARY01 ACT's recorded gates were captured under conditions
   that masked the regression (a different intermediate libtos or
   build-prefix state).

Either way, ACT §6 is unambiguous: the predecessor baseline does not
reproduce here, and that is the halt condition that ACT-POLYC-LLVM-SPIKE01
must observe.

## 1.2 Halt #2 (secondary): HALT_LLVM_TOOLCHAIN_UNAVAILABLE

The ACT §3.1 requirement "Use a locally installed LLVM 22.x development
package for this ACT" is **NOT met**.

```
$ which llvm-config
not found
$ llvm-config --version
zsh: command not found: llvm-config
```

Discovery summary (full evidence in
`evidence/llvmspike01/llvm_toolchain_discovery.txt`):

- No `llvm-config` on PATH; no Homebrew installation; Apple
  CommandLineTools ships only `llvm-{cov,cxxfilt,dwarfdump,nm,objdump,
  otool,profdata,size}` (no `llvm-config`, no headers).
- The default Nix `nixpkgs` available via `import <nixpkgs> {}` exposes
  `llvmPackages_{12,13,14,15,16,17,18,19,20,21,git,latest}` — **no
  `llvmPackages_22` attribute**.
- `llvmPackages_latest.llvm.version` evaluates to `"21.1.7"`.
- `/nix/store/*-llvm-{20,21,22}*` either has no `dev` derivation at all
  (the `.drv` files exist but are not built, hence no
  `include/llvm-c/Core.h`, no `lib/libLLVM-*.dylib`) or lacks `llvm-config`.
- The only fully usable LLVM toolchain on this machine is `llvm-16.0.6-dev`
  at `/nix/store/23p2rimyf7bgs0k02i0z3wis0krxz9r3-llvm-16.0.6-dev/`.
- `nix-channel --update` is not runnable on this machine (the user does
  not have permission to mutate `/Volumes/UserData/Users/chistyakov/.local/
  state/nix/profiles/channels.lock`).

ACT §3.1: "The build may accept another LLVM 22 patch release when the
required Core C API is available." LLVM 16.0.6 and LLVM 21.1.7 are **not**
LLVM 22 patch releases; the exception does not apply.

ACT §5: "If LLVM mode is explicitly requested but a compatible
installation cannot be found: HALT_LLVM_TOOLCHAIN_UNAVAILABLE. Do not
silently fall back to native codegen while claiming LLVM mode."

This halt would also have stopped the ACT even with a clean predecessor
baseline.

---

# 2. What was NOT done

Because of Halt #1, ACT §6 ("No LLVM implementation begins") was strictly
observed. Specifically:

- No `--emit-llvm` CLI flag added.
- No `src/llvm-backend.c` or `src/llvm-backend.h` created.
- No `Makefile` or `CMakeLists.txt` changes touching LLVM.
- No LLVM C-API headers included anywhere in PolyC production source.
- No `POLYC_ENABLE_LLVM` / `HCC_ENABLE_LLVM` flag introduced.
- No `--install-dir` plumbing changes.
- No neutral-IR-contract expansion.
- No `irAssignAbiParamLocations` fix attempted (that is the next ACT's
  problem, not this one).

The ACT halted at the §6 gate, by design.

---

# 3. Doctrine observed

The ACT halted at the gate as written. The halt is **not** a verdict
against the predecessor ACT's direction — the neutral-IR contract
remains the right next step for a backend-neutral LLVM spike. The halt
is a verdict against the **specific shipped form of the boundary
extraction**, which introduced a register-allocator regression that
prevents the predecessor baseline from reproducing.

Doctrine reminders:

> Do not build an LLVM compiler yet.
> Prove one translation.
> Do not use LLVM optimization to make incorrect IR look plausible.
> Verify first.

LLVM mode is forbidden from silent fallback. LLVM mode is also forbidden
from running when the predecessor baseline is RED. Both halts triggered
correctly. The ACT exits.

---

# 4. Required next actions

## 4.1 Immediate (before any further LLVM work)

The IR-BOUNDARY01 boundary refactor (`f75259b`) must be repaired so that
the predecessor baseline reproduces on a freshly-built tree without
relying on destroyed build artifacts.

Suggested minimal repair (not executed in this ACT, recorded as a
recommendation):

- Trace every `irCgGetLoff` call that panics on a `kind=4`
  (`IR_VAL_PARAM`) value in the failing tests.
- Determine whether the missing slot is because the parameter
  classification now happens in `irAssignAbiParamLocations` and the
  parameter's `loc`/`loff` is set there, but certain early codegen
  steps (e.g. SRA via stack spills in `aarch64.c` / `x86_64.c`) read
  the slot before `irAssignAbiParamLocations` runs.
- Add a regression test that compiles `47_struct_abi.HC` directly
  (not just the AOT unit-test harness wrapper) so future
  regressions are caught at the smallest possible granularity.

A dedicated ACT (`ACT-POLYC-IR-BOUNDARY02`) should own this repair and
re-verify AC01 (AOT=90/90, JIT=90/90, LSP=43/43, CORPUS=16/16) on a
freshly-built tree before any LLVM work resumes.

## 4.2 LLVM toolchain provisioning

Until LLVM 22.x (or an LLVM 22 patch release) is installed on this host,
the LLVM-SPIKE01 chain (`ACT-POLYC-LLVM-SPIKE01` →
`ACT-POLYC-LLVM-CORE01` → `ACT-POLYC-LLVM-EXEC01` → `ACT-POLYC-LLVM-ORC01`
→ `ACT-POLYC-LLVM-REPL01`) cannot proceed.

Options:

- Install LLVM 22.1.x via a tool that respects the sandbox permissions
  on this machine (the nix store is read-only-ish for the current user;
  Homebrew is not installed; Apple CommandLineTools only ships
  version 15).
- Wait for the next nixpkgs bump and re-run `nix-channel --update`
  with the right permissions.
- Use a CI runner that has LLVM 22 pre-installed; do not pursue
  LLVM work in this local environment until then.

## 4.3 Next ACT proposal

`NEXT_ACT = ACT-POLYC-IR-BOUNDARY02` (proposed)

Goal: restore AC01 (`AOT=90/90`, `JIT=90/90`, `LSP=43/43`,
`CORPUS=16/16`) on a freshly-built tree at `0996ce4` without
regressing the neutral-IR contract introduced by
`ACT-POLYC-IR-BOUNDARY01`. Only after that closes
`PASS_WITH_NEXT_ACT_DECISION` should the LLVM-SPIKE01 chain resume.

---

# 5. Closure handoff (§45)

```
ACT-POLYC-LLVM-SPIKE01

VERDICT=HALT_PREDECESSOR_BASELINE_RED
      (HALT_LLVM_TOOLCHAIN_UNAVAILABLE was also true and would have
       independently triggered the halt)

IDENTITY
ENTRY_HEAD=0996ce4c304abc125d8e7562dd1ef615b142cabd
FINAL_HEAD=0996ce4c304abc125d8e7562dd1ef615b142cabd
WORKTREE_STATUS=clean

LLVM
LLVM_VERSION=NOT_AVAILABLE
LLVM_CONFIG=NOT_FOUND
LLVM_API=C (planned; never used in this ACT)
DEFAULT_BUILD_REQUIRES_LLVM=NO

PREDECESSOR
AOT=86/90    (RED at entry HEAD)
JIT=NOT_RE_RUN_ON_ENTRY_HEAD
LSP=NOT_RE_RUN_ON_ENTRY_HEAD
CORPUS=NOT_RE_RUN_ON_ENTRY_HEAD

ON_60811e6 (predecessor ACT's pre-IR-BOUNDARY01 state):
AOT=90/90
JIT=90/90
LSP=43/43
CORPUS=17/17 items (16 byte-identical; S16 keeps #ifjit split)

RED
LLVM_EMIT_RED=NOT_EXECUTED (halt before §7)
RED_COMMIT=N/A

LOWERING
ENTRYPOINT=N/A
PARAM_LOC_REQUIREMENT=IR_LOC_NONE
IRREGPOOL_REFERENCES=N/A
SUPPORTED_OPS=N/A
UNSUPPORTED_OPS=N/A

WITNESSES
L01_CONST=NOT_EXECUTED
L02_ARITH=NOT_EXECUTED
L03_SUB=NOT_EXECUTED
L04_BRANCH=NOT_EXECUTED
L05_CALL=NOT_EXECUTED

VERIFY
LLVM_VERIFY_MODULE=NOT_EXECUTED
LLVM_AS=NOT_EXECUTED

BOUNDARY
IR_CMP_BR=NOT_EXERCISED
IR_RMW_DEREF=NOT_EXERCISED
IR_ASM=NOT_EXERCISED
PHYSICAL_REG_INPUT=NOT_EXERCISED

NATIVE_CONSERVATION
AOT=86/90 on entry HEAD (regression; see §1.1)
JIT=NOT_RE_RUN_ON_ENTRY_HEAD
LSP=NOT_RE_RUN_ON_ENTRY_HEAD
CORPUS=NOT_RE_RUN_ON_ENTRY_HEAD
DEFAULT_HCC_LINKS_LLVM=NO

EXECUTION
LLVM_MACHINE_CODE_EMITTED=NO
LLVM_ORC_USED=NO
LLVM_IR_EXECUTED=NO

RESIDUE
P0=Predecessor-baseline regression in f75259b blocks this ACT chain.
   Repair required via ACT-POLYC-IR-BOUNDARY02 before any LLVM work.
P1=LLVM 22.x not installed on this host.
   Provision LLVM 22.1.x (or a 22 patch release) before resuming
   the LLVM-SPIKE01 chain.
P2=irAssignAbiParamLocations duplicates ~30 lines of AAPCS
   classification; P2 from predecessor ACT remains deferred.

NEXT_ACT=ACT-POLYC-IR-BOUNDARY02 (proposed)
```

---

# 6. Final doctrine

The predecessor ACT was right about the boundary direction. The
shipped form of the boundary extraction has a bug. The bug must be
repaired before any LLVM work begins. LLVM 22 must be installed on
this machine before any LLVM work begins. Both halts were observed
correctly. The ACT exits without touching LLVM.

> The first LLVM backend success is not "it runs".
> The first success is "PolyC's own neutral meaning can be
> represented faithfully in LLVM without knowing which CPU register
> Terry's descendant compiler would have chosen."

We did not get to test that proposition here. We will not test it on a
broken neutral pipeline or with the wrong toolchain. We exit now.
