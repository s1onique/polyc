# CORRECTION03 C2 GREEN

The unchanged mandatory eight-case matrix was rerun against fresh isolated
selector-OFF and selector-ON production compilers. Every case now has equal
artifact classes and equal artifact bytes.

The implementation collects object, assembly, and dylib requests while
scanning argv, then applies the C oracle's first-match order: object,
assembly, dylib, executable. This removes argv-order sensitivity without
returning semantic authority to C.

The direct compiled PolyC ABI probe also passed 15/15 cases, including the
six mixed object/assembly cases.
