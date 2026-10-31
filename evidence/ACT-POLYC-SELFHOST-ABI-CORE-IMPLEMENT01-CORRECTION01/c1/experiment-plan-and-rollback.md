# The C2 experiment plan and the rollback, frozen at C1.

ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01.

## The four physical executions

Each execution is a SEPARATE physical run in its OWN disposable
detached worktree, with its OWN build prefix, its OWN install prefix
and its OWN execution id. No execution reuses another's artifacts.

| Execution id | Worktree | Mutation | Purpose |
|---|---|---|---|
| `EXEC-RO-CORR01-PRISTINE` | `/tmp/aci01-corr01-pristine` | none | the pristine baseline: a fresh selector-ON production build, the four witnesses' pristine outcomes, the pristine digests |
| `EXEC-RO-CORR01-MUTANT` | `/tmp/aci01-corr01-ro-mutant` | AST_BIN_OP_LT removed from `AbiCoreIsRangeOperator` | THE causal experiment: the same witness set, the same build recipe, with the RO-site mutation |
| `EXEC-PO-CORR01-ANTI` | `/tmp/aci01-corr01-po-ant` | AST_BIN_OP_LT removed from `AbiCoreIsValidPointerOperator` | the distinct adverse control: it proves the discriminator is site-specific, and it prevents a repeated M-POLYC-RO misbinding |
| `EXEC-RO-CORR01-RESTORED` | `/tmp/aci01-corr01-restored` | none (the pristine tree, rebuilt) | the restoration: the same build recipe, the same witnesses, the pristine results must come back |

The historical id `EXEC-M-POLYC-RO` is NEVER reused.

## The build recipe, identical in every execution

```sh
# inside the execution's own detached worktree
make production-hcc                 # SERIAL, never -j
make test-prefix-install
```

Both commands are run from the worktree's root. The build prefix and
the install prefix are the worktree's OWN `build/` directory, so no
execution can read another's objects.

**SERIAL ONLY.** A parallel `make -j2` was observed to fail on this
host because two rules write the same object path concurrently. That
is a pre-existing build-graph hazard, recorded as residue, and it is
why every build here is serial. Independently, the compiler writes
its assembly to the shared global `/tmp/holyc-asm.s`, so two
concurrent compiler invocations can race even across distinct make
commands. Every compiler invocation in this ACT is serial.

## The mutation procedure

The mutation is applied **inside the mutant worktree only**, by a
bounded, range-checked edit:

1. locate the RO function's byte range in the worktree's
   `tools/bootstrap/selfhost-core-operator.HC`;
2. locate the line within that range whose content is exactly the
   AST_BIN_OP_LT case line of `AbiCoreIsRangeOperator`;
3. remove exactly that line;
4. record `git diff --binary` in the worktree;
5. verify, by reading the APPLIED bytes, that:
   - every changed byte lies inside the RO range;
   - the RO function's recognised set changed by exactly one
     membership;
   - the PO function's bytes are identical to the pristine;
   - the CA function's bytes are identical to the pristine;
   - no other byte of the file changed.

Step 5 reads the applied bytes. The intended patch is NOT accepted as
proof of the applied bytes.

## The witness procedure

For every witness, in every execution:

1. compile it with that execution's production compiler, against that
   execution's isolated install prefix;
2. record the compiler's exit status and its own stdout/stderr;
3. run the produced program and record the process exit status;
4. emit the witness's assembly with `-S` and record its SHA-256 and a
   structural shape summary (branch instruction count, compare
   instruction count, function label count).

The semantic exit status and the emitted assembly must BOTH change
under the RO mutation. The assembly check does not rely on a fixed
assembler label and does not rely on a copied string comparison; it
compares the structural shape of the emitted function body.


## What each execution must show

```text
EXEC-RO-CORR01-PRISTINE : W-CORR-RO-DISCRIM exit 0, W-CORR-PO-LT exit 0,
                           W-CORR-CA exit 30, W-HISTORICAL-NONDISCRIM exit 1
EXEC-RO-CORR01-MUTANT   : W-CORR-RO-DISCRIM exit 1  <-- THE DISCRIMINATOR
                           W-CORR-PO-LT exit 0 (UNCHANGED)
                           W-CORR-CA exit 30 (UNCHANGED)
                           the subject object's SHA-256 DIFFERS from the pristine
                           the linked production executable's SHA-256 DIFFERS
                           the assembly's shape DIFFERS
EXEC-PO-CORR01-ANTI     : W-CORR-RO-DISCRIM exit 0  <-- the RO site is intact
                           W-CORR-PO-LT COMPILE_FAILED  <-- the PO site changed
                           W-CORR-CA exit 30 (UNCHANGED)
                           a DIFFERENT execution id, source digest and object digest
EXEC-RO-CORR01-RESTORED : the pristine outcomes and the pristine digests return
```

An RO mutation that changes only a pointer-specific witness, or that
changes the PO function, or that fails to change W-CORR-RO-DISCRIM, is
**NOT PROVEN**.

## The rollback

1. The mutant and anti-control worktrees are REMOVED with
   `git worktree remove --force` after their artifacts are recorded.
   Only worktrees this ACT created are removed; the pre-existing
   `slice08-wt` and pinned-producer worktrees are left alone.
2. The authoritative checkout is never mutated: every mutation lives in
   a disposable worktree, and `main`'s tracked tree and working index
   are verified untouched at C3.
3. The restoration execution rebuilds the pristine configuration in its
   own worktree and must reproduce the pristine source digest, the
   pristine subject object digest (given an identical producer and
   environment) and the pristine witness outcomes. Where byte identity
   of the OBJECT cannot be demonstrated, the difference is explained
   explicitly and semantic/normalized equivalence is demanded; it is
   never labelled byte-identical without demonstration.
4. `git worktree prune` is run afterwards so that no stale ACT-owned
   worktree metadata survives.

## The HALT conditions this plan cannot paper over

```text
HALT_RO_MUTATION_WRONG_SUBJECT   the applied bytes are not confined to the RO range
HALT_RO_MUTANT_BUILD             the build failed, or the subject object did not change
HALT_RO_CAUSAL_UNPROVEN          W-CORR-RO-DISCRIM did not change 0 -> 1
HALT_SITE_ISOLATION              the PO or CA witness changed under the RO mutation
HALT_RESTORATION                 the pristine state did not come back
```

In each case the ACT halts with the measured reason. No substitute
witness is invented, and no criterion is waived.
