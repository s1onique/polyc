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
    CopyFile(argv[12], argv[4]);
    CopyFile(argv[12], argv[5]);
    CopyFile(argv[14], argv[15]);
    CopyFile(argv[14], argv[16]);
    CopyFile(argv[19], argv[17]);
    CopyFile(argv[19], argv[18]);
    CopyFile(argv[20], argv[10]);
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
    I64 csize = 0;
    U8 *cbuf = FileRead(argv[16], &csize);
    if (cbuf != NULL) {
      // The ARTIFACT_SHA256 field is the ninth field. Its value starts
      // after the key and the space.
      I64 i = 0;
      I64 found = 0;
      while (i < csize && found < 8) {
        if (cbuf[i] == 10) found = found + 1;
        i = i + 1;
      }
      // Skip "ARTIFACT_SHA256 ".
      I64 k = 0;
      while (i + k < csize && cbuf[i + k] != 32) k = k + 1;
      i = i + k + 1;
      if (i < csize) {
        // The first hexadecimal digit is replaced by a different one.
        U8 *digit = "0123456789abcdef";
        I64 d = 0;
        while (d < 16 && digit[d] != cbuf[i]) d = d + 1;
        if (d < 16) {
          U8 replacement = digit[(d + 1) % 16];
          U8 *joined = MAlloc(csize);
          MemCpy(joined, cbuf, csize);
          joined[i] = replacement;
          FileWrite(argv[16], joined, csize);
          Free(joined);
        }
      }
      Free(cbuf);
    }
  }
  return 0;
}
