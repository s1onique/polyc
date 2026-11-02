# The comparator contract and the twelve ordered generation pairs

**ACT:** ACT-POLYC-SELFHOST-DRIVER-MIGRATION01, phase C1 EVIDENCE
**Status:** FROZEN. This document binds the C3 generation matrix and
the C3 comparator. Nothing in it may be relaxed to obtain a PASS.

## 1. The comparator

The comparator compares TWO REAL PROCESS RUNS of a real compiler
binary over a frozen case argv. It never compares a script's expected
text against a script's actual text, and it never compares a stored
blob against a stored blob.

For each case it records:

| field | meaning |
|---|---|
| `exit_status` | the process exit status, compared as an integer |
| `stdout_sha256` | the SHA-256 of the whole stdout stream |
| `stderr_sha256` | the SHA-256 of the whole stderr stream |
| `stdout_bytes` | the byte length of stdout |
| `stderr_bytes` | the byte length of stderr |

A case is `MATCH` when **all four** fields are equal. A case is
`DIFF` when any one of them differs. There is no partial credit and
no "significant-substring" comparison.

### 1.1 The one predeclared normalization

`ENVIRONMENT_EXPLAINED` applies to **exactly one** field of
**exactly one** case: the `commit-hash:` line of `C02_version`.

The `commit-hash:` line reports the Git commit the binary was built
from. The G0 oracle is built from the pinned entry commit
`2288a80330b9907341cd8a7d62d33cbfe9da5452`; the migrated binary is
built from a working tree that contains this ACT's own changes, so
its commit hash necessarily differs. The field is an artifact of the
BUILD ENVIRONMENT, not of the compiler's behaviour.

The normalization is: when comparing `C02_version` stdout, the
`commit-hash:` line is dropped from **both** sides before hashing.
Every other line of that stdout, and the whole of every other case,
is compared byte for byte.

This normalization is PREDECLARED here, at C1, BEFORE the C2
production edits and before the C3 matrix. It was not introduced
after seeing a diff.

### 1.2 What is NEVER normalized away

The comparator must NOT normalize away any of:

- a semantically meaningful stderr message;
- an exit status, in any case, including the `1` that both a
  no-input failure and an unknown-option failure return;
- a CLI side effect (a produced object file, a produced executable);
- an emitted target instruction;
- an object section.

### 1.3 The comparator's proven sensitivity

AC23 requires the comparator to be PROVEN CAPABLE of detecting a
representative divergence. The C3 phase must therefore demonstrate,
by EXECUTION, that:

1. a deliberately altered exit status is detected;
2. a deliberately altered stderr byte is detected;
3. a deliberately altered stdout byte is detected;
4. a deliberately removed produced object is detected.

The proof is by mutation of a REAL run, not by assertion. The
negative control NC20 covers the converse: a comparator that ignores
a changed exit, stderr, output or object semantic must be REJECTED.

## 2. The twelve ordered pairs

The predecessor rules distinguish an OBJECT-side comparison from a
SEMANTIC-STREAM comparison. Both are enumerated, separately, over the
same twelve ORDERED pairs.

### 2.1 The generations

| id | what it is | producer |
|---|---|---|
| G0 | the pure C-driver oracle | built from the pinned entry commit, selector OFF |
| G1 | the PolyC driver compiled by the existing C-rooted stage0 | `build/host-stage0/hcc` |
| G2 | the same PolyC source compiled by the current `./hcc` | `./hcc` |
| G3 | the same PolyC source compiled by an independently built qualified bootstrap generation | `build/runtime-producer/hcc-bootstrap04` |

The three producers are distinct executables by content SHA-256, and
none is a `PRODUCER_ALIAS` of another.

### 2.2 The twelve ORDERED pairs

Ordered means `G_a` against `G_b` is a DIFFERENT comparison from
`G_b` against `G_a`. All twelve are enumerated:

| # | ordered pair |
|---|---|
| 1 | G0 vs G1 |
| 2 | G1 vs G0 |
| 3 | G0 vs G2 |
| 4 | G2 vs G0 |
| 5 | G0 vs G3 |
| 6 | G3 vs G0 |
| 7 | G1 vs G2 |
| 8 | G2 vs G1 |
| 9 | G1 vs G3 |
| 10 | G3 vs G1 |
| 11 | G2 vs G3 |
| 12 | G3 vs G2 |

### 2.3 The two separate rosters

**Roster A -- OBJECT-side identity.** For each ordered pair, the
driver subject object of the left generation and of the right
generation are compared byte for byte.

- Between G1, G2 and G3 the comparison is meaningful: the same
  PolyC source is compiled, so object identity is EXPECTED when the
  target flags, the source bytes and the deterministic compiler
  settings match, and the C3 phase MUST report the measured result
  rather than assume it.
- Between G0 and any PolyC generation the comparison is NOT expected
  to hold, because G0 has no PolyC driver subject at all. G0's
  executable carries ZERO `_WpDriver` symbols. The comparison is
  reported as `NOT_APPLICABLE_NO_POLYC_SUBJECT`, never as a FAIL.

**Roster B -- SEMANTIC-STREAM equivalence.** For each ordered pair,
the frozen CLI corpus is executed against the left binary and the
right binary and the four comparator fields are compared, under the
one predeclared `ENVIRONMENT_EXPLAINED` normalization of section 1.1.

The G0-vs-G1/G2/G3 pairs are expected to be `MATCH` on all fourteen
cases once the `C02_version` normalization is applied, and a DIFF on
any other case is a FAIL of the migration, not an accepted variance.

### 2.4 The two rosters are not conflated

A pair that is `MATCH` in Roster B and `DIFFERENT` in Roster A is
reported as BOTH facts, separately. The two rosters answer different
questions:

- Roster A answers: *did the same compiler generation produce the
  same bytes?*
- Roster B answers: *did the two binaries behave identically on the
  frozen corpus?*

Conflating them -- for example, treating a byte difference between
G1 and G3 as a behavioural difference -- is a reporting error, and
NC20 guards the semantic-stream roster against becoming insensitive.

## 3. The C-dormancy mutants

The three DORMANT rows (`cliParseAssign`, `cliParseInt`,
`cliParseBoolean`) must be proven to STAY dormant: mutating their
bodies must produce NO observable change in any case of the frozen
corpus. A dormant mutant that changes an observable is a FAIL,
because it would mean the row was not actually dormant.

## 4. The three PolyC mutation targets

The three distinct PolyC mutation targets are frozen in
`c1/decision-authority-and-mutation-contract.tsv`, Part 2:

| id | group | PolyC function |
|---|---|---|
| M1_FLAG_ARITY | flag/arity classification | `WpDriverOptMatches` |
| M2_ACTION_DISPATCH | compile-action dispatch | `WpDriverSelectAction` |
| M3_STATUS_PROPAGATION | status/error propagation | `WpDriverMapStatus` |

Each must produce a DIFFERENT observable effect, and the three
effects must be distinguishable from each other. A mutation that
produces no observable change is a FAIL: it would mean the site is
decorative rather than load-bearing.
