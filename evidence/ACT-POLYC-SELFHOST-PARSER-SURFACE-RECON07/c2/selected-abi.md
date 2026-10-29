# SELECTED ABI

## THE ABI

```text
PolyC component : long long BootstrapDefaultArmTerminates(long long ast_kind)
Legacy C wrapper: static int parseDefaultArmTerminates(int kind)
PolyC ABI       : I64 ast_kind -> I64 terminate
```

## THE PROJECTION, EXPLICITLY

| Property | Value |
|---|---|
| Input | ONE bounded `AstKind` value (`long long`, the `stmt->kind` field) |
| Input domain | The 41 live AstKind values 256..299 (see the fixture) |
| Output | ONE bounded boolean: 1 = terminate the default arm, 0 = continue |
| Output domain | {0, 1} |
| Conditional reads | **ONE**, and it is the input itself: the decision reads `kind` and compares it against five constants. There is NO second field read, NO dereference of a host node, NO pointer traversal. |
| Sentinel / output semantics | `0` means "the default arm does NOT terminate here"; `1` means "it terminates here". There is no third value and no error return. |
| Determinism | Total: the function is a pure function of one bounded integer. |

## THE CAST CHAIN IS EXACT

```text
int (stmt->kind)  ->  long long (ast_kind)  ->  long long (terminate)  ->  int
```

The `AstKind` values are small non-negative integers (256..299) and
the result is a boolean. All of them fit in an `int` without loss, so
the widening and narrowing are exact and value-preserving. The
successor MUST assert this in its own ABI contract, exactly as
SLICE06 and SLICE07 do.

## NO HOST STATE

The component reads NOTHING except its scalar argument. It does not
read:

* the host AST node (`stmt` itself is not passed),
* the token stream,
* `cc` (the Cctrl pointer is not passed),
* any mutable map (`cc->symbol_table`, `cc->clsdefs`,
  `cc->uniondefs`),
* the recovery state,
* the allocation pool.

The `declvar->kind` hazard that SUB-003 had does NOT apply here:
SUB-002's decision reads ONE field of the statement node, and only
its `kind`.

## THE SHORT-CIRCUIT QUESTION IS MOOT

The source condition is a chain of `||` comparisons of ONE value
against constants. There is no `&&` chain and therefore no
short-circuit hazard: every comparison is against a constant, so
every comparison is evaluated, and the order of evaluation cannot
change the result. The successor MUST NOT introduce a short-circuit
whose order matters.

## THE BOUNDED-PROOF OBLIGATION

The successor MUST produce its own object-level proof that the
compiled PolyC component is exactly the five-way membership test over
the 41-row live domain, using the same bitset-decoding technique that
this ACT used (`sub base` / `cmp` / `lsl` / `tst` against a mask), and
MUST show that the mask covers EXACTLY {258, 270, 274, 280, 287}.
