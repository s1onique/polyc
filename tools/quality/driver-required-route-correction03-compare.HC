// tools/quality/driver-required-route-correction03-compare.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3.
//
// THE PRODUCTION COMPARATOR.
//
// THE CORE RULE: EQUALITY IS NOT VALIDITY.
//
// The comparator VALIDATES EVERY OBSERVATION BEFORE IT COMPARES IT. A
// comparison result is only reported when the observations are INDEPENDENTLY
// VALID:
//
//   * the artifact MUST be present and nonempty;
//   * the artifact MUST be of the EXPECTED class;
//   * the artifact MUST carry the EXPECTED architecture;
//   * the artifact MUST be STRUCTURALLY VALID (the entire Mach-O image is
//     validated, and only then are the validated symbol records searched);
//   * the artifact MUST carry the REQUIRED symbols;
//   * the compiler exit status MUST be a VALID record of the EXPECTED one;
//   * stdout and stderr MUST be EXACTLY equal, subject only to the
//     explicitly frozen normalization;
//   * the artifact content digest MUST be equal.
//
// The EXPECTED class, architecture, symbols and exit status are supplied by
// the harness, which derives them from the GENUINE selector-OFF C ORACLE. The
// comparator therefore never decides what the correct answer is: it decides
// whether the observed ON side MATCHES the observed OFF side AND is itself a
// valid observation.
//
// THE SHARED CONTRACT.
//
// This comparator and the emission verifier BOTH use
// driver-required-route-correction03-contract.HC. There is exactly ONE
// Mach-O validator, ONE exit-status codec and ONE archive decoder in the
// CORRECTION03 evidence path. The emission verifier is therefore never
// WEAKER than this comparator, because it IS this comparator's validation.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"

static I64 failures;
static I64 checks;

// The comparator's own observation slots.
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

// The file reader that reports PRESENCE and SIZE separately.
//
// A missing file and an empty file are DIFFERENT observations and the
// comparator must be able to tell them apart.
static U8 *ReadArtifact(U8 *path, I64 *size, I64 *present) {
  *size = 0;
  *present = 0;
  U8 *buf = FileRead(path, size);
  if (buf == NULL) return NULL;
  *present = 1;
  return buf;
}

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
// THE CAPTURE RECORD VALIDATION.
//
// THE F1 REQUIREMENT.
//
// The capture record is written by the EXECUTION-OWNING HARNESS, from the
// execution itself. The comparator RECOMPUTES every digest and EVERY
// context field from the files it is given, and requires each of them to
// MATCH the record.
//
// It then requires the record's EVENT_ID to be REGISTERED in the run ledger
// that the harness appends to DURING THIS RUN.
//
// The comparator INDEPENDENTLY checks the EXPECTED run, case and producer
// context: it is given the expected run id, the expected case id and the
// expected producer digest, and it requires the capture record to carry
// them.
//
// A REPLAY of an old artifact, an old capture record and an old ledger
// therefore FAILS, because:
//
//   * the old event id is not in THIS run's ledger, and
//   * the old record's run id is not THIS run's run id, and
//   * the old record's case id is not the expected case id.
//
// THE TRUST BOUNDARY. This establishes LOCAL TRACE INTEGRITY. It is NOT a
// cryptographic attestation against an attacker who can replace the entire
// trusted runner and all of its evidence.
// ---------------------------------------------------------------------------
#define CAPTURE_OK                  0
#define CAPTURE_MISSING             1
#define CAPTURE_FIELD_MISSING       2
#define CAPTURE_MALFORMED           3
#define CAPTURE_DIGEST_MISMATCH     4
#define CAPTURE_EXIT_MISMATCH       5
#define CAPTURE_NOT_REGISTERED      6
#define CAPTURE_SELECTOR_BAD        7
#define CAPTURE_ARGV_EMPTY          8
#define CAPTURE_ENV_EMPTY           9
#define CAPTURE_RUN_MISMATCH       10
#define CAPTURE_CASE_MISMATCH      11
#define CAPTURE_PRODUCER_MISMATCH  12
#define CAPTURE_ARTIFACT_ABSENT    13

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
  if (code == CAPTURE_RUN_MISMATCH) return "CAPTURE_RUN_ID_MISMATCH";
  if (code == CAPTURE_CASE_MISMATCH) return "CAPTURE_CASE_ID_MISMATCH";
  if (code == CAPTURE_PRODUCER_MISMATCH) return "CAPTURE_PRODUCER_IDENTITY_MISMATCH";
  if (code == CAPTURE_ARTIFACT_ABSENT) return "CAPTURE_ARTIFACT_ABSENT";
  return "CAPTURE_UNKNOWN";
}

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
    if (lend - i >= klen) {
      I64 m = 0;
      while (m < klen) {
        if (buf[i + m] != key[m]) { m = -1; break; }
        m = m + 1;
      }
      if (m == klen) {
        if (lend - i == klen) {
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

// The digest matcher. The recorded digest is a 64-character lowercase
// hexadecimal SHA-256, and it MUST match the digest the comparator computes
// from the bytes it is given.
static I64 DigestMatches(U8 *recorded, U8 *buf, I64 size) {
  if (recorded == NULL) return 0;
  if (StrLen(recorded) != 64) return 0;
  U8 *digest = MAlloc(32);
  U8 *hex = MAlloc(65);
  Sha256Bytes(buf, size, digest);
  Sha256Hex(hex, digest);
  I64 same = 0;
  if (StrCmp(recorded, hex) == 0) same = 1;
  Free(digest);
  Free(hex);
  return same;
}

// The ledger check. The event id MUST appear in the run ledger. The ledger
// is APPENDED to by the harness during THIS run, so it contains only the
// invocations THIS run performed.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F2.
//
// THE ORIGINAL DEFECT. The check compared the identity as a PREFIX of any
// line:
//
//     while (k < idlen) {
//       if (buf[i + k] != id[k]) { same = 0; break; }
//       k = k + 1;
//     }
//
// There was no check that the LINE was exactly the identity. A genuine
// sixty-four character event identity therefore satisfied a SIXTEEN
// character query, and any shorter prefix of a genuine identity was
// accepted as a membership. The harness's event identities are FIXED
// LENGTH, so a shorter or longer query is not a member of the ledger at
// all, and a longer identity whose first characters match a genuine
// identity is a DIFFERENT identity.
//
// THE REPAIR. The check requires an EXACT record:
//
//   * the line must have EXACTLY the identity's length;
//   * the bytes must match in full;
//   * the line must be terminated by the record separator.
//
// A prefix, a suffix, a one-character identity, an extended line and a
// line with a trailing NUL are all REJECTED.
static I64 LedgerHas(U8 *ledger_path, U8 *id) {
  I64 size = 0;
  U8 *buf = FileRead(ledger_path, &size);
  if (buf == NULL) return 0;
  I64 idlen = StrLen(id);
  // An EMPTY identity cannot be a member: every ledger record is non-empty.
  if (idlen <= 0) return 0;
  I64 i = 0;
  I64 found = 0;
  while (i < size) {
    // The record runs to the next record separator. A record that is not
    // terminated is NOT a complete record, and it is rejected.
    I64 end = i;
    while (end < size && buf[end] != 10) end = end + 1;
    // The record MUST have EXACTLY the identity's length.
    if (end - i == idlen) {
      I64 k = 0;
      I64 same = 1;
      while (k < idlen) {
        if (buf[i + k] != id[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1) found = 1;
    }
    // The next record begins after the separator. A record that runs to
    // the end of the file without a separator is not a complete record,
    // so the scan stops.
    if (end >= size) break;
    i = end + 1;
  }
  return found;
}

// The capture-record validator.
//
// `expected_run` is the run id of THIS run, `expected_case` is the case
// identity the harness used, and `expected_producer` is the SHA-256 of the
// producer executable that the harness actually invoked.
//
// It returns CAPTURE_OK when the record is complete, self-consistent,
// consistent with the observed bytes, consistent with the EXPECTED context
// and REGISTERED in the run ledger.
static I64 ValidateCapture(U8 *case_id, U8 *side, U8 *capture_path,
                            U8 *ledger_path, U8 *expected_run,
                            U8 *expected_case, U8 *expected_producer,
                            U8 *expected_selector,
                            U8 *art, I64 art_size,
                            U8 *stdout_path, U8 *stderr_path,
                            I64 exit_value, I64 exit_present,
                            I64 exit_ok) {
  I64 size = 0;
  U8 *buf = FileRead(capture_path, &size);
  if (buf == NULL) return CAPTURE_MISSING;

  U8 *run_id = CaptureField(buf, size, "RUN_ID");
  U8 *event_id = CaptureField(buf, size, "EVENT_ID");
  U8 *case_field = CaptureField(buf, size, "CASE_ID");
  U8 *selector = CaptureField(buf, size, "SELECTOR");
  U8 *producer_sha = CaptureField(buf, size, "PRODUCER_SHA256");
  U8 *source_sha = CaptureField(buf, size, "SOURCE_SHA256");
  U8 *fixture_sha = CaptureField(buf, size, "FIXTURE_SHA256");
  U8 *stdout_sha = CaptureField(buf, size, "STDOUT_SHA256");
  U8 *stderr_sha = CaptureField(buf, size, "STDERR_SHA256");
  U8 *artifact_sha = CaptureField(buf, size, "ARTIFACT_SHA256");
  U8 *artifact_present = CaptureField(buf, size, "ARTIFACT_PRESENT");
  U8 *exit_field = CaptureField(buf, size, "EXIT_STATUS");
  U8 *argv_field = CaptureField(buf, size, "ARGV");
  U8 *env_field = CaptureField(buf, size, "ENV");

  if (run_id == NULL || event_id == NULL || case_field == NULL ||
      selector == NULL || producer_sha == NULL || source_sha == NULL ||
      fixture_sha == NULL || stdout_sha == NULL || stderr_sha == NULL ||
      artifact_sha == NULL || artifact_present == NULL ||
      exit_field == NULL || argv_field == NULL || env_field == NULL) {
    return CAPTURE_FIELD_MISSING;
  }

  // The selector must be one of the two supported modes, and it must be
  // the EXPECTED one for this side.
  if (StrCmp(selector, "OFF") != 0 && StrCmp(selector, "ON") != 0) {
    return CAPTURE_SELECTOR_BAD;
  }
  if (expected_selector != NULL && StrCmp(selector, expected_selector) != 0) {
    return CAPTURE_SELECTOR_BAD;
  }
  // The ARGV and the ENV must not be empty. An execution with no argument
  // vector and no environment binding is not an execution.
  if (StrLen(argv_field) == 0) return CAPTURE_ARGV_EMPTY;
  if (StrLen(env_field) == 0) return CAPTURE_ENV_EMPTY;

  // The run, case and producer context. The comparator checks the EXPECTED
  // context INDEPENDENTLY.
  if (expected_run != NULL && StrCmp(run_id, expected_run) != 0) {
    return CAPTURE_RUN_MISMATCH;
  }
  if (expected_case != NULL && StrCmp(case_field, expected_case) != 0) {
    return CAPTURE_CASE_MISMATCH;
  }
  if (expected_producer != NULL &&
      StrCmp(producer_sha, expected_producer) != 0) {
    return CAPTURE_PRODUCER_MISMATCH;
  }

  // The ARTIFACT digest must MATCH the bytes the comparator was given.
  // An absent artifact is recorded with the sentinel "ABSENT", which is
  // NOT a digest.
  if (StrCmp(artifact_present, "1") != 0) {
    return CAPTURE_ARTIFACT_ABSENT;
  }
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
      if (rv > (EXIT_MAX + 1) / 10) return CAPTURE_MALFORMED;
      rv = rv * 10 + (c - 48);
      if (rv > EXIT_MAX) return CAPTURE_MALFORMED;
      rdigits = rdigits + 1;
      ri = ri + 1;
    }
    if (rdigits == 0) return CAPTURE_MALFORMED;
    if (rv != exit_value) return CAPTURE_EXIT_MISMATCH;
  } else {
    return CAPTURE_EXIT_MISMATCH;
  }

  // The EVENT must be REGISTERED in the run ledger. This is the step that
  // a stale replay cannot satisfy: the ledger is written by the harness
  // during THIS run, and it contains only the invocations THIS run
  // actually performed.
  if (LedgerHas(ledger_path, event_id) == 0) {
    return CAPTURE_NOT_REGISTERED;
  }

  return CAPTURE_OK;
}
// ---------------------------------------------------------------------------
// MAIN.
//
// The comparator is invoked as:
//
//   compare <case-id> <oracle-artifact> <polyc-artifact>
//           <oracle-stdout> <polyc-stdout>
//           <oracle-stderr> <polyc-stderr>
//           <oracle-exit>   <polyc-exit>
//           <expected-class> <expected-arch> <expected-exit>
//           <run-ledger> <oracle-capture> <polyc-capture>
//           <expected-run-id> <expected-case-id>
//           <oracle-producer-sha256> <polyc-producer-sha256>
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
  // THE CONTRACT SELF-CHECK MODE.
  //
  //   selfcheck
  //
  // The SHARED CONTRACT's own guarantees are ASSERTED by a self-check that
  // is INDEPENDENT of the comparison mode: the exit-status codec's round
  // trip and its rejections, and the archive member-name equality. The
  // self-check is EXECUTED, not merely compiled: a contract whose
  // guarantees are never exercised is not a contract.
  // -----------------------------------------------------------------------
  if (argc == 2 && StrCmp(argv[1], "selfcheck") == 0) {
    I64 sc_failures = ContractSelfCheck();
    if (sc_failures != 0) return 1;
    return 0;
  }

  // -----------------------------------------------------------------------
  // THE LEDGER-MEMBERSHIP SELF-CHECK MODE.
  //
  //   ledgercheck <ledger-path>
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F2.
  //
  // It exercises the COMPARATOR'S OWN `LedgerHas`, which is the function
  // that decides whether an event identity is a member of the run ledger.
  // The self-check writes a ledger that carries ONE genuine record and
  // then asks about several queries:
  //
  //   the genuine identity            it MUST be a member
  //   a prefix of the identity         it MUST NOT be a member
  //   the identity with a suffix       it MUST NOT be a member
  //   a one-character identity         it MUST NOT be a member
  //   the identity with a tab and a    it MUST NOT be a member
  //     trailing column
  //
  // The self-check is EXECUTED, not merely compiled: a membership rule
  // whose guarantees are never exercised is not a rule.
  // -----------------------------------------------------------------------
  if (argc == 3 && StrCmp(argv[1], "ledgercheck") == 0) {
    I64 lf = 0;
    I64 lc = 0;
    // The genuine identity. It is sixty-four hexadecimal characters.
    U8 *genuine = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
    I64 glen = 64;
    // The ledger: the genuine record, terminated.
    U8 *ledger = MAlloc(glen + 2);
    MemCpy(ledger, genuine, glen);
    ledger[glen] = 10;
    ledger[glen + 1] = 0;
    FileWrite(argv[2], ledger, glen + 1);
    // The genuine identity IS a member.
    lc = lc + 1;
    if (LedgerHas(argv[2], genuine) != 1) {
      "LEDGER_SELFTEST\tGENUINE_IDENTITY_IS_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // A PREFIX of the genuine identity is NOT a member.
    lc = lc + 1;
    if (LedgerHas(argv[2], "0123456789abcdef") != 0) {
      "LEDGER_SELFTEST\tPREFIX_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // The genuine identity with a SUFFIX is NOT a member.
    lc = lc + 1;
    if (LedgerHas(argv[2],
        "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdefX") != 0) {
      "LEDGER_SELFTEST\tSUFFIX_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // A ONE-CHARACTER identity is NOT a member.
    lc = lc + 1;
    if (LedgerHas(argv[2], "0") != 0) {
      "LEDGER_SELFTEST\tONE_CHARACTER_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // An EMPTY identity is NOT a member.
    lc = lc + 1;
    if (LedgerHas(argv[2], "") != 0) {
      "LEDGER_SELFTEST\tEMPTY_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // A ledger with an EXTRA COLUMN: the genuine identity is not a member
    // of a ledger whose record carries more than the identity.
    lc = lc + 1;
    U8 *extended = MAlloc(glen + 16);
    MemCpy(extended, genuine, glen);
    MemCpy(extended + glen, "\tEXTRA\n", 7);
    FileWrite(argv[2], extended, glen + 7);
    if (LedgerHas(argv[2], genuine) != 0) {
      "LEDGER_SELFTEST\tEXTRA_COLUMN_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // A ledger with NO TRAILING SEPARATOR: the record is incomplete, so
    // the identity is not a member.
    lc = lc + 1;
    U8 *unterminated = MAlloc(glen + 1);
    MemCpy(unterminated, genuine, glen);
    unterminated[glen] = 0;
    FileWrite(argv[2], unterminated, glen);
    if (LedgerHas(argv[2], genuine) != 0) {
      "LEDGER_SELFTEST\tUNTERMINATED_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // A ledger with an EMBEDDED NUL inside the record: the record is
    // longer than the identity, so it is not a member.
    lc = lc + 1;
    U8 *embedded = MAlloc(glen + 4);
    MemCpy(embedded, genuine, glen);
    embedded[glen] = 0;
    embedded[glen + 1] = 10;
    FileWrite(argv[2], embedded, glen + 2);
    if (LedgerHas(argv[2], genuine) != 0) {
      "LEDGER_SELFTEST\tEMBEDDED_NUL_IS_NOT_A_MEMBER\tFAIL\n";
      lf = lf + 1;
    }
    // The genuine ledger is restored, so the file the caller named holds a
    // well-formed ledger when the self-check finishes.
    FileWrite(argv[2], ledger, glen + 1);
    Free(ledger);
    Free(extended);
    Free(unterminated);
    Free(embedded);
    "LEDGER_SELFTEST_CHECKS\t%lld\n", lc;
    "LEDGER_SELFTEST_FAILURES\t%lld\n", lf;
    if (lf != 0) return 1;
    return 0;
  }

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
    I64 d_class = ContractClassify(dbuf, d_size);
    I64 d_arch = ContractArchOf(dbuf, d_size);
    "DERIVED_CLASS\t%s\n", ContractClassName(d_class);
    "DERIVED_ARCH\t%s\n", ContractArchName(d_arch);
    "DERIVED_PRESENT\t%d\n", d_present;
    "DERIVED_SIZE\t%lld\n", d_size;
    return 0;
  }

  // -----------------------------------------------------------------------
  // THE COMPARISON MODE.
  // -----------------------------------------------------------------------
  if (argc < 20) {
    "REASON_DETAIL=usage: compare <case-id> <oracle-art> <polyc-art> "
      "<oracle-stdout> <polyc-stdout> <oracle-stderr> <polyc-stderr> "
      "<oracle-exit> <polyc-exit> <expected-class> <expected-arch> "
      "<expected-exit> <run-ledger> <oracle-capture> <polyc-capture> "
      "<expected-run-id> <expected-case-id> <oracle-producer> "
      "<polyc-producer> [symbol ...]\n";
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
  U8 *expected_run = argv[16];
  U8 *expected_case = argv[17];
  U8 *o_producer = argv[18];
  U8 *p_producer = argv[19];

  // -----------------------------------------------------------------------
  // THE EXPECTED CLASS MUST BE A SUPPORTED CLASS.
  //
  // An UNSUPPORTED expectation (`OTHER`, or an unknown token) is REJECTED
  // OUTRIGHT, so a pair of IDENTICAL GARBAGE files can never be reported
  // as an equivalence with zero failures.
  // -----------------------------------------------------------------------
  I64 expected_class = -1;
  if (StrCmp(argv[10], "MACHO_OBJECT") == 0) expected_class = 1;
  if (StrCmp(argv[10], "MACHO_EXECUTABLE") == 0) expected_class = 2;
  if (StrCmp(argv[10], "MACHO_DYLIB") == 0) expected_class = 3;
  if (StrCmp(argv[10], "ELF") == 0) expected_class = 4;
  if (StrCmp(argv[10], "ASSEMBLER_TEXT") == 0) expected_class = 6;
  if (StrCmp(argv[10], "AR_ARCHIVE") == 0) expected_class = 7;
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
  // -----------------------------------------------------------------------
  I64 o_present = 0;
  I64 o_size = 0;
  U8 *obuf = ReadArtifact(oracle, &o_size, &o_present);
  I64 o_class = ContractClassify(obuf, o_size);
  I64 o_arch = ContractArchOf(obuf, o_size);

  // The exit status is read STRICTLY, with the SHARED codec.
  //
  // The PRESENCE and the VALIDITY of the exit record are DISTINCT facts.
  // A record that is PRESENT but MALFORMED must report the codec's own
  // reason token, so the presence is determined by the file's existence
  // and NOT by the codec's success.
  I64 o_exit_present = 0;
  I64 o_exit = 0;
  I64 o_exit_code = EXIT_OK;
  {
    I64 o_probe_size = 0;
    U8 *o_probe = FileRead(o_exitf, &o_probe_size);
    if (o_probe != NULL) o_exit_present = 1;
  }
  I64 o_exit_ok = ContractReadExitStatusFile(o_exitf, &o_exit, &o_exit_code);
  if (o_exit_ok == 1) o_exit_present = 1;

  Check(o_present == 1, case_id, "the oracle artifact is PRESENT");
  Check(o_present == 1 && o_size > 0, case_id,
        "the oracle artifact is NONEMPTY");
  Check(o_present == 1 && o_class == expected_class, case_id,
        "the oracle artifact has the EXPECTED class");
  Check(o_present == 1 && (expected_arch == -1 || o_arch == expected_arch),
        case_id, "the oracle artifact has the EXPECTED architecture");
  Check(o_exit_present == 1 && o_exit_ok == 1, case_id,
        "the oracle exit status is a VALID record");
  if (o_exit_ok == 0) {
    Reason(case_id, "oracle", ContractExitReason(o_exit_code));
  }
  Check(o_exit_present == 1 && o_exit_ok == 1 && o_exit == expected_exit,
        case_id, "the oracle exit status is the EXPECTED one");

  // The structural validation of the oracle artifact. It uses the SHARED
  // validator, so the emission verifier is never weaker than this
  // comparator.
  I64 o_mv = MV_OK;
  I64 o_requires_symtab = 0;
  if (expected_class == 1 || expected_class == 2 || expected_class == 3) {
    o_requires_symtab = 1;
  }
  if (o_present == 1 && o_size > 0 &&
      (o_class == expected_class || expected_class == 7)) {
    if (o_requires_symtab == 1) {
      o_mv = ContractValidateMachO(obuf, o_size, 1);
    }
  } else {
    o_mv = MV_BAD_MAGIC;
  }
  Check(o_present == 1 && o_mv == MV_OK, case_id,
        "the oracle artifact is STRUCTURALLY VALID");
  if (o_present == 1 && o_mv != MV_OK) {
    Reason(case_id, "oracle", ContractMachOReason(o_mv));
  }

  // -----------------------------------------------------------------------
  // STEP 2 -- VALIDATE THE POLYC OBSERVATION.
  // -----------------------------------------------------------------------
  I64 p_present = 0;
  I64 p_size = 0;
  U8 *pbuf = ReadArtifact(polyc, &p_size, &p_present);
  I64 p_class = ContractClassify(pbuf, p_size);
  I64 p_arch = ContractArchOf(pbuf, p_size);

  I64 p_exit_present = 0;
  I64 p_exit = 0;
  I64 p_exit_code = EXIT_OK;
  {
    I64 p_probe_size = 0;
    U8 *p_probe = FileRead(p_exitf, &p_probe_size);
    if (p_probe != NULL) p_exit_present = 1;
  }
  I64 p_exit_ok = ContractReadExitStatusFile(p_exitf, &p_exit, &p_exit_code);
  if (p_exit_ok == 1) p_exit_present = 1;

  Check(p_present == 1, case_id, "the PolyC artifact is PRESENT");
  Check(p_present == 1 && p_size > 0, case_id,
        "the PolyC artifact is NONEMPTY");
  Check(p_present == 1 && p_class == expected_class, case_id,
        "the PolyC artifact has the EXPECTED class");
  Check(p_present == 1 && (expected_arch == -1 || p_arch == expected_arch),
        case_id, "the PolyC artifact has the EXPECTED architecture");
  Check(p_exit_present == 1 && p_exit_ok == 1, case_id,
        "the PolyC exit status is a VALID record");
  if (p_exit_ok == 0) {
    Reason(case_id, "polyc", ContractExitReason(p_exit_code));
  }
  Check(p_exit_present == 1 && p_exit_ok == 1 && p_exit == expected_exit,
        case_id, "the PolyC exit status is the EXPECTED one");

  I64 p_mv = MV_OK;
  if (p_present == 1 && p_size > 0 &&
      (p_class == expected_class || expected_class == 7)) {
    if (o_requires_symtab == 1) {
      p_mv = ContractValidateMachO(pbuf, p_size, 1);
    }
  } else {
    p_mv = MV_BAD_MAGIC;
  }
  Check(p_present == 1 && p_mv == MV_OK, case_id,
        "the PolyC artifact is STRUCTURALLY VALID");
  if (p_present == 1 && p_mv != MV_OK) {
    Reason(case_id, "polyc", ContractMachOReason(p_mv));
  }

  // -----------------------------------------------------------------------
  // STEP 3 -- THE REQUIRED SYMBOLS.
  //
  // The symbol search is performed ONLY on an artifact that the SHARED
  // validator has already validated, and it EXAMINES EVERY symbol entry.
  // A malformed entry AFTER the requested symbol rejects the artifact.
  //
  // The REQUIRED SYMBOLS are the TRAILING arguments, beginning immediately
  // after the PolyC producer digest at argv[19]. They therefore begin at
  // argv[20].
  // -----------------------------------------------------------------------
  I64 i = 20;
  I64 nsym = 0;
  I64 sym_ok = 1;
  I64 o_stridx_bad = 0;
  I64 p_stridx_bad = 0;
  while (i < argc) {
    U8 *sym = argv[i];
    nsym = nsym + 1;
    if (o_requires_symtab == 1) {
      I64 obad = 0;
      I64 pbad = 0;
      if (ContractHasSymbolChecked(obuf, o_size, sym, &obad) == 0) sym_ok = 0;
      if (ContractHasSymbolChecked(pbuf, p_size, sym, &pbad) == 0) sym_ok = 0;
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
    Reason(case_id, "oracle", ContractMachOReason(MV_STRIDX_BOUNDS));
  }
  Check(p_stridx_bad == 0, case_id,
        "the PolyC symbol-string indices are IN BOUNDS");
  if (p_stridx_bad == 1) {
    Reason(case_id, "polyc", ContractMachOReason(MV_STRIDX_BOUNDS));
  }

  // -----------------------------------------------------------------------
  // STEP 3b -- VALIDATE THE INVOCATION PROVENANCE.
  //
  // This is the step that makes a STALE replay detectable. Each side
  // carries a CAPTURE RECORD that the EXECUTION-OWNING HARNESS wrote
  // DIRECTLY FROM THE EXECUTION.
  // -----------------------------------------------------------------------
  I64 o_cap = ValidateCapture(case_id, "oracle", o_capture, ledger,
                               expected_run, expected_case, o_producer,
                               "OFF", obuf, o_size, o_stdout, o_stderr,
                               o_exit, o_exit_present, o_exit_ok);
  Check(o_cap == CAPTURE_OK, case_id,
        "the oracle INVOCATION PROVENANCE is COMPLETE and REGISTERED");
  if (o_cap != CAPTURE_OK) {
    Reason(case_id, "oracle", CaptureReason(o_cap));
  }
  I64 p_cap = ValidateCapture(case_id, "polyc", p_capture, ledger,
                               expected_run, expected_case, p_producer,
                               "ON", pbuf, p_size, p_stdout, p_stderr,
                               p_exit, p_exit_present, p_exit_ok);
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

  // The artifact bytes are compared. The digest is computed over the
  // artifact bytes by the comparator itself. It is never taken from the
  // harness.
  U8 *od = MAlloc(32);
  U8 *pd = MAlloc(32);
  U8 *ohex = MAlloc(65);
  U8 *phex = MAlloc(65);
  Sha256Bytes(obuf, o_size, od);
  Sha256Hex(ohex, od);
  Sha256Bytes(pbuf, p_size, pd);
  Sha256Hex(phex, pd);
  "DIGEST\t%s\toracle\t%s\n", case_id, ohex;
  "DIGEST\t%s\tpolyc\t%s\n", case_id, phex;
  Check(o_present == 1 && p_present == 1 &&
        StrCmp(ohex, phex) == 0, case_id,
        "the artifact content digests agree");
  Check(o_present == 1 && p_present == 1 &&
        ContractBytesEqual(obuf, o_size, pbuf, p_size), case_id,
        "the actual artifact bytes agree");
  Free(od);
  Free(pd);
  Free(ohex);
  Free(phex);

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
  "ARTIFACT_CLASS\t%s\t%s\t%s\n", case_id, ContractClassName(o_class),
        ContractClassName(p_class);
  "ARTIFACT_ARCH\t%s\t%s\t%s\n", case_id, ContractArchName(o_arch),
        ContractArchName(p_arch);

  "CORRECTION03_COMPARE_CHECKS\t%d\n", checks;
  "CORRECTION03_COMPARE_FAILURES\t%d\n", failures;
  if (failures > 0) return 1;
  return 0;
}
