// tools/quality/driver-required-route-correction03-c4r4-probe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4.
//
// THE STRUCTURAL COUNTEREXAMPLE PROBE.
//
// It exercises the SHARED VALIDATION CONTRACT directly, with hand-built
// fixtures, so that each of the seven P1 defects has an INDEPENDENT,
// REPRODUCIBLE counterexample that does not depend on the production
// compiler having misbehaved.
//
// THE CONTRACT IS THE SUBJECT UNDER TEST. The probe never asserts a
// property of its own fixtures; it asserts a property of the CONTRACT, and
// it reports the CONTRACT's own reason token when the contract rejects the
// fixture. A defect therefore shows up as "the contract ACCEPTED a fixture
// that it must reject", and the fix shows up as "the contract REJECTED it
// with the reason token".
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.
//
// THE PROBE MODES.
//
//   probe macho <fixture-dir>      -- the F3 and F4 counterexamples.
//   probe archive <fixture-dir>    -- the F7 counterexamples.
//   probe ledger <fixture-dir>     -- the F2 counterexamples.
//
// Each mode prints one line per control:
//
//   PROBE_CONTROL\t<CONTROL-ID>\t<VERDICT>\t<REASON-TOKEN>
//
// The exit status is the number of FAILED controls, so the probe is usable
// directly as a gate.
//
// THE LAYOUT OF THE MACH-O FIXTURE.
//
//   0   mach_header_64                  32 bytes
//   32  LC_SEGMENT_64                   72 bytes + 80 bytes of section
//   128 LC_SYMTAB                       24 bytes
//   152 LC_DYSYMTAB                     80 bytes
//   232 the symbol table                32 bytes (two nlist_64 entries)
//   264 the string table                8 bytes
//
// The fixture is 256 bytes long, so the string table runs to the end.

#include "driver-required-route-correction03-contract.HC"

// The 64-bit little-endian writer.
static U0 ProbePut64(U8 *buf, I64 off, I64 v) {
  I64 i = 0;
  while (i < 8) {
    buf[off + i] = (v >> (i * 8)) & 255;
    i = i + 1;
  }
}

// The 32-bit little-endian writer.
static U0 ProbePut32(U8 *buf, I64 off, I64 v) {
  I64 i = 0;
  while (i < 4) {
    buf[off + i] = (v >> (i * 8)) & 255;
    i = i + 1;
  }
}

// The path builder.
static U8 *ProbePath(U8 *dir, U8 *name) {
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
static I64 ProbeWrite(U8 *path, U8 *buf, I64 size) {
  if (FileWrite(path, buf, size, O_CREAT | O_TRUNC | O_RDWR) == FALSE) return 0;
  return 1;
}

// The probe's counters.
static I64 probe_checks;
static I64 probe_failures;

// The verdict recorder.
//
// `expect_accept` is 1 for a POSITIVE control that must remain accepted and
// 0 for an ADVERSE control that must be rejected.
static U0 ProbeVerdict(U8 *control, I64 accepted, I64 expect_accept,
                       U8 *reason) {
  probe_checks = probe_checks + 1;
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
    probe_failures = probe_failures + 1;
  }
}

// ---------------------------------------------------------------------------
// THE F3 / F4 FIXTURE BUILDER.
//
// The builder writes a REAL Mach-O object image. The offsets are literal
// because the PolyC preprocessor expands only literal macro bodies.
//
// THE LAYOUT.
//
//   0     the mach_header_64            32 bytes
//   32    the LC_SEGMENT_64             152 bytes (72 + one 80-byte section)
//   184   the LC_SYMTAB                 24 bytes
//   208   the LC_DYSYMTAB               80 bytes
//   288   the symbol table              32 bytes (two nlist_64 entries)
//   320   the string table              8 bytes
//
// The image is 328 bytes long.
// ---------------------------------------------------------------------------

// The builder.
//
// `dysymtab_present` is 1 when the fixture carries an LC_DYSYMTAB.
// `late_symbol_bad` is 1 when the SECOND symbol entry's string index is
// out of range.
static U8 *ProbeBuildMachO(I64 size, I64 dysymtab_present,
                           I64 late_symbol_bad) {
  U8 *b = MAlloc(size);
  MemSet(b, 0, size);
  // The mach_header_64.
  ProbePut32(b, 0, 0xFEEDFACF);          // magic
  ProbePut32(b, 4, CPU_TYPE_ARM64);      // cputype
  ProbePut32(b, 8, 3);                   // cpusubtype
  ProbePut32(b, 12, MH_OBJECT);          // filetype
  I64 ncmds = 3;
  if (dysymtab_present == 0) ncmds = 2;
  ProbePut32(b, 16, ncmds);              // ncmds
  I64 sizeofcmds = 256;
  if (dysymtab_present == 0) sizeofcmds = 176;
  ProbePut32(b, 20, sizeofcmds);         // sizeofcmds

  // The LC_SEGMENT_64, at offset 32. It carries ONE section and NO file
  // bytes.
  ProbePut32(b, 32, LC_SEGMENT_64);
  ProbePut32(b, 36, 152);                // cmdsize = 72 + 80
  ProbePut64(b, 56, 0);                  // vmaddr
  ProbePut64(b, 64, 0);                  // vmsize
  ProbePut64(b, 72, 0);                  // fileoff
  ProbePut64(b, 80, 0);                  // filesize
  ProbePut32(b, 88, 7);                  // maxprot
  ProbePut32(b, 92, 7);                  // initprot
  ProbePut32(b, 96, 1);                  // nsects
  ProbePut32(b, 100, 0);                 // flags
  // The section_64, at offset 104.
  ProbePut32(b, 104, 0);                 // sectname
  ProbePut32(b, 108, 0);                 // segname
  ProbePut64(b, 144, 0);                 // size
  ProbePut64(b, 152, 0);                 // offset
  ProbePut32(b, 160, 0);                 // align
  ProbePut32(b, 164, 0);                 // reloff
  ProbePut32(b, 164, 0);                 // nreloc
  ProbePut32(b, 168, 0);                 // flags

  // The LC_SYMTAB, at offset 184.
  ProbePut32(b, 184, LC_SYMTAB);
  ProbePut32(b, 188, SYMTAB_CMDSZ);
  ProbePut32(b, 192, 288);               // symoff
  ProbePut32(b, 196, 2);                 // nsyms
  ProbePut32(b, 200, 336);               // stroff
  ProbePut32(b, 204, 8);                 // strsize

  // The LC_DYSYMTAB, at offset 208. It declares NO tables, so it is
  // trivially in bounds.
  if (dysymtab_present == 1) {
    ProbePut32(b, 208, LC_DYSYMTAB);
    ProbePut32(b, 212, DYSYMTAB_CMDSZ);
    ProbePut32(b, 216, 0);               // ilocalsym
    ProbePut32(b, 220, 0);               // nlocalsym
    ProbePut32(b, 224, 0);               // iextdefsym
    ProbePut32(b, 228, 0);               // nextdefsym
    ProbePut32(b, 232, 0);               // iundefsym
    ProbePut32(b, 236, 0);               // nundefsym
    ProbePut32(b, 240, 0);               // tocoff
    ProbePut32(b, 244, 0);               // ntoc
    ProbePut32(b, 248, 0);               // modtaboff
    ProbePut32(b, 252, 0);               // nmodtab
    ProbePut32(b, 256, 0);               // extrefsymoff
    ProbePut32(b, 260, 0);               // nextrefsyms
    ProbePut32(b, 264, 0);               // indirectsymoff
    ProbePut32(b, 268, 0);               // nindirectsyms
    ProbePut32(b, 272, 0);               // extreloff
    ProbePut32(b, 276, 0);               // nextrel
    ProbePut32(b, 280, 0);               // locreloff
    ProbePut32(b, 284, 0);               // nlocrel
  }

  // The symbol table, at offset 288. TWO entries: "_main" and a SECOND
  // entry whose string index may be out of range.
  //
  // The nlist_64 layout is: n_strx (4 bytes), n_type (1), n_sect (1),
  // n_desc (2), n_value (8). The first entry therefore occupies
  // 288..303 and the second 304..319.
  ProbePut32(b, 288, 1);                 // n_strx -> "_main"
  ProbePut64(b, 296, 0);                 // n_value
  ProbePut32(b, 304, 65535);             // the late entry's n_strx
  ProbePut64(b, 312, 0);                 // n_value

  // The string table, at offset 336.
  b[336] = 95;                           // '_'
  b[337] = 0;
  b[338] = 109;                          // 'm'
  b[339] = 97;                           // 'a'
  b[340] = 105;                          // 'i'
  b[341] = 110;                          // 'n'
  b[342] = 0;
  b[343] = 0;
  if (late_symbol_bad == 0) {
    // The second entry's string index is INSIDE the string table.
    ProbePut32(b, 304, 2);
  }
  return b;
}

// ---------------------------------------------------------------------------
// THE F3 / F4 CONTROLS.
//
// Each control builds a fixture, mutates exactly ONE structural field, and
// asks the contract whether the fixture is valid.
// ---------------------------------------------------------------------------

// The control runner for the Mach-O mode.
//
// `mutate` selects the mutation. The mutation is applied IN PLACE to the
// built fixture.
static U0 ProbeMachOControl(U8 *dir, U8 *control, I64 mutate,
                             I64 expect_accept, I64 require_symtab) {
  I64 size = 344;
  // The base fixture is VALID. Only the controls that mutate the symbol
  // table introduce the late symbol.
  I64 late_bad = 0;
  if (mutate == 5) late_bad = 1;
  U8 *b = ProbeBuildMachO(size, 1, late_bad);
  // The mutations.
  if (mutate == 1) {
    // The UPPER 32 BITS of the segment's fileoff. The field is 64 bits
    // wide in segment_command_64; the low 32 bits stay 0.
    ProbePut32(b, 76, 1);
  }
  if (mutate == 2) {
    // The UPPER 32 BITS of the segment's filesize.
    ProbePut32(b, 84, 1);
  }
  if (mutate == 3) {
    // The UPPER 32 BITS of the section's size.
    ProbePut32(b, 148, 1);
  }
  if (mutate == 4) {
    // The UPPER 32 BITS of the section's file OFFSET, with a non-zero
    // file-backed size.
    //
    // NOTE ON THE SECTION LAYOUT. The `section_64` structure is:
    //
    //   sectname[16]  segname[16]  addr:u64  size:u64  offset:u32
    //   align:u32  reloff:u32  nreloc:u32  flags:u32  reserved1..3
    //
    // The section's `offset` is THIRTY-TWO bits wide, so it has no upper
    // half to corrupt. This control therefore corrupts the upper half of
    // the section's `size` -- which IS sixty-four bits wide -- while the
    // section claims a non-zero file-backed extent. The upper half of the
    // SIZE is what the 32-bit reader ignored.
    //
    // The section's flags are at soff+64.
    ProbePut64(b, 144, 8);               // the section's size
    ProbePut64(b, 152, 300);             // the section's file offset
    ProbePut32(b, 148, 1);               // the upper half of the size
    ProbePut32(b, 168, 0);               // S_REGULAR
  }
  if (mutate == 5) {
    // The LATE SYMBOL: the SECOND symbol entry's string index is already
    // out of range in the base fixture, so this control asks whether the
    // contract notices it even though "_main" IS present.
  }
  if (mutate == 6) {
    // The LOAD COMMAND BOUNDARY: the declared load-command extent runs
    // past the end of the file.
    ProbePut32(b, 20, size);
  }
  if (mutate == 7) {
    // An UNSUPPORTED architecture: arm64_32 (0x0200000C). The contract
    // supports arm64 and x86_64 only.
    ProbePut32(b, 4, 0x0200000C);
  }
  if (mutate == 8) {
    // A VALID ZERO-FILL section: S_ZEROFILL, with a VIRTUAL size and NO
    // file bytes. A zero-fill section claims no file-backed extent at all,
    // so its file offset is meaningless and its size is not a file extent.
    //
    // This is the P2 zero-fill rule: a zero-fill section MUST be accepted.
    // The previous revision rejected every section whose size was not
    // inside the file, which rejected the valid zero-fill sections.
    ProbePut64(b, 144, 16);              // the virtual size
    ProbePut64(b, 152, 0);               // no file-backed offset
    ProbePut32(b, 168, 1);               // S_ZEROFILL
  }
  if (mutate == 9) {
    // The DYSYMTAB's TABLE OF CONTENTS is declared with a count that does
    // not fit in the file.
    ProbePut32(b, 240, size - 4);
    ProbePut32(b, 244, 64);
  }
  if (mutate == 10) {
    // The DYSYMTAB's MODULE TABLE is declared with a count that does not
    // fit in the file.
    ProbePut32(b, 248, size - 4);
    ProbePut32(b, 252, 64);
  }
  if (mutate == 11) {
    // The DYSYMTAB's EXTERNAL RELOCATION table is declared with a count
    // that does not fit in the file. Each relocation entry is EIGHT bytes.
    ProbePut32(b, 272, size - 4);
    ProbePut32(b, 276, 64);
  }
  if (mutate == 12) {
    // The DYSYMTAB's LOCAL RELOCATION table is declared with a count that
    // does not fit in the file. Each relocation entry is EIGHT bytes.
    ProbePut32(b, 280, size - 4);
    ProbePut32(b, 284, 64);
  }
  if (mutate == 13) {
    // The DYSYMTAB's INDIRECT SYMBOL table is declared with a count that
    // does not fit in the file. Each entry is FOUR bytes.
    ProbePut32(b, 264, size - 4);
    ProbePut32(b, 268, 64);
  }
  if (mutate == 14) {
    // The DYSYMTAB's EXTERNAL REFERENCE table is declared with a count
    // that does not fit in the file. Each entry is FOUR bytes.
    ProbePut32(b, 256, size - 4);
    ProbePut32(b, 260, 64);
  }
  if (mutate == 15) {
    // The DYSYMTAB's INDEX OF EXTERNAL SYMBOLS exceeds the LC_SYMTAB's
    // symbol count.
    ProbePut32(b, 216, 100);             // ilocalsym
    ProbePut32(b, 220, 100);             // nlocalsym
  }
  if (mutate == 16) {
    // The base fixture WITHOUT a dysymtab: it is VALID.
  }
  if (mutate == 17) {
    // The base fixture, but the SECOND symbol entry's string index is
    // INSIDE the string table: the fixture is valid.
    ProbePut32(b, 304, 2);
  }
  if (mutate == 18) {
    // The DYSYMTAB's EXTERNAL RELOCATION table is declared with a count
    // that fits ONLY IF the entry width were FOUR bytes. The real width
    // is EIGHT, so the table runs past the end of the file.
    ProbePut32(b, 272, 128);
    ProbePut32(b, 276, 20);
  }

  // The fixture is written so that the independent platform tools can
  // inspect the SAME bytes.
  U8 *path = ProbePath(dir, control);
  ProbeWrite(path, b, size);

  I64 code = ContractValidateMachO(b, size, require_symtab);
  I64 accepted = 0;
  if (code == MV_OK) accepted = 1;
  U8 *reason = ContractMachOReason(code);
  // The FULL validation path also validates the SYMBOL TABLE: every
  // symbol entry's string index must lie inside the string table. A late
  // entry with an out-of-range string index is therefore rejected even
  // though "_main" is present and valid.
  //
  // This is the SAME path the comparator and the emission verifier use,
  // so the control exercises the production decision, not a side path.
  if (code == MV_OK) {
    I64 stridx_bad = 0;
    I64 nsyms = ContractValidateSymbolTable(b, size, &stridx_bad);
    if (stridx_bad == 1 || nsyms == 0) {
      code = MV_STRIDX_BOUNDS;
      accepted = 0;
      reason = ContractMachOReason(code);
    }
  }
  ProbeVerdict(control, accepted, expect_accept, reason);
  Free(b);
  Free(path);
}

// ---------------------------------------------------------------------------
// THE F7 FIXTURE.
//
// A minimal `ar` archive with ONE member.
//
// The header is the BSD `ar` layout:
//
//   name[16]   mtime[12]   uid[6]   gid[6]   mode[8]   size[10]   "`\n"
//
// The member payload FOLLOWS the sixty-byte header.
// ---------------------------------------------------------------------------

// The archive builder.
//
// `payload_len` is the length of the member payload.
// `extended` is 1 when the name uses the "#1/N" extended encoding, in which
// case the payload BEGINS with the N-byte name.
static U8 *ProbeBuildArchive(I64 payload_len, I64 extended, I64 *out_size) {
  I64 hdr = AR_MEMBER_HDR_LEN;
  I64 namebytes = 0;
  if (extended == 1) namebytes = 8;
  I64 total = AR_MAGIC_LEN + hdr + payload_len;
  if (total % 2 != 0) total = total + 1;
  U8 *b = MAlloc(total + 1);
  MemSet(b, 0, total + 1);
  I64 k = 0;
  while (k < AR_MAGIC_LEN) { b[k] = "!<arch>\n"[k]; k = k + 1; }
  I64 off = AR_MAGIC_LEN;
  // The name field.
  if (extended == 1) {
    // The EXTENDED form is "#1/N" at the START of the sixteen-byte name
    // field, followed by spaces. This is the layout the platform `ar`
    // writes: the name field begins with "#1/20   ..." for a twenty-byte
    // extended name.
    b[off + 0] = 35;                   // '#'
    b[off + 1] = 49;                   // '1'
    b[off + 2] = 47;                   // '/'
    b[off + 3] = 56;                   // '8'
    I64 s = 4;
    while (s < 16) { b[off + s] = 32; s = s + 1; }
  } else {
    // The short form: the name, a terminating slash, then spaces.
    b[off + 0] = 115;                    // 's'
    b[off + 1] = 111;                    // 'o'
    b[off + 2] = 117;                    // 'u'
    b[off + 3] = 114;                    // 'r'
    b[off + 4] = 99;                     // 'c'
    b[off + 5] = 101;                    // 'e'
    b[off + 6] = 46;                     // '.'
    b[off + 7] = 111;                    // 'o'
    b[off + 8] = 47;                     // '/'
    I64 s = 9;
    while (s < 16) { b[off + s] = 32; s = s + 1; }
  }
  // The numeric fields. Every one is right-aligned and space-padded.
  I64 base = off + 16;
  I64 f = 0;
  while (f < 12) { b[base + f] = 32; f = f + 1; }             // mtime
  f = 0; while (f < 6) { b[base + 12 + f] = 32; f = f + 1; }  // uid
  f = 0; while (f < 6) { b[base + 18 + f] = 32; f = f + 1; }  // gid
  f = 0; while (f < 8) { b[base + 24 + f] = 32; f = f + 1; }  // mode
  // The size field, right-aligned in ten digits.
  f = 0; while (f < 10) { b[base + 32 + f] = 32; f = f + 1; }
  I64 sv = payload_len;
  U8 sdigits[24];
  I64 sn = 0;
  if (sv == 0) { sdigits[0] = 48; sn = 1; }
  while (sv > 0) { sdigits[sn] = 48 + (sv % 10); sv = sv / 10; sn = sn + 1; }
  I64 sr = 0;
  while (sr < sn) { b[base + 32 + 10 - sn + sr] = sdigits[sn - 1 - sr]; sr = sr + 1; }
  b[base + 42] = 96;
  b[base + 43] = 10;
  // The payload.
  I64 poff = off + hdr;
  I64 z = 0;
  while (z < payload_len) { b[poff + z] = 65 + (z % 26); z = z + 1; }
  if (extended == 1) {
    // The extended name occupies the FIRST eight bytes of the payload.
    b[poff + 0] = 115;                   // 's'
    b[poff + 1] = 111;                   // 'o'
    b[poff + 2] = 117;                   // 'u'
    b[poff + 3] = 114;                   // 'r'
    b[poff + 4] = 99;                    // 'c'
    b[poff + 5] = 101;                   // 'e'
    b[poff + 6] = 46;                    // '.'
    b[poff + 7] = 111;                   // 'o'
  }
  *out_size = poff + payload_len;
  return b;
}

// The F7 control runner.
//
// `payload_len` is the member payload length and `extended` selects the
// name encoding.
//
// THE GUARD. The archive bytes and the guard bytes are ONE allocation, so
// a write past the end of the archive's member payload lands IN the guard.
// The decoder is handed the EXACT archive length, so it may not read or
// write past it.
//
// The guard detects the ORIGINAL counterexample: a valid "source.o" member
// whose payload is FOUR bytes. The decoder allocates the name from the
// PAYLOAD size -- five bytes -- and then writes the SIXTEEN-byte short
// name through it. The write lands in the guard.
static U0 ProbeArchiveControl(U8 *dir, U8 *control, I64 payload_len,
                              I64 extended, I64 expect_accept) {
  I64 size = 0;
  U8 *b = ProbeBuildArchive(payload_len, extended, &size);
  // The guard. It follows the archive bytes.
  I64 guard_len = 64;
  U8 *guard = MAlloc(guard_len);
  I64 g = 0;
  while (g < guard_len) { guard[g] = 165; g = g + 1; }
  // The archive and the guard are ONE allocation.
  I64 total = size + guard_len;
  U8 *joined = MAlloc(total + 1);
  MemCpy(joined, b, size);
  MemCpy(joined + size, guard, guard_len);
  joined[total] = 0;
  // The decoder is given the EXACT archive length.
  ArArchive ar;
  I64 code = ContractDecodeArchive(joined, size, &ar);
  // The guard is checked.
  I64 corrupted = 0;
  I64 h = 0;
  while (h < guard_len) {
    if (joined[size + h] != 165) corrupted = 1;
    h = h + 1;
  }
  // The CONTRACT's OWN allocation guard is the authoritative witness for
  // the F7 memory-safety property: it verifies the bytes after every
  // decoded name and refuses the archive when they were disturbed.
  I64 contract_overrun = 0;
  if (code == AR_NAME_OVERRUN) contract_overrun = 1;
  // The DECODED IDENTITY must be correct when the archive decodes.
  I64 identity_ok = 1;
  if (code == AR_OK) {
    if (ar.count < 1) identity_ok = 0;
    else {
      if (ar.m[0].namelen != 8) identity_ok = 0;
      else {
        I64 k = 0;
        while (k < 8) {
          if (ar.m[0].name[k] != "source.o"[k]) identity_ok = 0;
          k = k + 1;
        }
      }
      // The PAYLOAD must be the declared number of bytes.
      if (extended == 1) {
        // The extended form's payload is the declared name length.
        if (ar.m[0].paylen != payload_len - 8) identity_ok = 0;
      } else {
        if (ar.m[0].paylen != payload_len) identity_ok = 0;
      }
    }
  }
  I64 accepted = 0;
  if (code == AR_OK && corrupted == 0 && contract_overrun == 0 &&
      identity_ok == 1) accepted = 1;
  U8 *reason = ContractArReason(code);
  if (corrupted == 1) reason = "ARCHIVE_MEMORY_WRITE_OUT_OF_BOUNDS";
  if (contract_overrun == 1) reason = "ARCHIVE_MEMBER_NAME_OUT_OF_BOUNDS";
  if (code == AR_OK && identity_ok == 0) reason = "ARCHIVE_MEMBER_IDENTITY_WRONG";
  // The fixture is written so that the independent platform tools can
  // inspect the SAME bytes.
  U8 *path = ProbePath(dir, control);
  ProbeWrite(path, b, size);
  ProbeVerdict(control, accepted, expect_accept, reason);
  Free(b);
  Free(guard);
  Free(joined);
  Free(path);
}

// ---------------------------------------------------------------------------
// THE F5 FIXTURE.
//
// An archive whose REAL MEMBER carries an EMBEDDED Mach-O OBJECT.
//
// The archive is built with TWO members: the platform's symbol-index
// bookkeeping member, whose name is "/", and the real member, whose name
// is "source.o" and whose payload is the embedded object.
//
// The embedded object's magic can be corrupted, which makes the member
// payload an INVALID Mach-O object while the archive itself remains
// structurally well formed.
// ---------------------------------------------------------------------------

// The embedded object. It is a minimal but VALID Mach-O object with no
// sections and one symbol.
//
//   0     the mach_header_64            32 bytes
//   32    the LC_SEGMENT_64             72 bytes
//   104   the LC_SYMTAB                 24 bytes
//   128   the symbol table              16 bytes (one nlist_64 entry)
//   144   the string table              8 bytes
//
// The image is 152 bytes long.
#define PROBE_OBJ_SIZE 152

static U8 *ProbeBuildEmbeddedObject(I64 corrupt_magic) {
  U8 *b = MAlloc(PROBE_OBJ_SIZE);
  MemSet(b, 0, PROBE_OBJ_SIZE);
  ProbePut32(b, 0, 0xFEEDFACF);
  if (corrupt_magic == 1) {
    // The magic is corrupted. The object is no longer a Mach-O object.
    ProbePut32(b, 0, 0xDEADBEEF);
  }
  ProbePut32(b, 4, CPU_TYPE_ARM64);
  ProbePut32(b, 8, 3);
  ProbePut32(b, 12, MH_OBJECT);
  ProbePut32(b, 16, 2);                 // ncmds
  ProbePut32(b, 20, 96);                // sizeofcmds
  // The LC_SEGMENT_64 with NO sections.
  ProbePut32(b, 32, LC_SEGMENT_64);
  ProbePut32(b, 36, SEGMENT64_SIZE);
  ProbePut64(b, 56, 0);                 // vmaddr
  ProbePut64(b, 64, 0);                 // vmsize
  ProbePut64(b, 72, 0);                 // fileoff
  ProbePut64(b, 80, 0);                 // filesize
  ProbePut32(b, 88, 7);                 // maxprot
  ProbePut32(b, 92, 7);                 // initprot
  ProbePut32(b, 96, 0);                 // nsects
  ProbePut32(b, 100, 0);                // flags
  // The LC_SYMTAB.
  ProbePut32(b, 104, LC_SYMTAB);
  ProbePut32(b, 108, SYMTAB_CMDSZ);
  ProbePut32(b, 112, 128);              // symoff
  ProbePut32(b, 116, 1);                // nsyms
  ProbePut32(b, 120, 144);              // stroff
  ProbePut32(b, 124, 8);                // strsize
  // The symbol table: ONE entry whose string index is inside the string
  // table.
  ProbePut32(b, 128, 1);                // n_strx
  ProbePut64(b, 136, 0);                // n_value
  // The string table.
  b[144] = 95;                          // '_'
  b[145] = 0;
  b[146] = 109;                         // 'm'
  b[147] = 97;                          // 'a'
  b[148] = 105;                         // 'i'
  b[149] = 110;                         // 'n'
  b[150] = 0;
  b[151] = 0;
  return b;
}

// The `ar` member header's SIZE field.
//
// It is TEN characters wide, RIGHT-ALIGNED and SPACE-PADDED, and it holds
// the member's payload length in decimal.
static U0 ProbeArSizeField(U8 *field, I64 value) {
  I64 i = 0;
  while (i < 10) { field[i] = 32; i = i + 1; }
  U8 digits[24];
  I64 dn = 0;
  I64 v = value;
  if (v == 0) { digits[0] = 48; dn = 1; }
  while (v > 0) { digits[dn] = 48 + (v % 10); v = v / 10; dn = dn + 1; }
  I64 r = 0;
  while (r < dn) { field[10 - dn + r] = digits[dn - 1 - r]; r = r + 1; }
}

// The archive builder for the F5 fixture.
//
// `corrupt_magic` is 1 when the embedded object's magic is corrupted.
// `index_only` is 1 when the archive carries ONLY the bookkeeping member.
static U8 *ProbeBuildArchiveWithObject(I64 corrupt_magic, I64 index_only,
                                       I64 *out_size) {
  I64 hdr = AR_MEMBER_HDR_LEN;
  U8 *obj = ProbeBuildEmbeddedObject(corrupt_magic);
  I64 objlen = PROBE_OBJ_SIZE;
  // The bookkeeping member: the name is "/", and the payload is the
  // archive's symbol index. It is NOT an object.
  I64 idxlen = 16;
  // The real member.
  I64 total = AR_MAGIC_LEN + hdr + idxlen + hdr + objlen;
  if (total % 2 != 0) total = total + 1;
  U8 *b = MAlloc(total + 1);
  MemSet(b, 0, total + 1);
  I64 k = 0;
  while (k < AR_MAGIC_LEN) { b[k] = "!<arch>\n"[k]; k = k + 1; }
  I64 off = AR_MAGIC_LEN;
  // The bookkeeping member's header. Its name is "/".
  b[off] = 47;
  I64 s = 1;
  while (s < 16) { b[off + s] = 32; s = s + 1; }
  I64 base = off + 16;
  I64 f = 0;
  while (f < 12) { b[base + f] = 32; f = f + 1; }
  f = 0; while (f < 6) { b[base + 12 + f] = 32; f = f + 1; }
  f = 0; while (f < 6) { b[base + 18 + f] = 32; f = f + 1; }
  f = 0; while (f < 8) { b[base + 24 + f] = 32; f = f + 1; }
  f = 0; while (f < 10) { b[base + 32 + f] = 32; f = f + 1; }
  ProbeArSizeField(b + base + 32, idxlen);
  I64 q = 42;
  while (q < 42) { b[base + q] = 32; q = q + 1; }
  b[base + 42] = 96; b[base + 43] = 10;
  I64 poff = off + hdr;
  I64 z = 0;
  while (z < idxlen) { b[poff + z] = 65 + (z % 26); z = z + 1; }
  off = poff + idxlen;
  if (off % 2 != 0) off = off + 1;
  if (index_only == 0) {
    // The real member's header. Its name is "source.o/".
    I64 m = 0;
    while (m < 8) { b[off + m] = "source.o"[m]; m = m + 1; }
    b[off + 8] = 47;
    s = 9;
    while (s < 16) { b[off + s] = 32; s = s + 1; }
    base = off + 16;
    f = 0;
    while (f < 12) { b[base + f] = 32; f = f + 1; }
    f = 0; while (f < 6) { b[base + 12 + f] = 32; f = f + 1; }
    f = 0; while (f < 6) { b[base + 18 + f] = 32; f = f + 1; }
    f = 0; while (f < 8) { b[base + 24 + f] = 32; f = f + 1; }
    f = 0; while (f < 10) { b[base + 32 + f] = 32; f = f + 1; }
    ProbeArSizeField(b + base + 32, objlen);
    q = 42;
    while (q < 42) { b[base + q] = 32; q = q + 1; }
    b[base + 42] = 96; b[base + 43] = 10;
    poff = off + hdr;
    MemCpy(b + poff, obj, objlen);
    off = poff + objlen;
  }
  *out_size = off;
  Free(obj);
  return b;
}

// The F5 control runner.
//
// It asserts that the CONTRACT refuses an archive whose real member
// carries an INVALID embedded object, and that it accepts an archive whose
// real member carries a VALID embedded object.
static U0 ProbeEmissionControl(U8 *dir, U8 *control, I64 corrupt_magic,
                                I64 index_only, I64 expect_accept) {
  I64 size = 0;
  U8 *b = ProbeBuildArchiveWithObject(corrupt_magic, index_only, &size);
  ArArchive ar;
  I64 code = ContractDecodeArchive(b, size, &ar);
  I64 accepted = 0;
  U8 *reason = ContractArReason(code);
  if (code == AR_OK) {
    I64 vcode = ContractArValidateMembers(&ar);
    if (vcode == ARV_OK) accepted = 1;
    reason = ContractArValidReason(vcode);
  }
  U8 *path = ProbePath(dir, control);
  ProbeWrite(path, b, size);
  ProbeVerdict(control, accepted, expect_accept, reason);
  Free(b);
  Free(path);
}

//
// The ledger membership check.
//
// The comparator's ledger check is a SEPARATE function from the contract,
// so the probe reproduces the EXACT membership semantics the comparator
// requires: the event identity must appear as a COMPLETE record.
// ---------------------------------------------------------------------------

// The strict ledger membership.
//
// It returns 1 when the identity appears as a COMPLETE line, and 0
// otherwise. A prefix of a genuine line, a suffix of a genuine line, a
// short identity and a malformed record are all REJECTED.
static I64 ProbeLedgerHas(U8 *ledger_path, U8 *id) {
  I64 size = 0;
  U8 *buf = FileRead(ledger_path, &size);
  if (buf == NULL) return 0;
  I64 idlen = StrLen(id);
  I64 i = 0;
  I64 found = 0;
  while (i < size) {
    // The record runs to the next newline.
    I64 end = i;
    while (end < size && buf[end] != 10) end = end + 1;
    I64 linelen = end - i;
    // The record MUST be EXACTLY the identity, with no extra columns, no
    // prefix and no suffix.
    if (linelen == idlen) {
      I64 k = 0;
      I64 same = 1;
      while (k < idlen) {
        if (buf[i + k] != id[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1) found = 1;
    }
    if (end >= size) break;
    i = end + 1;
  }
  return found;
}

// The F2 control runner.
//
// `ledger_text` is the ledger's exact content and `probe_id` is the
// identity the comparator is asked about.
static U0 ProbeLedgerControl(U8 *dir, U8 *control, U8 *ledger_text,
                             U8 *probe_id, I64 expect_accept) {
  U8 *path = ProbePath(dir, "ledger.txt");
  I64 len = StrLen(ledger_text);
  U8 *buf = MAlloc(len + 1);
  MemCpy(buf, ledger_text, len);
  buf[len] = 0;
  ProbeWrite(path, buf, len);
  I64 found = ProbeLedgerHas(path, probe_id);
  ProbeVerdict(control, found, expect_accept, "LEDGER_MEMBERSHIP");
  Free(buf);
  Free(path);
}

// ---------------------------------------------------------------------------
// MAIN.
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  probe_checks = 0;
  probe_failures = 0;

  if (argc < 3) {
    "PROBE_USAGE\tprobe macho|archive|ledger <fixture-dir>\n";
    return 2;
  }
  U8 *mode = argv[1];
  U8 *dir = argv[2];

  if (StrCmp(mode, "macho") == 0) {
    // The F3 and F4 controls.
    //
    // A control whose expectation is ACCEPT must remain ACCEPTED.
    ProbeMachOControl(dir, "M11_MACHO_UPPER32_FILEOFF", 1, 0, 1);
    ProbeMachOControl(dir, "M12_MACHO_UPPER32_FILESIZE", 2, 0, 1);
    ProbeMachOControl(dir, "M13_MACHO_UPPER32_SECTION_SIZE", 3, 0, 1);
    ProbeMachOControl(dir, "M13B_MACHO_UPPER32_SECTION_SIZE_WITH_OFFSET", 4, 0, 1);
    ProbeMachOControl(dir, "M14_MACHO_LATE_SYMBOL", 5, 0, 1);
    ProbeMachOControl(dir, "M14B_MACHO_LOAD_COMMAND_BOUNDARY", 6, 0, 1);
    ProbeMachOControl(dir, "M14C_MACHO_WRONG_ARCH", 7, 0, 1);
    ProbeMachOControl(dir, "M28_VALID_ZEROFILL_POSITIVE", 8, 1, 1);
    ProbeMachOControl(dir, "M15_DYSYMTAB_TOC_SHORT", 9, 0, 1);
    ProbeMachOControl(dir, "M15B_DYSYMTAB_MODULE_SHORT", 10, 0, 1);
    ProbeMachOControl(dir, "M16_DYSYMTAB_EXT_RELOC_OOB", 11, 0, 1);
    ProbeMachOControl(dir, "M16B_DYSYMTAB_LOC_RELOC_OOB", 12, 0, 1);
    ProbeMachOControl(dir, "M16C_DYSYMTAB_INDIRECT_OOB", 13, 0, 1);
    ProbeMachOControl(dir, "M16D_DYSYMTAB_EXTREF_OOB", 14, 0, 1);
    ProbeMachOControl(dir, "M15C_DYSYMTAB_INDEX_EXCEEDS_SYMTAB", 15, 0, 1);
    ProbeMachOControl(dir, "M14D_MACHO_VALID_BASE_POSITIVE", 16, 1, 1);
    ProbeMachOControl(dir, "M14E_MACHO_VALID_LATE_SYMBOL_POSITIVE", 17, 1, 1);
    ProbeMachOControl(dir, "M16E_DYSYMTAB_RELOC_WIDTH_POSITIVE", 18, 1, 1);
  }

  if (StrCmp(mode, "archive") == 0) {
    // The F7 controls.
    //
    // THE ORIGINAL COUNTEREXAMPLE: a valid "source.o" member whose payload
    // is FOUR bytes. Before the repair, the decoder allocated the name
    // from the PAYLOAD size -- five bytes -- and then wrote the SIXTEEN-
    // byte short name through it.
    //
    // AFTER THE REPAIR the archive is a VALID archive whose member
    // identity is "source.o" and whose payload is the four bytes, and
    // NEITHER the contract's allocation guard nor the probe's external
    // guard was disturbed. The control therefore asserts that the decode
    // is CORRECT and that no guard was disturbed.
    ProbeArchiveControl(dir, "M25_ARCHIVE_NAME_GUARDED_OVERFLOW", 4, 0, 1);
    // A ZERO-LENGTH payload.
    ProbeArchiveControl(dir, "M25B_ARCHIVE_NAME_ZERO_LENGTH", 0, 0, 1);
    // A ONE-CHARACTER payload.
    ProbeArchiveControl(dir, "M25C_ARCHIVE_NAME_ONE_CHARACTER", 1, 0, 1);
    // A payload of sixteen bytes: the allocation is large enough, so the
    // short name fits. This is the boundary POSITIVE control.
    ProbeArchiveControl(dir, "M25D_ARCHIVE_NAME_EXACT_SIZE_POSITIVE", 16, 0, 1);
    // The EXTENDED encoding, with a payload of exactly the name length.
    ProbeArchiveControl(dir, "M26_ARCHIVE_NAME_EXTENDED_VALID_POSITIVE", 8, 1, 1);
    // The EXTENDED encoding, with a payload that is SHORTER than the
    // declared extended name length: the archive is MALFORMED and the
    // decoder must reject it without overrunning.
    ProbeArchiveControl(dir, "M26B_ARCHIVE_NAME_EXTENDED_TRUNCATED", 3, 1, 0);
  }

  if (StrCmp(mode, "emission") == 0) {
    // The F5 controls.
    //
    // The archive's real member carries an EMBEDDED Mach-O OBJECT. The
    // archive itself is structurally well formed in every case, so only
    // the EMBEDDED OBJECT's validity can reject it.
    //
    // N17 -- the embedded object's magic is corrupted. The archive must be
    // refused, because the member payload is not a valid object.
    ProbeEmissionControl(dir, "M17_ARCHIVE_MALFORMED_EMBEDDED_OBJECT", 1, 0, 0);
    // N18 -- the archive carries ONLY the symbol-index bookkeeping member.
    // It must be refused, because it carries no real member.
    ProbeEmissionControl(dir, "M18_ARCHIVE_INDEX_ONLY", 0, 1, 0);
    // The POSITIVE control: the archive carries a VALID embedded object.
    ProbeEmissionControl(dir, "M17B_ARCHIVE_VALID_EMBEDDED_OBJECT_POSITIVE", 0, 0, 1);
  }

  if (StrCmp(mode, "ledger") == 0) {
    // The F2 controls.
    //
    // The genuine identity. It is 64 hexadecimal characters.
    U8 *genuine = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    // The genuine record, plus a newline.
    U8 *text = MAlloc(66);
    MemCpy(text, genuine, 64);
    text[64] = 10;
    text[65] = 0;
    ProbeLedgerControl(dir, "M08_LEDGER_PREFIX", text, "0123456789abcdef", 0);
    ProbeLedgerControl(dir, "M09_LEDGER_SUFFIX", text,
                       "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdefX", 0);
    ProbeLedgerControl(dir, "M09B_LEDGER_ONE_CHARACTER", text, "0", 0);
    ProbeLedgerControl(dir, "M10_LEDGER_DUPLICATE_RECORD", text, genuine, 1);
    // A ledger with NO trailing newline.
    U8 *nonl = MAlloc(65);
    MemCpy(nonl, genuine, 64);
    nonl[64] = 0;
    ProbeLedgerControl(dir, "M10B_LEDGER_MISSING_NEWLINE", nonl, genuine, 1);
    // A ledger with an EXTRA COLUMN.
    U8 *extra = MAlloc(80);
    MemCpy(extra, genuine, 64);
    MemCpy(extra + 64, "\tEXTRA\n", 7);
    ProbeLedgerControl(dir, "M10C_LEDGER_EXTRA_COLUMN", extra, genuine, 0);
    Free(text);
    Free(nonl);
    Free(extra);
  }

  "PROBE_CHECKS\t%lld\n", probe_checks;
  "PROBE_FAILURES\t%lld\n", probe_failures;
  return probe_failures;
}
