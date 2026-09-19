# ACT-POLYC-LIBTOS-SYMBOL-GAPS01

Factory-Version: 2
Lifecycle: AUTHORIZATION_ARTIFACT

**Title:** Repair canonical `libtos.a` symbol completeness for PolyC-built quality tooling and remove the emergency `all.s` supplementation path

**Repository:** PolyC
**Branch:** `main`

**Class:** COMPILER / RUNTIME / LIBTOS / SELFHOST-SUBSTRATE

**Priority:** P0

**Entry authority:**

```text
HEAD = 6e30e7f66a5516ee1af5ca9e68f9828303fc54bc

FACTORY_CLOSURE_ORACLE_LINEAGE =
TRUE_GREEN_FOR_FORWARD_USE
```

**Unblocks:**

```text
ACT-POLYC-SELFHOST-LEXER04-CORRECTION02
    ↓
ACT-POLYC-SELFHOST-SURFACE-RECON03
```

---

# 0. Mission

The current PolyC self-host toolchain can compile the LEXER04 PolyC subject, but a PolyC-built verifier cannot link cleanly against the canonical host `libtos.a`.

The mechanically observed unresolved symbol AT THIS ACT'S ENTRY is:

```text
_SpawnAndCapture
```

(Historical c2b evidence at the predecessor ACT recorded all five symbols — `_FREE, _STRNCMP, _SpawnAndCapture, _MEMSET, _STRLEN_FAST` — as unresolved. At the HEAD bound to this ACT, four of those five are present in the canonical archive. `_SpawnAndCapture` is the remaining gap. The smaller gap is exactly the kind of change ACT-POLYC-FACTORY-AGENT-CONVERGENCE01 contemplates: do not manufacture work the data no longer requires.)

Previous work used a bounded emergency supplementation path involving:

```text
src/holyc-lib/all.s
```

or a partially preserved host archive.

That workaround is not an acceptable long-term self-host substrate, AND it does not actually exist in the current tree (no `all.s` file is present; only the stale `if [ -f ./src/holyc-lib/all.s ]` branch in `Makefile:274-285`).

This ACT SHALL determine why the missing symbols are absent from the canonical archive, repair the smallest authoritative production surface, produce a **fresh canonical `libtos.a`**, and prove that representative PolyC consumers link and execute using the archive alone.

Successful terminal state:

```text
LIBTOS_FRESH_BUILD                = PASS

_FREE                             = PRESENT
_STRNCMP                          = PRESENT
_SpawnAndCapture                  = PRESENT
_MEMSET                           = PRESENT
_STRLEN_FAST                      = PRESENT

POLYC_VERIFIER_ARCHIVE_ONLY_LINK  = PASS
ALL_S_FALLBACK_REQUIRED           = NO

LEXER04_BLOCKER                   = RESOLVED
```
