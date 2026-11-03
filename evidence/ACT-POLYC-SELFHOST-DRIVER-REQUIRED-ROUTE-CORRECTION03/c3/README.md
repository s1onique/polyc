# CORRECTION03 C3 locally executable evidence

The fresh OFF/ON production matrix, direct PolyC ABI probe, required-route
regression, precedence/fail-closed regression, gate-fast, and gate-push all
pass.

The PolyC causal mutation changes `-c -S` from a Mach-O object to assembly
text with exit 0. The legacy C mutation changes the OFF oracle to assembly
text while the ON compiler remains a Mach-O object, proving the legacy C
policy is dormant on the ON route.

The independent Codex review required by AC11 has not run: no `codex`
executable or review harness is available in this environment. Therefore C4
is not authorized and no CLOSE/PASS verdict is claimed by this evidence.
