# LLM / Human Workflow

This document describes the intended lifecycle for collaboration
between a human and an LLM-driven agent on PolyC.

It is a process description, not a script. The actual step ordering
for each task is defined by the active ACT.

---

## The lifecycle

```text
REQUEST / IDEA
      ↓
RECON
      ↓
ACT / bounded contract
      ↓
ENTRY IDENTITY
      ↓
PREDECESSOR GATES
      ↓
PRINCIPAL RED
      ↓
IMPLEMENTATION
      ↓
TARGETED GREEN
      ↓
BROAD CONSERVATION
      ↓
FRESH-BUILD GATE
      ↓
DIFF / SCOPE REVIEW
      ↓
COMMIT(S)
      ↓
HANDOFF
      ↓
REVIEW / NEXT ACT
```

Each stage has a defined purpose. Skipping stages turns the workflow
from a discipline into a hope.

### REQUEST / IDEA

A human identifies a problem, improvement, or experiment they want
pursued.

This stage produces a *request*, not an ACT.

### RECON

The agent reads the actual repository to understand:

- what already exists;
- what the real execution seams are;
- what prior ACTs and evidence relate to the request;
- what assumptions the request implicitly makes.

Recon ends with a classification of the work, not a commitment to
proceed.

### ACT / bounded contract

The agent and human agree on a bounded ACT:

- what scope is in;
- what scope is out;
- what HALTs are foreseeable;
- what evidence will mark success;
- what residue is anticipated.

The ACT is the only authority for the work that follows.

### ENTRY IDENTITY

Before any mutation:

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

This identity is recorded in the closure handoff.

### PREDECESSOR GATES

If a prior ACT established baselines or claims that the new ACT
depends on, those are reproduced or verified here.

Skipping predecessor reproduction because "we know it worked last
time" is a common path to silent regressions.

### PRINCIPAL RED

If the ACT requires a behavior change, the agent reproduces the
defect or absence-of-feature against the real production seam.

This RED is preserved and committed where practical.

### IMPLEMENTATION

The minimum change that makes the principal RED GREEN.

No adjacent cleanup. No speculative generalization.

### TARGETED GREEN

The narrow witness for the defect transitions to green.

### BROAD CONSERVATION

The widest reasonable existing test gate is run to confirm:

- the new behavior changed;
- existing behavior did not regress.


### FRESH-BUILD GATE

For compiler work, a fresh clean build is performed before closure.

This is non-negotiable for ACTs that touch production code.

### DIFF / SCOPE REVIEW

Every changed line is reviewed against ACT scope:

- is this change authorized?
- is this change the minimum?
- is this change traceable to a clause in the ACT?

### COMMIT(S)

Commits correspond to proof steps.

Manufactured commits are forbidden.

### HANDOFF

A structured handoff is produced containing:

- VERDICT;
- IDENTITY (entry/final heads, worktree state);
- RED / IMPLEMENTATION summary;
- GATE results;
- SCOPE summary;
- RESIDUE (P0/P1/P2);
- NEXT_ACT recommendation.

### REVIEW / NEXT ACT

The human reviews the handoff.

Decisions:

- close;
- close with follow-up ACT;
- reject and return to RECON.

---

## Four separate dimensions

These dimensions are frequently conflated. They are not the same.

### human authorization

The human explicitly granted the agent permission to perform the
work, through:

- the active ACT;
- an explicit instruction;
- a pre-approved routine (for trivial cases).

### agent/tool capability

The agent can perform an action.

For example, an LLM can issue a file-write tool call.

Capability is necessary but not sufficient.

### technical evidence

The repository, the build, or the test suite supports a claim.

For example, a reproducer script exits with code 0.

### review opinion

A reviewer (human or LLM) believes something is true or should be
true.

Review opinion is a hypothesis until it is supported by evidence.

A correctly operating workflow keeps these dimensions separate:

```text
capability       = "the agent can do it"
authorization    = "the agent should do it"
evidence         = "the agent did it and the result is real"
review-opinion   = "someone thinks it is correct"
```

Confusion among these dimensions is a major source of silently
incorrect work.

---

## A model's confidence is not evidence

LLMs can produce confident text about claims that are not in evidence.

This is normal model behavior, not an indictment of any particular
response.

The agent operating contract treats LLM confidence the way a doctor
treats patient optimism:

- it is data about the model's state;
- it is not data about the repository.

The repository is the only acceptable witness for behavior claims.

---

## A reviewer hypothesis is valuable input, not a replacement for reproduction

Reviewers can be wrong in two directions:

- falsely pessimistic ("this won't work");
- falsely optimistic ("this is fine").

The ACT exists to test those hypotheses against the actual system.

Agents that adopt the reviewer's conclusion without testing are not
being deferential. They are being unprofessional.

The right relationship to review is:

```text
record the hypothesis
    ↓
design a witness
    ↓
run the witness
    ↓
report the witness result
    ↓
attribute any disagreement to evidence, not authority
```

---

## When the workflow halts

HALTs are not errors in the workflow.

HALTs are the workflow correctly refusing to continue past a missing
precondition.

The handoff for a HALT is structured the same as for a PASS. The
VERDICT is one of the HALT_* tokens. The evidence is preserved. A
corrective ACT is recommended.

Treating HALTs as failures is a strong pressure toward silent
shortcuts. The Factory rejects that pressure.


---

## What the workflow does not do

- It does not invent abstractions on the agent's initiative.
- It does not refactor adjacent code.
- It does not weaken tests to obtain PASS.
- It does not silently fall back to a substitute toolchain.
- It does not generate commit counts for cosmetic reasons.
- It does not treat prior summaries as fresh evidence.
- It does not edit the gates to make a failing tree green.
- It does not interpret broad human gestures as broad authorization.

The bounded ACT is the contract. Everything else is residue.
