# Q3 EVIDENCE SUMMARY

**ACT:** `ACT-POLYC-SELFHOST-DRIVER-BOUNDARY-QUALIFICATION01`
**Phase:** Q3-EVIDENCE

## WHAT Q3 PRODUCES

| artifact | what it is |
|---|---|
| `nc01-nc24-execution-matrix.tsv` | every frozen negative control, executed pristine / adverse / restored |
| `acceptance-ledger.tsv` | the frozen 50-ID acceptance roster, discharged |
| `baseline-conservation.tsv` | every predecessor baseline, re-measured and compared |
| `gate-results.tsv` | the canonical gates, run against the exact committed tree |
| `independent-recomputation.tsv` | the independent recomputation vs the compiled verifier |
| `run-nc-matrix.sh`, `nc-cases.sh`, `run-acceptance-ledger.sh`, `run-baseline-conservation.sh`, `run-gates.sh`, `run-independent-recomputation.sh` | the six executable evidence producers |

## THE NEGATIVE-CONTROL MATRIX

**24 of 24 adverse controls fire their OWN reason token and exit
non-zero. 0 unexpected results.** The pristine and restored phases are
SILENT for every control.

Each control's adverse input is BUILT by mutating one specific fact of
one specific table, on a DISPOSABLE COPY. The construction is in
`nc-cases.sh` and is therefore auditable rather than asserted.

### SIX CONTROLS THAT REQUIRED NEW DETECTION

Six of the frozen roster's expected reason tokens had **never been
implemented** in either detector:

```text
CORRECTION_CLOSE_IDENTITY_WRONG          NC02
NON_ACT_TRAILER_PROMOTED                 NC03
HISTORICAL_CLOSE_DUPLICATE_HIDDEN         NC04
MUTATION_LINK_PROVENANCE_MISSING         NC16
G0_DRIVER_CONTAMINATED                   NC17
COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE  NC18
```

This is a real gap in the frozen contract, disclosed here rather than
worked around: the roster froze 24 controls whose tokens the Q0 RED
detector did not implement and the Q2 verifier did not cover.

The gap was closed in the **verifier**, not in the roster:

- `CORRECTION_CLOSE_IDENTITY_WRONG` and
  `HISTORICAL_CLOSE_DUPLICATE_HIDDEN` are CHRONOLOGY-mode checks on
  the newly measured `CORRECTION04_TERMINAL_CLOSE` and
  `HISTORICAL_DUPLICATE_CLOSES` keys.
- `NON_ACT_TRAILER_PROMOTED`, `MUTATION_LINK_PROVENANCE_MISSING`,
  `G0_DRIVER_CONTAMINATED` and
  `COMPILER_SEMANTIC_COMPARATOR_INSENSITIVE` are a new **LINKS** mode,
  because all four ask the same question: is the claimed link between
  a source fact and an observed effect actually PRESENT, or has it
  been ASSUMED?

The frozen roster was NOT edited.

## THE ACCEPTANCE LEDGER

```text
LEDGER_PASS     = 46
LEDGER_FAIL     = 0
LEDGER_DEFERRED = 5
```

The five DEFERRED criteria are `AC47`, `AC48`, `AC49` (the Q4 close)
and `AC50` plus `AC_ROSTER_SIZE` (the external post-CLOSE probe).
They are DEFERRED, not PASS: they cannot be discharged before the
events they describe have happened.

Every PASS is tied to a NAMED, MEASURED artifact. The witness column
of the ledger names the artifact; the measured column states what was
measured.

## THE BASELINE CONSERVATION

**0 conservation mismatches.** Every baseline the WP-001 ACT family
recorded at its C0 was re-measured from the SAME commands:

| baseline | historical | measured |
|---|---|---|
| parser assertions | 376/376 over 90 files | 376/376 over 90 files |
| parser assertion-sequence MD5 | `b6f117eb1386ca80f81bc06226e2a741` | identical |
| parser failed lines | 0 | 0 |
| LEXER07 direct diff | 89 / 0 | 89 / 0 |
| LEXER08 direct diff | 45 / 0 | 45 / 0 |
| LEXER09 direct diff | 23 / 0 | 23 / 0 |
| F_NO_PYTHON paths | 12 | 12 |
| gate-fast | PASS | PASS |
| the WP-001 historical row counts | 32 / 13 / 16 / 3 | identical |

### THE HISTORICAL NON-GREENS ARE NOT CONVERTED TO PASS

```text
LEXER07_BROAD_CORPUS_STATUS       NOT_REMEASURED  -> NOT_REMEASURED
CROSS_TARGET_PREFIX_STATUS        NOT_REMEASURED  -> NOT_REMEASURED
F_NO_PYTHON_STATUS                FAIL_KNOWN_BASELINE -> FAIL
```

The two `NOT_REMEASURED` baselines stay `NOT_REMEASURED`: this ACT has
no scope to re-measure them, and relabelling them would be a false
green.

### THE HERMETIC PARSER PREFIX, AND WHY IT IS PROVEN TO BE THE SAME

The parser runner compiles each test file with a BARE `../../hcc`,
i.e. WITHOUT `--install-dir`, so the builtin header resolves at the
COMPILE-TIME constant `INSTALL_PREFIX`, which is `/usr/local` for the
production build.

On this machine `/usr/local/include` DOES NOT EXIST and cannot be
created (no sudo). **This is an ENVIRONMENT PRECONDITION, NOT A
REGRESSION**, and the predecessor recorded exactly the same condition
and exactly the same hermetic solution.

The baseline is therefore measured with a compiler configured with
`-DCMAKE_INSTALL_PREFIX=<abs>/build/test-prefix` and the SAME feature
set as the production tree (`HCC_ENABLE_JIT=ON`), so the bare
`../../hcc` resolves the SAME header through the hermetic prefix. The
substitution is PROVEN to be a substitution of the SAME CONTENT:

```text
TEST_PREFIX_TOS_HH_BYTES  historical 56333  measured 56333  MATCH
```

The test corpus, the compiler, the header content and the runner are
otherwise unchanged, and the production `./hcc` is restored
immediately after the run.

## THE INDEPENDENT RECOMPUTATION

**10 of 10 agreements, 0 disagreements.** The independent side
recomputes ownership, identity and chronology with POSIX shell, awk,
sort, uniq and git ONLY; the compiled verifier is invoked separately
and its verdict is compared with the independent verdict.

## WHAT Q3 DOES NOT ESTABLISH

- Q3 does **NOT** establish that PolyC owns the WP-001 boundary. The
  measurement points the other way for the two decisive branches.
- Q3 does **NOT** establish the historical terminality evidence is
  sound. `HISTORICAL_ACT_TERMINALITY_CONFIRMED` remains `UNPROVEN`.
- Q3 does **NOT** discharge the Q4 or External criteria. They are
  DEFERRED.
- Q3 does **NOT** modify any production file.
