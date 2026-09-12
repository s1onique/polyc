# `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02`

**Title:** Repair the trailer-bookkeeping defect on the C4 CLOSE
commit of `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01` and
record the v2 HALT classification in descriptive artifacts
under F-GIT-IDENTITY (no amend; corrections are new commits).

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / TRAILER-BOOKKEEPING / CORRECTION

**Predecessor:** `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01`
**Predecessor outcome:** C4 CLOSE committed at `505b007` with a
trailer set that violates `docs/factory/GIT-METADATA.md` §2.4:
`HALT_CLASS` / `BLOCKS_NEXT` trailers are forbidden on a
`PASS(_...)*` CLOSE commit.

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN**.

**Re-mutation of historical commits:** **FORBIDDEN**
(`git commit --amend`, `git rebase`, `git filter-branch`,
`git filter-repo`, `git replace`, reset+recommit — all
forbidden by `docs/factory/DOCTRINE.md` §23). Corrections
are new commits.

---

## 0. Mission

This ACT does NOT re-mutate the predecessor C4 CLOSE commit
(`505b007`). It:

1. Records the trailer-bookkeeping defect on the predecessor
   CLOSE commit so the board sees it.
2. Establishes the v2-correct trailer set as a new commit
   (a `CORRECTION03` style chained correction is not needed
   here because the corrected trailer set can be captured
   by superseding the predecessor's CLOSE trailer record
   in the ROADMAP / HANDOFF / closure-summary).
3. Re-affirms that the corrected verdict's HALT
   classification lives in the descriptive artifacts (under
   F-GIT-IDENTITY and §2.4 of `GIT-METADATA.md`), not in
   trailers on a `PASS` CLOSE commit.

Concretely:

```
ACT-Verdict              : PASS  (this ACT closes PASS)
ACT-Supersedes           : ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Corrected-Verdict    : PASS_WITH_GOVERNANCE_HALT_CORRECTION
                           (this ACT re-classifies the
                            predecessor CLOSE's TRAILER
                            BOOKKEEPING defect without
                            rewriting its historical content)
```

The mechanical claim is unchanged from
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01`: the
predecessor ACT's production delta is GREEN; the gep01
gate-push failure is non-attributable; v2 classification is
`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`.

---

## 1. Why this ACT exists

The C4 CLOSE commit of
`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01` (commit
`505b007`) carried:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

`docs/factory/GIT-METADATA.md` §2.4 is explicit:

> Cardinality rules:
>
> * `HALT_CLASS` -- exactly 0 on a `PASS(_...)*` CLOSE;
>   exactly 1 on a `HALT_*` CLOSE.
> * `BLOCKS_NEXT` -- exactly 0 on a `PASS(_...)*` CLOSE;
>   exactly 1 on a `HALT_*` CLOSE.

The verifier (`scripts/quality/factory-halt-classification.py`)
correctly rejected the trailer combination:

```
STATUS=FAIL
REASON=PASS verdict forbids HALT_CLASS (count=1)
```

The defect is also missing `ACT-Supersedes` per §2.3 rule 2:

> If present, `ACT-Corrected-Verdict` is OPTIONAL. If
> present, it appears ONLY on the CLOSE commit AND
> `ACT-Supersedes` MUST also be present.

The corrected verdict about the predecessor
(`HALT_GATE_PUSH_FAILED`) and its classification
(`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`) are truthful and
match the v2 mechanical claim. They need a v2-correct
binding surface.

---

## 2. v2-correct binding

Per `docs/factory/DOCTRINE.md` §25 + `docs/factory/GIT-METADATA.md`
§2.3 + §2.4:

1. The corrected verdict lives on a **grandfathered
   predecessor** (`ACT-POLYC-AOT-PIC-EXTERNAL-REFS01`,
   closed `2b1786c` before
   `ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01`'s activation
   boundary). The predecessor's historical trailer cannot
   be rewritten (F14).
2. The HALT classification for that corrected verdict
   therefore lives in **descriptive artifacts**: ROADMAP,
   closure-summary, HANDOFF.
3. This ACT's CLOSE carries a `PASS` verdict and a
   `PASS_WITH_GOVERNANCE_HALT_CORRECTION` corrected
   verdict — the corrected verdict names the trailer-
   bookkeeping defect on the predecessor's CLOSE commit
   (`HALT_CLASS` / `BLOCKS_NEXT` placed on a PASS CLOSE).
4. The actual v2-correct trailer set on the predecessor
   C4 CLOSE commit `505b007` SHOULD have been:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
```

   (which is what SHOULD have been committed; the
    `505b007` commit is mechanically inconsistent with
    §2.4 + missing `ACT-Supersedes`).

5. The HALT classification for the corrected verdict
   (`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`) lives in
   `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/
    c4/closure-summary.txt` (lines under "PRE-CONDITION
   CLAIM"), in
   `c4/roadmap-transition.txt` (the entire document),
   and in the ROADMAP entry for
   `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01` (the block added
   by CORRECTION01's C4 CLOSE).

---

## 3. Scope

### allowed

- `docs/acts/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02.md`
  (this file)
- `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02/**`
- `docs/ROADMAP.md` (correction note under the CORRECTION01
  status block)

### forbidden

- `src/aarch64.c` and any production source
- `src/x86_64.c`
- the predecessor ACT's evidence directories
  (`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/`)
- the CORRECTION01 ACT's evidence directories
  (`evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/`)
- the historical commit `505b007` (no amend, no rebase,
  no filter-branch, no filter-repo, no git replace,
  no reset+recommit — F-GIT-IDENTITY + §23)
- any push to `origin/main`
- opening `ACT-POLYC-BOOTSTRAP01` (out of scope)

---

## 4. Entry gate (F1)

```text
git branch --show-current = main
git status --short        = clean
git rev-parse HEAD        = 505b00769aa80619447334ecad1d944a7b74792e
                           (C4 CLOSE of CORRECTION01;
                            trailer-bookkeeping defect)
```

Recorded before any mutation.

---

## 5. Acceptance criteria

```
AC-02.1  git diff --stat 505b007..HEAD -- src/ returns empty
AC-02.2  git diff --stat 505b007..HEAD -- evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/ returns empty
AC-02.3  git diff --stat 505b007..HEAD -- evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01/ returns empty
AC-02.4  The CORRECTION01 ACT document is NOT mutated
AC-02.5  ROADMAP.md gains a correction note under the
         CORRECTION01 status block, naming:
           - the trailer-bookkeeping defect on 505b007
           - the v2-correct trailer set
           - the descriptive HALT classification binding
AC-02.6  evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02/
         c2/ carries the v2-correct trailer set as a
         plain-text artifact
AC-02.7  make gate-fast PASS
AC-02.8  factory-append-only-test PASS (no amend was used)
```

---

## 6. Commit topology

```
C1 RED      — capture the trailer-bookkeeping defect on
               505b007 + the v2-correct trailer set.
C2 IMPL     — produce this ACT's evidence packet and
               ROADMAP correction note.
C3 EVIDENCE — final-tree gate-fast PASS.
C4 CLOSE    — ACT-Supersedes CORRECTION01,
               ACT-Verdict: PASS,
               ACT-Corrected-Verdict: PASS_WITH_GOVERNANCE_HALT_CORRECTION.
```

Do not exceed four commits in this ACT.

---

## 7. HALT taxonomy

This ACT does not produce a HALT_*-verdict CLOSE. Its
corrected verdict is `PASS_WITH_GOVERNANCE_HALT_CORRECTION`
which is in the `PASS(_...)*` class (regex
`^(PASS(_[A-Z0-9_]+)*|HALT_[A-Z0-9_]+)$`); HALT_CLASS /
BLOCKS_NEXT trailers are forbidden on it.

The corrected verdict's HALT classification lives in the
descriptive artifacts.

---

## 8. Closure handoff

Follow `docs/factory/HANDOFF-TEMPLATE.md` Factory v2 form.

The CLOSE trailer on this ACT's C4 commit MUST carry:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Corrected-Verdict: PASS_WITH_GOVERNANCE_HALT_CORRECTION
```

(No `HALT_CLASS` / `BLOCKS_NEXT` trailers; per §2.4 those
are forbidden on `PASS(_...)*` CLOSE.)