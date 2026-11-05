# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 -- C4 ROUND 6

## R5-08 -- THE RED-TRANSCRIPT ACCOUNTING (FORWARD-ONLY CORRECTION)

    FINDING_ID   R5-08
    CLASS        P2
    DISPOSITION  THE PRIOR ACCOUNTING WAS WRONG. THE CORRECT FIGURES ARE
                 RECORDED BELOW AND IN `r5-08-accounting.tsv`.
    SUBJECT      the C4 ROUND 5 RED transcript accounting

### THE TRANSCRIPT UNDER AUDIT

    evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/
        c4r5/red-c4r5-probe.txt

### THE PRIOR CLAIM

The prior accounting described the C4 ROUND 5 RED transcript as

    34 OK + 16 FAIL

### THE CORRECT FIGURES

Three DIFFERENT quantities were being conflated into one. They are
distinct, and each has its own derivation:

  1. PHYSICAL ROWS -- the number of `PROBE_CONTROL` lines in the
     transcript.

         40

  2. OUTPUT ROWS -- the number of rows whose verdict is `OK`, and the
     number whose verdict is `FAIL`.

         24 OK + 16 FAIL = 40 physical rows

     The two verdicts partition the physical rows exactly: no row has a
     third verdict, and no row is counted twice.

  3. ASSERTED CHECKS -- the sum of the eight `PROBE_CHECKS` rows, which
     is the number of controls the probe ASSERTED.

         13 + 2 + 7 + 6 + 2 + 1 + 6 + 1 = 38

  4. UNIQUE CONTROL NAMES -- the number of DISTINCT control names.

         37

### WHY THE PHYSICAL ROW COUNT EXCEEDS THE UNIQUE NAME COUNT

Forty rows carry thirty-seven distinct names. Three names appear on TWO
rows each:

    R4_01_CAPTURE_BLOCK_128   2 rows
    R4_01_CAPTURE_BLOCK_65    2 rows
    R4_03_OUTPUT_PREEXISTS    2 rows

    37 unique names + 3 repeats = 40 physical rows

The repeats are not double-counting. `R4_01_CAPTURE_BLOCK_65` and
`R4_01_CAPTURE_BLOCK_128` are exercised in TWO DIFFERENT CONTEXTS (the
capture-block boundary and the ledger/identity context), and
`R4_03_OUTPUT_PREEXISTS` is exercised in TWO DIFFERENT CONTEXTS. The
probe asserts the SAME PROPERTY under two different names' worth of
setup, so the assertion is made twice.

### WHY THE ASSERTED-CHECK COUNT IS 38 AND NOT 40

The probe's `PROBE_CHECKS` counter and the number of `PROBE_CONTROL`
rows are counted at DIFFERENT POINTS in the probe's execution, so they
do not have to agree, and here they do not:

    asserted checks   38
    physical rows     40

The difference of two is accounted for by the two probe modes whose
counters are emitted separately from the rows that precede them. This is
recorded as an OBSERVATION about the probe's accounting shape, not as a
defect: the probe is a witness, and its counters are reported verbatim.

### WHY "34 OK + 16 FAIL" IS WRONG

`34 + 16 = 50`, which is TEN MORE than the 40 physical rows in the
transcript. The prior figure is arithmetically incompatible with the
transcript it describes. The correct split is `24 + 16 = 40`.

### THE FORWARD-ONLY RULE

This file and `r5-08-accounting.tsv` are NEW artefacts under `c4r6/`.
They do NOT edit the C4 ROUND 5 interim status, which continues to
record what it said at the time. Per the repository's F14 rule, a
historical document is historical evidence.

### THE REPRODUCING COMMANDS

    F=evidence/ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03/c4r5/red-c4r5-probe.txt

    grep -c PROBE_CONTROL  $F    # physical rows
    grep -c ^PROBE_CONTROL $F    # output rows
    grep -c $'\tOK\t'       $F    # ok rows
    grep -c $'\tFAIL\t'     $F    # fail rows
    grep ^PROBE_CONTROL $F | cut -f2 | sort -u | wc -l   # unique names
    grep '^PROBE_CHECKS' $F | cut -f2 | paste -sd+ - | bc  # asserted checks

Observed:

    40
    40
    24
    16
    37
    38
