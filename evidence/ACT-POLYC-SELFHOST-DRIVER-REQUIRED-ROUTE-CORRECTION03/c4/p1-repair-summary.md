# CORRECTION03 C4 P1 REPAIR SUMMARY

This is FORWARD-ONLY evidence for the C4 remediation of the three P1
findings raised by the independent Codex review of the C3 head. The C0,
C1, C2 and C3 commits and their source bytes are preserved exactly as
committed.

The working production precedence decision in
`tools/bootstrap/selfhost-driver-wp001.HC` is NOT modified by this
remediation. The C2 implementation's precedence logic is correct: it was
re-verified independently by the reviewer, and the C4 evidence measures
it, but does not change it.

## P1-1 -- THE FRESH-BUILD TARGET

### THE DEFECT

The committed rule was:

```make
driver-wp001-correction03-test: $(DRIVER_ROUTE03_COMPARE_BIN) $(DRIVER_ROUTE03_ABI_BIN)
	@rm -rf $(DRIVER_ROUTE03_WORKDIR)
	...
$(DRIVER_ROUTE03_ABI_BIN): $(DRIVER_ROUTE03_ABI_OBJ) $(DRIVER_ROUTE03_WORKDIR)/wp001-driver-subject.o src/selfhost-driver-wp001.c
```

`$(DRIVER_ROUTE03_WORKDIR)/wp001-driver-subject.o` had NO production
rule. It was produced only as a SIDE EFFECT of the ON cmake build inside
the recipe, which runs AFTER Make has already tried to satisfy the ABI
binary's prerequisite. The recipe's `rm -rf $(DRIVER_ROUTE03_WORKDIR)`
also DELETED it.

A fresh isolated build therefore FAILED:

```text
make: *** No rule to make target `build/driver-wp001-correction03/wp001-driver-subject.o', needed by `build/driver-required-route-correction03-abi-probe'.  Stop.
```

The RED is recorded in `p1-1-red-fresh-build.log`.

### THE REPAIR

An EXPLICIT, CORRECTLY ORDERED production chain was introduced. Each
step has its own rule, its own file target, and its own failure
propagation:

```text
1. $(DRIVER_ROUTE03_SUBJECT_STAMP)  the PolyC driver subject, produced by
   the REAL stage0 producer from the REAL PolyC source and VERIFIED:
   presence, nonzero size, object-file class, and ALL THIRTEEN exported
   driver symbols. A producer that exits 0 without producing the object
   is a HARD ERROR.
2. $(DRIVER_ROUTE03_SUBJECT_OBJ)    the object itself, re-checked for
   presence after its producer rule.
3. $(DRIVER_ROUTE03_OFF_HCC)        the fresh selector-OFF C oracle.
4. $(DRIVER_ROUTE03_ON_HCC)         the fresh selector-ON PolyC compiler.
5. $(DRIVER_ROUTE03_ABI_BIN)        links (2) and is a prerequisite of the
   test target, so the subject is ALWAYS resolved BEFORE its consumer.
```

### THE CLEANUP RACE

The STAMP mechanism is what removes the race:

* the STAMP is written ONLY AFTER the subject has been produced AND
  verified, so a required prerequisite cannot disappear after the
  consumer has been planned;
* the producer rule deletes ONLY the subject object it is about to
  produce, and NEVER the whole work directory, so it cannot delete the
  OFF or ON compiler, which are separate rules with separate build
  directories.

The measured evidence is in `p1-1-failure-mode-matrix.tsv`: the OFF and
ON compilers SURVIVE a re-run of the subject rule.

### THE INDEPENDENT FAILURE DETECTION

Every failure mode is detected by its OWN distinct reason token, and no
failure is detected by a downstream symptom. The measured matrix is in
`p1-1-failure-mode-matrix.tsv`.

## P1-2 -- THE COMPARISON INFRASTRUCTURE

### THE DEFECT

The committed comparator computed the artifact class of both sides,
checked that the classes agreed, and checked that the bytes agreed.
That is a WEAK NEGATION: two IDENTICAL GARBAGE files agree with each
other, and two MISSING files agree with each other, so the comparator
reported PASS on inputs that carried no evidence at all. It also did not
check the exit status, the stderr transcript, the architecture, or the
symbols.

### THE REPAIR

The comparator now VALIDATES EVERY OBSERVATION BEFORE IT COMPARES IT:

* the artifact MUST be present;
* the artifact MUST be nonempty;
* the artifact MUST be of the EXPECTED class;
* the artifact MUST carry the EXPECTED architecture;
* the artifact MUST carry the REQUIRED symbols;
* the compiler exit status MUST be RECORDED and MUST be the EXPECTED
  one;
* stdout MUST be EXACTLY equal;
* stderr MUST be EXACTLY equal;
* the artifact content digest MUST be equal.

The ONLY normalization is the EXPLICITLY FROZEN one: a trailing carriage
return is stripped. NOTHING else is normalized.

The EXPECTED class and architecture are DERIVED FROM THE GENUINE
selector-OFF C ORACLE by the comparator's own `derive` mode, so the
expectation is an OBSERVATION of the reference and not a restatement of
the implementation's own belief.

The symbol check reads the artifact's OWN Mach-O `LC_SYMTAB` string
table. The content digest is computed by the comparator itself over the
raw artifact bytes; it is never taken from the harness.

### THE ADVERSE PROBES

Ten probes each take a FRESH, ISOLATED copy of a known-good comparator
input, mutate or remove exactly ONE observable, and assert that the
comparator REJECTS the mutated input.

The measured rejection ledger is in
`p1-2-adverse-probe-rejection-ledger.tsv`. Every probe is rejected for
its OWN DISTINGUISHING reason. The `IDENTICAL_GARBAGE` probe is the
decisive one: it makes the two sides AGREE with each other, and it is
still rejected, because only the INDEPENDENT VALIDATION can reject it.

## P1-3 -- THE EMISSION COVERAGE

### THE DEFECT

The committed evidence established the emission precedence for the
OBJECT and the ASSEMBLY domain only, because those are the two domains a
single `-o` output file can express. The DYNAMIC LIBRARY domain
produces THREE artifacts and the EXECUTABLE domain produces a LINKED
EXECUTABLE, and neither had a production executable witness.

### THE REPAIR

A production executable witness was added for each of the four emission
domains:

```text
object      the `-c` route
assembly    the `-S` route
dylib       the `-lib <name>` route, which produces THREE artifacts
executable  the default route, which produces a LINKED EXECUTABLE
```

The expectations are DERIVED FROM THE GENUINE selector-OFF C ORACLE.

The EIGHT MANDATORY PRECEDENCE CASES ARE RETAINED. The canonical
coverage is EXPANDED to include the previously independently verified
DEFAULT and DYLIB paths.

The selected-emission ABI probe was EXTENDED from EIGHT cases to
SIXTEEN, so that every supported selected-emission value has OBSERVED
dispatch behavior and the INVALID values fail closed:

```text
the DYNAMIC LIBRARY domain, in two argv shapes
the EXECUTABLE (default) domain, in two argv shapes
the DYNAMIC LIBRARY domain outranking the EXECUTABLE domain
the OBJECT domain outranking the DYNAMIC LIBRARY domain
an ARITY VIOLATION failing closed to the UNKNOWN emission
an argv with NO SOURCE FILE failing closed to the UNKNOWN emission
```

The measured roster is in `abi-domain-coverage.tsv`.

An EMISSION-DOMAIN FAIL-CLOSED check was added: every supported
selected-emission value must be CONSUMED by the C consumer with an
explicit case, and an OUT-OF-DOMAIN value must be REJECTED by the
default case with an EXPLICIT diagnostic. This is the emission-domain
counterpart of the existing status-domain R06 check.

### THE ARCHIVE DISTINCTION

The static archive produced by the dylib route carries NONDETERMINISTIC
HEADER METADATA (the member timestamps, the owner/mode, the padding),
while its MEMBER BYTES are deterministic. The witness therefore records
the FULL ARTIFACT BYTE result and the ARCHIVE-MEMBER SEMANTIC result as
SEPARATE results:

```text
ARCHIVE_MEMBER_SEMANTICS          the member bytes agree
ARCHIVE_FULL_BYTES                the whole archive file agrees
ARCHIVE_METADATA_NONDETERMINISM   whether the two differ
```

A difference in the member bytes is a SEMANTIC difference and is a
FAILURE. A difference in the header bytes alone is METADATA
NONDETERMINISM and is neither an equivalence failure nor an equality
claim.

### THE FORWARD-ONLY STATUS

These tests were NOT frozen before the implementation. They are NEW,
FORWARD-ONLY supplemental evidence, and they are recorded as NEW. No
claim of preimplementation freezing is made anywhere in this ACT's
forward-only evidence.
