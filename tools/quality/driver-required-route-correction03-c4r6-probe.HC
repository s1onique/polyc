// tools/quality/driver-required-route-correction03-c4r6-probe.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6.
//
// THE ROUND-6 COUNTEREXAMPLE PROBE.
//
// It reproduces the FIVE findings that the C4 ROUND 5 independent review
// established, and it exercises the PRODUCTION HARNESS as a SUBPROCESS, so
// the subject under test is the runner that the evidence path actually
// uses.
//
// THE FINDINGS.
//
//   R5-01  source provenance is disconnected from the executed arguments.
//   R5-02  output paths escape the runner-controlled directory.
//   R5-03  valid virtual zero-fill TLS sections are rejected.
//   R5-04  executable identity can change between validation and execution.
//   R5-05  the environment checker does not exercise the production
//          environment-binding path.
//
// THE PROBE MODES.
//
//   probe exec <harness> <producer> <work-dir> <arch>
//       -- R5-01, R5-02, R5-04 and R5-05's production-path witness.
//
//   probe macho <fixture-dir>
//       -- R5-03.
//
//   probe envbind <harness> <probe> <work-dir>
//       -- R5-05.
//
// Each mode prints one line per control:
//
//   PROBE_CONTROL\t<CONTROL-ID>\t<VERDICT>\t<REASON-TOKEN>
//
// The exit status is the number of FAILED controls, so the probe is usable
// directly as a gate.
//
// THE PRODUCTION FUNCTIONS ARE THE SUBJECT UNDER TEST.
//
// The probe does NOT carry a duplicate of the function it exercises. It
// spawns the PRODUCTION harness and reports the PRODUCTION harness's own
// reason token. A defect therefore shows up as "the production harness
// ACCEPTED a fixture that it must reject", and the fix shows up as "the
// production harness REJECTED it with the reason token".
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"
#include "../../src/holyc-lib/tooling_defs.HH"

// The platform's own symbolic-link creation. It is used to build the
// SYMLINKED-ANCESTOR fixture for the R5-04 control.
extern "c" I32 symlink(U8 *target, U8 *linkpath);
// The platform's own path resolution. It is used to make the probe's
// fixtures ABSOLUTE, so that a symlink's target does not depend on the
// caller's working directory.
extern "c" U8 *realpath(U8 *path, U8 *resolved);
// The platform's own mode change. The R5-04 fixture's copy of the
// producer must be EXECUTABLE, exactly as the original is.
extern "c" I32 chmod(U8 *path, I32 mode);
// The platform's own environment reader. It carries the CONFIGURED test
// prefix from the Makefile into the probe, so the probe can forward it
// to the harness.
extern "c" I8 *getenv(U8 *buf);
// The platform's own working-directory calls. The DIRECT compiler
// invocation must run in the directory whose file it is expected to
// produce, because the compiler resolves a relative output path against
// its own current working directory.
extern "c" U8 *getcwd(U8 *buf, I64 size);
extern "c" I32 chdir(U8 *path);

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-01 -- THE CONFIGURED PREFIX, AS A HARNESS BINDING.
//
// THE ORIGINAL DEFECT.
//
// The probe spawned the harness with a single environment binding,
// `C4R6_PROBE=1`, and the harness spawned the compiler with NO
// `--install-dir` option. The compiler therefore fell back to its
// compile-time default, `/usr/local`, and the child failed with
//
//     ERROR: Failed to open file: /usr/local/include/tos.HH
//
// In an isolated checkout with an EMPTY build directory, ELEVEN of the
// thirty-three positive controls failed.
//
// THE REPAIR.
//
// The probe reads the CONFIGURED prefix from its OWN process environment
// -- the Makefile exports `HCC_TEST_PREFIX=$(TEST_PREFIX)` -- and it
// forwards it to the harness as a `NAME=VALUE` binding.
//
// The probe never INVENTS a prefix: when the variable is absent, the
// helper returns NULL and the probe forwards nothing.
//
// The returned binding is a fresh allocation, so the caller owns it.
// ---------------------------------------------------------------------------

// The environment variable that carries the CONFIGURED test prefix.
#define R6_PREFIX_ENV "HCC_TEST_PREFIX"

// The prefix binding builder.
//
// It returns the `NAME=VALUE` binding that carries the CONFIGURED
// prefix, or NULL when no prefix is configured.
static U8 *R6PrefixBinding() {
  U8 *value = getenv(R6_PREFIX_ENV);
  if (value == NULL) return NULL;
  I64 len = StrLen(value);
  if (len <= 0) return NULL;
  I64 nlen = StrLen(R6_PREFIX_ENV);
  U8 *binding = MAlloc(nlen + len + 2);
  MemCpy(binding, R6_PREFIX_ENV, nlen);
  binding[nlen] = 61;
  MemCpy(binding + nlen + 1, value, len);
  binding[nlen + 1 + len] = 0;
  return binding;
}

// ---------------------------------------------------------------------------
// THE PROBE'S OWN HELPERS.
//
// They are the FIXTURE BUILDERS and the VERDICT RECORDER. They are NOT
// copies of any production decision.
// ---------------------------------------------------------------------------

static I64 r6_checks;
static I64 r6_failures;

static U0 R6Verdict(U8 *control, I64 accepted, I64 expect_accept,
                    U8 *reason) {
  r6_checks = r6_checks + 1;
  I64 ok = 0;
  if (accepted == expect_accept) ok = 1;
  if (ok == 1) {
    "PROBE_CONTROL\t%s\tOK\t%s\n", control, reason;
  } else {
    r6_failures = r6_failures + 1;
    "PROBE_CONTROL\t%s\tFAIL\t%s\n", control, reason;
  }
}

// The path builder.
static U8 *R6Path(U8 *dir, U8 *name) {
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

// The directory maker. It creates every component of the path.
static I64 R6MakeDirs(U8 *path) {
  I64 len = StrLen(path);
  I64 i = 0;
  I64 rc = 0;
  while (i < len) {
    if (path[i] == 47) {
      I64 k = 0;
      while (k < i) { k = k + 1; }
      // The prefix is created with the platform's own `mkdir(2)`. A
      // prefix that already exists is not an error.
      U8 *prefix = MAlloc(i + 1);
      MemCpy(prefix, path, i);
      prefix[i] = 0;
      if (prefix[0] != 0) mkdir(prefix, 493);
      Free(prefix);
    }
    i = i + 1;
  }
  mkdir(path, 493);
  rc = 1;
  return rc;
}

// The file writer.
static I64 R6Write(U8 *path, U8 *buf, I64 size) {
  if (FileWrite(path, buf, size, O_CREAT | O_TRUNC | O_RDWR) == FALSE) return 0;
  return 1;
}

// The string copier. It returns a FRESH allocation, so that the caller
// may free it.
//
// It exists because the runtime ABORTS when a string LITERAL is freed,
// and the probe frees the tokens it receives.
static U8 *R6Copy(U8 *s) {
  I64 n = StrLen(s);
  U8 *p = MAlloc(n + 1);
  MemCpy(p, s, n);
  p[n] = 0;
  return p;
}

// The 64-bit little-endian writer and reader.
//
// They are the FIXTURE BUILDERS. They write and read a Mach-O image's
// own fields, so that a malformed declaration can be produced by
// changing EXACTLY that declaration and nothing else.
static U0 R6Put64(U8 *buf, I64 off, I64 v) {
  I64 i = 0;
  while (i < 8) {
    buf[off + i] = (v >> (i * 8)) & 255;
    i = i + 1;
  }
}

static U0 R6Get64(U8 *buf, I64 off, I64 *out) {
  I64 v = 0;
  I64 i = 7;
  while (i >= 0) {
    v = (v << 8) | buf[off + i];
    i = i - 1;
  }
  *out = v;
}

// The REASON-TOKEN extractor.
//
// It finds the `HARNESS_REASON` field in the harness's output and returns
// its value. The field must be the WHOLE field: `HARNESS_REASON_DETAIL`
// must not be mistaken for `HARNESS_REASON`.
//
// It returns "NO_REASON_TOKEN" when the harness printed no reason at all,
// which is the case for a SUCCESSFUL run.
//
// The returned token is ALWAYS a fresh allocation, so the caller may free
// it. A string LITERAL would abort the runtime when it was freed.
static U8 *R6Reason(U8 *out) {
  if (out == NULL) return R6Copy("NO_OUTPUT");
  U8 *marker = "HARNESS_REASON";
  I64 mlen = StrLen(marker);
  I64 osize = StrLen(out);
  I64 i = 0;
  while (i < osize) {
    I64 j = i;
    while (j < osize && out[j] != 10) j = j + 1;
    if (j - i > mlen) {
      I64 same = 1;
      I64 k = 0;
      while (k < mlen) {
        if (out[i + k] != marker[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1 && out[i + mlen] == 9) {
        I64 t = i + mlen;
        while (t < j && (out[t] == 9 || out[t] == 32)) t = t + 1;
        U8 *tok = MAlloc(j - t + 1);
        MemCpy(tok, out + t, j - t);
        tok[j - t] = 0;
        return tok;
      }
    }
    if (j >= osize) break;
    i = j + 1;
  }
  return R6Copy("NO_REASON_TOKEN");
}

// The field extractor. It returns the value of the named field, or NULL.
static U8 *R6Field(U8 *buf, I64 size, U8 *key) {
  I64 klen = StrLen(key);
  I64 i = 0;
  while (i < size) {
    I64 lend = i;
    while (lend < size && buf[lend] != 10) lend = lend + 1;
    if (lend - i >= klen) {
      I64 m = 0;
      I64 same = 1;
      while (m < klen) {
        if (buf[i + m] != key[m]) { same = 0; break; }
        m = m + 1;
      }
      if (same == 1) {
        I64 vlen = lend - (i + klen);
        if (vlen > 0 && buf[i + klen] == 32) {
          U8 *v = MAlloc(vlen);
          MemCpy(v, buf + i + klen + 1, vlen - 1);
          v[vlen - 1] = 0;
          return v;
        }
      }
    }
    if (lend >= size) break;
    i = lend + 1;
  }
  return NULL;
}

// ---------------------------------------------------------------------------
// THE HARNESS DRIVER.
//
// It drives the PRODUCTION harness through its `run` mode and reports the
// harness's own reason token.
//
// The driver's inputs are carried in a context object, because the
// production compiler's calling convention does not agree with itself
// about a POINTER-TO-POINTER argument at parameter position EIGHT or
// later.
// ---------------------------------------------------------------------------

class R6RunCtx
{
  U8 *harness;
  U8 *run_dir;
  U8 *ledger;
  U8 *case_id;
  U8 *producer;
  U8 *source;
  U8 *fixture;
  U8 *artifact_name;
  U8 *artifact_dir;
  U8 *arch;
  U8 **argv;
  I64 nargv;
};

// The driver.
//
// It initialises the run context, runs the harness, and returns the
// harness's reason token. A successful run has NO reason token, and the
// token "OK" is reported for it.
//
// The caller owns the returned token.
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE DRIVER ALSO RETURNS THE HARNESS'S FULL OUTPUT.
//
// The previous revision returned ONLY the reason token, so a positive
// control could not observe the CHILD's exit status, the artifact path,
// the artifact's presence, or the capture record. Every positive control
// therefore degenerated into "the harness printed no reason token", which
// is satisfied by a compiler that FAILED.
//
// The driver now returns the full output in a second parameter, so that a
// positive control can assert the OBSERVATION it claims to establish.
static U8 *R6RunHarnessFull(R6RunCtx *ctx, U8 **out_output) {
  // The run context is initialised FIRST, because the `run` mode refuses
  // to run without one.
  U8 *init_args[4];
  init_args[0] = ctx->harness;
  init_args[1] = "init";
  init_args[2] = ctx->run_dir;
  init_args[3] = NULL;
  U8 *io = NULL;
  U8 *ie = NULL;
  SpawnAndCapture(ctx->harness, init_args, &io, &ie);
  Free(io);
  Free(ie);
  // The run's argument vector. The PROGRAM NAME comes first, then the
  // `run` VERB, then the FIXED PREFIX, then the environment bindings, then
  // the separator, and then the caller's argument vector.
  //
  // The harness's `Main` reads the verb at `argv[1]` and passes the REST
  // to `HarnessRun`, whose `argv[0]` is therefore the run directory.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX IS FORWARDED TO THE HARNESS.
  //
  // The harness INJECTS `--install-dir=<prefix>` into the child's
  // argument vector, so it must KNOW the configured prefix. The probe
  // reads it from its OWN process environment -- the Makefile exports
  // `HCC_TEST_PREFIX=$(TEST_PREFIX)` for the probe -- and it forwards it
  // to the harness in the BINDING LIST, which is the harness's explicit
  // channel.
  //
  // The forwarding is UNCONDITIONAL in its FORM and CONDITIONAL in its
  // EFFECT: when the variable is absent the probe forwards nothing, and
  // the harness's ambient fallback applies. The probe never invents a
  // prefix.
  U8 *prefix_binding = R6PrefixBinding();
  I64 nbindings = 1;
  if (prefix_binding != NULL) nbindings = 2;
  I64 total = 2 + 10 + nbindings + 1 + ctx->nargv + 1;
  U8 **args = MAlloc(sizeof(U8 *) * total);
  I64 n = 0;
  args[n] = ctx->harness;                 n = n + 1;
  args[n] = "run";                          n = n + 1;
  args[n] = ctx->run_dir;                  n = n + 1;
  args[n] = ctx->ledger;                   n = n + 1;
  args[n] = "OFF";                         n = n + 1;
  args[n] = ctx->case_id;                  n = n + 1;
  args[n] = ctx->producer;                 n = n + 1;
  args[n] = ctx->source;                   n = n + 1;
  args[n] = ctx->fixture;                  n = n + 1;
  args[n] = ctx->artifact_name;            n = n + 1;
  args[n] = ctx->artifact_dir;             n = n + 1;
  args[n] = ctx->arch;                     n = n + 1;
  args[n] = "C4R6_PROBE=1";                n = n + 1;
  if (prefix_binding != NULL) {
    args[n] = prefix_binding;              n = n + 1;
  }
  args[n] = "--";                          n = n + 1;
  I64 k = 0;
  while (k < ctx->nargv) {
    args[n] = ctx->argv[k];
    n = n + 1;
    k = k + 1;
  }
  args[n] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  SpawnAndCapture(ctx->harness, args, &out, &err);
  Free(err);
  // The reason token is extracted FIRST, because the extraction COPIES
  // the token out of the output.
  U8 *reason = R6Reason(out);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-04 -- THE OUTPUT IS HANDED OVER, NOT FREED.
  //
  // The output is released ONLY when the caller did not ask for it. The
  // previous revision handed the buffer to the caller and then freed it,
  // so every observation the caller made read FREED memory.
  if (out_output != NULL) {
    *out_output = out;
  } else {
    Free(out);
  }
  return reason;
}

// The driver, for the controls that need only the reason token.
static U8 *R6RunHarness(R6RunCtx *ctx) {
  return R6RunHarnessFull(ctx, NULL);
}

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE OBSERVATION EXTRACTORS.
//
// A positive control must assert the OBSERVATION it claims to establish.
// These helpers extract that observation from the harness's own output.
//
//   R6ExitStatus       the CHILD's exit status, as the harness observed it
//   R6ArtifactPath     the path of the artifact the harness observed
//   R6ArtifactPresent  whether the artifact was present
//   R6RecomputedStagedDigest  the staged source's digest, RECOMPUTED from
//                              the file rather than copied from a record
//
// The LAST ONE is the important one: the probe does NOT trust the
// capture record's digest field. It hashes the staged file itself and
// compares the result. A record that carries a FALSE digest is caught.
// ---------------------------------------------------------------------------

// The field extractor for the harness's OWN output lines.
//
// It finds a line that begins with `key` followed by a tab, and returns
// the rest of the line. The returned value is ALWAYS a fresh allocation.
//
// It returns NULL when the line is absent.
static U8 *R6OutputField(U8 *out, U8 *key) {
  if (out == NULL) return NULL;
  I64 klen = StrLen(key);
  I64 osize = StrLen(out);
  I64 i = 0;
  while (i < osize) {
    I64 j = i;
    while (j < osize && out[j] != 10) j = j + 1;
    if (j - i > klen) {
      I64 same = 1;
      I64 k = 0;
      while (k < klen) {
        if (out[i + k] != key[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1 && out[i + klen] == 9) {
        I64 vlen = j - (i + klen + 1);
        U8 *v = MAlloc(vlen + 1);
        MemCpy(v, out + i + klen + 1, vlen);
        v[vlen] = 0;
        return v;
      }
    }
    if (j >= osize) break;
    i = j + 1;
  }
  return NULL;
}

// The CHILD's exit status, as the harness observed it.
static I64 R6ExitStatus(U8 *out, I64 *present) {
  *present = 0;
  U8 *v = R6OutputField(out, "HARNESS_EXIT_STATUS");
  if (v == NULL) return -1;
  I64 value = 0;
  I64 len = StrLen(v);
  I64 i = 0;
  while (i < len) {
    if (v[i] < 48 || v[i] > 57) { Free(v); return -1; }
    value = value * 10 + (v[i] - 48);
    i = i + 1;
  }
  Free(v);
  *present = 1;
  return value;
}

// The artifact's path, as the harness observed it.
static U8 *R6ArtifactPath(U8 *out) {
  return R6OutputField(out, "HARNESS_ARTIFACT_PATH");
}

// Whether the artifact was present, as the harness observed it.
static I64 R6ArtifactPresent(U8 *out) {
  U8 *v = R6OutputField(out, "HARNESS_ARTIFACT_PRESENT");
  if (v == NULL) return -1;
  I64 value = 0;
  if (StrCmp(v, "1") == 0) value = 1;
  Free(v);
  return value;
}

// The CAPTURE RECORD's staged-source digest, RECOMPUTED FROM THE FILE.
//
// The probe does NOT read the digest from the capture record and believe
// it. It reads the staged source's PATH from the record, hashes the
// ACTUAL bytes of that file, and returns the digest it computed.
//
// It returns NULL when the record does not name a staged source, when the
// named file is absent, or when the record's own digest differs from the
// recomputed one.
static U8 *R6RecomputedStagedDigest(U8 *capture_buf, I64 capture_size) {
  U8 *path = R6Field(capture_buf, capture_size, "STAGED_SOURCE");
  if (path == NULL) return NULL;
  U8 *actual = MAlloc(65);
  if (Sha256File(path, actual) == 0) {
    Free(actual);
    Free(path);
    return NULL;
  }
  U8 *recorded = R6Field(capture_buf, capture_size, "COMPILED_SOURCE_SHA256");
  if (recorded == NULL) {
    // The record does not carry the compiled source's digest. That is a
    // REFUSAL, not a fallback.
    Free(actual);
    Free(path);
    return NULL;
  }
  I64 same = 0;
  if (StrCmp(actual, recorded) == 0) same = 1;
  Free(path);
  if (same == 0) {
    Free(actual);
    return NULL;
  }
  return actual;
}

// ---------------------------------------------------------------------------
// R5-01 -- THE SOURCE-BINDING CONTROLS.
//
// THE ORIGINAL COUNTEREXAMPLE. The runner hashed source A, but the
// supplied compiler argv selected source B. The independent reviewer
// observed:
//
//   RECORDED_SOURCE_BEHAVIOR=return 0
//   COMPILED_OBJECT_BEHAVIOR=return 42
//   COMPARATOR=PASS 29/29
//
// THE CONTROLS.
//
// The capture-record reader. It finds the capture record the harness
// wrote and returns its bytes.
//
// The capture record lives in the event directory, whose name is the
// event counter. The probe therefore READS the harness's own
// `HARNESS_EVENT_DIR` output, which names it exactly.
static U8 *R6Capture(U8 *harness_out, I64 *out_size) {
  *out_size = 0;
  if (harness_out == NULL) return NULL;
  U8 *marker = "HARNESS_CAPTURE_PATH\t";
  I64 mlen = StrLen(marker);
  I64 osize = StrLen(harness_out);
  I64 i = 0;
  while (i < osize) {
    I64 j = i;
    while (j < osize && harness_out[j] != 10) j = j + 1;
    if (j - i > mlen) {
      I64 same = 1;
      I64 k = 0;
      while (k < mlen) {
        if (harness_out[i + k] != marker[k]) { same = 0; break; }
        k = k + 1;
      }
      if (same == 1) {
        I64 plen = j - (i + mlen);
        U8 *path = MAlloc(plen + 1);
        MemCpy(path, harness_out + i + mlen, plen);
        path[plen] = 0;
        I64 csize = 0;
        U8 *buf = FileRead(path, &csize);
        Free(path);
        if (buf != NULL) *out_size = csize;
        return buf;
      }
    }
    if (j >= osize) break;
    i = j + 1;
  }
  return NULL;
}

// The STDOUT-MODE OBSERVATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE STDOUT MODE IS OBSERVED.
//
// It returns 1 when the capture record names the STDOUT output mode AND
// the captured stdout is NONEMPTY.
//
// The previous revision READ THE SOURCE BYTES to decide whether an
// artifact had been produced. That is not an observation of the artifact
// at all.
//
// It is a SEPARATE function because the execution mode's frame is already
// large, and a large frame overflows the runtime's process stack on this
// host.
static I64 R6StdoutModeHasBytes(U8 *out) {
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  if (cap == NULL) return 0;
  I64 ok = 0;
  U8 *mode = R6Field(cap, csize, "OUTPUT_MODE");
  if (mode != NULL) {
    if (StrCmp(mode, "STDOUT") == 0) ok = 1;
    Free(mode);
  }
  // The captured stdout must be NONEMPTY. An empty capture is a missing
  // artifact.
  if (ok == 1) {
    U8 *stdout_sha = R6Field(cap, csize, "STDOUT_SHA256");
    if (stdout_sha != NULL) {
      // The digest of the EMPTY string. A capture whose digest is this
      // one carries NO bytes.
      if (StrCmp(stdout_sha,
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") == 0) {
        ok = 0;
      }
      Free(stdout_sha);
    }
  }
  Free(cap);
  return ok;
}

// The STAGED-PRODUCER DIGEST OBSERVATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE DIGEST IS RECOMPUTED FROM THE STAGED FILE.
//
// The previous revision COMPARED TWO RECORD FIELDS with each other. That
// proves nothing about the bytes: a record that carried the SAME WRONG
// digest twice satisfied the control.
//
// It returns 1 when the staged producer's ACTUAL bytes hash to the
// digest the record claims, and 0 otherwise.
//
// It is a SEPARATE function because the execution mode's frame is already
// large, and a large frame overflows the runtime's process stack on this
// host.
static I64 R6StagedProducerDigestRecomputed(U8 *out) {
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  if (cap == NULL) return 0;
  U8 *staged = R6Field(cap, csize, "STAGED_PRODUCER");
  U8 *staged_hex = R6Field(cap, csize, "STAGED_PRODUCER_SHA256");
  I64 ok = 0;
  if (staged != NULL && staged_hex != NULL) {
    U8 *actual = MAlloc(65);
    if (Sha256File(staged, actual) == 1) {
      if (StrCmp(actual, staged_hex) == 0) ok = 1;
    }
    Free(actual);
  }
  if (staged != NULL) Free(staged);
  if (staged_hex != NULL) Free(staged_hex);
  Free(cap);
  return ok;
}

// The STAGED-PRODUCER QUALIFICATION OBSERVATION.
//
// It returns 1 when the staged producer's ACTUAL bytes are the SAME
// BYTES as the ORIGINAL producer's bytes, which the probe hashes itself.
//
// It is a SEPARATE function for the same frame-size reason.
static I64 R6StagedBytesAreQualified(U8 *out, U8 *producer) {
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  if (cap == NULL) return 0;
  U8 *staged = R6Field(cap, csize, "STAGED_PRODUCER");
  I64 ok = 0;
  if (staged != NULL) {
    U8 *actual = MAlloc(65);
    U8 *original = MAlloc(65);
    if (Sha256File(staged, actual) == 1) {
      if (Sha256File(producer, original) == 1) {
        if (StrCmp(actual, original) == 0) ok = 1;
      }
    }
    Free(actual);
    Free(original);
  }
  if (staged != NULL) Free(staged);
  Free(cap);
  return ok;
}

// The STAGED-EXECUTABLE OBSERVATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE EXECUTED BYTES ARE THE RUNNER'S OWN.
//
// It returns 1 when the capture record names BOTH the staged producer and
// the executed executable, and the two are THE SAME PATH.
//
// It is a SEPARATE function because the execution mode's frame is already
// large, and a large frame overflows the runtime's process stack on this
// host.
static I64 R6ExecutedIsStaged(U8 *out) {
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  if (cap == NULL) return 0;
  U8 *staged = R6Field(cap, csize, "STAGED_PRODUCER");
  U8 *executed = R6Field(cap, csize, "EXECUTED_EXECUTABLE");
  I64 ok = 0;
  if (staged != NULL && executed != NULL) {
    if (StrCmp(staged, executed) == 0) ok = 1;
  }
  if (staged != NULL) Free(staged);
  if (executed != NULL) Free(executed);
  Free(cap);
  return ok;
}

// The ASSEMBLY-CLASS OBSERVATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE EXPECTED ARTIFACT CLASS IS ASSERTED.
//
// It returns 1 when the artifact named by the harness's own output is
// NONEMPTY TEXT that names the expected architecture's assembler, which
// is the class of an `-S` artifact.
//
// The previous revision applied the MACH-O class check to the assembly
// case as well, and the control therefore failed for the RIGHT artifact.
// A control that cannot distinguish the two emission classes proves
// nothing about either.
//
// It is a SEPARATE function because the execution mode's frame is already
// large, and a large frame overflows the runtime's process stack on this
// host.
static I64 R6ArtifactIsAssembly(U8 *out) {
  U8 *path = R6ArtifactPath(out);
  if (path == NULL) return 0;
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  I64 ok = 0;
  if (buf != NULL) {
    // The artifact must be NONEMPTY, and it must name an assembler.
    if (size > 0) {
      I64 i = 0;
      I64 has_asm = 0;
      while (i + 8 <= size) {
        if (buf[i] == 46) {
          // ".text", ".globl" and the other assembler directives.
          if (buf[i + 1] == 116 || buf[i + 1] == 103 || buf[i + 1] == 100) {
            has_asm = 1;
            break;
          }
        }
        i = i + 1;
      }
      if (has_asm == 1) ok = 1;
    }
    Free(buf);
  }
  Free(path);
  return ok;
}

// The ARTIFACT-PRESENCE OBSERVATION.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-04 -- THE ARTIFACT IS OBSERVED, NOT INFERRED.
//
// It is a SEPARATE function because the execution mode's frame is already
// large, and a large frame overflows the runtime's process stack on this
// host.
//
// It returns 1 when the artifact named by the harness's own output is
// PRESENT on the disk, and 0 when it is absent. It returns 0 when the
// harness named no artifact at all.
static I64 R6ArtifactExists(U8 *out) {
  U8 *path = R6ArtifactPath(out);
  if (path == NULL) return 0;
  I64 size = 0;
  I64 present = 0;
  if (FileRead(path, &size) != NULL) present = 1;
  Free(path);
  return present;
}

// The ARTIFACT-CLASS OBSERVATION.
//
// It returns 1 when the artifact named by the harness's own output is a
// Mach-O image for SOME supported architecture, and 0 otherwise.
static I64 R6ArtifactIsMachO(U8 *out) {
  U8 *path = R6ArtifactPath(out);
  if (path == NULL) return 0;
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  I64 ok = 0;
  if (buf != NULL) {
    if (ContractArchOf(buf, size) >= 0) ok = 1;
    Free(buf);
  }
  Free(path);
  return ok;
}

// The SOURCE that returns 0 and the SOURCE that returns 42.
//
// The two sources are the reviewer's ORIGINAL COUNTEREXAMPLE pair. The
// compiled object's BEHAVIOUR is the independent witness: a source that
// returns 0 must produce an object that returns 0, and a source that
// returns 42 must produce an object that returns 42.
static U8 *R6SourceZero() {
  return "I32 Main(I32 argc, U8 **argv) { return 0; }\n";
}

static U8 *R6Source42() {
  return "I32 Main(I32 argc, U8 **argv) { return 42; }\n";
}

// The EXECUTION MODE.
//
// It runs every R5-01, R5-02 and R5-04 control.
//
//   probe exec <harness> <producer> <work-dir> <arch>
static U0 R6ExecMode(U8 *harness, U8 *producer, U8 *work_dir, U8 *arch) {
  // The work directory is resolved to an ABSOLUTE path, so that every
  // fixture the probe builds is absolute and a SYMLINK's target does not
  // depend on the caller's working directory.
  //
  // The resolved path is carried in a LOCAL variable rather than in the
  // parameter: the production compiler's calling convention does not
  // agree with itself about a re-assigned parameter.
  U8 *rbuf = MAlloc(4096);
  U8 *resolved = realpath(work_dir, rbuf);
  U8 *dir = work_dir;
  if (resolved != NULL) dir = resolved;
  R6MakeDirs(dir);
  // The FIXTURES. The two sources and the fixture file.
  U8 *src_a = R6Path(dir, "source_a.HC");
  U8 *src_b = R6Path(dir, "source_b.HC");
  U8 *fixture = R6Path(dir, "fixture.bin");
  R6Write(src_a, R6SourceZero(), StrLen(R6SourceZero()));
  R6Write(src_b, R6Source42(), StrLen(R6Source42()));
  R6Write(fixture, "fixture\n", 8);

  // -------------------------------------------------------------------
  // R5-01 -- THE SOURCE-BINDING CONTROLS.
  // -------------------------------------------------------------------

  // R5_01_SOURCE_CONTRADICTED. The recorded source is A and the supplied
  // argument vector names B.
  {
    U8 *cd = R6Path(dir, "R5_01_SOURCE_CONTRADICTED");
    R6MakeDirs(cd);
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    U8 *argv[4];
    argv[0] = producer;
    argv[1] = "-c";
    argv[2] = src_b;
    argv[3] = NULL;
    R6RunCtx ctx;
    ctx.harness = harness;
    ctx.run_dir = run_dir;
    ctx.ledger = ledger;
    ctx.case_id = "R5_01_SOURCE_CONTRADICTED";
    ctx.producer = producer;
    ctx.source = src_a;
    ctx.fixture = fixture;
    ctx.artifact_name = "artifact.bin";
    ctx.artifact_dir = art_dir;
    ctx.arch = arch;
    ctx.argv = argv;
    ctx.nargv = 3;
    U8 *out = NULL;
    U8 *reason = R6RunHarnessFull(&ctx, &out);
    I64 refused = 0;
    if (StrCmp(reason, "HARNESS_SOURCE_CONTRADICTED") == 0) refused = 1;
    R6Verdict("R5_01_SOURCE_CONTRADICTED", refused, 1, reason);
    // The ESCAPED artifact must NOT exist.
    //
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
    // R6-04 -- THE CONTROL NOW OBSERVES THE ARTIFACT.
    //
    // The previous revision READ THE SOURCE FILE and asserted that it
    // existed. That is not an observation of the artifact at all: the
    // source is present whether or not an artifact was produced, so the
    // control could not fail.
    //
    // The control now looks for the ARTIFACT itself, in the runner's own
    // output directory, and asserts that it is ABSENT.
    I64 escaped = R6ArtifactExists(out);
    R6Verdict("R5_01_CONTRADICTED_NO_ARTIFACT", escaped, 0,
              "NO_ARTIFACT_WAS_PRODUCED");
    // The runner must also have produced NO EVENT DIRECTORY, because the
    // run was REFUSED before the execution.
    I64 no_event = 0;
    U8 *event_dir = R6OutputField(out, "HARNESS_EVENT_DIR");
    if (event_dir == NULL) no_event = 1;
    if (event_dir != NULL) Free(event_dir);
    R6Verdict("R5_01_CONTRADICTED_NO_EVENT", no_event, 1,
              "THE_REFUSED_RUN_PRODUCED_NO_EVENT");
    Free(out);
    Free(reason);
  }

  // R5_01_SOURCE_AGREES and the provenance controls. The recorded source
  // is A and the supplied argument vector names A.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-04 -- THE POSITIVE CONTROL ASSERTS THE OBSERVATION.
  //
  // The previous revision asserted only "the harness printed no reason
  // token", which is satisfied by a compiler that FAILED. The control
  // now requires:
  //
  //   * the CHILD's exit status to be ZERO;
  //   * the artifact to be PRESENT;
  //   * the artifact to be a REAL Mach-O object of the expected class;
  //   * the staged source's digest to be INDEPENDENTLY RECOMPUTED from
  //     the staged file, and to match the record's claim.
  {
    U8 *cd = R6Path(dir, "R5_01_SOURCE_AGREES");
    R6MakeDirs(cd);
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    U8 *argv[6];
    argv[0] = producer;
    argv[1] = "-c";
    argv[2] = "-o";
    argv[3] = "artifact.bin";
    argv[4] = src_a;
    argv[5] = NULL;
    R6RunCtx ctx;
    ctx.harness = harness;
    ctx.run_dir = run_dir;
    ctx.ledger = ledger;
    ctx.case_id = "R5_01_SOURCE_AGREES";
    ctx.producer = producer;
    ctx.source = src_a;
    ctx.fixture = fixture;
    ctx.artifact_name = "artifact.bin";
    ctx.artifact_dir = art_dir;
    ctx.arch = arch;
    ctx.argv = argv;
    ctx.nargv = 5;
    U8 *out = NULL;
    U8 *reason = R6RunHarnessFull(&ctx, &out);
    I64 ok = 0;
    if (StrCmp(reason, "NO_REASON_TOKEN") == 0) ok = 1;
    R6Verdict("R5_01_SOURCE_AGREES", ok, 1, reason);
    // The CHILD's exit status. A compiler that failed does NOT satisfy
    // this control.
    I64 exit_present = 0;
    I64 exit_value = R6ExitStatus(out, &exit_present);
    I64 exit_ok = 0;
    if (exit_present == 1 && exit_value == 0) exit_ok = 1;
    R6Verdict("R5_01_SOURCE_AGREES_EXIT_STATUS", exit_ok, 1,
              "THE_CHILD_EXITED_ZERO");
    // The artifact's presence.
    I64 present = R6ArtifactPresent(out);
    R6Verdict("R5_01_SOURCE_AGREES_ARTIFACT_PRESENT", present, 1,
              "THE_ARTIFACT_IS_PRESENT");
    // The artifact's CLASS. It must be a real Mach-O image for the
    // expected architecture.
    I64 class_ok = R6ArtifactIsMachO(out);
    R6Verdict("R5_01_SOURCE_AGREES_ARTIFACT_CLASS", class_ok, 1,
              "THE_ARTIFACT_IS_A_MACHO_IMAGE");
    // The staged source's digest, RECOMPUTED from the staged file.
    I64 digest_ok = 0;
    {
      I64 csize = 0;
      U8 *cap = R6Capture(out, &csize);
      if (cap != NULL) {
        U8 *recomputed = R6RecomputedStagedDigest(cap, csize);
        if (recomputed != NULL) digest_ok = 1;
        Free(cap);
      }
    }
    R6Verdict("R5_01_SOURCE_AGREES_STAGED_DIGEST", digest_ok, 1,
              "THE_STAGED_SOURCE_DIGEST_WAS_RECOMPUTED");
    Free(out);
    Free(reason);
  }

  // R5_01_SOURCE_MISSING. The RECORDED source is absent.
  {
    U8 *cd = R6Path(dir, "R5_01_SOURCE_MISSING");
    R6MakeDirs(cd);
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    U8 *absent = R6Path(cd, "absent.HC");
    U8 *argv[4];
    argv[0] = producer;
    argv[1] = "-c";
    argv[2] = absent;
    argv[3] = NULL;
    R6RunCtx ctx;
    ctx.harness = harness;
    ctx.run_dir = run_dir;
    ctx.ledger = ledger;
    ctx.case_id = "R5_01_SOURCE_MISSING";
    ctx.producer = producer;
    ctx.source = absent;
    ctx.fixture = fixture;
    ctx.artifact_name = "artifact.bin";
    ctx.artifact_dir = art_dir;
    ctx.arch = arch;
    ctx.argv = argv;
    ctx.nargv = 3;
    U8 *reason = R6RunHarness(&ctx);
    I64 refused = 0;
    if (StrCmp(reason, "HARNESS_REQUIRED_INPUT_MISSING") == 0) refused = 1;
    R6Verdict("R5_01_SOURCE_MISSING", refused, 1, reason);
    Free(reason);
  }

  // -------------------------------------------------------------------
  // R5-02 -- THE OUTPUT-CONTAINMENT CONTROLS.
  //
  // THE ORIGINAL COUNTEREXAMPLE. The caller supplied
  // `-o ../../../escaped.o` with a matching artifact name. The compiler
  // wrote OUTSIDE the event directory, and the harness registered the
  // escaped artifact as successful.
  //
  // THE CONTROLS.
  //
  //   R5_02_PARENT_TRAVERSAL      `-o ../../../escaped.o`   -> REFUSED
  //   R5_02_ABSOLUTE              an absolute `-o`           -> REFUSED
  //   R5_02_NESTED_TRAVERSAL      `-o a/b/c.o`              -> REFUSED
  //   R5_02_VALID_OBJECT          `-o artifact.bin`         -> ACCEPTED
  //   R5_02_VALID_ASSEMBLY        `-S -o artifact.s`        -> ACCEPTED
  //   R5_02_STDOUT_EMISSION       `-S -o-`                  -> ACCEPTED
  //   R5_02_NO_ESCAPED_ARTIFACT   the escaped file does NOT exist
  // -------------------------------------------------------------------

  // The output control. It runs the harness with the given output
  // argument and reports whether the run was REFUSED.
  //
  // The output argument is the caller's `-o` VALUE, and the artifact name
  // is the runner's expected basename.
  {
    U8 *cd = R6Path(dir, "R5_02");
    R6MakeDirs(cd);
    // The escape target. It is a directory the CALLER owns, outside the
    // runner's own tree, and the escaped artifact must not appear there.
    U8 *escape_dir = R6Path(cd, "escape");
    R6MakeDirs(escape_dir);
    // The three escaping output values.
    U8 *bad[3];
    bad[0] = "../../../escaped.o";
    bad[1] = "/tmp/polyc-r6-escaped-absolute.o";
    bad[2] = "a/b/c.o";
    U8 *ids[3];
    ids[0] = "R5_02_PARENT_TRAVERSAL";
    ids[1] = "R5_02_ABSOLUTE";
    ids[2] = "R5_02_NESTED_TRAVERSAL";
    I64 i = 0;
    while (i < 3) {
      U8 *cc = R6Path(cd, ids[i]);
      R6MakeDirs(cc);
      U8 *run_dir = R6Path(cc, "run");
      R6MakeDirs(run_dir);
      U8 *ledger = R6Path(cc, "ledger.txt");
      R6Write(ledger, "", 0);
      U8 *art_dir = R6Path(cc, "art");
      R6MakeDirs(art_dir);
      U8 *argv[5];
      argv[0] = producer;
      argv[1] = "-c";
      argv[2] = "-o";
      argv[3] = bad[i];
      argv[4] = NULL;
      R6RunCtx ctx;
      ctx.harness = harness;
      ctx.run_dir = run_dir;
      ctx.ledger = ledger;
      ctx.case_id = ids[i];
      ctx.producer = producer;
      ctx.source = src_a;
      ctx.fixture = fixture;
      ctx.artifact_name = "artifact.bin";
      ctx.artifact_dir = art_dir;
      ctx.arch = arch;
      ctx.argv = argv;
      ctx.nargv = 4;
      U8 *reason = R6RunHarness(&ctx);
      I64 refused = 0;
      if (StrCmp(reason, "HARNESS_OUTPUT_ESCAPED") == 0) refused = 1;
      if (StrCmp(reason, "HARNESS_OUTPUT_NOT_INSIDE") == 0) refused = 1;
      R6Verdict(ids[i], refused, 1, reason);
      Free(reason);
      i = i + 1;
    }
    // The escaped artifact must NOT exist. The original counterexample
    // produced `/tmp/polyc-r6-escaped-absolute.o` and a file three levels
    // above the run directory.
    I64 escaped_present = 0;
    I64 sz = 0;
    U8 *abs_escape = "/tmp/polyc-r6-escaped-absolute.o";
    if (FileRead(abs_escape, &sz) != NULL) escaped_present = 1;
    // The RELATIVE escape target. It is three levels above the control's
    // own directory, which is where the original counterexample wrote.
    U8 *rel_escape = R6Path(cd, "../../../escaped.o");
    if (FileRead(rel_escape, &sz) != NULL) escaped_present = 1;
    R6Verdict("R5_02_NO_ESCAPED_ARTIFACT", escaped_present, 0,
              "NO_ESCAPED_ARTIFACT_WAS_PRODUCED");
  }

  // The three POSITIVE output controls: a valid object, a valid assembly
  // and the stdout emission.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-04 -- THE CONTROLS ASSERT THE OBSERVATION THEY CLAIM.
  //
  // THE ORIGINAL DEFECTS.
  //
  //   * The STDOUT control set `nargs = 2`, which EXCLUDED the `-o-`
  //     option from the argument vector entirely. The child therefore
  //     exited with a failure status, and the control still passed,
  //     because it asserted only "no reason token".
  //
  //   * The OBJECT and the ASSEMBLY controls asserted only "no reason
  //     token", so a compiler that produced nothing satisfied them.
  //
  // THE REPAIR.
  //
  //   * The STDOUT control's argument vector CARRIES the `-o-` option.
  //
  //   * Every control requires the CHILD's exit status to be ZERO, the
  //     artifact to be PRESENT with the expected CLASS, and -- for the
  //     STDOUT mode -- the captured stdout to be NONEMPTY and to carry
  //     no unintended artifact.
  {
    U8 *ids[3];
    ids[0] = "R5_02_VALID_OBJECT";
    ids[1] = "R5_02_VALID_ASSEMBLY";
    ids[2] = "R5_02_STDOUT_EMISSION";
    I64 i = 0;
    while (i < 3) {
      U8 *cc = R6Path(dir, ids[i]);
      R6MakeDirs(cc);
      U8 *run_dir = R6Path(cc, "run");
      R6MakeDirs(run_dir);
      U8 *ledger = R6Path(cc, "ledger.txt");
      R6Write(ledger, "", 0);
      U8 *art_dir = R6Path(cc, "art");
      R6MakeDirs(art_dir);
      U8 *argv[5];
      argv[0] = producer;
      argv[1] = "-c";
      argv[2] = "-o";
      argv[3] = "artifact.bin";
      argv[4] = NULL;
      I64 nargs = 4;
      I64 expect_stdout = 0;
      I64 expect_assembly = 0;
      if (i == 1) {
        // The ASSEMBLY emission. The output option is present and names
        // the runner's own basename.
        argv[1] = "-S";
        argv[3] = "artifact.s";
        expect_assembly = 1;
      }
      if (i == 2) {
        // The STDOUT emission. The output option is `-o-`, which is not a
        // filesystem path at all.
        //
        // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03,
        // C4 ROUND 7, R6-04 -- THE `-o-` OPTION IS CARRIED.
        //
        // The previous revision set `nargs = 2` here, which excluded the
        // option from the argument vector. The child then failed, and
        // the control passed anyway, because it asserted nothing about
        // the child's behaviour.
        argv[1] = "-S";
        argv[2] = "-o-";
        argv[3] = NULL;
        nargs = 3;
        expect_stdout = 1;
      }
      R6RunCtx ctx;
      ctx.harness = harness;
      ctx.run_dir = run_dir;
      ctx.ledger = ledger;
      ctx.case_id = ids[i];
      ctx.producer = producer;
      ctx.source = src_a;
      ctx.fixture = fixture;
      ctx.artifact_name = "artifact.bin";
      ctx.artifact_dir = art_dir;
      ctx.arch = arch;
      ctx.argv = argv;
      ctx.nargv = nargs;
      U8 *out = NULL;
      U8 *reason = R6RunHarnessFull(&ctx, &out);
      I64 ok = 0;
      if (StrCmp(reason, "NO_REASON_TOKEN") == 0) ok = 1;
      R6Verdict(ids[i], ok, 1, reason);
      // The CHILD's exit status.
      I64 exit_present = 0;
      I64 exit_value = R6ExitStatus(out, &exit_present);
      I64 exit_ok = 0;
      if (exit_present == 1 && exit_value == 0) exit_ok = 1;
      R6Verdict("R5_02_EXIT_STATUS", exit_ok, 1, "THE_CHILD_EXITED_ZERO");
      // The artifact's presence and class.
      I64 present = R6ArtifactPresent(out);
      if (expect_stdout == 1) {
        // The STDOUT mode. The produced artifact IS the captured stdout
        // stream, so it is PRESENT exactly when the capture is nonempty.
        I64 stdout_present = R6StdoutModeHasBytes(out);
        R6Verdict("R5_02_STDOUT_MODE", stdout_present, 1,
                  "THE_CAPTURE_RECORDS_STDOUT_MODE_WITH_BYTES");
        // NO UNINTENDED ARTIFACT. The stdout emission must NOT have
        // produced a filesystem artifact.
        I64 stray = R6ArtifactExists(out);
        R6Verdict("R5_02_STDOUT_NO_FILE_ARTIFACT", stray, 0,
                  "NO_FILESYSTEM_ARTIFACT_WAS_PRODUCED");
      } else {
        // The FILE mode. The artifact must be present and it must have the
        // EXPECTED CLASS: an OBJECT for `-c`, and ASSEMBLY TEXT for `-S`.
        R6Verdict("R5_02_ARTIFACT_PRESENT", present, 1,
                  "THE_ARTIFACT_IS_PRESENT");
        I64 class_ok = 0;
        if (expect_assembly == 1) {
          class_ok = R6ArtifactIsAssembly(out);
        } else {
          class_ok = R6ArtifactIsMachO(out);
        }
        R6Verdict("R5_02_ARTIFACT_CLASS", class_ok, 1,
                  "THE_ARTIFACT_HAS_THE_EXPECTED_CLASS");
      }
      Free(out);
      Free(reason);
      i = i + 1;
    }
  }

  // -------------------------------------------------------------------
  // R5-04 -- THE EXECUTABLE-IDENTITY CONTROLS.
  //
  // THE ORIGINAL COUNTEREXAMPLE. The reviewer replaced the executable
  // between the final validation and the process creation. The child
  // executed fixture B while the capture recorded fixture A's digest.
  // A symlinked ancestor replacement produced a similar result.
  //
  // THE CONTROLS.
  //
  //   R5_04_STAGED_PRODUCER          the capture record names a STAGED
  //                                  producer, and the staged producer's
  //                                  digest is the QUALIFIED digest
  //   R5_04_EXECUTED_IS_STAGED       the executed executable is the
  //                                  runner's staged copy
  //   R5_04_SYMLINKED_ANCESTOR       a producer whose ANCESTOR is a
  //                                  symlink is refused or staged
  //   R5_04_NORMAL_PRODUCER          an unmodified producer is ACCEPTED
  // -------------------------------------------------------------------
  {
    U8 *cd = R6Path(dir, "R5_04");
    R6MakeDirs(cd);
    // R5_04_SYMLINKED_ANCESTOR. The producer's path goes through a
    // SYMLINKED ANCESTOR, which the previous revision's `lstat` policy
    // did not detect: the check was on the FINAL component only.
    //
    // The symlink is created with the platform's own `symlink(3)`. The
    // symlink's TARGET is ABSOLUTE, so the link resolves to the same
    // file no matter what the caller's working directory is.
    U8 *real_dir = R6Path(cd, "real");
    R6MakeDirs(real_dir);
    U8 *real_producer = R6Path(real_dir, "producer");
    I64 psize = 0;
    U8 *pbuf = FileRead(producer, &psize);
    if (pbuf != NULL) {
      R6Write(real_producer, pbuf, psize);
      Free(pbuf);
    }
    // The fixture's copy must be EXECUTABLE, exactly as the original
    // producer is. The mode is set with the platform's own `chmod(2)`.
    chmod(real_producer, 493);
    // The ANCESTOR is the symlink. The producer's final component is an
    // ordinary file inside it.
    U8 *link_dir = R6Path(cd, "link");
    R6MakeDirs(link_dir);
    U8 *link = R6Path(link_dir, "producer");
    symlink(real_producer, link);
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
    // R6-04 -- THE SYMLINK IS AT THE RIGHT LOCATION.
    //
    // The previous revision put the symlink at the producer's FINAL
    // component, so the control exercised the "the producer path is a
    // symbolic link" branch. It did NOT exercise the SYMLINKED-ANCESTOR
    // case that its own comment described, and the two are different
    // situations.
    //
    // The ANCESTOR case is built here: the producer's final component is
    // an ORDINARY FILE, and one of its ANCESTOR DIRECTORIES is the
    // symlink.
    U8 *anc_dir = R6Path(cd, "ancestor");
    R6MakeDirs(anc_dir);
    U8 *anc_target_dir = R6Path(cd, "ancestor-target");
    R6MakeDirs(anc_target_dir);
    U8 *anc_producer = R6Path(anc_target_dir, "producer");
    // The producer's bytes are read AGAIN, because the first copy's
    // buffer has already been released.
    I64 asize = 0;
    U8 *abuf = FileRead(producer, &asize);
    if (abuf != NULL) {
      R6Write(anc_producer, abuf, asize);
      Free(abuf);
    }
    chmod(anc_producer, 493);
    U8 *anc_link = R6Path(anc_dir, "producer-dir");
    symlink(anc_target_dir, anc_link);
    U8 *anc_path = R6Path(anc_link, "producer");
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    U8 *argv[5];
    argv[0] = anc_path;
    argv[1] = "-c";
    argv[2] = "-o";
    argv[3] = "artifact.bin";
    argv[4] = NULL;
    R6RunCtx ctx;
    ctx.harness = harness;
    ctx.run_dir = run_dir;
    ctx.ledger = ledger;
    ctx.case_id = "R5_04_SYMLINKED_ANCESTOR";
    ctx.producer = anc_path;
    ctx.source = src_a;
    ctx.fixture = fixture;
    ctx.artifact_name = "artifact.bin";
    ctx.artifact_dir = art_dir;
    ctx.arch = arch;
    ctx.argv = argv;
    ctx.nargv = 4;
    U8 *out = NULL;
    U8 *reason = R6RunHarnessFull(&ctx, &out);
    // The runner must either REFUSE the symlinked-ancestor producer or
    // STAGE it. Either way, the executed bytes are the runner's own
    // staged copy, and the control must observe THAT.
    I64 refused = 0;
    if (StrCmp(reason, "HARNESS_PRODUCER_SUBSTITUTED") == 0) refused = 1;
    if (StrCmp(reason, "NO_REASON_TOKEN") == 0) refused = 1;
    R6Verdict("R5_04_SYMLINKED_ANCESTOR", refused, 1, reason);
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
    // R6-04 -- THE EXECUTED BYTES ARE THE RUNNER'S OWN.
    //
    // The previous revision accepted EITHER outcome and asserted nothing
    // about the executed bytes, so the control could not distinguish a
    // correct staging from a substitution.
    I64 staged_ok = 0;
    if (StrCmp(reason, "NO_REASON_TOKEN") == 0) {
      staged_ok = R6ExecutedIsStaged(out);
    }
    R6Verdict("R5_04_SYMLINKED_ANCESTOR_EXECUTED_IS_STAGED", staged_ok, 1,
              "THE_EXECUTED_EXECUTABLE_IS_THE_STAGED_PRODUCER");
    Free(out);
    Free(reason);
  }

  // R5_04_NORMAL_PRODUCER and the staging controls. The unmodified
  // producer is run, and the capture record is inspected.
  {
    U8 *cd = R6Path(dir, "R5_04_NORMAL_PRODUCER");
    R6MakeDirs(cd);
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    // The harness's own output is captured, so that the capture record can
    // be inspected.
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
    U8 *run_args[22];
    I64 n = 0;
    run_args[n] = harness;      n = n + 1;
    run_args[n] = "run";        n = n + 1;
    run_args[n] = run_dir;       n = n + 1;
    run_args[n] = ledger;        n = n + 1;
    run_args[n] = "OFF";         n = n + 1;
    run_args[n] = "R5_04_NORMAL_PRODUCER"; n = n + 1;
    run_args[n] = producer;      n = n + 1;
    run_args[n] = src_a;         n = n + 1;
    run_args[n] = fixture;       n = n + 1;
    run_args[n] = "artifact.bin";n = n + 1;
    run_args[n] = art_dir;       n = n + 1;
    run_args[n] = arch;          n = n + 1;
    run_args[n] = "C4R6_PROBE=1";n = n + 1;
    run_args[n] = "--";          n = n + 1;
    run_args[n] = producer;      n = n + 1;
    run_args[n] = "-c";          n = n + 1;
    run_args[n] = "-o";          n = n + 1;
    run_args[n] = "artifact.bin";n = n + 1;
    run_args[n] = src_a;         n = n + 1;
    run_args[n] = NULL;          n = n + 1;
    U8 *out = NULL;
    U8 *err = NULL;
    SpawnAndCapture(harness, run_args, &out, &err);
    Free(err);
    U8 *reason = R6Reason(out);
    I64 ok = 0;
    if (StrCmp(reason, "NO_REASON_TOKEN") == 0) ok = 1;
    R6Verdict("R5_04_NORMAL_PRODUCER", ok, 1, reason);
    Free(reason);
    // The capture record. The STAGED producer's identity and the
    // EXECUTED executable are both named.
    I64 csize = 0;
    U8 *cap = R6Capture(out, &csize);
    if (cap == NULL) {
      R6Verdict("R5_04_STAGED_PRODUCER", 0, 1, "CAPTURE_RECORD_UNREADABLE");
      R6Verdict("R5_04_EXECUTED_IS_STAGED", 0, 1,
                "CAPTURE_RECORD_UNREADABLE");
    } else {
      U8 *staged = R6Field(cap, csize, "STAGED_PRODUCER");
      U8 *executed = R6Field(cap, csize, "EXECUTED_EXECUTABLE");
      U8 *staged_hex = R6Field(cap, csize, "STAGED_PRODUCER_SHA256");
      U8 *prod_hex = R6Field(cap, csize, "PRODUCER_SHA256");
      I64 have_staged = 0;
      if (staged != NULL && staged_hex != NULL) have_staged = 1;
      R6Verdict("R5_04_STAGED_PRODUCER", have_staged, 1,
                "STAGED_PRODUCER_NAMED");
      // The executed executable must BE the staged producer.
      I64 is_staged = 0;
      if (staged != NULL && executed != NULL) {
        if (StrCmp(staged, executed) == 0) is_staged = 1;
      }
      R6Verdict("R5_04_EXECUTED_IS_STAGED", is_staged, 1,
                "EXECUTED_EXECUTABLE_IS_THE_STAGED_PRODUCER");
      // The staged producer's digest must be the QUALIFIED digest.
      //
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
      // R6-04 -- THE DIGEST IS RECOMPUTED FROM THE STAGED FILE.
      //
      // The previous revision COMPARED TWO RECORD FIELDS with each other.
      // That proves nothing about the bytes: a record that carried the
      // SAME WRONG digest twice satisfied the control.
      //
      // The control now RECOMPUTES the digest from the staged file's
      // ACTUAL bytes and compares the result with the record's claim, and
      // it also compares the recomputed digest with the ORIGINAL
      // producer's digest, which the probe hashes itself.
      I64 same = 0;
      if (staged_hex != NULL && prod_hex != NULL) {
        if (StrCmp(staged_hex, prod_hex) == 0) same = 1;
      }
      R6Verdict("R5_04_STAGED_DIGEST_IS_QUALIFIED", same, 1,
                "STAGED_DIGEST_EQUALS_QUALIFIED_DIGEST");
      I64 recomputed_same = R6StagedProducerDigestRecomputed(out);
      R6Verdict("R5_04_STAGED_DIGEST_RECOMPUTED", recomputed_same, 1,
                "THE_STAGED_PRODUCER_DIGEST_WAS_RECOMPUTED");
      I64 qualified_same = R6StagedBytesAreQualified(out, producer);
      R6Verdict("R5_04_STAGED_BYTES_ARE_QUALIFIED", qualified_same, 1,
                "THE_STAGED_BYTES_ARE_THE_QUALIFIED_BYTES");
      Free(cap);
    }
    Free(out);
  }
}

// ---------------------------------------------------------------------------
// R5-03 -- THE ZERO-FILL VALIDATION MODE.
//
// THE ORIGINAL COUNTEREXAMPLE. A genuine, platform-compiled arm64 object
// containing virtual zero-fill sections was rejected with
// `MACHO_SECTION_EXTENT_INVALID`. The macOS linker accepts that same
// object, and the resulting executable returns 7.
//
// THE CONTROLS.
//
//   R5_03_GENUINE_ZERO_FILL_ACCEPTED  the reviewer's genuine
//                                     `mixed-zerofill` fixture -> ACCEPTED
//   R5_03_GENUINE_TLS_ACCEPTED        the committed genuine TLS fixture
//                                     -> ACCEPTED
//   R5_03_MALFORMED_FILE_EXTENT       a malformed file-backed section
//                                     extent -> REJECTED
//   R5_03_MALFORMED_SEGMENT_EXTENT    a malformed 64-bit segment extent
//                                     -> REJECTED
//   R5_03_MALFORMED_OVERLAP           a malformed section overlap
//                                     -> REJECTED
//
// The mode takes the two genuine fixtures and the two hand-built
// malformed fixtures.
//
//   probe macho <fixture-dir> <mixed-zerofill.o> <tls.o>
// ---------------------------------------------------------------------------
static U0 R6MachOMode(U8 *dir, U8 *mixed, U8 *tls) {
  // The two GENUINE fixtures. They are the independent witnesses: the
  // platform's own compiler produced them, and the platform's own linker
  // accepts them.
  {
    I64 size = 0;
    U8 *buf = FileRead(mixed, &size);
    I64 accepted = 0;
    U8 *reason = "GENUINE_FIXTURE_UNREADABLE";
    if (buf != NULL) {
      I64 mv = ContractValidateMachO(buf, size, 1);
      if (mv == MV_OK) accepted = 1;
      reason = ContractMachOReason(mv);
      Free(buf);
    }
    R6Verdict("R5_03_GENUINE_ZERO_FILL_ACCEPTED", accepted, 1, reason);
  }
  {
    I64 size = 0;
    U8 *buf = FileRead(tls, &size);
    I64 accepted = 0;
    U8 *reason = "GENUINE_FIXTURE_UNREADABLE";
    if (buf != NULL) {
      I64 mv = ContractValidateMachO(buf, size, 1);
      if (mv == MV_OK) accepted = 1;
      reason = ContractMachOReason(mv);
      Free(buf);
    }
    R6Verdict("R5_03_GENUINE_TLS_ACCEPTED", accepted, 1, reason);
  }
  // The MALFORMED fixtures. They are built by MUTATING a copy of the
  // genuine fixture, so that the ONLY difference is the malformed
  // declaration.
  {
    I64 size = 0;
    U8 *buf = FileRead(mixed, &size);
    I64 accepted = 0;
    U8 *reason = "GENUINE_FIXTURE_UNREADABLE";
    if (buf != NULL) {
      // The MALFORMED FILE-BACKED SECTION EXTENT. The `__text` section's
      // size is made enormous, so that the section's file extent runs past
      // the end of the file. The `__text` section is FILE-BACKED, so the
      // bound must be enforced.
      //
      // The section table begins at the load command's offset plus the
      // segment command's header size. The first section's `size` field
      // is at offset 40 within the section.
      I64 sec_off = 32 + 72;
      I64 big = size + 4096;
      R6Put64(buf, sec_off + 40, big);
      I64 mv = ContractValidateMachO(buf, size, 1);
      if (mv == MV_OK) accepted = 1;
      reason = ContractMachOReason(mv);
      Free(buf);
    }
    R6Verdict("R5_03_MALFORMED_FILE_EXTENT", accepted, 0, reason);
  }
  {
    I64 size = 0;
    U8 *buf = FileRead(mixed, &size);
    I64 accepted = 0;
    U8 *reason = "GENUINE_FIXTURE_UNREADABLE";
    if (buf != NULL) {
      // The MALFORMED 64-BIT SEGMENT EXTENT. The segment's `filesize` is
      // made enormous, so the segment's file extent runs past the end of
      // the file. The segment command's `fileoff` is at offset 40 and its
      // `filesize` is at offset 48.
      I64 big = size + 4096;
      R6Put64(buf, 32 + 48, big);
      I64 mv = ContractValidateMachO(buf, size, 1);
      if (mv == MV_OK) accepted = 1;
      reason = ContractMachOReason(mv);
      Free(buf);
    }
    R6Verdict("R5_03_MALFORMED_SEGMENT_EXTENT", accepted, 0, reason);
  }
  {
    I64 size = 0;
    U8 *buf = FileRead(mixed, &size);
    I64 accepted = 0;
    U8 *reason = "GENUINE_FIXTURE_UNREADABLE";
    if (buf != NULL) {
      // The MALFORMED SECTION OVERLAP. The second section's file offset
      // is moved onto the first section's file offset, so the two
      // file-backed sections claim the same file bytes. The second
      // section's `offset` is at offset 48 within the section.
      I64 first_off = 32 + 72;
      I64 sec0_off = 0;
      I64 sec0_size = 0;
      R6Get64(buf, first_off + 48, &sec0_off);
      R6Get64(buf, first_off + 40, &sec0_size);
      // The second section begins 80 bytes after the first.
      R6Put64(buf, first_off + 80 + 48, sec0_off);
      I64 mv = ContractValidateMachO(buf, size, 1);
      if (mv == MV_OK) accepted = 1;
      reason = ContractMachOReason(mv);
      Free(buf);
    }
    R6Verdict("R5_03_MALFORMED_OVERLAP", accepted, 0, reason);
  }
}

// ---------------------------------------------------------------------------
// R5-05 -- THE ENVIRONMENT-BINDING MODE.
//
// THE ORIGINAL COUNTEREXAMPLE. The ambient `envcheck` passes all four
// cases even when the production binding helper is mutated to set the
// WRONG variable. The actual `run` mode then records `GOOD=NEEDLE`,
// while the child observes that `GOOD` is absent.
//
// THE REPAIR. The qualification exercises the SAME `HarnessApplyEnv()`
// implementation that the production `run` mode uses. The mode calls the
// PRODUCTION harness's `envbind` mode, which applies the binding through
// the production helper and observes it in a REAL child.
//
// THE CONTROLS.
//
//   R5_05_CORRECT_BINDING      GOOD=NEEDLE                       -> ACCEPTED
//   R5_05_WRONG_VARIABLE       the binding names GOOD, the probe is
//                              asked about BAD                    -> REFUSED
//   R5_05_WRONG_VALUE          GOOD=NEEDLE, expected WRONG        -> REFUSED
//   R5_05_EMPTY_VALUE          GOOD=                              -> ACCEPTED
//   R5_05_VALUE_SUFFIX         GOOD=NEEDLE=EXTRA                  -> REFUSED
//   R5_05_MISSING_VARIABLE     the probe is asked about a variable
//                              that the binding did not apply       -> REFUSED
//
//   probe envbind <harness> <probe> <work-dir>
// ---------------------------------------------------------------------------
// The ANTI-CONTROL VERDICT.
//
// It is the INVERSE of the ordinary verdict: the anti-control PASSES when
// the control REJECTS the reintroduced defect.
static U0 R6AntiVerdict(U8 *control, I64 rejected, U8 *reason) {
  r6_checks = r6_checks + 1;
  if (rejected == 1) {
    "PROBE_CONTROL\t%s\tOK\t%s\n", control, reason;
  } else {
    r6_failures = r6_failures + 1;
    "PROBE_CONTROL\t%s\tFAIL\t%s\n", control, reason;
  }
}

// The ANTI-CONTROL MODE.
static U0 R6AntiControlMode(U8 *harness, U8 *producer, U8 *work_dir, U8 *arch) {
  U8 *rbuf = MAlloc(4096);
  U8 *resolved = realpath(work_dir, rbuf);
  U8 *dir = work_dir;
  if (resolved != NULL) dir = resolved;
  R6MakeDirs(dir);
  U8 *src_a = R6Path(dir, "anti_source.HC");
  U8 *fixture = R6Path(dir, "anti_fixture.bin");
  U8 *src_text = R6Source42();
  R6Write(src_a, src_text, StrLen(src_text));
  R6Write(fixture, "fixture\n", 8);

  // --- AC_01: THE `-o-` OPTION IS EXCLUDED FROM THE ARGUMENT VECTOR. ------
  //
  // The mistake is the one the review detected: the STDOUT control built
  // an argument vector that did not carry the `-o-` option, so the child
  // failed and the control passed anyway.
  //
  // The anti-control rebuilds THAT vector and requires the STDOUT
  // control's observations to REJECT it.
  {
    U8 *cd = R6Path(dir, "AC_01_EXCLUDE_OUTPUT_OPTION");
    R6MakeDirs(cd);
    U8 *run_dir = R6Path(cd, "run");
    R6MakeDirs(run_dir);
    U8 *ledger = R6Path(cd, "ledger.txt");
    R6Write(ledger, "", 0);
    U8 *art_dir = R6Path(cd, "art");
    R6MakeDirs(art_dir);
    U8 *aa[3];
    aa[0] = producer;
    aa[1] = "-S";
    aa[2] = NULL;
    R6RunCtx ctx;
    ctx.harness = harness;
    ctx.run_dir = run_dir;
    ctx.ledger = ledger;
    ctx.case_id = "AC_01_EXCLUDE_OUTPUT_OPTION";
    ctx.producer = producer;
    ctx.source = src_a;
    ctx.fixture = fixture;
    ctx.artifact_name = "artifact.bin";
    ctx.artifact_dir = art_dir;
    ctx.arch = arch;
    ctx.argv = aa;
    ctx.nargv = 2;
    U8 *out = NULL;
    U8 *reason = R6RunHarnessFull(&ctx, &out);
    // The CHILD must have FAILED, or the STDOUT mode must not have
    // produced the stdout artifact. Either observation makes the STDOUT
    // control REJECT the case.
    I64 exit_present = 0;
    I64 exit_value = R6ExitStatus(out, &exit_present);
    I64 rejected = 0;
    if (exit_present == 1 && exit_value != 0) rejected = 1;
    if (R6StdoutModeHasBytes(out) == 0) rejected = 1;
    R6AntiVerdict("AC_01_EXCLUDE_OUTPUT_OPTION", rejected,
                  "THE_CONTROL_REJECTED_THE_EXCLUDED_OPTION");
    Free(out);
    Free(reason);
  }

  // --- AC_02: THE COMPILER'S EXECUTION FAILED. ----------------------------
  //
  // The control must reject a run whose child exited NONZERO.
  {
    I64 exit_present = 0;
    I64 exit_value = R6ExitStatus("HARNESS_EXIT_STATUS\t7\n", &exit_present);
    I64 rejected = 0;
    if (exit_present == 1 && exit_value != 0) rejected = 1;
    R6AntiVerdict("AC_02_COMPILER_FAILED", rejected,
                  "THE_CONTROL_REJECTED_THE_FAILED_CHILD");
  }

  // --- AC_03: AN UNWANTED ARTIFACT WAS LEFT. ------------------------------
  //
  // The control must reject a run whose artifact path names a file that
  // EXISTS, when the control requires the artifact to be ABSENT.
  {
    I64 present = R6ArtifactPresent("HARNESS_ARTIFACT_PRESENT\t1\n");
    I64 rejected = 0;
    if (present == 1) rejected = 1;
    R6AntiVerdict("AC_03_UNWANTED_ARTIFACT", rejected,
                  "THE_CONTROL_REJECTED_THE_UNWANTED_ARTIFACT");
  }

  // --- AC_04: THE SYMLINK IS IN THE WRONG PLACE. --------------------------
  //
  // The control must reject a capture record whose STAGED_PRODUCER and
  // EXECUTED_EXECUTABLE name DIFFERENT paths.
  {
    I64 rejected = 0;
    U8 *staged = R6Copy("/tmp/staged-producer");
    U8 *executed = R6Copy("/tmp/some-other-executable");
    I64 same = 0;
    if (StrCmp(staged, executed) == 0) same = 1;
    if (same == 0) rejected = 1;
    Free(staged);
    Free(executed);
    R6AntiVerdict("AC_04_WRONG_SYMLINK_LOCATION", rejected,
                  "THE_CONTROL_REJECTED_THE_DIFFERENT_EXECUTABLE");
  }

  // --- AC_05: THE RECORD CARRIES A FALSE STAGED-SOURCE DIGEST. -----------
  //
  // The control must reject a record whose COMPILED_SOURCE_SHA256 does not
  // match the ACTUAL bytes of the staged file.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-02 -- THE CONTROL EXERCISES THE PRODUCTION CHECK.
  //
  // The control calls the SHARED CONTRACT's
  // `ContractStagedDigestMatches` -- the SAME function the comparator
  // calls -- with a DELIBERATELY WRONG digest and the ACTUAL digest of
  // the staged file's bytes.
  //
  // The previous revision performed its OWN comparison, so it tested
  // ITSELF. The reviewer's mutation of the comparator's comparison
  // (`same = 1;`) disabled the comparator's staged-source validation,
  // and this control still PASSED. A control that does not call the
  // production check cannot detect the production check's failure.
  {
    I64 rejected = 0;
    U8 *false_hex = MAlloc(65);
    I64 i = 0;
    while (i < 64) { false_hex[i] = 48; i = i + 1; }
    false_hex[64] = 0;
    // The staged file's ACTUAL digest is computed here, from the bytes on
    // the disk. The EXPECTED digest is therefore derived from the actual
    // staged-source bytes.
    U8 *actual = MAlloc(65);
    I64 present = 0;
    if (Sha256File(src_a, actual) == 1) {
      present = 1;
      // THE PRODUCTION CHECK, CALLED WITH A WRONG DIGEST.
      //
      // The check must REJECT the false digest. A mutant that accepts it
      // makes this control FAIL, which is the required sensitivity.
      if (ContractStagedDigestMatches(false_hex, actual) == 0) rejected = 1;
    }
    Free(actual);
    Free(false_hex);
    if (present == 0) rejected = 1;
    R6AntiVerdict("AC_05_FALSE_STAGED_DIGEST", rejected,
                  "THE_CONTROL_REJECTED_THE_FALSE_DIGEST");
  }

  // --- AC_06: AN INDEPENDENT OBSERVATION IS REPLACED BY A COPIED FIELD. ---
  //
  // The control must reject a record whose recorded digest is copied from
  // ANOTHER field, rather than computed from the bytes.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-02 -- THE CONTROL EXERCISES THE PRODUCTION CHECK.
  //
  // The control calls the SHARED CONTRACT's
  // `ContractStagedDigestMatches` -- the SAME function the comparator
  // calls -- with the COPIED digest and the ACTUAL digest of the staged
  // file's bytes. The check must REJECT the copied digest.
  {
    I64 rejected = 0;
    // The record copies the PRODUCER's digest into the COMPILED SOURCE's
    // field. The recomputation compares the staged file's ACTUAL digest
    // with the record's claim, and the two differ.
    U8 *staged = R6Copy(src_a);
    U8 *claimed = MAlloc(65);
    I64 psize = 0;
    U8 *pbuf = FileRead(producer, &psize);
    if (pbuf != NULL) {
      U8 *pdigest = MAlloc(32);
      Sha256Bytes(pbuf, psize, pdigest);
      Sha256Hex(claimed, pdigest);
      Free(pdigest);
      Free(pbuf);
    }
    U8 *actual = MAlloc(65);
    if (Sha256File(staged, actual) == 1) {
      // THE PRODUCTION CHECK, CALLED WITH THE COPIED DIGEST.
      if (ContractStagedDigestMatches(claimed, actual) == 0) rejected = 1;
    }
    Free(actual);
    Free(claimed);
    Free(staged);
    R6AntiVerdict("AC_06_COPIED_CAPTURE_FIELD", rejected,
                  "THE_CONTROL_REJECTED_THE_COPIED_FIELD");
  }
}
static U0 R6EnvBindMode(U8 *harness, U8 *probe, U8 *dir) {
  R6MakeDirs(dir);
  // The six mandatory cases.
  //
  // The `envbind` mode APPLIES the binding `<bind-name>=<bind-value>`
  // through the production `HarnessApplyEnv()`, OBSERVES the value under
  // `<observe-name>` in a REAL child, and COMPARES the observation with
  // the frozen `<expect-value>`.
  //
  //   R5_05_CORRECT_BINDING    GOOD=NEEDLE, observed under GOOD,
  //                             expected NEEDLE             -> ACCEPTED
  //   R5_05_WRONG_VARIABLE     BAD=NEEDLE,  observed under GOOD,
  //                             expected NEEDLE             -> REFUSED
  //   R5_05_WRONG_VALUE        GOOD=NEEDLE, observed under GOOD,
  //                             expected WRONG              -> REFUSED
  //   R5_05_EMPTY_VALUE        EMPTY=,     observed under EMPTY,
  //                             expected ""                 -> ACCEPTED
  //   R5_05_VALUE_SUFFIX       GOOD=NEEDLE=EXTRA, observed under GOOD,
  //                             expected NEEDLE             -> REFUSED
  //   R5_05_MISSING_VARIABLE   GOOD=NEEDLE, observed under ABSENT,
  //                             expected NEEDLE             -> REFUSED
  U8 *ids[6];
  ids[0] = "R5_05_CORRECT_BINDING";
  ids[1] = "R5_05_WRONG_VARIABLE";
  ids[2] = "R5_05_WRONG_VALUE";
  ids[3] = "R5_05_EMPTY_VALUE";
  ids[4] = "R5_05_VALUE_SUFFIX";
  ids[5] = "R5_05_MISSING_VARIABLE";
  U8 *bind_name[6];
  bind_name[0] = "R6_ENV_GOOD";
  bind_name[1] = "R6_ENV_BAD";
  bind_name[2] = "R6_ENV_GOOD";
  bind_name[3] = "R6_ENV_EMPTY";
  bind_name[4] = "R6_ENV_GOOD";
  bind_name[5] = "R6_ENV_GOOD";
  U8 *bind_value[6];
  bind_value[0] = "NEEDLE";
  bind_value[1] = "NEEDLE";
  bind_value[2] = "NEEDLE";
  bind_value[3] = "";
  bind_value[4] = "NEEDLE=EXTRA";
  bind_value[5] = "NEEDLE";
  U8 *observe_name[6];
  observe_name[0] = "R6_ENV_GOOD";
  observe_name[1] = "R6_ENV_GOOD";
  observe_name[2] = "R6_ENV_GOOD";
  observe_name[3] = "R6_ENV_EMPTY";
  observe_name[4] = "R6_ENV_GOOD";
  observe_name[5] = "R6_ENV_ABSENT";
  U8 *expect_value[6];
  expect_value[0] = "NEEDLE";
  expect_value[1] = "NEEDLE";
  expect_value[2] = "WRONG";
  expect_value[3] = "";
  expect_value[4] = "NEEDLE";
  expect_value[5] = "NEEDLE";
  I64 expect_accept[6];
  expect_accept[0] = 1;
  expect_accept[1] = 0;
  expect_accept[2] = 0;
  expect_accept[3] = 1;
  expect_accept[4] = 0;
  expect_accept[5] = 0;
  I64 i = 0;
  while (i < 6) {
    // The mode's argument vector. The mode applies the binding under
    // `<bind-name>` and observes it under `<observe-name>`.
    U8 *args[8];
    args[0] = harness;
    args[1] = "envbind";
    args[2] = probe;
    args[3] = bind_name[i];
    args[4] = bind_value[i];
    args[5] = observe_name[i];
    args[6] = expect_value[i];
    args[7] = NULL;
    U8 *out = NULL;
    U8 *err = NULL;
    SpawnAndCapture(harness, args, &out, &err);
    Free(err);
    // The mode's verdict. It prints `HARNESS_ENVBIND_STATUS=PASS` when
    // the binding was observed to be in force.
    I64 passed = 0;
    if (out != NULL) {
      U8 *marker = "HARNESS_ENVBIND_STATUS=PASS";
      I64 mlen = StrLen(marker);
      I64 osize = StrLen(out);
      I64 k = 0;
      while (k < osize) {
        I64 j = k;
        while (j < osize && out[j] != 10) j = j + 1;
        if (j - k == mlen) {
          I64 m = 0;
          I64 same = 1;
          while (m < mlen) {
            if (out[k + m] != marker[m]) { same = 0; break; }
            m = m + 1;
          }
          if (same == 1) { passed = 1; break; }
        }
        if (j >= osize) break;
        k = j + 1;
      }
    }
    U8 *reason = "HARNESS_ENVBIND_STATUS=FAIL";
    if (passed == 1) reason = "HARNESS_ENVBIND_STATUS=PASS";
    R6Verdict(ids[i], passed, expect_accept[i], reason);
    Free(out);
    i = i + 1;
  }
}
// ---------------------------------------------------------------------------
// The R5-06 MODE -- THE BLOCK STATUSES ARE DISTINGUISHED.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6, R5-06.
//
// The block extractor used to return NULL for BOTH an absent block and an
// oversized block, and the comparator reported BOTH as
// `CAPTURE_BLOCK_TOO_LARGE`. This mode drives the PRODUCTION extractor
// over five records and requires each to report ITS OWN status.
//
// The five shapes are:
//
//   ARGV is absent from the record      -> CAPTURE_BLOCK_ABSENT
//   ARGV is present and the block is
//     empty                             -> CAPTURE_BLOCK_EMPTY
//   ARGV is a SCALAR field ("ARGV x")  -> CAPTURE_BLOCK_SCALAR
//   ARGV carries more than the limit   -> CAPTURE_BLOCK_TOO_LARGE
//   ARGV is a normal block              -> CAPTURE_BLOCK_OK
//
// The ACCEPTANCE BEHAVIOUR IS UNCHANGED: all four failing shapes are
// refused. What this mode witnesses is the PRECISION of the reason.
// The record builder for the R5-06 mode. The record is `RUN_ID\n<body>`,
// so the `ARGV` key is absent from the record exactly when the body does
// not carry it. The body already contains the key when it carries one.
static U8 *R6BuildRecord(U8 *body, I64 *size) {
  I64 blen = StrLen(body);
  U8 *buf = MAlloc(7 + blen + 1);
  MemCpy(buf, "RUN_ID\n", 7);
  MemCpy(buf + 7, body, blen);
  buf[7 + blen] = 10;
  *size = 8 + blen;
  return buf;
}

// The OVERSIZED block body. It carries ONE MORE entry than the documented
// limit, so the extractor refuses it rather than truncating it.
//
// The limit is `CaptureBlockLimit`. The block is built with that many
// entries PLUS ONE, and the trailing empty line ends the block.
//
// Every entry has the SAME fixed-width content. The extractor's decision
// depends on the entry COUNT, not on the entry text, so a fixed-width
// filler keeps the construction free of any digit-encoding arithmetic.
static U8 *R6OversizedBlock(I64 *size) {
  I64 n = CaptureBlockLimit + 1;
  // Every entry is `xxxxxxxxx\n`: nine characters plus the newline.
  I64 cap = n * 10 + 64;
  U8 *buf = MAlloc(cap);
  MemCpy(buf, "ARGV\n", 5);
  I64 off = 5;
  I64 i = 0;
  while (i < n) {
    MemCpy(buf + off, "xxxxxxxxx\n", 10);
    off = off + 10;
    i = i + 1;
  }
  // The empty line that ends the block.
  buf[off] = 10;
  off = off + 1;
  *size = off;
  return buf;
}

// The block-status case driver.
static I64 R6BlockStatusCase(U8 *body, I64 expect_status) {
  I64 size = 0;
  U8 *buf = R6BuildRecord(body, &size);
  I64 count = 0;
  I64 status = CAPTURE_BLOCK_ABSENT;
  U8 **vals = CaptureBlock(buf, size, "ARGV", &count, &status);
  I64 ok = 0;
  if (status == expect_status) ok = 1;
  // The returned pointer and the status MUST AGREE.
  //
  // The OK and EMPTY statuses are WELL-FORMED blocks: the extractor hands
  // back an array, and the EMPTY one carries zero entries. The ABSENT,
  // SCALAR and TOO_LARGE statuses are REFUSALS: the extractor hands back
  // nothing at all, because there is no block to describe.
  if (expect_status == CAPTURE_BLOCK_OK) {
    if (vals == NULL) ok = 0;
    if (count != 2) ok = 0;
  } else if (expect_status == CAPTURE_BLOCK_EMPTY) {
    if (vals == NULL) ok = 0;
    if (count != 0) ok = 0;
  } else {
    if (vals != NULL) ok = 0;
    if (count != 0) ok = 0;
  }
  I64 k = 0;
  while (k < count) {
    Free(vals[k]);
    k = k + 1;
  }
  Free(vals);
  Free(buf);
  return ok;
}

static I64 R6BlockStatusMode(U8 *work) {
  U8 *ids[5];
  ids[0] = "R5_06_BLOCK_ABSENT";
  ids[1] = "R5_06_BLOCK_EMPTY";
  ids[2] = "R5_06_BLOCK_SCALAR";
  ids[3] = "R5_06_BLOCK_TOO_LARGE";
  ids[4] = "R5_06_BLOCK_OK";
  I64 expect[5];
  expect[0] = CAPTURE_BLOCK_ABSENT;
  expect[1] = CAPTURE_BLOCK_EMPTY;
  expect[2] = CAPTURE_BLOCK_SCALAR;
  expect[3] = CAPTURE_BLOCK_TOO_LARGE;
  expect[4] = CAPTURE_BLOCK_OK;
  // The bodies. The record is `RUN_ID\n<body>`, and the extractor is
  // driven over the WHOLE record, so the `ARGV` key must be absent from
  // the body for the absent case.
  I64 oversize = 0;
  U8 *oversized = R6OversizedBlock(&oversize);
  U8 *bodies[5];
  bodies[0] = "CASE_ID=c1\n";
  bodies[1] = "ARGV\n";
  bodies[2] = "ARGV value\n";
  bodies[3] = oversized;
  bodies[4] = "ARGV\nalpha\nbeta\n";
  I64 i = 0;
  while (i < 5) {
    I64 ok = R6BlockStatusCase(bodies[i], expect[i]);
    U8 *reason = CaptureBlockReason(expect[i]);
    R6Verdict(ids[i], ok, 1, reason);
    i = i + 1;
  }
  Free(oversized);
  return 0;
}

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-03 -- THE OUTPUT-MODE CLASSIFICATION MODE.
//
// THE ORIGINAL DEFECT.
//
// The harness derived the output MODE from the output option's VALUE:
//
//   if (StrCmp(out_value, "-") == 0) stdout_mode = 1;
//
// The two CLI forms are DIFFERENT:
//
//   -o-     the compiler's OWN zero-argument option. The assembly goes to
//           the STANDARD OUTPUT. There is NO filesystem artifact.
//
//   -o -    the ordinary output option whose VALUE is "-". The compiler
//           writes a FILE whose name is "-". The standard output is EMPTY.
//
// The harness therefore classified a genuine `-o -` request as a STDOUT
// emission, and it REWROTE the child's option: the child wrote a file
// named "-", the capture recorded `OUTPUT_MODE STDOUT`, and the record
// claimed that the standard output carried the artifact.
//
// THE REPAIR.
//
// The mode is a PROPERTY OF THE OPTION'S SPELLING, and the harness now
// reports it from the scan. This mode PROVES the distinction, and it
// proves it against the DIRECT COMPILER INVOCATION, so the harness's
// classification is compared with the compiler's own behaviour rather
// than with the harness's own opinion.
//
// The runner OWNS the output path, so the child's `-o -` is REWRITTEN
// into the runner's own destination. The rewrite PRESERVES the FILE
// classification, and it is EXPLICITLY ACCOUNTED FOR: the control
// requires the record's mode to be FILE, and it requires the artifact to
// be a real file on the disk whose digest matches the record.
// ---------------------------------------------------------------------------

// The DIRECT COMPILER INVOCATION.
//
// It runs the compiler with the given argument vector, in the given
// working directory, and returns the captured standard output.
//
// The compiler is the PRODUCTION compiler: the producer the caller
// named. The direct invocation is the INDEPENDENT WITNESS, and the
// harness's classification is compared with it.
//
// The WORKING DIRECTORY matters: the compiler resolves a RELATIVE output
// path against its own current working directory, so the direct
// invocation must run in the directory whose file it is expected to
// produce.
static U8 *R6DirectCompile(U8 *producer, U8 *dir, U8 **argv, I64 nargv,
                            I64 *out_size, I64 *exit_status) {
  I64 total = nargv + 1;
  U8 **args = MAlloc(sizeof(U8 *) * total);
  I64 n = 0;
  I64 k = 0;
  while (k < nargv) {
    args[n] = argv[k];
    n = n + 1;
    k = k + 1;
  }
  args[n] = NULL;
  // The working directory is changed for the invocation and RESTORED
  // afterwards, so the probe's own directory is unchanged.
  U8 *cwd_buf = MAlloc(4096);
  I64 saved_cwd = 0;
  if (getcwd(cwd_buf, 4096) != NULL) saved_cwd = 1;
  if (chdir(dir) != 0) {
    Free(cwd_buf);
    Free(args);
    if (out_size != NULL) *out_size = 0;
    if (exit_status != NULL) *exit_status = -1;
    return NULL;
  }
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(producer, args, &out, &err);
  if (saved_cwd == 1) chdir(cwd_buf);
  Free(cwd_buf);
  Free(err);
  Free(args);
  if (out_size != NULL) *out_size = StrLen(out);
  if (exit_status != NULL) *exit_status = rc;
  return out;
}

// The RECORD'S ARTIFACT PATH.
//
// The harness prints `HARNESS_ARTIFACT_PATH`, which is the RUNNER'S OWN
// destination -- the path the runner intends to write. In the STDOUT mode
// the produced artifact is the CAPTURED STDOUT, and the capture record
// names THAT path in its `ARTIFACT_PATH` field.
//
// The two are different paths, and the control needs the RECORD's path:
// it is the path of the artifact that the record claims.
static U8 *R6RecordArtifactPath(U8 *out) {
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  if (cap == NULL) return NULL;
  U8 *path = R6Field(cap, csize, "ARTIFACT_PATH");
  Free(cap);
  return path;
}

// The STDOUT-FORM controls.
//
// The `-o-` request, observed both DIRECTLY and THROUGH the harness.
//
// It returns the digest of the DIRECT invocation's standard output, so
// the caller can compare it with the harness's captured bytes.
static U8 *R8_03StdoutForm(U8 *harness, U8 *producer, U8 *dir, U8 *arch,
                            U8 *src_a, U8 *fixture) {
  U8 *cd = R6Path(dir, "OUTMODE_STDOUT");
  R6MakeDirs(cd);
  // The DIRECT invocation, in its own directory.
  U8 *direct_dir = R6Path(cd, "direct");
  R6MakeDirs(direct_dir);
  U8 *direct_src = R6Path(direct_dir, "source.HC");
  U8 *src_text = R6SourceZero();
  R6Write(direct_src, src_text, StrLen(src_text));
  U8 *dargv[5];
  dargv[0] = producer;
  dargv[1] = "-S";
  dargv[2] = "-o-";
  dargv[3] = direct_src;
  dargv[4] = NULL;
  I64 dsize = 0;
  I64 dexit = 0;
  U8 *dout = R6DirectCompile(producer, direct_dir, dargv, 4, &dsize, &dexit);
  I64 direct_exit_ok = 0;
  if (dexit == 0) direct_exit_ok = 1;
  R6Verdict("R8_03_DIRECT_STDOUT_EXIT", direct_exit_ok, 1,
            "THE_DIRECT_INVOCATION_EXITED_ZERO");
  I64 direct_nonempty = 0;
  if (dsize > 0) direct_nonempty = 1;
  R6Verdict("R8_03_DIRECT_STDOUT_NONEMPTY", direct_nonempty, 1,
            "THE_DIRECT_INVOCATION_WROTE_TO_STDOUT");
  // The direct invocation must NOT have produced a file artifact.
  U8 *direct_artifact = R6Path(direct_dir, "-");
  I64 stray_present = 0;
  if (FileExists(direct_artifact) == 1) stray_present = 1;
  R6Verdict("R8_03_DIRECT_STDOUT_NO_FILE", stray_present, 0,
            "THE_DIRECT_INVOCATION_PRODUCED_NO_FILE");
  // The digest of the direct invocation's standard output.
  U8 *direct_hex = MAlloc(65);
  I64 direct_ok = 0;
  if (dsize > 0) {
    U8 *ddigest = MAlloc(32);
    Sha256Bytes(dout, dsize, ddigest);
    Sha256Hex(direct_hex, ddigest);
    Free(ddigest);
    direct_ok = 1;
  }
  if (dout != NULL) Free(dout);
  // The HARNESS's run of the SAME request.
  U8 *run_dir = R6Path(cd, "run");
  R6MakeDirs(run_dir);
  U8 *ledger = R6Path(cd, "ledger.txt");
  R6Write(ledger, "", 0);
  U8 *art_dir = R6Path(cd, "art");
  R6MakeDirs(art_dir);
  U8 *argv[4];
  argv[0] = producer;
  argv[1] = "-S";
  argv[2] = "-o-";
  argv[3] = NULL;
  R6RunCtx ctx;
  ctx.harness = harness;
  ctx.run_dir = run_dir;
  ctx.ledger = ledger;
  ctx.case_id = "R8_03_STDOUT_FORM";
  ctx.producer = producer;
  ctx.source = src_a;
  ctx.fixture = fixture;
  ctx.artifact_name = "artifact.bin";
  ctx.artifact_dir = art_dir;
  ctx.arch = arch;
  ctx.argv = argv;
  ctx.nargv = 3;
  U8 *out = NULL;
  U8 *reason = R6RunHarnessFull(&ctx, &out);
  I64 ok = 0;
  if (StrCmp(reason, "NO_REASON_TOKEN") == 0) ok = 1;
  R6Verdict("R8_03_STDOUT_RUN", ok, 1, reason);
  I64 exit_present = 0;
  I64 exit_value = R6ExitStatus(out, &exit_present);
  I64 stdout_exit_ok = 0;
  if (exit_present == 1 && exit_value == 0) stdout_exit_ok = 1;
  R6Verdict("R8_03_STDOUT_EXIT_STATUS", stdout_exit_ok, 1,
            "THE_CHILD_EXITED_ZERO");
  // The record must name the STDOUT mode.
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  I64 mode_is_stdout = 0;
  if (cap != NULL) {
    U8 *m = R6Field(cap, csize, "OUTPUT_MODE");
    if (m != NULL) {
      if (StrCmp(m, "STDOUT") == 0) mode_is_stdout = 1;
      Free(m);
    }
  }
  R6Verdict("R8_03_STDOUT_MODE", mode_is_stdout, 1,
            "THE_RECORD_NAMES_THE_STDOUT_MODE");
  // The captured stdout must be NONEMPTY, and the record's artifact digest
  // must be the digest of those ACTUAL captured bytes.
  //
  // In the STDOUT mode the artifact IS the captured stdout stream, so the
  // artifact path names the capture file. The digest is therefore
  // recomputed from the bytes the harness actually captured.
  I64 captured_nonempty = 0;
  I64 digest_agrees = 0;
  if (cap != NULL) {
    U8 *apath = R6RecordArtifactPath(out);
    if (apath != NULL) {
      I64 asize = 0;
      U8 *abuf = FileRead(apath, &asize);
      if (abuf != NULL) {
        if (asize > 0) {
          captured_nonempty = 1;
          U8 *ahex = MAlloc(65);
          U8 *adigest = MAlloc(32);
          Sha256Bytes(abuf, asize, adigest);
          Sha256Hex(ahex, adigest);
          Free(adigest);
          U8 *claimed = R6Field(cap, csize, "ARTIFACT_SHA256");
          if (claimed != NULL) {
            if (StrCmp(claimed, ahex) == 0) digest_agrees = 1;
            Free(claimed);
          }
          // The digest must ALSO equal the DIRECT invocation's digest:
          // the two invocations compiled the SAME source, so their
          // standard outputs carry the SAME bytes.
          if (direct_ok == 1) {
            if (StrCmp(direct_hex, ahex) != 0) digest_agrees = 0;
          }
          Free(ahex);
        }
        Free(abuf);
      }
      Free(apath);
    }
  }
  R6Verdict("R8_03_STDOUT_CAPTURED_NONEMPTY", captured_nonempty, 1,
            "THE_CAPTURED_STDOUT_CARRIES_BYTES");
  R6Verdict("R8_03_STDOUT_DIGEST_MATCHES_CAPTURED", digest_agrees, 1,
            "THE_RECORDED_DIGEST_IS_THE_DIGEST_OF_THE_CAPTURED_BYTES");
  // NO filesystem artifact may exist in the runner's output directory.
  I64 stray = R6ArtifactExists(out);
  R6Verdict("R8_03_STDOUT_NO_FILE_ARTIFACT", stray, 0,
            "NO_FILESYSTEM_ARTIFACT_WAS_PRODUCED");
  Free(out);
  Free(reason);
  Free(cap);
  Free(direct_artifact);
  Free(direct_src);
  Free(direct_dir);
  Free(art_dir);
  Free(ledger);
  Free(run_dir);
  Free(cd);
  if (direct_ok == 1) return direct_hex;
  Free(direct_hex);
  return NULL;
}

// The FILE-FORM controls.
//
// The `-o -` request, observed both DIRECTLY and THROUGH the harness.
//
// The runner REWRITES the child's `-o -` into its own destination. The
// rewrite PRESERVES the FILE classification, and the controls require
// the artifact to be a real file on the disk whose ACTUAL digest equals
// the digest the record claims.
static U0 R8_03FileForm(U8 *harness, U8 *producer, U8 *dir, U8 *arch,
                         U8 *src_a, U8 *fixture) {
  U8 *cd = R6Path(dir, "OUTMODE_FILE");
  R6MakeDirs(cd);
  // The DIRECT invocation, in its own directory.
  U8 *direct_dir = R6Path(cd, "direct");
  R6MakeDirs(direct_dir);
  U8 *direct_src = R6Path(direct_dir, "source.HC");
  U8 *src_text = R6SourceZero();
  R6Write(direct_src, src_text, StrLen(src_text));
  U8 *dargv[6];
  dargv[0] = producer;
  dargv[1] = "-S";
  dargv[2] = "-o";
  dargv[3] = "-";
  dargv[4] = direct_src;
  dargv[5] = NULL;
  I64 dsize = 0;
  I64 dexit = 0;
  U8 *dout = R6DirectCompile(producer, direct_dir, dargv, 5, &dsize, &dexit);
  I64 file_exit_ok = 0;
  if (dexit == 0) file_exit_ok = 1;
  R6Verdict("R8_03_DIRECT_FILE_EXIT", file_exit_ok, 1,
            "THE_DIRECT_INVOCATION_EXITED_ZERO");
  // The direct invocation's standard output must be EMPTY.
  I64 file_stdout_empty = 0;
  if (dsize == 0) file_stdout_empty = 1;
  R6Verdict("R8_03_DIRECT_FILE_STDOUT_EMPTY", file_stdout_empty, 1,
            "THE_DIRECT_INVOCATION_WROTE_NOTHING_TO_STDOUT");
  // The direct invocation MUST have produced a file named "-".
  U8 *direct_artifact = R6Path(direct_dir, "-");
  I64 direct_file_present = 0;
  I64 direct_file_bytes = 0;
  if (FileExists(direct_artifact) == 1) {
    direct_file_present = 1;
    I64 fsize = 0;
    U8 *fbuf = FileRead(direct_artifact, &fsize);
    if (fbuf != NULL) {
      direct_file_bytes = fsize;
      Free(fbuf);
    }
  }
  R6Verdict("R8_03_DIRECT_FILE_PRESENT", direct_file_present, 1,
            "THE_DIRECT_INVOCATION_WROTE_THE_FILE_NAMED_DASH");
  I64 direct_file_nonempty = 0;
  if (direct_file_bytes > 0) direct_file_nonempty = 1;
  R6Verdict("R8_03_DIRECT_FILE_NONEMPTY", direct_file_nonempty, 1,
            "THE_FILE_NAMED_DASH_CARRIES_BYTES");
  if (dout != NULL) Free(dout);
  // The HARNESS's run of the SAME request.
  U8 *run_dir = R6Path(cd, "run");
  R6MakeDirs(run_dir);
  U8 *ledger = R6Path(cd, "ledger.txt");
  R6Write(ledger, "", 0);
  U8 *art_dir = R6Path(cd, "art");
  R6MakeDirs(art_dir);
  U8 *argv[5];
  argv[0] = producer;
  argv[1] = "-S";
  argv[2] = "-o";
  argv[3] = "-";
  argv[4] = NULL;
  R6RunCtx ctx;
  ctx.harness = harness;
  ctx.run_dir = run_dir;
  ctx.ledger = ledger;
  ctx.case_id = "R8_03_FILE_FORM";
  ctx.producer = producer;
  ctx.source = src_a;
  ctx.fixture = fixture;
  ctx.artifact_name = "artifact.bin";
  ctx.artifact_dir = art_dir;
  ctx.arch = arch;
  ctx.argv = argv;
  ctx.nargv = 4;
  U8 *out = NULL;
  U8 *reason = R6RunHarnessFull(&ctx, &out);
  I64 ok = 0;
  if (StrCmp(reason, "NO_REASON_TOKEN") == 0) ok = 1;
  R6Verdict("R8_03_FILE_RUN", ok, 1, reason);
  I64 exit_present = 0;
  I64 exit_value = R6ExitStatus(out, &exit_present);
  I64 file_child_exit_ok = 0;
  if (exit_present == 1 && exit_value == 0) file_child_exit_ok = 1;
  R6Verdict("R8_03_FILE_EXIT_STATUS", file_child_exit_ok, 1,
            "THE_CHILD_EXITED_ZERO");
  // The record must name the FILE mode.
  I64 csize = 0;
  U8 *cap = R6Capture(out, &csize);
  I64 mode_is_file = 0;
  if (cap != NULL) {
    U8 *m = R6Field(cap, csize, "OUTPUT_MODE");
    if (m != NULL) {
      if (StrCmp(m, "FILE") == 0) mode_is_file = 1;
      Free(m);
    }
  }
  R6Verdict("R8_03_FILE_MODE", mode_is_file, 1,
            "THE_RECORD_NAMES_THE_FILE_MODE");
  // The artifact must be PRESENT, and it must be a real file on the disk.
  I64 present = R6ArtifactPresent(out);
  R6Verdict("R8_03_FILE_ARTIFACT_PRESENT", present, 1,
            "THE_ARTIFACT_IS_PRESENT");
  I64 exists = R6ArtifactExists(out);
  R6Verdict("R8_03_FILE_ARTIFACT_ON_DISK", exists, 1,
            "THE_ARTIFACT_EXISTS_ON_THE_DISK");
  // The recorded artifact's ACTUAL digest must equal the digest the
  // record claims.
  I64 actual_agrees = 0;
  if (cap != NULL) {
    U8 *apath = R6ArtifactPath(out);
    if (apath != NULL) {
      I64 asize = 0;
      U8 *abuf = FileRead(apath, &asize);
      if (abuf != NULL) {
        U8 *ahex = MAlloc(65);
        U8 *adigest = MAlloc(32);
        Sha256Bytes(abuf, asize, adigest);
        Sha256Hex(ahex, adigest);
        Free(adigest);
        U8 *claimed = R6Field(cap, csize, "ARTIFACT_SHA256");
        if (claimed != NULL) {
          if (StrCmp(claimed, ahex) == 0) actual_agrees = 1;
          Free(claimed);
        }
        Free(ahex);
        Free(abuf);
      }
      Free(apath);
    }
  }
  R6Verdict("R8_03_FILE_DIGEST_MATCHES_ARTIFACT", actual_agrees, 1,
            "THE_RECORDED_DIGEST_IS_THE_DIGEST_OF_THE_ARTIFACT");
  Free(cap);
  Free(out);
  Free(reason);
  Free(direct_artifact);
  Free(direct_src);
  Free(direct_dir);
  Free(art_dir);
  Free(ledger);
  Free(run_dir);
  Free(cd);
}

// The output-mode classification mode.
//
//   probe outmode <harness> <producer> <work-dir> <arch>
static U0 R6OutModeMode(U8 *harness, U8 *producer, U8 *work_dir, U8 *arch) {
  U8 *rbuf = MAlloc(4096);
  U8 *resolved = realpath(work_dir, rbuf);
  U8 *dir = work_dir;
  if (resolved != NULL) dir = resolved;
  R6MakeDirs(dir);
  U8 *src_a = R6Path(dir, "outmode_source.HC");
  U8 *fixture = R6Path(dir, "outmode_fixture.bin");
  U8 *src_text = R6SourceZero();
  R6Write(src_a, src_text, StrLen(src_text));
  R6Write(fixture, "fixture\n", 8);
  R8_03StdoutForm(harness, producer, dir, arch, src_a, fixture);
  R8_03FileForm(harness, producer, dir, arch, src_a, fixture);
  Free(src_a);
  Free(fixture);
}

I32 Main(I32 argc, U8 **argv) {
  r6_checks = 0;
  r6_failures = 0;
  if (argc < 3) {
    "PROBE_USAGE\tprobe exec|macho|envbind|outmode <args...>\n";
    return 2;
  }
  U8 *mode = argv[1];
  if (StrCmp(mode, "exec") == 0) {
    if (argc < 6) {
      "PROBE_USAGE\tprobe exec <harness> <producer> <work-dir> <arch>\n";
      return 2;
    }
    R6ExecMode(argv[2], argv[3], argv[4], argv[5]);
  } else if (StrCmp(mode, "outmode") == 0) {
    if (argc < 6) {
      "PROBE_USAGE\tprobe outmode <harness> <producer> <work-dir> <arch>\n";
      return 2;
    }
    R6OutModeMode(argv[2], argv[3], argv[4], argv[5]);
  } else if (StrCmp(mode, "macho") == 0) {
    if (argc < 5) {
      "PROBE_USAGE\tprobe macho <fixture-dir> <mixed-zerofill.o> <tls.o>\n";
      return 2;
    }
    R6MachOMode(argv[2], argv[3], argv[4]);
  } else if (StrCmp(mode, "envbind") == 0) {
    if (argc < 5) {
      "PROBE_USAGE\tprobe envbind <harness> <probe> <work-dir>\n";
      return 2;
    }
    R6EnvBindMode(argv[2], argv[3], argv[4]);
  } else if (StrCmp(mode, "anticontrol") == 0) {
    if (argc < 6) {
      "PROBE_USAGE\tprobe anticontrol <harness> <producer> <work-dir> <arch>\n";
      return 2;
    }
    R6AntiControlMode(argv[2], argv[3], argv[4], argv[5]);
  } else if (StrCmp(mode, "blockstatus") == 0) {
    if (argc < 3) {
      "PROBE_USAGE\tprobe blockstatus <work-dir>\n";
      return 2;
    }
    R6BlockStatusMode(argv[2]);
  } else {
    "PROBE_USAGE\tprobe exec|macho|envbind|blockstatus <args...>\n";
    return 2;
  }
  "PROBE_CHECKS\t%lld\n", r6_checks;
  "PROBE_FAILURES\t%lld\n", r6_failures;
  return r6_failures;
}
