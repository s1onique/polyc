# ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01

**Title:** Staged correction: stage C1 (REDs + boolean contract);
defer C2 (LLVM backend change) and C3 (closure) to a
`-RESUME01` ACT after IR-BOUNDARY03 lands the upstream fix.

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** IMPLEMENTATION, but staged. Only stage C1 is authorised
in this document. Stages C2 and C3 are NOT authorised here; they
are placeholders that will be authored as a fresh
`...CORRECTION01-RESUME01` ACT (or equivalent) after the upstream
canonicalisation ACT closes GREEN.

**Predecessor:** ACT-POLYC-LLVM-SPIKE01-RESUME01 (commit `130098c`,
reviewer-verdict `HALT_LLVM_BOUNDARY_CONTRACT` — see §11 below).

**Production semantic changes:** FORBIDDEN on the native / JIT /
LSP paths (F10 conservation); authorised only on
`docs/`, `evidence/`, `scripts/quality/llvm-spike-test.sh` (test
harness only, not production lowering), and the RED-witness
language fixtures under `src/tests/llvm-spike/` that are needed
to capture REDs (no `.HC` file for REDs that are not language
fixtures).

**Authorised file scope, stage C1 (strict — F7, F15):**

```text
docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01.md   (this file)
docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01.md                 (HALT addendum, prior session)
docs/notes/llvm-ir-boolean-contract.md                      (RED-7)
src/tests/llvm-spike/red_ir_cmp_br_pipeline.HC              (RED-1A)
src/tests/llvm-spike/red_ir_cmp_br_consumer.HC              (RED-1B; only if the existing
                                                              cmp source does not already
                                                              produce a transcript adequate
                                                              to witness the consumer accept)
src/tests/llvm-spike/red_local_alloca_emitted.HC            (RED-2, language fixture)
src/tests/llvm-spike/red_pred_eq.HC                         (RED-6)
src/tests/llvm-spike/red_pred_ne.HC                         (RED-6)
src/tests/llvm-spike/red_pred_slt.HC                        (RED-6)
src/tests/llvm-spike/red_pred_sle.HC                        (RED-6)
src/tests/llvm-spike/red_pred_sgt.HC                        (RED-6)
src/tests/llvm-spike/red_pred_sge.HC                        (RED-6)
scripts/quality/llvm-spike-test.sh                          (predicate matrix expansion
                                                              in C1; predicate lowering
                                                              rules added in C2)
evidence/llvmspike01-resume01-correction01/                 (C1 RED transcripts + boolean
                                                              contract note; binary artefacts
                                                              disallowed per F11 / F13)
```

**NOT authorised in C1 (F15):**

```text
src/llvm-backend.{c,h}
src/cli.{c,h}
src/main.c
src/ir.c, src/ir-types.h
src/codegen-x86_64.c, src/codegen-aarch64.c, src/jit.c
```

The current CORRECTION01 cannot authorise the LLVM consumer fix
or the upstream IR-pipeline canonicalisation. Both are required
for a GREEN C2/C3 closure, and both are explicitly delegated
elsewhere (see §10, §11).

**Out-of-scope residue (recorded, NOT fixed here — F15):**

```text
- F64 parameters / arithmetic                       P2
- IR_LOAD_DEREF / IR_STORE_DEREF / IR_RMW_DEREF     P2
- IR_SWITCH / IR_SELECT / IR_VA_*                   P2
- IR_ASM real backend witness                       P2
- bitwise / shift / division / negation             P2
- U8 / U16 / U32 / F32                             P2
- aggregate / struct / class / pointer math        P2
- IR_CMP_BR removal from the neutral IR pipeline
  (belongs in ACT-POLYC-IR-BOUNDARY03, not here)    P2
- IR_CMP_BR removal from the LLVM consumer
  (this ACT's deferred C2)                          P2
```

---

## 0. Mission — nine review findings

The reviewer of commit `130098c` and the reviewer of the
prior-draft CORRECTION01 identified the following nine
findings. This staged correction ACT addresses only what its
file scope allows. The remaining items are delegated to
follow-on ACTs.

1. **Boundary breach (IR_CMP_BR consumer).** The LLVM consumer
   lowers `IR_CMP_BR` directly. Per `src/ir-types.h:39-41` and
   the boundary doctrine from `ACT-POLYC-IR-BOUNDARY01`,
   `IR_CMP_BR` is a **below-boundary native fusion** and must
   not reach an above-boundary consumer. — owner: deferred C2.

2. **Scope breach (alloca/load/store).** `src/llvm-backend.c`
   emits `LLVMBuildAlloca` / `LLVMBuildLoad2` /
   `LLVMBuildStore` (lines 409, 496-498, 727). The original
   spike forbade stack allocation. Memory lowering is not
   in scope. — owner: deferred C2 / future SPIKE02.

3. **Gate hygiene (`native_gate.txt` SUBJECT).** The committed
   `native_gate.txt` records `SUBJECT=b65d9ab` (the entry
   HEAD), not the implementation HEAD `130098c`. — owner:
   C1 hygiene; HALT addendum already records this.

4. **Whitespace hygiene (AC33 violation).** `git diff --check
   b65d9ab..HEAD` exits non-zero with 20 trailing-whitespace
   errors in `evidence/llvmspike01-resume01/native_gate.txt`.
   — owner: C1 hygiene.

5. **Text-evidence contract violation.** Twelve generated
   `.bc` files, `c_api_smoke`, `c_api_smoke.o` committed
   under `evidence/llvmspike01-resume01/`. — owner: C1
   hygiene.

6. **Predicate matrix reduction.** Only `sgt` exercised from
   PolyC source. The other five signed predicates
   (`eq / ne / slt / sle / sge`) exist only as switch arms
   in `llCmpKindToLLVMPred`, never reached by real source.
   — owner: C1 (RED fixtures); C2 (lowering rules).

7. **PolyC boolean vs LLVM i1 contract.** `LLVMBuildICmp`
   returns LLVM `i1` (`src/llvm-backend.c:622`). The `IR_BR`
   codepath runs the cached value through `llLowerI64Value`
   then `LLVMBuildTrunc(..., i1)` (`src/llvm-backend.c:594`).
   When `IR_ICMP` is cached and re-read by `IR_BR`, the trunc
   collapses to `i1 → i1`, which LLVM's IR verifier rejects
   (LangRef: source width must exceed destination width).
   The boundary contract between PolyC neutral IR and LLVM
   IR must be established from existing PolyC consumers
   before any `IR_ICMP + IR_BR` codepath is correct. — owner:
   C1 (boolean-contract note); C2 (implement the chosen
   mapping).

8. **`neg_asm.HC` is not a backend witness.** It fails at
   parse time, not at the LLVM backend. — owner: C1
   (reclassify honestly in the test harness; no source
   change).

9. **Unreachable GREEN under declared scope (this finding).**
   The prior-draft CORRECTION01 simultaneously required
   (a) the neutral IR pipeline to be allowed to emit
   `IR_CMP_BR`, (b) the LLVM consumer to refuse it, (c)
   all six predicate fixtures to reach LLVM successfully,
   and (d) upstream canonicalisation to be out of scope.
   That conjunction is unsatisfiable: if the pipeline emits
   `IR_CMP_BR` and the consumer refuses it, no predicate
   fixture can reach LLVM. — owner: this ACT (staged).

**Correct architectural ordering (per boundary doctrine):**

```text
LLVM-SPIKE01-RESUME01
        │
        └── HALT_LLVM_BOUNDARY_CONTRACT
                    │
                    ▼
CORRECTION01 / C1  (this ACT)
   reproduce RED-1A / RED-1B
   capture RED-2..RED-8
   establish boolean-contract note
                    │
                    ▼
      HALT_LLVM_SEES_NATIVE_FUSION   (expected, mandatory)
                    │
                    ▼
ACT-POLYC-IR-BOUNDARY03
   backend-neutral IR exposes canonical IR_ICMP + IR_BR
   native lowering may still fuse to IR_CMP_BR
   (the fusion remains valid; it just must not be visible
    above the backend-neutral boundary)
                    │
                    ▼
CORRECTION01-RESUME01  (fresh ACT, fresh entry SHA)
   C2: remove IR_CMP_BR consumer
       implement chosen boolean mapping
       expand predicate matrix lowering
   C3: closure + normalised evidence
                    │
                    ▼
   GREEN or further HALT
```

The previous-draft Path B was an attempt to keep C2 in this
ACT. It was correctly rejected because the upstream fix is
the missing half and must be authored under its own
contract, not absorbed here.

---

## 1. Entry identity

```text
branch: main
HEAD:   130098c7344c4fb430c1dec0291bbd16ce0bf3e6
        (feat(llvm-spike): bounded I64 backend with collapse-elimination)
```

---

## 2. Required RED witnesses (F3)

RED witnesses must exist BEFORE any production change is
written. C1 REDs are not all language fixtures — only the
REDs that genuinely involve source syntax produce `.HC`
files. The rest are shell / git / file witnesses captured as
transcripts under `evidence/llvmspike01-resume01-correction01/`.

### RED-1A: boundary crossing between neutral IR and codegen-prep IR

The reviewer of C1 found that the literal wording of the
predecessor's RED-1A claim ("`--dump-ir` shows `IR_CMP_BR`")
**does not reproduce** at the dump snapshot, because the dump
pipeline (`src/ir.c:3301-3315`) runs
`irBasicFunctionOptimisations`, not the `irOptPinResultReg`
fusion that creates `IR_CMP_BR`. The fusion happens later, in
`irFunctionPrepForCodeGen` (`src/ir.c:3085-3095`), which is
the codegen-prep path used by both the native backend and the
LLVM consumer, but **not** by `--dump-ir`.

The pre-closure correction therefore redefines RED-1A as the
**boundary crossing**, not the literal presence of `IR_CMP_BR`
in the dump output:

```text
RED-1A (literal claim, pre-closure):       DOES NOT REPRODUCE
    --dump-ir on the comparison fixture contains IR_CMP_BR.
    Falsified by source: --dump-ir runs
    irBasicFunctionOptimisations, not irOptPinResultReg.

RED-1A (refined claim, post-C1 evidence):  REPRODUCES
    The neutral IR snapshot (above the boundary) is canonical
    IR_ICMP + IR_BR. The codegen-prep snapshot (below the
    boundary, the path the LLVM consumer actually walks)
    contains IR_CMP_BR. The boundary crossing is therefore:
        canonical neutral IR
            |
            v  irFunctionPrepForCodeGen
              (src/ir.c:3085-3095)
            |
            v  irOptPinResultReg
              (src/ir-optimise.c:1079, 1113)
            |
            v  IR_CMP_BR (below-boundary fusion)
            |
            v  LLVM consumer silently re-translates
              (src/llvm-backend.c:610-639)

fixture:   src/tests/llvm-spike/red_ir_cmp_br_pipeline.HC
           (or existing 04_cmp_branch.HC if it suffices)
action:    run --dump-ir AND run --emit-llvm on that fixture
expected:  --dump-ir shows the canonical IR_ICMP + IR_BR pair;
           the LLVM consumer nevertheless sees the fused form
           because irFunctionPrepForCodeGen has already
           mutated the IR by the time the consumer walks it
witness:   evidence/llvmspike01-resume01-correction01/
             red-1A.dump-ir.txt       (canonical shape)
             red-1B.emit-llvm.ll      (LLVM consumer walk)
             red-1A.analysis.txt      (source-trace analysis)
```

This refined RED establishes the *upstream half* of finding
#1: the neutral-IR contract is canonical, but the codegen
prep mutates it into a below-boundary fusion before any
backend (native or LLVM) walks it. C1 captures this RED. C2
cannot land until the upstream half is resolved by
IR-BOUNDARY03 (which makes the boundary crossing legitimate
for the native backend and absent for the LLVM consumer).

### RED-1B: LLVM consumer accepts `IR_CMP_BR` (transcript witness)

```text
fixture:   same comparison source as RED-1A
action:    run --emit-llvm on that fixture
expected:  consumer rejects with LLVM_BACKEND_UNSUPPORTED_IR
           whose name includes "IR_CMP_BR"
today:     will FAIL — consumer has an `IR_CMP_BR` switch arm
           that successfully emits a `condbr` LLVM instruction
witness:   evidence/llvmspike01-resume01-correction01/
             red-1B.emit-llvm.txt
```

A standalone `.HC` fixture is created ONLY if the existing
comparison source does not already produce a transcript
adequate to demonstrate the consumer's behaviour. If the
existing source suffices, RED-1B's witness is the transcript
alone.

### RED-2: alloca / load / store emitted (language fixture)

```text
fixture:   src/tests/llvm-spike/red_local_alloca_emitted.HC
           (or any current 02_add / 03_sub_mul / 05_call source)
action:    run --emit-llvm, inspect resulting .ll
expected:  .ll contains no alloca, no store, no load on a ptr
today:     will FAIL — backend emits
              %slot = alloca i64
              store  i64 %v, ptr %slot
              %x   = load  i64, ptr %slot
           for 02_add / 03_sub_mul / 04_cmp_branch / 05_call
witness:   evidence/llvmspike01-resume01-correction01/
             red-2.emit-llvm.ll
```

If after the eventual C2 change alloca / load / store still
appears in any of 02..10, the deferred C2 will halt with
`HALT_LLVM_SPIKE_SUBSET_NOT_REACHABLE`. C1 only captures the
RED; C2 acts on it.

### RED-3: gate hygiene (shell witness)

```text
$ head -1 evidence/llvmspike01-resume01/native_gate.txt
# today: SUBJECT=b65d9ab       (entry HEAD, not implementation)
witness:   evidence/llvmspike01-resume01-correction01/
             red-3.gate-subject.txt    (captured by C1)
```

This is NOT a language fixture; it is a shell transcript.

### RED-4: whitespace hygiene (git witness)

```text
$ git diff --check b65d9ab..HEAD
# today: 20 trailing-whitespace errors
witness:   evidence/llvmspike01-resume01-correction01/
             red-4.git-diff-check.txt  (captured by C1)
```

This is NOT a language fixture; it is a `git diff --check`
transcript. The new CORRECTION01 and the boolean-contract
note are themselves required to be whitespace-clean.

### RED-5: text-evidence contract violation (file witness)

```text
$ git ls-files evidence/llvmspike01-resume01/ | grep -E '\.(bc|o)$'
$ ls evidence/llvmspike01-resume01/c_api_smoke 2>/dev/null
# today: 12 *.bc + c_api_smoke + c_api_smoke.o committed
witness:   evidence/llvmspike01-resume01-correction01/
             red-5.git-ls-files.txt    (captured by C1)
```

This is NOT a language fixture; it is a `git ls-files`
transcript. C1 does NOT delete the offending files in the
prior ACT's directory (that is a hygiene act of the closure
of the correction effort, which lives in C3 of a future
CORRECTION01-RESUME01 ACT). C1 only captures the witness.

### RED-6: signed-predicate source coverage (language fixtures)

The original reviewer's finding was a **coverage** defect,
not a product defect: only `sgt` had a real source-level
test witness. C1 reproduces that coverage defect honestly,
records whatever the existing compiler actually does for
each of the six signed predicates, and does NOT encode an
expected LLVM success/failure distribution into the witness.

```text
fixtures:  src/tests/llvm-spike/red_pred_{eq,ne,slt,sle,sgt,sge}.HC
           (each a minimal int comparison returning or branching
            on the result; shape borrowed from the existing
            cmp-branch pattern but rewritten with the named
            predicate operator)

ENTRY STATE (today):
  the LLVM backend implements all six signed-predicate
  mappings (src/llvm-backend.c:502-510, llCmpKindToLLVMPred),
  and the IR_CMP_BR switch arm (src/llvm-backend.c:610-639)
  plus the IR_ICMP switch arm (src/llvm-backend.c:741-749)
  both call that common mapper. So whichever arm the
  existing pipeline emits, the LLVM predicate encoding
  itself is already complete.
  The pre-existing coverage defect is narrower: only `sgt`
  has a real source-level witness.

C1 ACTION:
  add six source fixtures and execute all six against the
  existing compiler through both --dump-ir and --emit-llvm.

C1 DOES NOT require five predicates to fail.
  The observed --emit-llvm rc for each predicate is
  recorded as-is. Any predicate whose emitted .ll travels
  through the IR_CMP_BR path is also evidence for
  RED-1A / RED-1B, not a GREEN boundary result.

WITNESSES (one file per predicate):
  evidence/llvmspike01-resume01-correction01/
    red-6.<predicate>.dump-ir.txt
    red-6.<predicate>.emit-llvm.txt
  Each .emit-llvm.txt records:
    source operator
    neutral IR shape (the IR_CMP_BR / IR_ICMP+IR_BR mix)
    IrCmpKind / opcode observed
    --emit-llvm rc
    emitted LLVM predicate if rc == 0
```

Why this matters: if reality is that **all six** predicates
already pass --emit-llvm through the IR_CMP_BR path, the
architectural finding strengthens rather than weakens. LLVM
predicate semantics were mostly fine; the placement of
fusion was wrong. That is precisely the evidence that should
hand off to ACT-POLYC-IR-BOUNDARY03. C1 must be free to
report it without fighting an encoded expectation.

### RED-7: PolyC boolean vs LLVM i1 contract (document witness)

This RED is a documentation witness, not a fixture or test
fail.

```text
required artefact: docs/notes/llvm-ir-boolean-contract.md
                    (committed as part of C1; see §3)
content:
  - state the boundary contract for comparisons in PolyC
    neutral IR and how it maps to LLVM IR;
  - identify whether IR_ICMP is semantically boolean
    (cached as LLVM i1) and IR_BR consumes it directly,
    OR PolyC neutral IR materialises an I64 0/1 value and
    emission does explicit zext/sext at the comparison
    boundary with an i1 conversion at the branch boundary;
  - cite the source locations (line numbers in
    src/ir-types.h, src/llvm-backend.c) that motivate
    the chosen contract;
  - if the contract cannot be determined from current
    source and existing interpreter/native consumers,
    declare HALT_IR_BOOLEAN_CONTRACT_UNRESOLVED.
```

The choice between the two mappings is an implementation
conclusion, not an assumption. The note must justify it.

### RED-8: `neg_asm.HC` is not a backend witness (test-harness witness)

```text
$ scripts/quality/llvm-spike-test.sh 2>&1 | grep -A2 neg_asm
# today: assertion passes on generic "error:" — does not
#        prove IR_ASM reaches the LLVM backend
witness:   evidence/llvmspike01-resume01-correction01/
             red-8.llvm-spike-test.txt
```

C1 edits the test harness to reclassify this honestly (it
remains an x86 parse-time gate; it does not claim backend
reachability). C1 does NOT delete the fixture; it
re-labels the assertion.

---

## 3. Authorised production change — Stage C1 ONLY

**Exactly one stage is authorised in this ACT. Stages C2 and
C3 are placeholders that will be authored as a fresh
`...CORRECTION01-RESUME01` ACT after
`ACT-POLYC-IR-BOUNDARY03` closes GREEN.** F4: a HALT is a
successful execution outcome, not permission to invent an
alternate implementation strategy mid-stream. The expected
outcome of C1 is the mandatory halt
`HALT_LLVM_SEES_NATIVE_FUSION`.

### Commit topology (binding — AC-8 / AC-9)

```text
C1  docs(test): correction RED phase + boolean contract
    content:
      - docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01.md
      - docs/notes/llvm-ir-boolean-contract.md  (RED-7)
      - src/tests/llvm-spike/red_ir_cmp_br_pipeline.HC  (RED-1A)
      - src/tests/llvm-spike/red_ir_cmp_br_consumer.HC  (RED-1B;
        only if existing source is inadequate)
      - src/tests/llvm-spike/red_local_alloca_emitted.HC (RED-2)
      - src/tests/llvm-spike/red_pred_{eq,ne,slt,sle,sgt,sge}.HC (RED-6)
      - scripts/quality/llvm-spike-test.sh   (predicate matrix
        exposure; honest neg_asm reclassification)
      - evidence/llvmspike01-resume01-correction01/* (RED witnesses)
    artefact:  C1_HEAD

C2  (DEFERRED — to be authored as CORRECTION01-RESUME01 after
    IR-BOUNDARY03 closes GREEN):
    content:
      - src/llvm-backend.{c,h}
      - chosen boolean-mapping implementation
      - predicate matrix lowering rules
      - IR_CMP_BR consumer removal
    artefact:  IMPLEMENTATION_HEAD  (defined in the future ACT)

C3  (DEFERRED — same future ACT):
    content:
      - evidence/llvmspike01-resume01/* (hygiene normalisation)
      - HANDOFF.md
    artefact:  CLOSURE_HEAD        (defined in the future ACT)
```

The mechanical closure checks for the future C2/C3 ACT:

```bash
git diff --check 130098c..C1_HEAD                # C1 hygiene gate
git diff --check 130098c..IMPLEMENTATION_HEAD   # future ACT
git diff --check 130098c..CLOSURE_HEAD          # future ACT
```

`native_gate.txt` normalisation (RED-3) is NOT part of C1.
It belongs to C3 because re-running `gate-push.sh` against
`IMPLEMENTATION_HEAD` requires C2 to exist. C1 only captures
the witness.

### C1 scope (what this ACT actually does)

```text
1. Commit this CORRECTION01 ACT in its staged form.

2. Commit docs/notes/llvm-ir-boolean-contract.md, written from
   current source plus existing interpreter/native consumers
   (F3 / F2). The note explicitly states:
     - which of the two mappings it chose;
     - the line numbers in src/ir-types.h and
       src/llvm-backend.c that motivated the choice;
     - whether the choice requires any C2 production change
       beyond what the future CORRECTION01-RESUME01 already
       commits to (it should not — F7).

3. Commit the language fixtures for RED-1A, RED-1B (if needed),
   RED-2, and RED-6. Each fixture compiles today via the
   current native path; that is enough to demonstrate the RED
   reproduces. Verifier-clean .ll emission is NOT a C1
   requirement.

4. Commit the predicate-matrix extension to
   scripts/quality/llvm-spike-test.sh. The matrix must
   exercise all six signed predicates from PolyC source.
   C1 records the observed --dump-ir and --emit-llvm result
   for each predicate without assuming any particular
   success/failure distribution. Successful emission through
   IR_CMP_BR remains evidence for RED-1A / RED-1B and is not
   a GREEN boundary result.

5. Capture all RED witnesses as text under
   evidence/llvmspike01-resume01-correction01/. NO binary
   artefacts (F13).

6. Honest reclassification of neg_asm in the test harness:
   it is a parse-time gate, not a backend witness. The
   assertion text in the harness is updated to say so.

7. Mechanical hygiene gates:
     - git diff --check 130098c..C1_HEAD        exit 0
     - the new CORRECTION01 ACT itself has 0 trailing
       whitespace lines
     - the new boolean-contract note has 0 trailing
       whitespace lines
     - no .bc / .o / executable committed under
       evidence/llvmspike01-resume01-correction01/

8. Re-confirm predecessor baseline conservation (F10):
     - gate-push against C1_HEAD must reproduce the
       predecessor baseline counts exactly (native AOT,
       JIT, LSP, CORPUS). Note: C1 does NOT touch
       src/llvm-backend.c, so this is expected to hold
       trivially. The check is recorded in HANDOFF.md
       (C1 HANDOFF; see AC-12) as evidence, not as a
       PASS/FAIL gate.

9. Produce C1 HANDOFF.md following HANDOFF-TEMPLATE.md at
   evidence/llvmspike01-resume01-correction01/HANDOFF.md.
   The HANDOFF records:
     - which REDs reproduced;
     - the boolean contract conclusion;
     - the mandatory halt HALT_LLVM_SEES_NATIVE_FUSION;
     - the precise boundary state (which neutral-IR
       instruction is the blocker, with file:line);
     - the explicit non-authorisation of C2/C3 in this ACT.
```

### C1 mandatory halt

The expected outcome of C1 is:

```text
HALT_LLVM_SEES_NATIVE_FUSION
   Cause:  RED-1A (refined) reproduces — the neutral IR is
           canonical IR_ICMP + IR_BR, but the codegen-prep
           path (irFunctionPrepForCodeGen + irOptPinResultReg)
           fuses the pair into IR_CMP_BR before any backend
           walks it. The LLVM consumer therefore sees a
           below-boundary fused form, contradicting the
           boundary doctrine from ACT-POLYC-IR-BOUNDARY01.
   State:  RED-1B also reproduces — the LLVM consumer
           accepts IR_CMP_BR (silent re-translation in
           src/llvm-backend.c:610-639).
   Action: do not implement C2 here. Record the halt. Hand
           off to ACT-POLYC-IR-BOUNDARY03, which has the
           upstream fix as its mission.

   Pre-closure correction: the halt's *cause* and *state*
   are what was actually observed in C1. The literal
   predecessor wording ("RED-1A reproduces — the pipeline
   emits IR_CMP_BR") is corrected to the boundary-crossing
   observation. The halt name is unchanged because the
   architectural fact is unchanged: the LLVM consumer sees
   a native fusion it was not designed to see.
```

A successful C1 produces a halt, not a GREEN. C1 closes
with `STATUS = HALT_LLVM_SEES_NATIVE_FUSION` (mandatory) or
`STATUS = HALT_IR_BOOLEAN_CONTRACT_UNRESOLVED` (if the
boolean-contract note cannot reach a defended conclusion).

### Stages C2 and C3 (NOT authorised in this ACT)

```text
A separate ACT, ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-
RESUME01 (or equivalent under a fresh entry SHA), will author:
  - src/llvm-backend.c: REMOVE the IR_CMP_BR consumer switch
    arm; reject with LLVM_BACKEND_UNSUPPORTED_IR.
  - src/llvm-backend.c: implement the boolean mapping chosen
    in docs/notes/llvm-ir-boolean-contract.md.
  - scripts/quality/llvm-spike-test.sh: complete the
    predicate matrix lowering.
  - evidence/llvmspike01-resume01/*: normalise trailing
    whitespace; delete .bc / c_api_smoke / c_api_smoke.o;
    regenerate .ll locally and discard.
  - HANDOFF.md with PASS/FAIL counts, gate-push baseline
    re-confirmation, and the closure contract.
That ACT is authored under its own scope once
ACT-POLYC-IR-BOUNDARY03 closes GREEN.
```

---

## 4. Evidence hygiene (mandatory, C1)

```text
- Strip trailing whitespace from native_gate.txt and any
  other committed log. (C1 captures this as RED-4 witness;
  C3 in the future ACT performs the strip.)
- The new CORRECTION01 ACT must itself have 0 trailing-
  whitespace lines.
- docs/notes/llvm-ir-boolean-contract.md must itself have
  0 trailing-whitespace lines.
- git diff --check 130098c..C1_HEAD must exit 0.
- No binary artefacts committed under
  evidence/llvmspike01-resume01-correction01/.
- C1 does NOT delete the offending files in
  evidence/llvmspike01-resume01/ (those belong to C3 of
  the future ACT, which has the production change that
  makes the gate SUBJECT meaningful).
```

---

## 5. Acceptance criteria

### C1 acceptance criteria (this ACT)

| AC       | Description                                            |
|----------|--------------------------------------------------------|
| C1-AC-1  | RED-1A (refined) reproduces BEFORE C1 closes: the      |
|          | neutral-IR snapshot is canonical IR_ICMP + IR_BR; the   |
|          | codegen-prep snapshot contains IR_CMP_BR. The literal   |
|          | predecessor claim ("`--dump-ir` shows IR_CMP_BR") was   |
|          | investigated and falsified by source-trace; the refined |
|          | claim is recorded in §2 and the pre-closure correction  |
|          | block in §3.                                            |
| C1-AC-2  | RED-1B reproduces BEFORE C1 closes.                    |
| C1-AC-3  | RED-2 reproduces BEFORE C1 closes.                     |
| C1-AC-4  | RED-3, RED-4, RED-5, RED-8 captured as text witnesses  |
|          | under evidence/llvmspike01-resume01-correction01/.     |
| C1-AC-5  | RED-6: six signed-predicate source fixtures committed   |
|          | and exercised through both --dump-ir and --emit-llvm.  |
|          | For each predicate, C1 records:                        |
|          |   source operator                                       |
|          |   neutral IR shape                                      |
|          |   IrCmpKind / opcode observed                           |
|          |   --emit-llvm rc                                        |
|          |   emitted LLVM predicate if rc == 0                     |
|          | No particular LLVM success/failure distribution is     |
|          | assumed. Any predicate whose .ll travels through       |
|          | IR_CMP_BR remains evidence for RED-1A / RED-1B,        |
|          | not a GREEN boundary result.                           |
| C1-AC-6  | docs/notes/llvm-ir-boolean-contract.md exists; it      |
|          | states which of the two mappings it chose and cites    |
|          | source locations. If it cannot reach a defended        |
|          | conclusion, RED-7 closes as                              |
|          | `HALT_IR_BOOLEAN_CONTRACT_UNRESOLVED`.                  |
| C1-AC-7  | scripts/quality/llvm-spike-test.sh reclassifies        |
|          | neg_asm honestly (parse-time gate, not backend         |
|          | witness).                                              |
| C1-AC-8  | git diff --check 130098c..C1_HEAD exits 0.             |
| C1-AC-9  | The new CORRECTION01 ACT and the boolean-contract note |
|          | have 0 trailing-whitespace lines.                      |
| C1-AC-10 | No .bc / .o / executable committed under               |
|          | evidence/llvmspike01-resume01-correction01/.           |
| C1-AC-11 | gate-push against C1_HEAD reproduces the predecessor   |
|          | baseline counts exactly (F10; expected to hold        |
|          | trivially because C1 does not touch production code). |
| C1-AC-12 | C1 HANDOFF.md exists at                                 |
|          | evidence/llvmspike01-resume01-correction01/HANDOFF.md, |
|          | following HANDOFF-TEMPLATE.md; records REDs, halt,    |
|          | boundary state, and explicit non-authorisation of      |
|          | C2/C3.                                                 |
| C1-AC-13 | This ACT closes with `STATUS = HALT_LLVM_SEES_NATIVE_  |
|          | FUSION` (mandatory) or `STATUS = HALT_IR_BOOLEAN_     |
|          | CONTRACT_UNRESOLVED` (if RED-7 cannot close).         |

### C2 / C3 acceptance criteria (deferred, NOT authorised here)

These are recorded here only so the future ACT author has a
checklist. They are not ACs of this CORRECTION01.

```text
C2-AC-1  src/llvm-backend.c contains no reference to IR_CMP_BR.
C2-AC-2  IR_BR + cached IR_ICMP result produces verifier-clean
         .ll according to the boolean mapping chosen in
         docs/notes/llvm-ir-boolean-contract.md.
C2-AC-3  All six predicate fixtures (RED-6) produce verifier-
         clean .ll.
C2-AC-4  src/llvm-backend.c emits no alloca / load / store for
         the 02..10 fixtures' neutral shape.
C3-AC-1  native_gate.txt SUBJECT = IMPLEMENTATION_HEAD = C2 SHA.
C3-AC-2  git diff --check 130098c..IMPLEMENTATION_HEAD exits 0.
C3-AC-3  git diff --check 130098c..CLOSURE_HEAD exits 0.
C3-AC-4  No .bc / .o / executable committed under
         evidence/llvmspike01-resume01/.
C3-AC-5  HANDOFF.md at evidence/llvmspike01-resume01-correction01-
         resume01/ follows HANDOFF-TEMPLATE.md.
```

---

## 6. HALT clauses

```text
HALT_LLVM_SEES_NATIVE_FUSION  (C1 expected outcome)
   RED-1A reproduces AND RED-1B reproduces AND the upstream
   IR pipeline still emits IR_CMP_BR for comparison sources.
   This is the mandatory C1 halt.

HALT_IR_BOOLEAN_CONTRACT_UNRESOLVED  (C1 contingency)
   docs/notes/llvm-ir-boolean-contract.md cannot reach a
   defended choice between the cached-i1 contract and the
   explicit-zext contract from current source plus the
   existing interpreter/native consumers.

HALT_LLVM_SPIKE_SUBSET_NOT_REACHABLE  (future C2 contingency)
   The SSA-only neutral seam cannot represent the predicate
   fixtures without IR_VAL_LOCAL outside the return-collapse
   slot. A successor ACT (likely ACT-POLYC-LLVM-MEMORY01 or
   SPIKE02) authorises memory lowering on documented need.

HALT_PREDECESSOR_GATE_RED  (binding, all stages)
   gate-push against any stage HEAD fails for any reason
   unrelated to the --emit-llvm path. Conservation is
   non-negotiable (F10).

HALT_SCOPE_EXPANSION_REQUIRED  (binding, all stages)
   Any of the documented P2 residue items must be fixed to
   close the current stage. Per F15 the stage closes with
   residue, not with silent enlargement.
```

---

## 7. Out of scope (explicit, F7 / F15)

The earlier reviewer recommended proceeding to F64 / pointers
/ GEP / load-deref. **This ACT does NOT authorise any of
that.** SPIKE02, memory lowering, type widening, and pointer
math are separate future ACTs. The previously-draft Path B is
**removed** — there is no in-ACT fallback, by design.

Stages C2 and C3 of the original correction are also removed
from this ACT. They will be authored as a fresh ACT under a
new entry SHA, gated on `ACT-POLYC-IR-BOUNDARY03` closing
GREEN.

---

## 8. Residue inherited from RESUME01 (NOT fixed here)

```text
- dead_exit block emission when collapse folds fully       P2
- IR_ASM real backend witness (no source-level path today) P2
- IR_CMP_BR co-existence in the IR pipeline (upstream
  removal belongs in ACT-POLYC-IR-BOUNDARY03, not here)    P2
- The cmp-branch neutral-IR shape itself (this ACT keeps
  IR_ICMP + IR_BR but does not decide whether IR_CMP_BR
  should be deleted from the canonical neutral set)       P2
- C2 / C3 of the original correction (deferred to a
  separately-authored CORRECTION01-RESUME01 ACT)          P2
```

---

## 9. Conservation guarantee (F10)

```text
- C1 does not touch src/llvm-backend.{c,h}, src/cli.{c,h},
  src/main.c, or any production lowering path.
- --emit-llvm mode-exclusion (src/cli.{c,h}, src/main.c) is
  preserved unchanged.
- Native AOT (--compile), JIT (-jit), LSP, and -run paths
  must remain bit-for-bit identical to predecessor b65d9ab.
- gate-push at C1_HEAD must reproduce the exact predecessor
  baseline counts (C1-AC-11). C1 does not authorise any
  production lowering change, so this is expected to hold
  trivially; the gate is recorded as evidence.
```

---

## 10. Next ACT (recommendation, not authorised)

```text
ACT-POLYC-IR-BOUNDARY03
   - opened immediately upon C1 closure;
   - mission: backend-neutral IR consumers see canonical
     IR_ICMP + IR_BR; the native lowering path may still
     fuse to IR_CMP_BR (the fusion remains valid; it just
     must not be visible above the backend-neutral
     boundary);
   - scope: src/ir.c, src/ir-types.h, and the canonical-
     emission rules for comparison sources.

ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01
   - opened only after ACT-POLYC-IR-BOUNDARY03 closes GREEN;
   - scope: src/llvm-backend.{c,h} (C2 above) + closure
     (C3 above) + HANDOFF.

ACT-POLYC-LLVM-MEMORY01  (or SPIKE02 if folded)
   - opened only if C2 halts with
     HALT_LLVM_SPIKE_SUBSET_NOT_REACHABLE;
   - scope: IR_LOAD_DEREF / IR_STORE_DEREF / GEP for
     pointer-typed locals, IF AND ONLY IF the halt
     evidence identifies the exact neutral-IR instruction
     that required lowering;
   - never assumes prior halts; it is the consequence, not
     a parallel stream.
```

None of these ACTs is authorised by this document.

---

## 11. Predecessor rejection record

The reviewer of commit `130098c` issued `REJECT PASS` with the
following binding defects (independent grounds for closure
downgrade):

```text
P0  LLVM consumer accepts IR_CMP_BR  (boundary breach)        Finding 1
P0  alloca/load/store emitted         (scope breach)          Finding 2
P0  native_gate.txt SUBJECT=entry     (gate hygiene)          Finding 3
P0  git diff --check entry..HEAD fails (AC33)                 Finding 4
P1  only sgt predicate exercised                             Finding 6
P1  IR_ICMP+IR_BR path untested                              Finding 7
P1  12 .bc + c_api_smoke + .o committed                      Finding 5
P1  neg_asm.HC not a backend witness                         Finding 8
```

The reviewer-supplied verdict stands:

```text
LLVM-SPIKE01-RESUME01
    TOOLCHAIN      PASS
    BASIC LLVM     PASS
    ARCH BOUNDARY  RED
    ACT HYGIENE    RED

VERDICT = HALT_LLVM_BOUNDARY_CONTRACT
```

The reviewer of the prior-draft CORRECTION01 identified the
following additional binding defect:

```text
P0  Unreachable GREEN under declared scope                   Finding 9
    RED-1A says neutral pipeline emits IR_CMP_BR
    +
    LLVM consumer must reject IR_CMP_BR
    +
    upstream canonicalisation explicitly out of scope
    +
    AC-6 / AC-7 nevertheless require canonical comparisons
    to reach LLVM successfully
```

That defect is the reason for the staged correction.

```text
CORRECTIVE_RESPONSE
    VERDICT = ACCEPTED

CORRECTION01 CONTRACT REWRITE
    PREVIOUS EIGHT FINDINGS   = RESOLVED

NEW FINDING (this draft)
    P0 = UNREACHABLE_GREEN_CONTRACT
    RESOLVED BY = staged topology (C1 only here; C2/C3
                  deferred; upstream fix owned by
                  ACT-POLYC-IR-BOUNDARY03)

ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01
    STAGE         = C1 ONLY
    STATUS        = HALT_LLVM_SEES_NATIVE_FUSION
                    (mandatory C1 halt, captured in
                     evidence/llvmspike01-resume01-correction01/HANDOFF.md)
    EXPECTED CLOSE = HALT_LLVM_SEES_NATIVE_FUSION  (achieved)

CORRECTION01 (live progress at this draft)
    staged architecture       PASS
    scope/HALT discipline     PASS
    C1/C2/C3 separation       PASS
    witness-type cleanup      PASS
    RED-6 wording             PASS  (coverage RED, not product RED;
                                      matrix-shaped recording)
    §3 item 4 stale wording   FIXED (reviewer correction, this session)
    C1 execution              COMPLETE (12/0 harness, REDs captured)
    C1 halt                   HALT_LLVM_SEES_NATIVE_FUSION
    RED-1A contract           REFACTORED (literal claim falsified;
                                      refined boundary-crossing
                                      claim replaces it; halt
                                      preserved)
    boolean-contract note     CORRECTED (trunc-UB claim removed;
                                      Boolean vs Truthiness invariant
                                      question installed as input to
                                      ACT-POLYC-IR-BOUNDARY03)
    dump-ir transcript
      hygiene                 NORMALISED (raw bytes SHA256-pinned
                                      outside Git; normalised
                                      representation committed
                                      so `git diff --check` passes)
    C1 commit                 CREATED (C1_HEAD = real SHA)
    gate-push                 RUN against C1_HEAD
    C1 halt                   HALT_LLVM_SEES_NATIVE_FUSION

PRODUCTION_AUTHORIZATION
    C1 RED/DOC PHASE = YES (this ACT) — EXECUTED, closed as halt
    C2 LLVM IMPL     = NO  (deferred to CORRECTION01-RESUME01)
    C3 CLOSURE       = NO  (deferred to CORRECTION01-RESUME01)
```

---

## 12. Identity at close

Filled in at C1 close. See `git log -1` and
`HANDOFF.md §11` and `§14` for the SHA recorded against
this ACT. The C1 commit contains exactly the authorised
scope (no production code) and produces a real `C1_HEAD`
SHA that `git diff --check 130098c..C1_HEAD` passes.

The full closure record (gates, residue, next ACT) lives
at `evidence/llvmspike01-resume01-correction01/HANDOFF.md`,
which is updated to reflect the pre-closure corrections
(RED-1A contract refactor, boolean-contract trunc-UB
correction, dump-ir transcript hygiene normalisation,
real C1 commit + gate-push, and the CLOSURE01 docs-only
correction).

```text
branch:               main
entry HEAD:           130098c7344c4fb430c1dec0291bbd16ce0bf3e6
C1_HEAD:              fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
C1 working tree:      clean
C1 halt:              HALT_LLVM_SEES_NATIVE_FUSION  (mandatory, achieved)
C1 gate-push:         VERDICT=PASS against fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
                      (build/install/aot/jit/lsp/diff-check all PASS;
                      log: evidence/llvmspike01-resume01-correction01/
                      gate-push-fedfcbc.log)
C1 closure commit:    ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-CLOSURE01
                      (docs + evidence only; no production code)
C1 next-act pointer:  ACT-POLYC-IR-BOUNDARY03
```
