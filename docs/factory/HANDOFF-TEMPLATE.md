# ACT Closure Handoff Template

This template defines the structured closure summary an ACT MUST
produce.

It is the contract between agent and human at ACT boundary.

---

```text
ACT-...

VERDICT=

IDENTITY
ENTRY_HEAD=
FINAL_HEAD=
WORKTREE_STATUS=

RED
... (or HALT_* explanation if not reproduced)

IMPLEMENTATION
... (or HALT_* explanation if not implemented)

GATES
BUILD=
TARGETED=
UNIT=
JIT=
LSP=
DIFF_CHECK=

SCOPE
FILES_CHANGED=
DIFF_CHECK=
PRODUCTION_SEMANTICS_CHANGED=NO
LLVM_CHANGED=NO
ABI_REPAIR_CHANGED=NO

RESIDUE
P0=
P1=
P2=

NEXT_ACT=
```

---

## Section rules

### VERDICT

Allowed values:

- `PASS` — work complete, all gates satisfied;
- `PASS_WITH_EXPECTED_PRODUCT_RED` — work correct but the broader
  product has a known unrelated RED;
- `PASS_WITH_RESIDUE` — work complete, residue is the only open item;
- `HALT_RED_NOT_REPRODUCED` — required principal RED was not
  reproducible;
- `HALT_SCOPE_EXPANSION_REQUIRED` — correct completion requires work
  outside ACT;
- `HALT_*` — any other HALT_* token from this template system.

A HALT is not a failed PASS. It is a successful execution outcome.

### IDENTITY

- `ENTRY_HEAD` — the commit at which the ACT started;
- `FINAL_HEAD` — the commit at closure;
- `WORKTREE_STATUS` — `clean` or a description of authorized
  leftover state.

### RED

Either:

- a concrete description of the principal RED with reproduction
  commands; or
- a HALT_* explanation if no RED was reached.

### IMPLEMENTATION

Either:

- a concrete summary of the minimum change; or
- a HALT_* explanation.

### GATES

Each field is one of:

- `PASS` — gate ran and passed;
- `FAIL` — gate ran and failed (expected or unexpected must be
  explained);
- `N/A` — gate does not apply to this ACT;
- `NOT_RUN` — gate was not executed (avoid this in PASS verdicts).

### SCOPE

`FILES_CHANGED` lists paths. `DIFF_CHECK` reports the result of
`git diff --check` on the closure tree.

The three `*_CHANGED=NO` lines are mandatory for ACTs whose class
forbids the corresponding change.

### RESIDUE

P0/P1/P2 entries:

- `P0` — must include a brief blocker and a recommended next ACT;
- `P1` — should include a brief description;
- `P2` — optional.

Empty entries may be omitted or written as `-`.

### NEXT_ACT

Either:

- the recommended next ACT ID;
- or `-` if no follow-up is recommended.

---

## Acceptable brevity

For docs-only ACTs, the following fields MAY be omitted or marked
`N/A`:

- `RED`;
- `IMPLEMENTATION`;
- `UNIT`, `JIT`, `LSP` gates.

`IDENTITY`, `SCOPE`, `RESIDUE`, and `VERDICT` are always required.

For HALT verdicts, gate fields MAY be `NOT_RUN` if the halt occurred
before gate execution.

---

## Why this template exists

The handoff is the boundary at which:

- the agent transfers work back to the human;
- the human decides whether to close, retry, or expand.

A loose verbal summary loses information that future ACTs need.

A overlong report wastes review time.

This template targets the minimum information that supports a clear
decision.

Future ACTs may reference earlier handoffs verbatim. That only works
if the structure is stable.

Keep it stable.


---

## Factory v2 HANDOFF template (additive)

For ACTs opened after
`ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` closes, use this
template. The v1 template above remains binding for the
grandfathered v1 managed universe and historical ACTs.

The Factory v2 HANDOFF is descriptive only. It does NOT
carry an authoritative verdict field; the verdict lives on
the ACT's CLOSE commit `ACT-Verdict` trailer.

```markdown
# HANDOFF -- <ACT-ID>

Factory-Version: 2

## Result

<short human-readable result>

Closure verdict is authoritative in the `ACT-Verdict`
trailer of the ACT's CLOSE commit.

## What changed

- ...

## Evidence

- ...

## Production delta

- ...

## Residue

- P1 ...
- P2 ...

## Recommended next ACT

<ACT-ID>
```

### Forbidden fields

The Factory v2 HANDOFF MUST NOT carry:

* `Status:`
* `VERDICT:`
* `FINAL_HEAD:`
* `CLOSURE_HEAD:`
* `DOCS_HEAD:`
* `IMPLEMENTATION_HEAD:`
* `worktree=clean` (live observation, not durable text)

### Reviewer procedure

```sh
sh scripts/quality/factory-v2-range-check.sh <ACT-ID> HEAD
git show --stat <close>
git log <entry>..<close> --format=full
git status --porcelain=v1
git diff --check <entry>..<close>
```
