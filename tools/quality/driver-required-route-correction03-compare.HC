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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// CAPTURE_EVENT_ID_MISMATCH -- the record's EVENT_ID is not the identity
// that its OWN CONTENTS imply. The ledger membership check alone cannot
// reject a FORGED record: a record whose contents were altered after the
// event was registered keeps the registered EVENT_ID, so it satisfies the
// ledger check while describing an execution that did not happen. The
// comparator therefore RECOMPUTES the identity from the record's own
// fields and requires the two to agree.
#define CAPTURE_EVENT_ID_MISMATCH  14
// CAPTURE_DUPLICATE_EVENT -- the record's EVENT_ID is registered in the
// ledger MORE THAN ONCE. Two events in one run cannot share one identity,
// so a duplicate means the ledger was written twice from one execution, or
// that one event was replayed as two.
#define CAPTURE_DUPLICATE_EVENT    15
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-01.
//
// CAPTURE_BLOCK_TOO_LARGE -- the record's ARGV or ENV block carries more
// entries than the DOCUMENTED LIMIT. The block is refused rather than
// truncated, because a truncated block would silently describe a
// different execution.
#define CAPTURE_BLOCK_TOO_LARGE   16
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
// R5-06 -- THE BLOCK-STATUS REASON CODES.
//
// The comparator's own reason codes for the five block findings. They are
// DISTINCT codes, so a reviewer can tell WHICH finding the record
// carries. The ACCEPTANCE BEHAVIOUR is unchanged: every one of them is a
// refusal, and only the REASON TOKEN is now precise.
#define CAPTURE_BLOCK_ABSENT_C   17
#define CAPTURE_BLOCK_EMPTY_C    18
#define CAPTURE_BLOCK_SCALAR_C   19
#define CAPTURE_BLOCK_MALFORMED_C 20
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-03 -- THE COMPILED-SNAPSHOT IDENTITY REASON CODES.
//
// The comparator must validate the COMPILED snapshot's identity
// INDEPENDENTLY: it re-reads the staged file, hashes the ACTUAL bytes,
// and compares the result with the digest the record claims. It never
// accepts a supplied digest string as proof.
//
//   CAPTURE_COMPILED_SOURCE_MISSING  the record does not name the staged
//                                     snapshot at all
//   CAPTURE_COMPILED_SOURCE_ABSENT   the named staged snapshot does not
//                                     exist on the disk
//   CAPTURE_COMPILED_SOURCE_MISMATCH  the staged snapshot's ACTUAL digest
//                                     differs from the recorded one
#define CAPTURE_COMPILED_SOURCE_MISSING 21
#define CAPTURE_COMPILED_SOURCE_ABSENT  22
#define CAPTURE_COMPILED_SOURCE_MISMATCH 23

// The block-status to reason-code mapping. It is the ONE place where the
// shared contract's block statuses are turned into the comparator's own
// reason codes, so the two cannot drift apart.
static I64 CaptureBlockReasonCode(I64 status) {
  if (status == CAPTURE_BLOCK_ABSENT) return CAPTURE_BLOCK_ABSENT_C;
  if (status == CAPTURE_BLOCK_EMPTY) return CAPTURE_BLOCK_EMPTY_C;
  if (status == CAPTURE_BLOCK_SCALAR) return CAPTURE_BLOCK_SCALAR_C;
  if (status == CAPTURE_BLOCK_MALFORMED) return CAPTURE_BLOCK_MALFORMED_C;
  return CAPTURE_BLOCK_TOO_LARGE;
}

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
  if (code == CAPTURE_EVENT_ID_MISMATCH) return "CAPTURE_EVENT_ID_MISMATCH";
  if (code == CAPTURE_DUPLICATE_EVENT) return "CAPTURE_DUPLICATE_EVENT_ID";
  if (code == CAPTURE_BLOCK_TOO_LARGE) return "CAPTURE_BLOCK_TOO_LARGE";
  if (code == CAPTURE_BLOCK_ABSENT_C) return "CAPTURE_BLOCK_ABSENT";
  if (code == CAPTURE_BLOCK_EMPTY_C) return "CAPTURE_BLOCK_EMPTY";
  if (code == CAPTURE_BLOCK_SCALAR_C) return "CAPTURE_BLOCK_SCALAR";
  if (code == CAPTURE_BLOCK_MALFORMED_C) return "CAPTURE_BLOCK_MALFORMED";
  if (code == CAPTURE_COMPILED_SOURCE_MISSING) return "CAPTURE_COMPILED_SOURCE_MISSING";
  if (code == CAPTURE_COMPILED_SOURCE_ABSENT) return "CAPTURE_COMPILED_SOURCE_ABSENT";
  if (code == CAPTURE_COMPILED_SOURCE_MISMATCH) return "CAPTURE_COMPILED_SOURCE_MISMATCH";
  return "CAPTURE_UNKNOWN";
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

// The EVENT IDENTITY RECOMPUTATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// THE DEFECT. The comparator checked that the record's EVENT_ID was
// REGISTERED in the run ledger, and it checked that the record's digests
// matched the observed bytes. It never checked that the EVENT_ID was the
// identity that the record's OWN CONTENTS imply.
//
// A FORGED record therefore passed: take a genuine capture record, change
// its contents, and leave its EVENT_ID alone. The digests still match the
// forged bytes, and the EVENT_ID is still in the ledger -- because it is
// the genuine event's identity. The ledger check cannot see the forgery,
// because it never looks at the record's contents.
//
// THE REPAIR. The comparator RECOMPUTES the event identity from the
// record's own fields, using the SAME construction the runner used, and
// requires the two to agree. A forged record now fails, because its
// contents imply an identity that is not the one it carries.
//
// The construction is the runner's, byte for byte:
//
//   SHA-256 over
//     the run id,
//     the event counter as a DECIMAL field,
//     the case identity,
//     the selector,
//     the producer digest,
//     the source digest,
//     the fixture digest,
//     the argument vector, one element per line,
//     the environment, one element per line.
//
// Every field after the run id is terminated by the record separator, so
// the field boundaries are unambiguous. The run id is a fixed sixty-four
// character digest, so it needs no terminator of its own.
//
// The recomputation is INDEPENDENT of the harness: the comparator has its
// own copy of the construction, so a defect in the harness's copy cannot
// make a forged record pass.
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-05.
//
// THE RECOMPUTATION USES THE SHARED CONTRACT'S CANONICAL ENCODING.
//
// THE ORIGINAL DEFECT. The comparator's own copy of the construction
// CONCATENATED the argument vector and the environment with a single
// record separator. That encoding has no UNAMBIGUOUS field boundary, so
// the same byte stream could be produced by more than one (ARGV, ENV)
// pair. The concrete attack: move the last ARGV element into the ENV
// block and the identity is UNCHANGED, so the record still satisfies the
// recomputation while describing an execution that did not happen.
//
// THE REPAIR. Both the producer and the comparator call the shared
// contract's `ContractEventId`. There is ONE specified encoding, and it
// is unambiguous: every field and every element carries an explicit
// length.
//
// The recomputation remains INDEPENDENT in the sense that matters: it is
// computed from the record's OWN fields, not from anything the producer
// said about the record.
static U8 *RecomputeEventId(EventIdCtx *ctx, EventIdEnvCtx *env) {
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-05.
  //
  // THE PARAMETER LIST OF THIS FUNCTION IS TWO.
  //
  // The production compiler's calling convention does not agree with
  // itself about a POINTER-TO-POINTER argument at parameter position
  // EIGHT or later: the call site places it on the STACK while the
  // callee's prologue reads it from a REGISTER, and the arguments that
  // follow are shifted. The reason is recorded in the shared contract.
  //
  // The recomputation therefore takes the shared contract's contexts, and
  // the caller fills them BY NAME.
  return ContractEventIdWithEnv(ctx, env);
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
  U8 *counter_field = CaptureField(buf, size, "EVENT_COUNTER");
  U8 *env_applied = CaptureField(buf, size, "ENV_APPLIED");
  U8 *producer_arch = CaptureField(buf, size, "PRODUCER_ARCH");
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE COMPILED SNAPSHOT'S IDENTITY.
  //
  // The record must name the staged snapshot and its digest. The
  // comparator then RE-READS that file and hashes the ACTUAL bytes.
  U8 *compiled_source_sha = CaptureField(buf, size, "COMPILED_SOURCE_SHA256");
  U8 *compiled_source_path = CaptureField(buf, size, "STAGED_SOURCE");
  U8 *original_equals = CaptureField(buf, size, "ORIGINAL_EQUALS_COMPILED");

  if (run_id == NULL || event_id == NULL || case_field == NULL ||
      selector == NULL || producer_sha == NULL || source_sha == NULL ||
      fixture_sha == NULL || stdout_sha == NULL || stderr_sha == NULL ||
      artifact_sha == NULL || artifact_present == NULL ||
      exit_field == NULL || argv_field == NULL || env_field == NULL) {
    return CAPTURE_FIELD_MISSING;
  }
  // The COMPILED snapshot's identity is MANDATORY. A record that does not
  // name it cannot be checked against the bytes the compilation used.
  if (compiled_source_sha == NULL || compiled_source_path == NULL) {
    return CAPTURE_COMPILED_SOURCE_MISSING;
  }
  // The INDEPENDENT VALIDATION OF THE COMPILED SNAPSHOT.
  //
  // The comparator does NOT accept the recorded digest as proof. It
  // RE-READS the staged file, hashes the ACTUAL bytes, and compares the
  // result with the recorded digest. A record that names a staged source
  // which does not exist, or whose bytes differ from the recorded digest,
  // is REFUSED.
  //
  // This is the check that the reviewer's counterexample defeated: the
  // record authenticated the ORIGINAL source's digest, and the staged
  // snapshot -- the file the compiler actually consumed -- was never
  // validated at all.
  U8 *actual_compiled_hex = MAlloc(65);
  I64 compiled_present = 0;
  if (Sha256File(compiled_source_path, actual_compiled_hex) == 1) {
    compiled_present = 1;
  }
  if (compiled_present == 0) {
    Free(actual_compiled_hex);
    return CAPTURE_COMPILED_SOURCE_ABSENT;
  }
  I64 compiled_same = 0;
  if (StrCmp(actual_compiled_hex, compiled_source_sha) == 0) compiled_same = 1;
  Free(actual_compiled_hex);
  if (compiled_same == 0) return CAPTURE_COMPILED_SOURCE_MISMATCH;
  // The ORIGINAL-VERSUS-COMPILED equality, when the record states it, is
  // checked against the digests the record itself carries. A record that
  // claims the two are equal while their digests differ is REFUSED.
  if (original_equals != NULL) {
    if (StrCmp(original_equals, "1") == 0) {
      if (StrCmp(source_sha, compiled_source_sha) != 0) {
        return CAPTURE_COMPILED_SOURCE_MISMATCH;
      }
    }
  }

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // The EVENT COUNTER and the ENVIRONMENT-APPLIED marker are REQUIRED. The
  // counter is what makes two identical executions distinguishable, and
  // the marker says that the environment the record names was actually in
  // force. A record without them cannot be checked against its own
  // contents, so it is refused.
  if (counter_field == NULL) return CAPTURE_FIELD_MISSING;
  if (env_applied == NULL) return CAPTURE_FIELD_MISSING;
  if (StrCmp(env_applied, "1") != 0) return CAPTURE_ENV_EMPTY;
  if (producer_arch == NULL) return CAPTURE_FIELD_MISSING;

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

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // The event must be registered EXACTLY ONCE. Two executions in one run
  // cannot share one identity, because the identity carries the run id and
  // the monotonic event counter.
  if (LedgerCount(ledger_path, event_id) != 1) {
    return CAPTURE_DUPLICATE_EVENT;
  }

  // THE EVENT IDENTITY MUST BE THE IDENTITY ITS OWN CONTENTS IMPLY.
  //
  // The membership check above cannot see a FORGED record: a record whose
  // contents were changed after the event was registered keeps the
  // REGISTERED identity, so it satisfies the membership check while
  // describing an execution that did not happen. The comparator therefore
  // RECOMPUTES the identity from the record's own fields and requires the
  // two to agree.
  I64 nargv = 0;
  I64 nenv = 0;
  I64 argv_status = CAPTURE_BLOCK_ABSENT;
  I64 env_status = CAPTURE_BLOCK_ABSENT;
  U8 **argv_values = CaptureBlock(buf, size, "ARGV", &nargv, &argv_status);
  U8 **env_values = CaptureBlock(buf, size, "ENV", &nenv, &env_status);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-06 -- THE BLOCK STATUS IS REPORTED AS ITSELF.
  //
  // The previous revision reported EVERY block failure as
  // `CAPTURE_BLOCK_TOO_LARGE`, so an ABSENT block, an EMPTY block and a
  // SCALAR field in place of a block were all reported as an oversized
  // block. The DISTINCTION matters: the five findings have five
  // DIFFERENT remedies, and a reviewer reading the reason token was told
  // the wrong one.
  //
  // The ACCEPTANCE BEHAVIOUR IS NOT CHANGED. Every block failure was
  // already REFUSED, and every block failure is STILL REFUSED; only the
  // REASON TOKEN is now precise.
  if (argv_status != CAPTURE_BLOCK_OK) {
    return CaptureBlockReasonCode(argv_status);
  }
  if (env_status != CAPTURE_BLOCK_OK) {
    return CaptureBlockReasonCode(env_status);
  }
  // The recomputation contexts are filled BY NAME, so that no argument
  // can be shifted by the production compiler's calling convention.
  EventIdCtx rc_ctx;
  rc_ctx.run_id = run_id;
  rc_ctx.counter = counter_field;
  rc_ctx.case_id = case_field;
  rc_ctx.selector = selector;
  rc_ctx.producer_hex = producer_sha;
  rc_ctx.source_hex = source_sha;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE RECOMPUTATION INCLUDES THE COMPILED SOURCE'S IDENTITY.
  //
  // The identity binds BOTH digests, so the recomputation must supply
  // BOTH. The compiled digest is the one that was VALIDATED against the
  // actual staged bytes above.
  rc_ctx.compiled_source_hex = compiled_source_sha;
  rc_ctx.fixture_hex = fixture_sha;
  rc_ctx.argv = argv_values;
  rc_ctx.nargv = nargv;
  rc_ctx.envv = NULL;
  rc_ctx.nenv = 0;
  EventIdEnvCtx rc_env;
  rc_env.envv = env_values;
  rc_env.nenv = nenv;
  U8 *recomputed = RecomputeEventId(&rc_ctx, &rc_env);
  I64 same = 0;
  if (StrLen(event_id) == 64 && StrCmp(event_id, recomputed) == 0) same = 1;
  if (same == 0) return CAPTURE_EVENT_ID_MISMATCH;

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
// The EVENT-IDENTITY RECOMPUTATION DIAGNOSTIC.
//
// It reads the capture record, recomputes the event identity from the
// record's OWN fields, and prints the recorded identity and the
// recomputed one. The diagnostic exists so that a reviewer can see WHICH
// side of the comparison differs, without reading the comparator's source.
// It performs NO acceptance decision: it prints and returns.
//
// It is a SEPARATE function because a large frame in `Main` overflows the
// runtime's process stack on this host.
static I32 RecomputeDiagnostic(U8 *path) {
  I64 rsize = 0;
  U8 *rbuf = FileRead(path, &rsize);
  if (rbuf == NULL) {
    "RECOMPUTE\tCAPTURE_RECORD_MISSING\n";
    return 1;
  }
  U8 *r_run = CaptureField(rbuf, rsize, "RUN_ID");
  U8 *r_event = CaptureField(rbuf, rsize, "EVENT_ID");
  U8 *r_counter = CaptureField(rbuf, rsize, "EVENT_COUNTER");
  U8 *r_case = CaptureField(rbuf, rsize, "CASE_ID");
  U8 *r_sel = CaptureField(rbuf, rsize, "SELECTOR");
  U8 *r_prod = CaptureField(rbuf, rsize, "PRODUCER_SHA256");
  U8 *r_src = CaptureField(rbuf, rsize, "SOURCE_SHA256");
  U8 *r_compiled = CaptureField(rbuf, rsize, "COMPILED_SOURCE_SHA256");
  U8 *r_compiled_path = CaptureField(rbuf, rsize, "STAGED_SOURCE");
  U8 *r_fix = CaptureField(rbuf, rsize, "FIXTURE_SHA256");
  I64 rnargv = 0;
  I64 rnenv = 0;
  I64 rargv_status = CAPTURE_BLOCK_ABSENT;
  I64 renv_status = CAPTURE_BLOCK_ABSENT;
  U8 **rargv = CaptureBlock(rbuf, rsize, "ARGV", &rnargv, &rargv_status);
  U8 **renv = CaptureBlock(rbuf, rsize, "ENV", &rnenv, &renv_status);
  "RECOMPUTE\tRECORDED\t%s\n", r_event;
  "RECOMPUTE\tRUN_ID\t%s\n", r_run;
  "RECOMPUTE\tCOUNTER\t%s\n", r_counter;
  "RECOMPUTE\tCASE\t%s\n", r_case;
  "RECOMPUTE\tSELECTOR\t%s\n", r_sel;
  "RECOMPUTE\tPRODUCER\t%s\n", r_prod;
  "RECOMPUTE\tSOURCE\t%s\n", r_src;
  "RECOMPUTE\tCOMPILED_SOURCE\t%s\n", r_compiled;
  "RECOMPUTE\tCOMPILED_SOURCE_PATH\t%s\n", r_compiled_path;
  "RECOMPUTE\tFIXTURE\t%s\n", r_fix;
  "RECOMPUTE\tNARGV\t%lld\n", rnargv;
  "RECOMPUTE\tNENV\t%lld\n", rnenv;
  I64 k = 0;
  while (k < rnargv) {
    "RECOMPUTE\tARGV_%lld\t%s\n", k, rargv[k];
    k = k + 1;
  }
  k = 0;
  while (k < rnenv) {
    "RECOMPUTE\tENV_%lld\t%s\n", k, renv[k];
    k = k + 1;
  }
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-06 -- THE DIAGNOSTIC DOES NOT CLAIM A RECOMPUTATION IT DID NOT
  // PERFORM.
  //
  // The previous revision ALWAYS printed a `RECOMPUTED` line, even when
  // the record's ARGV or ENV block was absent, empty or malformed. A
  // recomputation over an ABSENT block is not a recomputation at all: the
  // identity cannot be reconstructed, and a digest printed in its place
  // would be a digest of a record that was never observed.
  //
  // The diagnostic therefore REPORTS THE BLOCK STATUS and does NOT print
  // a `RECOMPUTED` line when a mandatory input is missing. This is a
  // DIAGNOSTIC-PRECISION change; the comparator's ACCEPTANCE behaviour is
  // unchanged.
  I64 argv_ok = 0;
  if (rargv_status == CAPTURE_BLOCK_OK) argv_ok = 1;
  I64 env_ok = 0;
  if (renv_status == CAPTURE_BLOCK_OK) env_ok = 1;
  I64 fields_ok = 0;
  if (r_run != NULL && r_counter != NULL && r_case != NULL && r_sel != NULL &&
      r_prod != NULL && r_src != NULL && r_fix != NULL && r_event != NULL &&
      r_compiled != NULL) {
    fields_ok = 1;
  }
  "RECOMPUTE\tARGV_STATUS\t%s\n", CaptureBlockReason(rargv_status);
  "RECOMPUTE\tENV_STATUS\t%s\n", CaptureBlockReason(renv_status);
  if (argv_ok == 0 || env_ok == 0 || fields_ok == 0) {
    "RECOMPUTE\tRECOMPUTED\tNOT_COMPUTED\n";
    "RECOMPUTE\tREASON\tA_MANDATORY_INPUT_IS_ABSENT\n";
    return 0;
  }
  EventIdCtx dc_ctx;
  dc_ctx.run_id = r_run;
  dc_ctx.counter = r_counter;
  dc_ctx.case_id = r_case;
  dc_ctx.selector = r_sel;
  dc_ctx.producer_hex = r_prod;
  dc_ctx.source_hex = r_src;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE DIAGNOSTIC RECOMPUTES OVER THE COMPILED SOURCE TOO.
  dc_ctx.compiled_source_hex = r_compiled;
  dc_ctx.fixture_hex = r_fix;
  dc_ctx.argv = rargv;
  dc_ctx.nargv = rnargv;
  dc_ctx.envv = NULL;
  dc_ctx.nenv = 0;
  EventIdEnvCtx dc_env;
  dc_env.envv = renv;
  dc_env.nenv = rnenv;
  U8 *rc = RecomputeEventId(&dc_ctx, &dc_env);
  "RECOMPUTE\tRECOMPUTED\t%s\n", rc;
  return 0;
}

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
  // ---------------------------------------------------------------------------
  // THE EVENT-IDENTITY RECOMPUTATION DIAGNOSTIC.
  //
  //   recompute <capture-path>
  //
  // It reads the capture record, recomputes the event identity from the
  // record's OWN fields, and prints the recorded identity and the
  // recomputed one. The diagnostic exists so that a reviewer can see WHICH
  // side of the comparison differs, without reading the comparator's
  // source. It performs NO acceptance decision: it prints and returns.
  // -----------------------------------------------------------------------
  if (argc == 3 && StrCmp(argv[1], "recompute") == 0) {
    return RecomputeDiagnostic(argv[2]);
  }

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
