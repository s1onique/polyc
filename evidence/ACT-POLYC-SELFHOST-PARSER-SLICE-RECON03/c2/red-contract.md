# Successor RED contract — ACT-POLYC-SELFHOST-PARSER-SLICE-RECON03

**Selected target:** `parseGetPriority` (`src/prslib.c:1139..1207`)
**Successor ACT:** `ACT-POLYC-SELFHOST-PARSER-SLICE03`

The successor MUST be able to reproduce each RED below against the REAL
production seam, before it changes any production source.

---

## RED-1 — Legacy semantic authority

**Claim:** the selected semantic decision still lives in C.

**Reproduction:**

```text
$ grep -n 'parseGetPriority' src/prslib.c
$ nm -u build/CMakeFiles/hcc.dir/prslib.c.o | grep Bootstrap
```

Before the successor, `src/prslib.c:1363` calls the C function and the
production object has NO undefined `BootstrapOperatorPrecedence` symbol.

**Falsifier:** if the production object already carries
`U _BootstrapOperatorPrecedence`, RED-1 does not hold.

---

## RED-2 — PolyC implementation absent

**Claim:** no PolyC component implements the selected decision yet.

**Reproduction:**

```text
$ ls tools/bootstrap/selfhost-parser-operator-precedence.HC
$ grep -rn 'BootstrapOperatorPrecedence' tools/bootstrap/
```

Before the successor, neither the component source nor the symbol
exists anywhere in the tree.

---

## RED-3 — No production delegation

**Claim:** production still executes the C semantic path.

**Reproduction:**

```text
$ nm -u build/CMakeFiles/hcc.dir/prslib.c.o | grep -c BootstrapOperatorPrecedence
0
$ grep -c 'HCC_USE_SELFHOST_PARSER_OPERATOR_PRECEDENCE' build/CMakeCache.txt
0
```

Before the successor, the delegation flag does not exist and the
production object does not reference the component.

---

## RED-4 — No qualified component evidence

**Claim:** no valid four-generation qualification exists for the new
component.

**Reproduction:** there is no
`evidence/ACT-POLYC-SELFHOST-PARSER-SLICE03/` tree with the G0/G1/G2/G3
artifact set.

---

## RED-5 — Production-causal sensitivity

**Claim:** a bounded semantic mutation of the proposed PolyC component
would be observable in the compiled program once the delegation is
enabled.

**Reproduction:** see `causal-mutation-contract.md`.  The mutation must
be syntactically valid and must LINK SUCCESSFULLY.  A failed build or a
missing output is **NOT** semantic divergence.

---

## The RED-1..RED-5 discipline

Each RED must be demonstrated BEFORE the corresponding production
change, and each must be re-checked AFTER the change to show that it no
longer holds.  A RED that cannot be reproduced is a HALT
(`HALT_RED_NOT_REPRODUCED`), not a licence to implement an imagined
fix.
