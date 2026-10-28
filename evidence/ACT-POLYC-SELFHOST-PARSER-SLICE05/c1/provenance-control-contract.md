# ACT-POLYC-SELFHOST-PARSER-SLICE05 -- C1 PROVENANCE-CONTROL CONTRACT

**ACT_PHASE:** C1-EVIDENCE
**EVIDENCE_KIND:** provenance-control-contract

## 1. Why SLICE05 needs its own provenance verifier

SLICE04's verifier (`tools/quality/parser-slice04-provenance-verifier.HC`)
is closed evidence under F14 and MUST NOT be modified.  It also cannot
express the two controls the ACT requires, because:

* it has **no per-generation BINDING field** to compare, so it cannot
  distinguish "the G3 row carries the G1 payload" from "the G3 row is
  the G3 payload"; and
* its receipt-omission reason is **generic**
  (`REJECT_OMITTED_EXECUTION_RECEIPT`) and names whichever generation
  happens to fail first, so it cannot produce a **G3-scoped** omission
  reason.

Therefore SLICE05 implements its OWN verifier:

```text
tools/quality/parser-slice05-provenance-verifier.HC
```

It adds:

* a per-generation **BINDING** field (`GENERATION_BINDING`), which
  records the generation's expected stage identity and run binding id;
* **generation-scoped** rejection reasons, so a G3 defect is reported
  as a G3 defect;
* the ability to report **ALL** diagnostics, not only the first
  failing check.

## 2. The witness format

The witness is a flat `KEY=VALUE` file with four generation blocks, in
the order `g0`, `g1`, `g2`, `g3`.  Each block carries:

```text
GENERATION=<g0|g1|g2|g3>
GENERATION_BINDING=<the expected stage identity and run binding id>
COMPILER_INVOCATION=<the command that was typed>
COMPILER_RESOLVED_PATH=<the resolved absolute path of the compiler>
COMPILER_BINARY_SHA256=<the sha256 of that compiler>
COMPILER_VERSION=<the compiler's version string>
SOURCE_PATH=<the component source path>
SOURCE_SHA256=<the sha256 of that source>
EXACT_BUILD_COMMAND=<the exact build command>
OUTPUT_OBJECT_PATH=<the produced object path>
OUTPUT_OBJECT_SHA256=<the sha256 of that object>
LINKED_BINARY_PATH=<the linked probe binary path>
LINKED_BINARY_SHA256=<the sha256 of that linked binary>
PROVENANCE_NONCE=<the generation's nonce>
PROBE_EXECUTION_OUTPUT=<the probe's ACTUAL stdout>
PROBE_EXECUTION_EXIT_CODE=<the probe's exit code>
EXECUTION_RECEIPT_ID=<the receipt id>
RUN_BINDING_ID=<the run binding id>
```

## 3. What the verifier checks

For every generation:

1. the `GENERATION` label is one of the four expected labels;
2. the `GENERATION_BINDING` equals the **expected binding for that
   generation** -- this is the field that makes a G1 payload in the G3
   slot detectable;
3. the `PROVENANCE_NONCE` is present;
4. the `PROBE_EXECUTION_OUTPUT` is present and EQUALS the nonce (so the
   witness was produced by a REAL EXECUTION);
5. the recorded `COMPILER_BINARY_SHA256` equals the ACTUAL sha256 of
   the recorded `COMPILER_RESOLVED_PATH`;
6. the recorded `OUTPUT_OBJECT_SHA256` equals the ACTUAL sha256 of the
   recorded `OUTPUT_OBJECT_PATH`;
7. the recorded `SOURCE_SHA256` equals the ACTUAL sha256 of the
   recorded `SOURCE_PATH`;
8. the four generations' nonces are DISTINCT;
9. the `EXECUTION_RECEIPT_ID` and `RUN_BINDING_ID` are present.

## 4. The five mandatory negative controls

| ID | Mutation | Required rejection |
|---|---|---|
| NC-P01 | G1 witness payload placed in the G3 slot; all four generations remain present | `G3_BINDING_MISMATCH` |
| NC-P02 | Only G3 execution receipt removed | `G3_EXECUTION_RECEIPT_MISSING` |
| NC-P03 | One compiler SHA changed | `G3_COMPILER_IDENTITY_MISMATCH` (or the affected generation's) |
| NC-P04 | Validly linked but non-byte-identical subject substituted | `G3_OBJECT_IDENTITY_MISMATCH` (or the affected generation's) |
| NC-P05 | G1 and G3 stage identities interchanged | `G3_STAGE_IDENTITY_MISMATCH` (or the affected generation's) |

For EVERY control:

```text
PRISTINE_VERDICT=PASS
MUTATION_TARGET=<exact field>
NON_TARGET_FIELDS_UNCHANGED=YES
MUTANT_VERDICT=REJECTED
REJECTION_REASON=<expected class>
PRISTINE_RECHECK=PASS
```

## 5. THE CORRECTION OF THE TWO SLICE04 DEFECTS

### NC-P01 -- the G1 payload in the G3 slot

The control MUST start from a complete, valid four-generation witness
and MUST preserve:

```text
GENERATION_ROWS=4
STAGE_LABELS=G0,G1,G2,G3
ALL_REQUIRED_RECEIPTS_PRESENT=YES
```

It replaces **only the G3 block's payload** with the G1 block's
payload.  The G3 block keeps its `GENERATION=g3` label; the other
three blocks are **byte-for-byte unchanged**.

Required:

```text
NC_G3_SUBSTITUTION_MANIFEST_COMPLETE=YES
NC_G3_SUBSTITUTION_CHANGED_TARGET=G3
NC_G3_SUBSTITUTION_OTHER_ROWS_UNCHANGED=YES

NC_G3_SUBSTITUTION_REJECTED=YES
NC_G3_SUBSTITUTION_REJECTION_REASON=G3_BINDING_MISMATCH
```

**A row-count, missing-generation, or malformed-input rejection is NOT
sufficient.**  The reason must be the G3-specific binding mismatch.

### NC-P02 -- the G3 receipt omission

The control starts from the same complete valid four-generation
baseline and removes **only** the G3 execution receipt.  Every G0, G1
and G2 receipt is retained **byte-for-byte**.

Required:

```text
NC_G3_OMISSION_TARGET=G3
NC_G0_RECEIPT_PRESERVED=YES
NC_G1_RECEIPT_PRESERVED=YES
NC_G2_RECEIPT_PRESERVED=YES

NC_G3_OMISSION_REJECTED=YES
NC_G3_OMISSION_REJECTION_REASON=G3_EXECUTION_RECEIPT_MISSING
```

## 6. THE VALIDATION ORDERING

The controls MUST also record **ALL** parsing and structural
diagnostics, not merely the first failure.

A verifier that rejects because an earlier, unrelated field is broken
has NOT proven the intended negative control.  The verifier therefore
does **not** short-circuit on the first failure: it evaluates every
check for every generation and reports every diagnostic it finds, then
emits the verdict.

This is precisely what SLICE04's verifier could not do, and it is the
root cause of both historical defects.

## 7. The pristine recheck

After EVERY negative control:

```text
PRISTINE_MANIFEST_VALID=YES
PRISTINE_PROVENANCE_VERDICT=PASS
```

The pristine witness is re-verified after each control, so a control
cannot "consume" the witness or leave the store in a state that hides
a later control.

## 8. THE HONEST SECURITY BOUNDARY

Byte-identical G1/G2/G3 objects do not carry their own build identity.

A locally recorded compiler SHA, execution receipt, and object SHA can
prove **CONSISTENCY WITH INDEPENDENTLY RETAINED BUILD OBSERVATIONS**.
They CANNOT prove resistance to an adversary who can rewrite the entire
evidence store, because such an adversary can rewrite the recorded
SHAs along with everything else.

SLICE05 therefore claims exactly what its controls demonstrate:

```text
DETECTION OF THE SPECIFIED WITNESS SUBSTITUTIONS AND OMISSIONS
  = DEMONSTRATED
RESISTANCE TO A TOTAL EVIDENCE-STORE REWRITE
  = NOT CLAIMED
```

No claim of cryptographically unforgeable provenance is made anywhere
in SLICE05.
