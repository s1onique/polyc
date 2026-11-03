# THE FROZEN SELECTED-ACTION ABI -- C1

**ACT_ID:** ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION01
**ACT_PHASE:** C1-EVIDENCE
**ABI_VERSION:** `WP001-EMISSION-ACTION-1`

This document freezes the ABI that the C2 implementation MUST conform to.
It is written BEFORE any production change, and it is bound to the entry
source by real byte digests.

---

## 1. Why a NEW export is required

The existing `WpDriverSelectedAction()` exports the **whole-argv action**
(`WP_ACTION_*`). That value CANNOT express the required decision:

| argv | `WpDriverSelectedAction()` | artifact actually produced |
|---|---|---|
| `--install-dir=X -c input.HC -o out.o` | `WP_ACTION_COMPILE_OBJECT` (1) | object |
| `--install-dir=X input.HC -o out` | `WP_ACTION_COMPILE_OBJECT` (1) | executable |

Both argv shapes select the SAME action code. The whole-argv action
therefore does not determine the artifact class, and C cannot consume it
without re-deriving the distinction from argv -- which is exactly the
policy this ACT must remove.

This is a measured property of the frozen source, not an assumption:
`WpDriverSelectAction()` (tools/bootstrap/selfhost-driver-wp001.HC:600)
returns `WP_ACTION_COMPILE_OBJECT` for `saw_output == 1` OR
`saw_source == 1`, and the `WP_KIND_EMIT_OBJ` branch only contributes
to `explicit_action` for the INFORMATIONAL actions. The `-c`/`-obj`
option therefore does NOT influence the selected action.

## 2. The frozen ABI

The driver gains ONE new export. It is a **typed scalar action**
(PATTERN 1 of the ACT's permitted patterns), not a host-owned result
cell, because the decision is a pure function of the argv and the argv
is already owned by the immutable host state.

```c
/* src/selfhost-driver-wp001.h */
extern long long WpDriverSelectedEmission(void);
```

The emission domain is DISJOINT from both the action domain and the
status domain, so an invalid emission can never collide with a valid
one:

```c
/* src/selfhost-driver-wp001.h */
#define WP_DRIVER_EMIT_UNKNOWN        0   /* no emission decided */
#define WP_DRIVER_EMIT_COMPILE_OBJECT 1   /* -c / -obj  -> an object */
#define WP_DRIVER_EMIT_EXECUTE        2   /* default   -> an executable */
#define WP_DRIVER_EMIT_ASSEMBLY       3   /* -S        -> assembly text */
#define WP_DRIVER_EMIT_DYLIB          4   /* -lib      -> a shared object */
```

## 3. The domain matrix

The contract MUST separately represent every case the ACT names. The
C1 probe (`c1/selected-action-abi-and-domain.md` section 6) measures
each row against the compiled subject.

| case | argv | expected emission | why |
|---|---|---|---|
| valid object | `-c input.HC -o out.o` | `1` COMPILE_OBJECT | the `-c` option is present |
| valid object (alias) | `-obj input.HC -o out.o` | `1` COMPILE_OBJECT | `-obj` is the same kind |
| valid executable | `input.HC -o out` | `2` EXECUTE | no emission option is present |
| valid assembly | `-S input.HC -o out.s` | `3` ASSEMBLY | the `-S` option is present |
| valid dylib | `-lib input.HC -o out.dylib` | `4` DYLIB | the `-lib` option is present |
| unknown action | `-bogus input.HC` | `2` EXECUTE | an unknown option selects no emission |
| absent request | (no argv) | `0` UNKNOWN | no argv at all |
| error | `-c` with a missing value | `0` UNKNOWN | an arity failure is not an emission |

`WP_DRIVER_EMIT_UNKNOWN` (0) is the ABSENT / ERROR sentinel. It is
DISJOINT from the valid emissions (1..4) and from the status domain
(0..5 is the STATUS domain, and the STATUS domain is never consulted
for the emission).

## 4. The mechanical C executor contract

The C side receives the emission code and performs ONLY these duties:

```text
1. read the emission code from the PolyC export;
2. translate the code into the platform command that PRODUCES that
   artifact class;
3. report a diagnostic if the code is outside the domain.
```

The C side MUST NOT:

* re-derive the emission from argv, `CliArgs.emit_object`,
  `CliArgs.assemble_only`, `CliArgs.emit_dylib`, or any default;
* keep a second copy of the option table;
* fall back to a C policy when the code is invalid.

The translation table is a MECHANICAL map from a PolyC-produced code to
a platform command. It contains no option names, no arity rules and no
argv inspection.

## 5. The G0 oracle keeps the legacy behaviour

The selector-OFF G0 oracle is built from the SAME source with
`HCC_USE_SELFHOST_DRIVER_WP001=OFF`. Under that selector the C code
that consults the PolyC export is NOT compiled, and the legacy
`args->emit_object` logic remains. This is what makes G0 a genuine
independent oracle for the ORIGINAL C-driver behaviour (AC28).

## 6. The measured C1 probe

The ABI is compiled and runtime-tested at C1 by
`tools/quality/driver-required-route-correction01-abi-probe.HC`, a PolyC
program linked against the real driver subject and the real host bridge.
The probe reads the emission code for each argv shape in the domain
matrix above and prints the observed code. The measured values are
recorded in `c1/output-request-ownership-and-lifetime.tsv`.

## 7. The forbidden shapes

* an unchecked `void *` in the transport;
* a shared mutable request cell the C side writes;
* a `longjmp` across a PolyC frame;
* an unobserved fallback when the code is invalid;
* a second C flag parser;
* converting `args->emit_object` back into a C-selected policy token.

## 8. Why the existing `WpDriverSelectedAction()` is NOT sufficient

It remains exported and it remains the whole-argv action accessor. The
C2 change adds the emission accessor beside it. The existing symbol is
NOT repurposed, because repurposing it would change the meaning of an
already-frozen ABI that other code may read, and because the whole-argv
action and the emission class are DIFFERENT decisions that happen to
coincide on one argv shape.
