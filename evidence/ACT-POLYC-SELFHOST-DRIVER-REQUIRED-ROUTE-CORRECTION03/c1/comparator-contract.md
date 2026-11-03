# C1 comparator contract

For each frozen argv case the isolated OFF and ON production compilers run
from separate directories. The harness records compiler exit, stdout, stderr,
artifact presence, artifact bytes, and `file` architecture/class. A compiled
PolyC comparator reads both artifacts, classifies them from bytes, and checks
class equality and byte equality.

The selector-OFF legacy object command currently emits an assembler warning
for unused link flags; the selector-ON object command does not. This
pre-existing stderr difference is P1 residue. No PolyC-owned diagnostic may
be added by the emission-precedence fix.
