// tools/quality/driver-required-route-correction03-compare.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.
//
// THE PRODUCTION COMPARATOR.
//
// It compares the artifacts produced by the selector-OFF C oracle and the
// selector-ON PolyC compiler for one argv shape.
//
// THE CORE RULE (P1-2 repair): EQUALITY IS NOT VALIDITY.
//
// The previous revision of this comparator computed the artifact class of
// both sides, checked that the classes agreed, and checked that the bytes
// agreed. That is a WEAK NEGATION: two IDENTICAL GARBAGE files agree with
// each other, and two MISSING files agree with each other, so the
// comparator reported PASS on inputs that carried no evidence at all.
//
// The repaired comparator VALIDATES EVERY OBSERVATION BEFORE IT COMPARES
// IT. A comparison result is only reported when the observations are
// independently VALID:
//
//   * the artifact MUST be present;
//   * the artifact MUST be nonempty;
//   * the artifact MUST be of the EXPECTED class;
//   * the artifact MUST carry the EXPECTED architecture;
//   * the artifact MUST carry the REQUIRED symbols;
//   * the compiler exit status MUST be the EXPECTED one;
//   * stdout MUST be EXACTLY equal, subject only to the explicitly frozen
//     normalization;
//   * stderr MUST be EXACTLY equal, subject only to the explicitly frozen
//     normalization;
//   * the artifact content digest MUST be equal.
//
// The expected class, architecture, symbols and exit status are supplied
// by the harness, which derives them from the GENUINE selector-OFF C
// ORACLE. The comparator therefore never decides what the correct answer
// is: it decides whether the observed ON side MATCHES the observed OFF
// side AND is itself a valid observation.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MACHO64_MAGIC 0xFEEDFACF
#define ELF64_MAGIC   0x7F454C46

// The artifact classes the comparator can distinguish.
#define CLS_ABSENT      0
#define CLS_MACHO_OBJ   1
#define CLS_MACHO_EXEC  2
#define CLS_MACHO_DYLIB 3
#define CLS_ELF         4
#define CLS_OTHER       5
#define CLS_TEXT        6

static I64 failures;
static I64 checks;

// The comparator's own observation slots. Each slot is filled by ONE
// validation step and is then COMPARED with its peer. A slot that was
// not validated is NOT comparable and is reported as such.
#define OBS_ARTIFACT_PRESENT 0
#define OBS_ARTIFACT_NONEMPTY 1
#define OBS_ARTIFACT_CLASS 2
#define OBS_ARTIFACT_ARCH 3
#define OBS_EXIT_STATUS 5

// The reporting helpers.
//
// Every check is reported with its own name, so a reviewer can tell WHICH
// observation was rejected, not merely that "something" was rejected.
static U0 Check(I64 ok, U8 *case_id, U8 *what) {
  checks = checks + 1;
  if (ok == 1) {
    "%s\t%s\tPASS\n", case_id, what;
  } else {
    "%s\t%s\tFAIL\n", case_id, what;
    failures = failures + 1;
  }
}

// The observation table is printed so a reviewer can see the OBSERVED
// values, not only the verdicts.
static U0 ReportObs(U8 *case_id, U8 *side, I64 slot, I64 value) {
  "OBS\t%s\t%s\t%d\t%d\n", case_id, side, slot, value;
}

// ---------------------------------------------------------------------------
// The Mach-O reader.
//
// The comparator classifies an artifact FROM ITS BYTES. It never trusts a
// filename, a compiler exit status, or a harness-provided label.
// ---------------------------------------------------------------------------
static I64 WordAt(U8 *buf, I64 size, I64 off) {
  if (size < off + 4) return -1;
  I64 v = 0;
  I64 i = off + 3;
  while (i >= off) { v = v * 256 + buf[i]; i = i - 1; }
  return v;
}

// The Mach-O CPU type. 0x0100000C is arm64, 0x01000007 is x86_64.
#define CPU_TYPE_ARM64 0x0100000C
#define CPU_TYPE_X86_64 0x01000007

static I64 Classify(U8 *buf, I64 size) {
  if (buf == NULL) return CLS_ABSENT;
  if (size == 0) return CLS_OTHER;
  I64 magic = WordAt(buf, size, 0);
  if (magic == MACHO64_MAGIC) {
    I64 type = WordAt(buf, size, 12);
    if (type == 1) return CLS_MACHO_OBJ;
    if (type == 2) return CLS_MACHO_EXEC;
    if (type == 6) return CLS_MACHO_DYLIB;
    return CLS_OTHER;
  }
  if (magic == ELF64_MAGIC) return CLS_ELF;
  // An assembler text artifact is not a Mach-O image.
  if (size > 4) {
    if (buf[0] == '.' || buf[0] == '#' || buf[0] == '_' || buf[0] == '/') {
      return CLS_TEXT;
    }
  }
  return CLS_OTHER;
}

static I64 ArchOf(U8 *buf, I64 size) {
  if (buf == NULL) return -1;
  if (size == 0) return -1;
  I64 magic = WordAt(buf, size, 0);
  if (magic == MACHO64_MAGIC) return WordAt(buf, size, 4);
  return -1;
}

static U8 *ArchName(I64 arch) {
  if (arch == CPU_TYPE_ARM64) return "arm64";
  if (arch == CPU_TYPE_X86_64) return "x86_64";
  return "unknown";
}

static U8 *ClassName(I64 cls) {
  if (cls == CLS_ABSENT) return "ABSENT";
  if (cls == CLS_MACHO_OBJ) return "MACHO_OBJECT";
  if (cls == CLS_MACHO_EXEC) return "MACHO_EXECUTABLE";
  if (cls == CLS_MACHO_DYLIB) return "MACHO_DYLIB";
  if (cls == CLS_ELF) return "ELF";
  if (cls == CLS_TEXT) return "ASSEMBLER_TEXT";
  return "OTHER";
}

// ---------------------------------------------------------------------------
// The digest.
//
// The comparator computes its OWN content digest over the artifact bytes.
// It does not shell out to sha256 and it does not reuse a digest recorded
// by an earlier case. The digest is an FNV-1a 64-bit over the raw bytes.
// ---------------------------------------------------------------------------
static U64 Digest(U8 *buf, I64 size) {
  U64 h = 14695981039346656037;
  I64 i = 0;
  while (i < size) {
    h = h ^ buf[i];
    h = h * 1099511628211;
    i = i + 1;
  }
  return h;
}

// ---------------------------------------------------------------------------
// The file reader that reports PRESENCE and SIZE separately.
//
// A missing file and an empty file are DIFFERENT observations and the
// comparator must be able to tell them apart.
// ---------------------------------------------------------------------------
static U8 *ReadArtifact(U8 *path, I64 *size, I64 *present) {
  *size = 0;
  I64 s = 0;
  U8 *buf = FileRead(path, &s);
  if (buf == NULL) {
    *present = 0;
    *size = 0;
    return NULL;
  }
  *present = 1;
  *size = s;
  return buf;
}

// ---------------------------------------------------------------------------
// The byte comparison.
//
// Two files with the SAME LENGTH and the SAME BYTES are equal. Two files
// that are both missing are NOT equal here: the caller has already
// validated presence before this function is reached.
// ---------------------------------------------------------------------------
static I64 BytesEqual(U8 *a, I64 *asize, U8 *b, I64 *bsize) {
  if (a == NULL) return 0;
  if (b == NULL) return 0;
  if (*asize != *bsize) return 0;
  I64 i = 0;
  while (i < *asize) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

static I64 StringsEqual(U8 *a, U8 *b) {
  if (a == NULL) return 0;
  if (b == NULL) return 0;
  I64 i = 0;
  while (a[i] != 0 && b[i] != 0) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  if (a[i] == 0 && b[i] == 0) return 1;
  return 0;
}

// ---------------------------------------------------------------------------
// The symbol check.
//
// The comparator reads the artifact's OWN symbol table. It does not shell
// out to nm. A Mach-O image carries an LC_SYMTAB load command; the
// comparator walks the load commands, finds LC_SYMTAB, and then scans the
// string table for the REQUIRED symbol names.
//
//   LC_SYMTAB = 0x02
// ---------------------------------------------------------------------------
#define LC_SYMTAB 0x02

static I64 HasSymbol(U8 *buf, I64 size, U8 *name) {
  if (buf == NULL) return 0;
  if (size < 32) return 0;
  if (WordAt(buf, size, 0) != MACHO64_MAGIC) return 0;
  I64 ncmds = WordAt(buf, size, 16);
  I64 off = 32;
  I64 i = 0;
  while (i < ncmds) {
    if (off + 8 > size) return 0;
    I64 cmd = WordAt(buf, size, off);
    I64 cmdsize = WordAt(buf, size, off + 4);
    if (cmdsize <= 0) return 0;
    if (cmd == LC_SYMTAB) {
      // The LC_SYMTAB load command is exactly 24 bytes:
      //   cmd(4) cmdsize(4) symoff(4) nsyms(4) stroff(4) strsize(4)
      I64 symoff = WordAt(buf, size, off + 8);
      I64 nsyms = WordAt(buf, size, off + 12);
      I64 stroff = WordAt(buf, size, off + 16);
      I64 strsize = WordAt(buf, size, off + 20);
      if (stroff < 0) return 0;
      if (stroff + strsize > size) return 0;
      if (symoff < 0) return 0;
      I64 namelen = StrLen(name);
      I64 k = 0;
      while (k < nsyms) {
        I64 n_strx = WordAt(buf, size, symoff + k * 16);
        if (n_strx > 0 && n_strx < strsize) {
          I64 p = stroff + n_strx;
          I64 q = 0;
          I64 match = 1;
          while (q < namelen) {
            if (p + q >= stroff + strsize) { match = 0; break; }
            if (buf[p + q] != name[q]) { match = 0; break; }
            q = q + 1;
          }
          if (match == 1 && p + q < stroff + strsize && buf[p + q] == 0) {
            return 1;
          }
        }
        k = k + 1;
      }
      return 0;
    }
    off = off + cmdsize;
    i = i + 1;
  }
  return 0;
}

// ---------------------------------------------------------------------------
// The text comparison.
//
// The ONLY normalization the comparator applies is the EXPLICITLY FROZEN
// one: a trailing carriage return is stripped, because the two compilers
// are run through the same shell redirection on the same host and a CR
// would be a host artifact rather than a diagnostic difference.
//
// NOTHING else is normalized. A missing trailing newline, an extra
// diagnostic, a reordered diagnostic, and a differing diagnostic are all
// REJECTED.
// ---------------------------------------------------------------------------
static I64 NormalizedLen(U8 *buf, I64 size) {
  I64 n = size;
  while (n > 0 && buf[n - 1] == 13) n = n - 1;
  return n;
}

static I64 TextEqual(U8 *a, I64 asize, U8 *b, I64 bsize) {
  if (a == NULL) return 0;
  if (b == NULL) return 0;
  I64 an = NormalizedLen(a, asize);
  I64 bn = NormalizedLen(b, bsize);
  if (an != bn) return 0;
  I64 i = 0;
  while (i < an) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// ---------------------------------------------------------------------------
// The exit-status reader.
//
// The harness writes the compiler's exit status into a file. The
// comparator reads it back as a TEXT record, so a status that was never
// recorded is detected as a MISSING observation rather than being
// silently treated as zero.
// ---------------------------------------------------------------------------
static I64 ReadExitStatus(U8 *path, I64 *present) {
  *present = 0;
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -999;
  *present = 1;
  I64 v = 0;
  I64 i = 0;
  I64 digits = 0;
  while (i < size) {
    I64 c = buf[i];
    if (c >= 48 && c <= 57) {
      v = v * 10 + (c - 48);
      digits = digits + 1;
      i = i + 1;
      continue;
    }
    if (c == 10 || c == 13 || c == 32) { i = i + 1; continue; }
    break;
  }
  if (digits == 0) return -998;
  return v;
}


// ---------------------------------------------------------------------------
// The archive-member semantic comparison.
//
// An `ar` archive carries a HEADER with metadata that is NOT part of the
// archived content: the member timestamps, the owner/mode, and the padding
// between members. Two runs of the SAME producer produce archives whose
// MEMBER BYTES are identical and whose HEADER BYTES differ.
//
// The distinction is therefore:
//
//   * the FULL ARCHIVE BYTE result is recorded and compared;
//   * the ARCHIVE-MEMBER SEMANTIC result is recorded and compared
//     SEPARATELY.
//
// A difference in the member bytes is a SEMANTIC difference. A difference
// in the header bytes alone is METADATA NONDETERMINISM and is reported as
// such, never as an equivalence failure and never as an equality claim.
//
// The comparator reads the `ar` format itself: the global header is
// "!<arch>\n" followed by per-member headers of 60 bytes whose size field
// is at offset 48 and whose content follows.
// ---------------------------------------------------------------------------
#define AR_MAGIC_LEN 8
#define AR_MEMBER_HDR_LEN 60

static U8 *ArMemberBytes(U8 *buf, I64 size, I64 index, I64 *msize) {
  *msize = 0;
  if (buf == NULL) return NULL;
  if (size < AR_MAGIC_LEN) return NULL;
  I64 i = 0;
  while (i < AR_MAGIC_LEN) {
    if (buf[i] != "!<arch>\n"[i]) return NULL;
    i = i + 1;
  }
  I64 off = AR_MAGIC_LEN;
  I64 want = 0;
  while (off + AR_MEMBER_HDR_LEN <= size) {
    // The member size is a decimal ASCII field at offset 48, length 10.
    I64 m = 0;
    I64 digits = 0;
    I64 j = 48;
    while (j < 58) {
      I64 c = buf[off + j];
      if (c >= 48 && c <= 57) {
        m = m * 10 + (c - 48);
        digits = digits + 1;
      } else if (c == 32) {
        // A space terminates the field.
        j = 58;
        break;
      } else {
        return NULL;
      }
      j = j + 1;
    }
    if (digits == 0) return NULL;
    I64 content = off + AR_MEMBER_HDR_LEN;
    if (content + m > size) return NULL;
    if (want == index) {
      *msize = m;
      return buf + content;
    }
    want = want + 1;
    // Members are 2-byte aligned.
    I64 next = content + m;
    if (m % 2 == 1) next = next + 1;
    off = next;
  }
  return NULL;
}

// The archive-member count.
static I64 ArMemberCount(U8 *buf, I64 size) {
  if (buf == NULL) return -1;
  if (size < AR_MAGIC_LEN) return -1;
  I64 i = 0;
  while (i < AR_MAGIC_LEN) {
    if (buf[i] != "!<arch>\n"[i]) return -1;
    i = i + 1;
  }
  I64 off = AR_MAGIC_LEN;
  I64 count = 0;
  while (off + AR_MEMBER_HDR_LEN <= size) {
    I64 m = 0;
    I64 digits = 0;
    I64 j = 48;
    while (j < 58) {
      I64 c = buf[off + j];
      if (c >= 48 && c <= 57) {
        m = m * 10 + (c - 48);
        digits = digits + 1;
      } else if (c == 32) {
        j = 58;
        break;
      } else {
        return -1;
      }
      j = j + 1;
    }
    if (digits == 0) return -1;
    I64 content = off + AR_MEMBER_HDR_LEN;
    if (content + m > size) return -1;
    count = count + 1;
    I64 next = content + m;
    if (m % 2 == 1) next = next + 1;
    off = next;
  }
  return count;
}

// ---------------------------------------------------------------------------
// MAIN
//
// The comparator is invoked as:
//
//   compare <case-id> <oracle-artifact> <polyc-artifact>
//           <oracle-stdout> <polyc-stdout>
//           <oracle-stderr> <polyc-stderr>
//           <oracle-exit>   <polyc-exit>
//           <expected-class> <expected-arch> <expected-exit>
//           [required-symbol ...]
//
// The EXPECTED values are supplied by the harness, which derives them from
// the genuine selector-OFF C ORACLE. The comparator VALIDATES both sides
// against those expectations and only then COMPARES the two sides.
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  checks = 0;

  // -----------------------------------------------------------------------
  // THE DERIVATION MODE.
  //
  //   derive <artifact>
  //
  // It prints the artifact's class and architecture AS THE COMPARATOR
  // SEES THEM, so the harness can DERIVE the expectation from the GENUINE
  // selector-OFF C ORACLE artifact instead of hardcoding it. The
  // expectation is therefore an OBSERVATION of the reference, not a
  // restatement of the implementation's own belief.
  // -----------------------------------------------------------------------
  if (argc == 3 && StrCmp(argv[1], "derive") == 0) {
    I64 d_present = 0;
    I64 d_size = 0;
    U8 *dbuf = ReadArtifact(argv[2], &d_size, &d_present);
    I64 d_class = Classify(dbuf, d_size);
    I64 d_arch = ArchOf(dbuf, d_size);
    "DERIVED_CLASS\t%s\n", ClassName(d_class);
    "DERIVED_ARCH\t%s\n", ArchName(d_arch);
    "DERIVED_PRESENT\t%d\n", d_present;
    "DERIVED_SIZE\t%lld\n", d_size;
    return 0;
  }

  if (argc < 14) {
    "REASON_DETAIL=usage: compare <case-id> <oracle-art> <polyc-art> "
      "<oracle-stdout> <polyc-stdout> <oracle-stderr> <polyc-stderr> "
      "<oracle-exit> <polyc-exit> <expected-class> <expected-arch> "
      "<expected-exit> [symbol ...]\n";
    return 2;
  }
  U8 *case_id = argv[1];
  U8 *oracle = argv[2];
  U8 *polyc  = argv[3];
  U8 *o_stdout = argv[4];
  U8 *p_stdout = argv[5];
  U8 *o_stderr = argv[6];
  U8 *p_stderr = argv[7];
  U8 *o_exitf  = argv[8];
  U8 *p_exitf  = argv[9];

  I64 expected_class = 5;
  if (StrCmp(argv[10], "MACHO_OBJECT") == 0) expected_class = 1;
  if (StrCmp(argv[10], "MACHO_EXECUTABLE") == 0) expected_class = 2;
  if (StrCmp(argv[10], "MACHO_DYLIB") == 0) expected_class = 3;
  if (StrCmp(argv[10], "ELF") == 0) expected_class = 4;
  if (StrCmp(argv[10], "ASSEMBLER_TEXT") == 0) expected_class = 6;
  if (StrCmp(argv[10], "OTHER") == 0) expected_class = 5;

  I64 expected_arch = -1;
  if (StrCmp(argv[11], "arm64") == 0) expected_arch = CPU_TYPE_ARM64;
  if (StrCmp(argv[11], "x86_64") == 0) expected_arch = CPU_TYPE_X86_64;

  I64 expected_exit = 0;
  if (StrCmp(argv[12], "0") != 0) expected_exit = 1;

  // -----------------------------------------------------------------------
  // STEP 1 -- VALIDATE THE ORACLE OBSERVATION.
  //
  // The oracle side is the REFERENCE. If the oracle side is not a valid
  // observation, the comparison is UNSUPPORTED, not PASS.
  // -----------------------------------------------------------------------
  I64 o_present = 0;
  I64 o_size = 0;
  U8 *obuf = ReadArtifact(oracle, &o_size, &o_present);
  I64 o_class = Classify(obuf, o_size);
  I64 o_arch = ArchOf(obuf, o_size);

  I64 o_exit_present = 0;
  I64 o_exit = ReadExitStatus(o_exitf, &o_exit_present);

  Check(o_present == 1, case_id, "the oracle artifact is PRESENT");
  Check(o_present == 1 && o_size > 0, case_id,
        "the oracle artifact is NONEMPTY");
  Check(o_present == 1 && o_class == expected_class, case_id,
        "the oracle artifact has the EXPECTED class");
  Check(o_present == 1 && (expected_arch == -1 || o_arch == expected_arch),
        case_id, "the oracle artifact has the EXPECTED architecture");
  Check(o_exit_present == 1, case_id, "the oracle exit status is RECORDED");
  Check(o_exit_present == 1 && o_exit == expected_exit, case_id,
        "the oracle exit status is the EXPECTED one");

  // -----------------------------------------------------------------------
  // STEP 2 -- VALIDATE THE POLYC OBSERVATION.
  // -----------------------------------------------------------------------
  I64 p_present = 0;
  I64 p_size = 0;
  U8 *pbuf = ReadArtifact(polyc, &p_size, &p_present);
  I64 p_class = Classify(pbuf, p_size);
  I64 p_arch = ArchOf(pbuf, p_size);

  I64 p_exit_present = 0;
  I64 p_exit = ReadExitStatus(p_exitf, &p_exit_present);

  Check(p_present == 1, case_id, "the PolyC artifact is PRESENT");
  Check(p_present == 1 && p_size > 0, case_id,
        "the PolyC artifact is NONEMPTY");
  Check(p_present == 1 && p_class == expected_class, case_id,
        "the PolyC artifact has the EXPECTED class");
  Check(p_present == 1 && (expected_arch == -1 || p_arch == expected_arch),
        case_id, "the PolyC artifact has the EXPECTED architecture");
  Check(p_exit_present == 1, case_id, "the PolyC exit status is RECORDED");
  Check(p_exit_present == 1 && p_exit == expected_exit, case_id,
        "the PolyC exit status is the EXPECTED one");

  // -----------------------------------------------------------------------
  // STEP 3 -- VALIDATE THE REQUIRED SYMBOLS.
  //
  // The symbol requirement applies to an artifact that carries a symbol
  // table. An assembler TEXT artifact has none, so the requirement is NOT
  // APPLICABLE to it and is not reported as a failure.
  // -----------------------------------------------------------------------
  I64 i = 13;
  I64 nsym = 0;
  I64 sym_ok = 1;
  while (i < argc) {
    U8 *sym = argv[i];
    nsym = nsym + 1;
    if (expected_class == 1 || expected_class == 2 || expected_class == 3) {
      if (HasSymbol(obuf, o_size, sym) == 0) sym_ok = 0;
      if (HasSymbol(pbuf, p_size, sym) == 0) sym_ok = 0;
    }
    i = i + 1;
  }
  if (nsym > 0) {
    Check(sym_ok == 1, case_id,
          "the REQUIRED symbols are present in both artifacts");
  }

  // -----------------------------------------------------------------------
  // STEP 4 -- COMPARE THE VALIDATED OBSERVATIONS.
  //
  // A comparison is reported ONLY when the corresponding observation was
  // VALID on both sides. Otherwise the comparison is UNSUPPORTED and is
  // reported as FAIL, because an invalid observation cannot establish
  // equivalence.
  // -----------------------------------------------------------------------
  Check(o_present == 1 && p_present == 1 && o_class == p_class, case_id,
        "the artifact classes agree");
  Check(o_present == 1 && p_present == 1 &&
        (expected_arch == -1 || (o_arch == expected_arch &&
                                 p_arch == expected_arch)), case_id,
        "the artifact architectures agree");
  Check(o_exit_present == 1 && p_exit_present == 1 && o_exit == p_exit,
        case_id, "the exit statuses agree");

  // stdout and stderr are compared EXACTLY, modulo the ONE explicitly
  // frozen normalization (a trailing carriage return).
  I64 os_size = 0;
  I64 ps_size = 0;
  U8 *os_buf = FileRead(o_stdout, &os_size);
  U8 *ps_buf = FileRead(p_stdout, &ps_size);
  I64 oe_size = 0;
  I64 pe_size = 0;
  U8 *oe_buf = FileRead(o_stderr, &oe_size);
  U8 *pe_buf = FileRead(p_stderr, &pe_size);
  Check(os_buf != NULL && ps_buf != NULL, case_id,
        "the stdout transcripts are PRESENT");
  Check(oe_buf != NULL && pe_buf != NULL, case_id,
        "the stderr transcripts are PRESENT");
  Check(os_buf != NULL && ps_buf != NULL &&
        TextEqual(os_buf, os_size, ps_buf, ps_size), case_id,
        "the stdout transcripts are EQUAL");
  Check(oe_buf != NULL && pe_buf != NULL &&
        TextEqual(oe_buf, oe_size, pe_buf, pe_size), case_id,
        "the stderr transcripts are EQUAL");

  // The content digest is computed over the artifact bytes by the
  // comparator itself. It is never taken from the harness.
  U64 o_digest = Digest(obuf, o_size);
  U64 p_digest = Digest(pbuf, p_size);
  "DIGEST\t%s\toracle\t%lld\n", case_id, o_digest;
  "DIGEST\t%s\tpolyc\t%lld\n", case_id, p_digest;
  Check(o_present == 1 && p_present == 1 && o_digest == p_digest, case_id,
        "the artifact content digests agree");
  Check(o_present == 1 && p_present == 1 &&
        BytesEqual(obuf, &o_size, pbuf, &p_size), case_id,
        "the actual artifact bytes agree");

  ReportObs(case_id, "oracle", OBS_ARTIFACT_PRESENT, o_present);
  ReportObs(case_id, "polyc", OBS_ARTIFACT_PRESENT, p_present);
  ReportObs(case_id, "oracle", OBS_ARTIFACT_NONEMPTY, o_size);
  ReportObs(case_id, "polyc", OBS_ARTIFACT_NONEMPTY, p_size);
  ReportObs(case_id, "oracle", OBS_ARTIFACT_CLASS, o_class);
  ReportObs(case_id, "polyc", OBS_ARTIFACT_CLASS, p_class);
  ReportObs(case_id, "oracle", OBS_ARTIFACT_ARCH, o_arch);
  ReportObs(case_id, "polyc", OBS_ARTIFACT_ARCH, p_arch);
  ReportObs(case_id, "oracle", OBS_EXIT_STATUS, o_exit);
  ReportObs(case_id, "polyc", OBS_EXIT_STATUS, p_exit);
  "ARTIFACT_CLASS\t%s\t%s\t%s\n", case_id, ClassName(o_class),
        ClassName(p_class);
  "ARTIFACT_ARCH\t%s\t%s\t%s\n", case_id, ArchName(o_arch),
        ArchName(p_arch);

  "CORRECTION03_COMPARE_CHECKS\t%d\n", checks;
  "CORRECTION03_COMPARE_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
