# C2.3 — factory-halt-classification Python → PolyC migration

This directory is the C2.3 evidence packet for
`ACT-POLYC-SELFHOST-SURFACE01-CORRECTION01` (target:
`scripts/quality/factory-halt-classification.py` →
`tools/factory/factory-halt-classification.HC`).

## Layout

```
entry-identity.txt           — F1 identity captured at RED start
python-source-hash.txt       — SHA-256 of the three files in the migration scope
caller-map.tsv               — Mechanically discovered callers + argv shape
behavior-contract.txt        — Frozen Factory contract from Python source
freeze-oracle.py             — Python helper that captured raw/ from the oracle
raw/                         — Per-case stdout, stderr, rc files (Python output)
existing-fixtures-python.tsv — R1..R12 hashes
adversarial-python.tsv       — D01..D24 hashes
special-modes-python.tsv     — USAGE / MISSING_FILE / MATRIX hashes
principal-red.txt            — Binding RED (per ACT §6)
c2.3-red-result.txt          — RED phase result block

(added in later C2.3 subphases)
polyc-build.txt
polyc-selftest.txt
existing-fixtures-differential.tsv
adversarial-differential.tsv
stdout-differential.txt
stderr-differential.txt
rc-differential.txt
wrapper-audit.txt
python-deletion.txt
no-python-before-after.txt
legacy-baseline-delta.txt
factory-gates.txt
formal-dafny.txt
selfhost-conservation.txt
bootstrap-conservation.txt
shell-budget-residue.txt
scope-audit.txt
patch-hygiene.txt
c2.3-required-result.txt
```

## RED bind

The binding RED (per ACT §6) is NOT "the classifier is broken". It is:

```
FACTORY_HALT_CLASSIFICATION_LANGUAGE = PYTHON
F_NO_PYTHON_VIOLATION                = PRESENT
POLYC_EQUIVALENT                      = ABSENT
```

This directory establishes that RED mechanically.

## Migration contract

The PolyC implementation must match the Python oracle on **stdout bytes,
stderr bytes, and exit code** for every fixture in `raw/`. The Python
module is retained as the oracle through C2.3.a and C2.3.b; deletion
happens in C2.3.c only after byte/rc parity is proved.
