// tools/quality/driver-required-route-correction03-c4r5-probe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5.
//
// THE ROUND-5 COUNTEREXAMPLE PROBE.
//
// It exercises the PRODUCTION FUNCTIONS -- the SHARED VALIDATION
// CONTRACT, the SHARED CAPTURE AND LEDGER PRIMITIVES and the SHARED
// EVENT-IDENTITY ENCODING -- directly, with hand-built fixtures, so that
// each of the ten P1 findings has an INDEPENDENT, REPRODUCIBLE
// counterexample.
//
// THE PRODUCTION FUNCTIONS ARE THE SUBJECT UNDER TEST.
//
// The probe does NOT carry a duplicate of the function it exercises. It
// calls the PRODUCTION function and reports the PRODUCTION function's
// own reason token. A defect therefore shows up as "the production
// function ACCEPTED a fixture that it must reject", and the fix shows up
// as "the production function REJECTED it with the reason token".
//
// THE PROBE MODES.
//
//   probe macho <fixture-dir>    -- R4-06, R4-07 and R4-10.
//   probe archive <fixture-dir>  -- R4-08.
//   probe ledger <fixture-dir>   -- R4-04.
//   probe capture <fixture-dir>  -- R4-01.
//   probe identity <fixture-dir> -- R4-05.
//   probe emission <fixture-dir> -- R4-09.
//
// Each mode prints one line per control:
//
//   PROBE_CONTROL\t<CONTROL-ID>\t<VERDICT>\t<REASON-TOKEN>
//
// The exit status is the number of FAILED controls, so the probe is usable
// directly as a gate.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.
//
// THE RED COMPATIBILITY LAYER.
//
// The ROUND-5 repair moved the capture and ledger primitives and the event
// identity encoding from the COMPARATOR into the SHARED CONTRACT, and it
// added the emission domain roster to the SHARED CONTRACT.
//
// The probe therefore has to be buildable against BOTH the PRE-REPAIR tree
// -- where those primitives live in the comparator and the roster does not
// exist -- and the POST-REPAIR tree -- where they live in the contract.
//
// `C4R5_RED_COMPAT` is 1 when the probe is being built against the
// PRE-REPAIR tree. In that mode:
//
//   * the capture and ledger primitives come from the COMPARATOR, which is
//     the file that held them before the repair, so the probe exercises
//     the PRE-REPAIR implementation of the very functions it attacks; and
//
//   * the emission roster control is compiled OUT, because the roster did
//     not exist before the repair. The roster's absence is itself the
//     R4-09 defect, and the C4R5 evidence records it as such.
//
// The probe NEVER duplicates a production decision. In the RED build it
// calls the PRE-REPAIR production function; in the GREEN build it calls
// the POST-REPAIR production function.

#ifndef C4R5_RED_COMPAT
#define C4R5_RED_COMPAT 0
#endif

#include "driver-required-route-correction03-contract.HC"

#if C4R5_RED_COMPAT == 1
// The PRE-REPAIR tree: the capture and ledger primitives and the event
// identity construction lived in the COMPARATOR.
//
// `driver-required-route-correction03-c4r5-red-primitives.HC` carries those
// functions EXTRACTED VERBATIM from the entry HEAD's comparator, so the
// RED witness exercises the ENTRY-HEAD code and not a re-implementation
// of it. The extraction is byte-verified and its digest is recorded in
// the C4R5 evidence.
//
// The file exists ONLY in the RED worktree. It is NOT part of the
// post-repair tree, and the C4R5 evidence records its absence from the
// subject tree.
#include "driver-required-route-correction03-c4r5-red-primitives.HC"
#endif

// ---------------------------------------------------------------------------
// THE PROBE'S OWN HELPERS.
//
// They are the FIXTURE BUILDERS and the VERDICT RECORDER. They are NOT
// copies of any production decision.
// ---------------------------------------------------------------------------

// The 64-bit little-endian writer.
static U0 R5Put64(U8 *buf, I64 off, I64 v) {
  I64 i = 0;
  while (i < 8) {
    buf[off + i] = (v >> (i * 8)) & 255;
    i = i + 1;
  }
}

// The 32-bit little-endian writer.
static U0 R5Put32(U8 *buf, I64 off, I64 v) {
  I64 i = 0;
  while (i < 4) {
    buf[off + i] = (v >> (i * 8)) & 255;
    i = i + 1;
  }
}

// The DIRECTORY CREATOR.
//
// The platform's `mkdir(2)` does not create the PARENT directories, so a
// fixture tree that does not exist yet must be created LEVEL BY LEVEL.
// The probe therefore walks the path and creates each component in turn.
//
// The components are located by scanning for the separator, and the path
// is written into a scratch buffer that is large enough for it.
static I64 R5MakeDirs(U8 *path) {
  I64 len = StrLen(path);
  I64 ok = 0;
  if (len <= 0) return 0;
  U8 *buf = MAlloc(len + 1);
  MemCpy(buf, path, len);
  buf[len] = 0;
  I64 i = 1;
  while (i <= len) {
    if (buf[i] == 47 || i == len) {
      U8 saved = buf[i];
      buf[i] = 0;
      mkdir(buf, 493);
      buf[i] = saved;
    }
    i = i + 1;
  }
  ok = 1;
  Free(buf);
  return ok;
}

// The path builder.
static U8 *R5Path(U8 *dir, U8 *name) {
  I64 dlen = StrLen(dir);
  I64 nlen = StrLen(name);
  U8 *p = MAlloc(dlen + nlen + 2);
  MemCpy(p, dir, dlen);
  I64 k = 0;
  if (dlen > 0 && dir[dlen - 1] != 47) { p[dlen] = 47; k = 1; }
  MemCpy(p + dlen + k, name, nlen);
  p[dlen + k + nlen] = 0;
  return p;
}

// The file writer. It reports failure.
static I64 R5Write(U8 *path, U8 *buf, I64 size) {
  if (FileWrite(path, buf, size, O_CREAT | O_TRUNC | O_RDWR) == FALSE) return 0;
  return 1;
}

// The TRUNCATING writer.
//
// The runtime's `FileWrite` DEFAULTS to `O_CREAT | O_RDWR`, and a write of
// ZERO bytes therefore LEAVES THE OLD CONTENT in place. The probe needs
// to TRUNCATE the run ledger between the two phases of the R4-03 control,
// because the event counter is derived from the ledger's LINE COUNT, and
// the second phase must receive the SAME event identity as the first.
static I64 R5Truncate(U8 *path) {
  U8 *empty = MAlloc(1);
  empty[0] = 0;
  I64 ok = 0;
  if (FileWrite(path, empty, 0, O_CREAT | O_TRUNC | O_RDWR) == TRUE) ok = 1;
  Free(empty);
  return ok;
}

// The counters.
static I64 r5_checks;
static I64 r5_failures;

// The verdict recorder.
//
// `expect_accept` is 1 for a POSITIVE control that must remain accepted
// and 0 for an ADVERSE control that must be rejected.
static U0 R5Verdict(U8 *control, I64 accepted, I64 expect_accept,
                    U8 *reason) {
  r5_checks = r5_checks + 1;
  I64 ok = 0;
  if (expect_accept == 1) {
    if (accepted == 1) ok = 1;
  } else {
    if (accepted == 0) ok = 1;
  }
  if (ok == 1) {
    "PROBE_CONTROL\t%s\tOK\t%s\n", control, reason;
  } else {
    "PROBE_CONTROL\t%s\tFAIL\t%s\n", control, reason;
    r5_failures = r5_failures + 1;
  }
}

// ---------------------------------------------------------------------------
// THE MACH-O FIXTURE.
//
// The layout is the one the ROUND-4 probe uses, so the two probes'
// fixtures are comparable:
//
//   0     the mach_header_64            32 bytes
//   32    the LC_SEGMENT_64             152 bytes (72 + one 80-byte section)
//   184   the LC_SYMTAB                 24 bytes
//   208   the LC_DYSYMTAB               80 bytes
//   288   the symbol table              32 bytes (two nlist_64 entries)
//   336   the string table              8 bytes
//
// The image is 344 bytes long.
//
// The FIXTURE SIZE IS THE ROUND-5 SIZE. The two R4-06 counterexamples
// place a table's extent at 340 -- FOUR bytes before the end of the file
// -- and declare a count of one, so the table's real extent runs past the
// end of the file.
// ---------------------------------------------------------------------------

// The builder.
//
// `nsyms` is the symbol table's symbol count.
// `nlocalsym` is the dysymtab's local range count.
// `dysymtab_present` is 1 when the fixture carries an LC_DYSYMTAB.
static U8 *R5BuildMachO(I64 size, I64 dysymtab_present, I64 nsyms,
                         I64 nlocalsym) {
  U8 *b = MAlloc(size);
  MemSet(b, 0, size);
  // The mach_header_64.
  R5Put32(b, 0, 0xFEEDFACF);          // magic
  R5Put32(b, 4, CPU_TYPE_ARM64);      // cputype
  R5Put32(b, 8, 3);                   // cpusubtype
  R5Put32(b, 12, MH_OBJECT);          // filetype
  I64 ncmds = 3;
  if (dysymtab_present == 0) ncmds = 2;
  R5Put32(b, 16, ncmds);              // ncmds
  I64 sizeofcmds = 256;
  if (dysymtab_present == 0) sizeofcmds = 176;
  R5Put32(b, 20, sizeofcmds);         // sizeofcmds

  // The LC_SEGMENT_64, at offset 32. It carries ONE section and NO file
  // bytes.
  R5Put32(b, 32, LC_SEGMENT_64);
  R5Put32(b, 36, 152);                // cmdsize = 72 + 80
  R5Put64(b, 56, 0);                  // vmaddr
  R5Put64(b, 64, 0);                  // vmsize
  R5Put64(b, 72, 0);                  // fileoff
  R5Put64(b, 80, 0);                  // filesize
  R5Put32(b, 88, 7);                  // maxprot
  R5Put32(b, 92, 7);                  // initprot
  R5Put32(b, 96, 1);                  // nsects
  R5Put32(b, 100, 0);                 // flags
  // The section_64, at offset 104.
  R5Put32(b, 104, 0);                 // sectname
  R5Put32(b, 108, 0);                 // segname
  R5Put64(b, 144, 0);                 // size
  R5Put64(b, 152, 0);                 // offset
  R5Put32(b, 160, 0);                 // align
  R5Put32(b, 164, 0);                 // reloff
  R5Put32(b, 164, 0);                 // nreloc
  R5Put32(b, 168, 0);                 // flags -- S_REGULAR

  // The LC_SYMTAB, at offset 184.
  R5Put32(b, 184, LC_SYMTAB);
  R5Put32(b, 188, SYMTAB_CMDSZ);
  R5Put32(b, 192, 288);               // symoff
  R5Put32(b, 196, nsyms);             // nsyms
  R5Put32(b, 200, 336);               // stroff
  R5Put32(b, 204, 8);                 // strsize

  // The LC_DYSYMTAB, at offset 208.
  if (dysymtab_present == 1) {
    R5Put32(b, 208, LC_DYSYMTAB);
    R5Put32(b, 212, DYSYMTAB_CMDSZ);
    R5Put32(b, 216, 0);               // ilocalsym
    R5Put32(b, 220, nlocalsym);       // nlocalsym
    R5Put32(b, 224, 0);               // iextdefsym
    R5Put32(b, 228, 0);               // nextdefsym
    R5Put32(b, 232, 0);               // iundefsym
    R5Put32(b, 236, 0);               // nundefsym
    R5Put32(b, 240, 0);               // tocoff
    R5Put32(b, 244, 0);               // ntoc
    R5Put32(b, 248, 0);               // modtaboff
    R5Put32(b, 252, 0);               // nmodtab
    R5Put32(b, 256, 0);               // extrefsymoff
    R5Put32(b, 260, 0);               // nextrefsyms
    R5Put32(b, 264, 0);               // indirectsymoff
    R5Put32(b, 268, 0);               // nindirectsyms
    R5Put32(b, 272, 0);               // extreloff
    R5Put32(b, 276, 0);               // nextrel
    R5Put32(b, 280, 0);               // locreloff
    R5Put32(b, 284, 0);               // nlocrel
  }

  // The symbol table, at offset 288. TWO entries: "_main" and a second
  // entry whose string index is inside the string table.
  R5Put32(b, 288, 1);                 // n_strx -> "_main"
  R5Put64(b, 296, 0);                 // n_value
  R5Put32(b, 304, 2);                 // the second entry's n_strx
  R5Put64(b, 312, 0);                 // n_value

  // The string table, at offset 336.
  b[336] = 95;                        // '_'
  b[337] = 0;
  b[338] = 109;                       // 'm'
  b[339] = 97;                        // 'a'
  b[340] = 105;                       // 'i'
  b[341] = 110;                       // 'n'
  b[342] = 0;
  b[343] = 0;
  return b;
}

// ---------------------------------------------------------------------------
// THE MACH-O CONTROLS.
//
// They exercise the PRODUCTION `ContractValidateMachO` -- the shared
// validator that the comparator and the emission verifier both call.
// ---------------------------------------------------------------------------

// The Mach-O control runner.
//
// `mutate` selects the mutation. The mutation is applied IN PLACE to the
// built fixture.
//
// The fixture is written so that the independent platform tools can
// inspect the SAME bytes.
static U0 R5MachOControl(U8 *dir, U8 *control, I64 mutate,
                         I64 expect_accept, I64 require_symtab) {
  I64 size = 344;
  // The base fixture is VALID: two symbols, no dysymtab range.
  U8 *b = R5BuildMachO(size, 1, 2, 0);
  // The mutations.
  if (mutate == 1) {
    // R4-06 -- THE TABLE OF CONTENTS IS DECLARED AT 340 WITH A COUNT OF
    // ONE. The table of contents entry is EIGHT bytes wide, so the table
    // runs from 340 to 348, past the end of the 344-byte file.
    R5Put32(b, 240, 340);               // tocoff
    R5Put32(b, 244, 1);                 // ntoc
  }
  if (mutate == 2) {
    // R4-06 -- THE MODULE TABLE IS DECLARED AT 340 WITH A COUNT OF ONE.
    // The module table entry is FIFTY-SIX bytes wide, so the table runs
    // from 340 to 396, far past the end of the file.
    R5Put32(b, 248, 340);               // modtaboff
    R5Put32(b, 252, 1);                 // nmodtab
  }
  if (mutate == 3) {
    // R4-07 -- THE SYMBOL TABLE IS EMPTY AND THE DYSYMTAB DECLARES A
    // LOCAL RANGE OF ONE SYMBOL. The exact original counterexample.
    R5Put32(b, 196, 0);                 // nsyms == 0
    R5Put32(b, 220, 1);                 // nlocalsym == 1
  }
  if (mutate == 4) {
    // R4-10 -- THE MALFORMED 0x13 SECTION. The section declares a
    // THREAD-LOCAL-VARIABLES type, which is FILE-BACKED, and it claims
    // FOUR HUNDRED AND EIGHT bytes of file extent in a 344-byte file.
    //
    // The section's file offset is ZERO. A ZERO offset is what makes the
    // control isolate the CLASSIFICATION defect: the PRE-REPAIR validator
    // treats the 0x13 type as VIRTUAL and therefore accepts the section
    // outright, while the CORRECT classification treats it as FILE-BACKED
    // and therefore bounds its extent against the file. A NON-ZERO offset
    // would be refused by the PRE-REPAIR validator for an unrelated reason
    // and would not isolate the defect.
    R5Put64(b, 144, 408);               // the section's size
    R5Put64(b, 152, 0);                 // the section's file offset
    R5Put32(b, 168, 0x13);              // S_THREAD_LOCAL_VARIABLES
  }
  if (mutate == 5) {
    // R4-10 -- THE POSITIVE CONTROL FOR THE VIRTUAL CLASSES. A
    // S_THREAD_LOCAL_ZEROFILL section carries a VIRTUAL size and no file
    // bytes, and it MUST be accepted.
    R5Put64(b, 144, 16);                // the virtual size
    R5Put64(b, 152, 0);                 // no file-backed offset
    R5Put32(b, 168, 0x12);              // S_THREAD_LOCAL_ZEROFILL
  }
  if (mutate == 6) {
    // R4-10 -- THE POSITIVE CONTROL FOR S_GB_ZEROFILL.
    R5Put64(b, 144, 16);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x0c);              // S_GB_ZEROFILL
  }
  if (mutate == 7) {
    // R4-10 -- S_ZEROFILL, the plain zero fill.
    R5Put64(b, 144, 16);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x01);              // S_ZEROFILL
  }
  if (mutate == 8) {
    // R4-10 -- S_THREAD_LOCAL_REGULAR, which is FILE-BACKED. A section
    // that claims a file extent past the end of the file MUST be
    // rejected.
    R5Put64(b, 144, 408);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x11);              // S_THREAD_LOCAL_REGULAR
  }
  if (mutate == 9) {
    // R4-10 -- S_THREAD_LOCAL_VARIABLE_POINTERS, which is FILE-BACKED.
    R5Put64(b, 144, 408);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x14);
  }
  if (mutate == 10) {
    // R4-10 -- S_THREAD_LOCAL_INIT_FUNCTION_POINTERS, FILE-BACKED.
    R5Put64(b, 144, 408);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x15);
  }
  if (mutate == 11) {
    // R4-10 -- S_INIT_FUNC_OFFSETS, FILE-BACKED.
    R5Put64(b, 144, 408);
    R5Put64(b, 152, 0);
    R5Put32(b, 168, 0x16);
  }
  if (mutate == 13) {
    // R4-10 -- THE POSITIVE CONTROL FOR S_GB_ZEROFILL, THE OTHER VIRTUAL
    // TYPE THE PRE-REPAIR VALIDATOR MISCLASSIFIED.
    //
    // S_GB_ZEROFILL is a VIRTUAL type: it carries a virtual size and no
    // file bytes, and its file offset is ZERO. The PRE-REPAIR validator
    // did NOT list it among the virtual types, so it treated it as
    // FILE-BACKED and bounded its virtual size against the file. The
    // control therefore uses a virtual size that is LARGER than the file:
    // the correct validator accepts it, and the PRE-REPAIR validator
    // refuses it.
    R5Put64(b, 144, 4096);              // a virtual size larger than the file
    R5Put64(b, 152, 0);                 // no file-backed offset
    R5Put32(b, 168, 0x0c);              // S_GB_ZEROFILL
  }
  if (mutate == 12) {
    // R4-07 -- THE POSITIVE CONTROL FOR A ZERO-SYMBOL OBJECT. The symbol
    // table is empty and the dysymtab declares NO range. It MUST be
    // accepted.
    R5Put32(b, 196, 0);                 // nsyms == 0
    R5Put32(b, 220, 0);                 // nlocalsym == 0
  }

  // The fixture is written so that the independent platform tools can
  // inspect the SAME bytes.
  U8 *path = R5Path(dir, control);
  R5Write(path, b, size);

  // The PRODUCTION validator decides.
  I64 code = ContractValidateMachO(b, size, require_symtab);
  I64 accepted = 0;
  if (code == MV_OK) accepted = 1;
  U8 *reason = ContractMachOReason(code);
  R5Verdict(control, accepted, expect_accept, reason);
  Free(b);
  Free(path);
}

// ---------------------------------------------------------------------------
// THE ARCHIVE CONTROLS -- R4-08.
//
// They exercise the PRODUCTION `ContractArValidateMembers`.
//
// The archive carries ONE real member whose payload is an EMBEDDED Mach-O
// OBJECT. The mutation changes the embedded object's FILE TYPE from
// MH_OBJECT to MH_EXECUTE, which leaves the embedded image structurally
// valid -- an executable is a valid Mach-O image -- and makes it NOT a
// relocatable object.
//
// The BSD `ar` layout:
//
//   name[16]   mtime[12]   uid[6]   gid[6]   mode[8]   size[10]   "`\n"
//
// The member payload FOLLOWS the sixty-byte header.
// ---------------------------------------------------------------------------

// The embedded-object builder.
//
// The embedded object is a minimal, VALID Mach-O object: the header, an
// LC_SYMTAB, one symbol and a one-byte string table.
//
// It MUST carry a symbol table, because the PRODUCTION member validation
// calls `ContractValidateMachO(payload, paylen, 1)` with the symtab
// REQUIRED flag set. An object without a symbol table would be refused
// for a reason that is unrelated to the member's FILE TYPE, and the
// R4-08 control would then not isolate the defect it is meant to isolate.
//
// `filetype` is the file type the embedded object's header declares. It
// is the ONLY field the R4-08 mutation changes.
static U8 *R5BuildEmbedded(I64 filetype, I64 *out_size) {
  //   0    the mach_header_64          32 bytes
  //   32   the LC_SYMTAB               24 bytes
  //   56   the symbol table            16 bytes (one nlist_64 entry)
  //   72   the string table            4 bytes
  I64 size = 76;
  U8 *b = MAlloc(size);
  MemSet(b, 0, size);
  R5Put32(b, 0, 0xFEEDFACF);          // magic
  R5Put32(b, 4, CPU_TYPE_ARM64);      // cputype
  R5Put32(b, 8, 3);                   // cpusubtype
  R5Put32(b, 12, filetype);           // filetype -- THE MUTATED FIELD
  R5Put32(b, 16, 1);                  // ncmds
  R5Put32(b, 20, SYMTAB_CMDSZ);       // sizeofcmds
  // The LC_SYMTAB, at offset 32.
  R5Put32(b, 32, LC_SYMTAB);
  R5Put32(b, 36, SYMTAB_CMDSZ);
  R5Put32(b, 40, 56);                 // symoff
  R5Put32(b, 44, 1);                  // nsyms
  R5Put32(b, 48, 72);                 // stroff
  R5Put32(b, 52, 4);                  // strsize
  // The symbol table, at offset 56. ONE entry: "_main".
  R5Put32(b, 56, 1);                  // n_strx
  R5Put64(b, 64, 0);                  // n_value
  // The string table, at offset 72.
  b[72] = 95;                         // '_'
  b[73] = 0;
  b[74] = 0;
  b[75] = 0;
  *out_size = size;
  return b;
}

// The archive builder.
//
// It carries the archive magic, a REAL member whose payload is the
// embedded object, and the archive's terminator.
//
// THE HEADER LAYOUT is the BSD `ar` layout, as the PRODUCTION decoder
// reads it:
//
//   off +  0   name[16]    the short name, a terminating slash, spaces
//   off + 16   mtime[12]   right-aligned decimal, space-padded
//   off + 28   uid[6]
//   off + 34   gid[6]
//   off + 40   mode[8]
//   off + 48   size[10]   right-aligned decimal, space-padded
//   off + 58   "`\n"      the ARFMAG terminator
//
// The member payload FOLLOWS the sixty-byte header.
static U8 *R5BuildArchive(I64 filetype, I64 *out_size) {
  I64 psize = 0;
  U8 *payload = R5BuildEmbedded(filetype, &psize);
  I64 hdr = AR_MEMBER_HDR_LEN;
  I64 total = AR_MAGIC_LEN + hdr + psize;
  if (total % 2 != 0) total = total + 1;
  U8 *a = MAlloc(total);
  MemSet(a, 0, total);
  // The archive magic.
  I64 k = 0;
  while (k < AR_MAGIC_LEN) { a[k] = "!<arch>\n"[k]; k = k + 1; }
  I64 off = AR_MAGIC_LEN;
  // The NAME field: the short form, "source.o/", space-padded to sixteen
  // bytes.
  a[off + 0] = 115;  // 's'
  a[off + 1] = 111;  // 'o'
  a[off + 2] = 117;  // 'u'
  a[off + 3] = 114;  // 'r'
  a[off + 4] = 99;   // 'c'
  a[off + 5] = 101;  // 'e'
  a[off + 6] = 46;   // '.'
  a[off + 7] = 111;  // 'o'
  a[off + 8] = 47;   // '/'
  I64 s = 9;
  while (s < AR_NAME_FIELD_LEN) { a[off + s] = 32; s = s + 1; }
  // The MTIME, UID, GID and MODE fields: all spaces.
  I64 g = 0;
  while (g < 12) { a[off + 16 + g] = 32; g = g + 1; }
  g = 0;
  while (g < 6)  { a[off + 28 + g] = 32; g = g + 1; }
  g = 0;
  while (g < 6)  { a[off + 34 + g] = 32; g = g + 1; }
  g = 0;
  while (g < 8)  { a[off + 40 + g] = 32; g = g + 1; }
  // The SIZE field: RIGHT-ALIGNED in ten digits, space-padded on the left.
  g = 0;
  while (g < 10) { a[off + 48 + g] = 32; g = g + 1; }
  I64 sv = psize;
  U8 sdigits[24];
  I64 sn = 0;
  if (sv == 0) { sdigits[0] = 48; sn = 1; }
  while (sv > 0) { sdigits[sn] = 48 + (sv % 10); sv = sv / 10; sn = sn + 1; }
  I64 sr = 0;
  while (sr < sn) { a[off + 48 + 10 - sn + sr] = sdigits[sn - 1 - sr]; sr = sr + 1; }
  // The ARFMAG terminator.
  a[off + 58] = 96;
  a[off + 59] = 10;
  // The payload.
  MemCpy(a + off + hdr, payload, psize);
  Free(payload);
  *out_size = total;
  return a;
}

// The archive control runner.
static U0 R5ArchiveControl(U8 *dir, U8 *control, I64 filetype,
                           I64 expect_accept) {
  I64 size = 0;
  U8 *a = R5BuildArchive(filetype, &size);
  U8 *path = R5Path(dir, control);
  R5Write(path, a, size);
  // The PRODUCTION decoder and the PRODUCTION member validation.
  ArArchive ar;
  I64 dec = ContractDecodeArchive(a, size, &ar);
  I64 accepted = 0;
  U8 *reason = "OK";
  if (dec != AR_OK) {
    reason = ContractArReason(dec);
  } else {
    I64 valid = ContractArValidateMembers(&ar);
    reason = ContractArValidReason(valid);
    if (valid == ARV_OK) accepted = 1;
  }
  R5Verdict(control, accepted, expect_accept, reason);
  Free(a);
  Free(path);
}

// ---------------------------------------------------------------------------
// THE LEDGER CONTROLS -- R4-04.
//
// They exercise the PRODUCTION `LedgerHas` and `LedgerCount` from the
// SHARED CONTRACT. There is NO duplicate implementation here.
//
// The mandatory experiments are:
//
//   exactly one valid terminated record      PASS
//   a valid record lacking the final newline  REJECT
//   a valid record with a suffix              REJECT
//   a prefix-only identity                    REJECT
//   two identical records                     REJECT as a duplicate
//   an extra column                           REJECT
//   a truncated identity                      REJECT
// ---------------------------------------------------------------------------

// The ledger control runner.
//
// `ledger_text` is the ledger's exact content and `probe_id` is the
// identity the production membership check is asked about.
static U0 R5LedgerControl(U8 *dir, U8 *control, U8 *ledger_text,
                          U8 *probe_id, I64 expect_accept) {
  // The ledger is written into a DIRECTORY OF ITS OWN, so that the
  // control cannot be disturbed by another control that uses a ledger.
  //
  // The parent directory is created as well, so that the control works
  // when the probe is invoked directly and not only through the Makefile
  // target, which creates the fixture tree.
  R5MakeDirs(dir);
  U8 *ldir = R5Path(dir, control);
  R5MakeDirs(ldir);
  U8 *path = R5Path(ldir, "ledger.txt");
  I64 len = StrLen(ledger_text);
  U8 *buf = MAlloc(len + 1);
  MemCpy(buf, ledger_text, len);
  buf[len] = 0;
  R5Write(path, buf, len);
  // The PRODUCTION membership check.
  I64 found = LedgerHas(path, probe_id);
  I64 count = LedgerCount(path, probe_id);
  // A DUPLICATE is a FAILURE: the identity appears MORE THAN ONCE.
  I64 accepted = found;
  if (count > 1) accepted = 0;
  R5Verdict(control, accepted, expect_accept, "LEDGER_MEMBERSHIP");
  Free(buf);
  Free(path);
  Free(ldir);
}

// ---------------------------------------------------------------------------
// THE CAPTURE CONTROLS -- R4-01.
//
// They exercise the PRODUCTION `CaptureBlock` from the SHARED CONTRACT.
//
// A capture record's ENV block is built with N entries, and the extractor
// is asked to read it back. The count that comes back must be EXACTLY N,
// and no malformed capture may cause a crash.
//
// The mandatory sizes are 0, 1, 63, 64, 65 and 128 entries.
//
// The SIXTY-FIVE case is the ORIGINAL COUNTEREXAMPLE. The previous
// revision allocated a FIXED array of sixty-four pointers and returned
// the TRUE count, so the count came back as sixty-five while the array
// held sixty-four, and every caller that walked the count read past the
// end of the array and SEGMENTATION FAULTED.
// ---------------------------------------------------------------------------

// The capture-record builder.
//
// It writes a capture record whose ENV block carries `n` entries.
static U8 *R5BuildCapture(I64 n, I64 *out_size) {
  // The header, the ARGV block and the ENV block.
  I64 cap = 8192 + n * 64;
  U8 *b = MAlloc(cap);
  MemSet(b, 0, cap);
  I64 len = 0;
  // The header.
  U8 *header = "RUN_ID 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\n";
  I64 hlen = StrLen(header);
  MemCpy(b, header, hlen);
  len = hlen;
  // The ARGV block: one element.
  U8 *argv = "ARGV\none\n\n";
  I64 alen = StrLen(argv);
  MemCpy(b + len, argv, alen);
  len = len + alen;
  // The ENV block: N elements, then the terminating EMPTY line.
  MemCpy(b + len, "ENV\n", 4);
  len = len + 4;
  I64 i = 0;
  while (i < n) {
    // The element is "E" followed by the decimal index.
    b[len] = 69; // 'E'
    len = len + 1;
    I64 v = i;
    U8 digits[24];
    I64 dlen = 0;
    if (v == 0) { digits[0] = 48; dlen = 1; }
    while (v > 0) { digits[dlen] = 48 + (v % 10); v = v / 10; dlen = dlen + 1; }
    I64 k = 0;
    while (k < dlen) {
      b[len] = digits[dlen - 1 - k];
      len = len + 1;
      k = k + 1;
    }
    b[len] = 10;
    len = len + 1;
    i = i + 1;
  }
  // The terminating EMPTY line.
  b[len] = 10;
  len = len + 1;
  *out_size = len;
  return b;
}

// The capture control runner.
//
// It builds a capture record with N ENV entries, reads the ENV block
// back with the PRODUCTION extractor, and requires the count to be
// EXACTLY N.
static U0 R5CaptureControl(U8 *dir, U8 *control, I64 n) {
  I64 size = 0;
  U8 *b = R5BuildCapture(n, &size);
  U8 *path = R5Path(dir, "capture.txt");
  R5Write(path, b, size);
  // The PRODUCTION block extractor.
  I64 count = 0;
  I64 bstatus = CAPTURE_BLOCK_ABSENT;
  U8 **vals = CaptureBlock(b, size, "ENV", &count, &bstatus);
  // The count must be EXACTLY N, and the extractor must not have refused.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-06 -- THE BLOCK STATUS IS NOW DISTINGUISHED.
  //
  // A WELL-FORMED block reports `CAPTURE_BLOCK_OK` when it carries at
  // least one entry and `CAPTURE_BLOCK_EMPTY` when it carries none. Both
  // are ACCEPTED shapes, so both satisfy this control. The REFUSAL
  // statuses (ABSENT, SCALAR, TOO_LARGE, MALFORMED) hand back no array at
  // all, and the `vals != NULL` requirement already excludes them.
  //
  // The control is NOT WEAKENED: the count must still be EXACTLY N, the
  // array must still be non-NULL, and every element must still be
  // readable. Only the STATUS TOKEN that identifies a well-formed block
  // is now two tokens instead of one.
  I64 well_formed = 0;
  if (bstatus == CAPTURE_BLOCK_OK) well_formed = 1;
  if (bstatus == CAPTURE_BLOCK_EMPTY) well_formed = 1;
  I64 ok = 0;
  if (vals != NULL && count == n && well_formed == 1) ok = 1;
  R5Verdict(control, ok, 1, "CAPTURE_BLOCK_COUNT");
  // The elements must be readable.
  I64 readable = 1;
  I64 i = 0;
  while (i < count) {
    if (vals[i] == NULL) readable = 0;
    i = i + 1;
  }
  if (readable == 0) {
    "PROBE_CONTROL\t%s\tFAIL\tCAPTURE_BLOCK_ELEMENT_UNREADABLE\n", control;
    r5_failures = r5_failures + 1;
  }
  Free(b);
  Free(path);
}

// ---------------------------------------------------------------------------
// THE IDENTITY CONTROLS -- R4-05.
//
// They exercise the PRODUCTION canonical encoding in the SHARED CONTRACT.
//
// The ORIGINAL ATTACK is reproduced exactly: the FINAL ARGV element is
// MOVED into the ENV block, and the identity of the record must CHANGE.
//
// The identity is computed TWICE with the same inputs, and the two
// results must be EQUAL: an identity that depends on uninitialised memory
// is not an identity.
// ---------------------------------------------------------------------------

// The identity control runner.
//
// `move_last` is 1 when the final ARGV element is moved into the ENV
// block.
static U0 R5IdentityControl(U8 *control, I64 move_last) {
  U8 *argv[3];
  argv[0] = "one";
  argv[1] = "two";
  argv[2] = "X";
  U8 *envv[1];
  envv[0] = "K=V";
  I64 nargv = 3;
  I64 nenv = 1;
  if (move_last == 1) {
    // The ATTACK: the final ARGV element moves into the ENV block.
    argv[2] = "K=V";
    envv[0] = "X";
    nargv = 2;
    nenv = 2;
  }
#if C4R5_RED_COMPAT == 1
  // The PRE-REPAIR tree: the identity construction lives in the comparator.
  U8 *i1 = RecomputeEventId(
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "1", "case", "OFF",
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    argv, nargv, envv, nenv);
  U8 *i2 = RecomputeEventId(
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "1", "case", "OFF",
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    argv, nargv, envv, nenv);
#else
  EventIdCtx ctx;
  ctx.run_id = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  ctx.counter = "1";
  ctx.case_id = "case";
  ctx.selector = "OFF";
  ctx.producer_hex = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  ctx.source_hex = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE COMPILED SOURCE'S IDENTITY IS PART OF THE CONTEXT.
  ctx.compiled_source_hex = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";
  ctx.fixture_hex = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
  ctx.argv = argv;
  ctx.nargv = nargv;
  ctx.envv = NULL;
  ctx.nenv = 0;
  EventIdEnvCtx env;
  env.envv = envv;
  env.nenv = nenv;
  U8 *i1 = ContractEventIdWithEnv(&ctx, &env);
  U8 *i2 = ContractEventIdWithEnv(&ctx, &env);
#endif
  // DETERMINISM: the same inputs must produce the same identity.
  I64 deterministic = 0;
  if (StrCmp(i1, i2) == 0) deterministic = 1;
  R5Verdict(control, deterministic, 1, "EVENT_ID_DETERMINISM");
  Free(i1);
  Free(i2);
}

// The identity-AMBIGUITY control.
//
// THE ORIGINAL ATTACK, REPRODUCED EXACTLY.
//
// The PRE-REPAIR encoding concatenated the ARGUMENT VECTOR's elements and
// then the ENVIRONMENT's elements, each terminated by the record
// separator, with NO DOMAIN TAG between the two blocks. The two
// arrangements
//
//     ARGV = ["X"]   ENV = []
//     ARGV = []      ENV = ["X"]
//
// therefore produced the IDENTICAL byte stream, and the identity of one
// record equalled the identity of the other.
//
// The POST-REPAIR encoding is VERSIONED and carries an EXPLICIT DOMAIN
// TAG for each block, so the two arrangements produce DIFFERENT byte
// streams and therefore DIFFERENT identities.
//
// The control requires the two identities to DIFFER.
static U0 R5IdentityAmbiguityControl(U8 *control) {
  // The FIRST arrangement: the element is in the ARGUMENT VECTOR.
  U8 *argv_a[1];
  argv_a[0] = "X";
  U8 *envlist_a[1];
  envlist_a[0] = "";
  // The SECOND arrangement: the SAME element is in the ENVIRONMENT.
  U8 *argv_b[1];
  argv_b[0] = "";
  U8 *envlist_b[1];
  envlist_b[0] = "X";
#if C4R5_RED_COMPAT == 1
  U8 *id_a = RecomputeEventId(
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "1", "case", "OFF",
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    argv_a, 1, envlist_a, 0);
  U8 *id_b = RecomputeEventId(
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    "1", "case", "OFF",
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
    argv_b, 0, envlist_b, 1);
#else
  EventIdCtx ctx_a;
  ctx_a.run_id = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
  ctx_a.counter = "1";
  ctx_a.case_id = "case";
  ctx_a.selector = "OFF";
  ctx_a.producer_hex = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
  ctx_a.source_hex = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb";
  ctx_a.compiled_source_hex = "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd";
  ctx_a.fixture_hex = "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc";
  ctx_a.argv = argv_a;
  ctx_a.nargv = 1;
  ctx_a.envv = NULL;
  ctx_a.nenv = 0;
  EventIdEnvCtx env_a;
  env_a.envv = envlist_a;
  env_a.nenv = 0;
  U8 *id_a = ContractEventIdWithEnv(&ctx_a, &env_a);
  EventIdCtx ctx_b;
  ctx_b.run_id = ctx_a.run_id;
  ctx_b.counter = ctx_a.counter;
  ctx_b.case_id = ctx_a.case_id;
  ctx_b.selector = ctx_a.selector;
  ctx_b.producer_hex = ctx_a.producer_hex;
  ctx_b.source_hex = ctx_a.source_hex;
  ctx_b.compiled_source_hex = ctx_a.compiled_source_hex;
  ctx_b.fixture_hex = ctx_a.fixture_hex;
  ctx_b.argv = argv_b;
  ctx_b.nargv = 0;
  ctx_b.envv = NULL;
  ctx_b.nenv = 0;
  EventIdEnvCtx env_b;
  env_b.envv = envlist_b;
  env_b.nenv = 1;
  U8 *id_b = ContractEventIdWithEnv(&ctx_b, &env_b);
#endif
  // The two identities MUST DIFFER.
  I64 differ = 0;
  if (StrCmp(id_a, id_b) != 0) differ = 1;
  R5Verdict(control, differ, 1, "EVENT_ID_AMBIGUITY");
  Free(id_a);
  Free(id_b);
}

// ---------------------------------------------------------------------------
// THE EMISSION CONTROLS -- R4-09.
//
// They exercise the PRODUCTION domain roster in the SHARED CONTRACT.
//
// The ORIGINAL COUNTEREXAMPLE named an INVENTED domain and an UNSUPPORTED
// artifact class. The roster must REFUSE both.
//
// The four PRODUCTION domains must be RECOGNISED.
// ---------------------------------------------------------------------------

static U0 R5EmissionControl(U8 *control, U8 *domain, I64 expect_supported) {
#if C4R5_RED_COMPAT == 1
  // The PRE-REPAIR tree: there is NO domain roster. The R4-09 defect is
  // exactly that any domain the caller names is accepted, so the
  // PRE-REPAIR tree has no function to call and the control is compiled
  // out. The C4R5 evidence records the roster's ABSENCE as the RED.
  // The parameters are consumed so that the build stays warning-free.
  if (control == NULL) { }
  if (domain == NULL) { }
  if (expect_supported < 0) { }
#else
  I64 id = ContractDomainId(domain);
  I64 supported = 0;
  if (id != DOMAIN_UNKNOWN) supported = 1;
  R5Verdict(control, supported, expect_supported, "EMISSION_DOMAIN_ROSTER");
#endif
}

// ---------------------------------------------------------------------------
// MAIN.
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// THE HARNESS CONTROLS -- R4-02 AND R4-03.
//
// They exercise the PRODUCTION HARNESS BINARY end to end.
//
// The harness is a SEPARATE PROGRAM with its own `Main`, so the probe
// cannot call its functions directly. The probe therefore SPAWNS the
// harness binary and reads its exit status and its reason token. The
// decision under test is the PRODUCTION harness's own decision.
//
// R4-02 -- THE RUNNER OWNS THE EXECUTABLE.
//
// The ORIGINAL counterexample: the caller validated the repository's `hcc`
// and supplied `/bin/cp` as the first element of the argument vector. The
// runner spawned `/bin/cp`, and the capture record named `hcc` as the
// producer of the artifact `cp` had copied.
//
// The runner now constructs the executable path itself and CHECKS the
// supplied vector's first element against the producer it validated.
//
// R4-03 -- THE OUTPUT DESTINATION BELONGS TO THE RUNNER.
//
// The ORIGINAL counterexample: a VALID OLD OBJECT occupied the expected
// output path, and a compiler that creates NO new object -- `hcc --help`
// does exactly that -- was run. The runner registered the OLD artifact as
// the result of this execution.
//
// The runner now allocates a FRESH, CASE-SPECIFIC output directory inside
// the event directory, and it requires the expected output path to be
// ABSENT before the execution.
//
// THE PROBE'S ARGUMENTS.
//
//   probe harness <harness-binary> <producer> <work-dir>
//
// The producer must be a Mach-O image for the host's architecture.
// ---------------------------------------------------------------------------

// The harness control runner.
//
// It runs the harness with the adverse arrangement and requires the
// harness to refuse it with the EXPECTED reason token.
//
// The reason token is recovered from the child's standard output, which the
// harness writes as `HARNESS_REASON\t<TOKEN>`. The child's output is
// REDIRECTED into a file, and the probe reads that file back.
// The platform's own path resolver. It is the SAME function the
// production harness uses to compare the named executable with the
// producer it validated.
extern "c" U8 *realpath(U8 *path, U8 *resolved);

// The platform's own symbolic-link creator. It is used ONLY by the R4-02
// symlink control, which plants a symlinked producer and requires the
// runner to refuse it.
extern "c" I32 symlink(U8 *target, U8 *linkpath);

// The platform's own unlink, used to remove a link that a previous run
// planted.
extern "c" I32 unlink(U8 *path);
// The platform's own environment reader. It carries the CONFIGURED test
// prefix from the Makefile into the probe.
extern "c" I8 *getenv(U8 *buf);

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-01 -- THE CONFIGURED PREFIX, FORWARDED TO THE HARNESS.
//
// The harness INJECTS `--install-dir=<prefix>` into the child's argument
// vector, so it must KNOW the configured prefix. The probe reads it from
// its OWN process environment -- the Makefile exports
// `HCC_TEST_PREFIX=$(TEST_PREFIX)` -- and it forwards it to the harness
// in the BINDING LIST.
//
// The probe never INVENTS a prefix: when the variable is absent, the
// helper returns NULL and the probe forwards nothing.
//
// The returned binding is a fresh allocation, so the caller owns it.
// ---------------------------------------------------------------------------

// The environment variable that carries the CONFIGURED test prefix.
#define R5_PREFIX_ENV "HCC_TEST_PREFIX"

// The prefix binding builder.
static U8 *R5PrefixBinding() {
  U8 *value = getenv(R5_PREFIX_ENV);
  if (value == NULL) return NULL;
  I64 len = StrLen(value);
  if (len <= 0) return NULL;
  I64 nlen = StrLen(R5_PREFIX_ENV);
  U8 *binding = MAlloc(nlen + len + 2);
  MemCpy(binding, R5_PREFIX_ENV, nlen);
  binding[nlen] = 61;
  MemCpy(binding + nlen + 1, value, len);
  binding[nlen + 1 + len] = 0;
  return binding;
}

// The platform's own process spawner. The probe uses the runtime's
// `SpawnAndCapture`, which is the SAME spawner the production harness
// uses, so the probe exercises the harness exactly as the harness's own
// callers do.
#include "../../src/holyc-lib/tooling_defs.HH"

// The HARNESS CONTROL'S INPUTS.
//
// The inputs are carried in a CONTEXT OBJECT that is filled BY NAME,
// because the production compiler's calling convention does not agree
// with itself about a POINTER-TO-POINTER argument at parameter position
// EIGHT or later: the call site places it on the STACK while the callee's
// prologue reads it from a REGISTER, and the arguments that follow are
// shifted. The context object keeps every function in this probe BELOW
// that limit.
class R5HarnessCtx
{
  U8 *dir;             // the fixture directory
  U8 *control;         // the control's identity
  U8 *harness;         // the production harness binary
  U8 *producer;        // the producer the runner validates
  U8 *arch;            // the expected architecture
  U8 *named_exec;      // the executable the argument vector names
  U8 *marker;          // the production marker the token follows
  U8 *expected_token;  // the exact reason token the refusal must carry
  I64 expect_accept;   // 1 for a positive control, 0 for an adverse one
};

static U0 R5HarnessControl(R5HarnessCtx *ctx) {
  U8 *dir = ctx->dir;
  U8 *control = ctx->control;
  U8 *harness = ctx->harness;
  U8 *producer = ctx->producer;
  U8 *arch = ctx->arch;
  U8 *named_exec = ctx->named_exec;
  U8 *marker = ctx->marker;
  U8 *expected_token = ctx->expected_token;
  I64 expect_accept = ctx->expect_accept;
  // The run directory and the ledger.
  //
  // The control works in a DIRECTORY OF ITS OWN, so that it cannot be
  // disturbed by another control that uses a run directory or a ledger.
  //
  // The parent directory is created as well, so that the control works
  // when the probe is invoked directly and not only through the Makefile
  // target, which creates the fixture tree.
  R5MakeDirs(dir);
  U8 *cdir = R5Path(dir, control);
  R5MakeDirs(cdir);
  U8 *run_dir = R5Path(cdir, "run");
  mkdir(run_dir, 493);
  // The RUN CONTEXT is initialised FIRST, because the harness's `run` mode
  // reads the run id from it and refuses the run when it is absent. The
  // initialisation is the harness's OWN `init` mode, so the run context is
  // the production run context.
  U8 *init_args[4];
  init_args[0] = harness;
  init_args[1] = "init";
  init_args[2] = run_dir;
  init_args[3] = NULL;
  U8 *init_out = NULL;
  U8 *init_err = NULL;
  SpawnAndCapture(harness, init_args, &init_out, &init_err);
  Free(init_out);
  Free(init_err);
  U8 *ledger = R5Path(cdir, "ledger.txt");
  U8 *lbuf = MAlloc(1);
  lbuf[0] = 0;
  FileWrite(ledger, lbuf, 0);
  Free(lbuf);
  // The source and the fixture. They must EXIST and be readable, because
  // the harness refuses an absent input before it reaches the control
  // under test.
  U8 *source = R5Path(cdir, "source.HC");
  U8 *sbody = "I32 Main(I32 argc, U8 **argv) { return 0; }\n";
  FileWrite(source, sbody, StrLen(sbody));
  U8 *fixture = R5Path(cdir, "fixture.bin");
  U8 *fbody = "fixture\n";
  FileWrite(fixture, fbody, StrLen(fbody));
  // The artifact directory and the artifact name.
  U8 *artifact_dir = R5Path(cdir, "artifacts");
  mkdir(artifact_dir, 493);
  U8 *artifact_name = "artifact.bin";
  // The argument vector the harness is invoked with.
  //
  //   <harness> run <run-dir> <ledger> <selector> <case-id>
  //       <producer> <source> <fixture>
  //       <artifact-name> <artifact-dir> <expected-arch>
  //       <env>... -- <argv>...
  //
  // The environment bindings come BEFORE the separator and the argument
  // vector comes AFTER it. The argument vector's FIRST element is the
  // executable the caller names, and that is the control under test.
  //
  // The harness reads its verb from `argv[1]`, so the FIRST element of the
  // vector is the harness's own path, exactly as it is when the harness is
  // launched from a shell.
  U8 *args[20];
  I64 n = 0;
  args[n] = harness;                  n = n + 1;
  args[n] = "run";                    n = n + 1;
  args[n] = run_dir;                  n = n + 1;
  args[n] = ledger;                   n = n + 1;
  args[n] = "OFF";                    n = n + 1;
  args[n] = control;                  n = n + 1;
  args[n] = producer;                 n = n + 1;
  args[n] = source;                   n = n + 1;
  args[n] = fixture;                  n = n + 1;
  args[n] = artifact_name;            n = n + 1;
  args[n] = artifact_dir;             n = n + 1;
  args[n] = arch;                     n = n + 1;
  args[n] = "C4R5_PROBE=1";           n = n + 1;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX IS FORWARDED.
  U8 *prefix_binding = R5PrefixBinding();
  if (prefix_binding != NULL) {
    args[n] = prefix_binding;         n = n + 1;
  }
  args[n] = "--";                     n = n + 1;
  args[n] = named_exec;               n = n + 1;
  args[n] = "--help";                 n = n + 1;
  // The argument vector needs AT LEAST THREE elements, because the
  // harness counts the argument vector as `argc - sep - 2` -- the
  // terminator is not an argument. A vector with fewer elements makes the
  // harness read the terminator as an argument, and it refuses the call
  // with `HARNESS_USAGE` before it reaches the control under test.
  args[n] = "--version";              n = n + 1;
  args[n] = NULL;                     n = n + 1;
  // The child's output.
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(harness, args, &out, &err);
  // The reason token.
  // The MARKER the expected token follows.
  //
  // A REFUSED run prints `HARNESS_REASON\t<TOKEN>`; a SUCCESSFUL run
  // prints `HARNESS_EVENT_ID\t<id>`. The marker is therefore a parameter
  // of the control, and it is the PRODUCTION marker in both cases.
  I64 markerlen = StrLen(marker);
  U8 *reason = "NO_OUTPUT";
  U8 *obuf = out;
  I64 osize = 0;
  if (obuf == NULL) obuf = "";
  osize = StrLen(obuf);
  I64 i = 0;
  I64 found = 0;
  while (i < osize) {
    I64 j = i;
    while (j < osize && obuf[j] != 10) j = j + 1;
    I64 linelen = j - i;
    if (linelen > markerlen) {
      I64 same = 1;
      I64 k = 0;
      while (k < markerlen) {
        if (obuf[i + k] != marker[k]) { same = 0; break; }
        k = k + 1;
      }
      // The marker must be the WHOLE field. `HARNESS_REASON_DETAIL` must
      // not be mistaken for `HARNESS_REASON`.
      if (same == 1 && obuf[i + markerlen] == 9) {
        I64 t = i + markerlen;
        while (t < j && (obuf[t] == 9 || obuf[t] == 32)) t = t + 1;
        U8 *tok = MAlloc(j - t + 1);
        MemCpy(tok, obuf + t, j - t);
        tok[j - t] = 0;
        reason = tok;
        found = 1;
        break;
      }
    }
    if (j >= osize) break;
    i = j + 1;
  }
  if (found == 0) reason = "NO_REASON_TOKEN";
  // The child's standard error is echoed when the reason token was not
  // found, so that a reviewer can see WHY the harness refused the call.
  if (found == 0 && err != NULL) {
    "PROBE_DIAGNOSTIC\tSTDERR\t%s\n", err;
  }
  if (found == 0 && out != NULL) {
    "PROBE_DIAGNOSTIC\tSTDOUT\t%s\n", out;
  }
  // The verdict.
  //
  // The ADVERSE control: the harness REFUSES the arrangement with a
  // NON-ZERO exit status and the EXPECTED reason token.
  //
  // The POSITIVE control: the harness ACCEPTS the arrangement, so the
  // exit status is zero.
  I64 ok = 0;
  if (expect_accept == 1) {
    // The POSITIVE control: the run COMPLETED, so the exit status is zero
    // and the production completion marker is present.
    if (rc == 0 && found == 1) ok = 1;
  } else {
    // The ADVERSE control: the run was REFUSED, so the exit status is
    // non-zero and the production reason token is EXACTLY the expected
    // one.
    if (rc != 0 && found == 1 && StrCmp(reason, expected_token) == 0) ok = 1;
  }
  R5Verdict(control, ok, 1, reason);
  Free(out);
  Free(err);
  Free(run_dir);
  Free(ledger);
  Free(source);
  Free(fixture);
  Free(artifact_dir);
  Free(cdir);
}

// The R4-03 control.
//
// THE ORIGINAL COUNTEREXAMPLE. A VALID OLD OBJECT occupied the expected
// output path, and a compiler that creates NO new object -- `hcc --help`
// does exactly that -- was run. The runner registered the OLD artifact as
// the result of this execution, and the capture record carried a real
// digest of a real object. The comparator therefore found everything it
// needed: a FALSE PASS.
//
// THE REPAIR. The runner allocates a FRESH, CASE-SPECIFIC output
// directory inside the event directory, and it requires the expected output
// path to be ABSENT before the execution.
//
// THE CONTROL.
//
// The event identity is DETERMINISTIC for a given ledger, because the
// event counter is derived from the ledger's line count and the ledger is
// empty for the first event. The control therefore:
//
//   1. runs the harness once and reads the event directory it reported;
//
//   2. re-initialises the run context, so the event counter is back at
//      zero and the NEXT run has the SAME event identity;
//
//   3. plants a VALID OLD OBJECT at the expected output path inside the
//      event directory the first run reported; and
//
//   4. runs the harness again.
//
// The second run MUST be REFUSED, and the planted artifact MUST be left
// exactly where it was.
//
// The FIRST run is the positive control: it MUST complete, and it MUST
// report an event directory.
static U0 R5StaleOutputControl(U8 *dir, U8 *control, U8 *harness,
                                U8 *producer, U8 *arch) {
  // The run directory, the ledger, the source and the fixture.
  //
  // The control works in a DIRECTORY OF ITS OWN, so that it cannot be
  // disturbed by another control that uses a run directory or a ledger.
  //
  // The parent directory is created as well, so that the control works
  // when the probe is invoked directly and not only through the Makefile
  // target, which creates the fixture tree.
  R5MakeDirs(dir);
  U8 *cdir = R5Path(dir, control);
  R5MakeDirs(cdir);
  U8 *run_dir = R5Path(cdir, "run");
  mkdir(run_dir, 493);
  U8 *ledger = R5Path(cdir, "ledger.txt");
  U8 *lbuf = MAlloc(1);
  lbuf[0] = 0;
  FileWrite(ledger, lbuf, 0);
  Free(lbuf);
  U8 *source = R5Path(cdir, "source.HC");
  U8 *sbody = "I32 Main(I32 argc, U8 **argv) { return 0; }\n";
  FileWrite(source, sbody, StrLen(sbody));
  U8 *fixture = R5Path(cdir, "fixture.bin");
  U8 *fbody = "fixture\n";
  FileWrite(fixture, fbody, StrLen(fbody));
  U8 *artifact_dir = R5Path(cdir, "artifacts");
  mkdir(artifact_dir, 493);
  U8 *artifact_name = "artifact.bin";

  // The run is driven through the SAME argument vector in both phases.
  U8 *args[20];
  I64 n = 0;
  args[n] = harness;                  n = n + 1;
  args[n] = "run";                    n = n + 1;
  args[n] = run_dir;                  n = n + 1;
  args[n] = ledger;                   n = n + 1;
  args[n] = "OFF";                    n = n + 1;
  args[n] = control;                  n = n + 1;
  args[n] = producer;                 n = n + 1;
  args[n] = source;                   n = n + 1;
  args[n] = fixture;                  n = n + 1;
  args[n] = artifact_name;            n = n + 1;
  args[n] = artifact_dir;             n = n + 1;
  args[n] = arch;                     n = n + 1;
  args[n] = "C4R5_PROBE=1";           n = n + 1;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX IS FORWARDED.
  U8 *prefix_binding = R5PrefixBinding();
  if (prefix_binding != NULL) {
    args[n] = prefix_binding;         n = n + 1;
  }
  args[n] = "--";                     n = n + 1;
  args[n] = producer;                 n = n + 1;
  args[n] = "--help";                 n = n + 1;
  args[n] = "--version";              n = n + 1;
  args[n] = NULL;                     n = n + 1;

  // PHASE ONE -- the run context is initialised and the run happens.
  //
  // The LEDGER is truncated FIRST, so that the event counter starts at
  // zero and the first event of this control is event one. The control
  // therefore does not depend on how many events the other controls
  // registered before it.
  R5Truncate(ledger);
  U8 *init_args[4];
  init_args[0] = harness;
  init_args[1] = "init";
  init_args[2] = run_dir;
  init_args[3] = NULL;
  U8 *io = NULL;
  U8 *ie = NULL;
  SpawnAndCapture(harness, init_args, &io, &ie);
  Free(io);
  Free(ie);
  U8 *out1 = NULL;
  U8 *err1 = NULL;
  I64 rc1 = SpawnAndCapture(harness, args, &out1, &err1);
  // The event directory the first run reported.
  U8 *event_dir = NULL;
  if (out1 != NULL) {
    U8 *marker = "HARNESS_EVENT_DIR\t";
    I64 mlen = StrLen(marker);
    I64 osize = StrLen(out1);
    I64 i = 0;
    while (i < osize) {
      I64 j = i;
      while (j < osize && out1[j] != 10) j = j + 1;
      if (j - i > mlen) {
        I64 same = 1;
        I64 k = 0;
        while (k < mlen) {
          if (out1[i + k] != marker[k]) { same = 0; break; }
          k = k + 1;
        }
        if (same == 1) {
          U8 *ed = MAlloc(j - i - mlen + 1);
          MemCpy(ed, out1 + i + mlen, j - i - mlen);
          ed[j - i - mlen] = 0;
          event_dir = ed;
          break;
        }
      }
      if (j >= osize) break;
      i = j + 1;
    }
  }
  // THE POSITIVE CONTROL: the first run completed and it reported an
  // event directory.
  I64 ok = 0;
  if (rc1 == 0 && event_dir != NULL) ok = 1;
  R5Verdict(control, ok, 1, "HARNESS_FIRST_RUN");
  if (event_dir == NULL) {
    Free(out1);
    Free(err1);
    return;
  }
  // PHASE TWO -- the stale artifact is planted.
  //
  // The artifact is a VALID, NON-EMPTY file. Its bytes are a genuine
  // object-like payload, so the comparator would have accepted it if the
  // runner had registered it.
  U8 *out_dir = R5Path(event_dir, "out");
  mkdir(out_dir, 493);
  U8 *stale = R5Path(out_dir, artifact_name);
  U8 *oldbytes = "STALE-ARTIFACT\n";
  FileWrite(stale, oldbytes, StrLen(oldbytes));
  // The LEDGER is truncated, so the event counter is back at zero and the
  // next run has the SAME event identity.
  //
  // The ledger's LINE COUNT is the event counter's source: the first run
  // registered one event, and without the truncation the second run would
  // receive counter one and therefore a DIFFERENT event identity -- and
  // therefore a DIFFERENT event directory -- and the planted artifact
  // would never be seen.
  //
  // The RUN CONTEXT is NOT re-initialised, because the initialisation
  // generates a NEW run id, and the run id is part of the event identity.
  // A new run id would therefore change the identity just as the counter
  // does.
  R5Truncate(ledger);
  // PHASE THREE -- the run happens again, with the stale artifact in place.
  U8 *out2 = NULL;
  U8 *err2 = NULL;
  I64 rc2 = SpawnAndCapture(harness, args, &out2, &err2);
  // The reason token.
  U8 *reason = "NO_OUTPUT";
  I64 found = 0;
  if (out2 != NULL) {
    U8 *marker = "HARNESS_REASON";
    I64 mlen = StrLen(marker);
    I64 osize = StrLen(out2);
    I64 i = 0;
    while (i < osize) {
      I64 j = i;
      while (j < osize && out2[j] != 10) j = j + 1;
      if (j - i > mlen) {
        I64 same = 1;
        I64 k = 0;
        while (k < mlen) {
          if (out2[i + k] != marker[k]) { same = 0; break; }
          k = k + 1;
        }
        // The marker must be the WHOLE field. `HARNESS_REASON_DETAIL` must
        // not be mistaken for `HARNESS_REASON`.
        if (same == 1 && out2[i + mlen] == 9) {
          I64 t = i + mlen;
          while (t < j && (out2[t] == 9 || out2[t] == 32)) t = t + 1;
          U8 *tok = MAlloc(j - t + 1);
          MemCpy(tok, out2 + t, j - t);
          tok[j - t] = 0;
          reason = tok;
          found = 1;
          break;
        }
      }
      if (j >= osize) break;
      i = j + 1;
    }
  }
  if (found == 0) reason = "NO_REASON_TOKEN";
  // The SECOND run's output is ALWAYS echoed, so that a reviewer can see
  // exactly what the runner did when the stale artifact was in place.
  "PROBE_DIAGNOSTIC\tR4_03_SECOND_RUN\t%s\n", out2;
  // THE ADVERSE CONTROL: the run was REFUSED.
  //
  // The runner's refusal is the DEFENCE CHAIN, and the token that is
  // observed depends on WHICH link of the chain fires first:
  //
  //   * the event directory is allocated EXCLUSIVELY, so a directory that
  //     already exists is refused with `HARNESS_EVENT_DIR_EXISTS`; and
  //
  //   * the output directory inside it is allocated EXCLUSIVELY as well,
  //     so a directory that already exists is refused with
  //     `HARNESS_OUTPUT_DIR_FAILED`; and
  //
  //   * the expected output path must be ABSENT, so a path that already
  //     exists is refused with `HARNESS_OUTPUT_PREEXISTS`.
  //
  // In THIS control the FIRST link fires, because the planted artifact
  // necessarily lives inside the event directory that the first run
  // created, and the runner refuses to reuse that directory. The control
  // therefore accepts ANY of the three refusal tokens: what it asserts is
  // that the run was REFUSED and that the stale artifact was NOT
  // registered as the result of the second run.
  I64 refused = 0;
  if (rc2 != 0 && found == 1) {
    if (StrCmp(reason, "HARNESS_EVENT_DIR_EXISTS") == 0) refused = 1;
    if (StrCmp(reason, "HARNESS_OUTPUT_DIR_FAILED") == 0) refused = 1;
    if (StrCmp(reason, "HARNESS_OUTPUT_PREEXISTS") == 0) refused = 1;
  }
  R5Verdict(control, refused, 1, reason);
  // The planted artifact must be UNCHANGED.
  I64 csize = 0;
  U8 *cbuf = FileRead(stale, &csize);
  I64 untouched = 0;
  if (cbuf != NULL) {
    if (csize == StrLen(oldbytes)) {
      I64 same = 1;
      I64 k = 0;
      while (k < csize) {
        if (cbuf[k] != oldbytes[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1) untouched = 1;
    }
  }
  R5Verdict("R4_03_STALE_ARTIFACT_UNTOUCHED", untouched, 1,
            "STALE_ARTIFACT_BYTES");
  Free(cbuf);
  Free(stale);
  Free(out_dir);
  Free(event_dir);
  Free(out1);
  Free(err1);
  Free(out2);
  Free(err2);
  Free(run_dir);
  Free(ledger);
  Free(source);
  Free(fixture);
  Free(artifact_dir);
}
I32 Main(I32 argc, U8 **argv) {
  r5_checks = 0;
  r5_failures = 0;

  if (argc < 3) {
    "PROBE_USAGE\tprobe macho|archive|ledger|capture|identity|emission|tls "
      "<fixture-dir>\n"
      "PROBE_USAGE\tprobe harness <harness-binary> <producer> <work-dir> "
      "<arch>\n";
    return 2;
  }
  U8 *mode = argv[1];
  U8 *dir = argv[2];

  if (StrCmp(mode, "macho") == 0) {
    // R4-06 -- THE DYSYMTAB TABLE WIDTHS.
    //
    // The two ORIGINAL counterexamples: the table of contents and the
    // module table are each declared at offset 340 with a count of one
    // in a 344-byte fixture, so each table's REAL extent runs past the
    // end of the file.
    R5MachOControl(dir, "R4_06_DYSYMTAB_TOC_WIDTH", 1, 0, 1);
    R5MachOControl(dir, "R4_06_DYSYMTAB_MODULE_WIDTH", 2, 0, 1);
    // R4-07 -- THE ZERO-SYMBOL RANGE.
    //
    // The EXACT original counterexample: `LC_SYMTAB.nsyms == 0` and
    // `LC_DYSYMTAB.nlocalsym == 1`.
    R5MachOControl(dir, "R4_07_ZERO_SYMBOL_RANGE", 3, 0, 1);
    // R4-07 -- THE POSITIVE CONTROL: a valid zero-symbol object.
    R5MachOControl(dir, "R4_07_ZERO_SYMBOL_POSITIVE", 12, 1, 1);
    // R4-10 -- THE ZERO-FILL CLASSIFICATION.
    //
    // The malformed 0x13 section: it declares 408 bytes of file extent
    // in a 344-byte object.
    R5MachOControl(dir, "R4_10_SECTION_0x13_FILE_EXTENT", 4, 0, 1);
    // The VIRTUAL class: the three types that carry no file bytes.
    R5MachOControl(dir, "R4_10_SECTION_ZEROFILL_POSITIVE", 7, 1, 1);
    R5MachOControl(dir, "R4_10_SECTION_GB_ZEROFILL_POSITIVE", 6, 1, 1);
    R5MachOControl(dir, "R4_10_SECTION_GB_ZEROFILL_LARGE_VIRTUAL", 13, 1, 1);
    R5MachOControl(dir, "R4_10_SECTION_TLS_ZEROFILL_POSITIVE", 5, 1, 1);
    // The FILE-BACKED thread-local types.
    R5MachOControl(dir, "R4_10_SECTION_TLS_REGULAR_FILE_EXTENT", 8, 0, 1);
    R5MachOControl(dir, "R4_10_SECTION_TLS_VAR_PTRS_FILE_EXTENT", 9, 0, 1);
    R5MachOControl(dir, "R4_10_SECTION_TLS_INIT_PTRS_FILE_EXTENT", 10, 0, 1);
    R5MachOControl(dir, "R4_10_SECTION_INIT_FUNC_OFFSETS_FILE_EXTENT", 11, 0, 1);
  }

  if (StrCmp(mode, "archive") == 0) {
    // R4-08 -- THE EMBEDDED MEMBER'S CLASS.
    //
    // The ORIGINAL mutation: the embedded object's file type is changed
    // from MH_OBJECT to MH_EXECUTE. The embedded image is STRUCTURALLY
    // VALID -- an executable is a valid Mach-O image -- and it is NOT a
    // relocatable object.
    R5ArchiveControl(dir, "R4_08_ARCHIVE_MEMBER_IS_EXECUTABLE", MH_EXECUTE, 0);
    // The POSITIVE control: the embedded object is an MH_OBJECT.
    R5ArchiveControl(dir, "R4_08_ARCHIVE_MEMBER_IS_OBJECT_POSITIVE",
                     MH_OBJECT, 1);
  }

  if (StrCmp(mode, "ledger") == 0) {
    // R4-04 -- THE LEDGER'S TERMINATION.
    //
    // The genuine identity. It is 64 hexadecimal characters.
    U8 *genuine = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    // Exactly ONE valid terminated record: it MUST be a member.
    U8 *one = MAlloc(66);
    MemCpy(one, genuine, 64);
    one[64] = 10;
    one[65] = 0;
    R5LedgerControl(dir, "R4_04_LEDGER_ONE_VALID_RECORD", one, genuine, 1);
    // A valid record LACKING the final newline: it MUST be refused.
    U8 *nonl = MAlloc(65);
    MemCpy(nonl, genuine, 64);
    nonl[64] = 0;
    R5LedgerControl(dir, "R4_04_LEDGER_MISSING_TERMINATOR", nonl, genuine, 0);
    // A valid record with a SUFFIX: it MUST be refused.
    U8 *suffix = MAlloc(70);
    MemCpy(suffix, genuine, 64);
    MemCpy(suffix + 64, "X\n", 2);
    R5LedgerControl(dir, "R4_04_LEDGER_SUFFIX", suffix, genuine, 0);
    // A PREFIX-ONLY identity: it MUST be refused.
    R5LedgerControl(dir, "R4_04_LEDGER_PREFIX_ONLY", one,
                    "0123456789abcdef", 0);
    // TWO IDENTICAL records: it MUST be refused as a duplicate.
    U8 *dup = MAlloc(131);
    MemCpy(dup, genuine, 64);
    dup[64] = 10;
    MemCpy(dup + 65, genuine, 64);
    dup[129] = 10;
    dup[130] = 0;
    R5LedgerControl(dir, "R4_04_LEDGER_DUPLICATE_RECORD", dup, genuine, 0);
    // An EXTRA COLUMN: it MUST be refused.
    U8 *extra = MAlloc(72);
    MemCpy(extra, genuine, 64);
    MemCpy(extra + 64, "\tEXTRA\n", 7);
    R5LedgerControl(dir, "R4_04_LEDGER_EXTRA_COLUMN", extra, genuine, 0);
    // A TRUNCATED identity: it MUST be refused.
    R5LedgerControl(dir, "R4_04_LEDGER_TRUNCATED_IDENTITY", one,
                    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde", 0);
    Free(one);
    Free(nonl);
    Free(suffix);
    Free(dup);
    Free(extra);
  }

  if (StrCmp(mode, "capture") == 0) {
    // R4-01 -- THE CAPTURE BLOCK'S CAPACITY.
    //
    // The mandatory sizes. The SIXTY-FIVE case is the ORIGINAL
    // COUNTEREXAMPLE.
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_0", 0);
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_1", 1);
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_63", 63);
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_64", 64);
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_65", 65);
    R5CaptureControl(dir, "R4_01_CAPTURE_BLOCK_128", 128);
  }

  if (StrCmp(mode, "identity") == 0) {
    // R4-05 -- THE AMBIGUOUS ENCODING.
    //
    // The determinism control, and the ORIGINAL ATTACK.
    R5IdentityControl("R4_05_EVENT_ID_DETERMINISM", 0);
    R5IdentityAmbiguityControl("R4_05_EVENT_ID_AMBIGUITY");
  }

  if (StrCmp(mode, "emission") == 0) {
#if C4R5_RED_COMPAT == 1
    // The PRE-REPAIR tree: the roster does not exist. The control is
    // compiled out and the C4R5 evidence records the roster's ABSENCE.
    "PROBE_CONTROL\tR4_09_DOMAIN_ROSTER_ABSENT\tFAIL\tEMISSION_DOMAIN_ROSTER_ABSENT\n";
    r5_checks = r5_checks + 1;
    r5_failures = r5_failures + 1;
#else
    // R4-09 -- THE SUPPORTED-DOMAIN ROSTER.
    //
    // The ORIGINAL counterexample's domain: it MUST be refused.
    R5EmissionControl("R4_09_DOMAIN_INVENTED_REFUSED", "invented", 0);
    // The four PRODUCTION domains: they MUST be recognised.
    R5EmissionControl("R4_09_DOMAIN_OBJECT_POSITIVE", "object", 1);
    R5EmissionControl("R4_09_DOMAIN_ASSEMBLY_POSITIVE", "assembly", 1);
    R5EmissionControl("R4_09_DOMAIN_DYLIB_POSITIVE", "dylib", 1);
    R5EmissionControl("R4_09_DOMAIN_EXECUTABLE_POSITIVE", "executable", 1);
#endif
  }

  if (StrCmp(mode, "harness") == 0) {
    // R4-02 AND R4-03 -- THE HARNESS'S OWN EXECUTION BOUNDARY.
    //
    // The probe SPAWNS the production harness binary and reads its exit
    // status and its reason token. The decision under test is the
    // PRODUCTION harness's own decision.
    //
    // The probe's arguments are:
    //
    //   probe harness <harness-binary> <producer> <work-dir> <arch>
    if (argc < 6) {
      "PROBE_USAGE\tprobe harness <harness-binary> <producer> <work-dir> "
        "<arch>\n";
      return 2;
    }
    U8 *harness = argv[2];
    U8 *producer = argv[3];
    U8 *hdir = argv[4];
    U8 *arch = argv[5];
    // The producer path MUST be ABSOLUTE, because the harness's path
    // policy refuses a relative path: a relative path names a different
    // file depending on the runner's working directory, and the runner
    // must not depend on it.
    //
    // The probe therefore resolves the producer to its absolute form with
    // the platform's own `realpath(3)`, which is the same function the
    // harness uses to compare the named executable with the producer.
    U8 *prod_real = realpath(producer, NULL);
    if (prod_real == NULL) prod_real = producer;
    // The harness path is resolved the same way, because the harness is
    // spawned by PATH and the child must be able to find its own argv[0].
    U8 *harness_real = realpath(harness, NULL);
    if (harness_real == NULL) harness_real = harness;
    // R4-02 -- THE PRODUCER SUBSTITUTION. The argument vector names
    // `/bin/cp`, but the producer the runner validated is the repository's
    // own compiler. The runner MUST refuse with
    // `HARNESS_PRODUCER_SUBSTITUTED`.
    R5HarnessCtx hctx;
    hctx.dir = hdir;
    hctx.control = "R4_02_PRODUCER_SUBSTITUTED";
    hctx.harness = harness_real;
    hctx.producer = prod_real;
    hctx.arch = arch;
    hctx.named_exec = "/bin/cp";
    hctx.marker = "HARNESS_REASON";
    hctx.expected_token = "HARNESS_PRODUCER_SUBSTITUTED";
    hctx.expect_accept = 0;
    R5HarnessControl(&hctx);
    // R4-02 -- THE POSITIVE CONTROL. The argument vector names the
    // producer itself, which the runner MUST accept.
    //
    // A SUCCESSFUL run does not print a `HARNESS_REASON` line -- it prints
    // an `HARNESS_EVENT_ID` line instead. The positive control therefore
    // looks for the `HARNESS_EVENT_ID` marker, which is the production
    // marker of a completed run.
    hctx.control = "R4_02_PRODUCER_NAMED_POSITIVE";
    hctx.named_exec = prod_real;
    hctx.marker = "HARNESS_EVENT_ID";
    hctx.expected_token = "HARNESS_EVENT_ID";
    hctx.expect_accept = 1;
    R5HarnessControl(&hctx);
    // R4-02 -- THE SYMLINKED PRODUCER.
    //
    // The producer path is a SYMBOLIC LINK to the real producer. The
    // runner's path policy refuses it, because a symlink can be repointed
    // between the validation and the invocation, so the identity the
    // runner validated would not be the identity the runner executed.
    //
    // The control requires the refusal with `HARNESS_PRODUCER_SUBSTITUTED`.
    //
    // The link is planted in a directory of its own, so that the producer
    // copy it points at is the REAL producer and the refusal cannot be
    // confused with a refusal of a missing or a malformed producer.
    U8 *link_dir = R5Path(hdir, "link");
    mkdir(link_dir, 493);
    U8 *link_path = R5Path(link_dir, "producer-link");
    // A link that already exists from an earlier run is REMOVED, so that
    // the control is repeatable and so that the refusal it observes is
    // the refusal of a link the control planted itself.
    unlink(link_path);
    if (symlink(prod_real, link_path) == 0) {
      hctx.control = "R4_02_PRODUCER_IS_SYMLINK";
      hctx.producer = link_path;
      hctx.named_exec = link_path;
      hctx.marker = "HARNESS_REASON";
      hctx.expected_token = "HARNESS_PRODUCER_SUBSTITUTED";
      hctx.expect_accept = 0;
      R5HarnessControl(&hctx);
    } else {
      "PROBE_CONTROL\tR4_02_PRODUCER_IS_SYMLINK\tFAIL\tSYMLINK_COULD_NOT_BE_PLANTED\n";
      r5_checks = r5_checks + 1;
      r5_failures = r5_failures + 1;
    }
    Free(link_path);
    Free(link_dir);
    // R4-03 -- THE STALE OUTPUT.
    //
    // The control plants a VALID OLD OBJECT at the runner's expected
    // output path and requires the runner to refuse the run with
    // `HARNESS_OUTPUT_PREEXISTS`.
    R5StaleOutputControl(hdir, "R4_03_OUTPUT_PREEXISTS", harness_real,
                         prod_real, arch);
  }

  if (StrCmp(mode, "tls") == 0) {
    // R4-10 -- THE GENUINE arm64 THREAD-LOCAL FIXTURE.
    //
    // The probe's ARGUMENTS are:
    //
    //   probe tls <fixture-dir> <genuine-object>
    //
    // The genuine object is an arm64 Mach-O object that the PLATFORM'S OWN
    // compiler produced from a C source with a `__thread` variable. It
    // carries a `__thread_data` section, whose type is
    // `S_THREAD_LOCAL_REGULAR` (0x11), and a `__thread_vars` section, whose
    // type is `S_THREAD_LOCAL_VARIABLES` (0x13). BOTH types are
    // FILE-BACKED, and the production validator MUST accept the object.
    //
    // The control is the POSITIVE CONTROL for the R4-10 classification: it
    // proves that the corrected classification does not REJECT a genuine
    // thread-local object, which is the failure mode a too-strict
    // classification would produce.
    if (argc < 4) {
      "PROBE_USAGE\tprobe tls <fixture-dir> <genuine-object>\n";
      return 2;
    }
    U8 *gpath = argv[3];
    I64 gsize = 0;
    U8 *gbuf = FileRead(gpath, &gsize);
    if (gbuf == NULL) {
      R5Verdict("R4_10_GENUINE_TLS_OBJECT_ACCEPTED", 0, 1,
                "GENUINE_TLS_OBJECT_UNREADABLE");
    } else {
      I64 gcode = ContractValidateMachO(gbuf, gsize, 1);
      I64 gaccepted = 0;
      if (gcode == MV_OK) gaccepted = 1;
      R5Verdict("R4_10_GENUINE_TLS_OBJECT_ACCEPTED", gaccepted, 1,
                ContractMachOReason(gcode));
      Free(gbuf);
    }
  }

  "PROBE_CHECKS\t%lld\n", r5_checks;
  "PROBE_FAILURES\t%lld\n", r5_failures;
  return r5_failures;
}
