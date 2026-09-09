# MEMORY01 Negative Controls

The ACT §19 mandates five permanent negative controls. They prove
the gates correctly FAIL when expected.

NC1 / NC2 / NC3 / NC4 are unchanged from the original MEMORY01
closure; see the historical revision of this file for the original
prose. NC5 was hardened by ACT-POLYC-LLVM-MEMORY01-CORRECTION01
from "weak (aggregate SHAPE_DEPENDENT>=1)" to a strong, per-fixture
attribution with an independent regression probe. The NC5 section
below records the corrected form; the historical weak form is
archived as nc5-weak-historical.md in this directory.

## NC5 - counter regression (strong binding)

The MEMORY01 GREEN harness records per-fixture SHAPE_DEPENDENT
counts (one CAPABILITY_COUNTERS line is emitted on stderr per
fixture by the per-invocation totals helper). Each positive
fixture is then asserted against an expected minimum SHAPE_DEPENDENT
attribution:

```
red_pointer_param  : SHAPE_DEPENDENT == 0   (no dereference)
red_load_deref     : SHAPE_DEPENDENT >= 1   (one IR_LOAD_DEREF)
red_store_deref    : SHAPE_DEPENDENT >= 1   (one IR_STORE_DEREF)
p4_load_add        : SHAPE_DEPENDENT >= 1   (one IR_LOAD_DEREF)
p5_store_inc       : SHAPE_DEPENDENT >= 2   (load + store)
```

This uniquely attributes the SHAPE_DEPENDENT counter to the
IR_LOAD_DEREF / IR_STORE_DEREF dispatch arms. Any source
mutation that suppresses or doubles one LL_INC_SHAPE_DEPENDENT
call inside either arm trips the corresponding per-fixture
assertion.

The binding is proven empirically by
`scripts/quality/llvm-memory01-nc5-probe.sh`: the probe
snapshots `src/llvm-backend.c`, deletes the
`LL_INC_SHAPE_DEPENDENT(lc);` call inside `case IR_LOAD_DEREF: {`,
rebuilds, runs the GREEN harness, and asserts the harness FAILs
on the per-fixture `red_load_deref` NC5 assertion. The probe
restores the source on exit (via an EXIT trap that restores
BEFORE removing its temp dir, so the snapshot is always
reachable). The probe is wired into the closure gate:

```
sh scripts/quality/llvm-memory01-nc5-probe.sh
```

If the per-fixture assertion is weakened (e.g. the harness stops
checking `red_load_deref` for SHAPE_DEPENDENT >= 1), the probe
silently passes and the NC5 binding is broken: it must be loud
about that. The probe's own assertion
`grep -q 'FAIL  NC5 red_load_deref' "$PROBE_TMP/harness.out"`
guarantees the attribution is to the specific fixture that
exercises IR_LOAD_DEREF, not to any other per-fixture assertion
or aggregate counter.

Observed at IMPL run (CORRECTION01 closure):

```
=== MEMORY01 NC5 per-fixture attribution ===
PASS  NC5 red_pointer_param: shape_dependent=0 (== 0)
PASS  NC5 red_load_deref:    shape_dependent=1 (>= 1)
PASS  NC5 red_store_deref:   shape_dependent=2 (>= 1)
PASS  NC5 p4_load_add:       shape_dependent=1 (>= 1)
PASS  NC5 p5_store_inc:      shape_dependent=4 (>= 2)
PASS  NC5 per-fixture attribution: SHAPE_DEPENDENT uniquely attributable to IR_LOAD_DEREF / IR_STORE_DEREF
```

Observed probe run:

```
=== probe: source mutated (IR_LOAD_DEREF counter call removed) ===
=== probe: rebuilding hcc ===
=== probe: running harness (must FAIL on NC5 red_load_deref) ===
...
FAIL  NC5 red_load_deref: expected SHAPE_DEPENDENT >= 1, got 0

PASS probe: NC5 strong binding confirmed.
  harness rc        = 1 (expected non-zero)
  NC5 trip observed = FAIL NC5 red_load_deref
```
