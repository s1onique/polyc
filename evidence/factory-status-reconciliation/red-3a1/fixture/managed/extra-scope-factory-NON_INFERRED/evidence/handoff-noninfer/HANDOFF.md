HANDOFF -- ACT-POLYC-FACTORY-NONINFERRED (fixture for RED-3A1)
=============================================================

VERDICT
-------
HALT_FACTORY_NONINFERRED_DEMO

The seed closure-status-check.sh cannot discover this pair
because its act_to_evid_dir() function only handles LLVM-, IR-,
and FACTORY- prefixes and only special-cases "core" and
"boundary" tails. The pairing rule therefore yields an empty
or wrong evidence directory, and the seed's
  [ -f "$handoff" ] || continue
silently omits this pair.
