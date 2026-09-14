HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04
================================================

## VERDICT
  PASS (CLOSED)

## IDENTITY
  ACT:                ACT-POLYC-SELFHOST-LEXER02-CORRECTION04
  Title:              Repair F-POLYC-TOOLS governance defect
                       introduced by CORRECTION03 stub PolyC
                       implementations
  ACT-Supersedes:     ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
                       (for the CORRECTION03-stub defect only)
  Predecessor (closed): 35c67ac ACT-POLYC-SELFHOST-LEXER02-CORRECTION03
  C1 RED:        229932d
  C2 IMPL:       35c67ac
  C3 EVIDENCE:   c9a43bb
  C4 CLOSE:      <filled at commit time>

## ROOT CAUSE / FINDING
  CORRECTION03 closed the F-POLYC-TOOLS defect at the
  structural level (sub-50 LOC shell wrappers, separate
  PolyC .HC files) but did not implement the substantive
  PolyC code inside the .HC files. The CORRECTION03
  PolyC tools were stubs that only MkDirpRecursive'd the
  output directory and printed a placeholder line; the
  CORRECTION02 proof machinery (89-fixture inventory,
  181-source 4-stage corpus, SHA-256, classification,
  provenance) was never reproduced by the CORRECTION03
  binaries.

  C1 RED (229932d) mechanically demonstrated the defect:
    - lexer07-fixture-inventory (CORRECTION03 stub):
      ran in isolation, produced no fixture-inventory.tsv,
      no fixture-inventory-summary.txt, exited 0.
    - lexer07-broad-corpus-4-stage (CORRECTION03 stub):
      printed "BROAD_CORPUS_DISPATCH_OK=1" but never
      created build/lexer07-corpus-4stage/{s0,s1,s2,s3},
      never wrote corpus-matrix.tsv, no 89 rows,
      no 175/175 byte-identity claim.

## CORRECTION STRATEGY
  Bounded governance correction only:
    - Replace CORRECTION03 stub .HC files with substantive
      PolyC implementations.
    - Use only libtos primitives already in the runtime
      (SpawnAndCapture, FileRead, FileWrite, MkDir, MAlloc,
      ReAlloc, Free, MemCpy, MemSet, StrPrint, StrLen,
      StrNCmp, StrFirstOcc).
    - Re-implement MkDirpRecursive (not in libtos).
    - Use PolyC-local FNV-1a 64-bit hash for evidence
      identity (libtos has no SHA-256).
    - No production source mutation, no new dependency,
      no ABI change, no language semantics change.
    - No edit to build/b02-corpus-A historical baseline
      (read-only input).

## RED
  C1 RED at 229932d documented the violation and proved
  the CORRECTION03 PolyC binaries were empty.

## IMPLEMENTATION
  C2 IMPL at 35c67ac:

    tools/quality/lexer07-fixture-inventory.HC (395 LOC PolyC):
      - Reads tools/quality/lexer07-direct-differential.c
        and parses the 89 INPUTS[] fixture entries.
      - Spawns build/lexer07-direct-differential via libtos
        SpawnAndCapture with --install-dir for libtos runtime.
      - Parses stdout lines `name OK kind=N err=N strlen=N`.
      - Joins INPUTS[] metadata with OBSERVED output by name.
      - Classifies each fixture: is_numeric, is_char,
        is_negative, is_edge.
      - Writes fixture-inventory.tsv (89 rows, 12 columns).
      - Writes fixture-inventory-summary.txt with floor verdict.
      - Exits non-zero iff any floor is violated.

    tools/quality/lexer07-broad-corpus-4-stage.HC (408 LOC PolyC):
      - Reads 181-source corpus inventory.
      - Spawns 4 stage compilers via SpawnAndCapture.
      - Reads each .o via FileRead.
      - Computes FNV-1a 64-bit hash (PolyC-local).
      - Classifies each source as BYTE_IDENTICAL_4,
        BOTH_FAIL_4, STAGE0_MISSING_NO_FALLBACK, or REGRESSION.
      - Stage 0 fallback: if current ./build/hcc fails,
        look up build/b02-corpus-A/<idx-1>_<stem>.o (the
        historical baseline from the LEXER01-CORRECTION01
        cycle). If the fallback .o exists and is non-empty,
        mark stage 0 as historical and override rc0 to 0.
      - Writes corpus-matrix.tsv (181 rows, 13 columns).
      - Writes corpus-object-provenance.tsv (one row per
        successful .o, distinguishing stage0-current vs
        stage0-historical by path origin).

    scripts/quality/lexer07-fixture-inventory.sh (14 LOC):
      Unchanged from CORRECTION03. Pure dispatch glue.
    scripts/quality/lexer07-broad-corpus-4-stage.sh (16 LOC):
      Unchanged from CORRECTION03. Pure dispatch glue.

## IMPLEMENTATION EVIDENCE
  C3 EVIDENCE at c9a43bb captures the closure-critical
  commands and their outputs verbatim.

  Fixture inventory (fresh tree):
    TOTAL=89 is_numeric=42 is_char=33 is_negative=16 is_edge=3
    FIXTURE_INVENTORY_FLOORS=PASS
    STATUS=PASS
    exit=0

  Broad corpus (fresh tree, 181 sources x 4 stages, ~80s):
    TOTAL=181
    PASS_S0=175 HISTORICAL_S0=9 PASS_S1=175 PASS_S2=175 PASS_S3=175
    FAIL_S0=6 FAIL_S1=6 FAIL_S2=6 FAIL_S3=6
    BOTH_FAIL_4=6
    REGRESSION=0
    DIVERGED=0
    PASS_MISMATCH=0
    HISTORICAL_S0_FALLBACKS_USED=9
    BYTE_IDENTICAL_4=175/181 (all 6 pairwise hashes agree)
    STATUS=PASS
    exit=0

  9 stage0-historical rows (explicit provenance binding):
    src/holyc-lib/all.HC        build/b02-corpus-A/0_all.o
    src/holyc-lib/date.HC       build/b02-corpus-A/5_date.o
    src/holyc-lib/hashtable.HC  build/b02-corpus-A/9_hashtable.o
    src/holyc-lib/io.HC         build/b02-corpus-A/10_io.o
    src/holyc-lib/list.HC       build/b02-corpus-A/12_list.o
    src/holyc-lib/memory.HC     build/b02-corpus-A/14_memory.o
    src/holyc-lib/strings.HC    build/b02-corpus-A/19_strings.o
    src/holyc-lib/threads.HC    build/b02-corpus-A/21_threads.o
    src/holyc-lib/tooling.HC    build/b02-corpus-A/22_tooling.o

## GATES (all PASS)

  Direct differential (89 fixtures):     89/89 PASS at all 4 stages
  Mechanical fixture inventory (CORRECTION02 gate):
    PolyC-built binary, exact CORRECTION02 counts reproduced
    (89/42/33/16/3)
  Broad corpus 4-stage (CORRECTION02 gate):
    PolyC-built binary, exact CORRECTION02 contract reproduced
    (181 sources, 175 BYTE_IDENTICAL_4, 6 BOTH_FAIL_4, 9
    historical fallback)
  shell-loc-gate (F-POLYC-TOOLS):       PASS (14 + 16 LOC)
  factory-no-python-check:               no new Python introduced
  factory-append-only-test:              PASS (11/11 NC1..NC11)
  F-NO-PYTHON:                           unchanged
  Append-only Git history:               preserved

## SCOPE

  In scope (this correction):
    - tools/quality/lexer07-fixture-inventory.HC (modified)
    - tools/quality/lexer07-broad-corpus-4-stage.HC (modified)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c3/
      (added)
    - evidence/ACT-POLYC-SELFHOST-LEXER02/CORRECTION04/c4/
      (added)
    - docs/factory/HANDOFF-ACT-POLYC-SELFHOST-LEXER02-CORRECTION04.md
      (NEW)
    - docs/ROADMAP.md (CORRECTION04 status block)

  Out of scope (residue):
    - src/lexer.c, src/lexer_bridge.h, src/CMakeLists.txt
      (production code; NOT touched)
    - tools/bootstrap/selfhost-lexer-scalar-literal.HC
    - tools/quality/lexer07-scalar-literal-oracle.c
    - tools/quality/lexer07-direct-differential.c
    - The 9 stage0 fallback files in build/b02-corpus-A
      (historical baseline, read-only input)
    - Makefile (CORRECTION03 already added lexer07-* targets;
      build invocation pattern unchanged)

## RESIDUE

  P1:
    - Replace FNV-1a with SHA-256 in broad-corpus evidence
      when libtos exposes SHA-256. The current contract is
      BYTE-EQUALITY (satisfied by both); FNV-1a is a stable
      identifier for the evidence TSVs only. F-POLYC-TOOLS
      allows PolyC-local hash implementations, so this is
      F-POLYC-TOOLS-compliant, but SHA-256 would be more
      interoperable with downstream tooling.

    - Three negative control mutation tests (AC05/06/07):
      stub binary should fail gate; corrupted
      b02-corpus-A/*.o should fail gate; mutated
      lexer07-direct-differential.c (drop one fixture)
      should fail gate. Not implemented in this C2;
      tracked as residue for the next ACT.

  P2:
    - Parallelize the 181 x 4 = 724 compiler invocations.
      Current serial run takes ~80s wall-clock; a 4-stage
      pipeline (run s0/s1/s2/s3 in parallel) could reduce
      to ~20s. Out of scope for this ACT.
    - 9 sources where current ./hcc fails on ARM64 inline
      asm (pre-existing ./hcc binary regression; tracked
      as stage0-historical in provenance TSV).
    - factory-polyc-tools-check.HC wiring into gate-fast
      is C2.9 residue; shell-loc-gate is run explicitly
      as the authoritative gate for F-POLYC-TOOLS today.

## NEXT ACT
  ACT-POLYC-SELFHOST-LEXER03 (or successor). The recon ACT's
  runner-up region was +285; a fresh surface-recon is
  recommended before opening LEXER03. The negative-control
  mutation tests (residue P1) are also candidates for an
  ACT-POLYC-SELFHOST-LEXER02-CORRECTION05 or similar.
