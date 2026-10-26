# HANDOFF — ACT-POLYC-SELFHOST-PARSER-SLICE02-HARDEN01

**Repository:** https://github.com/s1onique/polyc

**Branch:** main

**Class:** SELFHOST / PARSER / PRODUCTION-QUALIFICATION-HARDENING

**Predecessor:** ACT-POLYC-SELFHOST-PARSER-SLICE02 (closed `PASS`)

**Successor:** ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Production semantic changes:** NONE. The production control-flow-token
decision, its ABI and the production subject are byte-identical to the
predecessor. What changed is the machinery that QUALIFIES the
production component, not the component and not the decision.

---

## 1. What this ACT did

The predecessor ACT transferred production control-flow-token authority
to a PolyC component. It did not, however, make the *qualification* of
that component incapable of accepting a false PASS. This ACT closed
three such gaps and proved the repair with executable negative controls.

The result is a production compiler whose PolyC control-flow-token
authority is unchanged, but whose build and qualification systems can
no longer accept an invalid object or an incomplete differential as
green.

## 2. The defects reproduced

All four were reproduced against the ORIGINAL SLICE02 implementation
with executable witnesses, before any production change
(`evidence/.../c0/red-reproduction.txt`).

### D1 — the symbol verifier was fail-open

`src/cmake/VerifyControlFlowTokenObject.cmake` searched the raw `nm`
output with a prefix regex against a hard-coded Mach-O spelling.

| Control | Original behaviour |
|---|---|
| object with only `U _BootstrapValidPostControlFlowToken` | **ACCEPTED** ("VERIFIED") |
| object with `T _BootstrapValidPostControlFlowTokenExtra` | **ACCEPTED** |
| object with a local `t _BootstrapValidPostControlFlowToken` | **ACCEPTED** |
| valid **ELF** object (`T BootstrapValidPostControlFlowToken`) | **REJECTED** on Linux |

The last row was reproduced **natively on Linux/ELF/x86_64**: a
perfectly valid object was rejected purely because of its platform.

### D2 — verification depended on the producer configuration

Mode B (a pre-existing object) only checked `EXISTS` at configure time.
Observed: a CMake configure with an undefined-symbol object
**succeeded**, the strict verifier was **never invoked**, and the build
failed only later at the **linker** with a generic "Undefined symbols"
error.

### D3 — the differential passed on incomplete fixtures

Its predicate was `fail == 0 && parse_errors == 0 && oracle_vs_expected_mismatch == 0`,
with no requirement on the fixture count or ID set.

| Input | Original |
|---|---|
| a one-row fixture | `TOTAL=1 PASS=1 STATUS=PASS` |
| an **empty** fixture | `TOTAL=0 STATUS=PASS` |
| the set missing F041 | `TOTAL=41 STATUS=PASS` |

### D4 — the signed integer parser overflowed

Measured against the verbatim `parse_int`: `INT64_MAX` parsed to `-1`,
`INT64_MIN` parsed to `0`, and both out-of-range magnitudes were
**accepted** rather than rejected.

## 3. The repairs

### The symbol verifier is now fail-closed

It reads the symbol table with

```text
nm --format=posix --no-weak <object>
```

Both Apple `nm` and GNU `nm` implement those two flags with the same
meaning, which is what makes the check portable. It now requires the
name to match the **target-format** spelling exactly, the record to be
a **global strong text definition**, and exactly **one** such
definition to exist.

The spelling is resolved from the target object format, which
`src/CMakeLists.txt` passes **explicitly** — it is never guessed from
the host — and the configured toolchain's `CMAKE_NM` is used.

> **`--no-weak` is load-bearing, and this was measured rather than
> assumed.** On ELF, GNU `nm` reports a weak definition as `W`. On
> Mach-O the default `nm` reports it as `T` — the *same* letter as a
> strong definition — so the type letter alone cannot reject a weak
> symbol on Mach-O. Filtering removes the ambiguity on both. A weak
> definition also **links**: it was measured satisfying a production
> reference at link time on both platforms, so accepting it would admit
> an object with no strong production authority.

Rejections carry a concrete reason token:
`REJECT_UNDEFINED_SYMBOL`, `REJECT_LOCAL_SYMBOL`,
`REJECT_SYMBOL_NAME_MISMATCH`, `REJECT_DUPLICATE_DEFINITION`,
`REJECT_INVALID_OBJECT`, `REJECT_UNSUPPORTED_OBJECT_FORMAT`,
`REJECT_NM_FAILURE`.

### Both producer modes converge on the same gate

Producer mode and prebuilt mode now route through ONE strict
verification gate that runs **before** the link.

> **The stale-stamp hazard was demonstrated concretely, not argued.** The
> pre-existing tree carried a 0-byte `*.verified` file from an earlier
> build; CMake reported "Built target hcc-control-flow-token-subject"
> **without running the verifier at all**. The verification is therefore
> a custom *target* (whose command always runs) rather than an
> OUTPUT-producing custom command (which is considered up-to-date
> whenever its file exists). The stamp is still written, but it is a
> *record* of the verification and it is **content-addressed**: it stores
> the object's SHA.

### The fixture set is now authoritative

The differential requires the exact canonical ID set `F001..F042`, each
ID exactly once, every row matching the declared 8-field schema, and
reports its own integrity ledger. A row that cannot be parsed is a
**failure**, never a silent skip.

### The integer parser no longer overflows

The magnitude is accumulated in the **negative** domain, so the only
magnitude that does not fit in a positive `I64` — `2^63`, which
`INT64_MIN` needs — is exactly representable, and the limit is checked
**before** every multiply-add.

> The magnitude is *not* accumulated in an unsigned type because that
> was measured to be unsound in this PolyC: a `U64` literal at or above
> `2^63` is parsed wrong (`9223372036854775808` evaluates to
> `7fffffffffffffff`), `U64` shift-right / divide / compare sign-extend
> at `2^63`, and `U64` multiply-add wrap in the signed domain.

The integer-boundary qualification tool is **assembled** from the
`parse_int` function mechanically **extracted** from the differential
source, so the function under test and the function under qualification
cannot drift apart.

## 4. The negative controls executed

| Control | Expected | Observed |
|---|---|---|
| NC-O1 undefined symbol | REJECT | `REJECT_UNDEFINED_SYMBOL` (Darwin + Linux) |
| NC-O2 near match | REJECT | `REJECT_SYMBOL_NAME_MISMATCH` (Darwin + Linux) |
| NC-O3 local symbol | REJECT | `REJECT_LOCAL_SYMBOL` (Darwin + Linux) |
| NC-O4 weak definition | REJECT | `REJECT_SYMBOL_NAME_MISMATCH` (Darwin + Linux) |
| NC-O5 duplicate definition | REJECT | defensive check (the linker refuses duplicate globals) |
| NC-O6 empty object | REJECT | `REJECT_INVALID_OBJECT` (Darwin + Linux) |
| NC-O7 invalid object | REJECT | `REJECT_INVALID_OBJECT` (Darwin + Linux) |
| NC-O8 no such symbol | REJECT | `REJECT_SYMBOL_NAME_MISMATCH` |
| NC-O9 missing object | REJECT | `REJECT_INVALID_OBJECT` (Darwin + Linux) |
| NC-O10 valid ELF object | ACCEPT | `STATUS=PASS`, count=1 (Linux) |
| NC-O11 valid Mach-O object | ACCEPT | `STATUS=PASS`, count=1 (Darwin) |
| NC-D1 remove F041 | FAIL | `FIXTURE_ID_SET_INCOMPLETE` |
| NC-D2 remove F007 | FAIL | `FIXTURE_ID_SET_INCOMPLETE` |
| NC-D3 duplicate F041, omit F042 | FAIL | `FIXTURE_ID_SET_INCOMPLETE` |
| NC-D4 F041 → F043 | FAIL | `FIXTURE_ID_SET_INCOMPLETE` |
| NC-D5 empty fixture | FAIL | `FIXTURE_SET_EMPTY` |
| NC-D6b trailing garbage `12abc` | FAIL | `FIXTURE_COUNT_MISMATCH` |
| NC-D7 truncated row | FAIL | `FIXTURE_ID_SET_INCOMPLETE` |
| NC-D8 shuffled valid matrix | PASS | PASS (order independence) |
| NC-D9 predecessor matrix | FAIL | `ORACLE_VS_EXPECTED_MISMATCH` |
| NC-D10 / M1..M4 subject mutation | FAIL | `SUBJECT_VS_ORACLE_MISMATCH` (4/4) |

The **positive** controls also hold: the corrected 42-row matrix is
42/42 with 0 parse errors, and the valid object is accepted on both
platforms.

## 5. Platform coverage actually achieved

| Predicate | Darwin / macOS / arm64 / Mach-O | Linux / Ubuntu 24.04 / x86_64 / ELF |
|---|---|---|
| actual object format | MEASURED | MEASURED |
| target-specific symbol spelling | MEASURED | MEASURED |
| global text definition | MEASURED | MEASURED |
| undefined symbol rejection | MEASURED | MEASURED |
| local symbol rejection | MEASURED | MEASURED |
| weak symbol rejection | MEASURED | MEASURED |
| near-match rejection | MEASURED | MEASURED |
| empty / invalid / missing rejection | MEASURED | MEASURED |
| valid object accepted | MEASURED | MEASURED |
| prebuilt-mode verification | MEASURED | MEASURED |
| producer-mode verification | MEASURED | MEASURED |
| valid production link | MEASURED (full `hcc`) | MEASURED (real ELF link; the program runs and returns the correct result) |

The Linux runner is an **existing** ssh runner (`192.168.244.202`); no
container runtime, CI service or infrastructure dependency was
introduced by this ACT.

> **One Linux limitation is recorded honestly rather than papered over.**
> The **full** PolyC compiler cannot be built on Linux, because the
> project itself refuses it at `src/CMakeLists.txt:1117`
> ("Tooling runtime host is macOS-only in this build. Linux support is
> ACT-POLYC-TOOLING-LINUX-PORT01."). That gate is pre-existing and
> deliberate — it is designed to fail rather than silently produce a
> forged-Apple `libtos`. The layer this ACT hardens — the object
> verification — depends only on `cmake`, `nm` and the object file, and
> is therefore fully qualified natively on Linux. **No Linux
> qualification is claimed for the full compiler build.**

## 6. Conservation

| Item | Entry | After hardening | Delta |
|---|---|---|---|
| Parser assertions | 363 | 363 | 0 |
| Parser assertions passed | 350 | 350 | 0 |
| Parser assertions failed | 13 | 13 | 0 |
| Parser compile failures | 0 | 0 | 0 |
| Parser run failures | 0 | 0 | 0 |
| Test files exercised | 67 | 67 | 0 |
| Padding differential | 16640/16640 | 16640/16640 | 0 |
| Legacy oracle cross-check | 326/326 | 326/326 | 0 |
| LSP suite | 43/43 | 43/43 | 0 |

The 13 parser failures are **all** the same pre-existing
`/usr/local/include/tos.HH` install-prefix limitation, in three test
files (`39_arg_count.HC`, `60_link.HC`, `64_sret_x8.HC`) that shell out
to the compiler without `--install-dir`. It is proven six ways,
including a direct reproduction with no harness involved and a clean
compile when the prefix *is* supplied. `src/tests/` is out of scope for
this ACT and was not modified.

| Item | Value |
|---|---|
| Production subject SHA256 | `77199636db559024365fffc168cd191c1281593452682aab80005151e6baf196` — **identical to the C0 freeze** |
| Frozen ABI | `I64 BootstrapValidPostControlFlowToken(I64 present, I64 kind, I64 value) -> I64` — unchanged |
| Frozen surfaces | all 7 byte-identical |
| `CONTROL_FLOW_TOKEN_PRODUCTION_AUTHORITY` | `POLYC` |
| `LEGACY_C_PRODUCTION_AUTHORITY` | `RETIRED` |
| `PRODUCTION_SEMANTIC_DELTA` | `0` |

The causal control was reproduced in an isolated scratch tree: a valid,
linkable mutant with a different SHA changes the **production
diagnostic** on the same fixture, and restoring the pristine subject
restores the production behaviour.

## 7. The gates

| Gate | Result |
|---|---|
| `make gate-fast` | PASS (RC=0) |
| `make gate-push` | PASS (RC=0; build/install/gep01/aot/jit/lsp all PASS) |
| `factory-v2-test.sh` | PASS (53/53) |
| `factory-append-only-test.sh` | PASS (11/11) |
| `git diff --check` over the committed range | PASS (0 errors) |
| F-NO-PYTHON | 12 **pre-existing** violations, **0 new** |
| F-POLYC-TOOLS | checker not yet landed (C2.9); **0 new**, checked directly |

## 8. Remaining independent defects (residue)

| # | Class | Defect | Why not fixed here |
|---|---|---|---|
| 1 | P1 | The stage-0 compiler cannot write to an **absolute** `-o` path (it prefixes the path with its own `./`). | Pre-existing — reproduced against the **original** SLICE02 `CMakeLists.txt` too. It affects the producer path only; the real production build path (the Makefile) builds the subject itself and hands CMake a prebuilt object. Fixing the compiler is outside this ACT's scope. |
| 2 | P1 | The **full** PolyC compiler cannot be built on Linux (`src/CMakeLists.txt:1117`). | Pre-existing and deliberate; Linux support is the open `ACT-POLYC-TOOLING-LINUX-PORT01`. The object-verification layer this ACT hardens **is** qualified natively on Linux. |
| 3 | P2 | The `F-POLYC-TOOLS` checker is still not landed. | Pre-existing (`C2.9`). This ACT's files comply directly: the new substantive qualification logic is PolyC, the new build logic is CMake, and no new shell or Python was added. |
| 4 | P2 | 13 parser assertions fail on the host install prefix. | Pre-existing; `src/tests/` is explicitly out of scope for this ACT. |

None of these is a consequence of this ACT, and none was silently
fixed.

## 9. Successor

```text
NEXT_ACT_ID=ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

NEXT_MISSION=
  Refresh remaining legacy-C parser semantic authorities,
  remove the newly migrated control-flow-token slice from
  the eligible candidate pool, recompute dependency-boundary
  rankings, and select the next production-authoritative
  self-hosting migration.
```

RECON03 was **not** opened by this ACT and its winner was **not**
preselected here. It must use the actual new parser authority state,
not historical assumptions.

## 10. Verdict

VERDICT

---

PASS
