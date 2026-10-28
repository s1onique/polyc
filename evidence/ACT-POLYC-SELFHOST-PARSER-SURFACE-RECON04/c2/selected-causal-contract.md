# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SELECTED CAUSAL CONTRACT

**SELECTED_CANDIDATE:** `SUB-001`
**CLASSIFICATION:** `EXECUTED_CAUSAL_CONTROL` (the strongest class: the
experiment was actually RUN, not merely planned)

---

## 1. The experiment that was EXECUTED

The ACT section 13 preferred experiment was performed at RECON04 time,
against a real production compiler built from a real source tree.

### The isolated tree

```text
COMMAND=git worktree add --detach /tmp/recon04-causal HEAD
```

The worktree is a REAL git worktree of THIS repository, checked out at
the ACT's own C1 commit, so the tracked production source is exactly
the source under test.  The tracked source in the MAIN repository was
NOT modified: the mutation was applied only inside the isolated
worktree and was reverted with `git checkout -- src/parser.c`.

### The witness

```text
FILE=c2/probes/witness-sub001.HC
```

The witness puts a COMPOUND STATEMENT as the first statement of the
first case arm and a marker statement after it:

```c
    switch (1) {
        case 1: { x = 41; }
            Print("ARM1_MARKER");
        case 2:
            x = 1;
            Print("ARM2_MARKER");
            break;
        ...
    }
```

With the PRISTINE decision the compound statement TERMINATES the arm,
so the marker statement is parsed by the `case 2:` arm and the first
arm's marker is never printed.  With the MUTATED decision the compound
statement does NOT terminate the arm, so the marker stays in the
`case 1:` arm and IS printed.

The observable is COMPILED PROGRAM OUTPUT.

### The mutation

```text
COMMAND=perl -pi -e 's/if \(stmt->kind == AST_COMPOUND_STMT \|\| stmt->kind == AST_CASE \|\|/if (stmt->kind == AST_CASE ||/' src/parser.c
```

The mutation REMOVES `AST_COMPOUND_STMT` from the terminating set.  It
removes ONE disjunct of ONE condition; the compiler still builds
successfully and still produces a working compiler.

## 2. The measured observations

```text
PRISTINE_BUILD=PASS
PRISTINE_OBSERVATION:
  SUB001:ARM2_MARKER
  SUB001:x=1

MUTANT_BUILD=PASS
MUTATED_OBSERVATION:
  SUB001:ARM1_MARKER
  SUB001:ARM2_MARKER
  SUB001:x=1

RESTORED_BUILD=PASS
RESTORED_OBSERVATION:
  SUB001:ARM2_MARKER
  SUB001:x=1
```

```text
MUTATED_OUTPUT_DIFFERS=YES
RESTORED_OUTPUT_EQUALS_PRISTINE=YES
```

The comparison is a byte comparison of the two captured outputs:

```text
COMMAND=./witness-pristine > obs-p.txt ; ./witness-mutant > obs-m.txt ; ./witness-restored > obs-r.txt
COMMAND=cmp -s obs-p.txt obs-r.txt   -> identical
COMMAND=cmp -s obs-p.txt obs-m.txt   -> differ
```

The restored output is BYTE-IDENTICAL to the pristine output, so the
mutation -- and only the mutation -- produced the difference.

## 3. What this proves, and what it does NOT prove

```text
PROVES=the switch-arm termination decision is OBSERVABLE in compiled
        program output, and that mutating it changes that output
DOES_NOT_PROVE=a PolyC implementation exists
DOES_NOT_PROVE=the production delegation seam works
DOES_NOT_PROVE=the migration is semantically safe
```

Those three remain the successor's obligations.

## 4. The successor's own causal obligation

The successor MUST repeat this experiment with the PolyC component in
place of the C condition:

```text
G0 pristine legacy decision  -> output A
G1 mutated POLYC decision    -> output B, B != A
G2 restored POLYC decision   -> output A again
```

with the SAME witness, and MUST show that the mutant is a SUCCESSFULLY
BUILT compiler whose compiled program output differs.  A mutation that
merely makes the compiler crash or prevents linking is INSUFFICIENT.

## 5. The oracle-level causal control (already executed)

The same mutation was also applied to the extracted oracle, which
isolates the decision from the whole compiler:

```text
PRISTINE:  274 -> 1
MUTATED:   274 -> 0
```

That is the SAME semantic change the production mutation produces, and
it confirms that the mutation is confined to the terminating set.
