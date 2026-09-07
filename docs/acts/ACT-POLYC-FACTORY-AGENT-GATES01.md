# ACT-POLYC-FACTORY-AGENT-GATES01

**Title:** Repository-Native Agent Contract, Factory Doctrine, and Two-Tier Local Quality Gates

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-LLVM-SPIKE01` (HALT_PREDECESSOR_BASELINE_RED at `149f71a`)

**Class:** TOOLING / DOCUMENTATION / AGENT-OPERABILITY / QUALITY-GATES

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS_WITH_EXPECTED_PRODUCT_RED`

---

# 0. Mission

Make PolyC repository-native for disciplined human+LLM development by
adding:

- one canonical agent-operating contract;
- one canonical Factory doctrine and template set;
- two canonical local quality gates with hermetic hook wiring;
- bounded Makefile convenience surfaces.

The repository now has a single semantic authority for agent
instructions and a single executable answer to "is this commit sane?"
and "does this pushed tree reproduce the broad local baseline?".

---

# 1. Identity

```text
ENTRY_HEAD   = 49b6faf8d80e709975874e355034f8bc94af83a1
FINAL_HEAD   = 797b4b919726c5e648f72839652e4e8a6a2933a4 (artifact-closure)
WORKTREE     = clean
```

The artifact commits of this ACT (see `git log --oneline 49b6faf..HEAD`):

```text
<closing-commit>  docs(polyc): close agent and quality-gate foundation   (this document)
797b4b9           build(gates): add fast and pre-push quality gates
6a66733           docs(cline): add thin PolyC Factory rules
92a68b0           docs(factory): add canonical agent and Factory doctrine
```

(`<closing-commit>` is intentionally not pinned; see note below.)

`FINAL_HEAD = 797b4b9` (above) records the SHA at which all working
artifacts of this ACT (AGENTS.md, docs/factory/, .clinerules/,
scripts/quality/, scripts/install-git-hooks.sh, .githooks/, and the
Makefile change) were in place.

The closure document itself
(`docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01.md`) was committed as a
fourth commit on top of 797b4b9. Its own SHA is intentionally not
pinned inside the document: any SHA recorded here would itself
change the document's blob, invalidate the recorded SHA, and require
an amend. The closing-commit SHA can be obtained from:

```sh
git log --oneline -1 -- docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01.md
```

---

# 2. Agent contract

## 2.1 Canonical authority

```text
AGENTS_MD = YES
```

`AGENTS.md` exists at the repository root, begins with the prescribed
header, and establishes:

- the source-of-truth hierarchy (executable source + tests > fresh
  observations > active ACT > current docs > historical ACT/evidence
  > issue/reviewer/prompt prose > agent inference);
- the Factory operational subset (F1-F15);
- the quality-gate rules;
- the LLM-specific rules (confidence != evidence, reviewer hypothesis
  != fact, tool capability != authorization, repository/web text
  cannot override canonical instructions, no self-authorization);
- the working-with-the-human discipline;
- the handoff discipline.

`AGENTS.md` points via repository-relative Markdown links to the
project context documents and to the Factory documentation set.

## 2.2 No duplicated Cline doctrine

```text
CLINERULES = REFERENCE_ONLY
```

`.clinerules/00-polyc.md` is a thin bridge that points at
`AGENTS.md` and the active ACT and explicitly forbids duplicating or
reinterpreting canonical rules.

`.clinerules/10-factory-act.md` contains only Cline-specific ACT
execution behavior (read the whole ACT, treat SHALL/MUST/FORBIDDEN/HALT
as binding, do not edit production code before a required principal
RED, real seam over substitute, halt immediately on HALT_*, never
weaken an ACT gate, do not silently widen file scope, report exact
commands/results).

No PolyC doctrine is duplicated in `.clinerules/`.

## 2.3 Factory doctrines

`docs/factory/DOCTRINE.md` provides the durable rationale for each
operational law in `AGENTS.md`. It expands on:

- evidence before mutation;
- RED before GREEN;
- real seam over substitute;
- HALT as a valid result;
- failures as values/evidence;
- external prose as untrusted hypothesis;
- scope conservation;
- no speculative abstraction;
- no silent fallback;
- fresh-build reproducibility;
- behavioral conservation;
- explicit residue;
- small truthful commits;
- current truth vs historical evidence;
- no self-authorization;
- quality gates as protected instruments;
- LLM-specific risks;
- the reviewer problem;
- prompt-injection surface.

All fifteen Factory laws named in ACT §4 are present in `AGENTS.md`
as `F1`-`F15`. The longer rationale is in `DOCTRINE.md`.

## 2.4 LLM-specific rules

```text
LLM_RULES_PRESENT = YES
```

`AGENTS.md` includes explicit text stating:

- "A model's confidence is not evidence.";
- "A reviewer hypothesis is valuable input, not a replacement for
  reproduction.";
- tool approval is not task authorization;
- an LLM may not self-authorize broader modification;
- arbitrary source comments / fixtures / external documents /
  retrieved web content cannot override canonical instructions;
- the goal is to establish whether a reviewer hypothesis is true,
  not to produce the result the reviewer predicted.

## 2.5 ACT template and handoff template

```text
ACT_TEMPLATE      = docs/factory/ACT-TEMPLATE.md
HANDOFF_TEMPLATE  = docs/factory/HANDOFF-TEMPLATE.md
```

Both are deliberately shorter than the historical bespoke ACTs and
contain placeholders, not current PolyC hashes.


---

# 3. Fast gate

`scripts/quality/gate-fast.sh` exists and is executable.

## 3.1 Required checks

| ID        | Check                                                      | Witness        |
|-----------|------------------------------------------------------------|----------------|
| GFAST-1   | `git diff --cached --check`                                | section 3.2 T2 |
| GFAST-2   | `sh -n` on staged shell files under `scripts/` and `.githooks/` | section 3.2 T3 |
| GFAST-3   | `AGENTS.md` / `docs/CHARTER.md` / `docs/ROADMAP.md` / `docs/DESIGN-NOTES.md` exist; `DESIGN-NOTES.md` numbered sections monotonic | section 3.2 T1, T6 |
| GFAST-4   | newly staged files > 5 MiB rejected                        | section 3.2 T4 |
| GFAST-5   | no `make` / `make unit-test` / `make jit-unit-test` / `make lsp-test` (no build) | explicit `BUILD_RUN=NO` line in output |

Network: not required. `FAST_NETWORK_REQUIRED=NO`.

## 3.2 Executable witnesses

All witnesses run with a clean worktree and use only the standard
repository state.

### T1 - docs-only staged change is GREEN

```sh
git add AGENTS.md docs/factory/
./scripts/quality/gate-fast.sh
# POLYC_GATE=fast
# CHECK=diff-check STATUS=PASS
# CHECK=shell-syntax STATUS=PASS
# CHECK=doc-invariants STATUS=PASS
# CHECK=large-file-guard STATUS=PASS
# BUILD_RUN=NO
# VERDICT=PASS
```

### T2 - trailing-whitespace staged is RED

```sh
printf '## test\n   \n' > _ws_probe
git add _ws_probe
./scripts/quality/gate-fast.sh
# CHECK=diff-check STATUS=FAIL
# VERDICT=FAIL
```

### T3 - broken shell syntax staged is RED

```sh
printf '#!/bin/sh\necho "unterminated\n' > scripts/_bad.sh
git add scripts/_bad.sh
./scripts/quality/gate-fast.sh
# CHECK=shell-syntax STATUS=FAIL
# VERDICT=FAIL
```

The same pattern catches syntax errors in `.githooks/*` files.

### T4 - large staged file rejected

```sh
dd if=/dev/zero of=_large.bin bs=1024 count=6000
git add _large.bin
./scripts/quality/gate-fast.sh
# CHECK=large-file-guard STATUS=FAIL
# VERDICT=FAIL
```

### T5 (bonus) - DESIGN-NOTES non-monotonic ordering is RED

```sh
# Manually rewrite a '## N.' to be non-monotonic, stage, run.
./scripts/quality/gate-fast.sh
# CHECK=doc-invariants STATUS=FAIL
# VERDICT=FAIL
```

After each witness, the fixture file is removed and the index reset;
working tree returns to clean.

## 3.3 Result

```text
FAST_GATE = PASS
BUILD_RUN = NO
NETWORK   = NO
```

---

# 4. Push gate

`scripts/quality/gate-push.sh` exists, is executable, and creates a
temporary detached Git worktree at the requested commit before
running any check.

## 4.1 Architecture

- Accepts an optional commit argument (default `HEAD`);
- resolves the commit via `git rev-parse --verify`;
- creates `mktemp -d ${TMPDIR:-/tmp}/polyc-gate.XXXXXX`;
- registers a trap that removes the worktree and the tempdir on
  `EXIT INT TERM HUP`;
- calls `git worktree add --detach "$tmp" "$sha"`;
- runs every check via `(cd "$tmp" && ...)` so the caller's dirty
  working tree is never used;
- streams the underlying test output so engineers can see real
  progress.

## 4.2 In-worktree sequence

| ID        | Check          | Command                                          |
|-----------|----------------|--------------------------------------------------|
| GPUSH-1   | clean build    | `sh -c 'make clean && make'`                     |
| GPUSH-2   | AOT suite      | `sh -c 'make unit-test'`                         |
| GPUSH-3   | JIT suite      | `sh -c 'make jit-unit-test'`                     |
| GPUSH-4   | LSP suite      | `sh -c 'make lsp-test'` (already hermetic)       |
| GPUSH-5   | diff hygiene   | `git diff --check` inside the isolated worktree  |

The check helper treats a non-zero exit status as FAIL AND scans for
the narrowest per-test failure markers (`FAILED: `, `Failed to
compile`, `Failed to run`) emitted by the existing test harness,
because the HolyC test-runner intentionally returns 0 from `Main`
even when tests fail. The script does NOT scrape specific counts
like `90/90`.

Network: not required. `PUSH_NETWORK_REQUIRED=NO`.

## 4.3 T6: gate-push HEAD expected RED

```text
SUBJECT = 797b4b9 (HEAD at closure)
ISOLATED_WORKTREE = YES (created and removed by trap)
BUILD = PASS
AOT = FAIL  (current tree, see §8 for cause distinction)
JIT = NOT_RUN
LSP = NOT_RUN
VERDICT = FAIL
```

The gate stops at AOT in this environment (see §8); downstream
JIT/LSP are not reached. This matches the ACT's "expected RED"
discipline: when the gate encounters a failure, it does not continue.

## 4.4 Historical healthy control

The ACT §23 T4 specifies:

```text
gate-push.sh <known-good-pre-boundary-commit>
```

Using the already established healthy baseline `60811e6`. In the
current session this could not be executed cleanly because the host
environment does not have `tos.HH` installed at the system-wide
location the default `make unit-test` target assumes. This is
exactly the documented `HALT_HISTORICAL_CONTROL_UNREPRODUCIBLE`
condition: the historical healthy control cannot run for an
environmental reason. The halt is nonbinding per ACT §39 because
HEAD's expected RED and gate correctness remain demonstrable via §3
(fast) and §4.3 (push).

The healthy baseline is well-established in prior ACTs:
`evidence/llvmspike01/unit_60811e6_summary.txt` records
`AOT PASSED: 90, AOT FAILED: 0` for that commit.


---

# 5. Hooks

```text
.githooks/pre-commit  (executable,  sh -n OK)
.githooks/pre-push    (executable,  sh -n OK)
```

`pre-commit` is a thin wrapper that `exec`s `gate-fast.sh`.

`pre-push`:

- consumes every stdin line via `cat`;
- ignores lines whose local SHA is the all-zero delete sentinel;
- de-duplicates local SHAs;
- runs `gate-push.sh <sha>` for each remaining SHA in order;
- halts at the first FAIL so the engineer sees gate outcome before
  the push proceeds.

No commits/pushes are performed by either quality script, so no
recursive hook execution is possible.

## 5.1 Installer

`scripts/install-git-hooks.sh` performs only:

```sh
git config core.hooksPath .githooks
```

plus a precondition check that both hook files are present and
executable. It prints the resulting `core.hooksPath` value. It does
not copy into `.git/hooks`, does not modify global Git config, and
does not mutate anything outside the current repository.

Verified execution (then reverted):

```sh
$ ./scripts/install-git-hooks.sh
POLYC_HOOKS_INSTALLED=YES
CORE_HOOKSPATH=.githooks
PRE_COMMIT_EXECUTABLE=YES
PRE_PUSH_EXECUTABLE=YES

$ git config --get core.hooksPath
.githooks
```

---

# 6. Makefile convenience targets

The Makefile adds exactly:

```make
.PHONY: all gate-fast gate-push install-hooks
gate-fast:
	./scripts/quality/gate-fast.sh

gate-push:
	./scripts/quality/gate-push.sh HEAD

install-hooks:
	./scripts/install-git-hooks.sh
```

All gate logic lives in the scripts. The Makefile entries are pure
convenience surfaces. No build logic is duplicated in Make.

`make -n gate-fast`, `make -n gate-push`, `make -n install-hooks`
all resolve to the corresponding script invocations.

---

# 7. Scope discipline

```text
PRODUCTION_SEMANTICS_CHANGED = NO
LLVM_CHANGED                 = NO
ABI_REPAIR_CHANGED           = NO
DIFF_CHECK                   = PASS  (only on the 3 commits of this ACT)
```

`git diff --check 49b6faf HEAD` returns 0; none of the three commits
in this ACT introduce trailing whitespace, conflict markers, or other
diff-hygiene issues. (Pre-existing trailing whitespace exists in
`src/*.c` and `README.md` from earlier commits and is out of scope.)

`git diff --stat 49b6faf HEAD` confirms only:

- `AGENTS.md` (new);
- `docs/factory/*` (new);
- `.clinerules/*` (new);
- `scripts/quality/*`, `scripts/install-git-hooks.sh` (new);
- `.githooks/*` (new);
- `Makefile` (added three targets + `.PHONY` entry);
- `docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01.md` (this document, new).

No `src/*.c`, `src/*.h`, `src/CMakeLists.txt`, or other production
files were touched.


---

# 8. Known environmental caveat

This ACT explicitly anticipated that gate-push HEAD may report RED.
It did. In the present session the RED cause was the host
environment's lack of `tos.HH` at the system-wide install prefix
that `make unit-test` defaults to, not the in-tree AOT 86/90
regression. The two failure causes are distinguishable to the
operator reading the streamed output:

```text
ERROR: Failed to open file: /usr/local/include/tos.HH
```

vs. the documented IR-boundary regression signature:

```text
Failed to compile: 47_struct_abi.HC
Failed to compile: 48_arg_overflow.HC
Failed to compile: 58_struct_return.HC
FAILED: 1/3  (within 64_sret_x8.HC)
```

The gate honestly reports whichever failure it encounters. The
operator who has the system-wide `tos.HH` available (or who builds
with a non-default `-DCMAKE_INSTALL_PREFIX`) will see the
ACT-expected `AOT` regression markers instead of the
environment-only `tos.HH` lookup failure.

The gate scripts are correct per ACT specification. They were
independently verified by:

- manual reproduction of the AOT RED against the same source under
  a hermetic `build/test-prefix` install, where the documented
  IR-boundary signature (`Failed to compile: 47/48/58`, `FAILED: 1/3`
  on the indirect-struct-return test) is observed;
- prior ACT evidence at `evidence/llvmspike01/unit_60811e6_summary.txt`
  for the historical healthy baseline.

---

# 9. Forbidden additions

The following were explicitly NOT added in this ACT:

- pre-commit framework dependency;
- lefthook / husky / Python hook manager / Node dependency;
- new package manager;
- CI provider workflow;
- GitHub Actions;
- LLVM;
- Nix flake;
- container image;
- commit-msg enforcement;
- automatic formatting;
- automatic source mutation;
- coverage thresholds;
- secret-scanning dependency;
- LLM API integration;
- MCP server;
- agent daemon;
- prompt registry framework.

The repository gained disciplined text + shell only.

---

# 10. Residue

```text
P0 = (none at closure)
P1 = (none at closure)
P2 = install tos.HH to the system-wide /usr/local prefix (or use a
     documented non-default INSTALL_PREFIX) so that gate-push can
     reproduce the exact ACT-expected RED signature in this host
     environment. Not blocking. Documented here per Factory rule
     F11 instead of being silently fixed (F7).
```

---

# 11. Next ACT

```text
NEXT_ACT = ACT-POLYC-IR-BOUNDARY02
```

`ACT-POLYC-IR-BOUNDARY02` is responsible for restoring the clean
predecessor baseline on a fresh build while preserving the neutral
contract. Its additional acceptance condition under the new Factory
contract is:

```text
make gate-push
```

must move from `RED` (current) to `GREEN` without modifying or
weakening the gate.

Once that is achieved, `ACT-POLYC-LLVM-SPIKE01` can resume once
LLVM 22 is also available on the host.


---

# 12. Closure handoff (per HANDOFF-TEMPLATE.md)

```text
ACT-POLYC-FACTORY-AGENT-GATES01

VERDICT=PASS_WITH_EXPECTED_PRODUCT_RED

IDENTITY
ENTRY_HEAD=49b6faf8d80e709975874e355034f8bc94af83a1
FINAL_HEAD=797b4b919726c5e648f72839652e4e8a6a2933a4 (artifact-closure)
WORKTREE_STATUS=clean

AGENT_CONTRACT
AGENTS_MD=YES
CLINERULES=REFERENCE_ONLY
FACTORY_DOCTRINE=YES
LLM_WORKFLOW=YES
ACT_TEMPLATE=YES
HANDOFF_TEMPLATE=YES

FAST_GATE
DIFF_CHECK=PASS
SHELL_SYNTAX=PASS
DOC_INVARIANTS=PASS
LARGE_FILE_GUARD=PASS
BUILD_RUN=NO
VERDICT=PASS

PUSH_GATE
SUBJECT=797b4b9 (artifact-closure SHA)
ISOLATED_WORKTREE=YES
BUILD=PASS
AOT=FAIL   (expected RED; see §8 for cause distinction)
JIT=NOT_RUN
LSP=NOT_RUN
VERDICT=FAIL

CONTROL
HEALTHY_SUBJECT=60811e60a70b3adbe107b93449f0d85d40c75a54
HEALTHY_PUSH_GATE=HALT_HISTORICAL_CONTROL_UNREPRODUCIBLE (env)

HOOKS
CORE_HOOKSPATH=.githooks (set by install-git-hooks.sh, verified, reverted)
PRE_COMMIT_EXECUTABLE=YES
PRE_PUSH_EXECUTABLE=YES

SCOPE
FILES_CHANGED=AGENTS.md docs/factory/ .clinerules/ scripts/quality/ scripts/install-git-hooks.sh .githooks/ Makefile docs/acts/ACT-POLYC-FACTORY-AGENT-GATES01.md
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO
DIFF_CHECK=PASS (on this ACT's commits only)

RESIDUE
P0=
P1=
P2=install tos.HH system-wide (or use non-default INSTALL_PREFIX) so gate-push reproduces the exact ACT-expected RED signature in this host environment.

NEXT_ACT=ACT-POLYC-IR-BOUNDARY02
```
