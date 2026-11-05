// tools/quality/driver-required-route-correction03-adverse.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03.
//
// THE ADVERSE PROBE.
//
// It INDEPENDENTLY mutates or removes ONE observable of a validated
// comparator input and asserts that the comparator REJECTS the mutated
// input with the EXPECTED reason.
//
// The point is that a comparator which reports "PASS" on a mutated
// observation proves nothing. Each probe therefore:
//
//   1. takes a KNOWN-GOOD input directory (produced by a real OFF/ON run);
//   2. COPIES it into a FRESH, ISOLATED directory;
//   3. mutates or removes exactly ONE observable;
//   4. runs the comparator against the mutated copy;
//   5. asserts that the comparator's exit status is NONZERO and that the
//      EXPECTED reason token appears in its output.
//
// Every probe uses its OWN directory. No probe can reuse an artifact from
// an earlier probe or an earlier case.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

// The probe copies a file byte for byte.
static I64 CopyFile(U8 *from, U8 *to) {
  I64 size = 0;
  U8 *buf = FileRead(from, &size);
  if (buf == NULL) return 0;
  if (FileWrite(to, buf, size) == 0) return 0;
  return size;
}

// The probe writes a fixed byte sequence.
static I64 WriteBytes(U8 *path, U8 *bytes, I64 n) {
  if (FileWrite(path, bytes, n) == 0) return 0;
  return n;
}

// The probe appends a byte sequence to a file.
static I64 AppendBytes(U8 *path, U8 *bytes, I64 n) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  U8 *joined = MAlloc(size + n + 1);
  MemCpy(joined, buf, size);
  MemCpy(joined + size, bytes, n);
  I64 ok = FileWrite(path, joined, size + n);
  Free(joined);
  if (ok == 0) return 0;
  return size + n;
}

// The probe removes a file.
static I64 RemoveFile(U8 *path) {
  return unlink(path);
}

// The probe truncates a file to zero bytes.
//
// The truncation MUST actually truncate: `FileWrite` opens without
// O_TRUNC by default, so writing zero bytes would be a NO-OP and the
// artifact would survive unchanged. The probe therefore opens the file
// with O_TRUNC explicitly and closes it.
static I64 TruncateFile(U8 *path) {
  I32 fd = open(path, O_RDWR | O_TRUNC, 420);
  if (fd == -1) return 0;
  close(fd);
  return 1;
}

// ---------------------------------------------------------------------------
// THE MACH-O STRUCTURAL MUTATION HELPERS.
//
// These three mutate the Mach-O STRUCTURE of the PolyC artifact in place.
// They are the MANDATORY structural controls that the comparator's
// independent validation must reject:
//
//   OUT_OF_BOUNDS_NSYMS         the LC_SYMTAB command declares MORE
//                               symbols than the file can hold
//   UNDERSIZED_SYMBOL_TABLE     the LC_SYMTAB command declares a symbol
//                               table whose extent does not fit in the file
//   OUT_OF_BOUNDS_STRING_ENTRY  a symbol entry's string index points
//                               outside the string table
//
// Each mutation is applied to a COPY, and each must be rejected by the
// comparator with its OWN reason token. A comparator that accepted any
// of them would be able to be satisfied by a malformed image.
//
// The mutations need the LOCATION of the LC_SYMTAB load command, so the
// probe re-walks the load commands of the artifact it was given.
// ---------------------------------------------------------------------------

// The probe reads a little-endian 32-bit word.
static I64 ReadWord32(U8 *buf, I64 size, I64 off) {
  if (off < 0 || off + 4 > size) return -1;
  return buf[off] + buf[off + 1] * 256 + buf[off + 2] * 65536 +
         buf[off + 3] * 16777216;
}

// The probe writes a little-endian 32-bit word.
static I64 WriteWord32(U8 *buf, I64 size, I64 off, I64 value) {
  if (off < 0 || off + 4 > size) return 0;
  buf[off] = value % 256;
  buf[off + 1] = (value / 256) % 256;
  buf[off + 2] = (value / 65536) % 256;
  buf[off + 3] = (value / 16777216) % 256;
  return 1;
}

// The probe finds the offset of the LC_SYMTAB load command. It returns -1
// when there is no such command, which makes the mutation FAIL CLOSED.
static I64 FindSymtabCmd(U8 *buf, I64 size) {
  if (size < 32) return -1;
  I64 ncmds = ReadWord32(buf, size, 16);
  I64 sizeofcmds = ReadWord32(buf, size, 20);
  if (ncmds < 0 || ncmds > 4096) return -1;
  if (sizeofcmds < 0 || 32 + sizeofcmds > size) return -1;
  I64 off = 32;
  I64 limit = 32 + sizeofcmds;
  I64 i = 0;
  while (i < ncmds) {
    if (off > limit - 8) return -1;
    I64 cmd = ReadWord32(buf, size, off);
    I64 cmdsize = ReadWord32(buf, size, off + 4);
    if (cmdsize < 8) return -1;
    if (cmdsize > limit - off) return -1;
    if (cmd == 2) return off;
    off = off + cmdsize;
    i = i + 1;
  }
  return -1;
}

// The probe applies a Mach-O structural mutation to the PolyC artifact.
static I64 MutateMachO(U8 *path, U8 *mutation) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  I64 cmd = FindSymtabCmd(buf, size);
  if (cmd < 0) {
    Free(buf);
    return 0;
  }
  I64 done = 0;
  if (StrCmp(mutation, "OUT_OF_BOUNDS_NSYMS") == 0) {
    // The symbol count is the FOURTH word of the LC_SYMTAB command.
    // It is raised to a value that cannot fit in the file.
    I64 symoff = ReadWord32(buf, size, cmd + 8);
    if (symoff >= 0 && symoff <= size) {
      I64 maxfit = (size - symoff) / 16;
      done = WriteWord32(buf, size, cmd + 12, maxfit + 1000);
    }
  }
  if (StrCmp(mutation, "UNDERSIZED_SYMBOL_TABLE") == 0) {
    // The symbol count is raised to a value that does NOT fit at the
    // symbol table's offset, so the table is undersized relative to its
    // declaration.
    I64 symoff = ReadWord32(buf, size, cmd + 8);
    if (symoff >= 0 && symoff <= size) {
      I64 maxfit = (size - symoff) / 16;
      // A count of maxfit + 1 entries does NOT fit at symoff.
      done = WriteWord32(buf, size, cmd + 12, maxfit + 1);
    }
  }
  if (StrCmp(mutation, "OUT_OF_BOUNDS_STRING_ENTRY") == 0) {
    // The FIRST symbol entry's string index is pointed OUTSIDE the
    // string table. The symbol table's own extent is left intact, so
    // ONLY the string index is out of bounds.
    I64 symoff = ReadWord32(buf, size, cmd + 8);
    I64 nsyms = ReadWord32(buf, size, cmd + 12);
    I64 strsize = ReadWord32(buf, size, cmd + 20);
    if (symoff >= 0 && symoff <= size && nsyms > 0 &&
        symoff + 16 <= size && strsize >= 0) {
      // The index is the string table's own size, which is one past its
      // last valid byte.
      done = WriteWord32(buf, size, symoff, strsize);
    }
  }
  if (done == 1) {
    FileWrite(path, buf, size);
  }
  Free(buf);
  return done;
}

// The CAPTURE-RECORD mutator.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// It alters exactly ONE field of the capture record, and it locates the
// field BY ITS KEY rather than by a fixed offset, so the mutation cannot
// silently edit a DIFFERENT field when the record's shape changes.
//
// The FORGED mutations replace a field's value with a DIFFERENT value of
// the same shape. The record therefore remains well formed -- it parses,
// every field is present, and every digest is still sixty-four hexadecimal
// digits -- but its CONTENTS no longer imply the EVENT_ID it carries.
//
// The MISSING mutations DELETE a field outright, so the record no longer
// carries the evidence the recomputation needs.
static I64 MutateCapture(U8 *path, U8 *mutation) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  I64 result = 0;
  I64 i = 0;
  while (i < size) {
    I64 lend = i;
    while (lend < size && buf[lend] != 10) lend = lend + 1;
    // The line is `KEY VALUE` or `KEY`.
    I64 sp = -1;
    I64 k = i;
    while (k < lend) {
      if (buf[k] == 32) { sp = k; break; }
      k = k + 1;
    }
    if (sp > i) {
      I64 klen = sp - i;
      U8 *key = MAlloc(klen + 1);
      MemCpy(key, buf + i, klen);
      key[klen] = 0;
      I64 hit = 0;
      I64 delete_it = 0;
      if (StrCmp(mutation, "FORGED_EVENT_SOURCE") == 0 &&
          StrCmp(key, "SOURCE_SHA256") == 0) hit = 1;
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
      // R6-03 -- THE COMPILED SOURCE'S DIGEST IS FORGED AS WELL.
      //
      // The event identity binds BOTH the ORIGINAL source's digest and the
      // COMPILED snapshot's digest, in SEPARATE tagged fields. A mutation
      // that alters only the ORIGINAL therefore no longer attacks the
      // identity binding: the COMPILED digest still satisfies the
      // compiled-source validation, and the run is rejected by a
      // DIFFERENT check, with a different reason token.
      //
      // The mutation's STATED intent is to attack the identity binding,
      // so it now alters BOTH digests. The identity recomputation then
      // rejects the record with `CAPTURE_EVENT_ID_MISMATCH`, exactly as
      // the mutation claims.
      if (StrCmp(mutation, "FORGED_EVENT_SOURCE") == 0 &&
          StrCmp(key, "COMPILED_SOURCE_SHA256") == 0) hit = 1;
      if (StrCmp(mutation, "FORGED_EVENT_PRODUCER") == 0 &&
          StrCmp(key, "PRODUCER_SHA256") == 0) hit = 1;
      if (StrCmp(mutation, "FORGED_EVENT_COUNTER") == 0 &&
          StrCmp(key, "EVENT_COUNTER") == 0) hit = 1;
      if (StrCmp(mutation, "MISSING_ENV_APPLIED") == 0 &&
          StrCmp(key, "ENV_APPLIED") == 0) { hit = 1; delete_it = 1; }
      if (StrCmp(mutation, "MISSING_EVENT_COUNTER") == 0 &&
          StrCmp(key, "EVENT_COUNTER") == 0) { hit = 1; delete_it = 1; }
      if (StrCmp(mutation, "MISSING_PRODUCER_ARCH") == 0 &&
          StrCmp(key, "PRODUCER_ARCH") == 0) { hit = 1; delete_it = 1; }
      if (hit == 1) {
        if (delete_it == 1) {
          // The line is removed. The following lines are moved up.
          I64 rest = lend + 1;
          I64 restlen = size - rest;
          U8 *joined = MAlloc(size);
          MemCpy(joined, buf, i);
          if (restlen > 0) MemCpy(joined + i, buf + rest, restlen);
          FileWrite(path, joined, i + restlen);
          Free(joined);
          Free(buf);
          return 1;
        }
        // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
        // R6-03 -- THE FORGED SOURCE DIGESTS ARE FORGED TOGETHER.
        //
        // The `FORGED_EVENT_SOURCE` mutation attacks the IDENTITY binding:
        // the record's contents must no longer imply the identity it
        // carries. The identity binds the ORIGINAL source's digest and
        // the COMPILED snapshot's digest, and the record also states
        // whether the two are EQUAL.
        //
        // When the two digests are forged to DIFFERENT values, the
        // record's own equality statement becomes FALSE, and the record
        // is rejected by the compiled-source consistency check instead
        // of by the identity recomputation. The mutation would then be
        // testing a DIFFERENT property than the one it claims.
        //
        // Both digests are therefore forged to the SAME wrong value, so
        // that the equality statement remains true and the IDENTITY
        // RECOMPUTATION is the check that rejects the record.
        if (StrCmp(mutation, "FORGED_EVENT_SOURCE") == 0) {
          // The forged value. It is a well-formed sixty-four character
          // hexadecimal digest, so the record remains well formed.
          U8 *forged = "ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
          I64 flen = 64;
          // Every source-digest field is set to the SAME forged value.
          U8 *keys[3];
          keys[0] = "SOURCE_SHA256";
          keys[1] = "COMPILED_SOURCE_SHA256";
          keys[2] = "ORIGINAL_SOURCE_SHA256";
          I64 ki = 0;
          while (ki < 3) {
            I64 klen = StrLen(keys[ki]);
            I64 p = 0;
            while (p < size) {
              I64 l = p;
              while (l < size && buf[l] != 10) l = l + 1;
              if (l - p > klen) {
                I64 same = 1;
                I64 k = 0;
                while (k < klen) {
                  if (buf[p + k] != keys[ki][k]) { same = 0; break; }
                  k = k + 1;
                }
                if (same == 1 && buf[p + klen] == 32) {
                  // The field's VALUE begins after the key and the space.
                  I64 vstart = p + klen + 1;
                  if (vstart + flen <= l) {
                    U8 *joined = MAlloc(size);
                    MemCpy(joined, buf, size);
                    MemCpy(joined + vstart, forged, flen);
                    FileWrite(path, joined, size);
                    Free(joined);
                    buf = FileRead(path, &size);
                    result = 1;
                  }
                  break;
                }
              }
              if (l >= size) break;
              p = l + 1;
            }
            ki = ki + 1;
          }
          Free(key);
          Free(buf);
          return result;
        }
        // The value's FIRST character is replaced by a different one. The
        // value keeps its shape -- it is still a digest or a decimal --
        // so the record remains well formed.
        U8 *digit = "0123456789abcdef";
        I64 d = 0;
        while (d < 16 && digit[d] != buf[sp + 1]) d = d + 1;
        if (d < 16) {
          U8 *joined = MAlloc(size);
          MemCpy(joined, buf, size);
          joined[sp + 1] = digit[(d + 1) % 16];
          FileWrite(path, joined, size);
          Free(joined);
          result = 1;
        }
        Free(key);
        Free(buf);
        return result;
      }
      Free(key);
    }
    if (lend >= size) break;
    i = lend + 1;
  }
  // The FORGED_EVENT_ARGV and FORGED_EVENT_ENV mutations operate on the
  // BLOCK fields, which are not `KEY VALUE` lines. They are handled here,
  // because the loop above only finds the single-value fields.
  if (StrCmp(mutation, "FORGED_EVENT_ARGV") == 0 ||
      StrCmp(mutation, "FORGED_EVENT_ENV") == 0) {
    U8 *blockkey = "ARGV";
    if (StrCmp(mutation, "FORGED_EVENT_ENV") == 0) blockkey = "ENV";
    I64 blen = StrLen(blockkey);
    I64 at = -1;
    I64 j = 0;
    while (j + blen <= size) {
      I64 match = 1;
      I64 m = 0;
      while (m < blen) {
        if (buf[j + m] != blockkey[m]) { match = 0; break; }
        m = m + 1;
      }
      // The key must START a line, and it must be the WHOLE line.
      if (match == 1 && (j == 0 || buf[j - 1] == 10)) {
        I64 e = j + blen;
        if (e >= size || buf[e] == 10) { at = j; break; }
      }
      j = j + 1;
    }
    if (at >= 0) {
      // The FIRST value line after the key is altered.
      I64 v = at + blen + 1;
      I64 vend = v;
      while (vend < size && buf[vend] != 10) vend = vend + 1;
      if (vend > v) {
        U8 *joined = MAlloc(size);
        MemCpy(joined, buf, size);
        // The last character of the value is changed, so the value keeps
        // its shape and its length.
        joined[vend - 1] = 90;
        FileWrite(path, joined, size);
        Free(joined);
        Free(buf);
        return 1;
      }
    }
  }
  Free(buf);
  return result;
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 4) {
    "REASON_DETAIL=usage: adverse <probe-id> <mutation> <work-dir>\n";
    return 2;
  }
  U8 *probe_id = argv[1];
  U8 *mutation = argv[2];
  U8 *work = argv[3];

  // The MUTATIONS. Each one mutates or removes exactly ONE observable.
  //
  //   ZERO_BYTE_ARTIFACT   the PolyC artifact is truncated to zero bytes
  //   MISSING_ARTIFACT     the PolyC artifact is removed
  //   IDENTICAL_GARBAGE    BOTH artifacts are replaced by the SAME garbage,
  //                        so the two sides agree with each other and only
  //                        the independent VALIDATION can reject them
  //   GARBAGE_BOTH_SIDES   the PolyC artifact is replaced by garbage, and
  //                        the oracle artifact is replaced by the SAME
  //                        garbage, so the BYTE comparison and the DIGEST
  //                        comparison AGREE and only the CLASS and the
  //                        ARCHITECTURE validation can reject them
  //   WRONG_ARCHITECTURE   the PolyC artifact is replaced by an artifact
  //                        whose Mach-O CPU type is a DIFFERENT architecture
  //   MISSING_SYMBOL       the PolyC artifact is replaced by an object that
  //                        lacks the required symbol
  //   MISSING_STDERR       the PolyC stderr transcript is removed
  //   EXTRA_STDERR         an extra diagnostic is appended to the PolyC
  //                        stderr transcript
  //   STALE_OUTPUT         the PolyC artifact is replaced by a STALE copy
  //                        of an OLD artifact whose bytes differ from the
  //                        oracle's
  //   MISSING_EXECUTABLE   the PolyC artifact is removed AND the exit
  //                        status is replaced by a failing one
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
  // ROUND 2 -- THE NEW ADVERSE MUTATIONS.
  //
  //   FORGED_EXIT_TRAILING_TEXT   the exit status becomes a malformed record
  //                               that still PARSES as the expected value
  //   OVERFLOWING_EXIT            the exit status becomes an integer that
  //                               overflows
  //   NEGATIVE_EXIT               the exit status becomes negative
  //   STALE_BOTH_SIDES            a VALID but STALE artifact is replayed on
  //                               BOTH sides, with its stale capture record
  //   STALE_STDOUT_BOTH_SIDES     a VALID but STALE stdout is replayed on
  //                               BOTH sides
  //   STALE_STDOUT_ON_ONLY        a VALID but STALE stdout is replayed on
  //                               the ON side only
  //   MISSING_CAPTURE             the capture record is removed
  //   ALTERED_CAPTURE             the capture record's artifact digest is
  //                               altered so it no longer matches the bytes
  //
  // The tool receives the extra witnesses it needs through the argument
  // vector, so the harness can point each mutation at its own file.
  //
  //   argv[12] the stale artifact
  //   argv[13] the stale stdout
  //   argv[14] the stale capture record
  //   argv[15] the oracle capture record
  //   argv[16] the PolyC capture record
  //   argv[17] the oracle stdout
  //   argv[18] the PolyC stdout
  //   argv[19] the stale stderr
  //   argv[20] the PolyC stderr
  //   argv[21] the stale ON-side capture record
  //   argv[22] the stale ON-side stdout
  //   argv[23] the stale ON-side stderr
  //   argv[24] the stale ON-side artifact
  //
  // The STALE_BOTH_SIDES mutation replays a stale invocation. The stale
  // invocation on the ORACLE side was produced by the OFF producer, and the
  // stale invocation on the POLYC side was produced by the ON producer, so
  // each side's capture record carries its OWN selector and its OWN
  // producer identity. Both stale invocations are ABSENT from this run's
  // ledger, which is the property that rejects the replay.
  //
  "ADVERSE_PROBE\t%s\t%s\n", probe_id, mutation;

  if (StrCmp(mutation, "ZERO_BYTE_ARTIFACT") == 0) {
    TruncateFile(argv[4]);
  }
  if (StrCmp(mutation, "MISSING_ARTIFACT") == 0) {
    RemoveFile(argv[4]);
  }
  if (StrCmp(mutation, "IDENTICAL_GARBAGE") == 0) {
    // BOTH sides become the SAME garbage. The two sides AGREE with each
    // other, so only the independent VALIDATION can reject them.
    CopyFile(argv[9], argv[5]);
    CopyFile(argv[9], argv[4]);
  }
  if (StrCmp(mutation, "GARBAGE_BOTH_SIDES") == 0) {
    // The same mutation as IDENTICAL_GARBAGE, kept as a distinct token so
    // that the rejection ledger records both named hazards.
    CopyFile(argv[9], argv[5]);
    CopyFile(argv[9], argv[4]);
  }
  if (StrCmp(mutation, "WRONG_ARCHITECTURE") == 0) {
    // The stale artifact carries a DIFFERENT Mach-O CPU type.
    CopyFile(argv[7], argv[4]);
  }
  if (StrCmp(mutation, "MISSING_SYMBOL") == 0) {
    CopyFile(argv[8], argv[4]);
  }
  if (StrCmp(mutation, "MISSING_STDERR") == 0) {
    RemoveFile(argv[10]);
  }
  if (StrCmp(mutation, "EXTRA_STDERR") == 0) {
    U8 *extra = "polyc extra diagnostic\n";
    AppendBytes(argv[10], extra, StrLen(extra));
  }
  if (StrCmp(mutation, "STALE_OUTPUT") == 0) {
    // A STALE artifact: a real, valid artifact from an EARLIER run whose
    // bytes DIFFER from the oracle's current artifact. The BYTE comparison
    // must reject it.
    CopyFile(argv[7], argv[4]);
  }
  if (StrCmp(mutation, "MISSING_EXECUTABLE") == 0) {
    RemoveFile(argv[4]);
    U8 *fail = "1\n";
    WriteBytes(argv[11], fail, 2);
  }

  // --- THE NEW ADVERSE MUTATIONS -----------------------------------------
  if (StrCmp(mutation, "FORGED_EXIT_TRAILING_TEXT") == 0) {
    // The exit status is a MALFORMED record that still begins with the
    // EXPECTED value. Only a STRICT reader rejects it.
    U8 *forged = "0 trailing garbage text\n";
    WriteBytes(argv[11], forged, StrLen(forged));
  }
  if (StrCmp(mutation, "OVERFLOWING_EXIT") == 0) {
    U8 *big = "99999999999999999999999999\n";
    WriteBytes(argv[11], big, StrLen(big));
  }
  if (StrCmp(mutation, "NEGATIVE_EXIT") == 0) {
    U8 *neg = "-5\n";
    WriteBytes(argv[11], neg, StrLen(neg));
  }
  if (StrCmp(mutation, "STALE_BOTH_SIDES") == 0) {
    // A VALID but STALE artifact is replayed on BOTH sides, together with
    // its OWN stale capture record AND its OWN stale transcripts. The two
    // sides AGREE, the artifact is VALID, the digests MATCH the stale
    // capture record, and the byte comparison SUCCEEDS. Only the
    // INVOCATION PROVENANCE -- the fact that this run's ledger does not
    // contain the stale invocation -- can reject it.
    //
    // The ORACLE side replays the stale OFF invocation, and the POLYC side
    // replays the stale ON invocation, so that each side's capture record
    // carries the selector its side requires.
    CopyFile(argv[12], argv[4]);
    CopyFile(argv[12], argv[5]);
    CopyFile(argv[14], argv[15]);
    CopyFile(argv[14], argv[16]);
    CopyFile(argv[19], argv[10]);
    CopyFile(argv[21], argv[16]);
    CopyFile(argv[22], argv[18]);
    CopyFile(argv[23], argv[20]);
    CopyFile(argv[24], argv[5]);
  }
  if (StrCmp(mutation, "STALE_STDOUT_BOTH_SIDES") == 0) {
    // A VALID but STALE stdout is replayed on BOTH sides. The two sides
    // AGREE, so only the transcript DIGEST in the capture record can
    // reject it.
    CopyFile(argv[13], argv[17]);
    CopyFile(argv[13], argv[18]);
  }
  if (StrCmp(mutation, "STALE_STDOUT_ON_ONLY") == 0) {
    CopyFile(argv[13], argv[18]);
  }
  if (StrCmp(mutation, "MISSING_CAPTURE") == 0) {
    RemoveFile(argv[16]);
  }
  if (StrCmp(mutation, "ALTERED_CAPTURE") == 0) {
    // The capture record's ARTIFACT digest is altered so that it no longer
    // matches the bytes the comparator was given. A record that is edited
    // to match a stale file must not become trustworthy.
    //
    // The field is located BY ITS KEY, not by a fixed line offset: the
    // capture record's field order is the harness's, and a fixed offset
    // would silently edit a DIFFERENT field when the record's shape
    // changes.
    I64 csize = 0;
    U8 *cbuf = FileRead(argv[16], &csize);
    if (cbuf != NULL) {
      U8 *key = "ARTIFACT_SHA256 ";
      I64 klen = StrLen(key);
      I64 at = -1;
      I64 i = 0;
      while (i + klen <= csize) {
        I64 match = 1;
        I64 j = 0;
        while (j < klen) {
          if (cbuf[i + j] != key[j]) { match = 0; break; }
          j = j + 1;
        }
        // The key must START a line.
        if (match == 1 && (i == 0 || cbuf[i - 1] == 10)) {
          at = i + klen;
          break;
        }
        i = i + 1;
      }
      if (at >= 0 && at < csize) {
        // The first hexadecimal digit is replaced by a different one.
        U8 *digit = "0123456789abcdef";
        I64 d = 0;
        while (d < 16 && digit[d] != cbuf[at]) d = d + 1;
        if (d < 16) {
          U8 replacement = digit[(d + 1) % 16];
          U8 *joined = MAlloc(csize);
          MemCpy(joined, cbuf, csize);
          joined[at] = replacement;
          FileWrite(argv[16], joined, csize);
          Free(joined);
        }
      }
      Free(cbuf);
    }
  }
  // --- THE MACH-O STRUCTURAL ADVERSE MUTATIONS ----------------------------
  //
  // The helpers are at FILE SCOPE, above Main. Each mutation is applied to
  // a COPY of the PolyC artifact, and each must be rejected by the
  // comparator with its OWN reason token.
  if (StrCmp(mutation, "OUT_OF_BOUNDS_NSYMS") == 0) {
    if (MutateMachO(argv[4], mutation) == 0) {
      "ADVERSE_MUTATION_FAILED\tOUT_OF_BOUNDS_NSYMS\n";
      return 3;
    }
  }
  if (StrCmp(mutation, "UNDERSIZED_SYMBOL_TABLE") == 0) {
    if (MutateMachO(argv[4], mutation) == 0) {
      "ADVERSE_MUTATION_FAILED\tUNDERSIZED_SYMBOL_TABLE\n";
      return 3;
    }
  }
  if (StrCmp(mutation, "OUT_OF_BOUNDS_STRING_ENTRY") == 0) {
    if (MutateMachO(argv[4], mutation) == 0) {
      "ADVERSE_MUTATION_FAILED\tOUT_OF_BOUNDS_STRING_ENTRY\n";
      return 3;
    }
  }
  // --- THE F1 ADVERSE MUTATIONS --------------------------------------------
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // Each mutation attacks ONE trust-boundary property of the execution
  // provenance, and each must be rejected with its OWN reason token.
  //
  //   FORGED_EVENT_SOURCE     the record's SOURCE digest is altered, so
  //                           the record's contents no longer imply the
  //                           identity it carries. The ledger membership
  //                           check cannot see this, because the identity
  //                           is still the genuine registered one.
  //   FORGED_EVENT_ARGV       the record's ARGUMENT VECTOR is altered.
  //   FORGED_EVENT_ENV        the record's ENVIRONMENT is altered.
  //   FORGED_EVENT_COUNTER    the record's EVENT COUNTER is altered.
  //   FORGED_EVENT_PRODUCER   the record's PRODUCER digest is altered.
  //   DUPLICATE_LEDGER_ENTRY  the event identity is registered in the run
  //                           ledger TWICE. Two executions in one run
  //                           cannot share one identity.
  //   MISSING_ENV_APPLIED     the record carries no ENVIRONMENT-APPLIED
  //                           marker, so the environment it names cannot
  //                           be shown to have been in force.
  //   MISSING_EVENT_COUNTER   the record carries no EVENT COUNTER, so the
  //                           identity cannot be recomputed from it.
  //   MISSING_PRODUCER_ARCH   the record carries no PRODUCER ARCHITECTURE,
  //                           so the evidence does not say which target
  //                           the producer was.
  //
  // The PolyC capture record is argv[16] and the run ledger is argv[25].
  if (StrCmp(mutation, "FORGED_EVENT_SOURCE") == 0 ||
      StrCmp(mutation, "FORGED_EVENT_ARGV") == 0 ||
      StrCmp(mutation, "FORGED_EVENT_ENV") == 0 ||
      StrCmp(mutation, "FORGED_EVENT_COUNTER") == 0 ||
      StrCmp(mutation, "FORGED_EVENT_PRODUCER") == 0 ||
      StrCmp(mutation, "MISSING_ENV_APPLIED") == 0 ||
      StrCmp(mutation, "MISSING_EVENT_COUNTER") == 0 ||
      StrCmp(mutation, "MISSING_PRODUCER_ARCH") == 0) {
    if (MutateCapture(argv[16], mutation) == 0) {
      "ADVERSE_MUTATION_FAILED\t%s\n", mutation;
      return 3;
    }
  }
  if (StrCmp(mutation, "DUPLICATE_LEDGER_ENTRY") == 0) {
    // The event identity is appended to the run ledger a SECOND time. The
    // ledger is the runner's record of the executions THIS run performed,
    // and one execution cannot be performed twice under one identity.
    //
    // The LAST COMPLETE record is duplicated. A record is complete only
    // when it is terminated by the record separator, so the scan finds the
    // final separator and the record runs from the separator before it.
    I64 lsize = 0;
    U8 *lbuf = FileRead(argv[25], &lsize);
    if (lbuf == NULL || lsize <= 0) {
      "ADVERSE_MUTATION_FAILED\tDUPLICATE_LEDGER_ENTRY\n";
      return 3;
    }
    I64 end = lsize - 1;
    while (end >= 0 && lbuf[end] != 10) end = end - 1;
    if (end < 0) {
      "ADVERSE_MUTATION_FAILED\tDUPLICATE_LEDGER_ENTRY\n";
      return 3;
    }
    I64 start = end - 1;
    while (start >= 0 && lbuf[start] != 10) start = start - 1;
    start = start + 1;
    I64 len = end - start;
    if (len <= 0) {
      "ADVERSE_MUTATION_FAILED\tDUPLICATE_LEDGER_ENTRY\n";
      return 3;
    }
    // The duplicated record, terminated by the record separator, exactly
    // as the runner writes it.
    U8 *joined = MAlloc(lsize + len + 1);
    MemCpy(joined, lbuf, lsize);
    MemCpy(joined + lsize, lbuf + start, len);
    joined[lsize + len] = 10;
    FileWrite(argv[25], joined, lsize + len + 1);
    Free(joined);
    Free(lbuf);
  }
  return 0;
}
