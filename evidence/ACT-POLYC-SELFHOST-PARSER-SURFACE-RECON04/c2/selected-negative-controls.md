# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON04 -- SELECTED NEGATIVE CONTROLS

**SELECTED_CANDIDATE:** `SUB-001`

---

## 1. Fixture negative controls (ACT section 11.2)

Each control MUST fail for the INTENDED reason.  A control that is
rejected for an unrelated reason does NOT demonstrate the intended
detector.

| ID | Control | Intended failure |
|---|---|---|
| FC-01 | delete one row for a TERMINATING kind (e.g. `AST_BREAK`) from the fixture | `MISSING_IDS=1` |
| FC-02 | duplicate one fixture row under a second id | `DUPLICATE_IDS=1` |
| FC-03 | add a row whose id is not in the producer's id space | `UNKNOWN_IDS=1` |
| FC-04 | add an unknown row with LEADING WHITESPACE, so a naive parser would skip it | `UNKNOWN_IDS=1` (the whitespace must not hide the row) |
| FC-05 | corrupt one row's copied record (a malformed kind field, e.g. `abc`) | `MALFORMED_ROWS=1` |
| FC-06 | put an out-of-range numeric value in one row's kind field | `INVALID_INPUT_VALUES=1` |
| FC-07 | delete a BOUNDARY row (the enum's last value) | `MISSING_IDS=1` and `UNTESTED_SEMANTIC_BRANCHES=1` |
| FC-08 | change one row's expected result | the differential reports exactly one mismatch, at that row |

## 2. Production-differential negative controls

| ID | Control | Intended failure |
|---|---|---|
| PD-01 | the PolyC component returns the INVERSE of the legacy decision for one kind | exactly one differential mismatch |
| PD-02 | the PolyC component omits one terminating kind | exactly one differential mismatch |
| PD-03 | the PolyC component adds one non-terminating kind | exactly one differential mismatch |
| PD-04 | the delegation macro is defined but the production object still contains the legacy condition | the object-level legacy-condition check FAILS |

## 3. Production-semantic negative controls

| ID | Control | Intended failure |
|---|---|---|
| PS-01 | the production delegation is REMOVED while the PolyC component remains | the production object no longer references `BootstrapSwitchArmTerminates`, and the delegation-load-bearing check FAILS |
| PS-02 | the PolyC component is mutated to drop `AST_COMPOUND_STMT` from the terminating set | the causal witness output CHANGES (ARM1_MARKER appears), so the mutation is detected as a real semantic change |
| PS-03 | the causal mutation is reverted | the witness output returns BYTE-IDENTICAL to the pristine output |

## 4. Structural-boundary negative controls

| ID | Control | Intended failure |
|---|---|---|
| SB-01 | the candidate is classified `SCALAR_FOLLOWUP` instead of `STRUCTURAL_BOUNDARY` | the class partition changes and the winner changes to `CAND-022` |
| SB-02 | the candidate's structural effect is removed from its record | the structural classification check FAILS |
| SB-03 | the candidate is given a production call site that does not exist | the production-reachability check FAILS |

## 5. What the successor must run

The successor MUST run EVERY control above and MUST report, for each,
the intended failure reason.  A control that fails for a different
reason is a FAILURE of the control, not a pass.
