# ACT-POLYC-SELFHOST-LEXER01-CORRECTION01

**Title:** Bounded evidence correction — fail-closed stage1/2/3 operator linkage, prove I0==I1==I2==I3 identifier fixed-point, run operator production seam on stage0/1/2/3, run full corpus across 0/1/2/3, capture real call-site disassembly, re-run all RED witnesses, and CLOSE only on universal PASS

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-SELFHOST-LEXER01` CLOSE commit `3760de9` (the original ACT was closed without an authoritative contract document — see §0.1)

**Class:** GOVERNANCE / EVIDENCE-CORRECTION / FAIL-CLOSED-LINKAGE

**Production compiler semantic changes:** **FORBIDDEN** — no `src/lexer.c` semantic mutation in this correction ACT; the operator classifier's runtime behavior is already fixed and verified, only linkage topology and evidence strengthening are in scope

**IR/ABI repair authorization:** NONE

**LLVM authorization:** NONE

**Language-change authorization:** NONE

**No-Python authorization:** NONE — `POLYC_TOOLS_TRACKED_PYTHON = 12` remains the canonical pre-state; this ACT must not introduce or remove Python

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

---

# 0. Mission

The reviewer audit of the `ACT-POLYC-SELFHOST-LEXER01` closure
(commit `3760de9`) identified three P0 defects and two P1
defects in the closure evidence. The substantive
self-hosting advance (operator/punctuation recognizer
migration to PolyC, four-generation operator fixed-point,
175/175 corpus conservation) is real and correct. The
closure claims, however, were stronger than the committed
evidence in three mechanically checkable ways.

This correction ACT records, repairs, and re-classifies
all five defects in a single bounded pass. No new
lexical semantics are introduced; no new candidate slice
is migrated; no Python is touched.

## 0.1 Authoritative defect enumeration

### DEFECT-1 (P0): identifier fixed-point is only 3 generations

The ACT's C3 contract required `I0 == I1 == I2 == I3`.
The committed `evidence/ACT-POLYC-SELFHOST-LEXER01/c2/
identifier-fixed-point.txt` hashes only
`bootstrap02-ident.o`, `bootstrap03-ident.stage1.o`, and
`bootstrap04-ident.stage2.o`, and concludes
`N0==N1==N2` (note: the file even conflates the operator
and identifier `N` namespace).

The reviewer audit correctly observes that the generic
self-host driver was extended to `STAGE=3` for the
operator migration but was never exercised to produce a
`bootstrap05-ident.stage3.o`. The "all four stages"
prose is therefore unsupported by evidence.

### DEFECT-2 (P0): broad-corpus equivalence stops at stage2

`c2/corpus.tsv` has columns `s0_rc s1_rc s2_rc` and
concludes `175 BYTE_IDENTICAL + 6 BOTH_FAIL` for stages
0/1/2. The ACT's C3 contract required stage0/1/2/3 with
successful outputs byte-identical across all four and
equivalent failures. There is no stage3 column.

This matters because the central claim isn't merely
"the new component itself has a fixed point" -- it is
that **the compiler generation consuming the
stage2-produced component remains observationally
equivalent when run with the stage3-produced
component**.

### DEFECT-3 (P0): real production-seam execution is only stage1

`production-seam.tsv` begins `BUILD_LABEL=stage1` and
records 33/33 cases for stage1 only. The ACT's C3
contract required:

```text
stage0 real seam
  ==
stage1 real seam
  ==
stage2 real seam
  ==
stage3 real seam
```

Static symbol presence in `hcc-bootstrap03` and
`hcc-bootstrap04` is weaker than executing their lexer
seams.

Given the previously observed EOF-pointer incident
during C2 verification (where the wrapper's
`l->ptr = start + length` synthetic advance mis-classified
`::` in asm blocks), the reviewer correctly insists on
executing each stage's real lexer seam rather than
relying on a static-build-time proxy.

### DEFECT-4 (P1): static binding proves symbols but not call sites

`c3/static-binding.txt` records `nm`-style symbol
listings showing `_BootstrapClassifyOperator` in all
three stage binaries. That proves linkage. It does
**not** show the requested disassembly evidence that
the production lexer (`lexCore` operator cases via
`lexClassifyOperator`) actually contains a call site
to that symbol in stage1/2/3. "Linked but dead" is
not ownership.

The required correction is mechanically equivalent to:

```text
hcc-bootstrap02: lexClassifyOperator -> bl _BootstrapClassifyOperator
hcc-bootstrap03: lexClassifyOperator -> bl _BootstrapClassifyOperator
hcc-bootstrap04: lexClassifyOperator -> bl _BootstrapClassifyOperator
```

Stage0 must prove the opposite (no call site, or a
local branch to the legacy C switch).

### DEFECT-5 (P1): CMake linkage is not fail-closed

For every self-host generation, `src/CMakeLists.txt`
currently does approximately:

```cmake
if (EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT}")
    link operator component
else()
    link only B1
endif()
```

and prints `operator component not yet built; linking
only B1`. Once `HCC_USE_SELFHOST_COMPONENTS` is enabled,
the operator object is no longer optional in the
semantic model -- the source expects
`_BootstrapClassifyOperator`. The linker may ultimately
fail anyway because of the unresolved symbol, but that
is accidental fail-closed behavior. The build graph
itself should state the invariant.

The required correction is morally equivalent to:

```cmake
if (NOT EXISTS "${BOOTSTRAP06_OPERATOR_OBJECT}")
    message(FATAL_ERROR "required self-host operator component missing")
endif()
target_link_libraries(...)
```

so that `SELFHOST_COMPONENT_PRESENT` is a build
prerequisite rather than a hopeful optional attachment.

---

# 1. Authorized surface

This correction ACT authorizes ONLY the following
mutations:

1. `src/CMakeLists.txt` -- replace the three optional
   `if (EXISTS ...)` branches in `hcc-bootstrap02`,
   `hcc-bootstrap03`, `hcc-bootstrap04` with hard
   `message(FATAL_ERROR ...)` guards so that the
   operator object becomes a build prerequisite.

2. `tools/quality/bootstrap06-*-stage*.c` (or
   extensions of existing harnesses) -- add a target
   that runs the operator production seam against
   stage0/stage1/stage2/stage3 binaries.

3. `Makefile` -- add `bootstrap06-lexer-seam-stage2`
   and `bootstrap06-lexer-seam-stage3` targets
   (parity with the existing
   `bootstrap06-lexer-seam-stage1` target).

4. `evidence/ACT-POLYC-SELFHOST-LEXER01-CORRECTION01/`
   directory -- capture all evidence for this correction.

No production semantic mutation is authorized.

---

# 2. Phases

## C1 RED (RECORD)

Capture the failing evidence for the four closed
defects. The corpus already exists at stages 0/1/2;
this phase records the *missing* evidence:

- Stage3 identifier object SHA (will be computed in C2)
- Stage3 corpus column (will be computed in C2)
- Stage0/2/3 production-seam captures (will be
  computed in C2)
- Stage0/1/2/3 disassembly call-site captures (will be
  computed in C2)

## C2 IMPL (REPAIR)

Execute the missing measurements and the CMake
fail-closed conversion:

1. Apply CMake fail-closed guard to all three stages.
2. Build `bootstrap05-ident.stage3.o` via the
   stage3-capable generic self-host driver.
3. Run production seam on stage0 (real hcc-bootstrap02
   invocation), stage2 (real hcc-bootstrap03
   invocation), and stage3 (real hcc-bootstrap04
   invocation); existing stage1 capture remains.
4. Run full corpus across stages 0/1/2/3 (add s3_rc
   column).
5. Capture disassembly call sites for
   `_BootstrapClassifyOperator` in stage1/2/3 and the
   absence of the call site in stage0.
6. Re-run 47/47 direct differential, Dafny, and the
   no-Python gate to prove no regression in the
   already-closed RED witnesses.

## C3 VERIFY (CONSERVATION)

Re-prove that the previous closures still hold after
the C2 IMPL:

- Operator fixed point: N0==N1==N2==N3 (unchanged)
- Identifier fixed point: I0==I1==I2==I3 (NEW --
  previously only I0==I1==I2 was proven)
- 47/47 C-oracle PASS (unchanged)
- 47/47 C-vs-PolyC differential PASS (unchanged)
- 33/33 production seam PASS at every stage (NEW --
  was stage1 only)
- 175/175 byte-identical corpus at every stage (NEW --
  was 0/1/2 only)
- POLYC_TOOLS_TRACKED_PYTHON = 12 (unchanged)
- Formal Dafny 17/17 verified (unchanged)

## C4 CLOSE (CORRECTION VERDICT)

Commit the final correction packet. The ACT-Phase is
`CLOSE` and the ACT-Verdict is `PASS` only if:

```text
IDENTIFIER_FIXED_POINT = PASS I0==I1==I2==I3
CORPUS_EQUIVALENCE_4_STAGES = PASS (175/175 BYTE_IDENTICAL + 6/6 BOTH_FAIL)
OPERATOR_SEAM_4_STAGES = PASS (33/33 at each of stage0/1/2/3)
CALL_SITE_PRESENT = PASS (bl _BootstrapClassifyOperator at stage1/2/3)
CALL_SITE_ABSENT = PASS (no such call at stage0)
LINKAGE_FAIL_CLOSED = PASS (CMake requires operator object)
DIRECT_DIFFERENTIAL = PASS 47/47
C_ORACLE = PASS 47/47
FORMAL_DAFNY = PASS 17/17
NO_PYTHON = PASS (POLYC_TOOLS_TRACKED_PYTHON=12)
FACTORY_GATES = PASS
```

---

# 3. Halts

## HALT_RED_NOT_REPRODUCED

If any of the four closed defects cannot be
reproduced (e.g., the stage3 driver cannot be made
to build, or the stage3 corpus column cannot be
measured), this ACT halts with
`HALT_RED_NOT_REPRODUCED`.

## HALT_SCOPE_EXPANSION_REQUIRED

If closing the four defects requires semantic
changes to `src/lexer.c` or any other production
source (e.g., a real bug discovered in the
operator classifier while re-running the corpus
at stage3), this ACT halts with
`HALT_SCOPE_EXPANSION_REQUIRED` and recommends a
follow-on bounded correction.

## HALT_LINKAGE_ALREADY_FAIL_CLOSED

If on inspection the existing CMake already
provides equivalent fail-closed semantics (e.g.,
the missing object causes a hard link error
without the `if (EXISTS)` guard), this ACT may
record `LINKAGE_ALREADY_FAIL_CLOSED` and proceed
without re-introducing an explicit guard. This is
NOT a halt -- it is a documented equivalence.

---

# 4. Residue budget

This ACT's residue is bounded to:

- The four closed defects repaired.
- The `F-NO-PYTHON` campaign residue (12 grandfathered
  Python files; not in scope).
- One new evidence directory:
  `evidence/ACT-POLYC-SELFHOST-LEXER01-CORRECTION01/`.

No new candidate slices, no new COMPONENT registry
rows, no new tests outside this ACT's scope.

---

# 5. Predecessor gates

Predecessor `ACT-POLYC-SELFHOST-LEXER01` is recorded
as CLOSED at `3760de9`. Per F14, the historical CLOSE
is preserved; this correction ACT does not modify the
historical document. Instead, the corrected closure
evidence is recorded under a new
`ACT-POLYC-SELFHOST-LEXER01-CORRECTION01/` evidence
directory, and the correction ACT itself becomes the
authoritative post-correction record.

Note: there is no `docs/acts/ACT-POLYC-SELFHOST-
LEXER01.md` document in the repository; the original
ACT was closed by direct evidence + commit
trailer without an authoritative ACT contract
document. This is a governance gap that this
correction ACT does not retroactively repair; a
separate bounded correction could do so. For the
purposes of this ACT, the original commits and
their evidence are taken as the predecessor
contract.
