# ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT — implementation authorization, not an execution or completion report
Class: SELFHOST / CORE_SEMANTIC / FACTORY_V2 / CLOSURE_CARDINALITY_CORRECTION
Priority: P0
Prepared: 2026-10-31
Repository: existing canonical local PolyC checkout (s1onique/polyc)
Branch: existing main; no ceremonial per-ACT branch
Expected ENTRY_HEAD: 4c22f97377a2452ee970b2e8393ac3d7b8500360
Expected ENTRY_TREE: 6867b460a6057bf6aaa5dab76d6a777b9f10f141
Binding predecessor: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02 (local, unpublished, CLOSED at HALT_PREDECESSOR_PROOF_INCOMPLETE)
Supersedes: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02
Corrected verdict: HALT_PREDECESSOR_PROOF_INCOMPLETE (UNCHANGED)
Authorized production migrations: ZERO
New production authorities: ZERO
SELFHOST_M2_ACHIEVED=NO; SLICE10_AUTHORIZED=NO

## 0. Mission

Repair the Factory-v2 closure-cardinality defect that the predecessor
introduced, without changing any of the predecessor's technical findings
and without touching a single production byte.

The predecessor's technical result is CORRECT and is NOT revised: the
predecessor's `M-POLYC-RO` experiment physically mutated
`AbiCoreIsValidPointerOperator` rather than `AbiCoreIsRangeOperator`, the
thirteenth authority therefore has no executed causal experiment, and the
predecessor's verdict of `HALT_PREDECESSOR_PROOF_INCOMPLETE` stands.

What is defective is the predecessor's closure BOOKKEEPING: its
committed range contains **two** commits carrying
`ACT-Phase: CLOSE` for the same ACT id, which violates the Cardinality-1
closure-identity invariant.

## 1. The exact defect

The predecessor's committed range is:

```text
576254dd451ef23141b6653fb4f062a6ba960d1d  ACT-Phase: RED
5412bce596f2caa224c448a878459db2afaf7fa3  ACT-Phase: EVIDENCE
2f1db0e3672e79d317e91ccec3ff9c0244dd5fc4  ACT-Phase: CLOSE   <- intended terminal CLOSE
8e078b7ff6e3a6b0a6d8b92e210eaaa5db73dc10  ACT-Phase: CLOSE   <- duplicate CLOSE
4c22f97377a2452ee970b2e8393ac3d7b8500360  (no ACT trailer)   <- ordinary commit
```

The canonical cardinality recipe reports:

```text
EXPECTED 1 CLOSE COMMIT FOR ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02, GOT 2
```

and `scripts/quality/factory-v2-range-check.sh` rejects the range for
either candidate CLOSE:

```text
STATUS=FAIL
REASON=expected exactly 1 CLOSE commit in range, found 2
```

and, for the intended terminal CLOSE:

```text
STATUS=FAIL
REASON=commit 8e078b7ff6e3a6b0a6d8b92e210eaaa5db73dc10 after CLOSE still carries
        ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02; ACT must not continue past CLOSE
```

### 1.1 How the defect arose

The predecessor's C4 CLOSE was committed correctly as `2f1db0e3`. A
FURTHER commit `8e078b7f` was then made, carrying the same ACT trailer,
whose stated purpose was to restate the F14 path-freeze re-verification
against the terminal CLOSE commit. That commit was unnecessary: the
committed C3 form of that file already records the measured substance
(5790 frozen paths, 0 mismatches, F14 PASS), and the terminal
verification belongs in the external read-only receipt, which is outside
the repository. The redundant commit created the second CLOSE.

A follow-up ordinary commit `4c22f973` restored the C3 form of the file
and made the terminal tree equal to the intended CLOSE tree
(`6867b460a6057bf6aaa5dab76d6a777b9f10f141`), but it could not remove the
duplicate CLOSE, because the append-only invariant makes every commit
after `baf5dbd77cf89330699685dffd932c54031c815c` immutable.

### 1.2 Why it cannot be repaired in place

The append-only invariant forbids `amend`, `rebase`, `filter-branch`,
`reset + recommit` and `force push`. The repository's established
mechanism for exactly this class of defect is a forward-only correction
ACT, as used by `ACT-POLYC-SELFHOST-PARSER-SLICE03-CORRECTION01`, whose
recorded defect D5 is "the historical range has six commits, not the
specified five".

Multiple CLOSE commits for one ACT id also have direct precedent in this
repository: `ACT-POLYC-LLVM-FLOAT01-CORRECTION01` carries eight, and
`ACT-POLYC-TOOLING-RUNTIME01-CORRECTION04` carries three, under the
repository's own "RE-CLOSE" convention.

## 2. What this ACT does

1. Record the defect, its cause and its measured consequence.
2. Carry the predecessor's technical verdict forward unchanged, using the
   repository's `ACT-Supersedes` / `ACT-Corrected-Verdict` mechanism.
3. Establish a terminal, unambiguous closure identity for the RECON02
   work: this ACT's own CLOSE is the single authoritative CLOSE for the
   RECON02 line of work, and the predecessor's `2f1db0e3` is named as the
   intended terminal closure of the predecessor's phase range.
4. Change NOTHING else: no production source, no test, no dependency, no
   predecessor evidence byte, no prior ACT document, no prior HANDOFF.

## 3. Explicit non-goals

No production delegation, no new compiler feature, no ABI change, no
change to the predecessor's technical findings, no change to the
predecessor's verdict, no re-run of the predecessor's experiments, no
selection of a successor bundle, no self-hosting or M2 claim.

## 4. Entry gate

```text
git branch --show-current          -> main
git rev-parse HEAD HEAD^{tree}     -> 4c22f97377a2452ee970b2e8393ac3d7b8500360
                                     6867b460a6057bf6aaa5dab76d6a777b9f10f141
git status --porcelain=v1          -> empty
git replace -l                     -> empty
```

The predecessor's five-commit range and the two CLOSE commits are
recorded verbatim in `evidence/.../c0/`.

## 5. Acceptance criteria

| ID | Predicate |
|---|---|
| CAC01 | The defect is recorded with its exact measured consequence: the canonical cardinality recipe reports GOT 2 and the range checker reports `expected exactly 1 CLOSE commit in range, found 2`. |
| CAC02 | The predecessor's technical finding and verdict are carried forward UNCHANGED. |
| CAC03 | This ACT's CLOSE carries `ACT-Supersedes: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02` and `ACT-Corrected-Verdict: HALT_PREDECESSOR_PROOF_INCOMPLETE`. |
| CAC04 | Exactly one CLOSE commit exists for THIS ACT id, and it is the last commit of this ACT's range. |
| CAC05 | The range checker passes for this ACT's own CLOSE. |
| CAC06 | No production source, test, dependency or predecessor evidence byte is changed. |
| CAC07 | Every baseline is conserved: parser 376/376 with MD5 b6f117eb1386ca80f81bc06226e2a741, lexer direct 89/89 45/45 23/23, lexer broad 15 identities with MD5 7ee761440de83552e751e3c3976c1683, graph 52/134/1 cut, 13 authorities structurally active. |
| CAC08 | gate-fast, gate-push, append-only and F14 are green. |
| CAC09 | The external read-only receipt is produced after the terminal CLOSE and binds the corrected closure identity. |
| CAC10 | The RECON02 technical conclusion is NOT weakened: SITE-RANGE-OPERATOR still has no executed causal experiment, and the proposed bounded correction ACT for the predecessor's range site is unchanged. |

## 6. Authorized paths

```text
docs/acts/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01.md
docs/factory/HANDOFF-ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01.md
docs/factory/act-handoff-map.tsv       # one row only
docs/ROADMAP.md                        # bounded append only
evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01/**
```

No `src/**`, no `tools/**`, no existing quality tool, no existing test, no
previous ACT document, no previous HANDOFF, no previous evidence, no
factory doctrine, no dependency, no Python.

## 7. Phase contract

Exactly one linear, non-merge commit per phase, with the repository's
current `factory-v2-commit-msg-check.sh` validation before each commit.

- **C0 — RED**: entry identity, the predecessor's verbatim commit range,
  the reproduced cardinality defect and the frozen acceptance contract.
- **C1 — EVIDENCE**: the closure-identity analysis, the forward-only
  mechanism's justification and the repository precedent.
- **C2 — IMPL**: the correction artifacts (ACT document, HANDOFF, map
  row, ROADMAP append, evidence). No production semantics.
- **C3 — EVIDENCE**: the range check, the cardinality checks, the
  conservation measurement and the gates.
- **C4 — CLOSE**: the terminal commit carrying
  `ACT: ACT-POLYC-SELFHOST-CORE-SEMANTIC-BUNDLE-RECON02-CORRECTION01`,
  `ACT-Phase: CLOSE`, `ACT-Verdict: PASS`, `ACT-Supersedes:` and
  `ACT-Corrected-Verdict: HALT_PREDECESSOR_PROOF_INCOMPLETE`.

## 8. HALT classification

```text
HALT_ENTRY_IDENTITY
HALT_FACTORY_V2_APPEND_ONLY_F14
HALT_BASELINE_CONSERVATION
HALT_EVIDENCE_ID_JOIN_OR_FALSE_PASS
HALT_EXTERNAL_POST_CLOSE_TERMINALITY
```

## 9. Handoff and next authorized step

The HANDOFF must record the corrected closure identity, the unchanged
technical verdict and the unchanged proposed successor. The proposed
next step remains
`ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01-CORRECTION01`, the bounded
append-only correction that executes a real range-site mutation with a
discriminating witness. This ACT does NOT authorize it.

No publication or push as part of this ACT.
