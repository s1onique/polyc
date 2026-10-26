# HANDOFF — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01

**Repository:** https://github.com/s1onique/polyc
**Branch:** main
**Class:** GOVERNANCE / CORRECTION / CONTRACT
**Predecessor:** ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
**Production semantic changes:** NONE

---

## 1. What this ACT did

An independent review of the predecessor's closure found five binding
contract defects. This ACT publishes a **corrected, forward-only**
successor-facing contract and corrects the predecessor's verdict. It
mutates **no** production source, rebuilds **no** compiler generation,
rewrites **no** history, and regenerates **no** unrelated evidence.

The predecessor's closed evidence directory, ACT document and HANDOFF
are **not modified** (F14). Every correction lives in new artifacts
under `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/`.

## 2. The five defects, and the corrections

| Sev | Defect | Correction |
|-----|--------|------------|
| P0 | `c2-selected-fixture-model.tsv` F041 expected `0`, but the real C function returns `1` | F041 `expected_result` -> `1`; counts 22/20 -> **23/19** |
| P0 | Ranking CONTROL 6 reported CAND-004 as the "next eligible winner"; CAND-004 is `eligible = NO` | CONTROL 6 re-run over the **full eligibility predicate** |
| P1 | Ranking CONTROL 5 perturbed the broad (state-boundary) ranking, not the eligible set | CONTROL 5 re-run over the **full eligibility predicate**, in a falsifiable form |
| P1 | `INVENTORY_TOTAL=16` while the inventory carried 17 rows | corrected total **17** |
| P1 | LEXER07 "21 sources currently fail" conflated the baseline with the current | baseline **21** separated from current **15** |

### The P0 fixture defect, proven against the production function

`TK_SUPERSCRIPT` (`src/lexer.h:15`) and `TK_STR` (`src/lexer.h:19`)
are **both** `0x301`. The legacy C body compares the kind **by
number** (`src/parser.c:835`: `if (tok->tk_type == TK_STR) return 1;`),
so kind `0x301` is `TK_STR` and is **accepted**, whatever the payload.

The reference side is the **real** production function, linked from
`build/CMakeFiles/hcc.dir/parser.c.o` — not a re-implementation of the
decision table, which the predecessor's ABI contract section 8
forbids.

```text
predecessor matrix:  ROWS=42 ACCEPT=23 REJECT=19 DISAGREE=1   (F041)
corrected matrix:    ROWS=42 ACCEPT=23 REJECT=19 DISAGREE=0
```

The predecessor's own ABI contract already stated the correct
behaviour (`| 1 | TK_STR (0x301) | (any) | **1** | :835 |`); only the
matrix contradicted it. **The successor's differential is now
satisfiable** — under the predecessor's matrix it was not.

### The P0 ranking-control defect

The ranker drops `eligible != YES` before sorting. The predecessor ran
CONTROL 5 and CONTROL 6 over `rank-input-full.tsv`, whose six rows all
carry a hard-coded `eligible=YES` (the *state-boundary* set), instead
of the full hard-eligibility predicate the controls claim to test.

Against the **real** full-eligibility set — whose membership is
re-derived by the eligibility checker (`build/slice-recon02-rank/elig.sh`)
directly from the predecessor's committed C1 artifacts:

```text
CONTROL 5: raising CAND-001's R0 does NOT change the leader
           (the eligible set has exactly one member)
CONTROL 6: removing CAND-001 leaves ZERO ranked rows
           (CAND-004 does NOT win -- it is not eligible)
```

Both controls are re-stated in a **falsifiable** form in which a second
candidate is present, so the claimed effect is actually observable: the
leader does change, and the next eligible candidate does win.

**The second candidate's eligibility is proven, not assumed.** It is
built as a *complete* candidate (a row in all four of the predecessor's
committed C1 artifacts), put through the real eligibility checker, and
**admitted by that checker** (13/13 clauses). The rank input is then
joined from the checker's output, so no `eligible` flag is hand-written
for any synthetic row. The checker's *negative* behaviour is demonstrated
too — flipping one inventory field flips clause 2 and the candidate is
rejected — so the admission is a real verdict and not a rubber stamp.

## 3. What is NOT changed

| Item | Value | Changed? |
|------|-------|----------|
| Selected candidate | CAND-001 `parseValidPostControlFlowToken` | NO |
| Source range | `src/parser.c:832..864` | NO |
| ABI | `I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value) -> I64` | NO |
| `ABI_HOST_IDENTITY_FIELDS` | 0 | NO |
| Eligibility conjunction | the 13 hard-eligibility clauses | NO |
| Scoring | (R0, R1, R2, R3, R4, R5, R6), R0 first | NO |
| Eligible set | {CAND-001} | NO |
| RED model | RED-1..RED-5 | NO |
| Proof model | 16 dimensions | NO |
| Production seam | 5 ordinary call sites | NO |
| Successor ACT | `ACT-POLYC-SELFHOST-PARSER-SLICE02` | NO |

The corrected contract carries **42** items: **11 changed, 31
unchanged** (`c2/c2-corrected-contract.tsv`). The three counters are
derived from the contract TSV's own rows by `awk`, not entered by hand;
the derivation command is recorded in `c2/c2-required-result.txt` as
`COMMAND_2`.

## 4. The successor's frozen inputs

The successor MUST use:

- fixture matrix:
  `evidence/ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01/c1/c1-corrected-fixture-model.tsv`
  (42 rows, 23 accept, 19 reject)
- legacy C oracle: `src/parser.c:832..864`,
  `parseValidPostControlFlowToken`
- bound constants: the live `src/lexer.h` values, bound **by number**
  (`TK_IDENT 0x300`, `TK_STR 0x301`, `TK_PUNCT 0x329`,
  `TK_KEYWORD 0x332`, `TK_PLUS_PLUS 0x305`, `TK_MINUS_MINUS 0x306`,
  and the 12 accepted keyword payloads)

**The aliasing the successor MUST honour:** `TK_SUPERSCRIPT` and
`TK_STR` are both `0x301`. At the ABI level `0x301` is `TK_STR` and is
**ACCEPTED**. A successor that assumed a distinct "superscript" kind
would produce a different result and fail the differential. F041 pins
it — with the expectation `1`.

## 5. Gates

```text
GATE_FAST     = PASS (RC=0; 5/5 checks; manifest PAIR_OK=26 PAIR_FAIL=0)
FACTORY_V2    = PASS (PASS=53 FAIL=0)
APPEND_ONLY   = PASS (PASS=11 FAIL=0)
PATCH_HYGIENE = PASS (git diff --check over the COMMITTED correction
                      range -> RC=0; covers the new files by construction)
F14           = PASS (predecessor evidence / ACT doc / HANDOFF deltas 0)
F_NO_PYTHON   = PRE_EXISTING_VIOLATIONS (RC=1; 12 tracked .py; 0 touched)
F_POLYC_TOOLS = PRE_EXISTING_VIOLATIONS (RC=1; 0 new)
AC_LEDGER     = 13 PASS / 1 DEFERRED / 0 FAIL
```

The two checker failures are PRE-EXISTING baseline violations in files
this ACT does not touch. They are **not waived**: their exact results
are recorded in `c3/c3-required-result.txt`.

**Patch hygiene is checked over the committed range, not the working
tree.** `git diff --check HEAD` sees only tracked files, so it reported
RC=0 while three of this ACT's own new files carried a trailing blank
line at EOF. Re-running it with `git add -N` exposed those three
defects; they were repaired, and the final check covers the committed
correction range.

**AC14 is DEFERRED until the CLOSE commit exists.** It asserts that the
predecessor's verdict has been corrected through the `ACT-Supersedes` /
`ACT-Corrected-Verdict` trailers. A validated *proposed* commit message
is not a committed CLOSE. AC14 is established in the CLOSE phase against
the actual CLOSE commit; no PASS is claimed for it beforehand.

## 6. The predecessor's verdict

The predecessor's own history is not rewritten. Its CLOSE commit keeps
`PASS_TRUE_GREEN`; this ACT's CLOSE carries the correction:

```text
ACT-Supersedes: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT-Corrected-Verdict: HALT_CONTRACT_DEFECT_UNRESOLVED
```

The corrected verdict says the historical ACT did not satisfy its
written contract. It does **not** invalidate the mechanically-proven
production dependency the successor requires, so roadmap progression
stays unblocked.

## 7. Verdict

VERDICT

---

PASS

---

### The post-CLOSE read-only step (AC14)

AC14 — *the predecessor's verdict is corrected forward-only* — asserts
something that only becomes true when a **committed** CLOSE exists. It
is therefore recorded as DEFERRED in the AC ledger, exactly as the
predecessor ACT recorded its own AC50. It is established by the
following read-only step, which runs after this CLOSE commit exists and
writes nothing:

```text
sh scripts/quality/factory-v2-range-check.sh \
   ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01 <CLOSE sha>

git --no-pager log -1 --format='%B' <CLOSE sha> | git interpret-trailers --parse
```

The trailer block is a single terminal region:

```text
ACT: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-SELFHOST-PARSER-SLICE-RECON02
ACT-Corrected-Verdict: HALT_CONTRACT_DEFECT_UNRESOLVED
```

A `PASS` verdict carries no `HALT_CLASS` and no `BLOCKS_NEXT`, as
`tools/factory/factory-halt-classification.HC` requires.
