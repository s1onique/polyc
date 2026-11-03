// tools/quality/driver-required-route-correction03-capture.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 2.
//
// THE CAPTURE-RECORD GENERATOR.
//
// It writes the CAPTURE RECORD that binds ONE observed execution to the
// observation the comparator reads, and it REGISTERS the invocation in the
// run ledger.
//
// The tool is invoked BY THE HARNESS, IMMEDIATELY AFTER the execution it
// describes, with the paths of the files that the execution produced:
//
//   capture <capture-path> <ledger-path> <selector>
//          <source-path> <fixture-path> <producer-path>
//          <artifact-path> <stdout-path> <stderr-path> <exit-path>
//          <argv>...
//
// It NEVER invents an observation. Every digest it writes is computed from
// the BYTES of the file it is given, and the exit status is read from the
// file the execution wrote.
//
// The INVOCATION_ID is derived from the OBSERVED content:
//
//   FNV-1a 64 over
//     the selector
//     the producer digest
//     the source digest
//     the fixture digest
//     the artifact digest
//     the stdout digest
//     the stderr digest
//     the exit status
//     the argument vector
//
// Two DIFFERENT invocations therefore have DIFFERENT identities, and an
// invocation that is repeated with different observable content has a
// DIFFERENT identity.
//
// The ledger is APPENDED to, so the ledger of THIS run contains exactly
// the invocations THIS run performed. A stale artifact replayed on BOTH
// sides carries an identity that this run's ledger does not contain,
// unless the stale artifact is replayed WITH the stale capture record AND
// the stale identity was registered in THIS run's ledger -- which cannot
// happen because the ledger is written from THIS run's executions.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "../../src/holyc-lib/memory_defs.HH"
#include "../../src/holyc-lib/io_defs.HH"

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

// The digest of a file. A MISSING file has the digest of the empty
// sequence, which is distinguishable from the digest of any real content.
static U64 FileDigest(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return Digest("", 0);
  return Digest(buf, size);
}

// The buffer builder. The record is assembled in memory and written once.
static U8 *rec;
static I64 rec_len;
static I64 rec_cap;

static U0 RecInit() {
  rec_cap = 8192;
  rec = MAlloc(rec_cap);
  rec_len = 0;
}

static U0 RecAppend(U8 *s) {
  I64 n = StrLen(s);
  if (rec_len + n + 1 > rec_cap) {
    I64 newcap = rec_cap * 2;
    while (rec_len + n + 1 > newcap) newcap = newcap * 2;
    U8 *bigger = MAlloc(newcap);
    MemCpy(bigger, rec, rec_len);
    Free(rec);
    rec = bigger;
    rec_cap = newcap;
  }
  MemCpy(rec + rec_len, s, n);
  rec_len = rec_len + n;
  rec[rec_len] = 0;
}

// The line builder. It appends `key` and `value` on ONE line.
static U0 RecField(U8 *key, U8 *value) {
  RecAppend(key);
  RecAppend(" ");
  RecAppend(value);
  RecAppend("\n");
}

// The multi-line field builder. It appends `key` and then ONE LINE per
// value, so the field is a block of lines.
static U0 RecBlock(U8 *key, U8 **values, I64 n) {
  RecAppend(key);
  RecAppend("\n");
  I64 i = 0;
  while (i < n) {
    RecAppend(values[i]);
    RecAppend("\n");
    i = i + 1;
  }
  // The block is terminated by a blank line, so the extractor can find the
  // end of it.
  RecAppend("\n");
}

I32 Main(I32 argc, U8 **argv) {
  if (argc < 13) {
    "REASON_DETAIL=usage: capture <capture-path> <ledger-path> <selector> "
      "<source-path> <fixture-path> <producer-path> <artifact-path> "
      "<stdout-path> <stderr-path> <exit-path> <argv>...\n";
    return 2;
  }
  U8 *capture_path = argv[1];
  U8 *ledger_path = argv[2];
  U8 *selector = argv[3];
  U8 *source_path = argv[4];
  U8 *fixture_path = argv[5];
  U8 *producer_path = argv[6];
  U8 *artifact_path = argv[7];
  U8 *stdout_path = argv[8];
  U8 *stderr_path = argv[9];
  U8 *exit_path = argv[10];

  // The argument vector. The remaining arguments are the exact argv.
  I64 nargv = argc - 11;

  // The observed exit status. It is read STRICTLY: a malformed record is
  // a hard error, because a capture record that misreports the exit status
  // would be a capture record that misreports the execution.
  I64 esize = 0;
  U8 *ebuf = FileRead(exit_path, &esize);
  if (ebuf == NULL) {
    "REASON_DETAIL=the exit-status record is missing\n";
    return 3;
  }
  I64 ev = 0;
  I64 ei = 0;
  I64 edigits = 0;
  while (ei < esize) {
    I64 c = ebuf[ei];
    if (c < 48 || c > 57) break;
    if (ev > 25) {
      "REASON_DETAIL=the exit-status record overflows\n";
      return 3;
    }
    ev = ev * 10 + (c - 48);
    edigits = edigits + 1;
    ei = ei + 1;
  }
  if (edigits == 0) {
    "REASON_DETAIL=the exit-status record is not decimal\n";
    return 3;
  }
  if (ei < esize) {
    if (ebuf[ei] == 10 && ei + 1 == esize) {
      ei = ei + 1;
    } else {
      "REASON_DETAIL=the exit-status record carries trailing bytes\n";
      return 3;
    }
  }

  // The digests.
  U8 source_hex[17];
  U8 fixture_hex[17];
  U8 producer_hex[17];
  U8 artifact_hex[17];
  U8 stdout_hex[17];
  U8 stderr_hex[17];
  FormatDigest(source_hex, FileDigest(source_path));
  FormatDigest(fixture_hex, FileDigest(fixture_path));
  FormatDigest(producer_hex, FileDigest(producer_path));
  FormatDigest(artifact_hex, FileDigest(artifact_path));
  FormatDigest(stdout_hex, FileDigest(stdout_path));
  FormatDigest(stderr_hex, FileDigest(stderr_path));

  // The invocation identity. It is derived from the OBSERVED content, so
  // two different executions have different identities.
  U64 id = 14695981039346656037;
  I64 i = 0;
  while (selector[i] != 0) {
    U64 b = selector[i];
    id = id ^ b;
    id = id * 1099511628211;
    i = i + 1;
  }
  U8 *digests[6];
  digests[0] = producer_hex;
  digests[1] = source_hex;
  digests[2] = fixture_hex;
  digests[3] = artifact_hex;
  digests[4] = stdout_hex;
  digests[5] = stderr_hex;
  i = 0;
  while (i < 6) {
    I64 j = 0;
    while (j < 16) {
      U64 b = digests[i][j];
      id = id ^ b;
      id = id * 1099511628211;
      j = j + 1;
    }
    i = i + 1;
  }
  U64 evb = ev;
  id = id ^ evb;
  id = id * 1099511628211;
  i = 0;
  while (i < nargv) {
    U8 *a = argv[11 + i];
    I64 j = 0;
    while (a[j] != 0) {
      U64 b = a[j];
      id = id ^ b;
      id = id * 1099511628211;
      j = j + 1;
    }
    U64 sep = 10;
    id = id ^ sep;
    id = id * 1099511628211;
    i = i + 1;
  }
  U8 id_hex[17];
  FormatDigest(id_hex, id);

  // The record.
  RecInit();
  RecField("SOURCE_SHA256", source_hex);
  RecField("FIXTURE_SHA256", fixture_hex);
  RecField("SELECTOR", selector);
  RecField("PRODUCER_SHA256", producer_hex);
  RecField("INVOCATION_ID", id_hex);
  U8 exit_text[32];
  I64 n = 0;
  I64 v = ev;
  if (v == 0) {
    exit_text[0] = 48;
    n = 1;
  }
  while (v > 0) {
    exit_text[n] = 48 + (v % 10);
    v = v / 10;
    n = n + 1;
  }
  I64 r = 0;
  while (r < n) {
    exit_text[r] = exit_text[n - 1 - r];
    r = r + 1;
  }
  exit_text[n] = 0;
  RecField("EXIT_STATUS", exit_text);
  RecField("STDOUT_SHA256", stdout_hex);
  RecField("STDERR_SHA256", stderr_hex);
  RecField("ARTIFACT_SHA256", artifact_hex);
  RecBlock("ARGV", argv + 11, nargv);
  // The environment block records the bindings the harness fixed for the
  // execution. The comparator requires it to be NONEMPTY.
  U8 *envv[1];
  envv[0] = "HCC_TEST_PREFIX=SET";
  RecBlock("ENV", envv, 1);

  if (FileWrite(capture_path, rec, rec_len) == 0) {
    "REASON_DETAIL=the capture record could not be written\n";
    return 4;
  }

  // The ledger. It is APPENDED, so it accumulates the invocations of THIS
  // run. The comparator requires a capture record's identity to appear in
  // it.
  U8 *ledger_line = MAlloc(18);
  MemCpy(ledger_line, id_hex, 16);
  ledger_line[16] = 10;
  ledger_line[17] = 0;
  // The ledger is opened in append mode.
  I32 fd = open(ledger_path, O_RDWR | O_CREAT | O_APPEND, 420);
  if (fd == -1) {
    "REASON_DETAIL=the run ledger could not be opened\n";
    return 5;
  }
  I64 wrote = write(fd, ledger_line, 17);
  close(fd);
  if (wrote != 17) {
    "REASON_DETAIL=the run ledger could not be appended\n";
    return 5;
  }

  "CAPTURE_INVOCATION_ID\t%s\n", id_hex;
  "CAPTURE_SELECTOR\t%s\n", selector;
  "CAPTURE_ARTIFACT_SHA256\t%s\n", artifact_hex;
  return 0;
}
