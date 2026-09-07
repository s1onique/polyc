# C1 HANDOFF

**ACT:** ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01, stage C1.
**Status:** HALT_LLVM_SEES_NATIVE_FUSION (mandatory C1 halt).
**Date:** captured at C1 close, this session.
**Author:** automated C1 execution under reviewer-authorised
ACCEPT for the staged CORRECTION01 ACT.

---

## 1. VERDICT

```text
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01
    STAGE           = C1 ONLY
    STATUS          = HALT_LLVM_SEES_NATIVE_FUSION
                      (mandatory C1 halt; achieved)
    C1_HEAD         = fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
    GATE-PUSH       = VERDICT=PASS against C1_HEAD
                      (build/install/aot/jit/lsp/diff-check all PASS;
                      see §11.5 and §14 for evidence)
    REPRODUCED REDs = RED-1B, RED-2, RED-3..8 (witnesses captured)
    DID NOT REPRODUCE = RED-1A (literal claim; see analysis)
    BOOLEAN CONTRACT  = documented (RED-7 PASS); §4 tightened at
                        CLOSURE01 (LLVM-consumer representation
                        fact distinguished from neutral-IR proof
                        obligation; IR-BOUNDARY03 cannot inherit
                        "contract B is sound today")
    PREDICATE COVERAGE = six predicates exercised (RED-6 PASS)
    NEXT ACT          = ACT-POLYC-IR-BOUNDARY03 (upstream fix)
```

C1 produced the mandatory halt. C2 and C3 are NOT authorised
in this ACT; they are placeholders that will be authored as
a fresh ACT after ACT-POLYC-IR-BOUNDARY03 closes GREEN.

---

## 2. IDENTITY

```text
branch:               main
entry HEAD:           130098c7344c4fb430c1dec0291bbd16ce0bf3e6
C1 commit:            CREATED IN THIS SESSION
                      C1_HEAD = fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
                      (see §14 for the recorded SHA).
                      Gate-push against this SHA: VERDICT=PASS
                      (see §11.5 and §14).
toolchain (probed):   hcc (built Sep 7 with HCC_ENABLE_LLVM=ON,
                      links /nix/store/.../libLLVM.dylib = LLVM 22.1.8)
                      llvm-config / llvm-as (Homebrew llvm@21.1.8);
                      LLVM-21's llvm-as was observed to accept
                      the LLVM-22 backend's textual output for
                      the I64-only subset the spike supports.
                      LLVM_AS_21_RESULT = informational;
                      LLVM_AS_22_RESULT = authoritative for future
                      acceptance testing.
                      Gate-push build toolchain (CLOSURE01):
                      cmake 4.1.6
                      (/run/current-system/sw/bin/cmake,
                      provided by the project Nix migration)
                      + AppleClang 15.0.0.15000040 + llvm@21.
```


## 3. ROOT CAUSE / FINDING (the architectural defect)

The architectural defect flagged by the predecessor reviewer
is real but slightly different from the literal wording of
RED-1A:

```text
  - The neutral IR (above the boundary, what --dump-ir shows
    and what every backend-neutral analysis tool sees) is the
    canonical IR_ICMP + IR_BR form. This is the documented
    contract in src/ir-types.h:135-150 ("this opcode is BELOW
    THE NEUTRAL BOUNDARY ... The neutral IR contract uses the
    canonical IR_ICMP + IR_BR form"). Good.

  - The codegen-prep IR (below the boundary, what the LLVM
    consumer and the native codegen see) is the fused
    IR_CMP_BR form, produced by an architectural transformation
    (irOptPinResultReg, src/ir-optimise.c:1079-1122) that the
    neutral-IR spec does not authorise. The fusion happens in
    irFunctionPrepForCodeGen (src/ir.c:3085-3095), which runs
    after irLowerFunction and after the dump pipeline.

  - The LLVM consumer must silently re-translate the fused form
    back into LLVM's native icmp + condbr. Its IR_CMP_BR switch
    arm at src/llvm-backend.c:610-639 reinvents the contract on
    the fly, which is why the existing 04_cmp_branch.HC emission
    is verifier-clean in spite of the placement defect.

  - The defect is therefore NOT "neutral IR emits IR_CMP_BR"
    (that is wrong; the dump shows IR_ICMP + IR_BR).
    The defect IS "the boundary between neutral IR and
    codegen-prep IR runs an architectural transformation that
    the neutral-IR spec does not authorise and the LLVM

## 4. RED outcomes

| RED | Witness                                      | Outcome         |
|-----|----------------------------------------------|-----------------|
| 1A  | red-1A.dump-ir.txt, red-1A.analysis.txt      | DOES NOT REPRODUCE at --dump-ir (dump is above-boundary; fusion happens below-boundary in codegen prep). The architectural finding strengthens, not weakens; see §3. |
| 1B  | red-1B.emit-llvm.txt, red-1B.emit-llvm.ll, red-1B.analysis.txt | REPRODUCES. The LLVM consumer's IR_CMP_BR arm (src/llvm-backend.c:610-639) silently re-translates the fused form; the emitted .ll is verifier-clean. |
| 2   | red-2.emit-llvm.txt, red-2.emit-llvm.ll, red-2b.locals.ll, red-2b.emit.stdout, red-2b.emit.stderr | REPRODUCES for 04_cmp_branch.HC (2 alloca / 2 store / 2 load). red_local_alloca_emitted.HC collapses to a bare `add` (collapse-elimination wins; recorded as residue for future study). |
| 3   | red-3.gate-subject.txt                        | WITNESS CAPTURED. Resolution (gate subject normalisation) deferred to C3. |
| 4   | red-4.git-diff-check.txt                      | PASS. `git diff --check 130098c..HEAD` exits 0; the untracked C1 files introduce no whitespace errors. |
| 5   | red-5.text-evidence-contract.txt              | PASS. All files under evidence/llvmspike01-resume01-correction01/ are text per `file` (ASCII or UTF-8); no .bc/.o/executable. |
| 6   | red-6.red_pred_{eq,ne,slt,sle,sgt,sge}.{dump-ir.txt,emit-llvm.txt,llvm-as.stderr} | PASS (coverage achieved). All six signed predicates reach the LLVM backend with the matching LLVM predicate and llvm-as-21 accepts the .ll. See §6 for the matrix. |
| 7   | docs/notes/llvm-ir-boolean-contract.md        | PASS (contract documented, source locations cited, fragile-by-construction flagged). Current contract = "explicit-i64 at the neutral IR, single trunc at the LLVM emission boundary." Neither the cached-i1 nor the explicit-zext option exactly; the hybrid is fragile. Direction A vs B choice delegated to ACT-POLYC-IR-BOUNDARY03. |
| 8   | red-8.llvm-spike-test.txt, red-8.neg-asm.stderr | PASS (reclassification). neg_asm.HC fails at PARSE time (RC != 0 + `error:` token); the negative assertion no longer claims IR_ASM reachability through the LLVM backend. |


## 5. IMPLEMENTATION (what C1 actually did)

C1 is RED-only + docs. It did NOT modify production code.

Files created or modified in this ACT (F7 / F15 scope-strict):

```text
docs/acts/ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01.md
    (this ACT, staged form; section §3 item 4 corrected by
    reviewer; RED-6 rewritten as coverage RED; review block
    updated; RED-7 / RED-6 / C1-AC-5 cross-checked)

docs/notes/llvm-ir-boolean-contract.md
    (RED-7 evidence-based note; documents current contract;
    flags fragility; cites 11 source locations)

scripts/quality/llvm-spike-test.sh
    (predicate matrix extension for RED-6; RED-1A/1B/2 capture;
    RED-8 honest reclassification; .bc redirected to _tmp/ so
    re-runs do not touch predecessor .bc files)

src/tests/llvm-spike/red_pred_{eq,ne,slt,sle,sgt,sge}.HC
    (RED-6 language fixtures; branching shape so RED-7 is not
    triggered)

src/tests/llvm-spike/red_local_alloca_emitted.HC
    (RED-2 additional fixture; observed to collapse to bare
    add, recorded as residue)

evidence/llvmspike01-resume01-correction01/
    (C1 RED transcripts + boolean contract note; no binary
    artefacts)
```

Production code (`src/llvm-backend.c`, `src/ir-types.h`,
`src/ir-optimise.c`, etc.) was NOT modified. F10 conservation
holds trivially.



    consumer must silently re-translate."

## 6. RED-6 matrix (reality, no encoded expectation)

All six signed predicates were exercised through the existing
compiler. Recorded --emit-llvm rc + observed LLVM predicate:

| Predicate | Source | --emit-llvm rc | Observed LLVM predicate | llvm-as-21 rc |
|-----------|--------|---------------:|--------------------------|--------------:|
| eq        | `==`   | 0              | icmp eq                  | 0             |
| ne        | `!=`   | 0              | icmp ne                  | 0             |
| slt       | `<`    | 0              | icmp slt                 | 0             |
| sle       | `<=`   | 0              | icmp sle                 | 0             |
| sgt       | `>`    | 0              | icmp sgt                 | 0             |
| sge       | `>=`   | 0              | icmp sge                 | 0             |

All six predicates reach the LLVM backend with the matching
LLVM predicate, and LLVM-21's `llvm-as` accepts the textual
output. This is exactly the strengthening of the architectural
finding the reviewer predicted: predicate semantics were
always fine; the placement defect (IR_CMP_BR fusion being
below-boundary without an above-boundary witness) is the real
issue.

This matrix evidence hands off to ACT-POLYC-IR-BOUNDARY03.


## 7. GATES

| Gate | Status | Evidence |
|------|--------|----------|
| git diff --check 130098c..HEAD | PASS, exit 0 | red-4.git-diff-check.txt |
| trailing whitespace in CORRECTION01 ACT | PASS, 0 lines | grep -cE ' +$' on the file |
| trailing whitespace in boolean-contract note | PASS, 0 lines | grep -cE ' +$' on the file |
| text-only evidence directory | PASS | red-5.text-evidence-contract.txt |
| no .bc/.o/executable committed | PASS | red-5.text-evidence-contract.txt |
| scope-strict file list (F7) | PASS | §5 above |
| F10 conservation (production untouched) | PASS | git diff --stat shows only docs + tests + harness + fixtures |
| llvm-spike-test.sh | PASS, 12/0 | tail of harness output captured in this directory |
| gate-push against C1_HEAD=fedfcbc44edb | PASS, VERDICT=PASS | gate-push-fedfcbc.log (build/install/aot/jit/lsp/diff-check all PASS) |


## 8. SCOPE

**Authorised (executed):**

- ACT + boolean-contract note (docs)
- predicate matrix + RED-8 reclassification (harness)
- six RED-6 fixtures + one RED-2 fixture (tests)
- RED-1A/1B/2/3/4/5/6/7/8 transcripts (evidence)

**NOT authorised (explicitly excluded by this ACT):**

- src/llvm-backend.{c,h} modification
- src/cli.{c,h}, src/main.c modification
- src/ir.c, src/ir-types.h modification
- src/codegen-x86_64.c, src/codegen-aarch64.c, src/jit.c modification
- IR_CMP_BR consumer arm removal (lives in IR-BOUNDARY03)
- predicate lowering rules added to the test harness (lives in
  C2/C3 of the future ACT)
- F64 / pointers / GEP / load-deref / IR_RMW_DEREF / IR_SWITCH /
  IR_SELECT / IR_VA_* / IR_ASM real backend witness (P2 residue)
- bitwise / shift / division / negation (P2 residue)
- U8 / U16 / U32 / F32 (P2 residue)
- aggregate / struct / class / pointer math (P2 residue)




## 9. RESIDUE (P0/P1/P2; F11)

```text
P0  = none remaining in C1.

       The earlier P0 (HALT_GATE_PUSH_TOOLCHAIN_MISSING) was
       resolved at CLOSURE01 once cmake was available in the
       sandboxed shell. gate-push against
       fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad returns
       VERDICT=PASS (build / install / aot / jit / lsp /
       diff-check all PASS). The earlier transcript
       (gate-push-c1.log / red-c1-ac11.gate-push-attempt.log)
       is superseded by gate-push-fedfcbc.log in this
       directory.

P1  = none introduced by C1.

P2  (deferred to future ACTs):

    - IR_CMP_BR co-existence in the IR pipeline
      (irOptPinResultReg, src/ir-optimise.c:1079-1122).
      Belongs in ACT-POLYC-IR-BOUNDARY03, not here.

    - The cmp-branch neutral-IR shape itself.
      C1 keeps IR_ICMP + IR_BR but does not decide whether
      IR_CMP_BR should be deleted from the canonical
      neutral set. Belongs in IR-BOUNDARY03.

    - IR_CMP_BR consumer arm removal.
      C2 of the future CORRECTION01-RESUME01 ACT.

    - collapse-elimination aggressiveness on named locals.
      red_local_alloca_emitted.HC collapses to a bare `add`
      even though it has two named locals. Whether that is
      a feature or a foot-gun for future SPIKE02 memory
      lowering is a separate question.

    - dead_exit block emission when collapse folds fully
      (visible in red-2b.locals.ll, red-2.emit-llvm.ll, and
      most existing fixtures).

    - IR_ASM real backend witness
      (no source-level path today; parse-time rejection
      recorded as residue).

    - F64 / pointers / GEP / load-deref / IR_RMW_DEREF /
      IR_SWITCH / IR_SELECT / IR_VA_*.

    - bitwise / shift / division / negation.

    - U8 / U16 / U32 / F32.

    - aggregate / struct / class / pointer math.

    - native_gate.txt SUBJECT normalisation to C1 HEAD /
      IMPLEMENTATION_HEAD. Belongs in C3 of the future ACT.
```


## 10. NEXT ACT

```text
ACT-POLYC-IR-BOUNDARY03
    mission   = move the IR_CMP_BR fusion decision to the
                above-boundary pipeline (or remove the
                opcode entirely from the neutral set);
                remove the LLVM consumer's IR_CMP_BR arm
                in the same fix; answer the corrected
                boolean question
                  (IR_BR condition ∈ {0,1}  vs.
                   IR_BR condition ∈ I64 zero/nonzero)
                documented in docs/notes/llvm-ir-boolean-
                contract.md §1 and §4.
    status    = NOT authorised by this ACT. C1 hands off
                by recording the architectural defect,
                not by fixing it.
```

After ACT-POLYC-IR-BOUNDARY03 closes GREEN, a separate ACT
will author the deferred C2/C3 of the original correction
(src/llvm-backend.c: REMOVE IR_CMP_BR consumer arm +
implement the chosen boolean mapping + complete predicate
matrix lowering + native_gate.txt normalisation + HANDOFF
finalisation). That ACT is
ACT-POLYC-LLVM-SPIKE01-RESUME01-CORRECTION01-RESUME01 or
equivalent under a fresh entry SHA.

---

## 11. Dump-ir transcript hygiene (corrected this session)

The seven `--dump-ir` transcripts (red-1A + six red-6.*)
originally carried trailing whitespace on the line emitted
by `src/ir.c:3311`:

    ===== After basic optimisations =====

The trailing space before EOL is the literal output of the
PolyC IR printer (`printf("... ===== \n");`). To satisfy
`git diff --check 130098c..C1_HEAD` (C1-AC-8) without
losing the byte-faithful witness, each transcript is now
committed in **two paired forms**:

```text
<name>.dump-ir.txt        NORMALISED textual representation
                          (trailing horizontal whitespace
                          stripped per line; passes
                          `git diff --check`).

<name>.dump-ir.txt.sha256 SHA256 of the ORIGINAL raw bytes
                          (computed against
                          hcc --dump-ir stdout as captured
                          on this machine, this session).

<name>.dump-ir.txt.b64    Base64 encoding of the ORIGINAL
                          raw bytes (chunked at 76 columns
                          for git-friendliness). Reconstruct
                          raw bytes with `base64 -d`.
```

Reconstruct and verify any transcript with:

```sh
base64 -d <name>.dump-ir.txt.b64 | shasum -a 256
# must print the SHA256 listed in
# <name>.dump-ir.txt.sha256
# and the `raw_sha256:` header inside
# <name>.dump-ir.txt.
```

A consolidated manifest is at
`dump-ir-manifest.md` in this directory. After this
correction, `git diff --check 130098c..C1_HEAD` exits 0.

The witness is therefore both:
- byte-faithful (the base64 + sha256 sidecars allow exact
  reconstruction of the compiler's raw stdout), and
- hygiene-clean (the normalised .dump-ir.txt passes
  `git diff --check` without further manipulation).

This is the closure pattern future ACTs should adopt when
transcripts must capture compiler output that itself
contains trailing whitespace or other non-conforming
bytes.

## 11.5. Gate-push evidence hygiene (CLOSURE01)

The gate-push transcript against `C1_HEAD=fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad`
is captured in this directory as the same
two-paired-form shape used for the dump-ir transcripts in
§11:

```text
gate-push-fedfcbc.log         NORMALISED textual representation
                              (trailing horizontal whitespace
                              stripped per line; passes
                              `git diff --check`).

gate-push-fedfcbc.log.sha256  SHA256 of the ORIGINAL raw bytes
                              (captured from the live
                              `./scripts/quality/gate-push.sh
                              fedfcbc44edb...` invocation).

gate-push-fedfcbc.log.b64     Base64 encoding of the ORIGINAL
                              raw bytes (chunked at 76 columns
                              for git-friendliness).
```

Reconstruct and verify with:

```sh
base64 -d gate-push-fedfcbc.log.b64 | shasum -a 256
# must print the SHA256 listed in
# gate-push-fedfcbc.log.sha256
```

Summary line of the gate-push result:

```text
POLYC_GATE=push
SUBJECT=fedfcbc44edb
CHECK=build      STATUS=PASS
CHECK=install    STATUS=PASS
CHECK=aot        STATUS=PASS
CHECK=jit        STATUS=PASS
CHECK=lsp        STATUS=PASS
CHECK=diff-check STATUS=PASS
VERDICT=PASS
```

## 12. Next ACT (after IR-BOUNDARY03)

The corrected boolean-contract question from §1 of
`docs/notes/llvm-ir-boolean-contract.md` is the input that
IR-BOUNDARY03 needs first:

```text
Does the PolyC neutral IR guarantee:

    IR_BR condition ∈ {0, 1}            (Boolean invariant)
or merely:
    IR_BR condition ∈ I64, zero=false /
                          nonzero=true   (Truthiness invariant)
```

The current source implements contract B (explicit-i64
with strict invariant) via plain trunc at the emission
boundary; the {0, 1} invariant holds implicitly through
the LLVM-C representation but is nowhere asserted in
neutral IR. Whether to add the assertion (and keep B) or
to switch to contract A (cached-i1, requires adding
IR_TYPE_I1) is the boundary ACT's decision.

This section (§12) and §10 carry complementary detail; §10
lists the next ACT and its mission, this section lists the
specific architectural question the next ACT must answer.

## 13. C1 closing state

```text
CORRECTION01 (live progress at CLOSURE01)
    staged architecture       PASS
    scope/HALT discipline     PASS
    C1/C2/C3 separation       PASS
    witness-type cleanup      PASS
    RED-6 wording             PASS  (coverage RED, not product RED;
                                      matrix-shaped recording)
    §3 item 4 stale wording   FIXED  (reviewer correction)
    RED-1A contract           REFACTORED (literal claim falsified;
                                      refined boundary-crossing
                                      claim replaces it; halt
                                      preserved)
    boolean-contract note     CORRECTED (trunc-UB claim removed;
                                      Boolean vs Truthiness
                                      invariant question installed
                                      as input to IR-BOUNDARY03)
    boolean-contract §4
      tightened               DONE (CLOSURE01; reviewer correction:
                                      distinguishes LLVM-consumer
                                      representation fact from
                                      neutral-IR proof obligation;
                                      IR-BOUNDARY03 cannot inherit
                                      "contract B is sound today"
                                      as established fact)
    dump-ir transcript
      hygiene                 NORMALISED (raw bytes SHA256-pinned
                                      outside Git; normalised
                                      representation committed
                                      so `git diff --check` passes)
    C1 commit                 CREATED  (C1_HEAD = fedfcbc44edb,
                                      see §14)
    gate-push                 RUN against C1_HEAD=fedfcbc44edb
                              VERDICT=PASS (build/install/aot/
                              jit/lsp/diff-check all PASS;
                              see §14 and gate-push-fedfcbc.log)
    stale ACT §12 + HANDOFF
      §7/§13/§14 closure
      statements              RECONCILED (CLOSURE01; all three
                              now agree on C1_HEAD and gate
                              PASS; HALT_LM typo fixed to
                              HALT_LLVM; "uncommitted" replaced
                              with C1_HEAD and "clean")
    C1 halt                   HALT_LLVM_SEES_NATIVE_FUSION

PRODUCTION_AUTHORIZATION
    C1 RED/DOC PHASE = YES (this ACT) — EXECUTED, closed as halt
    C2 LLVM IMPL     = NO  (deferred to CORRECTION01-RESUME01)
    C3 CLOSURE       = NO  (deferred to CORRECTION01-RESUME01)
```


## 14. HANDOFF signature

```text
C1_HEAD                = fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad

C1 commit message      = "docs(test): CORRECTION01 stage C1
                          - REDs + boolean contract + closure
                          to HALT_LLVM_SEES_NATIVE_FUSION"

C1 diff stat           = 64 files changed,
                          2872 insertions(+),
                          11 deletions(-)

C1-AC-8
  (git diff --check
   130098c..C1_HEAD)   = PASS, exit 0

C1-AC-11
  (gate-push against
   C1_HEAD)            = PASS, VERDICT=PASS
                         Subject: fedfcbc44edb3013fdd5d2749e6bec0a486ae3ad
                         Per-check status:
                             CHECK=build     STATUS=PASS
                             CHECK=install   STATUS=PASS
                             CHECK=aot       STATUS=PASS
                             CHECK=jit       STATUS=PASS
                             CHECK=lsp       STATUS=PASS
                             CHECK=diff-check STATUS=PASS
                             VERDICT=PASS
                         Transcript: gate-push-fedfcbc.log in
                         this directory (hygiene-normalised,
                         with .sha256 + .b64 sidecars of the
                         raw bytes; b64 round-trip verified).
                         Toolchain: cmake 4.1.6
                         (/run/current-system/sw/bin/cmake,
                         provided by the project Nix migration)
                         + AppleClang 15.0.0 + llvm@21.

C1 halt                = HALT_LLVM_SEES_NATIVE_FUSION
                         (mandatory C1 halt; achieved)
```

The earlier `gate-push-c1.log` / `red-c1-ac11.gate-push-attempt.log`
transcripts in this directory capture the initial
`cmake: command not found` attempt; they are SUPERSEDED by
`gate-push-fedfcbc.log` and remain in place only as
historical residue. The earlier P0 residue
`HALT_GATE_PUSH_TOOLCHAIN_MISSING` is RESOLVED; see §9.

C1 produced its mandatory halt honestly. REDs were captured
truthfully (RED-1A's literal claim did not reproduce at
--dump-ir; the architectural finding strengthens in spite of
that). The boolean contract is documented and locatable. The
predicate coverage is achieved across all six signed
predicates. The handoff to ACT-POLYC-IR-BOUNDARY03 is clean.

C2 and C3 are NOT authorised in this ACT; they are
placeholders that will be authored as a fresh ACT under a
new entry SHA, gated on ACT-POLYC-IR-BOUNDARY03 closing
GREEN.



```

That is precisely what ACT-POLYC-IR-BOUNDARY03 has as its
mission.
