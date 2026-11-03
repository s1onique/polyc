// tools/quality/driver-required-route-correction03-contract.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3.
//
// THE SHARED VALIDATED-OBSERVATION CONTRACT.
//
// THE GOVERNING PRINCIPLE OF THIS ROUND:
//
//   Repair the evidence architecture rather than layering another set of
//   partial validators onto it.
//
// The three responsibilities are SEPARATED:
//
//   1. EXECUTION  -- a trusted local harness runs a real compiler and
//                    records what actually happened. It owns the invocation.
//   2. VALIDATION -- this file. It establishes that the captured artifacts
//                    and observations are STRUCTURALLY VALID.
//   3. COMPARISON -- the comparator evaluates valid OFF/ON observations
//                    against the frozen equivalence contract.
//
// NO COMPONENT MAY CERTIFY EXECUTION MERELY FROM THE EXISTENCE OF MATCHING
// FILES, HASHES OR LEDGER ENTRIES.
//
// The previous round kept TWO INCOMPATIBLE VALIDATORS: the comparator and
// the emission verifier each had their own, weaker, Mach-O reader and their
// own exit-status reader. The emission verifier accepted identical malformed
// Mach-O payloads, archives with only symbol-index bookkeeping, and exit
// records with trailing garbage. The comparator was stricter.
//
// THIS FILE IS THE SINGLE CONTRACT. The comparator and the emission verifier
// BOTH use it. There is now exactly ONE Mach-O validator, ONE exit-status
// codec and ONE archive decoder in the CORRECTION03 evidence path.
//
// The reasons are DISTINCT so a reviewer can tell WHICH property was
// violated.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-sha256.HC"

// ---------------------------------------------------------------------------
// THE ARTIFACT CLASSES.
// ---------------------------------------------------------------------------
#define CLS_ABSENT      0
#define CLS_MACHO_OBJ   1
#define CLS_MACHO_EXEC  2
#define CLS_MACHO_DYLIB 3
#define CLS_ELF         4
#define CLS_OTHER       5
#define CLS_TEXT        6
#define CLS_AR_ARCHIVE  7

// The Mach-O CPU types.
#define CPU_TYPE_ARM64  0x0100000C
#define CPU_TYPE_X86_64 0x01000007

// The Mach-O file types.
#define MH_OBJECT      1
#define MH_EXECUTE     2
#define MH_DYLIB       6

// The load commands the validator understands.
#define LC_SEGMENT_64  0x19
#define LC_SYMTAB      0x02
#define LC_DYSYMTAB    0x0B

// The sizes.
#define MACHO_HEADER_SIZE 32
#define NLIST64_SIZE     16
#define SEGMENT64_SIZE   72
#define SYMTAB_CMDSZ     24
#define DYSYMTAB_CMDSZ   80

// The little-endian word reader. It returns -1 when the four bytes are not
// inside the buffer, so a caller can never read past the end.
static I64 ContractWordAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + 4) return -1;
  I64 v = 0;
  I64 i = off + 3;
  while (i >= off) { v = v * 256 + buf[i]; i = i - 1; }
  return v;
}

// The class of a byte run.
static I64 ContractClassify(U8 *buf, I64 size) {
  if (buf == NULL) return CLS_ABSENT;
  if (size == 0) return CLS_OTHER;
  // The `ar` global header.
  if (size >= 8) {
    I64 k = 0;
    I64 same = 1;
    while (k < 8) {
      if (buf[k] != "!<arch>\n"[k]) { same = 0; break; }
      k = k + 1;
    }
    if (same == 1) return CLS_AR_ARCHIVE;
  }
  I64 magic = ContractWordAt(buf, size, 0);
  if (magic == 0xFEEDFACF) {
    I64 type = ContractWordAt(buf, size, 12);
    if (type == MH_OBJECT) return CLS_MACHO_OBJ;
    if (type == MH_EXECUTE) return CLS_MACHO_EXEC;
    if (type == MH_DYLIB) return CLS_MACHO_DYLIB;
    return CLS_OTHER;
  }
  if (magic == 0x7F454C46) return CLS_ELF;
  // An assembler text artifact is not a Mach-O image.
  if (size > 4) {
    if (buf[0] == '.' || buf[0] == '#' || buf[0] == '_' || buf[0] == '/') {
      return CLS_TEXT;
    }
  }
  return CLS_OTHER;
}

static U8 *ContractClassName(I64 cls) {
  if (cls == CLS_ABSENT) return "ABSENT";
  if (cls == CLS_MACHO_OBJ) return "MACHO_OBJECT";
  if (cls == CLS_MACHO_EXEC) return "MACHO_EXECUTABLE";
  if (cls == CLS_MACHO_DYLIB) return "MACHO_DYLIB";
  if (cls == CLS_ELF) return "ELF";
  if (cls == CLS_AR_ARCHIVE) return "AR_ARCHIVE";
  if (cls == CLS_TEXT) return "ASSEMBLER_TEXT";
  return "OTHER";
}

static U8 *ContractArchName(I64 arch) {
  if (arch == CPU_TYPE_ARM64) return "arm64";
  if (arch == CPU_TYPE_X86_64) return "x86_64";
  return "none";
}

static I64 ContractArchOf(U8 *buf, I64 size) {
  if (buf == NULL) return -1;
  if (size < MACHO_HEADER_SIZE) return -1;
  if (ContractWordAt(buf, size, 0) != 0xFEEDFACF) return -1;
  return ContractWordAt(buf, size, 4);
}

// ---------------------------------------------------------------------------
// THE MACH-O VALIDATION RESULT CODES.
//
// The codes are DISTINCT so a reviewer can tell WHICH structural property
// was violated. They are also the reason tokens the harness prints.
// ---------------------------------------------------------------------------
#define MV_OK                    0
#define MV_ABSENT                1
#define MV_EMPTY                 2
#define MV_BAD_MAGIC             3
#define MV_BAD_HEADER            4
#define MV_BAD_CPUTYPE           5
#define MV_BAD_FILETYPE          6
#define MV_BAD_NCMDS             7
#define MV_BAD_SIZEOFCMDS        8
#define MV_LOADCMD_OVERRUN       9
#define MV_LOADCMD_SIZE         10
#define MV_NO_SYMTAB            11
#define MV_SYMTAB_STRUCT        12
#define MV_SYMTAB_BOUNDS        13
#define MV_STRTAB_BOUNDS        14
#define MV_STRIDX_BOUNDS        15
#define MV_SEGMENT_BOUNDS       16
#define MV_SEGMENT_STRUCT       17
#define MV_SECTION_BOUNDS       18
#define MV_DYSYMTAB_BOUNDS      19
#define MV_DUPLICATE_SYMTAB     20
#define MV_DUPLICATE_SEGMENT    21
#define MV_RELOCATION_BOUNDS     22
#define MV_SECTION_OVERLAP       23

static U8 *ContractMachOReason(I64 code) {
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
  if (code == MV_SEGMENT_BOUNDS) return "MACHO_SEGMENT_EXTENT_OUT_OF_BOUNDS";
  if (code == MV_SEGMENT_STRUCT) return "MACHO_SEGMENT_STRUCTURE_INVALID";
  if (code == MV_SECTION_BOUNDS) return "MACHO_SECTION_EXTENT_OUT_OF_BOUNDS";
  if (code == MV_DYSYMTAB_BOUNDS) return "MACHO_LC_DYSYMTAB_OUT_OF_BOUNDS";
  if (code == MV_DUPLICATE_SYMTAB) return "MACHO_DUPLICATE_LC_SYMTAB";
  if (code == MV_DUPLICATE_SEGMENT) return "MACHO_DUPLICATE_LC_SEGMENT_64";
  if (code == MV_RELOCATION_BOUNDS) return "MACHO_RELOCATION_OUT_OF_BOUNDS";
  if (code == MV_SECTION_OVERLAP) return "MACHO_SECTION_EXTENT_INVALID";
  return "MACHO_UNKNOWN";
}

// The validated Mach-O facts. They are filled by ContractValidateMachO and
// are the ONLY source the symbol lookup uses, so the symbol lookup can never
// read past a bound that the validator has already proved.
static I64 vm_symoff;
static I64 vm_nsyms;
static I64 vm_stroff;
static I64 vm_strsize;

// The validated segment count and the dysymtab presence.
static I64 vm_nsegments;
static I64 vm_has_dysymtab;

// The MAXIMUM number of load commands and segments the validator accepts.
// The bounds are finite so a hostile count cannot drive an unbounded walk.
#define MV_MAX_LOADCMDS 4096
#define MV_MAX_SEGMENTS 128
#define MV_MAX_SECTIONS  4096

// The section count seen across all segments.
static I64 vm_nsections;

// The section extents that were validated. They are checked for OVERLAP so a
// pair of sections that claim the same bytes is rejected.
static I64 vm_sec_off[MV_MAX_SECTIONS];
static I64 vm_sec_size[MV_MAX_SECTIONS];

// ---------------------------------------------------------------------------
// THE STRUCTURAL MACH-O VALIDATOR.
//
// PHASE ONE: VALIDATE THE ENTIRE IMAGE.
//
// The validator walks EVERY load command and checks EVERY structural
// property of the image BEFORE any symbol lookup happens. A defect in a
// symbol entry that appears AFTER the required `_main` therefore rejects the
// image, exactly as a defect BEFORE `_main` does.
//
// The previous revision returned EARLY from the symbol lookup as soon as it
// found the requested symbol, so an invalid entry after `_main` was never
// examined and the image was accepted. That is the F3 defect this function
// removes.
//
// PHASE TWO: SEARCH THE VALIDATED SYMBOL RECORDS.
//
// The lookup uses ONLY the facts phase one proved. It cannot read past a
// bound that phase one has already established.
//
// ALL the bound arithmetic is OVERFLOW-SAFE. A declared count or offset is a
// 32-bit unsigned value carried in a signed 64-bit accumulator, so a
// multiplication of a symbol count by the 16-byte nlist size cannot wrap.
// The checks are written as "off <= size" and "count <= (size - off) / 16"
// rather than "off + count * 16 <= size", so no intermediate product can
// overflow.
// ---------------------------------------------------------------------------

// The section-extent overlap check. Two sections that claim the same file
// bytes are an inconsistent structural declaration.
static I64 ContractSectionsOverlap(I64 n) {
  I64 i = 0;
  while (i < n) {
    I64 j = i + 1;
    while (j < n) {
      I64 a0 = vm_sec_off[i];
      I64 a1 = vm_sec_size[i];
      I64 b0 = vm_sec_off[j];
      I64 b1 = vm_sec_size[j];
      // An EMPTY section claims no bytes and cannot overlap.
      if (a1 > 0 && b1 > 0) {
        // The overlap test is written as "a0 < b0 + b1 && b0 < a0 + a1",
        // and the sums are computed from values that are already known to
        // be inside the file, so they cannot overflow.
        if (a0 < b0 + b1 && b0 < a0 + a1) return 1;
      }
      j = j + 1;
    }
    i = i + 1;
  }
  return 0;
}

// The validator. `require_symtab` is 1 when the class is expected to carry a
// symbol table (an object, an executable or a dynamic library) and 0
// otherwise.
//
// It returns MV_OK when the image is structurally valid, and otherwise the
// FIRST violated property's code. The FIRST violation is reported so the
// reason is deterministic.
static I64 ContractValidateMachO(U8 *buf, I64 size, I64 require_symtab) {
  vm_symoff = 0;
  vm_nsyms = 0;
  vm_stroff = 0;
  vm_strsize = 0;
  vm_nsegments = 0;
  vm_has_dysymtab = 0;
  vm_nsections = 0;

  if (buf == NULL) return MV_ABSENT;
  if (size == 0) return MV_EMPTY;
  if (size < MACHO_HEADER_SIZE) return MV_BAD_HEADER;
  if (ContractWordAt(buf, size, 0) != 0xFEEDFACF) return MV_BAD_MAGIC;

  // The declared CPU type must be a type the comparator understands.
  I64 cputype = ContractWordAt(buf, size, 4);
  if (cputype != CPU_TYPE_ARM64 && cputype != CPU_TYPE_X86_64) {
    return MV_BAD_CPUTYPE;
  }
  // The declared file type must be one of the three Mach-O image kinds.
  I64 filetype = ContractWordAt(buf, size, 12);
  if (filetype != MH_OBJECT && filetype != MH_EXECUTE && filetype != MH_DYLIB) {
    return MV_BAD_FILETYPE;
  }

  // The load-command count and the declared load-command extent.
  I64 ncmds = ContractWordAt(buf, size, 16);
  I64 sizeofcmds = ContractWordAt(buf, size, 20);
  if (ncmds < 0 || ncmds > MV_MAX_LOADCMDS) return MV_BAD_NCMDS;
  if (sizeofcmds < 0) return MV_BAD_SIZEOFCMDS;
  // The declared load-command extent must lie inside the file. The
  // subtraction form cannot overflow because sizeofcmds is already bounded
  // to be non-negative and the header is already inside the file.
  if (sizeofcmds > size - MACHO_HEADER_SIZE) return MV_BAD_SIZEOFCMDS;

  // Walk the load commands. Every one must lie inside the DECLARED extent
  // and inside the file, and every one must have a plausible size.
  I64 off = MACHO_HEADER_SIZE;
  I64 limit = MACHO_HEADER_SIZE + sizeofcmds;
  I64 i = 0;
  I64 found_symtab = 0;
  I64 found_dysymtab = 0;
  while (i < ncmds) {
    if (off > limit - 8) return MV_LOADCMD_OVERRUN;
    I64 cmd = ContractWordAt(buf, size, off);
    I64 cmdsize = ContractWordAt(buf, size, off + 4);
    if (cmdsize < 8) return MV_LOADCMD_SIZE;
    if (cmdsize > limit - off) return MV_LOADCMD_OVERRUN;

    if (cmd == LC_SYMTAB) {
      // A SECOND LC_SYMTAB is an inconsistent structural declaration.
      if (found_symtab == 1) return MV_DUPLICATE_SYMTAB;
      // The LC_SYMTAB load command is EXACTLY 24 bytes.
      if (cmdsize != SYMTAB_CMDSZ) return MV_SYMTAB_STRUCT;
      I64 symoff = ContractWordAt(buf, size, off + 8);
      I64 nsyms = ContractWordAt(buf, size, off + 12);
      I64 stroff = ContractWordAt(buf, size, off + 16);
      I64 strsize = ContractWordAt(buf, size, off + 20);
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

    if (cmd == LC_DYSYMTAB) {
      if (found_dysymtab == 1) return MV_DYSYMTAB_BOUNDS;
      // The LC_DYSYMTAB load command is EXACTLY 80 bytes.
      if (cmdsize != DYSYMTAB_CMDSZ) return MV_DYSYMTAB_BOUNDS;
      // The three table extents the dysymtab declares. Each of them must
      // lie inside the file. The comparison form cannot overflow because
      // each count is checked against the remaining bytes.
      I64 extents[3];
      extents[0] = ContractWordAt(buf, size, off + 32);   // table of contents
      extents[1] = ContractWordAt(buf, size, off + 40);   // module table
      extents[2] = ContractWordAt(buf, size, off + 56);   // external reloc
      I64 counts[3];
      counts[0] = ContractWordAt(buf, size, off + 36);
      counts[1] = ContractWordAt(buf, size, off + 44);
      counts[2] = ContractWordAt(buf, size, off + 60);
      I64 e = 0;
      while (e < 3) {
        if (extents[e] < 0 || counts[e] < 0) return MV_DYSYMTAB_BOUNDS;
        if (extents[e] > size) return MV_DYSYMTAB_BOUNDS;
        // A count of zero places no requirement on the extent.
        if (counts[e] > 0) {
          if (counts[e] > (size - extents[e]) / 4) {
            return MV_DYSYMTAB_BOUNDS;
          }
        }
        e = e + 1;
      }
      found_dysymtab = 1;
      vm_has_dysymtab = 1;
    }

    if (cmd == LC_SEGMENT_64) {
      // The LC_SEGMENT_64 load command is AT LEAST 72 bytes: the base
      // segment_command_64 struct, followed by the section table, which is
      // 80 bytes per section. A segment with N sections therefore has
      // cmdsize == 72 + 80 * N.
      //
      // The previous revision required cmdsize to be EXACTLY 72, which
      // rejected every real Mach-O image that carries sections.
      if (cmdsize < SEGMENT64_SIZE) return MV_SEGMENT_STRUCT;
      if (vm_nsegments >= MV_MAX_SEGMENTS) return MV_SEGMENT_STRUCT;
      // The segment's file extent.
      I64 fileoff = ContractWordAt(buf, size, off + 40);
      I64 filesize = ContractWordAt(buf, size, off + 48);
      // The segment's in-memory extent.
      I64 vmaddr = ContractWordAt(buf, size, off + 24);
      I64 vmsize = ContractWordAt(buf, size, off + 32);
      I64 maxprot = ContractWordAt(buf, size, off + 56);
      I64 initprot = ContractWordAt(buf, size, off + 60);
      if (fileoff < 0 || filesize < 0) return MV_SEGMENT_STRUCT;
      if (vmaddr < 0 || vmsize < 0) return MV_SEGMENT_STRUCT;
      // The file extent must lie inside the file. The subtraction form
      // cannot overflow because filesize is already non-negative and the
      // extent is checked against the file size.
      if (fileoff > size) return MV_SEGMENT_BOUNDS;
      if (filesize > size - fileoff) return MV_SEGMENT_BOUNDS;
      // The in-memory extent must not wrap the address space.
      if (vmsize > 0) {
        if (vmaddr > 0x7FFFFFFFFFFF - vmsize) return MV_SEGMENT_STRUCT;
      }
      // The protection fields must not grant more than the maximum.
      if ((initprot & ~maxprot) != 0) return MV_SEGMENT_STRUCT;

      // The section table. It is 80 bytes per section.
      I64 nsects = ContractWordAt(buf, size, off + 64);
      if (nsects < 0) return MV_SEGMENT_STRUCT;
      if (nsects > (cmdsize - SEGMENT64_SIZE) / 80) return MV_SEGMENT_STRUCT;
      I64 s = 0;
      while (s < nsects) {
        I64 soff = off + SEGMENT64_SIZE + s * 80;
        I64 sec_size = ContractWordAt(buf, size, soff + 40);
        I64 sec_offset = ContractWordAt(buf, size, soff + 48);
        I64 sec_align = ContractWordAt(buf, size, soff + 52);
        I64 reloff = ContractWordAt(buf, size, soff + 56);
        I64 nreloc = ContractWordAt(buf, size, soff + 60);
        I64 sec_flags = ContractWordAt(buf, size, soff + 64);
        if (sec_size < 0 || sec_offset < 0) return MV_SECTION_BOUNDS;
        if (reloff < 0 || nreloc < 0) return MV_SECTION_BOUNDS;
        if (sec_align < 0) return MV_SECTION_BOUNDS;
        // A section with CONTENT must lie inside the file.
        if (sec_size > 0) {
          if (sec_offset > size) return MV_SECTION_BOUNDS;
          if (sec_size > size - sec_offset) return MV_SECTION_BOUNDS;
        }
        // The relocations must lie inside the file. Each relocation is 8
        // bytes.
        if (nreloc > 0) {
          if (reloff > size) return MV_RELOCATION_BOUNDS;
          if (nreloc > (size - reloff) / 8) return MV_RELOCATION_BOUNDS;
        }
        // A ZERO-FILL section claims no file bytes.
        if ((sec_flags & 255) == 1) {
          if (sec_size > 0 && sec_offset != 0) return MV_SECTION_BOUNDS;
        }
        // Record the extent for the overlap check.
        if (vm_nsections >= MV_MAX_SECTIONS) return MV_SECTION_BOUNDS;
        vm_sec_off[vm_nsections] = sec_offset;
        vm_sec_size[vm_nsections] = sec_size;
        vm_nsections = vm_nsections + 1;
        s = s + 1;
      }
      vm_nsegments = vm_nsegments + 1;
    }

    off = off + cmdsize;
    i = i + 1;
  }
  // The load commands must exactly fill the declared extent.
  if (off != limit) return MV_BAD_SIZEOFCMDS;

  // Two sections that claim the same file bytes are an inconsistent
  // structural declaration.
  if (ContractSectionsOverlap(vm_nsections) == 1) return MV_SECTION_OVERLAP;

  if (require_symtab == 1 && found_symtab == 0) return MV_NO_SYMTAB;
  return MV_OK;
}

// ---------------------------------------------------------------------------
// PHASE TWO: THE SYMBOL SEARCH.
//
// The search is performed ONLY on an image that phase one has already
// validated. It uses ONLY the facts phase one proved.
//
// THE CRITICAL PROPERTY: the search does NOT return EARLY.
//
// The previous revision returned as soon as it found the requested symbol,
// so a symbol entry that appeared AFTER `_main` and carried an invalid
// string index was never examined. The independent review reproduced
// exactly that: an image with a valid `_main` followed by an invalid entry
// was accepted.
//
// The repaired search EXAMINES EVERY symbol entry and validates EVERY entry's
// string index BEFORE it reports whether the requested symbol is present.
// A malformed entry ANYWHERE in the table rejects the image.
// ---------------------------------------------------------------------------
static I64 ContractHasSymbolChecked(U8 *buf, I64 size, U8 *name,
                                    I64 *stridx_bad) {
  *stridx_bad = 0;
  if (buf == NULL) return 0;
  // The image MUST have been structurally validated. The caller validates
  // it before it reaches here; this is the belt to that suspenders.
  if (ContractValidateMachO(buf, size, 1) != MV_OK) return 0;
  if (vm_nsyms == 0) return 0;

  I64 namelen = StrLen(name);
  I64 found = 0;
  I64 k = 0;
  while (k < vm_nsyms) {
    // The entry offset is inside the file because the validator proved
    // that vm_nsyms entries of NLIST64_SIZE bytes fit at vm_symoff.
    I64 entry = vm_symoff + k * NLIST64_SIZE;
    I64 n_strx = ContractWordAt(buf, size, entry);
    // EVERY accessed symbol-string index must lie inside the string table.
    // An index that does not is a STRUCTURAL defect, not a missing symbol,
    // and it rejects the image -- EVEN IF THE REQUESTED SYMBOL WAS ALREADY
    // FOUND IN AN EARLIER ENTRY.
    if (n_strx < 0 || n_strx >= vm_strsize) {
      *stridx_bad = 1;
      return 0;
    }
    // The name must be NUL-terminated inside the string table.
    I64 p = vm_stroff + n_strx;
    I64 q = 0;
    I64 terminated = 0;
    while (q < vm_strsize - n_strx) {
      if (buf[p + q] == 0) { terminated = 1; break; }
      q = q + 1;
    }
    if (terminated == 0) {
      // The string table entry is not NUL-terminated. That is a structural
      // defect and it rejects the image.
      *stridx_bad = 1;
      return 0;
    }
    // The name comparison. The requested name must match the WHOLE
    // terminated string, so "main" does not match "mainx".
    if (found == 0 && q == namelen) {
      I64 r = 0;
      I64 match = 1;
      while (r < namelen) {
        if (buf[p + r] != name[r]) { match = 0; break; }
        r = r + 1;
      }
      if (match == 1) found = 1;
    }
    k = k + 1;
  }
  return found;
}

// The convenience wrapper. It keeps the "the symbol is present" semantics but
// it now REJECTS an image whose string indices are out of range, because a
// malformed image must not be able to satisfy a symbol requirement.
static I64 ContractHasSymbol(U8 *buf, I64 size, U8 *name) {
  I64 bad = 0;
  return ContractHasSymbolChecked(buf, size, name, &bad);
}

// The symbol-count validator. It validates EVERY symbol entry's string index
// and reports the count of validated entries.
//
// It is the "the whole symbol table is well formed" check that the
// comparator and the emission verifier BOTH apply.
static I64 ContractValidateSymbolTable(U8 *buf, I64 size, I64 *stridx_bad) {
  *stridx_bad = 0;
  if (buf == NULL) return 0;
  if (ContractValidateMachO(buf, size, 1) != MV_OK) return 0;
  I64 k = 0;
  while (k < vm_nsyms) {
    I64 entry = vm_symoff + k * NLIST64_SIZE;
    I64 n_strx = ContractWordAt(buf, size, entry);
    if (n_strx < 0 || n_strx >= vm_strsize) {
      *stridx_bad = 1;
      return 0;
    }
    I64 p = vm_stroff + n_strx;
    I64 q = 0;
    I64 terminated = 0;
    while (q < vm_strsize - n_strx) {
      if (buf[p + q] == 0) { terminated = 1; break; }
      q = q + 1;
    }
    if (terminated == 0) {
      *stridx_bad = 1;
      return 0;
    }
    k = k + 1;
  }
  return vm_nsyms;
}

// ---------------------------------------------------------------------------
// THE EXIT-STATUS CODEC.
//
// THE F2 DEFECT.
//
// The previous revision's ENCODER reversed the decimal digits IN PLACE:
//
//   exit_text[r] = exit_text[n - 1 - r];
//
// The write position and the read position were THE SAME BUFFER. The
// reversal therefore DESTROYED the digits as it read them: "42" became
// "24", "127" became "721", and "10" became "01".
//
// The repair uses SEPARATE READ AND WRITE POSITIONS. The digits are read
// from one buffer and written into ANOTHER, so no write can overwrite a
// digit that has not yet been read.
//
// The EXACT ROUND TRIP is required for:
//
//   0, 1, 9, 10, 12, 42, 127, 255
//
// and the codec REJECTS:
//
//   * a negative value,
//   * a value above 255,
//   * an integer overflow,
//   * trailing text,
//   * additional lines,
//   * a missing record.
//
// A CORRECTED ENCODER WITH AN INCORRECT DECODER IS NOT A DISCHARGE, so both
// directions are exercised by the self-test.
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

static U8 *ContractExitReason(I64 code) {
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

// The DECODER. It reads the exit-status record and reports the value and
// the validation code.
//
// The record MUST consist of decimal digits ONLY, MAY be terminated by
// EXACTLY ONE trailing newline, and MUST NOT carry trailing text, extra
// tokens, a negative sign, a plus sign, or any other byte. The value MUST
// fit in the range of a process exit status, and the accumulation MUST NOT
// overflow.
//
// The accumulation is overflow-safe: the value is checked against the
// maximum BEFORE it is multiplied, so no intermediate product can exceed
// the accumulator's range.
static I64 ContractReadExitStatus(U8 *buf, I64 size, I64 *value,
                                   I64 *code) {
  *value = 0;
  *code = EXIT_OK;
  if (buf == NULL) {
    *code = EXIT_MISSING;
    return 0;
  }
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

// The ENCODER.
//
// THE REPAIR: the READ POSITION and the WRITE POSITION are SEPARATE
// BUFFERS. The digits are read from `digits` and written into `out`, so no
// write can overwrite a digit that has not yet been read.
//
// `out_len` receives the number of bytes written (the decimal digits, with
// NO trailing newline).
//
// It returns 0 when the value cannot be represented, and the reason code
// otherwise.
static I64 ContractWriteExitStatus(I64 value, U8 *out, I64 out_cap,
                                   I64 *out_len, I64 *code) {
  *out_len = 0;
  *code = EXIT_OK;
  if (value < 0) {
    *code = EXIT_NEGATIVE;
    return 0;
  }
  if (value > EXIT_MAX) {
    *code = EXIT_RANGE;
    return 0;
  }
  // The decimal digits, produced in REVERSE order into a SEPARATE buffer.
  // The buffer is at most 3 digits wide because the value is at most 255.
  U8 digits[4];
  I64 n = 0;
  I64 v = value;
  if (v == 0) {
    digits[0] = 48;
    n = 1;
  }
  while (v > 0) {
    digits[n] = 48 + (v % 10);
    v = v / 10;
    n = n + 1;
  }
  if (n > out_cap) {
    *code = EXIT_RANGE;
    return 0;
  }
  // The SEPARATE WRITE POSITION copies the digits back into order. The
  // source and the destination are DIFFERENT buffers, so the copy cannot
  // destroy a digit that has not yet been read.
  I64 w = 0;
  while (w < n) {
    I64 src = n - 1 - w;
    out[w] = digits[src];
    w = w + 1;
  }
  out[n] = 0;
  *out_len = n;
  return 1;
}

// The file-level reader. It reads the record and decodes it.
static I64 ContractReadExitStatusFile(U8 *path, I64 *value, I64 *code) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    *value = 0;
    *code = EXIT_MISSING;
    return 0;
  }
  return ContractReadExitStatus(buf, size, value, code);
}

// ---------------------------------------------------------------------------
// THE ARCHIVE DECODER.
//
// THE F4 DEFECT.
//
// The previous revision's `ArNameEqual` compared only the COMMON PREFIX of
// the two names:
//
//   I64 n = alen;
//   if (blen < n) n = blen;
//   ... compare the first n bytes ...
//   return 1;
//
// so "source.o" and "source" compared EQUAL. The independent review
// reproduced that: a member whose decoded name is "source.o" satisfied a
// requirement for "source".
//
// THE REPAIR: equality requires BOTH
//
//   * EQUAL DECODED NAME LENGTHS, and
//   * EQUAL DECODED BYTES.
//
// The four things an `ar` archive carries are kept DISTINCT:
//
//   1. THE RAW HEADER REPRESENTATION -- the 16 bytes of the name field as
//      they appear in the file. Two archives may encode the SAME member in
//      DIFFERENT raw representations.
//   2. THE DECODED MEMBER IDENTITY -- the member's name after the archive's
//      name encoding has been decoded. This is what the requirement is
//      about.
//   3. THE MEMBER PAYLOAD -- the member's bytes.
//   4. THE ARCHIVE BOOKKEEPING METADATA -- the timestamp, the owner, the
//      mode and the padding.
//
// TWO VALID ARCHIVE ENCODINGS of the SAME decoded member name and payload
// MUST remain semantically equivalent. So the comparison uses the DECODED
// IDENTITY and the PAYLOAD, never the raw header bytes.
// ---------------------------------------------------------------------------
#define AR_MAGIC_LEN      8
#define AR_MEMBER_HDR_LEN 60
#define AR_MAX_MEMBERS    256

// The archive decoding result codes.
#define AR_OK                  0
#define AR_ABSENT              1
#define AR_BAD_MAGIC           2
#define AR_HEADER_OVERRUN      3
#define AR_BAD_SIZE_FIELD      4
#define AR_MEMBER_OVERRUN      5
#define AR_BAD_EXTENDED_NAME   6
#define AR_TOO_MANY_MEMBERS    7
#define AR_EMPTY_MEMBER        8

static U8 *ContractArReason(I64 code) {
  if (code == AR_OK) return "OK";
  if (code == AR_ABSENT) return "ARCHIVE_ABSENT";
  if (code == AR_BAD_MAGIC) return "ARCHIVE_BAD_MAGIC";
  if (code == AR_HEADER_OVERRUN) return "ARCHIVE_MEMBER_HEADER_OUT_OF_BOUNDS";
  if (code == AR_BAD_SIZE_FIELD) return "ARCHIVE_MEMBER_SIZE_FIELD_INVALID";
  if (code == AR_MEMBER_OVERRUN) return "ARCHIVE_MEMBER_PAYLOAD_OUT_OF_BOUNDS";
  if (code == AR_BAD_EXTENDED_NAME) return "ARCHIVE_EXTENDED_NAME_INVALID";
  if (code == AR_TOO_MANY_MEMBERS) return "ARCHIVE_TOO_MANY_MEMBERS";
  if (code == AR_EMPTY_MEMBER) return "ARCHIVE_MEMBER_PAYLOAD_EMPTY";
  return "ARCHIVE_UNKNOWN";
}

// The decoded member. It carries the DECODED identity and the payload. The
// RAW header representation is deliberately NOT carried, because two valid
// encodings of the same member must compare EQUAL.
class ArMember
{
  U8 *name;      // the decoded member name, NUL-terminated
  I64 namelen;   // the decoded name length
  I64 extended;  // 1 when the name used the "#1/N" extended form
  U8 *payload;   // the member payload
  I64 paylen;    // the member payload length
  I64 mtime;     // the archive bookkeeping metadata
};

// The decoded archive.
class ArArchive
{
  ArMember m[AR_MAX_MEMBERS];
  I64 count;
};

// The decimal field reader.
//
// The `ar` member header's numeric fields are RIGHT-ALIGNED and SPACE-PADDED,
// not zero-padded: the size field of a 556-byte member is "556       ".
//
// The field therefore contains a decimal run followed by spaces. A leading
// space is permitted, and the run may be empty only when the whole field is
// spaces (which is a malformed field for the fields this reader is used
// for).
//
// It returns -1 when the field is malformed.
static I64 ContractArField(U8 *buf, I64 size, I64 off, I64 width) {
  if (off < 0) return -1;
  if (size < off + width) return -1;
  // The leading spaces.
  I64 i = 0;
  while (i < width && buf[off + i] == 32) i = i + 1;
  // The decimal run.
  I64 v = 0;
  I64 digits = 0;
  while (i < width) {
    I64 c = buf[off + i];
    if (c < 48 || c > 57) break;
    v = v * 10 + (c - 48);
    digits = digits + 1;
    i = i + 1;
  }
  if (digits == 0) return -1;
  // The trailing spaces.
  while (i < width) {
    if (buf[off + i] != 32) return -1;
    i = i + 1;
  }
  return v;
}

// The size field reader. The size field is at offset 48 and is ten digits.
//
// The field is terminated by the two-byte ARFMAG sequence "`\n" (0x60 0x0A).
// The previous revision required a SPACE there, which is the GNU `ar`
// convention, and it therefore rejected every archive that the system
// `ar` produced.
static I64 ContractArSizeAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + AR_MEMBER_HDR_LEN) return -1;
  I64 v = ContractArField(buf, size, off + 48, 10);
  if (v < 0) return -1;
  // The size field is terminated by the ARFMAG sequence.
  if (buf[off + 58] != 96 || buf[off + 59] != 10) return -1;
  return v;
}

// The timestamp field reader. The timestamp field is at offset 16 and is
// twelve digits.
static I64 ContractArMtimeAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + AR_MEMBER_HDR_LEN) return -1;
  I64 v = ContractArField(buf, size, off + 16, 12);
  if (v < 0) return 0;
  return v;
}

// THE NAME EQUALITY.
//
// THE REPAIR: equality requires EQUAL DECODED NAME LENGTHS and EQUAL
// DECODED BYTES. The previous revision compared only the common prefix, so
// "source.o" compared EQUAL to "source".
static I64 ContractArNameEqual(U8 *a, I64 alen, U8 *b, I64 blen) {
  if (alen != blen) return 0;
  I64 i = 0;
  while (i < alen) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// The decoder.
//
// The archive is decoded into its DECODED member identities and payloads.
//
// The name field of a member header is sixteen bytes. It carries EITHER
//
//   * a short name, terminated by a slash and then padded with spaces, or
//   * the extended form "#1/N", where N is the length of the name that
//     FOLLOWS the header as the first N bytes of the member's data.
//
// The extended form is the "alternative encoding" that MUST remain
// semantically equivalent to the short form for the SAME decoded name.
static I64 ContractDecodeArchive(U8 *buf, I64 size, ArArchive *ar) {
  ar->count = 0;
  if (buf == NULL) return AR_ABSENT;
  if (size < AR_MAGIC_LEN) return AR_BAD_MAGIC;
  I64 k = 0;
  I64 same = 1;
  while (k < AR_MAGIC_LEN) {
    if (buf[k] != "!<arch>\n"[k]) { same = 0; break; }
    k = k + 1;
  }
  if (same == 0) return AR_BAD_MAGIC;

  I64 off = AR_MAGIC_LEN;
  while (off < size) {
    // The archive may end with an even number of padding bytes. A run of
    // fewer than AR_MEMBER_HDR_LEN bytes left is the padding.
    if (size - off < AR_MEMBER_HDR_LEN) {
      I64 p = off;
      I64 all_newline = 1;
      while (p < size) {
        if (buf[p] != 10) { all_newline = 0; break; }
        p = p + 1;
      }
      if (all_newline == 1) return AR_OK;
      return AR_HEADER_OVERRUN;
    }
    if (ar->count >= AR_MAX_MEMBERS) return AR_TOO_MANY_MEMBERS;

    I64 msize = ContractArSizeAt(buf, size, off);
    if (msize < 0) return AR_BAD_SIZE_FIELD;
    I64 mtime = ContractArMtimeAt(buf, size, off);

    // The payload follows the header.
    I64 payload_off = off + AR_MEMBER_HDR_LEN;
    if (msize > size - payload_off) return AR_MEMBER_OVERRUN;

    // The name field.
    I64 name_off = off;
    I64 namelen = 0;
    I64 extended = 0;
    U8 *name = MAlloc(msize + 1);

    // The extended form is signalled by "#1/".
    //
    // The extended name field is "#1/N" followed by spaces, where N is the
    // DECIMAL LENGTH of the name that follows the header as the first N
    // bytes of the member's data. The length is NOT a fixed-width field,
    // so it is read as a decimal run terminated by a space or by the end
    // of the name field.
    if (buf[name_off] == 35 && buf[name_off + 1] == 49 && buf[name_off + 2] == 47) {
      extended = 1;
      I64 extlen = 0;
      I64 e = name_off + 3;
      I64 edigits = 0;
      while (e < name_off + 16) {
        I64 c = buf[e];
        if (c < 48 || c > 57) break;
        extlen = extlen * 10 + (c - 48);
        edigits = edigits + 1;
        e = e + 1;
      }
      if (edigits == 0 || extlen <= 0 || extlen > msize) {
        return AR_BAD_EXTENDED_NAME;
      }
      // The extended name is the FIRST `extlen` bytes of the payload.
      if (extlen > msize) return AR_BAD_EXTENDED_NAME;
      MemCpy(name, buf + payload_off, extlen);
      // The extended name area is NUL-PADDED to an eight-byte boundary:
      // the name of a member named "good.o" is stored as "good.o" followed
      // by a NUL and then by further NUL padding, and the DECLARED length
      // covers the padding as well.
      //
      // The MEMBER IDENTITY is the name itself, WITHOUT the padding. The
      // padding is an artefact of the extended encoding and is not part of
      // the name, so it is trimmed here. Without the trim, the decoded
      // identity of "good.o" would be the twelve bytes "good.o\0\0\0\0\0\0",
      // and a requirement for the member "good.o" would NOT be satisfied.
      I64 real = extlen;
      while (real > 0 && name[real - 1] == 0) real = real - 1;
      if (real == 0) return AR_BAD_EXTENDED_NAME;
      namelen = real;
      // The payload is the remainder AFTER the extended name.
      ar->m[ar->count].payload = buf + payload_off + extlen;
      ar->m[ar->count].paylen = msize - extlen;
    } else {
      // The short form. The name is the field up to the terminating slash,
      // and it is space-padded.
      I64 n = 0;
      while (n < 16) {
        if (buf[name_off + n] == 47) break;
        if (buf[name_off + n] == 32) break;
        n = n + 1;
      }
      if (n > 0 && buf[name_off + n] == 47) {
        // The trailing slash terminates the name. The name is the bytes
        // BEFORE it.
        namelen = n;
        MemCpy(name, buf + name_off, namelen);
      } else if (n > 0 && buf[name_off + n] == 32) {
        // A space-padded name with no trailing slash.
        namelen = n;
        MemCpy(name, buf + name_off, namelen);
      } else {
        // A name that fills the whole field with no terminator.
        namelen = 16;
        MemCpy(name, buf + name_off, 16);
      }
      ar->m[ar->count].payload = buf + payload_off;
      ar->m[ar->count].paylen = msize;
    }
    name[namelen] = 0;
    ar->m[ar->count].name = name;
    ar->m[ar->count].namelen = namelen;
    ar->m[ar->count].extended = extended;
    ar->m[ar->count].mtime = mtime;
    ar->count = ar->count + 1;

    // The next member starts after the payload, rounded up to an even
    // offset.
    off = payload_off + msize;
    if (off % 2 != 0) off = off + 1;
  }
  return AR_OK;
}

// The member-set comparison.
//
// The comparison is over the DECODED MEMBER IDENTITIES and the PAYLOADS.
//
// It is used for TWO purposes:
//
//   * the EXPECTED member roster check (does the archive carry the members
//     the contract requires?), and
//   * the SEMANTIC EQUIVALENCE check (do the two sides carry the SAME
//     members with the SAME payloads?).
//
// The ARCHIVE BOOKKEEPING METADATA (the timestamps) is NOT part of the
// semantic identity, and the RAW HEADER REPRESENTATION is NOT part of it
// either. Two valid archive encodings of the same decoded member name and
// payload therefore compare EQUAL.
//
// The return value is 0 when the two member sets are semantically equal, and
// a reason code otherwise.
#define AREQ_OK                0
#define AREQ_COUNT_MISMATCH    1
#define AREQ_NAME_MISMATCH     2
#define AREQ_PAYLOAD_MISMATCH  3
#define AREQ_MISSING_MEMBER    4
#define AREQ_EMPTY_PAYLOAD     5

static U8 *ContractArEqReason(I64 code) {
  if (code == AREQ_OK) return "OK";
  if (code == AREQ_COUNT_MISMATCH) return "ARCHIVE_MEMBER_COUNT_MISMATCH";
  if (code == AREQ_NAME_MISMATCH) return "ARCHIVE_MEMBER_NAME_MISMATCH";
  if (code == AREQ_PAYLOAD_MISMATCH) return "ARCHIVE_MEMBER_PAYLOAD_MISMATCH";
  if (code == AREQ_MISSING_MEMBER) return "ARCHIVE_REQUIRED_MEMBER_MISSING";
  if (code == AREQ_EMPTY_PAYLOAD) return "ARCHIVE_MEMBER_PAYLOAD_EMPTY";
  return "ARCHIVE_UNKNOWN";
}

// The index of the member with the given decoded name, or -1.
static I64 ContractArFindMember(ArArchive *ar, U8 *name, I64 namelen) {
  I64 i = 0;
  while (i < ar->count) {
    if (ContractArNameEqual(ar->m[i].name, ar->m[i].namelen, name, namelen) == 1) {
      return i;
    }
    i = i + 1;
  }
  return -1;
}

// The REQUIRED MEMBER check. The archive MUST carry a member with the given
// decoded name, and that member's payload MUST be non-empty.
//
// A member with an EMPTY payload is a member that carries no content, and
// it does not satisfy a requirement for a real member.
static I64 ContractArRequireMember(ArArchive *ar, U8 *name, I64 namelen) {
  I64 idx = ContractArFindMember(ar, name, namelen);
  if (idx < 0) return AREQ_MISSING_MEMBER;
  if (ar->m[idx].paylen <= 0) return AREQ_EMPTY_PAYLOAD;
  return AREQ_OK;
}

// The SEMANTIC EQUIVALENCE check.
//
// The two archives MUST carry the same number of members, and each member of
// the first MUST have a counterpart in the second with the SAME decoded name
// and the SAME payload bytes.
//
// The member ORDER is NOT part of the semantic identity: an archive that
// lists the same members in a different order carries the same members.
static I64 ContractArEquivalent(ArArchive *a, ArArchive *b) {
  if (a->count != b->count) return AREQ_COUNT_MISMATCH;
  I64 i = 0;
  while (i < a->count) {
    I64 idx = ContractArFindMember(b, a->m[i].name, a->m[i].namelen);
    if (idx < 0) return AREQ_NAME_MISMATCH;
    if (b->m[idx].paylen != a->m[i].paylen) return AREQ_PAYLOAD_MISMATCH;
    if (a->m[i].paylen > 0) {
      I64 k = 0;
      I64 same = 1;
      while (k < a->m[i].paylen) {
        if (a->m[i].payload[k] != b->m[idx].payload[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 0) return AREQ_PAYLOAD_MISMATCH;
    }
    i = i + 1;
  }
  return AREQ_OK;
}

// The bytes-equal helper.
static I64 ContractBytesEqual(U8 *a, I64 alen, U8 *b, I64 blen) {
  if (alen != blen) return 0;
  I64 i = 0;
  while (i < alen) {
    if (a[i] != b[i]) return 0;
    i = i + 1;
  }
  return 1;
}

// ---------------------------------------------------------------------------
// THE CONTRACT SELF-TEST.
//
// It exercises the properties that the reviewer challenged:
//
//   * the exit-status ENCODER and DECODER ROUND TRIP for
//     0, 1, 9, 10, 12, 42, 127, 255;
//   * the exit-status DECODER REJECTS a negative value, a value above 255,
//     an integer overflow, trailing text, additional lines and a missing
//     record;
//   * the archive member NAME EQUALITY REJECTS a prefix name and ACCEPTS a
//     different raw encoding of the same decoded name.
// ---------------------------------------------------------------------------
static I64 ContractSelfCheck() {
  I64 failures = 0;
  I64 checks = 0;

  // --- The exit-status round trip. ---------------------------------------
  I64 values[8];
  values[0] = 0;
  values[1] = 1;
  values[2] = 9;
  values[3] = 10;
  values[4] = 12;
  values[5] = 42;
  values[6] = 127;
  values[7] = 255;
  I64 v = 0;
  while (v < 8) {
    I64 value = values[v];
    U8 *text = MAlloc(16);
    I64 len = 0;
    I64 code = EXIT_OK;
    I64 enc_ok = ContractWriteExitStatus(value, text, 15, &len, &code);
    // The decoder is exercised on the encoded bytes WITH a trailing newline,
    // because that is the form the harness writes.
    U8 *record = MAlloc(len + 2);
    MemCpy(record, text, len);
    record[len] = 10;
    I64 back = 0;
    I64 dcode = EXIT_OK;
    I64 dec_ok = ContractReadExitStatus(record, len + 1, &back, &dcode);
    checks = checks + 1;
    if (enc_ok == 0 || dec_ok == 0 || back != value) {
      "CONTRACT_SELFTEST\tEXIT_ROUNDTRIP_%lld\tFAIL\tvalue=%lld back=%lld\n",
        value, value, back;
      failures = failures + 1;
    }
    Free(text);
    Free(record);
    v = v + 1;
  }

  // --- The exit-status rejections. ---------------------------------------
  // A negative value.
  U8 *out = MAlloc(16);
  I64 olen = 0;
  I64 ocode = EXIT_OK;
  checks = checks + 1;
  if (ContractWriteExitStatus(-1, out, 15, &olen, &ocode) != 0 ||
      ocode != EXIT_NEGATIVE) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_NEGATIVE\tFAIL\n";
    failures = failures + 1;
  }
  // A value above 255.
  checks = checks + 1;
  if (ContractWriteExitStatus(256, out, 15, &olen, &ocode) != 0 ||
      ocode != EXIT_RANGE) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_RANGE\tFAIL\n";
    failures = failures + 1;
  }
  // An integer overflow.
  I64 ov = 0;
  I64 ocode2 = EXIT_OK;
  checks = checks + 1;
  if (ContractReadExitStatus("99999999999999999999", 20, &ov, &ocode2) != 0 ||
      ocode2 != EXIT_OVERFLOW) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_OVERFLOW\tFAIL\n";
    failures = failures + 1;
  }
  // Trailing text.
  checks = checks + 1;
  if (ContractReadExitStatus("0 trailing garbage", 16, &ov, &ocode2) != 0 ||
      ocode2 != EXIT_TRAILING_TEXT) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_TRAILING_TEXT\tFAIL\n";
    failures = failures + 1;
  }
  // Additional lines.
  checks = checks + 1;
  if (ContractReadExitStatus("0\n1\n", 4, &ov, &ocode2) != 0 ||
      ocode2 != EXIT_TRAILING_BYTES) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_ADDITIONAL_LINES\tFAIL\n";
    failures = failures + 1;
  }
  // A missing record.
  checks = checks + 1;
  if (ContractReadExitStatus(NULL, 0, &ov, &ocode2) != 0 ||
      ocode2 != EXIT_MISSING) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_MISSING\tFAIL\n";
    failures = failures + 1;
  }
  // An empty record.
  checks = checks + 1;
  if (ContractReadExitStatus("", 0, &ov, &ocode2) != 0 ||
      ocode2 != EXIT_EMPTY) {
    "CONTRACT_SELFTEST\tEXIT_REJECT_EMPTY\tFAIL\n";
    failures = failures + 1;
  }
  Free(out);

  // --- The archive member name equality. ---------------------------------
  // "source.o" and "source" are DIFFERENT decoded identities.
  checks = checks + 1;
  if (ContractArNameEqual("source.o", 8, "source", 6) == 1) {
    "CONTRACT_SELFTEST\tAR_NAME_PREFIX_REJECT\tFAIL\n";
    failures = failures + 1;
  }
  // Identical decoded names are equal.
  checks = checks + 1;
  if (ContractArNameEqual("source.o", 8, "source.o", 8) != 1) {
    "CONTRACT_SELFTEST\tAR_NAME_EQUAL\tFAIL\n";
    failures = failures + 1;
  }
  // Different names of the SAME length are not equal.
  checks = checks + 1;
  if (ContractArNameEqual("source.o", 8, "source.p", 8) == 1) {
    "CONTRACT_SELFTEST\tAR_NAME_DIFFERENT\tFAIL\n";
    failures = failures + 1;
  }

  // --- The ALTERNATE ARCHIVE ENCODING. -----------------------------------
  //
  // Two VALID encodings of the SAME decoded member name and the SAME
  // payload MUST compare EQUAL. The archive's name field is sixteen
  // bytes, and a short name may be written EITHER as the name followed by
  // a terminating slash, or as the space-padded name with no terminator.
  // Both are valid encodings of the same decoded identity.
  //
  // The control is a POSITIVE control: it asserts that the two encodings
  // are ACCEPTED as equivalent. Without it, a decoder that rejected every
  // short name would pass the negative controls above.
  {
    I64 member_len = 4;
    I64 hdr = AR_MEMBER_HDR_LEN;
    I64 total = AR_MAGIC_LEN + hdr + member_len;
    if (total % 2 != 0) total = total + 1;
    U8 *enc_a = MAlloc(total + 1);
    U8 *enc_b = MAlloc(total + 1);
    I64 k = 0;
    while (k < AR_MAGIC_LEN) {
      enc_a[k] = "!<arch>\n"[k];
      enc_b[k] = "!<arch>\n"[k];
      k = k + 1;
    }
    // The NAME field of the member header, in the two encodings.
    //
    //   encoding A   "source.o/" followed by spaces
    //   encoding B   "source.o" followed by spaces
    //
    // The remaining header fields are the SAME in both encodings, so the
    // two archives differ ONLY in the raw representation of the name.
    I64 n = 0;
    while (n < 8) {
      enc_a[AR_MAGIC_LEN + n] = "source.o"[n];
      enc_b[AR_MAGIC_LEN + n] = "source.o"[n];
      n = n + 1;
    }
    enc_a[AR_MAGIC_LEN + 8] = 47;
    enc_b[AR_MAGIC_LEN + 8] = 32;
    I64 f = 9;
    while (f < 16) {
      enc_a[AR_MAGIC_LEN + f] = 32;
      enc_b[AR_MAGIC_LEN + f] = 32;
      f = f + 1;
    }
    // The MTIME, UID, GID, MODE and SIZE fields. The size is "4" followed
    // by spaces, and the member's terminator is the two-byte magic.
    I64 base = AR_MAGIC_LEN + 16;
    I64 g = 0;
    while (g < 12) { enc_a[base + g] = 32; enc_b[base + g] = 32; g = g + 1; }
    g = 0;
    while (g < 6)  { enc_a[base + 12 + g] = 32; enc_b[base + 12 + g] = 32; g = g + 1; }
    g = 0;
    while (g < 6)  { enc_a[base + 18 + g] = 32; enc_b[base + 18 + g] = 32; g = g + 1; }
    g = 0;
    while (g < 8)  { enc_a[base + 24 + g] = 32; enc_b[base + 24 + g] = 32; g = g + 1; }
    enc_a[base + 32] = 52; enc_b[base + 32] = 52;
    g = 33;
    while (g < 42) { enc_a[base + g] = 32; enc_b[base + g] = 32; g = g + 1; }
    enc_a[base + 42] = 96; enc_b[base + 42] = 96;
    enc_a[base + 43] = 10; enc_b[base + 43] = 10;
    // The payload.
    I64 poff = AR_MAGIC_LEN + hdr;
    enc_a[poff] = 65; enc_b[poff] = 65;
    enc_a[poff + 1] = 66; enc_b[poff + 1] = 66;
    enc_a[poff + 2] = 67; enc_b[poff + 2] = 67;
    enc_a[poff + 3] = 68; enc_b[poff + 3] = 68;
    enc_a[total] = 0;
    enc_b[total] = 0;

    ArArchive ar_a;
    ArArchive ar_b;
    I64 da = ContractDecodeArchive(enc_a, poff + member_len, &ar_a);
    I64 db = ContractDecodeArchive(enc_b, poff + member_len, &ar_b);
    checks = checks + 1;
    if (da != AR_OK || db != AR_OK) {
      "CONTRACT_SELFTEST\tAR_ALTERNATE_ENCODING_DECODE\tFAIL\n";
      failures = failures + 1;
    } else {
      // The two decoded identities must be EQUAL.
      checks = checks + 1;
      if (ContractArEquivalent(&ar_a, &ar_b) != AREQ_OK) {
        "CONTRACT_SELFTEST\tAR_ALTERNATE_ENCODING_EQUAL\tFAIL\n";
        failures = failures + 1;
      }
    }
    Free(enc_a);
    Free(enc_b);
  }

  "CONTRACT_SELFTEST_CHECKS\t%lld\n", checks;
  "CONTRACT_SELFTEST_FAILURES\t%lld\n", failures;
  return failures;
}
