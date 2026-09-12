ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06 — Closure Summary Replacement

This file is the AUTHORITATIVE closure summary for the
runtime ACT chain (CORRECTION03 + CORRECTION04 + CORRECTION05),
replacing the SHA-of-self violation in
`evidence/ACT-POLYC-TOOLING-RUNTIME01/correction05/closure-summary.txt`.

The CORRECTION05 file itself is F14-protected historical
evidence; it is NOT rewritten. This file is the new
authoritative successor, per DOCTRINE.md §22.

## IDENTITY (stable, Git-queryable pattern)

```text
branch           = main
working tree     = clean (verified after each commit)
predecessor      = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05
                   (PASS_WITH_HYGIENE_RESIDUE)
                 = ACT-POLYC-FACTORY-NO-SHA-OF-SELF01
                   (PASS — codifies F-GIT-IDENTITY)
ACT id           = ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06
phase            = CLOSE
verdict          = PASS_WITH_HYGIENE_RESIDUE
```

To obtain the closing commit's SHA:

```sh
git log --grep='^ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06$' \
        --grep='^ACT-Phase: CLOSE$' --pretty=format:'%H'
```

To obtain the CORRECTION05 closing commit's SHA (which the
F-GIT-IDENTITY doctrine forbids embedding here):

```sh
git log --grep='^ACT: ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05$' \
        --grep='^ACT-Phase: CLOSE$' --pretty=format:'%H'
```

## RUNTIME TECHNICAL STATE

The runtime substrate (TOOLING-RUNTIME01 + corrections) is:

- TOOLING_RUNTIME_SEMANTICS        GREEN
- DUAL_PIPE_CAPTURE                GREEN
- EINTR_HANDLING                   GREEN
- INSTALL_PATH                     GREEN
- STALE_PRODUCER_FALSE_GREEN       CLOSED (c05 file(REMOVE) added)
- WORKTREE / RANGE HYGIENE         GREEN for reviewed range

All empirically verified end-to-end:

  cmake --install                      exit=0
  libtos.a + libtos.0.0.1.dylib + symlink installed
  runtime01-selftest built vs prefix   exit=0
  runtime01-selftest run               18/18 PASS
  EINTR retry (against installed)      rc=0 err=4194304
  llvm-gep01-test.sh                   30/30 PASS
  stale-producer negative test         install exit=1
                                        install prefix EMPTY
                                        FATAL_ERROR fires

## HYGIENE ROLLUP (three-count convention per DOCTRINE.md §22)

See `hygiene-rollup.txt` for the full table. Headline:

  baseline F14 findings     = 5
    (4 in c1/c4 evidence; 1 in src/holyc-lib/tooling.HC EOF)
  P2 residue findings       = 1
    (correction03/cmake-install.log:15 verbatim argv)
  newly introduced findings = 0

  TOTAL = 6

  Per the new convention, the relevant CLOSE question is
  "newly introduced findings = 0", which is satisfied.

## TRACK B ADVANCE

GRANTED.

The remaining questions are not about substrate cleanliness.
They are about MIGRATE-GEP01: can we delete the 232-line
Bash GEP harness and preserve its exact behavior in PolyC?

## NEXT ACT

ACT-POLYC-TOOLING-MIGRATE-GEP01
