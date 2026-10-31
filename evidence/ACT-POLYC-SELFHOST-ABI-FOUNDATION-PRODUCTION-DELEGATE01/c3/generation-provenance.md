# ACT_ID=ACT-POLYC-SELFHOST-ABI-FOUNDATION-PRODUCTION-DELEGATE01
# ACT_PHASE=C3-EVIDENCE
# EVIDENCE_KIND=generation-provenance
#
# THREE DISTINCT PRODUCER EXECUTABLES. The same binary is never counted
# three times, and independence is never manufactured by renaming a path.
#
#   G1 producer  build/host-stage0/hcc
#   G2 producer  ./hcc                (the production compiler)
#   G3 producer  build/hcc-bootstrap04 (a separately built bootstrap-generation compiler)
#
# The subject OBJECTS are byte-identical across G1, G2 and G3, which is
# the expected result of deterministic compilation. The PRODUCER
# executables are three distinct binaries with three distinct digests,
# and that is what the independence claim rests on.
#
# THE TWELVE ORDERED PAIRS. For each of the nine frozen witnesses the
# four generations produce identical stdout, identical stderr and
# identical exit status, so all 12 ordered pairs (G0-G1, G0-G2, G0-G3,
# G1-G2, G1-G3, G2-G3 and their six reverses) agree on every row.
#
# The full per-witness table is c3/four-generations-and-12-ordered-differentials.tsv.
# The producer identities are c3/generation-provenance.tsv.
