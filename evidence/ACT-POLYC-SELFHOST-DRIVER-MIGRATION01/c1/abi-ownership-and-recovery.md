# The WP-001 driver ABI — ownership, lifetime, domain and recovery

**ACT:** ACT-POLYC-SELFHOST-DRIVER-MIGRATION01, phase C1 EVIDENCE
**Status:** FROZEN. This document is the binding ABI contract for C2.
**Proven by:** `c1/host-abi-prototype-experiment.tsv` — a prototype compiled
by the real production compiler, linked with a C host, and executed over
positive and adverse cases.

---

## 1. The seam

The seam is deliberately as small as the compiler permits. It carries
**no raw `argv`, no `void *`, and no struct layout assumption**.

### 1.1 The host provides (C, mechanical, three functions)

```c
long     WpDriverHostArgc(void);              /* the argument count          */
long     WpDriverHostArgLen(long idx);        /* the byte length of arg idx   */
unsigned char *WpDriverHostArgByte(long idx); /* the first byte of arg idx    */
```

These are **byte accessors**. They copy nothing, allocate nothing and
own nothing. They are exactly the class of duty the frozen contract
allows the C side to keep: *"safe argument byte access/copying"*.

### 1.2 The PolyC side owns (every decision)

| PolyC export | Owns |
|---|---|
| `WpDriverClassifyOption(long argIdx)` | option-name matching against the PolyC-owned option table |
| `WpDriverValueArgIndex(long argIdx)` | the option's value index, **domain-checked** |
| `WpDriverSelectAction(void)` | the compile-versus-other action choice |
| `WpDriverMapStatus(long action)` | the failure/exit-status mapping |

The option table itself (names, arity, kind) is **PolyC data**, declared
in the PolyC subject. The C side holds no option table, no switch on an
option enum, and no second copy of the CLI policy.

---

## 2. Ownership and lifetime matrix

| Item | Owner | Lifetime | Rule |
|---|---|---|---|
| `argv` array | C host (the OS) | the whole process | **never crosses the seam** |
| each argument's bytes | C host (the OS) | the whole process | **borrowed**, never copied, never freed by PolyC |
| the argument count | C host | the whole process | read-only after `main` |
| the option table | **PolyC** | the whole process | static PolyC data |
| the action decision | **PolyC** | the whole process | a scalar |
| the status decision | **PolyC** | the whole process | a scalar |
| the compile request | **PolyC** (formed) / C (consumed) | one call | the C side consumes it and never mutates it |
| the compiled object | the C compile engine | the process | unchanged ownership |

**The lifetime rule.** The host writes `g_argc`/`g_argv` exactly once, in
`main`, before the first PolyC call, and never mutates them afterwards.
Every borrowed byte pointer therefore stays valid for the whole
decision. There is **no global mutable argv decoder**, so there is no
stale state to reuse between calls.

**Reentrancy.** Not assumed safe and not claimed safe. The prototype's
host state is set once and is immutable thereafter, so a second call with
the same argv is well defined, but the contract makes no promise about
concurrent use and the C2 bridge will not introduce any.

---

## 3. The domain column

Every ABI operation has an explicit domain. A domain failure is a
**distinct, named status**, never a silent zero and never a
zero-value-collision.

| Operation | Domain | Absent | Invalid | Empty | Valid |
|---|---|---|---|---|---|
| `WpDriverHostArgc` | always in range | n/a | n/a | n/a | n/a |
| `WpDriverHostArgLen(idx)` | `0 <= idx < argc` | out of range | out of range | length 0 is legal | in range |
| `WpDriverHostArgByte(idx)` | `0 <= idx < argc` | out of range | out of range | a legal empty string | in range |
| `WpDriverClassifyOption(idx)` | `0 <= idx < argc` | returns `-1` | returns `-1` | returns `-1` | returns the option index |
| `WpDriverValueArgIndex(idx)` | `0 <= idx < argc` **and** the value must be present | returns `-1` | returns `-1` | returns `-1` | returns the value index |
| `WpDriverSelectAction` | whole argv | `WP_ACTION_ERROR` | `WP_ACTION_ERROR` | `WP_ACTION_ERROR` | an action |
| `WpDriverMapStatus` | a known action | `WP_STATUS_OK` | `WP_STATUS_OK` | `WP_STATUS_OK` | a status |

**The zero-value-collision rule.** A legitimate *action* and a
*legitimate result* may both be zero. The status domain is therefore
**disjoint from the action domain**: actions are `>= 1`, and the failure
statuses are `>= 1`, while `0` is reserved for "no error, nothing to do".
The driver never encodes a failure as `0`.

### 3.1 The domain check is load-bearing — proven by execution

The **first** prototype returned `valueidx = 2` for the invocation `-o`
alone. `argv` has only two entries there (`argv[0]` is the program name
and `argv[1]` is `-o`), so index `2` is **out of range**. The frozen
contract requires a *missing* value to be rejected, so the value
accessor re-checks the arity and returns `-1`. The second prototype
returns `-1` and the action decision is unchanged.

This defect was found **by running the prototype**, not by reading it.
It is the concrete reason the contract carries an explicit domain column
rather than an informal "be careful" note.

---

## 4. Recovery

**No `longjmp` crosses a PolyC frame.** The C side uses ordinary
returns. The PolyC side returns a status; it never unwinds.

The C compile engine keeps its own existing error handling, including
`loggerPanic`, which terminates the process. That is unchanged
`C_SEMANTIC_ENGINE_RETAINED` behaviour, and it happens **after** the
PolyC driver has already returned its status. The PolyC driver therefore
never observes, and never has to recover from, an engine abort.

The one recovery-shaped decision the driver owns is the **status
mapping**: an engine failure, an argument-arity failure and an
unknown-option failure must map to *distinguishable* statuses. The
frozen status domain is:

```text
WP_STATUS_OK       0   success / nothing to do
WP_STATUS_USAGE    1   usage error (unknown option, missing value)
WP_STATUS_COMPILE  2   a compile action was selected
WP_STATUS_ARITY    3   an argument arity/domain violation
WP_STATUS_ENGINE   4   the compile engine reported failure
```

`WP_STATUS_ENGINE` is assigned by the C side **from the engine's own
return code**, after the driver has selected the action. It does not
overturn a PolyC decision; it reports the engine's outcome.

---

## 5. What the C side must NOT do

The frozen contract is explicit, and the C2 review will check each item:

1. **No C option table.** The option names, arities and kinds live in
   the PolyC subject.
2. **No C switch on an option enum** that reproduces the option
   dispatch. A C `switch` over the driver's decision codes would be a
   second CLI policy, which the ACT forbids.
3. **No C flag parsing.** The C side must not test `argv[i][0] == '-'`.
4. **No C fallback.** If the PolyC subject is absent, the build must
   FAIL, never fall back to the C driver.
5. **No hidden default.** The production default is the PolyC driver;
   the C-only oracle is selector-OFF and is a *separate executable*, not
   a runtime branch.

## 6. The three load-bearing sites

The ACT requires three physically distinct, independently mutable
decision sites. The live C source shows them separable, so no alternative
grouping is needed:

| Site | PolyC function | Decision | Observable channel |
|---|---|---|---|
| (a) flag / arity classification | `WpDriverClassifyOption` + `WpDriverValueArgIndex` | which argument is an option, and whether its value is present | the option-index and value-index results; the arity status |
| (b) compile-action dispatch | `WpDriverSelectAction` | compile-to-object versus another action versus an error | the action code |
| (c) status / error mapping | `WpDriverMapStatus` | the status a decision maps to | the status code, and the process exit status |

They are separate functions, they read different inputs, and each can be
mutated on its own without touching the other two. C3 will prove this
with three physically independent single-rule mutations.
