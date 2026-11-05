// tools/quality/wp001-driver-takeover01-red.HC
//
// ACT-POLYC-SELFHOST-WP001-DRIVER-TAKEOVER01.
//
// THE PRINCIPAL RED DETECTOR.
//
// WHAT IT DETECTS: whether the PRODUCTION compiler's route-selection
// object CONSUMES the compiled PolyC driver's whole-argv action.
//
// WHY THIS IS THE RIGHT SEAM: a SYMBOL DEFINITION IS NOT CONSUMPTION.
// The PolyC driver subject exports WpDriverSelectedAction, but the
// production compiler may still never CALL it. In that state the
// PolyC action is DECORATIVE, the C route-selection branches in
// main() remain the real authority, and the takeover is a claim rather
// than a fact.
//
// The detector reads the REAL Mach-O object of the production route
// selection, parses its symbol table, and reports which driver
// accessors the object IMPORTS (an undefined reference) and which it
// DEFINES (a local copy, which would be a duplicated action source).
//
// The detector NEVER reads a verdict string. It reads the artifact.
//
// It is a COMPILED POLYC program: it is built by the real production
// compiler and executed against the real production object.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.
//
// USAGE:
//   wp001-driver-takeover01-red <production-route-object> [accessor...]
//
// With no accessor arguments it reports the FULL import/define table
// for the driver accessors. With accessor arguments it reports, for
// each, whether the object IMPORTS it (consumed), DEFINES it
// (duplicated action source) or does neither (not consumed).
//
// EXIT STATUS:
//   0  the route object consumed the requested accessors
//   1  the route object did NOT consume a requested accessor
//   2  usage or read error

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The Mach-O 64-bit magic, read little-endian.
#define MACHO64_MAGIC 0xFEEDFACF
// The Mach-O 32-bit magic.
#define MACHO32_MAGIC 0xFEEDFACE
// The ELF 64-bit magic. The ELF magic is byte-order invariant, so the
// same little-endian reader recognises it unchanged.
#define ELF64_MAGIC   0x7F454C46

// The maximum number of symbols the reader will consider.
#define MAXSYM 65536

// The maximum symbol-name length.
#define MAXNAME 256

// The symbol table records that the reader keeps.
//
//   name      the symbol's name, NUL-terminated
//   n_type    the Mach-O n_type byte
//   n_sect    the Mach-O n_sect byte
//   desc      the Mach-O n_desc field
//   value     the Mach-O n_value field
//
static U8  SYMNAME[MAXSYM][MAXNAME];
static U8  SYMTYPE[MAXSYM];
static U8  SYMSECT[MAXSYM];
static U64 SYMVALUE[MAXSYM];
static U32 SYMDESC[MAXSYM];
static I64 SYMCOUNT;

// The reader's failure reason, or 0 when the read succeeded.
static I64 READERR;

// The little-endian 16-bit value at a byte offset, or -1 when the file
// is too short.
static I64 HalfAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + 2) return -1;
  I64 v = buf[off] | (buf[off + 1] << 8);
  return v;
}

// The little-endian 32-bit value at a byte offset, or -1 when the file
// is too short.
static I64 WordAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + 4) return -1;
  I64 v = buf[off] | (buf[off + 1] << 8) | (buf[off + 2] << 16)
        | (buf[off + 3] << 24);
  return v;
}

// The little-endian 64-bit value at a byte offset, or -1 when the file
// is too short.
static I64 QwordAt(U8 *buf, I64 size, I64 off) {
  if (off < 0) return -1;
  if (size < off + 8) return -1;
  I64 v = 0;
  I64 i = 0;
  while (i < 8) {
    v = v | (buf[off + i] << (8 * i));
    i = i + 1;
  }
  return v;
}


// Does the symbol at index `s` carry the name `name`?
//
// The Mach-O symbol names carry a leading underscore. The comparison
// is made against the name WITH the underscore, and also against the
// name WITHOUT it, so the same detector serves Mach-O and ELF.
static I64 SymIs(I64 s, U8 *name) {
  U8 *n = SYMNAME[s];
  I64 i = 0;
  while (name[i] != 0 && n[i] != 0) {
    if (name[i] != n[i]) return 0;
    i = i + 1;
  }
  if (name[i] != 0) return 0;
  if (n[i] != 0) return 0;
  return 1;
}

// Record one symbol. Returns 0 when the symbol table is full.
static U0 AddSym(U8 *name, I64 n_type, I64 n_sect, I64 desc, I64 value) {
  if (SYMCOUNT >= MAXSYM) return;
  I64 i = 0;
  while (i < MAXNAME - 1 && name[i] != 0) {
    SYMNAME[SYMCOUNT][i] = name[i];
    i = i + 1;
  }
  SYMNAME[SYMCOUNT][i] = 0;
  SYMTYPE[SYMCOUNT] = n_type;
  SYMSECT[SYMCOUNT] = n_sect;
  SYMDESC[SYMCOUNT] = desc;
  SYMVALUE[SYMCOUNT] = value;
  SYMCOUNT++;
}

// The Mach-O SYMBOL TABLE command.
#define LC_SYMTAB 0x2

// Parse a Mach-O 64-bit object.
static U0 ParseMacho64(U8 *buf, I64 size) {
  I64 ncmds = WordAt(buf, size, 16);
  if (ncmds < 0) { READERR = 1; return; }
  I64 off = 32;
  I64 i = 0;
  while (i < ncmds) {
    I64 cmd = WordAt(buf, size, off);
    if (cmd < 0) { READERR = 1; return; }
    I64 cmdsize = WordAt(buf, size, off + 4);
    if (cmdsize < 0) { READERR = 1; return; }
    if (cmd == LC_SYMTAB) {
      I64 symoff = WordAt(buf, size, off + 8);
      I64 nsyms = WordAt(buf, size, off + 12);
      I64 stroff = WordAt(buf, size, off + 16);
      I64 strsize = WordAt(buf, size, off + 20);
      if (symoff < 0 || nsyms < 0 || stroff < 0) { READERR = 1; return; }
      I64 s = 0;
      while (s < nsyms) {
        I64 so = symoff + s * 16;
        I64 n_strx = WordAt(buf, size, so);
        I64 n_type = buf[so + 4];
        I64 n_sect = buf[so + 5];
        I64 n_desc = HalfAt(buf, size, so + 6);
        I64 n_value = QwordAt(buf, size, so + 8);
        if (n_strx < 0 || n_strx >= strsize) { READERR = 1; return; }
        AddSym(buf + stroff + n_strx, n_type, n_sect, n_desc, n_value);
        s = s + 1;
      }
      return;
    }
    off = off + cmdsize;
  }
  READERR = 2;
}

// Parse an ELF 64-bit object.
//
// The ELF symbol table is located through the section headers, which
// is more work than the Mach-O path needs, and the ACT's production
// target is Mach-O. The ELF path therefore reports the read error
// rather than silently reporting "not consumed" on a foreign format.
static U0 ParseElf64(U8 *buf, I64 size) {
  READERR = 3;
}

// The classification of one accessor against the loaded symbol table.
//
//   2  the object IMPORTS it: an undefined reference. This is the
//      CONSUMPTION.
//   1  the object DEFINES it: a local copy. This is a DUPLICATED
//      ACTION SOURCE.
//   0  the object does neither: NOT CONSUMED.
//
static I64 Classify(U8 *name) {
  I64 i = 0;
  while (i < SYMCOUNT) {
    if (SymIs(i, name) == 1) {
      // N_EXT is 0x01 and N_TYPE is 0x0e in the Mach-O n_type byte.
      // An UNDEFINED symbol has N_TYPE == N_UNDF (0x0) and N_EXT set.
      // A DEFINED external symbol has N_TYPE == N_SECT (0xe) or
      // N_ABS (0x2), and N_EXT set.
      I64 t = SYMTYPE[i];
      if ((t & 0x0e) == 0 && (t & 0x01) == 0x01) return 2;
      if ((t & 0x01) == 0x01) return 1;
    }
    i = i + 1;
  }
  return 0;
}

// The classification of one accessor, taking the leading-underscore
// spelling into account.
//
// The C identifier for a driver accessor has no underscore; the Mach-O
// symbol does. The detector therefore checks both spellings.
static I64 ClassifyEither(U8 *name) {
  I64 r = Classify(name);
  if (r != 0) return r;
  // Build the underscored spelling and classify that.
  static U8 underscored[MAXNAME];
  I64 i = 0;
  underscored[0] = 95;   // '_'
  i = 1;
  while (name[i - 1] != 0 && i < MAXNAME - 1) {
    underscored[i] = name[i - 1];
    i = i + 1;
  }
  underscored[i] = 0;
  return Classify(underscored);
}

// Does the symbol name carry the driver prefix "WpDriver"?
static I64 IsDriverName(U8 *n) {
  I64 j = 0;
  while (n[j] != 0) {
    if (n[j] == 87 && n[j + 1] == 112 && n[j + 2] == 68 && n[j + 3] == 114) {
      return 1;
    }
    j = j + 1;
  }
  return 0;
}

// The classification of a symbol by its Mach-O type byte.
static I64 KindOf(I64 t) {
  if ((t & 0x0e) == 0 && (t & 0x01) == 0x01) return 2;
  if ((t & 0x01) == 0x01) return 1;
  return 0;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 2) {
    "REASON_DETAIL=usage: <production-route-object> [accessor...]\n";
    return 2;
  }

  I64 size = 0;
  U8 *buf = FileRead(argv[1], &size);
  if (buf == NULL) {
    "REASON_DETAIL=cannot read the production route object\n";
    return 2;
  }
  if (size < 16) {
    "REASON_DETAIL=the production route object is too short to be an object file\n";
    return 2;
  }

  I64 magic = WordAt(buf, size, 0);
  if (magic == MACHO64_MAGIC) {
    ParseMacho64(buf, size);
  } else if (magic == MACHO32_MAGIC) {
    "REASON_DETAIL=the production route object is 32-bit Mach-O, which this detector does not parse\n";
    return 2;
  } else if (magic == ELF64_MAGIC) {
    ParseElf64(buf, size);
  } else {
    "REASON_DETAIL=the production route object has an unrecognised magic\n";
    return 2;
  }

  if (READERR != 0) {
    "REASON_DETAIL=cannot read the symbol table of the production route object\n";
    return 2;
  }

  "SYMBOL_COUNT=%d\n", SYMCOUNT;

  // With no accessor arguments, report the WHOLE table's driver
  // accessors. This is the ENTRY census.
  if (argc == 2) {
    I64 i = 0;
    while (i < SYMCOUNT) {
      U8 *n = SYMNAME[i];
      if (IsDriverName(n) == 1) {
        "DRIVER_SYMBOL kind=%d name=%s\n", KindOf(SYMTYPE[i]), n;
      }
      i = i + 1;
    }
    return 0;
  }

  // With accessor arguments, classify each one.
  I64 a = 2;
  I64 missing = 0;
  while (a < argc) {
    I64 c = ClassifyEither(argv[a]);
    if (c == 2) "ACCESSOR name=%s classification=IMPORTED\n", argv[a];
    if (c == 1) "ACCESSOR name=%s classification=DEFINED_DUPLICATE_SOURCE\n", argv[a];
    if (c == 0) {
      "ACCESSOR name=%s classification=NOT_CONSUMED\n", argv[a];
      missing++;
    }
    a = a + 1;
  }
  if (missing > 0) {
    "WP001_DRIVER_TAKEOVER_RED=FIRED\n";
    return 1;
  }
  "WP001_DRIVER_TAKEOVER_RED=NOT_FIRED\n";
  return 0;
}
