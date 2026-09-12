# ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION02 — C1 RED

C1 captures the trailer-bookkeeping defect on the C4 CLOSE
commit of `ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01`
(commit `505b007`).

## Defect summary

The commit trailer block on `505b007`:

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
HALT_CLASS: GOVERNANCE
BLOCKS_NEXT: NO
```

violates `docs/factory/GIT-METADATA.md` §2.4 in two ways:

1. **`HALT_CLASS` and `BLOCKS_NEXT` trailers on a PASS
   verdict** — §2.4 forbids both on a `PASS(_...)*` CLOSE
   (verifier rejects with `STATUS=FAIL` /
   `REASON=PASS verdict forbids HALT_CLASS (count=1)`).
2. **Missing `ACT-Supersedes`** — §2.3 rule 2 requires
   `ACT-Supersedes` whenever `ACT-Corrected-Verdict` is
   present.

## v2-correct trailer set

```
ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
ACT-Phase: CLOSE
ACT-Verdict: PASS
ACT-Supersedes: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED
```

(no `HALT_CLASS` / `BLOCKS_NEXT`).

## Where the HALT classification lives

The corrected verdict's HALT classification
(`HALT_CLASS=GOVERNANCE / BLOCKS_NEXT=NO`) lives in the
descriptive artifacts, not in commit trailers:

- `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/
  c4/closure-summary.txt` (PRE-CONDITION CLAIM block)
- `evidence/ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01/
  c4/roadmap-transition.txt` (entire document)
- `docs/ROADMAP.md` (CORRECTION01 status block)

## Why this ACT does not amend `505b007`

`docs/factory/DOCTRINE.md` §23 + `AGENTS.md` F-GIT-IDENTITY
forbid amending historical commits. The F-GIT-IDENTITY
violation-discovery-and-repair procedure explicitly
prescribes "open a new bounded correction ACT" rather than
amend. This ACT is that correction.

## Files in this directory

- `red-trailer-defect.txt` — captured defect witness:
  trailers present on `505b007`, verifier verdict, v2-correct
  set, §2.3 + §2.4 rule quotes, factory-append-only-test
  PASS evidence.

## Reproduction

```sh
# 505b007 trailers
git show --format=%B -s 505b007

# Verifier verdict
python3 scripts/quality/factory-halt-classification.py \
    <(git show --format=%B -s 505b007)

# v2-correct trailer set (SHOULD have been)
# ACT: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01-CORRECTION01
# ACT-Phase: CLOSE
# ACT-Verdict: PASS
# ACT-Supersedes: ACT-POLYC-AOT-PIC-EXTERNAL-REFS01
# ACT-Corrected-Verdict: HALT_GATE_PUSH_FAILED

# Append-only invariant preserved (no amend was used)
sh scripts/quality/factory-append-only-test.sh
```
