# Mutation transcript
# M1: TK_ADD_EQU mapping changed from AST_BIN_OP_ADD to AST_BIN_OP_SUB in src/prslib.c only.
# First direct cmake attempt was rejected at configure because the nine PolyC subjects were absent; this is a missing-prerequisite transcript, not a causal failure.
# The real Makefile production-hcc path then built stage0 and all subjects and produced a linked mutant compiler.
# Pristine witness: Main returns 30.
# Mutant witness: Main returns 246 (10 - 20).
# Restored source SHA-256 and object SHA-256 are identical to pristine; restored witness returns 30.
# No production source was changed on authoritative main.
