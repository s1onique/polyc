# SELECTED CAUSAL CONTRACT

## THE PURPOSE

This contract exists so that the successor ACT cannot repeat the
N-06 mistake, in which ONE PolyC-source mutation was reported under
TWO control IDs (N-06 and S7-CC-01) and the frozen N-06 obligation
("mutate ONLY the selected **C** decision") was never discharged.

**Two SEPARATE, TIME-SCOPED controls are required. One experiment
must not silently discharge two independently required controls.**

---

## CONTROL 1 -- `PRE-C-MUTANT`

```text
control_id              = RECON07-SUB-002-PRE-C-MUTANT
phase                   = PRE-MIGRATION (before the PolyC delegation exists)
source_subject          = the LEGACY C decision in src/parser.c
                          (the condition at src/parser.c:1683-1684, or
                          its factored-out equivalent)
selector_state          = the selector is OFF, so the C body executes
compiler_producer       = the real production compiler, built from the
                          current entry tree in an isolated build root
object_hash             = the SHA-256 of the PRODUCTION C TRANSLATION
                          UNIT object (the G0 object), and of the
                          production parser object
build_exit              = MUST be 0
witness_channel         = COMPILED_PROGRAM_SEMANTIC_OUTPUT_CHANGED
execution_id            = RECON07-SUB-002-PRE-C-MUTANT
restoration             = the C source MUST be restored BYTE-IDENTICALLY
                          and the production parser object MUST be
                          byte-identical to the pristine one
reuse_of_another_subject= NOT PERMITTED.  This control's subject is
                          the C decision.  It MUST NOT be satisfied by
                          the POST-POLYC-MUTANT experiment or by any
                          other experiment.
```

**THIS CONTROL IS ALREADY EXECUTED BY THIS ACT.** The successor MUST
CITE it as a recorded pre-migration event and MUST NOT re-run it as if
it were its own.

```text
REC07_PRE_C_MUTANT_EXECUTION_ID=RECON07-SUB-002-PRE-C-MUTANT
REC07_PRE_C_MUTANT_SOURCE_SHA256_MUTANT=e2dfc1176e9c28b0f722c63554d2a8688c4aa3fe519056a0619113ddb9a6fd22
REC07_PRE_C_MUTANT_SOURCE_SHA256_PRISTINE=2b31a7912bfbcfe538786aff17383a8282da815f0990910a652a0119f084fe17
REC07_PRE_C_MUTANT_PARSER_OBJECT_SHA256_MUTANT=35864f988ee8847a64affb6aa848038ac672775c892ef1d3c434a6caed0fc833
REC07_PRE_C_MUTANT_PARSER_OBJECT_SHA256_RESTORED=253d2404625c5bb2e5f0482465dae809c7d66c7360b1bb31e760f7f44c402246
REC07_PRE_C_MUTANT_BUILD_EXIT=0
REC07_PRE_C_MUTANT_WITNESS_PRISTINE=WITNESS_OUTPUT=110 155
REC07_PRE_C_MUTANT_WITNESS_MUTANT=WITNESS_OUTPUT=110 177
REC07_PRE_C_MUTANT_G0_ORACLE_CHANGED_ROW=274
REC07_PRE_C_MUTANT_RESTORATION_BYTE_IDENTICAL=YES
```

The successor MUST record, in its own evidence, that this control is
a **CITED PRIOR EXECUTION**, with the execution ID above, and that it
is a **pre-migration** event.

---

## CONTROL 2 -- `POST-POLYC-MUTANT`

```text
control_id              = RECON07-SUB-002-POST-POLYC-MUTANT
phase                   = POST-MIGRATION (after the delegation exists)
source_subject          = the ACTUAL COMPILED POLYC COMPONENT, i.e.
                          tools/bootstrap/<the successor's component>.HC
                          and the compiled object it produces
selector_state          = the selector is ON, so the production path
                          routes through the PolyC component
compiler_producer       = the real production compiler, built from the
                          migrated tree in an isolated build root
object_hash             = the SHA-256 of the compiled PolyC subject
                          object, and of the production parser object
build_exit              = MUST be 0
witness_channel         = COMPILED_PROGRAM_SEMANTIC_OUTPUT_CHANGED
execution_id            = RECON07-SUB-002-POST-POLYC-MUTANT
restoration             = the PolyC source MUST be restored
                          BYTE-IDENTICALLY and the production parser
                          object MUST be byte-identical to the pristine
                          one
reuse_of_another_subject= NOT PERMITTED.  This control MUST be
                          NEWLY EXECUTED BY THE SUCCESSOR ACT.  It MUST
                          NOT be satisfied by the PRE-C-MUTANT
                          experiment, by the G0 legacy oracle, or by
                          any inference from them.
```

**THIS CONTROL IS NOT YET EXECUTED AND MUST NOT BE CLAIMED AS
EXECUTED BY THIS ACT.** This ACT does NOT migrate the decision, so it
cannot execute this control. The successor MUST execute it.

---

## CONTROL 3 -- `SLICE08-C-OFF-C-MUTANT` (only if the successor
## inherits a C-mutant demand)

```text
control_id              = RECON07-SUB-002-SLICE08-C-OFF-C-MUTANT
phase                   = POST-MIGRATION, C-AUTHORITATIVE configuration
source_subject          = the LEGACY C decision in src/parser.c
selector_state          = the selector is OFF (a genuine isolated
                          C-OFF build of the migrated tree)
compiler_producer       = the real production compiler, C-OFF
object_hash             = the SHA-256 of the C-OFF production parser
                          object
build_exit              = MUST be 0
witness_channel         = COMPILED_PROGRAM_SEMANTIC_OUTPUT_CHANGED
execution_id            = RECON07-SUB-002-SLICE08-C-OFF-C-MUTANT
restoration             = BYTE-IDENTICAL source and object restoration
reuse_of_another_subject= NOT PERMITTED.  This is a DISTINCT experiment
                          from the PRE-C-MUTANT one, because the tree
                          it runs on is the MIGRATED tree, not the
                          pre-migration tree.  It MUST NOT be satisfied
                          by citing RECON07's PRE-C-MUTANT result.
```

**This control is REQUIRED ONLY IF the successor's own frozen
contract demands a C mutant during SLICE08.** If it does, it must be
executed as a distinct experiment with its own execution ID, exactly
as ACT-POLYC-SELFHOST-PARSER-SLICE07-EVIDENCE-CORRECTION01 did for
N-06.

---

## THE SHARED-EXECUTION RULE

If, and only if, two of the above control IDs are to be discharged by
ONE physical experiment, then BOTH rows MUST:

* state explicitly, in their own evidence, that they SHARE that
  experiment,
* name the shared execution ID,
* and MUST NOT claim experiment independence.

No other arrangement is acceptable. One experiment discharging two
controls without an explicit sharing statement is the exact N-06
defect and is FORBIDDEN.

---

## THE DECLARED OBSERVATION CHANNEL

```text
CHANNEL=COMPILED_PROGRAM_SEMANTIC_OUTPUT_CHANGED
DECLARED_BEFORE=the mutation is applied
WITNESS=the default-arm compound-statement witness:
    switch (x) {
      case 1: r = 10; break;
      default:
        { r = 55; }
        r = 77;
    }
EXPECTED_PRISTINE_OUTPUT=WITNESS_OUTPUT=110 155
EXPECTED_MUTANT_OUTPUT=WITNESS_OUTPUT=110 177
```

A witness **compile failure** after a **successful** mutant compiler
rebuild is a valid `COMPILER_ACCEPTANCE_CHANGED` observation and MUST
NOT be mislabeled as a runtime output change. The three exits (the
compiler build exit, the witness compile exit and the witness run
exit) MUST be recorded separately, as they are in
`c2/candidate-causality-raw.tsv`.
