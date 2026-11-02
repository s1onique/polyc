# `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02`

**Title:** Re-establish the Factory-v2 phase sequence of
`ACT-POLYC-SELFHOST-DRIVER-MIGRATION01` with the `ACT:` and
`ACT-Phase:` trailers that the Doctrine requires on EVERY ACT
commit, WITHOUT rewriting any committed history.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** GOVERNANCE / GIT-METADATA / CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-DRIVER-MIGRATION01`

**Factory-Version:** 2

**Production semantic changes:** **FORBIDDEN** in this ACT. The
parent ACT's production delta is mechanically GREEN and must not be
re-mutated. This ACT changes NO production file.

**Re-mutation of the predecessor's evidence directories:**
**FORBIDDEN** (F14). The parent ACT's committed evidence is NOT
edited by this ACT.

---

## 0. Mission

This ACT establishes the single mechanical claim:

```text
parent_C1_C2_C3_commits_carry_the_ACT_trailer = NO
the_contiguous_parent_range_covers_every_phase = NO
corrected_range_is_contiguous_and_trailer_complete = YES
```

and only that.

---

## 1. Why this ACT exists

The Doctrine's additive Factory-v2 mechanics require:

> Every ACT commit carries `ACT:` and `ACT-Phase:` trailers
> (RED / IMPL / EVIDENCE / CLOSE). CLOSE additionally carries
> `ACT-Verdict:` matching the verdict grammar.

and the canonical range validator enforces it as rule 2:

> Every commit in FIRST..CLOSE has ACT=&lt;same id&gt; with a valid
> ACT-Phase.

The parent ACT's C0 commit DOES carry the trailers:

```text
ACT: ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
ACT-Phase: RED
```

but the parent ACT's C1, C2 and C3 commits DO NOT. Their subject
lines use the human-readable form

```text
ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C1: EVIDENCE -- ...
```

which is NOT a git trailer block. The canonical commit-message
validator classifies those three commits as `MODE=NON_ACT`, and the
range validator's backwards walk from a CLOSE therefore stops at C0,
because C1 does not carry the `ACT:` trailer.

THE MEASURED FACT:

| commit | phase | `ACT:` trailer | validator mode |
|---|---|---|---|
| C0 | RED | YES | ACT |
| C1 | EVIDENCE | NO | NON_ACT |
| C2 | IMPL | NO | NON_ACT |
| C3 | EVIDENCE | NO | NON_ACT |

The parent ACT's own contract states: "Commit trailers for each phase
must be prevalidated by repository tools." Three of its five phases
did not satisfy that.

THE HISTORY IS APPEND-ONLY. The parent ACT's commits cannot be
amended, rebased or replayed. The only forward-only mechanism that
can restore a CONTIGUOUS, TRAILER-COMPLETE phase range is a NEW ACT
whose commits carry the trailers.

---

## 2. Scope

### allowed

- `docs/acts/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02.md`
  -- this document.
- `evidence/ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02/**`
  -- this ACT's evidence.
- The parent's HANDOFF, the parent's terminality plan, the ROADMAP
  section and the handoff-map rows, to the extent that they must
  name this correction.

### forbidden

- Any modification of the parent ACT's committed evidence directories.
- Any modification of ANY production file: `src/**`, `tools/**`.
- Any modification of the canonical gates, scripts or tests.
- Any amendment, rebase, replay or history rewrite of ANY commit.

---

## 3. The correction

The correction is a FORWARD-ONLY phase sequence. This ACT's commits
carry the trailers:

```text
ACT: ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02
ACT-Phase: RED | EVIDENCE | IMPL | CLOSE
```

and they carry the parent's ACT identity as well, so that the
parent's range becomes CONTINUOUS across the boundary:

```text
ACT: ACT-POLYC-SELFHOST-DRIVER-MIGRATION01-CORRECTION02
ACT-Supersedes: ACT-POLYC-SELFHOST-DRIVER-MIGRATION01
```

The canonical range validator's rule 5 states that
`ACT-Supersedes` may appear ONLY on a CLOSE. It is therefore NOT used
on the intermediate commits of this ACT, and the range identity of
this ACT is established by its own `ACT:` trailer alone.

THE KEY MECHANIC: the range validator derives FIRST by walking
BACKWARDS from the CLOSE through commits that carry the SAME `ACT:`
id, stopping at the first commit that does not. The parent ACT's
range is therefore broken by the three trailer-less commits, and this
ACT cannot repair that from the outside without rewriting history.

WHAT THIS ACT THEREFORE DOES, AND WHAT IT DOES NOT:

- It DOES record, by MEASUREMENT, the exact trailer state of every
  one of the parent ACT's five phase commits, so that the defect is
  a mechanical fact and not a narrative.
- It DOES establish a NEW, fully trailer-complete, contiguous phase
  range for the parent's WORK, so that the repository has a
  mechanically valid range covering the same evidence.
- It does NOT claim that the parent's original range was valid. It
  records that it was NOT, and it records WHY it cannot be repaired
  without a history rewrite that the append-only invariant forbids.

---

## 4. Exit gate

This ACT closes when, MEASURED BY EXECUTION:

1. the canonical commit-message validator reports `MODE=ACT` and
   `STATUS=PASS` for every commit of this ACT;
2. the canonical range validator reports `STATUS=PASS` for this
   ACT's own range;
3. the parent ACT's five phase commits have their trailer state
   recorded, by measurement, in this ACT's evidence;
4. the parent's production delta is byte-identical, i.e. this ACT
   changed NO production file;
5. the parent's committed evidence directories are byte-identical.

---

## 5. Non-goals

This ACT does NOT:

- rewrite, amend, rebase or replay any commit;
- claim the parent's original range was valid;
- change any compiler behaviour;
- discharge AC50 of the parent ACT, which remains deferred until the
  external post-CLOSE receipt of the parent's CLOSE.
