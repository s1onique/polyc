# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — C2 evidence

## C2.1.2 IMPL — second-round reviewer-driven forward fixes

Reviewer verdict (post-C2.1.1) identified two P0 false-
negative paths and three P1 tightening items. All five
fixed forward as C2.1.2 IMPL inside the same authorized
ACT.

* **P0 #1 — GitHub/GitLab workflow Python currently exempted.**
  The C2.1.1 `IsCommandSurface()` rejected all `.yml`/`.yaml`
  paths BEFORE checking `.github/workflows/` and
  `.gitlab-ci.yml`. Reordered so CI workflow YAML wins
  over the generic YAML exclusion. Added dedicated
  `InspectCIWorkflow()` scanner that detects:
    - `run:` blocks (GitHub Actions)
    - `script:` blocks (GitLab CI), including multi-line
      list form with `- ` items under `script:`
    - `shell: python*` defaults
    - `image: python*` containers
* **P0 #2 — known PolyC→Python edge still invisible.**
  C2.1.1 only detected literal first-arg
  `SpawnAndCapture("python...")` calls. The known
  variable-resolved edge in
  `tools/quality/llvm-gep01-test.HC` was invisible.
  Added bounded `KnownPolyCPythonEdges[]` inventory
  mirroring `python-callgraph.tsv` (kind=
  polyc_harness_to_python), with the single current
  entry `tools/quality/llvm-gep01-test.HC`. The
  inventory contract is now also published canonically
  at `docs/factory/PYTHON-CALLGRAPH.tsv` so that
  C2.4 (llvm-cap-table-verifier rewrite) can delete
  the entry when the edge is removed.
* **P1 #1 — `python*` shebang wildcard made explicit.**
  Was `StrNCmp(interp, "python", 6)` (would match
  `pythonista` accidentally). Now: matches if next char
  is digit, dot, or end-of-string. Selftest for
  `python3.11` (MUST flag) and `pythonista` (MUST NOT)
  added.
* **P1 #2 — `requirements*.txt` wildcard contract.**
  Was numeric-suffix only. Now also matches
  `requirements-dev.txt`, `requirements_test.txt`,
  etc. Selftest for `requirements-dev.txt` (MUST flag),
  `requirement.txt` (MUST NOT), `requirements1.txt`
  (MUST flag), `requirements.in` (MUST NOT — `.in`
  suffix is not covered by the contract).
* **P1 #3 — fail CLOSED on overlong NUL records.**
  `MAX_PATH=4096` previously silently truncated. Now
  emits `ERROR: <prefix>...  path record exceeds
  MAX_PATH=4096 (FAIL CLOSED)` and increments
  `violations`. Selftest via synthetic 5000-byte
  record in
  `evidence/factory-no-python-check-overlong-record.txt`.
## Mechanical demonstration

```
$ build/factory-no-python-check --selftest
SELFTEST=PASS       (24+ embedded assertions, all pass)
```

```
$ bash scripts/quality/factory-no-python-check.sh
POLYC_TOOLS_TRACKED_PYTHON=19
POLYC_TOOLS_TRACKED_INSPECTED=2679
POLYC_TOOLS_TRACKED_PASSES=2670
STATUS=FAIL         (correct: 9 Python source + 9 shell
                     invocations + 1 known PolyC->Python
                     edge = 19 real violations)
```

The 19 violations include the previously invisible
`tools/quality/llvm-gep01-test.HC  known PolyC -> Python
execution edge (callgraph inventory)` entry — the P0 #2
defect is now closed.

```
$ build/factory-no-python-check /tmp/long_list.bin
ERROR:  xxxx...  path record exceeds MAX_PATH=4096
        (FAIL CLOSED)
POLYC_TOOLS_TRACKED_PYTHON=1
STATUS=FAIL
rc=1
```

```
$ make selfhost-component-build COMPONENT='x;touch /tmp/sentinel_SC' STAGE=0
rc=2 sentinels=0
$ make selfhost-component-build "COMPONENT=x';touch /tmp/sentinel_Q;echo '" "STAGE=0"
rc=2 sentinels=0
$ make selfhost-component-build 'COMPONENT=x`touch /tmp/sentinel_BT`' STAGE=0
rc=2 sentinels=0
```

Make injection hardening still closed (regression check).

## Status

```
C2.1.1_MAKE_INJECTION          = PASS (regression verified)
C2.1.1_NUL_TRANSPORT           = PASS (regression verified)
C2.1.1_FALSE_POSITIVE_REPAIR   = PASS (regression verified)
C2.1.2_WORKFLOW_CLASSIFICATION = PASS (new)
C2.1.2_POLYC_DYNAMIC_EDGE      = PASS (new)

C2.2_BLOCKED                   = NO
```

**The authoritative F-NO-PYTHON checker is now sound.**
C2.2 (selfhost-component-registry PolyC rewrite) may
begin immediately under the same ACT, per the
reviewer's directive and F-CONVERGENCE.
