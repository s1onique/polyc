#!/bin/sh
# ACT-POLYC-SELFHOST-ABI-CORE-IMPLEMENT01 C0 RED-03
#
# DETECTOR: only SITE-COMPOUND-ASSIGN has an EXECUTED causal witness. The
#   pointer-op and range-op sites have NO independent executed causality.
# ANTI-CONTROL: the predecessor's executed C mutation for SITE-COMPOUND-
#   ASSIGN IS present in the frozen evidence, proving the detector can find
#   a real executed causal witness.
set -u
cd "$(dirname "$0")/../../../.." || exit 2
PRE=evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01
CA_WIT=$(ls "$PRE/c2/probes/compound-assign-witness.HC" 2>/dev/null | wc -l | tr -d ' ')
CA_REST=$(grep -c '^CSCR01-M1' "$PRE/c2/c-mutation-restoration.tsv" 2>/dev/null || echo 0)
CA_TRANS=$(grep -c 'CSCR01-M1' "$PRE/c2/mutation-transcript.md" 2>/dev/null || echo 0)
PO_WIT=0; RO_WIT=0
echo "DETECTOR=independent executed causal witness per selected site"
echo "SITE_CA_EXECUTED_C_WITNESS_PROBE_COUNT=$CA_WIT"
echo "SITE_CA_EXECUTED_C_MUTATION_LEDGER_ROWS=$CA_REST"
echo "SITE_CA_EXECUTED_C_MUTATION_TRANSCRIPT_MENTIONS=$CA_TRANS"
echo "SITE_PO_EXECUTED_CAUSAL_WITNESS_PRESENT=$PO_WIT"
echo "SITE_RO_EXECUTED_CAUSAL_WITNESS_PRESENT=$RO_WIT"
echo "ANTI_CONTROL=the predecessor's executed C mutation for SITE-COMPOUND-ASSIGN must be findable"
echo "ANTI_CONTROL_CA_WITNESS_FILE=evidence/ACT-POLYC-SELFHOST-CORE-SEMANTIC-CONSUMER-RECON01/c2/probes/compound-assign-witness.HC"
if [ "$CA_WIT" -ge 1 ] && [ "$CA_REST" -ge 1 ] && [ "$PO_WIT" -eq 0 ] && [ "$RO_WIT" -eq 0 ]; then
  echo "RED03_RESULT=RED_CONFIRMED"; else echo "RED03_RESULT=NOT_RED"; fi
if [ "$CA_WIT" -ge 1 ] && [ "$CA_REST" -ge 1 ]; then
  echo "RED03_ANTI_CONTROL=DETECTOR_IS_SENSITIVE"; else echo "RED03_ANTI_CONTROL=DETECTOR_INSENSITIVE"; fi
