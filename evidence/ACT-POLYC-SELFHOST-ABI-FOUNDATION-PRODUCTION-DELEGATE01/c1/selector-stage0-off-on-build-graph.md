# C1 — the stage0 / C-OFF / production-ON selector and build graph

**Frozen at C1, before any implementation.** The Makefile and CMake rules
are written from this contract, and the effective dependency graph is
proven at C2/C3 by `make -n` and by the causal mutation — never by reading
`+=` text.

## 1. The selector

The selector is a **dedicated** compile-time option, independent of the
nine existing parser selectors:

```text
selector name        HCC_USE_SELFHOST_ABI_CPA
CMake option         HCC_USE_SELFHOST_ABI_CPA   (default OFF)
C preprocessor       #ifdef HCC_USE_SELFHOST_ABI_CPA
```

It is deliberately NOT folded into `HCC_USE_SELFHOST_COMPONENTS` and NOT
folded into `HCC_USE_SELFHOST_PARSER_PADDING`. Those two already carry
their own subject sets, and coupling a third authority to them would make
the nine-authority accounting ambiguous — precisely the PD-05/PD-06 trap.

## 2. The three configurations

| Configuration | Selector | Subject linked | Legacy C predicate | Who builds it |
|---------------|----------|----------------|--------------------|---------------|
| **stage0** bootstrap host compiler | `OFF` | no | **active** (the legacy C decision) | `Makefile: $(BOOTSTRAP_STAGE0_HCC)` |
| **G0** C-only production oracle | `OFF` | no | **active** | an explicit `-DHCC_USE_SELFHOST_ABI_CPA=OFF` configure |
| **production ON** `./hcc` | `ON` | **yes** | compiled out | `Makefile: $(PRODUCTION_HCC)` |

The stage0 compiler MUST keep the selector OFF: it is the legacy control
that *produces* the PolyC subjects, so linking the CPA subject into it
would create a bootstrap cycle. This is the same invariant that already
holds for `HCC_USE_SELFHOST_PARSER_PADDING` at stage0.

## 3. The subject

```text
PolyC source         tools/bootstrap/selfhost-abi-compile-print-ast.HC
subject object       build/selfhost-abi-cpa-subject.o
producer             $(BOOTSTRAP_STAGE0_HCC)  (the same digest-bound stage0
                     producer that builds the nine existing subjects)
command              $(BOOTSTRAP_STAGE0_HCC) \
                       --install-dir=$(CURDIR)/$(BOOTSTRAP_PREFIX_DIR) \
                       -c tools/bootstrap/selfhost-abi-compile-print-ast.HC \
                       -o build/selfhost-abi-cpa-subject.o
exported symbol      _AbiCpaShouldPrintAst   (T)
imported symbol      _AbiCpaAstKind          (U)
```

The subject source is the **frozen** IMPLEMENT01 shadow PolyC decision,
moved verbatim to its production-authorized path. The only permitted
deviation is a mechanical bootstrap-compatibility change that is
indispensable AND separately proven; no such change is expected, and none
is made without measurement.

The producer rule verifies, and fails closed on:

```text
- the object was actually produced by the stage0 compiler;
- the exported symbol _AbiCpaShouldPrintAst is present;
- the architecture matches the production target (arm64 here).
```

## 4. The Makefile ordering constraint (the RED-5 hazard)

GNU Make expands a rule's **prerequisite list while the makefile is read**.
A prerequisite variable defined AFTER the consuming rule is therefore
silently dropped: the dependency is not enforced and a build with a
missing input exits 0. This was reproduced with an exact detector at C0
(`c0/red-4-and-red-5.txt`, RED-5).

Therefore, in the production Makefile:

```text
the CPA_SRC / CPA_OBJ variables are DEFINED   -- before
the $(PRODUCTION_HCC) rule is READ            -- which consumes them
```

and the subject object is added to `PRODUCTION_HCC_INPUTS` **before** the
`$(PRODUCTION_HCC): $(PRODUCTION_HCC_INPUTS)` rule appears.

The C2/C3 proof is `make -n` output plus a source-mutation experiment,
not the presence of the `+=` line.

## 5. The CMake side

```text
option(HCC_USE_SELFHOST_ABI_CPA "..." OFF)

if (HCC_USE_SELFHOST_ABI_CPA)
    target_compile_definitions(hcc PRIVATE HCC_USE_SELFHOST_ABI_CPA)
    # the subject object must be schedulable, or linkable, but never absent:
    #   - ABI_CPA_PRODUCER set  -> add_custom_command schedules production
    #   - ABI_CPA_PRODUCER unset -> the object must already exist, else a
    #                              FATAL_ERROR naming the exact command
    target_link_libraries(hcc ${ABI_CPA_OBJECT})
endif()
```

The `OFF` path links nothing and compiles no PolyC subject. The `ON` path
**fails closed**: a missing subject is a hard configure error naming the
exact producer command. There is no path on which the production compiler
silently links the legacy C predicate while claiming the PolyC authority.

## 6. Exact failure conditions (frozen)

| Condition | Required behaviour |
|-----------|-------------------|
| Subject missing from `make -n` / the generated CMake link | FAIL — never a silently linked stale object |
| PolyC source mutated but the old object survives | FAIL — the source is a file prerequisite of the object, and the object is a prerequisite of the compiler |
| Hidden C decision in the ON object | FAIL — the ON object must contain neither the `0x2401` mask nor any `AST_*` comparison |
| Wrong target ABI | FAIL — the architecture check rejects the object |
| Unintended change to any of the nine subjects | FAIL — their sources, objects and symbols must be byte-identical |

## 7. Install prefix and provenance observability

Both the G0 and the production-ON compilers are built with the intended
functional install prefix (`build/test-prefix`), never against accidental
`/usr/local` state. Stage0 object provenance, the production ON flags and
the host install prefix are independently observable from:

```text
- build/CMakeCache.txt                       (the selector and the object paths)
- build/compile_commands.json                (the -DHCC_USE_SELFHOST_ABI_CPA flag)
- build/CMakeFiles/hcc.dir/link.txt          (the linked subject object)
- nm on the subject, the consumer object and the final binary
- shasum on each of those artifacts
```
