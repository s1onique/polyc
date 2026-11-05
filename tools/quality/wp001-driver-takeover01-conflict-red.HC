// tools/quality/wp001-driver-takeover01-conflict-red.HC
//
// ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
//
// THE EMIT-LLVM CONFLICT PREDICATE RED.
//
// WHAT IT DETECTS: whether the compiled PolyC driver's
// WpDriverEmitLlvmConflict() agrees with the LEGACY C ORACLE's
// mutual-exclusion condition.
//
// THE ORACLE. At entry (src/main.c at c92be049) the compiler tested
// the condition INSIDE an `if (args.emit_llvm)` guard:
//
//   if (args.emit_llvm) {
//     if (args.jit || args.repl || args.run || args.assemble_only ||
//         args.emit_object || args.emit_dylib || args.transpile ||
//         args.lsp)
//     { ...conflict... }
//   }
//
// The OUTER guard is part of the condition: a conflicting option
// WITHOUT an --emit-llvm request is NOT a conflict, because there is
// no LLVM request to be exclusive with.
//
// THE DEFECT THIS DETECTS. The PolyC driver flattened that nesting
// and DROPPED the outer guard, so it reported the conflict for a
// plain `-c` or a plain `-S`. The host renders the conflict
// diagnostic only on the LLVM route, so the compiler's OBSERVABLE
// behaviour was masked; the EXPORTED status was nevertheless wrong,
// and the exported status is the driver's published semantic
// authority.
//
// THE WITNESS. The tool links against the REAL production driver
// subject and calls the REAL exported predicate on the REAL argv
// shapes. It compares the driver's answer with the oracle's answer.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.
//
// USAGE:
//   wp001-takeover-conflict-red
//
// EXIT STATUS:
//   0  the predicate agrees with the legacy C oracle on every shape
//   1  the predicate DISAGREES with the oracle on at least one shape
//   2  a usage or internal error
//
// ---------------------------------------------------------------------------
// The driver host seam. The tool sets the driver's argv and then calls
// the driver's own exported predicate, so the predicate sees the REAL
// argv the way the production compiler presents it.
// ---------------------------------------------------------------------------
extern "c" U0 WpDriverHostSetArgv(I32 argc, U8 **argv);
extern "c" I64 WpDriverEmitLlvmConflict();

// ---------------------------------------------------------------------------
// The oracle's own answer, transcribed from the legacy C condition.
//
//   if (args.emit_llvm) {
//     if (<the conflicting options>) return 1;
//   }
//   return 0;
// ---------------------------------------------------------------------------
static I64 OracleConflict(I64 emit_llvm, I64 jit, I64 repl, I64 run,
                           I64 assemble_only, I64 emit_object,
                           I64 emit_dylib, I64 transpile, I64 lsp) {
  if (emit_llvm == 0) return 0;
  if (jit) return 1;
  if (repl) return 1;
  if (run) return 1;
  if (assemble_only) return 1;
  if (emit_object) return 1;
  if (emit_dylib) return 1;
  if (transpile) return 1;
  if (lsp) return 1;
  return 0;
}


// ---------------------------------------------------------------------------
// One case: the argv shape and the oracle's answer.
//
// The argv is built at RUNTIME. The reason is recorded in the
// takeover's other PolyC tools: this compiler can emit a string
// literal as an undefined label symbol in some shapes, and the tool
// would then fail to link.
// ---------------------------------------------------------------------------
#define MAXARG 16
static U8 *ARGS[MAXARG];
static I64 ARGC;

static U0 Put(U8 *s) {
  if (ARGC >= MAXARG) return;
  ARGS[ARGC] = s;
  ARGC = ARGC + 1;
}

static U0 Reset() {
  ARGC = 0;
  Put("hcc");
}

// Run one shape and compare the driver's answer with the oracle's.
static I64 Check(U8 *shape, I64 want,
                 I64 emit_llvm, I64 jit, I64 repl, I64 run,
                 I64 assemble_only, I64 emit_object, I64 emit_dylib,
                 I64 transpile, I64 lsp) {
  I32 n = ARGC;
  WpDriverHostSetArgv(n, ARGS);
  I64 got = WpDriverEmitLlvmConflict();
  I64 oracle = OracleConflict(emit_llvm, jit, repl, run, assemble_only,
                              emit_object, emit_dylib, transpile, lsp);
  // The oracle's answer is the EXPECTED answer; `want` is checked
  // against the oracle so the table and the transcription cannot
  // drift apart unnoticed.
  if (oracle != want) {
    "ORACLE_TABLE_MISMATCH shape=%s table=%d oracle=%d\n", shape, want, oracle;
    return 1;
  }
  if (got == want) {
    "CONFLICT_OK shape=%s value=%d\n", shape, got;
    return 0;
  }
  "CONFLICT_MISMATCH shape=%s want=%d got=%d\n", shape, want, got;
  return 1;
}


I32 Main(I32 argc, U8 **argv) {
  // The tool takes no arguments: the argv shapes are internal.
  if (argc < 1) return 2;
  if (argv == 0) return 2;

  I64 fail = 0;

  // A conflicting option with NO --emit-llvm request: NOT a conflict.
  Reset(); Put("-c"); Put("input.HC"); Put("-o"); Put("out.o");
  fail = fail + Check("plain_c", 0, 0, 1, 0, 0, 0, 1, 0, 0, 0);

  Reset(); Put("-S"); Put("input.HC"); Put("-o"); Put("out.o");
  fail = fail + Check("plain_S", 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);

  Reset(); Put("-transpile"); Put("input.HC");
  fail = fail + Check("plain_transpile", 0, 0, 0, 0, 0, 0, 0, 0, 1, 0);

  Reset(); Put("-lsp"); Put("input.HC");
  fail = fail + Check("plain_lsp", 0, 0, 0, 0, 0, 0, 0, 0, 0, 1);

  Reset(); Put("-lib"); Put("libtos.dylib"); Put("input.HC");
  fail = fail + Check("plain_lib", 0, 0, 0, 0, 0, 0, 0, 1, 0, 0);

  // --emit-llvm on its own: NOT a conflict.
  Reset(); Put("--emit-llvm"); Put("input.HC");
  fail = fail + Check("llvm_only", 0, 1, 0, 0, 0, 0, 0, 0, 0, 0);

  // --emit-llvm TOGETHER with a conflicting option: IS a conflict.
  Reset(); Put("--emit-llvm"); Put("-c"); Put("input.HC"); Put("-o"); Put("out.o");
  fail = fail + Check("llvm_and_c", 1, 1, 1, 0, 0, 0, 0, 0, 0, 0);

  Reset(); Put("--emit-llvm"); Put("-S"); Put("input.HC"); Put("-o"); Put("out.o");
  fail = fail + Check("llvm_and_S", 1, 1, 0, 0, 0, 1, 0, 0, 0, 0);

  Reset(); Put("--emit-llvm"); Put("-jit"); Put("input.HC");
  fail = fail + Check("llvm_and_jit", 1, 1, 0, 1, 0, 0, 0, 0, 0, 0);

  Reset(); Put("--emit-llvm"); Put("-repl"); Put("input.HC");
  fail = fail + Check("llvm_and_repl", 1, 1, 0, 0, 1, 0, 0, 0, 0, 0);

  Reset(); Put("--emit-llvm"); Put("-transpile"); Put("input.HC");
  fail = fail + Check("llvm_and_transpile", 1, 1, 0, 0, 0, 0, 0, 0, 1, 0);

  Reset(); Put("--emit-llvm"); Put("-lsp"); Put("input.HC");
  fail = fail + Check("llvm_and_lsp", 1, 1, 0, 0, 0, 0, 0, 0, 0, 1);

  if (fail != 0) {
    "WP001_EMIT_LLVM_CONFLICT_RED=FIRED\n";
    return 1;
  }
  "WP001_EMIT_LLVM_CONFLICT_RED=NOT_FIRED\n";
  return 0;
}
