# ACT-POLYC-FACTORY-NO-SHA-OF-SELF01

**Title:** Codify the no SHA-of-self doctrine and surface it as F-GIT-IDENTITY in DOCTRINE.md §22

**Repository:** `https://github.com/s1onique/polyc`

**Branch:** `main`

**Predecessor:** `ACT-POLYC-FACTORY-GIT-METADATA-SIMPLIFY01` (PASS)

**Class:** DOCUMENTATION / AGENT-OPERABILITY

**Production compiler semantic changes:** **FORBIDDEN**

**IR/ABI repair authorization:** **NONE**

**LLVM authorization:** **NONE**

**Language-change authorization:** **NONE**

**VERDICT:** `PASS`

---

# 0. Mission

Bind the no SHA-of-self doctrine as Factory operating law.
Surfaces it as a new section (§22, F-GIT-IDENTITY) in
`docs/factory/DOCTRINE.md`, with explicit:

- the prohibition pattern (any `<LABEL>=<40-hex>` claiming
  the containing commit's SHA);
- the stable identity pattern closure artifacts bind to
  (ACT id, phase, verdict, predecessor, repository state,
  ancestry checks, measured outputs);
- the strict F14 reading for corrections (no appending
  "ADDENDUM" to historical evidence files);
- the hygiene arithmetic convention (three counts: baseline
  F14, P2 residue, newly introduced; never a single total);
- the violation discovery and repair procedure (new
  bounded correction ACT; never amend).

Adds a pointer in `AGENTS.md` so the doctrine is surfaced
to every agent that reads the agent contract.

---

# 1. Why this ACT exists

The reviewer audit on `ACT-POLYC-TOOLING-RUNTIME01-CORRECTION05`
identified three defects:

1. **P0 build-integrity** (stale-producer false GREEN) —
   fixed in CORRECTION05 itself.
2. **P0 evidence-contract** — CORRECTION04 had mutated
   three `correction03/*` evidence files (F14 violation).
3. **Evidence truth** — "0 C03-introduced" was arithmetic
   fiction; correct is "3 introduced, 2 remediated, 1 P2".

The reviewer also surfaced a doctrinal point the Factory had
implicitly relied on but never explicitly named: **closure
artifacts must not contain SHA-of-self claims**. Git's
content-addressed object model makes self-referential SHAs
inside a commit structurally impossible — the SHA depends on
the tree, the tree depends on the file content, the content
depends on the SHA.

This ACT names the doctrine explicitly so future agents and
reviewers can enforce it.

---

# 2. Scope

In scope:

- New `docs/factory/DOCTRINE.md` §22 (F-GIT-IDENTITY)
- New "No SHA-of-self claims" section in `AGENTS.md`
  pointing at §22

Out of scope:

- Retroactive repair of historical ACT docs that contain
  SHA-of-self claims. They are F14-protected historical
  evidence. A separate bounded correction ACT MAY address
  them; this ACT does not.
- Retroactive repair of the CORRECTION05 closure-summary
  violation. See ACT-POLYC-TOOLING-RUNTIME01-CORRECTION06
  for that bounded repair.

---

# 3. Acceptance criteria

AC01. `docs/factory/DOCTRINE.md` contains a new §22 with
      heading "No SHA-of-self claims (F-GIT-IDENTITY)".

AC02. §22 explicitly forbids `HEAD=<self>`, `FINAL_HEAD=<self>`,
      `C<N>_COMMIT=<self>`, `ENTRY_HEAD=<self>`, `RED_HEAD=<self>`,
      `IMPLEMENTATION_HEAD=<self>`, `DOCS_HEAD=<self>`,
      `CLOSURE_HEAD=<self>`, and any pattern of the form
      `<LABEL>=<40-hex>` where the label is self-referential.

AC03. §22 enumerates the stable, mechanically inspectable
      facts closure artifacts bind to: ACT id, phase, verdict,
      predecessor link, repository state, ancestry checks,
      measured outputs.

AC04. §22 codifies the strict F14 reading for corrections:
      historical evidence packet is immutable; corrections
      live in new `<original-id>-CORRECTION<N+1>/` directories.

AC05. §22 codifies the hygiene arithmetic convention: three
      counts (baseline F14, P2 residue, newly introduced),
      not a single total.

AC06. `AGENTS.md` contains a new "No SHA-of-self claims"
      section with a pointer to `docs/factory/DOCTRINE.md`
      §22.

AC07. `git diff --check` on the closing commit is clean
      (no new hygiene findings).

AC08. Working tree is clean after the closing commit.

---

# 4. HALT conditions

HALT_SCOPE_EXPANSION_REQUIRED — if a needed change is
discovered outside this scope (e.g. a docs/ rework is
required beyond the §22 and AGENTS.md pointer additions).

---

# 5. Execution metadata

This ACT requires 1 commit: the closing commit containing
both DOCTRINE.md and AGENTS.md additions.

The closing commit will carry trailers:

```text
ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01
ACT-Phase: CLOSE
ACT-Verdict: PASS
```

The closing commit's SHA is NOT pinned inside this ACT
document. Query it with:

```sh
git log --all-match \
        --grep='^ACT: ACT-POLYC-FACTORY-NO-SHA-OF-SELF01$' \
        --grep='^ACT-Phase: CLOSE$' --pretty=format:'%H'
```

This is exactly the doctrine this ACT codifies.
