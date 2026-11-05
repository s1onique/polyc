# `ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01`

**Title:** Repair the two externally-reviewed defects in the closed WP-001
driver takeover: the differential runner's Mach-O filetype mapping and the
PolyC driver's emit-LLVM conflict predicate.

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Class:** IMPLEMENTATION / CORRECTION

**Predecessor:** `ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01`
**Predecessor outcome:** `PASS_WITH_RESIDUE`, closed at `16a7fc93`.

**Factory-Version:** 2

**Production semantic changes:** **AUTHORIZED (scoped)** to exactly one
production predicate: `WpDriverEmitLlvmConflict()` in
`tools/bootstrap/selfhost-driver-wp001.HC`. The repair RESTORES the legacy
C oracle's nesting; it does not introduce a new semantic.

**Re-mutation of the predecessor's evidence directories:** **FORBIDDEN**
(F14). This ACT's evidence lives only in
`evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01/**`.

**Re-mutation of the predecessor's HANDOFF:** **FORBIDDEN** (F14). The
predecessor's HANDOFF is historical evidence of the predecessor's closure.
The findings and repairs are recorded in THIS ACT's HANDOFF and in
`docs/ROADMAP.md`.

---

## 0. Mission

An external review of the closed WP-001 tree raised two source-level
observations. Both were confirmed by measurement, and both are real
defects:

1. The differential runner's Mach-O filetype mapping was wrong, so a
   real dynamic library was reported as an executable, and the dylib case
   verified nothing at all.
2. The compiled PolyC driver's `WpDriverEmitLlvmConflict()` dropped the
   legacy C oracle's outer `--emit-llvm` guard, so the EXPORTED conflict
   status was wrong for a plain `-c` or `-S`.

This ACT repairs both, proves each repair with a real witness, and
re-measures the full conservation set.

---

## 1. Why this ACT exists

The predecessor ACT closed at `16a7fc93` with `ACT-Verdict:
PASS_WITH_RESIDUE`. Its closure record was truthful with respect to what
it measured. The external review then found two defects that the
predecessor's measurement set did not cover:

- **F1 — the Mach-O filetype mapping.** The runner read filetype `6` as
  `MH_EXECUTE` and `8` as `MH_DYLIB`. Apple's own
  `usr/include/mach-o/loader.h` in the local SDK says `MH_DYLIB 0x6` and
  `MH_BUNDLE 0x8`. A real dynamic library produced by the compiler
  therefore carried filetype bytes `06 00 00 00` and was classified as an
  EXECUTABLE. Compounding it, the frozen `D14` row expected class `NONE`
  and the dylib route writes `lib<name>.dylib` rather than `case.out.o`,
  so the runner read `NONE`, the expectation matched, and the case
  verified NOTHING.
- **F2 — the emit-LLVM conflict predicate.** The legacy C oracle tested
  the mutual-exclusion condition INSIDE an `if (args.emit_llvm)` guard.
  The PolyC driver flattened that nesting and dropped the outer guard, so
  the predicate returned 1 for a conflicting option with no LLVM request
  present at all. The host renders the conflict diagnostic only on the
  LLVM route, so the compiler's OBSERVABLE behaviour was masked; the
  EXPORTED status was nevertheless wrong, and the exported status is the
  driver's published semantic authority.

Neither finding invalidates the predecessor's core route migration: the
route decision in the compiled PolyC driver is untouched by both repairs.

The predecessor's evidence directories and HANDOFF are immutable history
(F14), and the predecessor's ACT id is closed — the Factory v2 range
validator forbids any descendant commit from carrying a closed ACT's id
(rule 6 of `scripts/quality/factory-v2-range-check.sh`). A CORRECTION ACT
is therefore the only lawful vehicle for these repairs.

---

## 2. Scope

### allowed

- `tools/bootstrap/selfhost-driver-wp001.HC` — the
  `WpDriverEmitLlvmConflict()` predicate only.
- `tools/quality/wp001-driver-takeover01-diff.HC` — the Mach-O filetype
  mapping and the dylib observation.
- `tools/quality/wp001-driver-takeover01-conflict-red.HC` — NEW: the
  compiled-PolyC RED witness for F2.
- `tests/driver-wp001/takeover/cases.tsv` — the `D14` row only.
- `Makefile` — the `wp001-takeover-conflict-red` build rule.
- `docs/ROADMAP.md` — the two findings and their repairs.
- `docs/factory/HANDOFF-ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01.md`
  — THIS ACT's HANDOFF.
- `docs/acts/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01.md` —
  THIS ACT's contract.
- `docs/factory/act-handoff-map.tsv` — THIS ACT's HANDOFF registration.
- `evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01/**` —
  THIS ACT's evidence.

### forbidden

- Any change to the route DECISION itself (`WpDriverPlanBuild`,
  `WpDriverSelectedRoute`, the C host's consumption of the plan).
- Any change to the legacy C chain retained as the selector-OFF oracle.
- Any change to the legacy C lexer.
- Any change to `src/main.c`, `src/cli.c`, or `src/selfhost-driver-wp001.h`.

---

## 3. Entry gate

```text
git branch --show-current   # main
git status --short
git rev-parse HEAD          # 16a7fc93ab36de713d090b2b97b7454247ea1157
```

Required state, recorded in
`evidence/ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01-CORRECTION01/c0/entry-identity.tsv`:

- on `main`;
- entry HEAD is the predecessor's CLOSE commit;
- the worktree carries only this ACT's authorized changes.

---

## 4. Principal RED

### F2 — the emit-LLVM conflict predicate

`tools/quality/wp001-driver-takeover01-conflict-red.HC` is a COMPILED
POLYC PROGRAM (F-POLYC-TOOLS). It links against the REAL production
driver subject, calls the REAL exported `WpDriverEmitLlvmConflict()` on
the REAL argv shapes, and compares the driver's answer against the legacy
C oracle's transcribed answer. The oracle's own answer is checked against
the case table, so the table and the transcription cannot drift apart
unnoticed.

It is a REAL-SEAM witness: it exercises the production predicate through
its published export, not a mock.

Measured against the PRE-REPAIR subject (the guard removed):

```text
CONFLICT_MISMATCH shape=plain_c         want=0 got=1
CONFLICT_MISMATCH shape=plain_S         want=0 got=1
CONFLICT_MISMATCH shape=plain_transpile want=0 got=1
CONFLICT_MISMATCH shape=plain_lsp       want=0 got=1
CONFLICT_MISMATCH shape=plain_lib       want=0 got=1
WP001_EMIT_LLVM_CONFLICT_RED=FIRED
EXIT 1
```

Measured against the REPAIRED subject:

```text
WP001_EMIT_LLVM_CONFLICT_RED=NOT_FIRED
EXIT 0
```

### F1 — the dylib route's observation

The RED for F1 is the frozen `D14` row itself: before the repair it
expected class `NONE` while observing a file the dylib route does not
write. After the repair the row expects `DYLIB` and the runner observes
`libcase.out.dylib`, the file the route actually writes. The differential
then measures the real artifact class rather than a vacuous match.

---

## 5. Implementation boundary

The repair to `WpDriverEmitLlvmConflict()` is to establish the presence of
`--emit-llvm` FIRST, and only then look for a conflicting option. The
legacy C nesting is restored; nothing else about the predicate changes.

The repair to the runner is:

- the filetype mapping becomes Apple's values: `1 → OBJECT`,
  `2 → EXEC`, `6 → DYLIB`, `8 → DYLIB`;
- the runner observes the dynamic library FIRST, because the dylib route
  does not write the object;
- the content digest is taken from whichever artifact the class was read
  from;
- the dylib is removed between runs, with the trailing space the `rm`
  command needs.

The runner's shared name buffer is resized: a `dylib_name` region and a
`slash_dylib` region are added, and every subsequent offset and
`NB_TOTAL` are recomputed. Each region's capacity is checked against the
bytes written into it.

---

## 6. Conservation

Required, on the repaired tree:

```text
CONFLICT RED          NOT_FIRED, exit 0
G0/G1 DIFFERENTIAL    CASES=30 ; DISAGREE=0 ; DIFFERENTIAL=PASS
                      D14_dylib G0=0/DYLIB G1=0/DYLIB AGREE
PARSER                376/376 over 90 blocks, MD5
                      b6f117eb1386ca80f81bc06226e2a741
LEXER07               89/89
LEXER08               45/45
LEXER09               23/23
GATE_FAST             VERDICT=PASS
GATE_PUSH             PASS
BOOTSTRAP             the stage0 compiler compiles the repaired PolyC
                      driver subject to a BYTE-IDENTICAL object
```

The G0 and G1 compilers MUST be built from the SAME working-tree state,
because `--version` embeds the build metadata. The build type MUST be the
canonical `Release` (Makefile: `BUILD_TYPE ?= Release`).

---

## 7. Residue policy

Discovered non-scope work is classified and recorded, never silently fixed
(F11). See the ACT's evidence and HANDOFF for the residue carried
forward, including the predecessor's P2 ordered-plan surface and the
pre-existing legacy-C lexer end-of-file overread found while re-measuring.

---

## 8. Halt conditions

This ACT halts on any of the closed halt list's conditions (F-CONVERGENCE).
In particular:

```text
HALT_RED_NOT_REPRODUCED
HALT_SCOPE_EXPANSION_REQUIRED
```

An acceptance or entry gate that demonstrably fails, required information
that cannot be recovered, an irreversible or separately approval-gated
action, a required external dependency that is genuinely unavailable, or
an explicit user stop request also halt the ACT.

- Any change to the predecessor's evidence directories or HANDOFF.
- Dependency addition.
- Any new shell tool implementation (F-POLYC-TOOLS: new tools SHALL be
  PolyC; shell is permitted only as ≤50 LOC bootstrap glue).
