# ACT-POLYC-FACTORY-MISSINGHO (fixture for RED-3B)

## Status

HALT_FACTORY_MISSINGHO_DEMO

## Goal

Demonstrate RED-3B: this ACT is paired with a HANDOFF that does
not exist on disk. The seed closure-status-check.sh silently
skips it via:
  [ -f "$handoff" ] || continue
Therefore the absence is invisible to the closure-status gate.
