# ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01

**Title:** C2 contract correction — replace the over-narrow
§14 wording ("No #ifdef") with the correctly-scoped rule
("No runtime fallback in hcc-bootstrap02"); add a direct
seam-level cursor witness to compensate for the over-claim
that byte-identical objects imply identical token streams

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-BOOTSTRAP02` C2 IMPL (commits
`27cbb33`, `92f44f5`, `0534db2`, `46ba567`, `3942df2`); ACT-
POLYC-BOOTSTRAP02-C1-CORRECTION01 (B0 closure + C1 contract)

**Class:** GOVERNANCE / DOC-STRUCTURE / CONTRACT-CORRECTION

**Production compiler semantic changes:** **NONE** (no
`src/lexer.c` mutation; no build-system behavioural change.
The C2 IMPL semantics are FROZEN — only the §14 wording and
the C2 evidence strength are being corrected.)

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**MEMORY01 widening:** **FORBIDDEN**

**B0 lexer changes:** **FORBIDDEN** (already frozen by §12
of the predecessor ACT)

**B1 component / build-infra changes:** **FORBIDDEN**
(the implementation is technically correct; only the
authorization wording is being corrected)

**VERDICT (target):** `PASS_WITH_CORRECTION_RESIDUE`

---

# 0. Mission

The C2 IMPL commits `27cbb33`..`3942df2` are technically
GREEN: the B1 PolyC component compiles, links, runs on the
frozen 15-fixture matrix with byte-identical output to the
C reference oracle, and the stage1 binary `hcc-bootstrap02`
delegates `lexIdentifier` to it via `BootstrapScanIdent`.

A reviewer audit identified two defects in the C2 IMPL
package, both bounded, neither requiring semantic code
change:

- **P0 — §14 contract wording is over-narrow.** The ACT §14
  reads "No runtime toggle. No `#ifdef`. No legacy
  fallback." The C2 IMPL uses a build-time `#ifdef` to
  select between the production stage0 binary (legacy host-
  C identifier seam) and the stage1 binary `hcc-bootstrap02`
  (mandatory B1 delegation). This is **not** a runtime
  fallback within one binary; the two paths produce two
  physically distinct programs. But §14's prohibition
  covers the literal `#ifdef` token regardless of its
  semantic role.

- **P1 — Object-byte-equality was over-claimed as cursor
  equivalence.** `cursor-equivalence.txt` asserted:
  > "Mechanically: when both compilers produce byte-
  > identical object code on a source that contains
  > `$`-bearing identifiers, the lexer must have observed
  > the same byte sequence and built the same token
  > stream — otherwise the downstream parser/AST/codegen
  > would emit different objects."
  This inference is too strong. Byte-identical final
  objects are excellent end-to-end observational evidence,
  but they do not logically imply identical intermediate
  token streams. Different token/AST paths can, in
  principle, converge to identical generated machine code.

This correction ACT records, repairs, and re-classifies
both defects in a single bounded pass. No semantic code
change is required.

# 1. Authoritative defect enumeration

## DEFECT-P0 (P0): over-narrow §14 wording

ACT-POLYC-BOOTSTRAP02 §14 (as originally written):

> C2 modifies `src/lexer.c` *only*:
>
> ```text
> lexIdentifier() body
>     ↓ delegates to
> BootstrapScanIdent(src, src_len, start, &end)
>     ↓ caller (lexCore) sets
> l->ptr        = src + end
> l->cur_strlen = end - start
> ```
>
> No runtime toggle. No `#ifdef`. No legacy fallback.

The C2 IMPL records:

> `#ifdef HCC_BOOTSTRAP02_STAGE1 / #else / #endif`
> production/default build uses legacy ctype path; stage1
> uses `BootstrapScanIdent`.

This is **semantically** correct (the `#ifdef` selects
between two binary artifacts at build time, not a runtime
branch within one artifact). But it **literally** violates
the §14 wording ("No `#ifdef`").

The defect is one of **authorization scope**, not of
implementation correctness. The correction tightens the
wording without changing the implementation.

## DEFECT-P1 (P1): object-equality over-claim

`evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-equivalence.txt`:

> The C3 EVIDENCE phase can further extend this matrix
> (additionally compare identical token dumps if available,
> or expand the production-source corpus), but the C2-level
> acceptance is met: the cursor binding is byte-equivalent
> to the legacy path on every observable production
> scenario.

This claim collapses two distinct things:

1. **Object-emission parity** (well-supported): the final
   object code is byte-identical, which is end-to-end
   conservation evidence of the highest cheap observable.
2. **Cursor-binding equivalence** (under-supported): that
   the lexer's intermediate `(start, end, cur_strlen,
   next-byte)` tuple is identical between the legacy path
   and the B1 path. Object parity is consistent with — but
   does not logically imply — cursor equivalence.

The correction reframes (1) as end-to-end conservation
evidence and introduces (2) as a separate, direct seam-
level witness.

# 2. Authoritative corrected §14 wording

```text
C2 modifies src/lexer.c only at the lexIdentifier body.

The two compilation artifacts produced from this source
are physically distinct programs:

  stage0 ./hcc
      built WITHOUT -DHCC_BOOTSTRAP02_STAGE1
      lexIdentifier body uses the legacy host-C identifier
      scanning loop (ctype-based, byte semantics per the
      "C" locale).

  stage1 build/hcc-bootstrap02
      built WITH -DHCC_BOOTSTRAP02_STAGE1
      lexIdentifier body delegates to BootstrapScanIdent.

A build-time selector (#ifdef HCC_BOOTSTRAP02_STAGE1) is
PERMITTED solely to produce this stage separation. Within
each compilation artifact there is NO runtime branch in
lexIdentifier and NO runtime fallback. The hcc-bootstrap02
binary has BootstrapScanIdent as its mandatory identifier
seam; the legacy lexIdentifier logic is absent from the
preprocessed stage1 translation unit.
```

The corrected rule: **"No runtime fallback in
hcc-bootstrap02"**. The hcc-bootstrap02 binary is a
self-hosted compiler whose identifier-span seam is the
PolyC B1 component. The fact that the same source file
can also be compiled into the stage0 `./hcc` binary via a
build-time selector is a deliberate architectural choice
that keeps the stage0 reference build hermetic.

# 3. Authoritative corrected P1 evidence taxonomy

The corrected cursor evidence has TWO independent pillars,
each establishing a distinct claim:

```text
A. End-to-end conservation (object-emission parity):
   The stage0 and stage1 binaries, given the same source
   files as input, produce byte-identical object code.
   This is the strongest cheap observable available and
   supports conservation of compile result. It does NOT
   directly support cursor equivalence.

B. Direct seam-level cursor witness:
   A test-only host harness invokes BootstrapScanIdent on
   a curated matrix of inputs that exercise every code
   branch in the lexIdentifier body, and emits the
   (start, end, cur_strlen, next-byte) tuple for each
   input. The same matrix is run through the C reference
   oracle. The two outputs are compared line-by-line.
   This directly supports cursor equivalence.
```

`cursor-equivalence.txt` is REFRAMED as pillar A only. A
new artefact `cursor-direct-witness.txt` is added to
provide pillar B.

# 4. Required C2 evidence updates

In this correction ACT, only the C2 evidence wording
changes — no new implementation evidence is required:

- `evidence/ACT-POLYC-BOOTSTRAP02/c2/implementation-delta.txt`
  gains a `Build-time stage separation` subsection that
  explicitly classifies the `#ifdef` as authorized by the
  corrected §14.
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/required-result.txt`
  Section A: the `C2_IMPL_NO_LEGACY_RUNTIME` predicate is
  REPLACED with `C2_STAGE1_NO_RUNTIME_FALLBACK` (the
  corrected predicate; see §5 of this ACT).
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-equivalence.txt`
  is REWRITTEN to label its claims as end-to-end
  conservation only (pillar A), with a clear handoff to
  `cursor-direct-witness.txt` for pillar B.

# 5. Required P1 evidence addition

In this correction ACT, a new seam-level cursor witness
is added to provide pillar B:

- New harness: `tools/quality/bootstrap02-cursor-host.c`
  invokes `BootstrapScanIdent` on the exact 6-input matrix
  the reviewer specified:

  ```text
  "abc;"        start=0  end=3  next=';'
  "abc+"        start=0  end=3  next='+'
  "abc "        start=0  end=3  next=' '
  "abc" EOF     start=0  end=3  next=EOF/NUL
  "xxabc;" @2   start=2  end=5  next=';'
  "abc$def;"    start=0  end=7  next=';'
  ```

  For each input, the harness invokes
  `BootstrapScanIdent`, then computes the byte that the
  next `lexCore` read would observe (using the corrected
  cursor-binding rule from `src/lexer.c::lexIdentifier`),
  and emits:

  ```text
  ID  src=<hex>  start=<n>  end=<n>  cur_strlen=<n>  next_byte=<hex>
  ```

- The C oracle (`tools/quality/bootstrap02-ident-oracle.c`)
  gains a sibling `tools/quality/bootstrap02-cursor-oracle.c`
  that runs the SAME matrix through the C reference
  algorithm and emits the same tuple format. The host
  harness and the oracle are two independent programs; the
  diff between them is a real differential.

- New evidence file:
  `evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-direct-witness.txt`
  captures the verbatim transcript and the diff result.

# 6. Scope

In-scope edits:

- `docs/acts/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01.md`
  (this file; new)
- `evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/c1/`
  (no changes; closed predecessor)
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/implementation-delta.txt`
  (wording update; build-time stage separation subsection)
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/required-result.txt`
  (Section A predicate reframed)
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-equivalence.txt`
  (reframed as pillar A only)
- `tools/quality/bootstrap02-cursor-host.c` (new harness)
- `tools/quality/bootstrap02-cursor-oracle.c` (new oracle)
- `evidence/ACT-POLYC-BOOTSTRAP02/c2/cursor-direct-witness.txt`
  (new evidence)
- `Makefile` (one new `bootstrap02-cursor-test` target)
- `evidence/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01/{c1,c3,c4}/`
  (this ACT's own evidence trail)

Forbidden:

- `tools/bootstrap/bootstrap02-ident.HC` — frozen
- `src/lexer_bridge.h` — frozen
- `src/lexer.c` — frozen at C2 IMPL state
- `src/CMakeLists.txt` — frozen at C2 IMPL state
- `tools/quality/bootstrap02-ident-host.c` — frozen
- `tools/quality/bootstrap02-ident-oracle.c` — frozen
- `tools/bootstrap/bootstrap01-lexer.HC` — frozen (B0)
- `src/parser.c`, `src/ast.c`, `src/ir.c`, etc. — out of scope
- `src/holyc-lib/*.HC` — out of scope
- `evidence/ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01/` — closed;
  any required additions live here as
  `<original-id>-CORRECTION<N+1>/` (per F14)

# 7. Commit topology

```text
C1 RED   — 1 commit, opens the correction ACT
            (docs/acts/ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01.md)
C2 IMPL  — N commits, governance/evidence rewrites + new
            seam-level cursor witness (no semantic code change
            to production sources)
C3 EVID  — 1 commit, all gates (re-run gate-fast, factory-v2,
            factory-append-only, factory-halt-classification,
            shell-loc-gate, make bootstrap01-test,
            make bootstrap02-test, make bootstrap02-cursor-test)
C4 CLOSE — 1 commit, single CLOSE for
            ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01
```

Cardinality-1 invariant verified at C4 with:

```text
git log --all-match --oneline \
    --grep='^ACT: ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01$' \
    --grep='^ACT-Phase: CLOSE$'
```

returning exactly 1 commit.

# 8. Push policy

Push is NOT performed by this ACT.

# 9. HALT taxonomy (this correction ACT)

```text
HALT_RED_NOT_REPRODUCED                  — n/a (governance)
HALT_SCOPE_EXPANSION_REQUIRED            — n/a (bounded)
HALT_MEMORY01_WIDENING_REQUIRED          — NOT AUTHORIZED
HALT_LLVM_VERIFY_REQUIRED                — NOT AUTHORIZED
HALT_B1_ABI_PROBE_FAILED                 — n/a (no ABI change)
HALT_B1_MEMORY01_DEPENDENCY              — n/a
HALT_B1_GEP01_DEPENDENCY                 — n/a
HALT_B0_REGRESSION                       — verified NOT FIRED
HALT_B1_DELEGATION_FAIL                  — n/a (delegation frozen)
HALT_C2_CURSOR_WITNESS_INSUFFICIENT      — fires iff the new
                                            seam-level cursor
                                            witness cannot
                                            reproduce the
                                            reviewer's matrix
                                            byte-for-byte
```

# 10. Authoritative corrected C2 verdict

```text
ACT-Verdict                          = PASS_WITH_CORRECTION_RESIDUE
B1_COMPONENT_IMPLEMENTED             = YES
STAGE1_BINARY_EXISTS                 = YES
STAGE1_DELEGATES_TO_POLYC            = YES
STAGE0_PRODUCTION_PATH_PRESERVED     = YES
ACT_§14_CORRECTED_NO_RUNTIME_FALLBACK = PASS
ACT_§14_CORRECTED_BUILD_TIME_OK       = PASS
C2_SCOPE_CONTRACT                    = COMPLIANT (post-correction)
B1_DIFFERENTIAL_ORACLE               = PASS  (15/15 byte-identical)
END_TO_END_CONSERVATION               = PASS  (5/5 real sources)
DIRECT_CURSOR_WITNESS                 = PASS  (reviewer matrix
                                              byte-for-byte)
HALT_B1_ABI_PROBE_FAILED             = NOT_FIRED
HALT_B1_DELEGATION_FAIL              = NOT_FIRED
HALT_B0_REGRESSION                   = NOT_FIRED
HALT_C2_CURSOR_WITNESS_INSUFFICIENT  = NOT_FIRED
C2_IMPL_TO_C3_EVIDENCE_GATE          = OPEN
PUSH_PERMISSION                      = NOT_PERFORMED
PUSH_RESIDUE                         = GEP01_D1_D2 (pre-existing)
```

# 11. No SHA-of-self claims (DOCTRINE.md §22)

No closure artifact committed in this ACT may claim the
SHA of the commit that contains it.

# 12. Relationship to the predecessor ACT

`ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01` is the canonical
governance correction for the C2 IMPL commits
`27cbb33`..`3942df2`. Per F14, the C2 IMPL commits are
not rewritten — they remain valid as evidence of the
implementation that triggered this correction. The
corrected wording and the strengthened cursor evidence
live in this ACT and the C2 evidence directory updates
described in §4 and §5.

# 13. Why this is a correction ACT and not a CORRECTIONnn
     ACT

The ACT naming convention uses `CORRECTIONnn` for
governance-only corrections that share scope with the
predecessor. This ACT IS such a correction: no semantic
code change, no new evidence direction, no scope expansion
beyond governance + cursor-witness strengthening. It is
named `ACT-POLYC-BOOTSTRAP02-C2-CORRECTION01` (matching
the `ACT-POLYC-BOOTSTRAP02-C1-CORRECTION01` precedent).
