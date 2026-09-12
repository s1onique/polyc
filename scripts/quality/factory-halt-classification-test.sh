#!/bin/sh
# scripts/quality/factory-halt-classification-test.sh
#
# ACT-POLYC-FACTORY-MECHANICAL-BLOCKING01
# ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01 D3
#
# Thin launcher that runs the 12-fixture regression matrix
# (R1..R12) implemented in factory-halt-classification.py.
# Pre-migration this script was 182 LOC of Bash holding the
# fixture bodies; that substantive logic now lives in Python so
# this shell script can stay under the <=50 LOC ratchet.

set -eu
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
exec python3 "$SCRIPT_DIR/factory-halt-classification.py" --matrix
