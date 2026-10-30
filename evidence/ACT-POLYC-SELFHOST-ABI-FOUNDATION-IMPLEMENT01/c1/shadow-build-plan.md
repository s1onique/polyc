# C1 — shadow build plan

The shadow compiler (G1) is a **complete** compiler, not a component fixture.

## 1. Isolation

```text
worktree   /tmp/abiimpl01/g1   (git worktree add --detach <ENTRY_HEAD>)
           a second detached worktree, distinct from G0's /tmp/abiimpl01/g0
build      in-tree `build/` inside the worktree, so every object path is new
prefix     build/test-prefix inside the worktree
main       NEVER touched: no tracked file outside this ACT's permitted paths
           changes, and the shadow patch is never cherry-picked.
```

## 2. Change set inside the worktree (7 files, all shadow-only)

| # | file | change | purpose |
|---|------|--------|---------|
| 1 | `src/cctrl.h` | `#include "ast.h"` -> `typedef struct Ast Ast; typedef struct AstType AstType;` | stop the transitive AST layout import |
| 2 | `src/parser.h` | `#include "ast.h"` -> `typedef struct Ast Ast;` | stop the transitive AST layout import |
| 3 | `src/ir-types.c` | add `#include "ast.h"` | the only TU that was relying on the removed transitive import; it now states its own dependency |
| 4 | `src/compile.c` | delete `#include "ast.h"`; replace the three `ast->kind` comparisons with one call to the compiled PolyC decision | the migration |
| 5 | `src/abi/cpa_host.c` (new) | the C host adapter: slot table, epoch, accessors, issue/retire | mechanical only |
| 6 | `src/abi/cpa_host.h` (new) | the C-side declarations | declarations only |
| 7 | `src/CMakeLists.txt` | add `abi/cpa_host.c` to `SOURCES`; add the PolyC subject object to the `hcc` link | link glue |

plus the **new experimental PolyC subject** compiled from
`tools/experimental/compile-print-ast-decision.HC` inside the worktree.

Nothing else is edited. In particular the nine existing PolyC subjects, their
`.HC` sources, every other `src/*.c`, and the selector set stay byte-identical —
which is what makes the shadow build a real `hcc` and not a toy.

## 3. Producer chain (identical to production, plus one subject)

```text
host cc  ->  build/host-stage0/hcc
         ->  build/bootstrap-prefix/include/tos.HH
         ->  nine parser-padding / slice subjects   (unchanged .HC sources)
         ->  NEW: build/compile-print-ast-decision-subject.o
                 produced by ./hcc (the G0 compiler) from
                 tools/experimental/compile-print-ast-decision.HC
         ->  cmake build of src/ with HCC_USE_SELFHOST_PARSER_* selectors ON
         ->  ./hcc  (G1)
```

The new subject's producer identity, target triple, flags and digests are
recorded in `c2/producer-and-linkage.tsv`. The subject is compiled by a
**digest-bound real `hcc`**, never hand-written as C.

## 4. Effective-build-graph assertions (GNU Make semantics)

`make -n` output is used only for *graph inspection*, never as a substitute for
executing the build. The following are asserted from the effective graph before
the link is trusted:

```text
G-1  CMakeLists.txt lists abi/cpa_host.c in SOURCES            (no late definition)
G-2  CMakeLists.txt adds the new subject object to the hcc link  (no stale prebuilt)
G-3  build/CMakeFiles/hcc.dir/compile.c.o exists and is NEWER than the patched
     src/compile.c                                                (no stale object)
G-4  build/CMakeFiles/hcc.dir/abi/cpa_host.c.o exists and is newer than its source
G-5  build/CMakeFiles/hcc.dir/link.txt contains
     compile.c.o, cpa_host.c.o and the subject object
G-6  nm ./hcc shows _AbiCpaShouldPrintAst as T (defined)
G-7  nm build/CMakeFiles/hcc.dir/compile.c.o shows it as U (imported)
G-8  the nine _Bootstrap* symbols are still present with unchanged identities
```

## 5. Behavioural corpus

Six real repo files plus three frozen negative/edge cases
(`c1/frozen-g0-and-witnesses.tsv`). Each is run through
`./hcc --install-dir=build/test-prefix -ast <file>` on **both** G0 and G1 and the
complete stdout, stderr, exit code and diagnostic identity are compared. The
`-ast` dump is a first-class compiler observable, not a debug printf added for
this ACT.

## 6. Two causal channels

```text
(a) POLYC-SOURCE mutation: change a PolyC constant so the decision flips for
    one kind, rebuild the subject AND relink the real shadow compiler, and
    observe the expected change in the -ast dump.  The PolyC object digest
    changes; the C objects do not.  Then restore and prove byte identity.
(b) HOST-ACCESSOR mutation: change the C accessor so it reports a wrong kind,
    leave the PolyC source untouched, rebuild the host object and relink, and
    observe the specified semantic change.  The PolyC object digest is
    unchanged.  Then restore and prove byte identity.
```

If (a) leaves the witness unchanged the verdict is
`HALT_DORMANT_DELEGATION`; if (b) does, the verdict is
`HALT_CONTROL_NOT_SENSITIVE`.

## 7. What the shadow build may NOT do

```text
- no change to the nine production subjects or their .HC sources;
- no change to src/CMakeLists.txt outside the two documented additions;
- no temporary removal of the PolyC link to "make it build";
- no use of a stale build/, test-prefix/, libtos.a or prebuilt object to
  claim a clean runtime baseline;
- no cherry-pick of the shadow patch back to main.
```
