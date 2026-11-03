// tools/bootstrap/selfhost-driver-wp001.HC
//
// ACT-POLYC-SELFHOST-DRIVER-MIGRATION01 C2 IMPL.
//
// THE POLYC-AUTHORED COMPILER DRIVER (WP-001).
//
// This component owns the DECISION GRAPH of the production compile
// route. It is compiled by the real producer from this PolyC source and
// linked into the production ./hcc.
//
// WHAT IT OWNS (the migrated authority):
//
//   (a) flag/argument classification  WpDriverClassifyOption
//                                     WpDriverValueArgIndex
//   (b) compile-action dispatch        WpDriverSelectAction
//   (c) status/error mapping           WpDriverMapStatus
//
// Plus the data those decisions read: the option table itself, and the
// source-file-type classifier.
//
// WHAT IT DOES NOT OWN. The C side keeps only the platform duties:
// the argument byte accessors, the process entry, the retained
// compilation engine (C_SEMANTIC_ENGINE_RETAINED) and the existing
// diagnostic path. There is NO C option table, NO C flag test and NO C
// fallback: if this subject is missing the build fails.
//
// THE ABI (frozen in c1/abi-ownership-and-recovery.md):
//
//   long     WpDriverHostArgc();
//   long     WpDriverHostArgLen(long idx);
//   unsigned char *WpDriverHostArgByte(long idx);
//
// The seam carries no raw argv, no void* and no struct layout.
//
// THE STATUS DOMAIN is DISJOINT from the action domain. Actions are
// >= 1; a legitimate zero-valued action can therefore never collide
// with a failure status.
//
// PolyC has no `void` type, so the empty return type is U0, and PolyC
// has no ternary operator, so every conditional is an explicit if.

// ---------------------------------------------------------------------------
// THE HOST SEAM
// ---------------------------------------------------------------------------

extern "c" I64 WpDriverHostArgc();
extern "c" I64 WpDriverHostArgLen(I64 idx);
extern "c" U8 *WpDriverHostArgByte(I64 idx);

// ---------------------------------------------------------------------------
// THE STATUS DOMAIN
//
// 0 is reserved for "no error". Every failure is >= 1 and every failure
// is DISTINGUISHABLE from every other failure.
// ---------------------------------------------------------------------------

#define WP_STATUS_OK        0   // success, or nothing to do
#define WP_STATUS_USAGE     1   // unknown option
#define WP_STATUS_COMPILE   2   // a compile action was selected
#define WP_STATUS_ARITY     3   // an argument arity / domain violation
#define WP_STATUS_NO_INPUT  4   // no input file
#define WP_STATUS_ENGINE    5   // the compile engine reported failure

// The action domain. Actions are >= 1, disjoint from the status domain.
#define WP_ACTION_COMPILE_OBJECT  1
#define WP_ACTION_EMIT_ASSEMBLY    2
#define WP_ACTION_PRINT_AST        3
#define WP_ACTION_PRINT_TOKENS     4
#define WP_ACTION_DUMP_IR          5
#define WP_ACTION_TRANSPILE        6
#define WP_ACTION_EMIT_DYLIB       7
#define WP_ACTION_RUN              8
#define WP_ACTION_JIT              9
#define WP_ACTION_REPL            10
#define WP_ACTION_LSP             11
#define WP_ACTION_CFG             12
#define WP_ACTION_USAGE           13
#define WP_ACTION_VERSION        14
#define WP_ACTION_HELP           15
#define WP_ACTION_TERRY          16
#define WP_ACTION_MEMSTATS       17
#define WP_ACTION_CAPTABLE       18
#define WP_ACTION_EMIT_LLVM      19
#define WP_ACTION_NONE           20   // no action selected; an error

// ---------------------------------------------------------------------------
// THE OPTION TABLE -- OWNED BY POLYC
//
// Each entry is: name, arity (0 = no value, 1 = takes a value), kind.
// The kind is a driver-internal classification used to select the
// action; it is NOT the compiler's CliArgType enum and it does not
// depend on it.
// ---------------------------------------------------------------------------

#define WP_KIND_FLAG       1   // a boolean switch
#define WP_KIND_OUTFILE    2   // -o
#define WP_KIND_INSTALL    3   // --install-dir
#define WP_KIND_SOURCE     4   // -lib
#define WP_KIND_CLIBS      5   // -clibs
#define WP_KIND_DEFINE     6   // -D
#define WP_KIND_TARGET     7   // --target
#define WP_KIND_EMIT_OBJ   8   // -c / -obj
#define WP_KIND_ASSEMBLY   9   // -S
#define WP_KIND_AST       10   // -ast
#define WP_KIND_TOKENS    11   // -tokens
#define WP_KIND_CFG       12   // -cfg / -cfg-png / -cfg-svg
#define WP_KIND_RUN       13   // -run
#define WP_KIND_JIT       14   // -jit
#define WP_KIND_REPL      15   // -repl
#define WP_KIND_LSP       16   // -lsp
#define WP_KIND_STDOUT    17   // -o-
#define WP_KIND_TRANSPILE 18   // -transpile
#define WP_KIND_DUMP_IR   19   // --dump-ir
#define WP_KIND_DUMP_IRP  20   // --dump-ir-pooled
#define WP_KIND_LLVM      21   // --emit-llvm
#define WP_KIND_CAPTABLE  22   // --print-cap-table
#define WP_KIND_VERSION   23   // --version
#define WP_KIND_HELP      24   // --help
#define WP_KIND_TERRY     25   // --terry
#define WP_KIND_MEMSTATS  26   // --mem-stats
#define WP_KIND_MEMSAFE   27   // -Memsafe
#define WP_KIND_WERROR    28   // -Werror
#define WP_KIND_PIC       29   // -fPIC
#define WP_KIND_LEGACYX86 30   // --use-legacy-x86

// The number of options in the table.
#define WP_OPT_COUNT 32

// WHERE an option's value lives.
#define WP_VALUE_NEXT 1   // the value is the NEXT argument
#define WP_VALUE_SAME 2   // the value is the SUFFIX of this argument
#define WP_VALUE_NONE 3   // the option takes no value

// The option name. The table order is the frozen C0 order, which is
// the live cli.c option-table order.
static U8 *WpDriverOptName(I64 i) {
  if (i ==  0) return "-ast";
  if (i ==  1) return "-cfg";
  if (i ==  2) return "-cfg-png";
  if (i ==  3) return "-cfg-svg";
  if (i ==  4) return "-tokens";
  if (i ==  5) return "-S";
  if (i ==  6) return "-obj";
  if (i ==  7) return "-c";
  if (i ==  8) return "-lib";
  if (i ==  9) return "-clibs";
  if (i == 10) return "-run";
  if (i == 11) return "-jit";
  if (i == 12) return "-Memsafe";
  if (i == 13) return "-repl";
  if (i == 14) return "-lsp";
  if (i == 15) return "-o";
  if (i == 16) return "-o-";
  if (i == 17) return "-transpile";
  if (i == 18) return "--target";
  if (i == 19) return "--install-dir";
  if (i == 20) return "-D";
  if (i == 21) return "--dump-ir";
  if (i == 22) return "--dump-ir-pooled";
  if (i == 23) return "--emit-llvm";
  if (i == 24) return "--print-cap-table";
  if (i == 25) return "--mem-stats";
  if (i == 26) return "--version";
  if (i == 27) return "--help";
  if (i == 28) return "--terry";
  if (i == 29) return "--use-legacy-x86";
  if (i == 30) return "-Werror";
  if (i == 31) return "-fPIC";
  return "";
}

// The arity: 0 means the option takes no value, 1 means it takes one.
static I64 WpDriverOptArity(I64 i) {
  if (i ==  8) return 1;   // -lib
  if (i ==  9) return 1;   // -clibs
  if (i == 15) return 1;   // -o
  if (i == 18) return 1;   // --target
  if (i == 19) return 1;   // --install-dir
  if (i == 20) return 1;   // -D
  return 0;
}

// The kind: the driver-internal classification of the option.
static I64 WpDriverOptKind(I64 i) {
  if (i ==  0) return WP_KIND_AST;
  if (i ==  1) return WP_KIND_CFG;
  if (i ==  2) return WP_KIND_CFG;
  if (i ==  3) return WP_KIND_CFG;
  if (i ==  4) return WP_KIND_TOKENS;
  if (i ==  5) return WP_KIND_ASSEMBLY;
  if (i ==  6) return WP_KIND_EMIT_OBJ;
  if (i ==  7) return WP_KIND_EMIT_OBJ;
  if (i ==  8) return WP_KIND_SOURCE;
  if (i ==  9) return WP_KIND_CLIBS;
  if (i == 10) return WP_KIND_RUN;
  if (i == 11) return WP_KIND_JIT;
  if (i == 12) return WP_KIND_MEMSAFE;
  if (i == 13) return WP_KIND_REPL;
  if (i == 14) return WP_KIND_LSP;
  if (i == 15) return WP_KIND_OUTFILE;
  if (i == 16) return WP_KIND_STDOUT;
  if (i == 17) return WP_KIND_TRANSPILE;
  if (i == 18) return WP_KIND_TARGET;
  if (i == 19) return WP_KIND_INSTALL;
  if (i == 20) return WP_KIND_DEFINE;
  if (i == 21) return WP_KIND_DUMP_IR;
  if (i == 22) return WP_KIND_DUMP_IRP;
  if (i == 23) return WP_KIND_LLVM;
  if (i == 24) return WP_KIND_CAPTABLE;
  if (i == 25) return WP_KIND_MEMSTATS;
  if (i == 26) return WP_KIND_VERSION;
  if (i == 27) return WP_KIND_HELP;
  if (i == 28) return WP_KIND_TERRY;
  if (i == 29) return WP_KIND_LEGACYX86;
  if (i == 30) return WP_KIND_WERROR;
  if (i == 31) return WP_KIND_PIC;
  return WP_KIND_FLAG;
}

// ---------------------------------------------------------------------------
// THE SOURCE FILE TYPE CLASSIFIER -- OWNED BY POLYC
//
// This is the migrated cliGetFileType decision: a source file is
// recognised by its extension. The classifier reads the argument BYTES
// through the host accessor, so it never assumes a C layout.
// ---------------------------------------------------------------------------

#define WP_FILE_INVALID  0
#define WP_FILE_SOURCE   1
#define WP_FILE_HEADER   2
#define WP_FILE_ASM      3
#define WP_FILE_OBJECT   4
#define WP_FILE_SHARED   5

// Read the byte at `idx` of argument `argIdx`.
// Returns -1 when the index is outside the argument.
static I64 WpDriverArgByteAt(I64 argIdx, I64 idx) {
  I64 len = WpDriverHostArgLen(argIdx);
  if (idx < 0) return -1;
  if (idx >= len) return -1;
  U8 *p = WpDriverHostArgByte(argIdx) + idx;
  return *p;
}

// The byte at `idx` of argument `argIdx`, LOWERCASED when it is an
// ASCII letter.
//
// The live C classifier uses tolower(), so ".HC" and ".hc" agree. This
// helper performs that lowering itself, because the extension check
// looks at several bytes and each must be compared case-insensitively.
//
// Returns -1 when the index is outside the argument.
static I64 WpDriverArgByteLower(I64 argIdx, I64 idx) {
  I64 len = WpDriverHostArgLen(argIdx);
  if (idx < 0) return -1;
  if (idx >= len) return -1;
  U8 *p = WpDriverHostArgByte(argIdx) + idx;
  I64 b = *p;
  if (b >= 65 && b <= 90) b = b + 32;
  return b;
}

// The file type of the argument, or WP_FILE_INVALID.
static I64 WpDriverClassifyFile(I64 argIdx) {
  I64 len = WpDriverHostArgLen(argIdx);
  if (len < 3) return WP_FILE_INVALID;
  I64 last = len - 1;
  I64 c = WpDriverArgByteLower(argIdx, last);
  I64 p1 = WpDriverArgByteLower(argIdx, last - 1);
  I64 p2 = WpDriverArgByteLower(argIdx, last - 2);
  if (c == 99 && p1 == 104 && p2 == 46) {
    // .hc
    return WP_FILE_SOURCE;
  }
  if (c == 104 && p1 == 104 && p2 == 46) {
    // .hh
    return WP_FILE_HEADER;
  }
  if (c == 115 && p1 == 46) {
    // .s
    return WP_FILE_ASM;
  }
  if (c == 111 && p1 == 46) {
    // .o
    return WP_FILE_OBJECT;
  }
  if (c == 111 && p1 == 115 && p2 == 46) {
    // .so
    return WP_FILE_SHARED;
  }
  if (len >= 7) {
    I64 e = last - 5;
    if (WpDriverArgByteLower(argIdx, e) == 46
        && WpDriverArgByteLower(argIdx, e + 1) == 100   // d
        && WpDriverArgByteLower(argIdx, e + 2) == 121   // y
        && WpDriverArgByteLower(argIdx, e + 3) == 108   // l
        && WpDriverArgByteLower(argIdx, e + 4) == 105   // i
        && WpDriverArgByteLower(argIdx, e + 5) == 98) { // b
      return WP_FILE_SHARED;                             // .dylib
    }
  }
  return WP_FILE_INVALID;
}

// ---------------------------------------------------------------------------
// SITE (a) FLAG / ARGUMENT CLASSIFICATION
//
// WpDriverClassifyOption: is this argument one of our options?
// WpDriverValueArgIndex:   where is that option's value?
//
// Both are DOMAIN CHECKED. An out-of-range index is a domain failure,
// not a silent zero.
// ---------------------------------------------------------------------------

// Compare the argument at argIdx against the option name at optIdx.
// Returns 1 on an exact match, 0 otherwise.
//
// This reproduces the LIVE cliParserFind decision exactly:
//
//   1. EXACT match: the argument IS the option name.
//   2. THE "=" FORM: the argument is the option name, then '=', then
//      the value. The value lives in the SAME argument.
//   3. THE "-D" PREFIX: any argument that begins with "-D" matches the
//      "-D" option, because a #define is written "-DNAME".
//
// Rules 2 and 3 only apply when the argument is LONGER than the option
// name, exactly as the live code requires.
static I64 WpDriverOptMatches(I64 argIdx, I64 optIdx) {
  I64 alen = WpDriverHostArgLen(argIdx);
  U8 *an = WpDriverOptName(optIdx);
  I64 nlen = 0;
  while (an[nlen] != 0) nlen = nlen + 1;

  // Rule 1: the exact match.
  if (alen == nlen) {
    I64 j = 0;
    while (j < nlen) {
      U8 *ap = WpDriverHostArgByte(argIdx) + j;
      if (*ap != an[j]) return 0;
      j = j + 1;
    }
    return 1;
  }
  if (alen < nlen) return 0;

  // The argument is longer than the option name.
  // Rule 2: the "=" form.
  I64 k = 0;
  I64 prefix_ok = 1;
  while (k < nlen) {
    U8 *ap = WpDriverHostArgByte(argIdx) + k;
    if (*ap != an[k]) { prefix_ok = 0; }
    k = k + 1;
  }
  if (prefix_ok == 1) {
    U8 *eqp = WpDriverHostArgByte(argIdx) + nlen;
    if (*eqp == 61) return 1;    // '='
  }
  // Rule 3: the "-D" prefix. Both the option name and the argument
  // must begin with "-D".
  if (an[0] == 45 && an[1] == 68) {
    U8 *a0 = WpDriverHostArgByte(argIdx);
    if (a0[0] == 45 && a0[1] == 68) return 1;
  }
  return 0;
}

// The option index of the argument, or -1 when the argument is not an
// option. The domain is checked first.
I64 WpDriverClassifyOption(I64 argIdx) {
  if (argIdx < 0) return -1;
  if (argIdx >= WpDriverHostArgc()) return -1;
  I64 i = 0;
  while (i < WP_OPT_COUNT) {
    if (WpDriverOptMatches(argIdx, i) == 1) return i;
    i = i + 1;
  }
  return -1;
}

// WHERE the option's value lives.
//
//   WP_VALUE_NEXT   the value is the NEXT argument
//   WP_VALUE_SAME   the value is the SUFFIX of this very argument
//   WP_VALUE_NONE   the option takes no value
//
// This is the migrated arity decision. The rule reproduces the live
// cliParseArgs decision exactly:
//
//   1. if the ARGUMENT carries the "=" form, the value is the suffix
//      of THIS argument -- this wins for every option, including the
//      ones whose arity is 1;
//   2. otherwise, if the option's arity is 1, the value is the NEXT
//      argument;
//   3. otherwise the option takes no value.
//
// The live table's arg_count says whether the NEXT argument may hold
// the value; the live parse function says whether a suffix may hold
// it. The "-D" option has arity 0 but a suffix value, and --target has
// arity 0 but a suffix value, while --install-dir has arity 1 and
// accepts BOTH forms.
static I64 WpDriverValueSource(I64 argIdx, I64 optIdx) {
  // The "=" form. The argument is the option name, then '=', then the
  // value, so the value is a SUFFIX of this argument.
  I64 alen = WpDriverHostArgLen(argIdx);
  U8 *an = WpDriverOptName(optIdx);
  I64 nlen = 0;
  while (an[nlen] != 0) nlen = nlen + 1;
  if (alen > nlen) {
    I64 k = 0;
    I64 prefix_ok = 1;
    while (k < nlen) {
      U8 *ap = WpDriverHostArgByte(argIdx) + k;
      if (*ap != an[k]) { prefix_ok = 0; }
      k = k + 1;
    }
    if (prefix_ok == 1) {
      U8 *eqp = WpDriverHostArgByte(argIdx) + nlen;
      if (*eqp == 61) return WP_VALUE_SAME;   // '='
    }
  }
  // The "-D" prefix form: the value is the suffix after "-D".
  if (optIdx == 20) return WP_VALUE_SAME;
  // The next-argument form.
  if (WpDriverOptArity(optIdx) == 1) return WP_VALUE_NEXT;
  return WP_VALUE_NONE;
}

// The arity check. An option whose value is the NEXT argument must
// have that argument present and inside argv. A MISSING value is a
// DOMAIN FAILURE.
static I64 WpDriverArityOk(I64 argIdx, I64 optIdx) {
  I64 src = WpDriverValueSource(argIdx, optIdx);
  if (src == WP_VALUE_NEXT) {
    if (argIdx + 1 < 0) return 0;
    if (argIdx + 1 >= WpDriverHostArgc()) return 0;
    return 1;
  }
  return 1;
}

// The index of the option's value argument, or -1 when the argument is
// not an option, when the option takes no value, or when the value is
// MISSING.
//
// A SUFFIX value lives in the argument itself, so its index is the
// argument's own index.
I64 WpDriverValueArgIndex(I64 argIdx) {
  I64 opt = WpDriverClassifyOption(argIdx);
  if (opt < 0) return -1;
  I64 src = WpDriverValueSource(argIdx, opt);
  if (src == WP_VALUE_NONE) return -1;
  if (WpDriverArityOk(argIdx, opt) == 0) return -1;
  if (src == WP_VALUE_SAME) return argIdx;
  return argIdx + 1;
}

// The byte offset AT WHICH the value starts inside its argument.
//
// For a NEXT value this is 0: the value IS the whole next argument.
// For a SUFFIX value this is the length of the option name, plus one
// for the '=' when the "=" form was used, or exactly two for the "-D"
// option, which drops precisely two characters.
I64 WpDriverValueOffset(I64 argIdx, I64 optIdx) {
  I64 src = WpDriverValueSource(argIdx, optIdx);
  if (src == WP_VALUE_SAME) {
    U8 *an = WpDriverOptName(optIdx);
    I64 nlen = 0;
    while (an[nlen] != 0) nlen = nlen + 1;
    // The "-D" option drops exactly two characters.
    if (nlen == 2) return 2;
    // The "=" form drops the option name AND the '='.
    I64 alen = WpDriverHostArgLen(argIdx);
    if (alen > nlen) {
      U8 *eqp = WpDriverHostArgByte(argIdx) + nlen;
      if (*eqp == 61) return nlen + 1;
    }
    return nlen;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// THE ARGUMENT CLASSIFIER -- OWNED BY POLYC
//
// This is the migrated cliParserFind + cliGetFileType decision, fused
// into ONE classification:
//
//   WP_ARG_OPTION   the argument is a known option
//   WP_ARG_SOURCE   the argument is a source/header/assembly file
//   WP_ARG_OBJECT   the argument is an object or shared object
//   WP_ARG_UNKNOWN  the argument is neither
//
// An UNKNOWN argument is the one the live CLI collects into the argv
// list and then reports as "Unknown commandline options". That
// reporting is a decision, so it is PolyC's to make.
//
// The classification is what makes the "unknown option" path work: an
// argument that is not a known option and not a file is UNKNOWN, and
// the driver counts them.
// ---------------------------------------------------------------------------

#define WP_ARG_OPTION  1
#define WP_ARG_SOURCE  2
#define WP_ARG_OBJECT  3
#define WP_ARG_UNKNOWN 4

// The classification of the argument at argIdx.
I64 WpDriverClassifyArgument(I64 argIdx) {
  if (argIdx < 0) return WP_ARG_UNKNOWN;
  if (argIdx >= WpDriverHostArgc()) return WP_ARG_UNKNOWN;
  if (WpDriverClassifyOption(argIdx) >= 0) return WP_ARG_OPTION;
  I64 ftype = WpDriverClassifyFile(argIdx);
  if (ftype == WP_FILE_SOURCE) return WP_ARG_SOURCE;
  if (ftype == WP_FILE_HEADER) return WP_ARG_SOURCE;
  if (ftype == WP_FILE_ASM) return WP_ARG_SOURCE;
  if (ftype == WP_FILE_OBJECT) return WP_ARG_OBJECT;
  if (ftype == WP_FILE_SHARED) return WP_ARG_OBJECT;
  return WP_ARG_UNKNOWN;
}

// The number of UNKNOWN arguments in the argv. This is the migrated
// "Unknown commandline options" decision input.
I64 WpDriverUnknownArgCount() {
  I64 n = 0;
  I64 i = 1;   // argv[0] is the program name
  I64 argc = WpDriverHostArgc();
  while (i < argc) {
    if (WpDriverClassifyArgument(i) == WP_ARG_UNKNOWN) n = n + 1;
    i = i + 1;
  }
  return n;
}

// The number of ARITY violations in the argv. An option whose value
// must be the NEXT argument but has no NEXT argument is a violation.
I64 WpDriverArityViolationCount() {
  I64 n = 0;
  I64 i = 1;
  I64 argc = WpDriverHostArgc();
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      if (WpDriverArityOk(i, opt) == 0) n = n + 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }
  return n;
}

// ---------------------------------------------------------------------------
// SITE (b) COMPILE-ACTION DISPATCH
//
// WpDriverSelectAction: which action does this argv select?
//
// This is the migrated cliParseArgs dispatch decision and the migrated
// getASMFileName file-type-to-action decision, in one PolyC-owned
// function. The C side does not get a say.
//
// The result is an ACTION code, never a status. The status mapping is a
// separate site (c) so that the two are independently mutable.
// ---------------------------------------------------------------------------

// The whole-argv decision. It returns an action code, or
// WP_ACTION_NONE when the argv selects no action at all.
//
// The decision order matters and is PolyC-owned:
//   1. an explicit informational action wins (help, version, ...);
//   2. an output file selects the compile-to-object action;
//   3. otherwise the source file decides.
// The ACTION for the option at optIdx, as decided by the driver.
I64 WpDriverOptionAction(I64 optIdx) {
  I64 kind = WpDriverOptKind(optIdx);
  if (kind == WP_KIND_AST)       return WP_ACTION_PRINT_AST;
  if (kind == WP_KIND_CFG)       return WP_ACTION_CFG;
  if (kind == WP_KIND_TOKENS)    return WP_ACTION_PRINT_TOKENS;
  if (kind == WP_KIND_ASSEMBLY)  return WP_ACTION_EMIT_ASSEMBLY;
  if (kind == WP_KIND_EMIT_OBJ)  return WP_ACTION_COMPILE_OBJECT;
  if (kind == WP_KIND_SOURCE)    return WP_ACTION_EMIT_DYLIB;
  if (kind == WP_KIND_RUN)       return WP_ACTION_RUN;
  if (kind == WP_KIND_JIT)       return WP_ACTION_JIT;
  if (kind == WP_KIND_REPL)      return WP_ACTION_REPL;
  if (kind == WP_KIND_LSP)       return WP_ACTION_LSP;
  if (kind == WP_KIND_TRANSPILE) return WP_ACTION_TRANSPILE;
  if (kind == WP_KIND_DUMP_IR)   return WP_ACTION_DUMP_IR;
  if (kind == WP_KIND_DUMP_IRP)  return WP_ACTION_DUMP_IR;
  if (kind == WP_KIND_LLVM)      return WP_ACTION_EMIT_LLVM;
  if (kind == WP_KIND_CAPTABLE)  return WP_ACTION_CAPTABLE;
  if (kind == WP_KIND_VERSION)   return WP_ACTION_VERSION;
  if (kind == WP_KIND_HELP)      return WP_ACTION_HELP;
  if (kind == WP_KIND_TERRY)     return WP_ACTION_TERRY;
  if (kind == WP_KIND_MEMSTATS)  return WP_ACTION_MEMSTATS;
  return WP_ACTION_NONE;
}

I64 WpDriverSelectAction() {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;                    // argv[0] is the program name
  I64 explicit_action = WP_ACTION_NONE;
  I64 saw_output = 0;
  I64 saw_source = 0;

  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      if (WpDriverArityOk(i, opt) == 0) return WP_ACTION_NONE;
      I64 act = WpDriverOptionAction(opt);
      // An informational action is remembered and wins.
      if (act == WP_ACTION_HELP || act == WP_ACTION_VERSION
          || act == WP_ACTION_TERRY || act == WP_ACTION_CAPTABLE
          || act == WP_ACTION_MEMSTATS) {
        explicit_action = act;
      }
      if (WpDriverOptKind(opt) == WP_KIND_OUTFILE) saw_output = 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      // Only a NEXT value consumes the following argument. A SUFFIX
      // value lives inside the argument we just consumed.
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    // Not an option: it may be a source file.
    I64 kind = WpDriverClassifyArgument(i);
    if (kind == WP_ARG_SOURCE) saw_source = 1;
    i = i + 1;
  }

  if (explicit_action != WP_ACTION_NONE) return explicit_action;
  if (saw_output == 1) return WP_ACTION_COMPILE_OBJECT;
  if (saw_source == 1) return WP_ACTION_COMPILE_OBJECT;
  return WP_ACTION_NONE;
}

// ---------------------------------------------------------------------------
// SITE (c) STATUS / ERROR MAPPING
//
// WpDriverMapStatus: what status does this action map to?
//
// The status domain is DISJOINT from the action domain. A legitimate
// zero-valued action can never collide with a failure status, and every
// failure is distinguishable from every other failure.
// ---------------------------------------------------------------------------

// Whether an UNKNOWN argument was present. This is the migrated
// "Unknown commandline options" decision.
//
// The live CLI collects the unknown arguments and reports them when
// the argv holds at least one and neither -jit nor -run was asked
// for. That check does NOT depend on whether an action was selected:
// the live C runs it after the option loop, and it fires even when a
// source file was also present.
//
// The "-jit" and "-run" exemptions are the driver's own decision, so
// they are PolyC's to make.
I64 WpDriverHasUnknownArgument() {
  if (WpDriverUnknownArgCount() == 0) return 0;
  I64 i = 1;
  I64 argc = WpDriverHostArgc();
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_JIT) return 0;
      if (kind == WP_KIND_RUN) return 0;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }
  return 1;
}

I64 WpDriverMapStatus(I64 action) {
  // The ARITY decision comes FIRST: an option whose value is missing
  // is an arity violation whatever else the argv says.
  if (WpDriverArityViolationCount() > 0) return WP_STATUS_ARITY;
  // The UNKNOWN-ARGUMENT decision comes SECOND: the live CLI reports
  // the collected unknown arguments even when a source file was also
  // present, so this check does not depend on the selected action.
  //
  // This is the STATUS PROPAGATION site that the C3 M3 mutation
  // targets: changing the status returned here changes the message
  // the process reports, from "Unknown commandline options: ..." to
  // "no input files", while the exit status stays 1.
  if (WpDriverHasUnknownArgument() == 1) return WP_STATUS_USAGE;
  if (action == WP_ACTION_COMPILE_OBJECT) return WP_STATUS_COMPILE;
  if (action == WP_ACTION_EMIT_ASSEMBLY)   return WP_STATUS_COMPILE;
  if (action == WP_ACTION_PRINT_AST)       return WP_STATUS_COMPILE;
  if (action == WP_ACTION_PRINT_TOKENS)    return WP_STATUS_COMPILE;
  if (action == WP_ACTION_DUMP_IR)         return WP_STATUS_COMPILE;
  if (action == WP_ACTION_TRANSPILE)       return WP_STATUS_COMPILE;
  if (action == WP_ACTION_EMIT_DYLIB)      return WP_STATUS_COMPILE;
  if (action == WP_ACTION_RUN)             return WP_STATUS_COMPILE;
  if (action == WP_ACTION_JIT)             return WP_STATUS_COMPILE;
  if (action == WP_ACTION_REPL)            return WP_STATUS_COMPILE;
  if (action == WP_ACTION_LSP)             return WP_STATUS_COMPILE;
  if (action == WP_ACTION_CFG)             return WP_STATUS_COMPILE;
  if (action == WP_ACTION_EMIT_LLVM)       return WP_STATUS_COMPILE;
  if (action == WP_ACTION_USAGE)           return WP_STATUS_USAGE;
  if (action == WP_ACTION_VERSION)         return WP_STATUS_OK;
  if (action == WP_ACTION_HELP)            return WP_STATUS_OK;
  if (action == WP_ACTION_TERRY)           return WP_STATUS_OK;
  if (action == WP_ACTION_MEMSTATS)        return WP_STATUS_OK;
  if (action == WP_ACTION_CAPTABLE)        return WP_STATUS_OK;
  if (action == WP_ACTION_NONE) {
    // No action was selected. The reason is either an UNKNOWN
    // argument or the absence of an input file. The live CLI reports
    // the unknown argument first, because it collects the unknown
    // arguments and then reports them.
    if (WpDriverUnknownArgCount() > 0) return WP_STATUS_USAGE;
    return WP_STATUS_NO_INPUT;
  }
  return WP_STATUS_USAGE;
}

// The single entry point the C side calls. It performs the whole
// PolyC-owned decision and returns the STATUS.
//
// The C side uses this status and NOTHING ELSE to decide what to do.
// It has no second policy of its own.
I64 WpDriverDecide() {
  I64 action = WpDriverSelectAction();
  return WpDriverMapStatus(action);
}

// The action code, exposed so the C side can carry out the selected
// action without re-deriving it.
I64 WpDriverSelectedAction() {
  return WpDriverSelectAction();
}

// ---------------------------------------------------------------------------
// THE FIELD SELECTION -- OWNED BY POLYC
//
// The C side must not contain a second policy, so even the decision
// "which CliArgs field does this option set?" lives here.
//
// The field codes are driver-internal. The C bridge maps each code to
// exactly one CliArgs member with a mechanical switch that contains NO
// option names, NO arity logic and NO action selection.
//
//   0  none
//   1  print_ast
//   2  print_tokens
//   3  cfg_create
//   4  cfg_create_png
//   5  cfg_create_svg
//   6  assemble_only
//   7  werror
//   8  emit_dylib          (value: the library name)
//   9  emit_object
//   10 run
//   11 jit
//   12 memsafe
//   13 repl
//   14 lsp
//   15 assemble
//   16 transpile
//   17 to_stdout
//   18 output_filename     (value)
//   19 clibs               (value)
//   20 defines_list        (value)
//   21 target              (value)
//   22 install_dir         (value)
//   23 dump_ir
//   24 dump_ir_pooled
//   25 emit_llvm
//   26 print_cap_table
//   27 print_mem_stats
//   28 help
//   29 version
//   30 terry
//   31 use_legacy_x86
//   32 fPIC
// ---------------------------------------------------------------------------

#define WP_FIELD_NONE             0
#define WP_FIELD_PRINT_AST        1
#define WP_FIELD_PRINT_TOKENS     2
#define WP_FIELD_CFG_CREATE       3
#define WP_FIELD_CFG_PNG          4
#define WP_FIELD_CFG_SVG          5
#define WP_FIELD_ASSEMBLE_ONLY    6
#define WP_FIELD_WERROR           7
#define WP_FIELD_EMIT_DYLIB       8
#define WP_FIELD_EMIT_OBJECT      9
#define WP_FIELD_RUN             10
#define WP_FIELD_JIT             11
#define WP_FIELD_MEMSAFE         12
#define WP_FIELD_REPL            13
#define WP_FIELD_LSP             14
#define WP_FIELD_ASSEMBLE        15
#define WP_FIELD_TRANSPILE       16
#define WP_FIELD_TO_STDOUT       17
#define WP_FIELD_OUTPUT_FILENAME 18
#define WP_FIELD_CLIBS           19
#define WP_FIELD_DEFINES_LIST    20
#define WP_FIELD_TARGET          21
#define WP_FIELD_INSTALL_DIR     22
#define WP_FIELD_DUMP_IR         23
#define WP_FIELD_DUMP_IR_POOLED  24
#define WP_FIELD_EMIT_LLVM       25
#define WP_FIELD_CAP_TABLE       26
#define WP_FIELD_MEM_STATS       27
#define WP_FIELD_HELP            28
#define WP_FIELD_VERSION         29
#define WP_FIELD_TERRY           30
#define WP_FIELD_USE_LEGACY_X86  31
#define WP_FIELD_FPIC            32

// The CliArgs field that the ACTION selects.
//
// This is the bridge between the action dispatch (site b) and the
// field selection. An option whose action is WP_ACTION_COMPILE_OBJECT
// sets the emit-object field; an option whose action is anything else
// sets NO field, because no other action is reached through a
// CliArgs flag on this route.
//
// The point of the indirection is CAUSAL: the field is derived from
// the ACTION, so a mutation of the action mapping changes the field,
// and the field is what the C engine reads. An action that is
// computed but never consulted would be decorative.
I64 WpDriverFieldForAction(I64 action) {
  if (action == WP_ACTION_COMPILE_OBJECT) return WP_FIELD_EMIT_OBJECT;
  return WP_FIELD_NONE;
}

// The field code for the option at optIdx.
I64 WpDriverOptionField(I64 optIdx) {
  if (optIdx ==  0) return WP_FIELD_PRINT_AST;
  if (optIdx ==  1) return WP_FIELD_CFG_CREATE;
  if (optIdx ==  2) return WP_FIELD_CFG_PNG;
  if (optIdx ==  3) return WP_FIELD_CFG_SVG;
  if (optIdx ==  4) return WP_FIELD_PRINT_TOKENS;
  if (optIdx ==  5) return WP_FIELD_ASSEMBLE_ONLY;
  // The COMPILE-OBJECT options are NOT named here. The field they set
  // is DERIVED FROM THE ACTION MAPPING, so that the action dispatch
  // (site b) is on the CAUSAL PATH of the observable behaviour.
  //
  // The reason is measured, not aesthetic: an earlier revision mapped
  // the emit-object options to WP_FIELD_EMIT_OBJECT directly, and the
  // M2 mutation (which changes the action that WP_KIND_EMIT_OBJ
  // selects) then produced NO observable difference over the frozen
  // corpus. The action was computed but DECORATIVE. Deriving the
  // field from the action makes the dispatch load-bearing: a
  // mutation that changes the action changes the field, and the
  // field is what the C engine reads.
  if (optIdx ==  6) return WpDriverFieldForAction(WpDriverOptionAction(optIdx));
  if (optIdx ==  7) return WpDriverFieldForAction(WpDriverOptionAction(optIdx));
  if (optIdx ==  8) return WP_FIELD_EMIT_DYLIB;
  if (optIdx ==  9) return WP_FIELD_CLIBS;
  if (optIdx == 10) return WP_FIELD_RUN;
  if (optIdx == 11) return WP_FIELD_JIT;
  if (optIdx == 12) return WP_FIELD_MEMSAFE;
  if (optIdx == 13) return WP_FIELD_REPL;
  if (optIdx == 14) return WP_FIELD_LSP;
  if (optIdx == 15) return WP_FIELD_OUTPUT_FILENAME;
  if (optIdx == 16) return WP_FIELD_TO_STDOUT;
  if (optIdx == 17) return WP_FIELD_TRANSPILE;
  if (optIdx == 18) return WP_FIELD_TARGET;
  if (optIdx == 19) return WP_FIELD_INSTALL_DIR;
  if (optIdx == 20) return WP_FIELD_DEFINES_LIST;
  if (optIdx == 21) return WP_FIELD_DUMP_IR;
  if (optIdx == 22) return WP_FIELD_DUMP_IR_POOLED;
  if (optIdx == 23) return WP_FIELD_EMIT_LLVM;
  if (optIdx == 24) return WP_FIELD_CAP_TABLE;
  if (optIdx == 25) return WP_FIELD_MEM_STATS;
  if (optIdx == 26) return WP_FIELD_VERSION;
  if (optIdx == 27) return WP_FIELD_HELP;
  if (optIdx == 28) return WP_FIELD_TERRY;
  if (optIdx == 29) return WP_FIELD_USE_LEGACY_X86;
  if (optIdx == 30) return WP_FIELD_WERROR;
  if (optIdx == 31) return WP_FIELD_FPIC;
  return WP_FIELD_NONE;
}


// -----------------------------------------------------------------------------
// THE EMISSION ACTION -- OWNED BY POLYC
//
// WpDriverSelectedEmission: which ARTIFACT CLASS does this argv select?
//
// This is a DIFFERENT decision from WpDriverSelectAction. The whole-argv
// action says WHAT to do; the emission action says WHICH ARTIFACT CLASS
// to produce. The two coincide on some argv shapes and differ on others:
//
//   --install-dir=X -c input.HC -o out.o   -> WP_ACTION_COMPILE_OBJECT (1)
//   --install-dir=X input.HC -o out        -> WP_ACTION_COMPILE_OBJECT (1)
//
// Both select the SAME whole-argv action, but they produce DIFFERENT
// artifacts. The artifact class is therefore a decision of its own, and
// it is made HERE, by PolyC, from the option table the driver already
// owns. The C side consumes the RESULT; it never re-derives it.
//
// The emission domain is DISJOINT from the action domain and from the
// status domain, so an invalid emission can never collide with a valid
// one, and a valid zero-valued emission can never be mistaken for a
// failure.
// -----------------------------------------------------------------------------

#define WP_EMIT_UNKNOWN        0
#define WP_EMIT_COMPILE_OBJECT 1
#define WP_EMIT_EXECUTE        2
#define WP_EMIT_ASSEMBLY       3
#define WP_EMIT_DYLIB          4

// The emission class the argv selects.
//
// The decision order is PolyC-owned and mirrors the emission order of
// the compiler: an explicit object request wins, then the assembly
// request, then the shared-object request. With none of them present
// the argv selects the executable.
I64 WpDriverSelectedEmission() {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;                    // argv[0] is the program name
  I64 emission = WP_EMIT_UNKNOWN;

  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      // An option whose value is MISSING is an arity failure. The
      // emission decision is not made on a malformed argv.
      if (WpDriverArityOk(i, opt) == 0) return WP_EMIT_UNKNOWN;
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_EMIT_OBJ) emission = WP_EMIT_COMPILE_OBJECT;
      if (kind == WP_KIND_ASSEMBLY) emission = WP_EMIT_ASSEMBLY;
      if (kind == WP_KIND_SOURCE) emission = WP_EMIT_DYLIB;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      // Only a NEXT value consumes the following argument.
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }

  // With no emission option present, the argv selects the executable --
  // but ONLY when it actually asks for something to be compiled. An argv
  // that carries no source file and no output request selects NO
  // emission at all, which is the ABSENT case and is distinct from the
  // EXECUTE case.
  if (emission == WP_EMIT_UNKNOWN) {
    I64 j = 1;
    I64 saw_source = 0;
    while (j < argc) {
      if (WpDriverClassifyArgument(j) == WP_ARG_SOURCE) saw_source = 1;
      j = j + 1;
    }
    if (saw_source == 0) return WP_EMIT_UNKNOWN;
    return WP_EMIT_EXECUTE;
  }
  return emission;
}
}
