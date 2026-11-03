# C1 precedence contract

The independent selector-OFF compiler derives the emission precedence from
`src/main.c`: an object request is tested first, assembly second, dylib
third, and executable is the default. This is a property of the whole argv,
not of the last option encountered.

The PolyC implementation SHALL therefore select the highest-priority
recognized emission request while scanning argv. It SHALL NOT overwrite an
already selected higher-priority request with a lower-priority one.

| priority | emission |
| --- | --- |
| 1 | object (`-c`, `-obj`) |
| 2 | assembly (`-S`) |
| 3 | dylib (`-lib`) |
| 4 | executable/default |

The default executable route remains conditional on a source file, matching
the existing selected-emission semantics. Invalid arity remains UNKNOWN.
