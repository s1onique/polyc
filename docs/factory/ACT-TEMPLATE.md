# ACT Template (short)

Use this template for bounded ACTs that do not need the full
historical RECON-style structure.

It deliberately omits:

- long lineage reproductions,
- detailed class taxonomy,
- embedded ACT-IDs in the header.

Fill placeholders. Remove sections that do not apply.

Do not paste current PolyC hashes into the template — they go in the
filled ACT, not here.

---

```markdown
# ACT-...

**Title:** ...

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** IMPLEMENTATION | RECON | TOOLING | DOCUMENTATION | ...

**Predecessor:** ACT-... (optional)

**Production semantic changes:** FORBIDDEN | AUTHORIZED (scoped)

**IR / ABI / LLVM authorization:** NONE | SCOPED

---

## 0. Mission

One paragraph. State the bounded objective in observable terms.

## 1. Why

One paragraph. State the evidence that motivates the work.

## 2. Scope

### allowed

- file/area 1
- file/area 2

### forbidden

- semantic change to X
- dependency addition
- CI / framework / container changes

## 3. Entry gate

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Required state:

- on main;
- worktree clean (or only authorized pre-existing dirty);
- entry HEAD recorded.

## 4. Principal RED

Describe the real failing witness before any production change.

State where it lives and how to reproduce it.

## 5. Implementation boundary

State the minimum production change required.

State what is deliberately *not* included.

## 6. Acceptance criteria

List AC01, AC02, ... with concrete commands and expected results.

## 7. Conservation gates

List the existing gates that must remain PASS.

E.g.:

- `make unit-test` → expected count
- `make jit-unit-test` → expected count
- `make lsp-test` → expected count
- predecessor regression tests

## 8. Halt taxonomy

List the HALT_* tokens that apply to this ACT.

At minimum, include any HALT_* tokens whose preconditions this ACT
triggers.

## 9. Residue

Pre-declare known side observations (P0/P1/P2) where possible.

These will be updated at closure.

## 10. Commit topology

Suggested commit ordering. Mark "do not exceed".

If the work is trivial, a single commit is fine.

## 11. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md`.
```

---

## Section guidance

### Class

Pick the dominant class. Multi-class ACTs are allowed but discouraged.

Common classes:

- RECON;
- IMPLEMENTATION;
- ARCHITECTURAL-BOUNDARY;
- TOOLING;
- DOCUMENTATION;
- QUALITY-GATES;
- EXPERIMENT.

### Predecessor

State the predecessor ACT or commit hash only if this ACT depends on
its claims.

### Production semantic changes

Default to FORBIDDEN unless the ACT is explicitly authorized to change
observable compiler or language behavior.

### Scope: forbidden

Always populate this section.

A scope section that lists only allowed work is unbounded by omission.

### Acceptance criteria

Each AC MUST be checkable by a single concrete command.

If it cannot be checked by a single concrete command, it is not an AC.

### Conservation gates

Conservative ACTs list the broadest reasonable existing gate.

Bounded ACTs are allowed to list narrower gates but should explicitly
justify the reduction.

### Halt taxonomy

Pull from the canonical list in this template system.

Define new HALT_* tokens only when no existing token fits.

### Commit topology

Default:

```text
1. RED (tests / fixtures)
2. implementation
3. verification / docs
```

Adjust when proof steps naturally differ.

---

## When NOT to use this template

Use the long-form historical ACT structure (e.g. RECON01) when:

- the ACT must reproduce a multi-thousand-line evidence corpus;
- the ACT closes a major architectural change;
- downstream ACTs depend on its detailed claims.

Otherwise prefer this template.

Shorter ACTs are easier to read, easier to review, and easier to
amend.
