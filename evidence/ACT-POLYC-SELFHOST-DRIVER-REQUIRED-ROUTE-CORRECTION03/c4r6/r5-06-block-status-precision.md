# ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03 -- C4 ROUND 6

## R5-06 -- THE ARGV/ENV BLOCK DIAGNOSTIC PRECISION

    FINDING_ID   R5-06
    CLASS        P2
    DISPOSITION  IMPLEMENTED. THE REASON TOKENS ARE NOW DISTINCT, AND
                 THE DIAGNOSTIC NO LONGER CLAIMS A RECOMPUTATION IT DID
                 NOT PERFORM.
    SUBJECT      the comparator's block extraction and recomputation
                 diagnostic

### THE DEFECT

The block extractor returned `NULL` for BOTH "the block is ABSENT" and
"the block is TOO LARGE", and the comparator's caller reported BOTH as
`CAPTURE_BLOCK_TOO_LARGE`. A record whose ARGV block was simply not
present was therefore reported to a reviewer as an OVERSIZED block.

Three distinct findings were collapsed into one reason token:

    an absent block            reported as CAPTURE_BLOCK_TOO_LARGE
    an empty block             reported as CAPTURE_BLOCK_TOO_LARGE
    a scalar field in place
      of a block               reported as CAPTURE_BLOCK_TOO_LARGE
    a genuinely oversized
      block                    reported as CAPTURE_BLOCK_TOO_LARGE

These four findings have FOUR DIFFERENT REMEDIES, and the token told a
reviewer the wrong one.

### THE REPAIR

#### THE STATUS IS CARRIED OUT OF THE EXTRACTOR

`CaptureBlock` in the shared contract now takes a `status` out-parameter
and reports ONE of five statuses:

    CAPTURE_BLOCK_OK          the block was found and read
    CAPTURE_BLOCK_ABSENT      the key is not present in the record
    CAPTURE_BLOCK_EMPTY       the key is present and the block is EMPTY
    CAPTURE_BLOCK_SCALAR      the key is present as a SCALAR field
    CAPTURE_BLOCK_TOO_LARGE   the block exceeds the DOCUMENTED LIMIT
    CAPTURE_BLOCK_MALFORMED   the block is present but malformed

The extractor's RETURN VALUE and its STATUS now agree, and the probe
asserts that agreement:

  * the OK and EMPTY statuses hand back an array (the EMPTY one carries
    zero entries), because there IS a well-formed block to describe;
  * the ABSENT, SCALAR and TOO_LARGE statuses hand back nothing, because
    there is no block to describe.

#### THE COMPARATOR REPORTS THE STATUS IT WAS GIVEN

The comparator maps each status to its OWN reason code, so a reviewer can
tell WHICH finding the record carries:

    CAPTURE_BLOCK_ABSENT
    CAPTURE_BLOCK_EMPTY
    CAPTURE_BLOCK_SCALAR
    CAPTURE_BLOCK_MALFORMED
    CAPTURE_BLOCK_TOO_LARGE

The mapping lives in ONE place (`CaptureBlockReasonCode`), so the shared
contract's statuses and the comparator's reason codes cannot drift apart.

#### THE ACCEPTANCE BEHAVIOUR IS NOT CHANGED

Every block failure was already a REFUSAL. Every block failure is STILL a
refusal. The change is to the REASON TOKEN only. The comparator's
acceptance decisions are byte-identical to the previous revision for
every input; only the reason reported for a refused input is now
precise.

#### THE DIAGNOSTIC DOES NOT CLAIM A RECOMPUTATION IT DID NOT PERFORM

The recomputation diagnostic ALWAYS printed a `RECOMPUTED` line, even
when the record's ARGV or ENV block was absent, empty or malformed. A
recomputation over an ABSENT block is not a recomputation at all: the
identity cannot be reconstructed, and a digest printed in its place
would be a digest of a record that was never observed.

The diagnostic now REPORTS THE BLOCK STATUS:

    RECOMPUTE   ARGV_STATUS   CAPTURE_BLOCK_ABSENT
    RECOMPUTE   ENV_STATUS    CAPTURE_BLOCK_OK
    RECOMPUTE   RECOMPUTED    NOT_COMPUTED
    RECOMPUTE   REASON        A_MANDATORY_INPUT_IS_ABSENT

and prints no `RECOMPUTED` digest when a mandatory input is missing. The
diagnostic performs NO acceptance decision in either revision; it
prints and returns.

### THE WITNESS

The R5-06 witness is a NEW MODE of the C4 ROUND 6 probe, `blockstatus`.
It drives the PRODUCTION extractor over five record shapes and requires
each to report ITS OWN status:

    PROBE_CONTROL   R5_06_BLOCK_ABSENT       OK   CAPTURE_BLOCK_ABSENT
    PROBE_CONTROL   R5_06_BLOCK_EMPTY        OK   CAPTURE_BLOCK_EMPTY
    PROBE_CONTROL   R5_06_BLOCK_SCALAR       OK   CAPTURE_BLOCK_SCALAR
    PROBE_CONTROL   R5_06_BLOCK_TOO_LARGE    OK   CAPTURE_BLOCK_TOO_LARGE
    PROBE_CONTROL   R5_06_BLOCK_OK           OK   CAPTURE_BLOCK_OK
    PROBE_CHECKS    5
    PROBE_FAILURES  0

The transcript is `green-c4r6-probe.txt` in this directory.

### THE DIAGNOSTIC'S OWN TRANSCRIPT

The diagnostic's behaviour on three record shapes is recorded in
`r5-06-diagnostic-transcript.txt`:

    === absent ===
    RECOMPUTE   ARGV_STATUS   CAPTURE_BLOCK_ABSENT
    RECOMPUTE   ENV_STATUS    CAPTURE_BLOCK_ABSENT
    RECOMPUTE   RECOMPUTED    NOT_COMPUTED
    RECOMPUTE   REASON        A_MANDATORY_INPUT_IS_ABSENT

    === empty ===
    RECOMPUTE   ARGV_STATUS   CAPTURE_BLOCK_EMPTY
    RECOMPUTE   ENV_STATUS    CAPTURE_BLOCK_ABSENT
    RECOMPUTE   RECOMPUTED    NOT_COMPUTED
    RECOMPUTE   REASON        A_MANDATORY_INPUT_IS_ABSENT

    === scalar ===
    RECOMPUTE   ARGV_STATUS   CAPTURE_BLOCK_SCALAR
    RECOMPUTE   ENV_STATUS    CAPTURE_BLOCK_ABSENT
    RECOMPUTE   RECOMPUTED    NOT_COMPUTED
    RECOMPUTE   REASON        A_MANDATORY_INPUT_IS_ABSENT

Each shape reports its OWN status, and in every case the diagnostic
declines to print a recomputed digest.

### A COMPILER OBSERVATION FOUND WHILE BUILDING THE WITNESS

The first construction of the oversized-block body encoded each entry's
index in decimal. The encoding expression

    48 + (i / div) - (i / div) * 10

produced the WRONG BYTES under the production compiler: the observed
byte sequence was `118, 39, 151, 18, 10` where a decimal digit and a
newline were intended, and a NUL byte appeared at offset 773. The
observed byte values are not the arithmetic the expression denotes, so
the expression form is not relied upon.

The witness was rewritten to use a FIXED-WIDTH entry with no digit
encoding at all. The extractor's decision depends on the entry COUNT, not
on the entry text, so the fixed-width filler witnesses the same property
without depending on the encoding.

This is recorded as an OBSERVATION about the production compiler, NOT as
a defect claim and NOT as a task: no general audit of the compiler's
arithmetic is authorised by this ACT, and the affected expression form is
NOT used anywhere in the repaired code. The pre-existing, separately
recorded residue that the production compiler's `&` operator and certain
hex-literal expression forms are not audited remains open, and is
DISPOSED as correct-by-arithmetic in `r5-07-bitwise-correction.md` where
that specific claim is concerned.

### THE REPRODUCING COMMAND

    make driver-wp001-correction03-c4r6-probe-test
