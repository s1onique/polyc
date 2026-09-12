# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 — evidence index

This file is the **ACT-level evidence index**. It is NOT itself a
single phase packet; the phase packets live in `c1/`, `c2/`, `c3/`,
`c4/` and that structure is the authoritative source of truth for any
specific claim.

The detail captured here is pre-RED residue from the original handoff
(the audit notes that surfaced three mechanical defects during the
push pre-flight of merge commit `8f398be`). It is preserved as
historical context per F14 (current truth may invalidate history, but
history itself is not rewritten).

============================================================
Identity
============================================================

```text
branch            = main
HEAD              = 8f398be66487488e8aef13a936b5db835b0ff6db
Track-A parent    = a14ea6c5cc8d0177edf2f42d5ca5b5d4b2a95d88
Track-B parent    = e544a48f192606256af9f348befec0c852b6387b
merge-base        = 456b71c0f2535c6175271d2107b67f985b4bc2c8
protection branch = integration/pre-bootstrap-track-merge
origin/main       = e544a48 (unchanged; no push performed)
```

============================================================
Defect D1 — llvm-gep01-test is unbound (B5-class)
============================================================

Symptom

  * tools/quality/llvm-gep01-test.HC    EXISTS  (44607 bytes,
                                              MIGRATE-GEP01 C2 IMPL)
  * scripts/quality/llvm-gep01-test.sh  MISSING (deleted by
                                              MIGRATE-GEP01 C3)
  * No Makefile rule produces llvm-gep01-test
  * No quality gate invokes tools/quality/llvm-gep01-test.HC
  * No gate-fast, gate-push, or shell gate touches it
  * .gitignore lists "llvm-gep01-test" (binary) on line 69
    implying a build target was planned but never added

Conservation impact

  Track-A a14ea6c : llvm-gep01-test 30/0 PASS (Bash harness)
  Track-B e544a48 : same 30/0 PASS (closure claim from C3)
  Merged  8f398be : 30/0 not reproducible via the gate graph;
                    the .HC source exists but is not built
                    or invoked by any gate.

  This is the F-MECHANICAL-BLOCKING B5 pattern:
  "mechanically required predecessor capability exists,
   but the quality system no longer exercises it."

Historical acknowledgement

  MIGRATE-GEP01 C4 residue.txt P2.3 explicitly noted:
  "The PolyC harness is currently built ad-hoc via the
   documented `./hcc --install-dir=... -o llvm-gep01-test
   tools/quality/llvm-gep01-test.HC` incantation. A
   `make llvm-gep01-test` target would tighten the
   freshness invariant. Out of scope for this ACT
   (F7: don't refactor adjacent code)."

  Reviewer correctly notes: F7 was being misapplied.
  The Makefile target IS the binding required by
  Outcome A of MIGRATE-GEP01; it is NOT adjacent code.

Closure claim defect

  MIGRATE-GEP01 C3 conservation-gates.txt claims:
  "llvm-gep01-test (PolyC) | PASS | GEP01_PASS=30 ..."

  This claim was run ad-hoc against the pre-built
  ./hcc binary. It is not reproducible from a clean
  tree via the gate graph. Per F9 (fresh-tree evidence
  outranks warm-tree evidence) and F10 (Conservation
  before closure), this conservation claim is INSUFFICIENT.

============================================================
Defect D2 — install seam has missing errno_shim.o
============================================================

Symptom (live, captured at C1 RED)

  Direct `hcc -lib tos` invocations in:

  1. Makefile lsp-test (line 74):
       cd ./src/holyc-lib && ../../hcc -lib tos \
           --install-dir=$(CURDIR)/build/test-prefix \
           ./all.HC

  2. scripts/quality/gate-push.sh line 284 (GPUSH-2):
       cd ./src/holyc-lib && ../../hcc -fPIC -lib tos \
           --install-dir='$gate_prefix' ./all.HC

  Both invoke hcc's -lib tos with NO errno_shim.o
  on the eventual cc -dynamiclib link line.

  Live witness: nm src/holyc-lib/libtos.a | grep errno
                 U _Errno

  Canonical CMake install dance (src/CMakeLists.txt
  install(CODE ...) stanza) DOES incorporate errno_shim.c,
  producing libtos.a + libtos.dylib + libtos.0.0.1.dylib
  with _Errno resolved to __error (macOS).

Pre-existing residue (reclassified)

  MIGRATE-GEP01-CORRECTION02 §10 explicitly classified
  this as P1 NON_BLOCKING_GOVERNANCE_RESIDUE. The
  classification was wrong — the defect blocks gate-push
  AND make lsp-test, so it is BLOCKING, not governance.

============================================================
Defect D3 — shell budget ratchet violation
============================================================

Symptom (live, captured at C1 RED)

  factory-halt-classification-check.sh    187 LOC
  factory-halt-classification-test.sh     182 LOC
                                          369 total

  shell-loc-gate.sh:
    FAIL NEW  scripts/quality/factory-halt-classification-test.sh  cur=182 > 50
    FAIL NEW  scripts/quality/factory-halt-classification-check.sh cur=187 > 50
    RC=1

  Both are NEW (not in baseline.txt), so the gate
  cannot grandfather them.

Pre-existing residue

  MECHANICAL-BLOCKING01 closure acknowledged the
  files exceed the ratchet but did not fix them.
  Per F5 (no test weakening), simply raising the
  shell-loc-gate threshold is NOT acceptable.

============================================================
Conservation baseline (verified on merged HEAD 8f398be)
============================================================

  Track-A compiler production changes           PRESERVED
  Track-B tooling/factory production changes   PRESERVED
  Historical evidence trees (5+6 = 11 ACTs)     INTACT
  ROADMAP.md (both Track-A and Track-B entries) PRESERVED
  AGENTS.md (both contents merged cleanly)     PRESERVED
  Merge topology (2 parents, no conflict)      CORRECT

  Substantive gates on fresh build:
    llvm-byte-memory01       PASS 37/0
    llvm-intops01            PASS 4/0
    ir-return-slot-fwd01     PASS 6/0
    factory-v2-test          PASS 35/0
    factory-append-only      PASS 11/0
    factory-closure-status   PASS 6/6 PAIR_OK
    factory-halt-classification PASS 12/0
    gate-fast                PASS

  Broken gates (pre-existing Track-B residue, not
  introduced by merge):
    shell-loc-gate           FAIL RC=1 (D3)
    gate-push (install)      FAIL RC=1 (D2)

  Unbound capability (pre-existing Track-B residue,
  not introduced by merge):
    llvm-gep01-test          not exercised by gate graph (D1)

============================================================
ACT contract — file map
============================================================

  docs/acts/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01.md
    Authoritative ACT document (§0..§20).

  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c1/
    RED evidence packet — defects D1, D2, D3 frozen here.
    See c1/README.md.

  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c2/
    IMPL evidence — implementation surface, scoped diffs,
    per-AC inspection points. See c2/README.md.

  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c3/
    EVIDENCE packet — fresh-tree conservation suite,
    positive and negative controls for each AC.
    See c3/README.md.

  evidence/ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01/c4/
    CLOSE packet — final truth table, ROADMAP transition,
    push authorisation audit. See c4/README.md.
