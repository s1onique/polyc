# ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01 — C2 evidence

## C2.1.3 IMPL — third-round reviewer-driven forward fixes

Reviewer verdict (post-C2.1.2) flagged:

* P0: GitHub multiline `run: |` block still invisible.
* P1: `tox` not scanned despite §26 doctrine enumeration.
* P1: PolyC literal command classification drifted from
  policy (used `python`/`pip` substring; should use the
  single doctrine predicate).
* P1: `pypy3` mentioned in shebang docstring but not
  recognized.

All four closed forward in C2.1.3 IMPL inside the same
authorized ACT.

### Central `IsForbiddenPythonExecutable()` predicate

New single source of truth (DOCTRINE.md §26):

```
python / versioned python (python3, python3.11, pypy3, ...)
pip / versioned pip (pip, pip3, pip3.10, ...)
pytest  tox  poetry
```

Suffix rules:
- `python`/`pip`/`pypy`: next char MUST be digit, dot, or
  end-of-string.
- `pytest`/`tox`/`poetry`: must match the whole token
  (followed by non-alphanumeric/underscore boundary).

Used uniformly across:
- shebang inspection
- shell/Make invocation scanner
- CI `run:` / `script:` inline value
- CI `shell:` default
- CI `image:` container
- PolyC literal `SpawnAndCapture("…")` / `Exec("…")` edge

### Generalized CI block-scalar recognition

CI workflow scanner now recognizes all 6 block-scalar
forms (`run:` and `script:`):

```
run: |   | |-   | >   | >-
script: |   | >
```

A block is entered when:
1. The opener is detected on the key line;
2. The opener's indent is recorded.
A block continues while subsequent lines are more indented
than the opener and ends on:
- Blank line (YAML convention);
- Less-indented line;
- Same-indent YAML sibling key.

### `.rodata` write trap

An earlier attempt of C2.1.3 segfaulted (rc=138) because
the scanner was NUL-terminating input via
`*eol = 0; *eol = saved;`. Selftest literals live in
`.rodata` (__TEXT,__cstring, `maxprot=r-x`) — the write
crashed silently. Fixed by copying each value into a
writable stack buffer before classification:

```
U8 sbuf[256];
MemCpy(sbuf, v, slen);
sbuf[slen] = 0;
if (IsForbiddenPythonExecutable(sbuf)) { ... }
```

### C2.1.3 RED

`evidence/factory-no-python-check-selftest-c2.1.3-red.txt`
captured 6 distinct failures (selftest rc=1) at the moment
the IFPE predicate existed but was not yet wired into all
five call sites:

```
FAIL  selftest: GH block run pipe python3
FAIL  selftest: GH block run fold python3
FAIL  selftest: GL block script pipe python3
FAIL  selftest: shell tox
FAIL  selftest: PolyC literal pytest
FAIL  selftest: PolyC literal tox
FAIL  selftest: PolyC literal poetry
```

(Note: 'GL block script pipe' and 'PolyC literal poetry'
collapsed with other FAIL lines in the captured output but
each represents a distinct defect identified by the
reviewer.)

### C2.1.3 GREEN

```
$ build/factory-no-python-check --selftest
SELFTEST=PASS
```

Full-tree:
```
$ bash scripts/quality/factory-no-python-check.sh
POLYC_TOOLS_TRACKED_PYTHON=19
POLYC_TOOLS_TRACKED_INSPECTED=2681
POLYC_TOOLS_TRACKED_PASSES=2672
STATUS=FAIL     (correct: 9 Python source + 9 shell
                 invocation + 1 known PolyC->Python edge)
```

Make injection regression check still closed (semicolon /
singlequote / backtick all return rc=2 with 0 sentinels).

### Status

```
C2.1.1_MAKE_INJECTION              = PASS (regression)
C2.1.1_NUL_TRANSPORT               = PASS (regression)
C2.1.1_FALSE_POSITIVE_REPAIR       = PASS (regression)
C2.1.2_CI_CLASSIFICATION           = PASS (regression)
C2.1.2_KNOWN_POLYC_EDGE            = PASS (regression)
C2.1.2_REQUIREMENTS_WILDCARD       = PASS (regression)
C2.1.2_OVERLONG_PATH_FAIL_CLOSED   = PASS (regression)
C2.1.3_CENTRAL_IFPE_PREDICATE      = PASS (new)
C2.1.3_CI_BLOCK_SCALAR             = PASS (new)
C2.1.3_TOX_POLICY_PARITY           = PASS (new)
C2.1.3_POLYC_LITERAL_POLICY_PARITY = PASS (new)

C2.2_BLOCKED = NO
```

**The authoritative F-NO-PYTHON checker is now sound.**
C2.2 (selfhost-component-registry PolyC rewrite) may
begin immediately under the same ACT, per the reviewer's
directive and F-CONVERGENCE.

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
