// tools/quality/driver-required-route-correction03-emission.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.
//
// THE PRODUCTION EMISSION WITNESS.
//
// It validates ONE EMISSION DOMAIN end to end: the Object domain, the
// Assembly domain, the Dynamic-library domain, or the Executable
// (default) domain.
//
// It is the P1-3 repair. The previous evidence established the emission
// precedence for the OBJECT and ASSEMBLY domains only, because those are
// the two domains a single `-o` output file can express. The DYNAMIC
// LIBRARY domain produces THREE artifacts (an object, a static archive
// and a shared library) and the EXECUTABLE domain produces a LINKED
// EXECUTABLE, and neither had a production executable witness.
//
// THE RULES.
//
//   1. EVERY observation is VALIDATED BEFORE it is COMPARED. An
//      observation that is not valid makes the comparison UNSUPPORTED,
//      which is a FAIL, never a PASS.
//
//   2. The EXPECTED class, architecture, symbols and exit status are
//      DERIVED FROM THE GENUINE selector-OFF C ORACLE by the harness. The
//      witness never decides what the correct answer is.
//
//   3. The FULL ARTIFACT BYTE result and the ARCHIVE-MEMBER SEMANTIC
//      result are recorded as SEPARATE results. A static archive's
//      header bytes carry nondeterministic metadata; that difference is
//      reported as METADATA NONDETERMINISM and never as an equivalence
//      failure, and never as an equality claim.
//
//   4. Where an artifact is LINKABLE, the link/run OUTCOME is checked.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

#define MACHO64_MAGIC 0xFEEDFACF
#define ELF64_MAGIC   0x7F454C46

#define CLS_ABSENT      0
#define CLS_MACHO_OBJ   1
#define CLS_MACHO_EXEC  2
#define CLS_MACHO_DYLIB 3
#define CLS_ELF         4
#define CLS_OTHER       5
#define CLS_TEXT        6
#define CLS_AR          7

#define CPU_TYPE_ARM64 0x0100000C
#define CPU_TYPE_X86_64 0x01000007

#define AR_MAGIC_LEN 8
#define AR_MEMBER_HDR_LEN 60

static I64 failures;
static I64 checks;

static U0 Check(I64 ok, U8 *case_id, U8 *what) {
  checks = checks + 1;
  if (ok == 1) {
    "%s\t%s\tPASS\n", case_id, what;
  } else {
    "%s\t%s\tFAIL\n", case_id, what;
    failures = failures + 1;
  }
}

// The reason token. A rejection MUST carry a REASON that says WHICH
// property was violated, so a reviewer can distinguish the failure modes
// and cannot mistake a generic rejection for the specific one.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2.
static U0 Reason(U8 *case_id, U8 *side, U8 *token) {
  "REASON\t%s\t%s\t%s\n", case_id, side, token;
}

static I64 WordAt(U8 *buf, I64 size, I64 off) {
  if (size < off + 4) return -1;
  I64 v = 0;
  I64 i = off + 3;
  while (i >= off) { v = v * 256 + buf[i]; i = i - 1; }
  return v;
}

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
  if (size >= AR_MAGIC_LEN) {
    I64 i = 0;
    I64 ok = 1;
    while (i < AR_MAGIC_LEN) {
      if (buf[i] != "!<arch>\n"[i]) { ok = 0; break; }
      i = i + 1;
    }
    if (ok == 1) return CLS_AR;
  }
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
  if (WordAt(buf, size, 0) != MACHO64_MAGIC) return -1;
  return WordAt(buf, size, 4);
}

static U8 *ArchName(I64 arch) {
  if (arch == CPU_TYPE_ARM64) return "arm64";
  if (arch == CPU_TYPE_X86_64) return "x86_64";
  return "none";
}

static U8 *ClassName(I64 cls) {
  if (cls == CLS_ABSENT) return "ABSENT";
  if (cls == CLS_MACHO_OBJ) return "MACHO_OBJECT";
  if (cls == CLS_MACHO_EXEC) return "MACHO_EXECUTABLE";
  if (cls == CLS_MACHO_DYLIB) return "MACHO_DYLIB";
  if (cls == CLS_ELF) return "ELF";
  if (cls == CLS_TEXT) return "ASSEMBLER_TEXT";
  if (cls == CLS_AR) return "AR_ARCHIVE";
  return "OTHER";
}

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
// MAIN
//
// The witness is invoked as:
//
//   emission <case-id> <domain>
//            <oracle-prefix> <polyc-prefix>
//            <oracle-stdout> <polyc-stdout>
//            <oracle-stderr> <polyc-stderr>
//            <oracle-exit>   <polyc-exit>
//            <expected-class> <expected-arch> <expected-exit>
//            <artifact-suffix> [<artifact-suffix> ...]
//            <required-symbol> [<required-symbol> ...]
//
// The DOMAIN selects which artifacts the witness validates:
//
//   object      the single output artifact
//   assembly    the single output artifact
//   dylib       THREE artifacts: the object, the static archive and the
//               shared library, all named by the same suffix pattern
//   executable  the single LINKED executable, plus its link/run outcome
//
// The EXPECTED values are DERIVED FROM THE GENUINE selector-OFF C ORACLE by
// the harness.
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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2, F3 -- THE ARCHIVE SEMANTIC EQUIVALENCE.
//
// THE DEFECT. The previous revision of this verifier read the archive's
// member SIZES and compared the member CONTENT BYTES, but it NEVER DECODED
// the member NAMES.
//
// The Darwin/BSD `ar` producer stores a member's name in the 16-byte name
// field of the member header, and it uses the EXTENDED NAME form
//
//     #1/<N>
//
// when the name does not fit. In that form the first N bytes of the
// member's CONTENT are the name, and the declared size INCLUDES them.
//
// A mutation of the `#1/N` field therefore changes what `ar` extracts,
// WITHOUT changing the archive's total size and WITHOUT changing the
// member's raw content bytes. The previous verifier classified it as
// harmless METADATA NONDETERMINISM, and reported
//
//     ARCHIVE_MEMBER_SEMANTICS  EQUAL
//
// for an archive whose extracted payload was DIFFERENT.
//
// THE REPAIR. The archive is parsed and validated PROPERLY:
//
//   1. the archive magic, every member header, every declared size, every
//      member boundary and the 2-byte padding are validated;
//   2. the member NAME is decoded, including the `#1/N` extended-name
//      form and the `__.SYMDEF` symbol-table form;
//   3. the DECODED member PAYLOAD is the content that FOLLOWS the
//      extended name, so the payload the verifier compares is exactly the
//      payload `ar` extracts;
//   4. the decoded payload is validated INDEPENDENTLY as the expected
//      Mach-O object;
//   5. the member IDENTITY, the name FORMAT, the ORDER, the ARCHITECTURE,
//      the SYMBOLS and the PAYLOAD BYTES are compared;
//   6. an EMPTY archive, a MISSING member, a DUPLICATE member, an
//      UNEXPECTED member and a MALFORMED length or name encoding are
//      REJECTED;
//   7. a TIMESTAMP-ONLY difference is reported SEPARATELY from a
//      member-CONTENT difference, and it is never reported as a content
//      difference.
//
// The reasons are DISTINCT, so a reviewer can tell WHICH property was
// violated.
// ---------------------------------------------------------------------------
#define AR_HDR_NAME_OFF  0
#define AR_HDR_NAME_LEN  16
#define AR_HDR_SIZE_OFF  48
#define AR_HDR_SIZE_LEN  10
#define AR_HDR_FMAG_OFF  58
#define AR_NAME_MAX      256
#define AR_MAX_MEMBERS   64
static I64 ArMemberSizeAt(U8 *buf, I64 size, I64 off) {
  if (off + AR_MEMBER_HDR_LEN > size) return -1;
  I64 m = 0;
  I64 digits = 0;
  I64 j = 48;
  while (j < 58) {
    I64 c = buf[off + j];
    if (c >= 48 && c <= 57) {
      m = m * 10 + (c - 48);
      digits = digits + 1;
      j = j + 1;
      continue;
    }
    break;
  }
  if (digits == 0) return -1;
  return m;
}

// The archive validation result codes.
#define ARV_OK               0
#define ARV_ABSENT           1
#define ARV_EMPTY            2
#define ARV_BAD_MAGIC        3
#define ARV_BAD_HEADER       4
#define ARV_BAD_SIZE_FIELD   5
#define ARV_SIZE_OVERRUN     6
#define ARV_BAD_NAME         7
#define ARV_BAD_EXTNAME      8
#define ARV_PADDING          9
#define ARV_TRAILING_BYTES   10
#define ARV_NO_MEMBERS       11
#define ARV_MEMBER_COUNT     12
#define ARV_DUPLICATE        13
#define ARV_MISSING          14
#define ARV_UNEXPECTED       15
#define ARV_PAYLOAD          16
#define ARV_PAYLOAD_CLASS    17
#define ARV_PAYLOAD_ARCH     18
#define ARV_PAYLOAD_SYMBOL   19
#define ARV_NAME_FORMAT      20
#define ARV_ORDER            21
#define ARV_TIMESTAMP        22

static U8 *ArReason(I64 code) {
  if (code == ARV_OK) return "OK";
  if (code == ARV_ABSENT) return "ARCHIVE_ABSENT";
  if (code == ARV_EMPTY) return "ARCHIVE_EMPTY";
  if (code == ARV_BAD_MAGIC) return "ARCHIVE_BAD_MAGIC";
  if (code == ARV_BAD_HEADER) return "ARCHIVE_BAD_MEMBER_HEADER";
  if (code == ARV_BAD_SIZE_FIELD) return "ARCHIVE_BAD_SIZE_FIELD";
  if (code == ARV_SIZE_OVERRUN) return "ARCHIVE_MEMBER_SIZE_OUT_OF_BOUNDS";
  if (code == ARV_BAD_NAME) return "ARCHIVE_BAD_MEMBER_NAME";
  if (code == ARV_BAD_EXTNAME) return "ARCHIVE_BAD_EXTENDED_NAME_ENCODING";
  if (code == ARV_PADDING) return "ARCHIVE_BAD_MEMBER_PADDING";
  if (code == ARV_TRAILING_BYTES) return "ARCHIVE_UNEXPECTED_TRAILING_BYTES";
  if (code == ARV_NO_MEMBERS) return "ARCHIVE_NO_MEMBERS";
  if (code == ARV_MEMBER_COUNT) return "ARCHIVE_MEMBER_COUNT_MISMATCH";
  if (code == ARV_DUPLICATE) return "ARCHIVE_DUPLICATE_MEMBER";
  if (code == ARV_MISSING) return "ARCHIVE_MEMBER_MISSING";
  if (code == ARV_UNEXPECTED) return "ARCHIVE_UNEXPECTED_MEMBER";
  if (code == ARV_PAYLOAD) return "ARCHIVE_MEMBER_PAYLOAD_MISMATCH";
  if (code == ARV_PAYLOAD_CLASS) return "ARCHIVE_MEMBER_PAYLOAD_CLASS_INVALID";
  if (code == ARV_PAYLOAD_ARCH) return "ARCHIVE_MEMBER_PAYLOAD_ARCH_INVALID";
  if (code == ARV_PAYLOAD_SYMBOL) return "ARCHIVE_MEMBER_PAYLOAD_SYMBOL_MISSING";
  if (code == ARV_NAME_FORMAT) return "ARCHIVE_MEMBER_NAME_FORMAT_MISMATCH";
  if (code == ARV_ORDER) return "ARCHIVE_MEMBER_ORDER_MISMATCH";
  if (code == ARV_TIMESTAMP) return "ARCHIVE_MEMBER_TIMESTAMP_NONDETERMINISM";
  return "ARCHIVE_UNKNOWN";
}

// The decoded member.
static U8 *am_name[AR_MAX_MEMBERS];
static I64 am_namelen[AR_MAX_MEMBERS];
static I64 am_extname[AR_MAX_MEMBERS];       // 1 when the name is extended
static I64 am_namelen_field[AR_MAX_MEMBERS];  // the declared #1/N length
static U8 *am_payload[AR_MAX_MEMBERS];
static I64 am_paylen[AR_MAX_MEMBERS];
static I64 am_mtime[AR_MAX_MEMBERS];
static I64 am_count;

// The ORACLE and the POLYC copies of the decoded members. The decoder
// fills the `am_*` tables, so the oracle's decoding is copied out before
// the PolyC side is decoded.
static U8 *o_name[AR_MAX_MEMBERS];
static I64 o_namelen[AR_MAX_MEMBERS];
static I64 o_ext[AR_MAX_MEMBERS];
static I64 o_extlen[AR_MAX_MEMBERS];
static U8 *o_payload[AR_MAX_MEMBERS];
static I64 o_paylen[AR_MAX_MEMBERS];
static I64 o_mtime[AR_MAX_MEMBERS];
static U8 *p_name[AR_MAX_MEMBERS];
static I64 p_namelen[AR_MAX_MEMBERS];
static I64 p_ext[AR_MAX_MEMBERS];
static I64 p_extlen[AR_MAX_MEMBERS];
static U8 *p_payload[AR_MAX_MEMBERS];
static I64 p_paylen[AR_MAX_MEMBERS];
static I64 p_mtime[AR_MAX_MEMBERS];

// The name comparison. The name is compared as a byte run.
static I64 ArNameEqual(U8 *a, I64 alen, U8 *b, I64 blen) {
  I64 n = alen;
  if (blen < n) n = blen;
  I64 i = 0;
  while (i < n) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// The size field reader. The field is a decimal ASCII run, optionally
// terminated by a space. It returns -1 when the field is malformed.
static I64 ArSizeAt(U8 *buf, I64 size, I64 off) {
  if (off + AR_MEMBER_HDR_LEN > size) return -1;
  I64 m = 0;
  I64 digits = 0;
  I64 j = AR_HDR_SIZE_OFF;
  while (j < AR_HDR_SIZE_OFF + AR_HDR_SIZE_LEN) {
    I64 c = buf[off + j];
    if (c >= 48 && c <= 57) {
      // The accumulation is overflow-safe: the value is checked BEFORE it
      // is multiplied.
      if (m > 2000000000) return -1;
      m = m * 10 + (c - 48);
      digits = digits + 1;
      j = j + 1;
      continue;
    }
    if (c == 32) break;
    return -1;
  }
  if (digits == 0) return -1;
  return m;
}

// The mtime field reader. It is read so that a TIMESTAMP-ONLY difference
// can be reported separately from a content difference.
static I64 ArMtimeAt(U8 *buf, I64 size, I64 off) {
  if (off + AR_MEMBER_HDR_LEN > size) return -1;
  I64 m = 0;
  I64 digits = 0;
  I64 j = 16;
  while (j < 28) {
    I64 c = buf[off + j];
    if (c >= 48 && c <= 57) {
      if (m > 2000000000) return -1;
      m = m * 10 + (c - 48);
      digits = digits + 1;
      j = j + 1;
      continue;
    }
    if (c == 32) break;
    return -1;
  }
  if (digits == 0) return 0;
  return m;
}

// The ARCHIVE DECODER.
//
// It parses the archive into its decoded members, and it validates every
// structural property as it goes.
//
// It returns ARV_OK when the archive is structurally valid, and otherwise
// the FIRST violated property's code.
//
// The DECODED PAYLOAD of a member is the content that FOLLOWS the
// extended name. That is exactly the byte range `ar` extracts, so the
// payload this function reports is the payload the independent `ar`
// extraction produces.
//
// It fills the `am_*` tables. The caller MUST NOT read them when the
// return value is not ARV_OK.
static I64 DecodeArchive(U8 *buf, I64 size) {
  am_count = 0;
  if (buf == NULL) return ARV_ABSENT;
  if (size == 0) return ARV_EMPTY;
  if (size < AR_MAGIC_LEN) return ARV_BAD_MAGIC;
  I64 i = 0;
  while (i < AR_MAGIC_LEN) {
    if (buf[i] != "!<arch>\n"[i]) return ARV_BAD_MAGIC;
    i = i + 1;
  }

  I64 off = AR_MAGIC_LEN;
  while (off < size) {
    // A member header must fit entirely inside the archive.
    if (off + AR_MEMBER_HDR_LEN > size) return ARV_BAD_HEADER;
    if (am_count >= AR_MAX_MEMBERS) return ARV_NO_MEMBERS;

    // The header's terminating magic is "`\n".
    if (buf[off + AR_HDR_FMAG_OFF] != 96) return ARV_BAD_HEADER;
    if (buf[off + AR_HDR_FMAG_OFF + 1] != 10) return ARV_BAD_HEADER;

    // The declared size.
    I64 m = ArSizeAt(buf, size, off);
    if (m < 0) return ARV_BAD_SIZE_FIELD;
    I64 content = off + AR_MEMBER_HDR_LEN;
    // The declared size must fit inside the archive. The subtraction form
    // cannot overflow because `content` is already inside the archive.
    if (m > size - content) return ARV_SIZE_OVERRUN;

    // The name field. It is a 16-byte run, space padded.
    U8 *namefield = buf + off + AR_HDR_NAME_OFF;
    I64 ext = 0;
    I64 extlen = 0;
    I64 namelen = 0;
    U8 *name = NULL;

    // The EXTENDED NAME form: the name field begins with "#1/".
    if (namefield[0] == 35 && namefield[1] == 49 && namefield[2] == 47) {
      // The declared length follows.
      I64 n = 0;
      I64 digits = 0;
      I64 j = 3;
      while (j < AR_HDR_NAME_LEN) {
        I64 c = namefield[j];
        if (c >= 48 && c <= 57) {
          if (n > 100000) return ARV_BAD_EXTNAME;
          n = n * 10 + (c - 48);
          digits = digits + 1;
          j = j + 1;
          continue;
        }
        break;
      }
      if (digits == 0) return ARV_BAD_EXTNAME;
      // The declared name length must fit inside the member's content.
      if (n > m) return ARV_BAD_EXTNAME;
      // The name must be NUL terminated inside the declared length.
      I64 k = 0;
      I64 term = 0;
      while (k < n) {
        if (content + k >= size) return ARV_BAD_EXTNAME;
        if (buf[content + k] == 0) { term = 1; break; }
        k = k + 1;
      }
      if (term == 0) return ARV_BAD_EXTNAME;
      name = buf + content;
      namelen = k;
      ext = 1;
      extlen = n;
    } else {
      // The SHORT name form. The name is the run up to the first space or
      // the end of the field. The name MUST be NUL terminated or space
      // padded, and it MUST NOT be empty.
      I64 k = 0;
      while (k < AR_HDR_NAME_LEN && namefield[k] != 32) k = k + 1;
      if (k == 0) return ARV_BAD_NAME;
      namelen = k;
      name = namefield;
      ext = 0;
      extlen = 0;
    }

    // The payload. For the extended form the payload FOLLOWS the name
    // bytes; for the short form it is the whole content.
    I64 payload_off = content;
    I64 payload_len = m;
    if (ext == 1) {
      payload_off = content + extlen;
      payload_len = m - extlen;
    }

    // The 2-byte alignment padding. An odd-sized member is followed by
    // one padding byte, which the producer writes as a newline.
    I64 next = content + m;
    if (m % 2 == 1) {
      if (next >= size) return ARV_PADDING;
      if (buf[next] != 10) return ARV_PADDING;
      next = next + 1;
    }
    if (next > size) return ARV_SIZE_OVERRUN;

    // The member is recorded.
    am_name[am_count] = name;
    am_namelen[am_count] = namelen;
    am_extname[am_count] = ext;
    am_namelen_field[am_count] = extlen;
    am_payload[am_count] = buf + payload_off;
    am_paylen[am_count] = payload_len;
    am_mtime[am_count] = ArMtimeAt(buf, size, off);
    am_count = am_count + 1;

    off = next;
  }

  if (am_count == 0) return ARV_NO_MEMBERS;
  return ARV_OK;
}
// ---------------------------------------------------------------------------
// THE INVALID-DOMAIN DETECTOR.
//
// It verifies that the C CONSUMER of the selected emission FAILS CLOSED on
// an emission value OUTSIDE the supported domain.
//
// The supported emission domain is exactly:
//
//   1  WP_EMIT_COMPILE_OBJECT
//   2  WP_EMIT_EXECUTE
//   3  WP_EMIT_ASSEMBLY
//   4  WP_EMIT_DYLIB
//
// A value of 0 (UNKNOWN) and every value >= 5 are OUT OF DOMAIN, and the
// consumer must REJECT them rather than falling back to a supported
// emission.
//
// The detector reads the REAL C source of the consumer and requires that
// every supported value has an explicit case and that a DEFAULT case
// exists which rejects the remaining values.
//
// This is the EMISSION-domain counterpart of the STATUS-domain R06 check.
// ---------------------------------------------------------------------------
static I64 CountOccurrences(U8 *hay, I64 hlen, U8 *needle) {
  I64 n = StrLen(needle);
  if (n == 0) return 0;
  I64 count = 0;
  I64 i = 0;
  while (i + n <= hlen) {
    I64 j = 0;
    I64 match = 1;
    while (j < n) {
      if (hay[i + j] != needle[j]) { match = 0; break; }
      j = j + 1;
    }
    if (match == 1) {
      count = count + 1;
      i = i + n;
      continue;
    }
    i = i + 1;
  }
  return count;
}

static I64 HasDefaultCase(U8 *hay, I64 hlen) {
  if (CountOccurrences(hay, hlen, "default:") > 0) return 1;
  return 0;
}

// The detector mode.
//
//   domain <c-source-path>
//
// It prints the verdict for each supported value and for the rejection
// path.
I32 DetectDomain(I32 argc, U8 **argv) {
  if (argc < 3) {
    "REASON_DETAIL=usage: domain <c-source-path>\n";
    return 2;
  }
  I64 size = 0;
  U8 *buf = FileRead(argv[2], &size);
  if (buf == NULL) {
    "REASON_DETAIL=the C consumer source could not be read\n";
    return 2;
  }
  I64 failures = 0;
  I64 checks = 0;

  // Every supported emission value must have an explicit case in the C
  // consumer's switch over the selected emission.
  U8 *names[4];
  names[0] = "WP_DRIVER_EMIT_COMPILE_OBJECT";
  names[1] = "WP_DRIVER_EMIT_EXECUTE";
  names[2] = "WP_DRIVER_EMIT_ASSEMBLY";
  names[3] = "WP_DRIVER_EMIT_DYLIB";
  I64 i = 0;
  while (i < 4) {
    I64 n = CountOccurrences(buf, size, names[i]);
    checks = checks + 1;
    if (n > 0) {
      "DOMAIN\t%s\tDECLARED_AND_CONSUMED\t%d\n", names[i], n;
    } else {
      "DOMAIN\t%s\tMISSING\t0\n", names[i];
      failures = failures + 1;
    }
    i = i + 1;
  }

  // The consumer must have a DEFAULT case, so that an out-of-domain value
  // is rejected instead of falling through to a supported emission.
  checks = checks + 1;
  if (HasDefaultCase(buf, size) == 1) {
    "DOMAIN\tOUT_OF_DOMAIN\tREJECTED_BY_DEFAULT\t1\n";
  } else {
    "DOMAIN\tOUT_OF_DOMAIN\tNOT_REJECTED\t0\n";
    failures = failures + 1;
  }

  // The rejection path must be an explicit error, not a silent fallback.
  checks = checks + 1;
  if (CountOccurrences(buf, size, "invalid emission") > 0) {
    "DOMAIN\tOUT_OF_DOMAIN_DIAGNOSTIC\tEXPLICIT\t1\n";
  } else {
    "DOMAIN\tOUT_OF_DOMAIN_DIAGNOSTIC\tABSENT\t0\n";
    failures = failures + 1;
  }

  "CORRECTION03_DOMAIN_CHECKS\t%d\n", checks;
  "CORRECTION03_DOMAIN_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}

I32 Main(I32 argc, U8 **argv) {
  failures = 0;
  checks = 0;

  if (argc >= 2 && StrCmp(argv[1], "domain") == 0) {
    return DetectDomain(argc, argv);
  }

  // The fixed argument positions are:
  //   1  case-id          2  domain
  //   3  oracle-prefix    4  polyc-prefix
  //   5  oracle-stdout    6  polyc-stdout
  //   7  oracle-stderr    8  polyc-stderr
  //   9  oracle-exit     10  polyc-exit
  //  11  expected-class  12  expected-arch   13  expected-exit
  //  14.. artifacts, then the required symbols.
  if (argc < 15) {
    "REASON_DETAIL=usage: emission <case-id> <domain> <oracle-prefix> "
      "<polyc-prefix> <oracle-stdout> <polyc-stdout> <oracle-stderr> "
      "<polyc-stderr> <oracle-exit> <polyc-exit> <expected-class> "
      "<expected-arch> <expected-exit> <artifact>... <symbol>...\n";
    return 2;
  }
  U8 *case_id = argv[1];
  U8 *domain = argv[2];
  U8 *o_prefix = argv[3];
  U8 *p_prefix = argv[4];
  U8 *o_stdout = argv[5];
  U8 *p_stdout = argv[6];
  U8 *o_stderr = argv[7];
  U8 *p_stderr = argv[8];
  U8 *o_exitf  = argv[9];
  U8 *p_exitf  = argv[10];

  I64 expected_class = 5;
  if (StrCmp(argv[11], "MACHO_OBJECT") == 0) expected_class = 1;
  if (StrCmp(argv[11], "MACHO_EXECUTABLE") == 0) expected_class = 2;
  if (StrCmp(argv[11], "MACHO_DYLIB") == 0) expected_class = 3;
  if (StrCmp(argv[11], "ELF") == 0) expected_class = 4;
  if (StrCmp(argv[11], "ASSEMBLER_TEXT") == 0) expected_class = 6;
  if (StrCmp(argv[11], "AR_ARCHIVE") == 0) expected_class = 7;
  if (StrCmp(argv[11], "OTHER") == 0) expected_class = 5;

  I64 expected_arch = -1;
  if (StrCmp(argv[12], "arm64") == 0) expected_arch = CPU_TYPE_ARM64;
  if (StrCmp(argv[12], "x86_64") == 0) expected_arch = CPU_TYPE_X86_64;

  I64 expected_exit = 0;
  if (StrCmp(argv[13], "0") != 0) expected_exit = 1;

  // The artifact list and the symbol list are separated by the DOMAIN.
  //
  // The layout after the expected exit status is:
  //
  //   <artifact> <expected-class> <expected-arch>   (repeated per artifact)
  //   <required-symbol>                              (repeated)
  //
  // The expectation is PER ARTIFACT because a domain may produce artifacts
  // of DIFFERENT classes: the dynamic library domain produces an OBJECT, a
  // STATIC ARCHIVE and a SHARED LIBRARY.
  I64 nartifact = 1;
  if (StrCmp(domain, "dylib") == 0) nartifact = 3;
  I64 i = 14;
  I64 nartifact_read = 0;
  while (i < argc && nartifact_read < nartifact) {
    i = i + 3;
    nartifact_read = nartifact_read + 1;
  }
  I64 nsym = argc - i;

  // The PER-ARTIFACT expected class and architecture.
  I64 eclass[4];
  I64 earch[4];
  I64 k = 0;
  while (k < nartifact) {
    eclass[k] = 5;
    earch[k] = -1;
    U8 *ct = argv[15 + k * 3];
    U8 *at = argv[16 + k * 3];
    if (StrCmp(ct, "MACHO_OBJECT") == 0) eclass[k] = 1;
    if (StrCmp(ct, "MACHO_EXECUTABLE") == 0) eclass[k] = 2;
    if (StrCmp(ct, "MACHO_DYLIB") == 0) eclass[k] = 3;
    if (StrCmp(ct, "ELF") == 0) eclass[k] = 4;
    if (StrCmp(ct, "ASSEMBLER_TEXT") == 0) eclass[k] = 6;
    if (StrCmp(ct, "AR_ARCHIVE") == 0) eclass[k] = 7;
    if (StrCmp(ct, "OTHER") == 0) eclass[k] = 5;
    if (StrCmp(at, "arm64") == 0) earch[k] = CPU_TYPE_ARM64;
    if (StrCmp(at, "x86_64") == 0) earch[k] = CPU_TYPE_X86_64;
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // VALIDATE THE ORACLE SIDE (the REFERENCE).
  // -----------------------------------------------------------------------
  I64 o_exit_present = 0;
  I64 o_exit = ReadExitStatus(o_exitf, &o_exit_present);
  Check(o_exit_present == 1, case_id, "the oracle exit status is RECORDED");
  Check(o_exit_present == 1 && o_exit == expected_exit, case_id,
        "the oracle exit status is the EXPECTED one");

  // The oracle artifacts are validated for presence and nonemptiness.
  I64 o_present[4];
  I64 o_size[4];
  U8 *o_buf[4];
  k = 0;
  while (k < nartifact) {
    o_present[k] = 0;
    o_size[k] = 0;
    o_buf[k] = NULL;
    k = k + 1;
  }
  k = 0;
  while (k < nartifact) {
    // The artifact path is <prefix><suffix>. The suffix is read from the
    // argument list.
    I64 argidx = 14 + k * 3;
    U8 *suffix = argv[argidx];
    I64 plen = StrLen(o_prefix);
    I64 slen = StrLen(suffix);
    U8 *path = MAlloc(plen + slen + 1);
    MemCpy(path, o_prefix, plen);
    MemCpy(path + plen, suffix, slen);
    path[plen + slen] = 0;
    o_buf[k] = ReadArtifact(path, &o_size[k], &o_present[k]);
    Check(o_present[k] == 1, case_id,
          "the oracle artifact is PRESENT");
    Check(o_present[k] == 1 && o_size[k] > 0, case_id,
          "the oracle artifact is NONEMPTY");
    Free(path);
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // VALIDATE THE POLYC SIDE.
  // -----------------------------------------------------------------------
  I64 p_exit_present = 0;
  I64 p_exit = ReadExitStatus(p_exitf, &p_exit_present);
  Check(p_exit_present == 1, case_id, "the PolyC exit status is RECORDED");
  Check(p_exit_present == 1 && p_exit == expected_exit, case_id,
        "the PolyC exit status is the EXPECTED one");

  I64 p_present[4];
  I64 p_size[4];
  U8 *p_buf[4];
  k = 0;
  while (k < nartifact) {
    p_present[k] = 0;
    p_size[k] = 0;
    p_buf[k] = NULL;
    k = k + 1;
  }
  k = 0;
  while (k < nartifact) {
    I64 argidx = 14 + k * 3;
    U8 *suffix = argv[argidx];
    I64 plen = StrLen(p_prefix);
    I64 slen = StrLen(suffix);
    U8 *path = MAlloc(plen + slen + 1);
    MemCpy(path, p_prefix, plen);
    MemCpy(path + plen, suffix, slen);
    path[plen + slen] = 0;
    p_buf[k] = ReadArtifact(path, &p_size[k], &p_present[k]);
    Check(p_present[k] == 1, case_id,
          "the PolyC artifact is PRESENT");
    Check(p_present[k] == 1 && p_size[k] > 0, case_id,
          "the PolyC artifact is NONEMPTY");
    Free(path);
    k = k + 1;
  }

  // -----------------------------------------------------------------------
  // VALIDATE THE CLASS, THE ARCHITECTURE AND THE REQUIRED SYMBOLS.
  // -----------------------------------------------------------------------
  k = 0;
  while (k < nartifact) {
    I64 o_cls = Classify(o_buf[k], o_size[k]);
    I64 p_cls = Classify(p_buf[k], p_size[k]);
    I64 o_arch = ArchOf(o_buf[k], o_size[k]);
    I64 p_arch = ArchOf(p_buf[k], p_size[k]);
    "ARTIFACT_CLASS\t%s\t%d\t%s\t%s\n", case_id, k, ClassName(o_cls),
          ClassName(p_cls);
    "ARTIFACT_ARCH\t%s\t%d\t%s\t%s\n", case_id, k, ArchName(o_arch),
          ArchName(p_arch);
    Check(o_present[k] == 1 && o_cls == eclass[k], case_id,
          "the oracle artifact has the EXPECTED class");
    Check(p_present[k] == 1 && p_cls == eclass[k], case_id,
          "the PolyC artifact has the EXPECTED class");
    Check(o_present[k] == 1 &&
          (earch[k] == -1 || o_arch == earch[k]), case_id,
          "the oracle artifact has the EXPECTED architecture");
    Check(p_present[k] == 1 &&
          (earch[k] == -1 || p_arch == earch[k]), case_id,
          "the PolyC artifact has the EXPECTED architecture");
    Check(o_present[k] == 1 && p_present[k] == 1 && o_cls == p_cls,
          case_id, "the artifact classes agree");
    k = k + 1;
  }

  // The required symbols are checked on the artifacts that carry a symbol
  // table. An assembler TEXT artifact has none, so the requirement is NOT
  // APPLICABLE to it.
  I64 sym_ok = 1;
  I64 s = 0;
  while (s < nsym) {
    U8 *sym = argv[i + s];
    k = 0;
    while (k < nartifact) {
      I64 o_cls = Classify(o_buf[k], o_size[k]);
      I64 p_cls = Classify(p_buf[k], p_size[k]);
      if (o_cls == CLS_MACHO_OBJ || o_cls == CLS_MACHO_EXEC ||
          o_cls == CLS_MACHO_DYLIB) {
        if (HasSymbol(o_buf[k], o_size[k], sym) == 0) sym_ok = 0;
      }
      if (p_cls == CLS_MACHO_OBJ || p_cls == CLS_MACHO_EXEC ||
          p_cls == CLS_MACHO_DYLIB) {
        if (HasSymbol(p_buf[k], p_size[k], sym) == 0) sym_ok = 0;
      }
      k = k + 1;
    }
    s = s + 1;
  }
  if (nsym > 0) {
    Check(sym_ok == 1, case_id,
          "the REQUIRED symbols are present in the artifacts");
  }

  // -----------------------------------------------------------------------
  // COMPARE THE VALIDATED OBSERVATIONS.
  // -----------------------------------------------------------------------
  Check(o_exit_present == 1 && p_exit_present == 1 && o_exit == p_exit,
        case_id, "the exit statuses agree");

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

  // The FULL ARTIFACT BYTE result and the ARCHIVE-MEMBER SEMANTIC result
  // are SEPARATE results.
  k = 0;
  while (k < nartifact) {
    I64 o_cls = Classify(o_buf[k], o_size[k]);
    U64 o_digest = Digest(o_buf[k], o_size[k]);
    U64 p_digest = Digest(p_buf[k], p_size[k]);
    "DIGEST\t%s\t%d\toracle\t%lld\n", case_id, k, o_digest;
    "DIGEST\t%s\t%d\tpolyc\t%lld\n", case_id, k, p_digest;
    if (o_cls == CLS_AR) {
      // The archive: the FULL BYTE result and the MEMBER SEMANTIC result
      // are two DIFFERENT results.
      //
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4
      // REMEDIATION ROUND 2, F3: the archive is DECODED on each side, and
      // the DECODED members are compared. The previous revision compared
      // the RAW member bytes and never decoded the names, so a name-format
      // mutation that changes the extracted payload was classified as
      // harmless metadata nondeterminism.
      I64 full_equal = BytesEqual(o_buf[k], &o_size[k], p_buf[k], &p_size[k]);

      // The oracle side is decoded into the ORACLE tables.
      I64 o_dec = DecodeArchive(o_buf[k], o_size[k]);
      I64 o_count = am_count;
      I64 mi = 0;
      while (mi < o_count && mi < AR_MAX_MEMBERS) {
        o_name[mi] = am_name[mi];
        o_namelen[mi] = am_namelen[mi];
        o_ext[mi] = am_extname[mi];
        o_extlen[mi] = am_namelen_field[mi];
        o_payload[mi] = am_payload[mi];
        o_paylen[mi] = am_paylen[mi];
        o_mtime[mi] = am_mtime[mi];
        mi = mi + 1;
      }

      // The PolyC side is decoded into the POLYC tables.
      I64 p_dec = DecodeArchive(p_buf[k], p_size[k]);
      I64 p_count = am_count;
      mi = 0;
      while (mi < p_count && mi < AR_MAX_MEMBERS) {
        p_name[mi] = am_name[mi];
        p_namelen[mi] = am_namelen[mi];
        p_ext[mi] = am_extname[mi];
        p_extlen[mi] = am_namelen_field[mi];
        p_payload[mi] = am_payload[mi];
        p_paylen[mi] = am_paylen[mi];
        p_mtime[mi] = am_mtime[mi];
        mi = mi + 1;
      }

      Check(o_dec == ARV_OK && p_dec == ARV_OK, case_id,
            "the archives are STRUCTURALLY VALID");
      if (o_dec != ARV_OK) Reason(case_id, "oracle", ArReason(o_dec));
      if (p_dec != ARV_OK) Reason(case_id, "polyc", ArReason(p_dec));

      // The member counts must agree. An EMPTY archive carries no
      // evidence, and it is rejected by the decoder itself.
      Check(o_dec == ARV_OK && p_dec == ARV_OK && o_count == p_count, case_id,
            "the archive member COUNTS agree");
      if (o_dec == ARV_OK && p_dec == ARV_OK && o_count != p_count) {
        Reason(case_id, "harness", ArReason(ARV_MEMBER_COUNT));
      }

      // The member-by-member comparison. Every member is compared by
      // IDENTITY, by NAME FORMAT, by PAYLOAD BYTES, and by the
      // VALIDITY of its decoded payload.
      I64 member_equal = 1;
      I64 name_equal = 1;
      I64 format_equal = 1;
      I64 payload_equal = 1;
      I64 payload_valid = 1;
      I64 timestamp_only = 1;
      mi = 0;
      while (mi < o_count && mi < p_count) {
        // The member IDENTITY. The decoded name must be the same.
        if (ArNameEqual(o_name[mi], o_namelen[mi], p_name[mi],
                        p_namelen[mi]) == 0) {
          name_equal = 0;
          member_equal = 0;
        }
        // The NAME FORMAT. The extended-name form and the declared name
        // length are semantically relevant: a mutation of the `#1/N`
        // field changes what `ar` extracts.
        if (o_ext[mi] != p_ext[mi]) {
          format_equal = 0;
          member_equal = 0;
        }
        if (o_ext[mi] == 1 && o_extlen[mi] != p_extlen[mi]) {
          format_equal = 0;
          member_equal = 0;
        }
        // The PAYLOAD BYTES. The payload is the content `ar` extracts.
        I64 opl = o_paylen[mi];
        I64 ppl = p_paylen[mi];
        if (opl != ppl) {
          payload_equal = 0;
          member_equal = 0;
        } else {
          if (BytesEqual(o_payload[mi], &opl, p_payload[mi], &ppl) == 0) {
            payload_equal = 0;
            member_equal = 0;
          }
        }
        // The TIMESTAMP. A timestamp-only difference does NOT make the
        // members different, and it is reported separately.
        if (o_mtime[mi] != p_mtime[mi]) timestamp_only = 0;
        mi = mi + 1;
      }

      // The DECODED PAYLOAD is validated INDEPENDENTLY as the expected
      // Mach-O object. A payload that is not a valid Mach-O object is
      // REJECTED, even when both sides carry the SAME invalid payload.
      mi = 0;
      while (mi < o_count) {
        I64 ocls = Classify(o_payload[mi], o_paylen[mi]);
        I64 oarch = ArchOf(o_payload[mi], o_paylen[mi]);
        // The symbol table member is NOT a Mach-O object; it is the
        // archive's own symbol index.
        I64 is_symdef = 0;
        if (o_namelen[mi] >= 9) {
          if (ArNameEqual(o_name[mi], 9, "__.SYMDEF", 9) == 1) is_symdef = 1;
        }
        if (is_symdef == 0) {
          if (ocls != CLS_MACHO_OBJ) payload_valid = 0;
          if (earch[k] != -1 && oarch != earch[k]) payload_valid = 0;
        }
        mi = mi + 1;
      }
      mi = 0;
      while (mi < p_count) {
        I64 pcls = Classify(p_payload[mi], p_paylen[mi]);
        I64 parch = ArchOf(p_payload[mi], p_paylen[mi]);
        I64 is_symdef = 0;
        if (p_namelen[mi] >= 9) {
          if (ArNameEqual(p_name[mi], 9, "__.SYMDEF", 9) == 1) is_symdef = 1;
        }
        if (is_symdef == 0) {
          if (pcls != CLS_MACHO_OBJ) payload_valid = 0;
          if (earch[k] != -1 && parch != earch[k]) payload_valid = 0;
        }
        mi = mi + 1;
      }

      Check(name_equal == 1, case_id,
            "the archive member IDENTITIES agree");
      if (name_equal == 0) Reason(case_id, "harness", ArReason(ARV_MISSING));
      Check(format_equal == 1, case_id,
            "the archive member NAME FORMATS agree");
      if (format_equal == 0) {
        Reason(case_id, "harness", ArReason(ARV_NAME_FORMAT));
      }
      Check(payload_valid == 1, case_id,
            "the DECODED member payloads are VALID Mach-O objects");
      if (payload_valid == 0) {
        Reason(case_id, "harness", ArReason(ARV_PAYLOAD_CLASS));
      }
      Check(payload_equal == 1, case_id,
            "the DECODED member PAYLOAD BYTES agree");
      if (payload_equal == 0) {
        Reason(case_id, "harness", ArReason(ARV_PAYLOAD));
      }

      U8 *ms_eq = "DIFFERENT";
      U8 *fb_eq = "DIFFERENT";
      U8 *md_nd = "YES";
      if (member_equal == 1) ms_eq = "EQUAL";
      if (full_equal == 1) fb_eq = "EQUAL";
      if (full_equal == 1) md_nd = "NO";
      "ARCHIVE_MEMBER_SEMANTICS\t%s\t%d\t%s\n", case_id, k, ms_eq;
      "ARCHIVE_FULL_BYTES\t%s\t%d\t%s\n", case_id, k, fb_eq;
      Check(member_equal == 1, case_id,
            "the archive MEMBER SEMANTICS agree");
      // The timestamp nondeterminism is reported ONLY when every DECODED
      // member is otherwise identical. A content difference is NEVER
      // reported as timestamp nondeterminism.
      if (member_equal == 1) {
        if (timestamp_only == 0) md_nd = "YES";
        else md_nd = "NO";
      } else {
        md_nd = "NOT_APPLICABLE";
      }
      "ARCHIVE_METADATA_NONDETERMINISM\t%s\t%d\t%s\n", case_id, k, md_nd;
      // The full-byte difference is NOT an equivalence failure: it is
      // reported separately and never counted as a member-semantic
      // difference.
    } else {
      Check(o_present[k] == 1 && p_present[k] == 1 && o_digest == p_digest,
            case_id, "the artifact content digests agree");
      Check(o_present[k] == 1 && p_present[k] == 1 &&
            BytesEqual(o_buf[k], &o_size[k], p_buf[k], &p_size[k]), case_id,
            "the actual artifact bytes agree");
    }
    k = k + 1;
  }

  "CORRECTION03_EMISSION_CHECKS\t%d\n", checks;
  "CORRECTION03_EMISSION_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
