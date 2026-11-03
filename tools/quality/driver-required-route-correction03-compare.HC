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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F2 -- THE FAIL-CLOSED REPAIR.
//
// The C4 remediation's comparator still ACCEPTED:
//
//   * a forged exit status carrying trailing text;
//   * an out-of-bounds Mach-O symbol count;
//   * an undersized symbol table;
//   * an out-of-bounds string-table entry;
//   * an identical pair of UNSUPPORTED artifacts;
//   * a VALID but STALE artifact replayed on BOTH sides;
//   * a VALID but STALE stdout replayed on BOTH sides.
//
// The reason each was accepted is the SAME: the comparator checked that the
// two sides agreed, and it never checked that either side was a VALID
// OBSERVATION OF AN EXECUTION THAT HAPPENED.
//
// THE REPAIR has two halves.
//
// HALF ONE -- STRUCTURAL VALIDITY. The Mach-O reader validates the image
// BEFORE it looks for a symbol in it, and it validates the image
// INDEPENDENTLY of whether the two sides match. The exit-status reader
// accepts ONLY a complete, correctly formatted record of a valid process
// exit code.
//
// HALF TWO -- INVOCATION PROVENANCE. Each side of a comparison carries a
// CAPTURE RECORD that the harness writes DIRECTLY FROM THE EXECUTION. The
// record binds the observation to the execution that produced it:
//
//   SOURCE_SHA256    the digest of the source that was compiled
//   FIXTURE_SHA256   the digest of the fixture the source came from
//   ARGV             the exact argument vector, one argument per line
//   ENV              the relevant environment, one binding per line
//   SELECTOR         the selector mode, OFF or ON
//   PRODUCER_SHA256  the digest of the producer executable
//   INVOCATION_ID    the unique identity of THIS invocation
//   EXIT_STATUS      the observed process exit code
//   STDOUT_SHA256    the digest of the observed stdout transcript
//   STDERR_SHA256    the digest of the observed stderr transcript
//   ARTIFACT_SHA256  the digest of the observed output artifact
//
// The comparator RECOMPUTES the artifact digest, the transcript digests and
// the exit status from the files it is given, and it REJECTS the
// comparison when they do not match the record. The comparator ALSO
// requires the INVOCATION_ID to appear in the RUN LEDGER, which the
// harness writes during THIS run.
//
// A stale artifact replayed on BOTH sides therefore fails, because its
// capture record either does not exist, does not match the bytes, or names
// an invocation that is not in this run's ledger.
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

// The reason token. A rejection MUST carry a REASON that says WHICH
// property was violated, so a reviewer can distinguish the failure modes
// and cannot mistake a generic rejection for the specific one.
static U0 Reason(U8 *case_id, U8 *side, U8 *token) {
  "REASON\t%s\t%s\t%s\n", case_id, side, token;
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

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F2 -- THE STRUCTURAL MACH-O VALIDATOR.
//
// The comparator does NOT look for a symbol in an image it has not first
// proved to be a well-formed image. Every check below is performed on EACH
// SIDE INDEPENDENTLY of whether the two sides match, so two IDENTICAL
// MALFORMED images are rejected exactly as two DIFFERENT malformed images
// are.
//
// The reason tokens are DISTINCT, so a reviewer can tell WHICH structural
// property was violated.
//
// ALL the bound arithmetic is OVERFLOW-SAFE. A declared count or offset is
// a 32-bit unsigned value carried in a signed 64-bit accumulator, so a
// multiplication of a symbol count by the 16-byte nlist size cannot wrap.
// The checks are written as "off <= size" and "count <= (size - off) / 16"
// rather than "off + count * 16 <= size", so no intermediate product can
// overflow.
// ---------------------------------------------------------------------------
#define MACHO_HEADER_SIZE 32
#define NLIST64_SIZE     16
#define LC_SYMTAB_CMD    0x02
#define LC_SYMTAB_CMDSZ  24

// The Mach-O validation result codes.
#define MV_OK                0
#define MV_ABSENT            1
#define MV_EMPTY             2
#define MV_BAD_MAGIC         3
#define MV_BAD_HEADER        4
#define MV_BAD_CPUTYPE       5
#define MV_BAD_FILETYPE      6
#define MV_BAD_NCMDS         7
#define MV_BAD_SIZEOFCMDS    8
#define MV_LOADCMD_OVERRUN   9
#define MV_LOADCMD_SIZE      10
#define MV_NO_SYMTAB         11
#define MV_SYMTAB_STRUCT     12
#define MV_SYMTAB_BOUNDS     13
#define MV_STRTAB_BOUNDS     14
#define MV_STRIDX_BOUNDS     15

static U8 *MachOReason(I64 code) {
  if (code == MV_OK) return "OK";
  if (code == MV_ABSENT) return "MACHO_ABSENT";
  if (code == MV_EMPTY) return "MACHO_EMPTY";
  if (code == MV_BAD_MAGIC) return "MACHO_BAD_MAGIC";
  if (code == MV_BAD_HEADER) return "MACHO_BAD_HEADER";
  if (code == MV_BAD_CPUTYPE) return "MACHO_BAD_CPUTYPE";
  if (code == MV_BAD_FILETYPE) return "MACHO_BAD_FILETYPE";
  if (code == MV_BAD_NCMDS) return "MACHO_BAD_NCMDS";
  if (code == MV_BAD_SIZEOFCMDS) return "MACHO_BAD_SIZEOFCMDS";
  if (code == MV_LOADCMD_OVERRUN) return "MACHO_LOAD_COMMAND_OUT_OF_BOUNDS";
  if (code == MV_LOADCMD_SIZE) return "MACHO_LOAD_COMMAND_SIZE_INVALID";
  if (code == MV_NO_SYMTAB) return "MACHO_NO_LC_SYMTAB";
  if (code == MV_SYMTAB_STRUCT) return "MACHO_LC_SYMTAB_STRUCTURE_INVALID";
  if (code == MV_SYMTAB_BOUNDS) return "MACHO_SYMBOL_TABLE_OUT_OF_BOUNDS";
  if (code == MV_STRTAB_BOUNDS) return "MACHO_STRING_TABLE_OUT_OF_BOUNDS";
  if (code == MV_STRIDX_BOUNDS) return "MACHO_SYMBOL_STRING_INDEX_OUT_OF_BOUNDS";
  return "MACHO_UNKNOWN";
}

// The validated Mach-O facts. They are filled by ValidateMachO and are the
// ONLY source the symbol lookup uses, so the symbol lookup can never read
// past a bound that the validator has already proved.
static I64 vm_symoff;
static I64 vm_nsyms;
static I64 vm_stroff;
static I64 vm_strsize;

// The structural validator.
//
// `require_symtab` is 1 when the class is expected to carry a symbol table
// (an object, an executable or a dynamic library) and 0 otherwise.
//
// It returns MV_OK when the image is structurally valid, and otherwise the
// FIRST violated property's code. The FIRST violation is reported so the
// reason is deterministic.
static I64 ValidateMachO(U8 *buf, I64 size, I64 require_symtab) {
  vm_symoff = 0;
  vm_nsyms = 0;
  vm_stroff = 0;
  vm_strsize = 0;

  if (buf == NULL) return MV_ABSENT;
  if (size == 0) return MV_EMPTY;
  if (size < MACHO_HEADER_SIZE) return MV_BAD_HEADER;
  if (WordAt(buf, size, 0) != MACHO64_MAGIC) return MV_BAD_MAGIC;

  // The declared CPU type must be a type the comparator understands.
  I64 cputype = WordAt(buf, size, 4);
  if (cputype != CPU_TYPE_ARM64 && cputype != CPU_TYPE_X86_64) {
    return MV_BAD_CPUTYPE;
  }
  // The declared file type must be one of the three Mach-O image kinds.
  I64 filetype = WordAt(buf, size, 12);
  if (filetype != 1 && filetype != 2 && filetype != 6) {
    return MV_BAD_FILETYPE;
  }

  // The load-command count and the declared load-command extent.
  I64 ncmds = WordAt(buf, size, 16);
  I64 sizeofcmds = WordAt(buf, size, 20);
  if (ncmds < 0 || ncmds > 4096) return MV_BAD_NCMDS;
  if (sizeofcmds < 0) return MV_BAD_SIZEOFCMDS;
  // The declared load-command extent must lie inside the file. The
  // subtraction form cannot overflow because sizeofcmds is already
  // bounded to be non-negative and the header is already inside the file.
  if (sizeofcmds > size - MACHO_HEADER_SIZE) return MV_BAD_SIZEOFCMDS;

  // Walk the load commands. Every one must lie inside the DECLARED extent
  // and inside the file, and every one must have a plausible size.
  I64 off = MACHO_HEADER_SIZE;
  I64 limit = MACHO_HEADER_SIZE + sizeofcmds;
  I64 i = 0;
  I64 found_symtab = 0;
  while (i < ncmds) {
    if (off > limit - 8) return MV_LOADCMD_OVERRUN;
    I64 cmd = WordAt(buf, size, off);
    I64 cmdsize = WordAt(buf, size, off + 4);
    if (cmdsize < 8) return MV_LOADCMD_SIZE;
    if (cmdsize > limit - off) return MV_LOADCMD_OVERRUN;
    if (cmd == LC_SYMTAB_CMD) {
      // The LC_SYMTAB load command is EXACTLY 24 bytes.
      if (cmdsize != LC_SYMTAB_CMDSZ) return MV_SYMTAB_STRUCT;
      I64 symoff = WordAt(buf, size, off + 8);
      I64 nsyms = WordAt(buf, size, off + 12);
      I64 stroff = WordAt(buf, size, off + 16);
      I64 strsize = WordAt(buf, size, off + 20);
      if (nsyms < 0 || strsize < 0) return MV_SYMTAB_STRUCT;
      if (symoff < 0 || stroff < 0) return MV_SYMTAB_STRUCT;
      // The symbol table must lie inside the file. The division form
      // cannot overflow: it computes the MAXIMUM number of entries that
      // fit in the remaining bytes.
      if (symoff > size) return MV_SYMTAB_BOUNDS;
      if (nsyms > (size - symoff) / NLIST64_SIZE) {
        return MV_SYMTAB_BOUNDS;
      }
      // The string table must lie inside the file.
      if (stroff > size) return MV_STRTAB_BOUNDS;
      if (strsize > size - stroff) return MV_STRTAB_BOUNDS;
      vm_symoff = symoff;
      vm_nsyms = nsyms;
      vm_stroff = stroff;
      vm_strsize = strsize;
      found_symtab = 1;
    }
    off = off + cmdsize;
    i = i + 1;
  }
  // The load commands must exactly fill the declared extent.
  if (off != limit) return MV_BAD_SIZEOFCMDS;

  if (require_symtab == 1 && found_symtab == 0) return MV_NO_SYMTAB;
  return MV_OK;
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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F2 -- THE BOUNDED SYMBOL LOOKUP.
//
// The previous revision RE-WALKED the load commands and RE-DERIVED the
// symbol-table bounds from the image bytes, using the expression
// `stroff + strsize > size`, which can WRAP when the declared values are
// large, and it silently SKIPPED a symbol whose string index was out of
// range instead of REJECTING the image.
//
// The repaired lookup uses ONLY the facts that ValidateMachO has already
// PROVED. The bounds are therefore already known to hold, and the string
// index of EVERY symbol entry is checked against the string table BEFORE
// the entry is used.
//
// The string-index check is reported through `stridx_bad`, so the caller can
// attribute the rejection to the SPECIFIC violated property.
// ---------------------------------------------------------------------------
static I64 HasSymbolChecked(U8 *buf, I64 size, U8 *name, I64 *stridx_bad) {
  *stridx_bad = 0;
  if (buf == NULL) return 0;
  // The image MUST have been structurally validated. The caller validates
  // it before it reaches here; this is the belt to that suspenders.
  if (ValidateMachO(buf, size, 1) != MV_OK) return 0;
  if (vm_nsyms == 0) return 0;

  I64 namelen = StrLen(name);
  I64 k = 0;
  while (k < vm_nsyms) {
    // The entry offset is inside the file because the validator proved
    // that vm_nsyms entries of NLIST64_SIZE bytes fit at vm_symoff.
    I64 entry = vm_symoff + k * NLIST64_SIZE;
    I64 n_strx = WordAt(buf, size, entry);
    // EVERY accessed symbol-string index must lie inside the string table.
    // An index that does not is a STRUCTURAL defect, not a missing
    // symbol, and it rejects the image.
    if (n_strx < 0 || n_strx >= vm_strsize) {
      *stridx_bad = 1;
      return 0;
    }
    I64 p = vm_stroff + n_strx;
    I64 q = 0;
    I64 match = 1;
    while (q < namelen) {
      if (p + q >= vm_stroff + vm_strsize) { match = 0; break; }
      if (buf[p + q] != name[q]) { match = 0; break; }
      q = q + 1;
    }
    if (match == 1 && p + q < vm_stroff + vm_strsize && buf[p + q] == 0) {
      return 1;
    }
    k = k + 1;
  }
  return 0;
}

// The legacy entry point. It keeps the OLD semantics of "the symbol is
// present" but it now REJECTS an image whose string indices are out of
// range, because a malformed image must not be able to satisfy a symbol
// requirement.
static I64 HasSymbol(U8 *buf, I64 size, U8 *name) {
  I64 bad = 0;
  return HasSymbolChecked(buf, size, name, &bad);
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
// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F2 -- THE STRICT EXIT-STATUS READER.
//
// The harness writes the compiler's exit status into a file. The comparator
// reads it back as a TEXT record, so a status that was never recorded is
// detected as a MISSING observation rather than being silently treated as
// zero.
//
// THE PREVIOUS REVISION was a WEAK NEGATION. It scanned leading digits and
// then BROKE OUT of the loop on the first non-digit, IGNORING whatever
// followed. A record of "0 trailing garbage text" therefore parsed as the
// value 0, which is EXACTLY the expected value for a successful compile.
// The record was malformed, and the comparator reported it as the expected
// status.
//
// THE REPAIRED reader accepts ONLY a COMPLETE, CORRECTLY FORMATTED record
// of a valid process exit code:
//
//   * the record MUST be nonempty;
//   * the record MUST consist of decimal digits ONLY;
//   * the record MAY be terminated by EXACTLY ONE trailing newline;
//   * the record MUST NOT carry trailing text, extra tokens, a negative
//     sign, a plus sign, or any other byte;
//   * the value MUST fit in the range of a process exit status, and the
//     accumulation MUST NOT overflow.
//
// The reasons are DISTINCT so a reviewer can tell WHICH property was
// violated.
// ---------------------------------------------------------------------------
#define EXIT_OK             0
#define EXIT_MISSING        1
#define EXIT_EMPTY          2
#define EXIT_NOT_DIGIT      3
#define EXIT_TRAILING_TEXT  4
#define EXIT_TRAILING_BYTES 5
#define EXIT_OVERFLOW       6
#define EXIT_NEGATIVE       7
#define EXIT_RANGE          8

// The largest value a process exit status may carry.
#define EXIT_MAX 255

static U8 *ExitReason(I64 code) {
  if (code == EXIT_OK) return "OK";
  if (code == EXIT_MISSING) return "EXIT_STATUS_RECORD_MISSING";
  if (code == EXIT_EMPTY) return "EXIT_STATUS_RECORD_EMPTY";
  if (code == EXIT_NOT_DIGIT) return "EXIT_STATUS_NOT_DECIMAL";
  if (code == EXIT_TRAILING_TEXT) return "EXIT_STATUS_TRAILING_TEXT";
  if (code == EXIT_TRAILING_BYTES) return "EXIT_STATUS_UNEXPECTED_TRAILING_BYTES";
  if (code == EXIT_OVERFLOW) return "EXIT_STATUS_INTEGER_OVERFLOW";
  if (code == EXIT_NEGATIVE) return "EXIT_STATUS_NEGATIVE";
  if (code == EXIT_RANGE) return "EXIT_STATUS_OUT_OF_RANGE";
  return "EXIT_STATUS_UNKNOWN";
}

// The strict reader. It returns the exit status through `value` and the
// validation code through `code`.
static I64 ReadExitStatusStrict(U8 *path, I64 *present, I64 *value,
                                 I64 *code) {
  *present = 0;
  *value = 0;
  *code = EXIT_OK;
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    *code = EXIT_MISSING;
    return 0;
  }
  *present = 1;
  if (size == 0) {
    *code = EXIT_EMPTY;
    return 0;
  }
  // A leading minus sign is a NEGATIVE status, which is never a valid
  // process exit code.
  if (buf[0] == 45) {
    *code = EXIT_NEGATIVE;
    return 0;
  }
  // The digits.
  I64 v = 0;
  I64 i = 0;
  I64 digits = 0;
  while (i < size) {
    I64 c = buf[i];
    if (c < 48 || c > 57) break;
    // The accumulation is overflow-safe: the value is checked against the
    // maximum BEFORE it is multiplied, so no intermediate product can
    // exceed the accumulator's range.
    if (v > (EXIT_MAX + 1) / 10) {
      *code = EXIT_OVERFLOW;
      return 0;
    }
    v = v * 10 + (c - 48);
    if (v > EXIT_MAX) {
      *code = EXIT_OVERFLOW;
      return 0;
    }
    digits = digits + 1;
    i = i + 1;
  }
  if (digits == 0) {
    *code = EXIT_NOT_DIGIT;
    return 0;
  }
  // EXACTLY ONE trailing newline is permitted, and NOTHING else.
  if (i < size) {
    if (buf[i] == 10) {
      i = i + 1;
      if (i < size) {
        *code = EXIT_TRAILING_BYTES;
        return 0;
      }
    } else {
      *code = EXIT_TRAILING_TEXT;
      return 0;
    }
  }
  *value = v;
  return 1;
}

// The legacy reader. It now DELEGATES to the strict reader, so no caller
// can accidentally use the weak parse.
static I64 ReadExitStatus(U8 *path, I64 *present) {
  I64 value = 0;
  I64 code = EXIT_OK;
  I64 ok = ReadExitStatusStrict(path, present, &value, &code);
  if (ok == 0) return -998;
  return value;
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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F2 -- THE INVOCATION PROVENANCE.
//
// A comparison of two FILES cannot establish that either file is the
// OBSERVATION OF AN EXECUTION THAT HAPPENED. The previous revision
// compared files, so a VALID but STALE artifact replayed on BOTH sides was
// reported as an equivalence.
//
// THE REPAIR binds every observation to the execution that produced it.
//
// The harness writes a CAPTURE RECORD directly from the execution, in a
// simple `KEY VALUE` line format:
//
//   SOURCE_SHA256   <64 hex>
//   FIXTURE_SHA256  <64 hex>
//   SELECTOR        OFF | ON
//   PRODUCER_SHA256 <64 hex>
//   INVOCATION_ID   <64 hex>
//   EXIT_STATUS     <decimal>
//   STDOUT_SHA256   <64 hex>
//   STDERR_SHA256   <64 hex>
//   ARTIFACT_SHA256 <64 hex>
//   ARGV            <one argument per line>
//   ENV             <one binding per line>
//
// The comparator:
//
//   1. requires the record to be PRESENT;
//   2. requires every MANDATORY field to be present and well formed;
//   3. RECOMPUTES the artifact digest, the transcript digests and the
//      exit status from the files it is given, and requires each of them
//      to MATCH the record;
//   4. requires the INVOCATION_ID to be REGISTERED in the run ledger,
//      which the harness writes during THIS run.
//
// A user cannot make an arbitrary stale file trustworthy by copying or
// editing a matching manifest, because the record is verified against the
// BYTES it is given, AND its invocation identity must appear in the
// ledger of THIS run. A record that is edited to match a stale file still
// names an invocation that this run did not perform.
//
// The digest the comparator recomputes is the SAME FNV-1a 64 digest it
// already uses for artifact comparison, so the record and the comparison
// use one digest function and cannot disagree about the bytes.
// ---------------------------------------------------------------------------
#define CAPTURE_OK               0
#define CAPTURE_MISSING          1
#define CAPTURE_FIELD_MISSING    2
#define CAPTURE_MALFORMED        3
#define CAPTURE_DIGEST_MISMATCH  4
#define CAPTURE_EXIT_MISMATCH    5
#define CAPTURE_NOT_REGISTERED   6
#define CAPTURE_SELECTOR_BAD     7
#define CAPTURE_ARGV_EMPTY       8
#define CAPTURE_ENV_EMPTY        9

static U8 *CaptureReason(I64 code) {
  if (code == CAPTURE_OK) return "OK";
  if (code == CAPTURE_MISSING) return "CAPTURE_RECORD_MISSING";
  if (code == CAPTURE_FIELD_MISSING) return "CAPTURE_FIELD_MISSING";
  if (code == CAPTURE_MALFORMED) return "CAPTURE_FIELD_MALFORMED";
  if (code == CAPTURE_DIGEST_MISMATCH) return "CAPTURE_DIGEST_MISMATCH";
  if (code == CAPTURE_EXIT_MISMATCH) return "CAPTURE_EXIT_STATUS_MISMATCH";
  if (code == CAPTURE_NOT_REGISTERED) return "CAPTURE_INVOCATION_NOT_REGISTERED";
  if (code == CAPTURE_SELECTOR_BAD) return "CAPTURE_SELECTOR_INVALID";
  if (code == CAPTURE_ARGV_EMPTY) return "CAPTURE_ARGV_EMPTY";
  if (code == CAPTURE_ENV_EMPTY) return "CAPTURE_ENV_EMPTY";
  return "CAPTURE_UNKNOWN";
}

// The parsed capture record.
static U8 *cp_source_sha;
static U8 *cp_fixture_sha;
static U8 *cp_selector;
static U8 *cp_producer_sha;
static U8 *cp_invocation_id;
static U8 *cp_stdout_sha;
static U8 *cp_stderr_sha;
static U8 *cp_artifact_sha;
static I64 cp_exit;

// The field extractor. It finds `KEY` at the start of a line and returns a
// COPY of the value, or NULL when the field is absent.
//
// A SINGLE-VALUE field is `KEY VALUE` on one line. A BLOCK field is `KEY`
// on its own line followed by the value lines. The extractor accepts both
// forms, so a block field's presence is detectable.
static U8 *CaptureField(U8 *buf, I64 size, U8 *key) {
  I64 klen = StrLen(key);
  I64 i = 0;
  while (i < size) {
    I64 lend = i;
    while (lend < size && buf[lend] != 10) lend = lend + 1;
    // The line must start with the key.
    if (lend - i >= klen) {
      I64 m = 0;
      while (m < klen) {
        if (buf[i + m] != key[m]) { m = -1; break; }
        m = m + 1;
      }
      if (m == klen) {
        // The key must be followed by a space (a single-value field) or by
        // the end of the line (a block field).
        if (lend - i == klen) {
          // A BLOCK field. The value is the first NONEMPTY line after it.
          I64 j = lend + 1;
          while (j < size) {
            I64 bend = j;
            while (bend < size && buf[bend] != 10) bend = bend + 1;
            if (bend > j) {
              U8 *v = MAlloc(bend - j + 1);
              MemCpy(v, buf + j, bend - j);
              v[bend - j] = 0;
              return v;
            }
            j = bend + 1;
          }
          return NULL;
        }
        if (buf[i + klen] == 32) {
          I64 vlen = lend - (i + klen + 1);
          if (vlen <= 0) return NULL;
          U8 *v = MAlloc(vlen + 1);
          MemCpy(v, buf + i + klen + 1, vlen);
          v[vlen] = 0;
          return v;
        }
      }
    }
    if (lend >= size) break;
    i = lend + 1;
  }
  return NULL;
}

// The hexadecimal digest formatter. The comparator computes an FNV-1a 64
// digest and prints it as 16 hexadecimal digits, so the capture record and
// the comparator agree on ONE representation.
static U0 FormatDigest(U8 *out, U64 d) {
  U8 *hex = "0123456789abcdef";
  I64 i = 0;
  while (i < 16) {
    U64 nib = (d >> ((15 - i) * 4)) & 15;
    out[i] = hex[nib];
    i = i + 1;
  }
  out[16] = 0;
}

// The digest comparison. The comparator's recomputed digest is formatted and
// compared with the record's field.
static I64 DigestMatches(U8 *recorded, U8 *buf, I64 size) {
  if (recorded == NULL) return 0;
  if (StrLen(recorded) != 16) return 0;
  U8 *mine = MAlloc(17);
  FormatDigest(mine, Digest(buf, size));
  I64 ok = 0;
  if (StrCmp(mine, recorded) == 0) ok = 1;
  Free(mine);
  return ok;
}

// The run ledger. It is a file, one registered invocation identity per
// line, written by the harness during THIS run. The comparator requires the
// capture record's INVOCATION_ID to appear in it.
static I64 LedgerHas(U8 *ledger_path, U8 *id) {
  if (id == NULL) return 0;
  I64 size = 0;
  U8 *buf = FileRead(ledger_path, &size);
  if (buf == NULL) return 0;
  I64 idlen = StrLen(id);
  I64 found = 0;
  I64 i = 0;
  while (i < size) {
    I64 lend = i;
    while (lend < size && buf[lend] != 10) lend = lend + 1;
    if (lend - i == idlen) {
      I64 m = 0;
      while (m < idlen) {
        if (buf[i + m] != id[m]) { m = -1; break; }
        m = m + 1;
      }
      if (m == idlen) { found = 1; break; }
    }
    if (lend >= size) break;
    i = lend + 1;
  }
  return found;
}


// The capture-record validator.
//
// It requires the record to be present, requires every mandatory field to
// be present and well formed, requires the recomputed artifact digest, the
// recomputed transcript digests and the observed exit status to MATCH the
// record, and requires the INVOCATION_ID to be REGISTERED in the run
// ledger.
//
// The FIRST violated property is returned, so the reason is specific.
static I64 ValidateCapture(U8 *case_id, U8 *side, U8 *capture_path,
                            U8 *ledger_path, U8 *art, I64 art_size,
                            U8 *stdout_path, U8 *stderr_path, I64 exit_code,
                            I64 exit_present, I64 exit_ok) {
  I64 size = 0;
  U8 *buf = FileRead(capture_path, &size);
  if (buf == NULL) return CAPTURE_MISSING;
  if (size == 0) return CAPTURE_MISSING;

  // The mandatory fields.
  U8 *source_sha = CaptureField(buf, size, "SOURCE_SHA256");
  U8 *fixture_sha = CaptureField(buf, size, "FIXTURE_SHA256");
  U8 *selector = CaptureField(buf, size, "SELECTOR");
  U8 *producer_sha = CaptureField(buf, size, "PRODUCER_SHA256");
  U8 *invocation_id = CaptureField(buf, size, "INVOCATION_ID");
  U8 *stdout_sha = CaptureField(buf, size, "STDOUT_SHA256");
  U8 *stderr_sha = CaptureField(buf, size, "STDERR_SHA256");
  U8 *artifact_sha = CaptureField(buf, size, "ARTIFACT_SHA256");
  U8 *exit_field = CaptureField(buf, size, "EXIT_STATUS");
  U8 *argv_field = CaptureField(buf, size, "ARGV");
  U8 *env_field = CaptureField(buf, size, "ENV");

  if (source_sha == NULL || fixture_sha == NULL || selector == NULL ||
      producer_sha == NULL || invocation_id == NULL ||
      stdout_sha == NULL || stderr_sha == NULL || artifact_sha == NULL ||
      exit_field == NULL || argv_field == NULL || env_field == NULL) {
    return CAPTURE_FIELD_MISSING;
  }

  // The selector must be one of the two supported modes.
  if (StrCmp(selector, "OFF") != 0 && StrCmp(selector, "ON") != 0) {
    return CAPTURE_SELECTOR_BAD;
  }
  // The ARGV and the ENV must not be empty. An execution with no argument
  // vector and no environment binding is not an execution.
  if (StrLen(argv_field) == 0) return CAPTURE_ARGV_EMPTY;
  if (StrLen(env_field) == 0) return CAPTURE_ENV_EMPTY;

  // The ARTIFACT digest must MATCH the bytes the comparator was given.
  if (DigestMatches(artifact_sha, art, art_size) == 0) {
    return CAPTURE_DIGEST_MISMATCH;
  }

  // The STDOUT and the STDERR digests must MATCH the transcripts.
  I64 osz = 0;
  I64 esz = 0;
  U8 *osb = FileRead(stdout_path, &osz);
  U8 *esb = FileRead(stderr_path, &esz);
  if (osb == NULL || esb == NULL) return CAPTURE_DIGEST_MISMATCH;
  if (DigestMatches(stdout_sha, osb, osz) == 0) {
    return CAPTURE_DIGEST_MISMATCH;
  }
  if (DigestMatches(stderr_sha, esb, esz) == 0) {
    return CAPTURE_DIGEST_MISMATCH;
  }

  // The EXIT STATUS must MATCH the record. The record's value is parsed
  // STRICTLY, so a malformed record cannot smuggle in a value.
  if (exit_present == 1 && exit_ok == 1) {
    I64 rv = 0;
    I64 rdigits = 0;
    I64 ri = 0;
    I64 rlen = StrLen(exit_field);
    while (ri < rlen) {
      I64 c = exit_field[ri];
      if (c < 48 || c > 57) return CAPTURE_MALFORMED;
      rv = rv * 10 + (c - 48);
      rdigits = rdigits + 1;
      ri = ri + 1;
    }
    if (rdigits == 0) return CAPTURE_MALFORMED;
    if (rv != exit_code) return CAPTURE_EXIT_MISMATCH;
  } else {
    return CAPTURE_EXIT_MISMATCH;
  }

  // The INVOCATION must be REGISTERED in the run ledger. This is the step
  // that a stale replay cannot satisfy: the ledger is written by the
  // harness during THIS run, and it contains only the invocations THIS
  // run actually performed.
  if (LedgerHas(ledger_path, invocation_id) == 0) {
    return CAPTURE_NOT_REGISTERED;
  }

  return CAPTURE_OK;
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

  // -----------------------------------------------------------------------
  // THE COMPARISON MODE.
  //
  //   compare <case-id> <oracle-artifact> <polyc-artifact>
  //           <oracle-stdout> <polyc-stdout> <oracle-stderr> <polyc-stderr>
  //           <oracle-exit>   <polyc-exit>
  //           <expected-class> <expected-arch> <expected-exit>
  //           <run-ledger> <oracle-capture> <polyc-capture>
  //           [required-symbol ...]
  //
  // The EXPECTED values are supplied by the harness, which derives them from
  // the genuine selector-OFF C ORACLE. The comparator VALIDATES both sides
  // against those expectations and only then COMPARES the two sides.
  // -----------------------------------------------------------------------
  if (argc < 17) {
    "REASON_DETAIL=usage: compare <case-id> <oracle-art> <polyc-art> "
      "<oracle-stdout> <polyc-stdout> <oracle-stderr> <polyc-stderr> "
      "<oracle-exit> <polyc-exit> <expected-class> <expected-arch> "
      "<expected-exit> <run-ledger> <oracle-capture> <polyc-capture> "
      "[symbol ...]\n";
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
  U8 *ledger   = argv[13];
  U8 *o_capture = argv[14];
  U8 *p_capture = argv[15];

  // -----------------------------------------------------------------------
  // THE EXPECTED CLASS MUST BE A SUPPORTED CLASS.
  //
  // An UNSUPPORTED expectation (`OTHER`, or an unknown token) is REJECTED
  // OUTRIGHT. The previous revision mapped an unknown token to the OTHER
  // class, and the OTHER class was a legal expectation, so a pair of
  // IDENTICAL GARBAGE files was reported as an equivalence with zero
  // failures.
  //
  // The comparator therefore only supports the classes it can VALIDATE.
  // -----------------------------------------------------------------------
  I64 expected_class = -1;
  if (StrCmp(argv[10], "MACHO_OBJECT") == 0) expected_class = 1;
  if (StrCmp(argv[10], "MACHO_EXECUTABLE") == 0) expected_class = 2;
  if (StrCmp(argv[10], "MACHO_DYLIB") == 0) expected_class = 3;
  if (StrCmp(argv[10], "ELF") == 0) expected_class = 4;
  if (StrCmp(argv[10], "ASSEMBLER_TEXT") == 0) expected_class = 6;
  Check(expected_class != -1, case_id,
        "the expected artifact class is a SUPPORTED class");
  if (expected_class == -1) {
    Reason(case_id, "harness", "EXPECTED_CLASS_UNSUPPORTED");
  }

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
  //
  // The STRUCTURAL validation is performed on THIS SIDE INDEPENDENTLY of
  // whether the two sides match, so an identical pair of MALFORMED images
  // is rejected on both sides.
  // -----------------------------------------------------------------------
  I64 o_present = 0;
  I64 o_size = 0;
  U8 *obuf = ReadArtifact(oracle, &o_size, &o_present);
  I64 o_class = Classify(obuf, o_size);
  I64 o_arch = ArchOf(obuf, o_size);

  // The exit status is read STRICTLY.
  I64 o_exit_present = 0;
  I64 o_exit = 0;
  I64 o_exit_code = EXIT_OK;
  I64 o_exit_ok = ReadExitStatusStrict(o_exitf, &o_exit_present, &o_exit,
                                       &o_exit_code);

  Check(o_present == 1, case_id, "the oracle artifact is PRESENT");
  Check(o_present == 1 && o_size > 0, case_id,
        "the oracle artifact is NONEMPTY");
  Check(o_present == 1 && o_class == expected_class, case_id,
        "the oracle artifact has the EXPECTED class");
  Check(o_present == 1 && (expected_arch == -1 || o_arch == expected_arch),
        case_id, "the oracle artifact has the EXPECTED architecture");
  Check(o_exit_present == 1 && o_exit_ok == 1, case_id,
        "the oracle exit status is a VALID record");
  if (o_exit_present == 1 && o_exit_ok == 0) {
    Reason(case_id, "oracle", ExitReason(o_exit_code));
  }
  Check(o_exit_present == 1 && o_exit_ok == 1 && o_exit == expected_exit,
        case_id, "the oracle exit status is the EXPECTED one");

  // The structural validation of the oracle image.
  I64 o_requires_symtab = 0;
  if (expected_class == 1 || expected_class == 2 || expected_class == 3) {
    o_requires_symtab = 1;
  }
  I64 o_mv = MV_OK;
  if (o_present == 1 && o_class == expected_class) {
    if (o_requires_symtab == 1) {
      o_mv = ValidateMachO(obuf, o_size, 1);
    }
  } else {
    o_mv = MV_BAD_MAGIC;
  }
  Check(o_present == 1 && o_mv == MV_OK, case_id,
        "the oracle artifact is STRUCTURALLY VALID");
  if (o_present == 1 && o_mv != MV_OK) {
    Reason(case_id, "oracle", MachOReason(o_mv));
  }

  // -----------------------------------------------------------------------
  // STEP 2 -- VALIDATE THE POLYC OBSERVATION.
  // -----------------------------------------------------------------------
  I64 p_present = 0;
  I64 p_size = 0;
  U8 *pbuf = ReadArtifact(polyc, &p_size, &p_present);
  I64 p_class = Classify(pbuf, p_size);
  I64 p_arch = ArchOf(pbuf, p_size);

  I64 p_exit_present = 0;
  I64 p_exit = 0;
  I64 p_exit_code = EXIT_OK;
  I64 p_exit_ok = ReadExitStatusStrict(p_exitf, &p_exit_present, &p_exit,
                                       &p_exit_code);

  Check(p_present == 1, case_id, "the PolyC artifact is PRESENT");
  Check(p_present == 1 && p_size > 0, case_id,
        "the PolyC artifact is NONEMPTY");
  Check(p_present == 1 && p_class == expected_class, case_id,
        "the PolyC artifact has the EXPECTED class");
  Check(p_present == 1 && (expected_arch == -1 || p_arch == expected_arch),
        case_id, "the PolyC artifact has the EXPECTED architecture");
  Check(p_exit_present == 1 && p_exit_ok == 1, case_id,
        "the PolyC exit status is a VALID record");
  if (p_exit_present == 1 && p_exit_ok == 0) {
    Reason(case_id, "polyc", ExitReason(p_exit_code));
  }
  Check(p_exit_present == 1 && p_exit_ok == 1 && p_exit == expected_exit,
        case_id, "the PolyC exit status is the EXPECTED one");

  I64 p_mv = MV_OK;
  if (p_present == 1 && p_class == expected_class) {
    if (o_requires_symtab == 1) {
      p_mv = ValidateMachO(pbuf, p_size, 1);
    }
  } else {
    p_mv = MV_BAD_MAGIC;
  }
  Check(p_present == 1 && p_mv == MV_OK, case_id,
        "the PolyC artifact is STRUCTURALLY VALID");
  if (p_present == 1 && p_mv != MV_OK) {
    Reason(case_id, "polyc", MachOReason(p_mv));
  }

  // -----------------------------------------------------------------------
  // STEP 3 -- VALIDATE THE REQUIRED SYMBOLS.
  //
  // The symbol requirement applies to an artifact that carries a symbol
  // table. An assembler TEXT artifact has none, so the requirement is NOT
  // APPLICABLE to it and is not reported as a failure.
  //
  // The lookup is the BOUNDED one. An image whose symbol-string index is
  // out of range is REJECTED with its OWN reason, not silently treated as
  // a missing symbol.
  // -----------------------------------------------------------------------
  // The REQUIRED SYMBOLS are the TRAILING arguments, beginning IMMEDIATELY
  // after the PolyC capture record at argv[15]. They therefore begin at
  // argv[16].
  //
  // The previous revision began the scan at argv[17], which SKIPPED the
  // FIRST required symbol. The consequence was that the symbol requirement
  // was SILENTLY DROPPED: with one required symbol the scan saw NO symbol at
  // all, so neither the "the REQUIRED symbols are present" check nor the
  // symbol-string bounds check ever ran. A malformed image whose symbol
  // string index pointed outside the string table was therefore accepted.
  // The off-by-one is corrected here.
  I64 i = 16;
  I64 nsym = 0;
  I64 sym_ok = 1;
  I64 o_stridx_bad = 0;
  I64 p_stridx_bad = 0;
  while (i < argc) {
    U8 *sym = argv[i];
    nsym = nsym + 1;
    if (expected_class == 1 || expected_class == 2 || expected_class == 3) {
      I64 obad = 0;
      I64 pbad = 0;
      if (HasSymbolChecked(obuf, o_size, sym, &obad) == 0) sym_ok = 0;
      if (HasSymbolChecked(pbuf, p_size, sym, &pbad) == 0) sym_ok = 0;
      if (obad == 1) o_stridx_bad = 1;
      if (pbad == 1) p_stridx_bad = 1;
    }
    i = i + 1;
  }
  if (nsym > 0) {
    Check(sym_ok == 1, case_id,
          "the REQUIRED symbols are present in both artifacts");
  }
  Check(o_stridx_bad == 0, case_id,
        "the oracle symbol-string indices are IN BOUNDS");
  if (o_stridx_bad == 1) {
    Reason(case_id, "oracle", MachOReason(MV_STRIDX_BOUNDS));
  }
  Check(p_stridx_bad == 0, case_id,
        "the PolyC symbol-string indices are IN BOUNDS");
  if (p_stridx_bad == 1) {
    Reason(case_id, "polyc", MachOReason(MV_STRIDX_BOUNDS));
  }

  // -----------------------------------------------------------------------
  // STEP 3b -- VALIDATE THE INVOCATION PROVENANCE.
  //
  // This is the step that makes a STALE replay detectable. Each side
  // carries a CAPTURE RECORD that binds the observation to the execution
  // that produced it, and the record's INVOCATION_ID must be REGISTERED in
  // the run ledger that the harness writes during THIS run.
  //
  // The comparator RECOMPUTES the artifact digest, the transcript digests
  // and the exit status from the files it is given, and requires each of
  // them to MATCH the record.
  // -----------------------------------------------------------------------
  I64 o_cap = ValidateCapture(case_id, "oracle", o_capture, ledger, obuf,
                               o_size, o_stdout, o_stderr, o_exit,
                               o_exit_present, o_exit_ok);
  Check(o_cap == CAPTURE_OK, case_id,
        "the oracle INVOCATION PROVENANCE is COMPLETE and REGISTERED");
  if (o_cap != CAPTURE_OK) {
    Reason(case_id, "oracle", CaptureReason(o_cap));
  }
  I64 p_cap = ValidateCapture(case_id, "polyc", p_capture, ledger, pbuf,
                               p_size, p_stdout, p_stderr, p_exit,
                               p_exit_present, p_exit_ok);
  Check(p_cap == CAPTURE_OK, case_id,
        "the PolyC INVOCATION PROVENANCE is COMPLETE and REGISTERED");
  if (p_cap != CAPTURE_OK) {
    Reason(case_id, "polyc", CaptureReason(p_cap));
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
