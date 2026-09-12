ACT-POLYC-TOOLING-RUNTIME01
C3 EVIDENCE — index of evidence files

This directory contains the C3 evidence pack for
ACT-POLYC-TOOLING-RUNTIME01.

------------------------------------------------------------
Files
------------------------------------------------------------

  README.md                      this file
  process-matrix.txt             full process / fs / temp /
                                  GEP matrix output
  verdict-channel.txt            seeded-failure verdict run
  gep-dogfood.txt                Bash vs PolyC parity
  compiler-hang-bisection.txt    bisection that found the
                                  parser-ternary defect
  conservation-gates.txt         shell-loc-gate output
  llvm-gep-loc.txt               llvm-gep01-test.sh LOC
                                  (must remain 232 to satisfy
                                   AC24 no-growth)

------------------------------------------------------------
Verification summary
------------------------------------------------------------

  P1 success-child           PASS
  P2 nonzero-exit            PASS
  P3 stderr-separate         PASS
  P4 missing-executable      PASS
  P5-1 literal-spaces        PASS
  P5-2 literal-dollar        PASS
  P5-3 literal-star          PASS
  P5-4 literal-semicolon     PASS
  P12 file-exists            PASS
  P12 file-read              PASS
  P13 file-write             PASS
  P14 temp-unique            PASS
  P15 cleanup                PASS
  GEP hcc-exit               PASS
  GEP contains-gep-i8        PASS
  GEP no-inbounds            PASS
  GEP no-ptrtoint            PASS
  GEP no-inttoptr            PASS

  Total: PASS=18 FAIL=0

  Seeded failure:            FAIL=1, exit=1 (correct)
  Normal run:                FAIL=0, exit=0 (correct)

  Bash-vs-PolyC parity:      YES (5/5 GEP assertions)

  shell-loc-gate:            PASS
  llvm-gep01-test.sh LOC:    232 (unchanged)

------------------------------------------------------------
Tooling
------------------------------------------------------------

  ./hcc (LLVM 22 enabled) at commit-hash 456b71c
  Apple clang 15.0.0.15000040, aarch64-apple-darwin
  LLVM 22.1.8 (llvm-as, opt on PATH)
  ./build/test-prefix/ hermetic install dir with libtos

------------------------------------------------------------
End of file
------------------------------------------------------------
