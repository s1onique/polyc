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

// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.
//
// The `-o-` output target REQUIRES `-S`. This condition was, until
// this ACT, decided by the C side, because the status domain could
// not EXPRESS it. The C side therefore fired its own policy and
// PREEMPTED the PolyC-selected status: an argv whose PolyC status was
// USAGE reported the C policy's diagnostic instead.
//
// The status domain can express it now. The new member is the
// LARGEST value, so it is DISJOINT from every pre-existing status and
// it cannot be confused with a valid zero-valued status.
//
//   WP_STATUS_TO_STDOUT  the `-o-` output target was requested
//                        without `-S`
#define WP_STATUS_TO_STDOUT  6

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

// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02.
//
// WpDriverStdoutNeedsAssembly: was the `-o-` output target requested
// WITHOUT `-S`?
//
// The `-o-` option asks the compiler to write the ASSEMBLY to stdout,
// which is only meaningful together with `-S`. The live CLI enforced
// that pairing itself, which made the C side the owner of the
// decision and let it PREEMPT the PolyC-selected status.
//
// The driver already classifies both options -- `-S` is
// WP_KIND_ASSEMBLY and `-o-` is WP_KIND_STDOUT -- so the condition is
// decided here from the driver's OWN classification. No option table,
// no option name, no flag test and no arity rule is added.
//
// The condition does NOT depend on the selected action: the live CLI
// ran it after the option loop and before the unknown-argument
// report, so it fired whatever else the argv said.
I64 WpDriverStdoutNeedsAssembly() {
  I64 i = 1;                    // argv[0] is the program name
  I64 argc = WpDriverHostArgc();
  I64 saw_stdout = 0;
  I64 saw_assembly = 0;
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_STDOUT) saw_stdout = 1;
      if (kind == WP_KIND_ASSEMBLY) saw_assembly = 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      // Only a NEXT value consumes the following argument.
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }
  if (saw_stdout == 1 && saw_assembly == 0) return 1;
  return 0;
}

I64 WpDriverMapStatus(I64 action) {
  // The ARITY decision comes FIRST: an option whose value is missing
  // is an arity violation whatever else the argv says.
  if (WpDriverArityViolationCount() > 0) return WP_STATUS_ARITY;
  // The TO-STDOUT decision comes SECOND: the live CLI checked the
  // `-o-`/`-S` pairing right after the option loop and before it
  // reported the unknown arguments, so this condition fires whatever
  // else the argv says.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION02: this
  // decision used to live in the C side, where it could PREEMPT the
  // PolyC-selected status. It is the driver's decision now.
  if (WpDriverStdoutNeedsAssembly() == 1) return WP_STATUS_TO_STDOUT;
  // The UNKNOWN-ARGUMENT decision comes THIRD: the live CLI reports
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
//
// The priority is a property of the WHOLE argv. A later option does not
// overwrite an earlier higher-priority request. This preserves the C
// oracle's object > assembly > dylib > executable precedence without
// returning the semantic decision to C.
I64 WpDriverSelectedEmission() {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;                    // argv[0] is the program name
  I64 emission = WP_EMIT_UNKNOWN;
  I64 saw_object = 0;
  I64 saw_assembly = 0;
  I64 saw_dylib = 0;

  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      // An option whose value is MISSING is an arity failure. The
      // emission decision is not made on a malformed argv.
      if (WpDriverArityOk(i, opt) == 0) return WP_EMIT_UNKNOWN;
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_EMIT_OBJ) saw_object = 1;
      if (kind == WP_KIND_ASSEMBLY) saw_assembly = 1;
      if (kind == WP_KIND_SOURCE) saw_dylib = 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      // Only a NEXT value consumes the following argument.
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }

  // Apply the C oracle's whole-argv branch order after collecting the
  // requests. The first matching branch wins, so argument order cannot
  // change the selected artifact class.
  if (saw_object == 1) emission = WP_EMIT_COMPILE_OBJECT;
  if (saw_object == 0 && saw_assembly == 1) emission = WP_EMIT_ASSEMBLY;
  if (saw_object == 0 && saw_assembly == 0 && saw_dylib == 1) {
    emission = WP_EMIT_DYLIB;
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
// ---------------------------------------------------------------------------
// THE DRIVER PLAN -- OWNED BY POLYC
//
// ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
//
// The plan is the WHOLE-CLI route decision, as an ORDERED list of steps.
//
// WHY A LIST AND NOT A SINGLE ACTION: the live compiler's route is a
// SEQUENCE. The C main() selected it with a chain of independent
// `if (args.<flag>)` statements, in a fixed order, and the FIRST
// matching branch won. Modelling the route as a single action code
// would lose the ORDER, and the order is load-bearing: `-tokens` beats
// `-ast` beats the compile, and `-repl` beats all of them.
//
// The plan therefore reproduces the live order EXACTLY, as an explicit
// list of steps. The C host walks the list and executes each step's
// action; it never decides whether a step applies.
//
// THE PLAN IS DETERMINISTIC: the same argv always yields the same
// plan, in the same order, with the same indices.
// ---------------------------------------------------------------------------

// The plan step codes.
//
// These are DISJOINT from the WP_ACTION_* domain (which selects the
// whole-argv action) and from the WP_STATUS_* domain (which selects
// the diagnostic). A step code is never an action code and never a
// status code, so an out-of-domain step can never be confused with a
// valid one.
//
//   0  invalid / absent
//   1  ASSEMBLE       the .s input is assembled; the process ends
//   2  REPL           the REPL runs; the process ends
//   3  PRINT_TOKENS   the token stream is emitted; the process ends
//   4  TRANSPILE      the transpiled C is emitted; the process ends
//   5  PRINT_AST      the AST is printed; the process ends
//   6  DUMP_IR        the IR is dumped; the process ends
//   7  DUMP_IR_POOLED the pooled IR is dumped; the process ends
//   8  CFG            the CFG is constructed; the process ends
//   9  EMIT_LLVM      the LLVM IR is emitted; the process ends
//  10  JIT            the program is JIT-compiled and run
//  11  COMPILE        the compile proceeds to codegen and emission
//
#define WP_STEP_INVALID        0
#define WP_STEP_ASSEMBLE       1
#define WP_STEP_REPL           2
#define WP_STEP_PRINT_TOKENS   3
#define WP_STEP_TRANSPILE      4
#define WP_STEP_PRINT_AST      5
#define WP_STEP_DUMP_IR        6
#define WP_STEP_DUMP_IR_POOLED 7
#define WP_STEP_CFG            8
#define WP_STEP_EMIT_LLVM      9
#define WP_STEP_JIT           10
#define WP_STEP_COMPILE       11

// The maximum number of steps in a plan.
//
// The live route chain has at most ELEVEN mutually-exclusive branches,
// and only ONE of them is ever taken, so the plan never exceeds a
// handful of entries. The bound is generous and it is CHECKED.
#define WP_PLAN_MAX 32

// The plan's storage.
//
//   WP_PLAN_ACTION[i]  the step code
//   WP_PLAN_ARG[i]     the argument index that caused the step
//   WP_PLAN_COUNT      the number of steps
//
static I64 WP_PLAN_ACTION[WP_PLAN_MAX];
static I64 WP_PLAN_ARG[WP_PLAN_MAX];
static I64 WP_PLAN_COUNT;
static I64 WP_PLAN_COUNT;

// The step code for the option kind, or WP_STEP_INVALID when the kind
// does not select a route.
//
// The mapping is the live main() chain, in the live order.
//
// NOTE ON THE ASSEMBLY ROUTE. The live chain's FIRST branch tested
// args.assemble, and args.assemble is set by the FILE TYPE of the
// input -- a .s file -- NOT by an option. The `-S` option sets
// args.assemble_only, which is a different field: it selects the
// ARTIFACT CLASS (assembly instead of an object), and that decision
// belongs to WpDriverSelectedEmission.
//
// Mapping `-S` to the assemble route would make the driver assemble
// the .HC SOURCE file, which is exactly the defect the G0/G1
// differential caught: the compiler then ran `cc input.HC` and the
// link failed.
//
// So NO option selects the assemble route. Only a .s input does, and
// WpDriverFirstArgForStep finds it by FILE TYPE.
static I64 WpDriverStepForKind(I64 kind) {
  if (kind == WP_KIND_REPL)      return WP_STEP_REPL;
  if (kind == WP_KIND_TOKENS)    return WP_STEP_PRINT_TOKENS;
  if (kind == WP_KIND_TRANSPILE) return WP_STEP_TRANSPILE;
  if (kind == WP_KIND_AST)       return WP_STEP_PRINT_AST;
  if (kind == WP_KIND_DUMP_IR)   return WP_STEP_DUMP_IR;
  if (kind == WP_KIND_DUMP_IRP)  return WP_STEP_DUMP_IR_POOLED;
  if (kind == WP_KIND_CFG)       return WP_STEP_CFG;
  if (kind == WP_KIND_LLVM)      return WP_STEP_EMIT_LLVM;
  if (kind == WP_KIND_JIT)       return WP_STEP_JIT;
  return WP_STEP_INVALID;
}

// The PRIORITY of a route step.
//
// The live main() chain is a sequence of `if` statements, so the
// FIRST matching branch wins. This function gives each route step its
// position in that chain. A LOWER number wins.
//
// The chain, in the live source order:
//
//   assemble
//   repl
//   print_tokens
//   transpile
//   print_ast
//   dump_ir
//   dump_ir_pooled
//   emit_llvm
//   jit
//   cfg
//   compile           (the default: codegen and emission)
//
// The priority is what the driver compares. It is a DECISION, so it
// lives here and not in C.
static I64 WpDriverStepPriority(I64 step) {
  if (step == WP_STEP_ASSEMBLE)       return 10;
  if (step == WP_STEP_REPL)           return 20;
  if (step == WP_STEP_PRINT_TOKENS)   return 30;
  if (step == WP_STEP_TRANSPILE)      return 40;
  if (step == WP_STEP_PRINT_AST)      return 50;
  if (step == WP_STEP_DUMP_IR)        return 60;
  if (step == WP_STEP_DUMP_IR_POOLED) return 70;
  if (step == WP_STEP_EMIT_LLVM)      return 80;
  if (step == WP_STEP_JIT)            return 90;
  if (step == WP_STEP_CFG)            return 100;
  if (step == WP_STEP_COMPILE)        return 200;
  return 1000;
}

// Append one step to the plan. A plan that would overflow the bound is
// REJECTED: the count stops growing and the plan is marked invalid.
static U0 WpDriverPlanPush(I64 action, I64 argIdx) {
  if (WP_PLAN_COUNT >= WP_PLAN_MAX) return;
  WP_PLAN_ACTION[WP_PLAN_COUNT] = action;
  WP_PLAN_ARG[WP_PLAN_COUNT] = argIdx;
  WP_PLAN_COUNT = WP_PLAN_COUNT + 1;
}

// The FIRST argument index that requests the given route step, or -1.
//
// The scan is over the whole argv, in argv order, and it CONSUMES the
// option's value argument exactly as the live parser did, so that a
// value which happens to look like an option is not mistaken for one.
static I64 WpDriverFirstArgForStep(I64 step) {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;                    // argv[0] is the program name
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      if (WpDriverStepForKind(WpDriverOptKind(opt)) == step) return i;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    // A .s ARGUMENT selects the assemble step, exactly as the live
    // getASMFileName set args.assemble.
    if (step == WP_STEP_ASSEMBLE) {
      if (WpDriverClassifyFile(i) == WP_FILE_ASM) return i;
    }
    i = i + 1;
  }
  return -1;
}

// Does the argv request BOTH the LLVM emission and one of the modes it
// is mutually exclusive with?
//
// The live check was:
//
//   if (args.jit || args.repl || args.run || args.assemble_only ||
//       args.emit_object || args.emit_dylib || args.transpile || args.lsp)
//
// and the diagnostic was the "mutually exclusive" message.
//
// The DECISION is whether the combination is present, so it is the
// driver's. The C host only renders the message the driver chose.
I64 WpDriverEmitLlvmConflict() {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;
  // The legacy C condition was NESTED:
  //
  //   if (args.emit_llvm) {
  //     if (args.jit || args.repl || args.run || args.assemble_only ||
  //         args.emit_object || args.emit_dylib || args.transpile ||
  //         args.lsp)
  //     { ...conflict... }
  //   }
  //
  // The OUTER guard is part of the condition. A conflicting option
  // WITHOUT an --emit-llvm request is NOT a conflict: there is no LLVM
  // request to be exclusive with.
  //
  // This function previously flattened that nesting and dropped the
  // outer guard, so a plain `-c` or a plain `-S` reported
  // WP_STATUS_EMIT_LLVM_CONFLICT. The host only RENDERS that status on
  // the LLVM route, so the compiler's observable behaviour was masked;
  // the EXPORTED status was nevertheless wrong.
  //
  // The M-POLYC-CONFLICT-01 experiment measured the divergence from
  // the legacy C oracle directly, and the guard was restored.
  I64 saw_llvm = 0;
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_LLVM) saw_llvm = 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }
  if (saw_llvm == 0) return 0;

  i = 1;
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      I64 kind = WpDriverOptKind(opt);
      if (kind == WP_KIND_JIT) return 1;
      if (kind == WP_KIND_REPL) return 1;
      if (kind == WP_KIND_RUN) return 1;
      if (kind == WP_KIND_ASSEMBLY) return 1;
      if (kind == WP_KIND_EMIT_OBJ) return 1;
      if (kind == WP_KIND_SOURCE) return 1;
      if (kind == WP_KIND_TRANSPILE) return 1;
      if (kind == WP_KIND_LSP) return 1;
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    i = i + 1;
  }
  return 0;
}

// The STATUS for the emit-LLVM mutual-exclusion condition.
//
// The live compiler reported this condition with a dedicated
// diagnostic and exit status 1. The condition is now a DRIVER status,
// so the C host renders it from the status rather than deciding it.
//
// This status is DISJOINT from every pre-existing status: it is the
// LARGEST value, so it cannot collide with a valid status.
#define WP_STATUS_EMIT_LLVM_CONFLICT 7

// The FIRST argument that is a SOURCE file.
//
// The compile route acts on a source file, so the plan records which
// argument it acts on. The scan is in argv order.
//
// THE SCAN CONSUMES AN OPTION'S VALUE, exactly as the live parser
// did. An option whose value is the NEXT argument (for example -o,
// --install-dir, -lib, --target) hands that argument to the option,
// and a value that happens to end in ".HC" is NOT a source file. The
// scan therefore skips it, so the plan records the argument the
// compile route really acts on.
//
// The scan is only reached when NO option route won, so the argv has
// no route option at all; it can still carry the artifact and
// installation options.
static I64 WpDriverFirstSourceArg() {
  I64 argc = WpDriverHostArgc();
  I64 i = 1;                    // argv[0] is the program name
  while (i < argc) {
    I64 opt = WpDriverClassifyOption(i);
    if (opt >= 0) {
      I64 src = WpDriverValueSource(i, opt);
      i = i + 1;
      if (src == WP_VALUE_NEXT) i = i + 1;
      continue;
    }
    if (WpDriverClassifyFile(i) == WP_FILE_SOURCE) return i;
    i = i + 1;
  }
  return -1;
}

// Build the plan.
//
// The plan is rebuilt from scratch on every call, so a stale plan can
// never be observed.
//
// The plan holds the SELECTED ROUTE. It is built by finding, for each
// route kind, the FIRST argument that requests it, and then choosing
// the winning route by the live chain's priority.
//
// The build is deliberately CONSERVATIVE about the live chain's
// special cases:
//
//   * The live chain tested args.assemble -- which is set by the .s
//     file type, NOT by an option. The driver therefore looks for an
//     argument whose FILE TYPE is the assembly type.
//
//   * The live chain tested args.cfg_create, args.cfg_create_png and
//     args.cfg_create_svg as three separate flags that led to ONE
//     branch. The driver maps all three CFG option kinds to the ONE
//     CFG step, and keeps the PNG/SVG distinction in the CliArgs
//     fields, which the C host reads for the RENDERING choice.
static U0 WpDriverPlanBuild() {
  WP_PLAN_COUNT = 0;
  I64 i = 0;
  while (i < WP_PLAN_MAX) {
    WP_PLAN_ACTION[i] = WP_STEP_INVALID;
    WP_PLAN_ARG[i] = -1;
    i = i + 1;
  }

  // The winning route is the route with the LOWEST priority number
  // among the routes the argv requests.
  I64 best_step = WP_STEP_INVALID;
  I64 best_arg = -1;
  I64 best_prio = 10000;

  // The route steps, in the live chain's order. The order of this
  // list is the order of the live `if` chain.
  I64 steps[10];
  steps[0] = WP_STEP_ASSEMBLE;
  steps[1] = WP_STEP_REPL;
  steps[2] = WP_STEP_PRINT_TOKENS;
  steps[3] = WP_STEP_TRANSPILE;
  steps[4] = WP_STEP_PRINT_AST;
  steps[5] = WP_STEP_DUMP_IR;
  steps[6] = WP_STEP_DUMP_IR_POOLED;
  steps[7] = WP_STEP_EMIT_LLVM;
  steps[8] = WP_STEP_JIT;
  steps[9] = WP_STEP_CFG;

  i = 0;
  while (i < 10) {
    I64 step = steps[i];
    I64 arg = WpDriverFirstArgForStep(step);
    if (arg >= 0) {
      I64 prio = WpDriverStepPriority(step);
      if (prio < best_prio) {
        best_prio = prio;
        best_step = step;
        best_arg = arg;
      }
    }
    i = i + 1;
  }

  // NO OPTION ROUTE WON. The live chain fell through to the COMPILE
  // branch, so the driver selects the COMPILE route EXPLICITLY.
  //
  // This is not a cosmetic change. When the plan stayed EMPTY, the
  // selected route was WP_STEP_INVALID (0), which was
  // INDISTINGUISHABLE from "the driver selected nothing". The C
  // host's dispatch is a set of POSITIVE equality tests with an
  // implicit fall-through to compile, so an empty plan compiled
  // anyway: a FAIL-OPEN.
  //
  // The M-POLYC-POISON-04 plan-validity experiment measured exactly
  // that. The C guard now REJECTS WP_STEP_INVALID, and the driver
  // therefore MUST push a real route for every argv that reaches the
  // dispatch. The compile route is pushed here, with the SOURCE
  // argument it acts on.
  if (best_step == WP_STEP_INVALID) {
    I64 src = WpDriverFirstSourceArg();
    if (src < 0) return;          // no source: nothing to compile
    WpDriverPlanPush(WP_STEP_COMPILE, src);
    return;
  }
  WpDriverPlanPush(best_step, best_arg);
}

// The number of steps in the plan.
//
// The plan is built on demand, so a caller that asks for the count
// always gets the count of the CURRENT argv's plan.
I64 WpDriverPlanActionCount() {
  WpDriverPlanBuild();
  return WP_PLAN_COUNT;
}

// The step code at index `idx`, or WP_STEP_INVALID when the index is
// outside the plan.
//
// The index is DOMAIN CHECKED. An out-of-range index is a domain
// failure, not a silent zero that a caller could mistake for the
// FIRST step.
I64 WpDriverPlanActionAt(I64 idx) {
  WpDriverPlanBuild();
  if (idx < 0) return WP_STEP_INVALID;
  if (idx >= WP_PLAN_COUNT) return WP_STEP_INVALID;
  return WP_PLAN_ACTION[idx];
}

// The argument index that caused the step at index `idx`, or -1.
//
// The argument index is a VALIDATED INDEX into the host's argument
// vector. It is never a pointer, so no raw host pointer crosses the
// seam.
I64 WpDriverPlanArgAt(I64 idx) {
  WpDriverPlanBuild();
  if (idx < 0) return -1;
  if (idx >= WP_PLAN_COUNT) return -1;
  return WP_PLAN_ARG[idx];
}

// The SELECTED ROUTE, as a single code.
//
// This is the one-step view of the plan: the route the argv selects.
// It is 0 when the argv selects no route.
//
// It is the accessor the C host uses to dispatch, and it is derived
// FROM THE PLAN, so the plan and the dispatch can never disagree.
I64 WpDriverSelectedRoute() {
  WpDriverPlanBuild();
  if (WP_PLAN_COUNT < 1) return WP_STEP_INVALID;
  return WP_PLAN_ACTION[0];
}

// The status for the WHOLE argv, INCLUDING the emit-LLVM conflict
// status.
//
// The conflict is checked AFTER the three post-loop checks, because
// the live compiler reached the emit-llvm branch only when those
// checks had already succeeded.
I64 WpDriverPlanStatus() {
  I64 status = WpDriverMapStatus(WpDriverSelectAction());
  if (status != WP_STATUS_OK) return status;
  if (WpDriverEmitLlvmConflict() == 1) return WP_STATUS_EMIT_LLVM_CONFLICT;
  return status;
}
}
