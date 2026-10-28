# ACT-POLYC-SELFHOST-PARSER-SURFACE-RECON05 — the SELECTED PROVENANCE CONTRACT

**Selected candidate:** `SUB-003`

---

## 1. The G0 oracle (the LEGACY C authority)

```text
G0_ROLE=THE LEGACY C DECISION, IN AN OBJECT-LEVEL ORACLE
G0_OBJECT=build/CMakeFiles/hcc.dir/parser.c.o
G0_OBJECT_IS_REAL_PRODUCTION_TU=YES
G0_PROVENANCE=compiled by the production CMake build from the live
              src/parser.c with the production flags
G0_FLAGS=-Wextra -Wall -Wpedantic -O3 -DNDEBUG -O2 -std=gnu11 -arch arm64
G0_TARGET_OBJECT_FORMAT=Mach-O
G0_TOOLCHAIN_NM=/usr/bin/nm
G0_ORACLE_POLYC_REFERENCE=ABSENT
G0_ORACLE_HAND_WRITTEN=NO
```

The absence of a reference to the proposed PolyC symbol is the
mechanical proof that the oracle is INDEPENDENT of the proposed target.
See `c2/selected-legacy-oracle.md`.

## 2. The G1/G2/G3 producers

The four generations are the repository's existing self-host ladder.
For this candidate the generations are:

```text
G0=the production C compiler (./hcc), which owns the legacy decision
G1=the stage-1 compiler produced by the bootstrap stage0 compiler
G2=the stage-2 compiler produced by the stage-1 compiler
G3=the stage-3 compiler produced by the stage-2 compiler
```

The producers are **AVAILABLE AND DISTINCT** in this repository:

```text
PRODUCER_STAGE0=build/hcc-bootstrap02
PRODUCER_STAGE1=build/hcc-bootstrap03
PRODUCER_STAGE2=build/hcc-bootstrap04
PINNED_PRODUCER_BUILD=build-pinned-producer/tree
```

The successor MUST bind its G1/G2/G3 producers to these EXACT
binaries, with their SHA-256 digests recorded, and MUST verify that the
three producers are pairwise DISTINCT (different digests).

**HONEST LIMITATION.** This ACT did NOT execute a four-generation PolyC
candidate semantic differential, because the candidate component DOES
NOT EXIST YET.  The four-generation differential is the SUCCESSOR's
job.  This ACT establishes only that the producers are available and
distinct and that the G0 object is the real production TU.

## 3. The architecture

```text
TARGET_ARCHITECTURE=arm64
TARGET_OBJECT_FORMAT=Mach-O
TARGET_TRIPLE=arm64-apple-darwin
COMPILER=./hcc (hcc v0.0.15-beta)
COMPILER_SOURCE_COMMIT=525374202a96d5d4235e25ed76cdff5504d65e7b
```

## 4. The tool provenance of this ACT

```text
TOOL_CENSUS_VERIFIER=tools/quality/parser-surface-recon05-verify.HC
TOOL_INDEPENDENT_RECOMPUTER=tools/quality/parser-surface-recon05-independent.HC
TOOL_LANGUAGE=PolyC (F-POLYC-TOOLS)
CANONICAL_CHECKER=tools/quality/parser-slice-recon03-eligibility.HC (UNMODIFIED)
CANONICAL_RANKER=tools/quality/parser-slice-recon03-ranking.HC (UNMODIFIED)
```

The canonical checker and the canonical ranker are CLOSED predecessor
artifacts.  They were used READ-ONLY and were NOT modified.
