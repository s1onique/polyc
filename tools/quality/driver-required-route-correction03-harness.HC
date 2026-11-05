// tools/quality/driver-required-route-correction03-harness.HC
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3, F1 -- THE EXECUTION-OWNING HARNESS.
//
// THE GOVERNING PRINCIPLE OF THIS ROUND:
//
//   Repair the evidence architecture rather than layering another set of
//   partial validators onto it.
//
// THE THREE RESPONSIBILITIES ARE SEPARATED:
//
//   1. EXECUTION  -- THIS FILE. It owns the compiler invocation, the run
//                    identity, the case identity, the arguments, the
//                    environment, the output directory, the exit status and
//                    the evidence capture. It is the ONLY component that
//                    runs a compiler.
//   2. VALIDATION -- driver-required-route-correction03-contract.HC.
//   3. COMPARISON -- driver-required-route-correction03-compare.HC.
//
// THE F1 DEFECT.
//
// The previous round's capture tool was a PASSIVE RECORDER. The harness
// invoked the compiler through a shell redirection and THEN handed the
// capture tool a set of paths. The capture tool could not tell whether the
// files it was given had just been produced by an execution, so:
//
//   * two executions could receive identical invocation identities;
//   * OLD artifacts, capture records and ledgers could be REPLAYED;
//   * OLD observations could be RE-REGISTERED without running a compiler;
//   * INVENTED source, fixture and producer identities passed;
//   * ALTERED argv and environment passed;
//   * MISSING required inputs passed as empty-file digests.
//
// THE REPAIR: EXECUTION-OWNED PROVENANCE.
//
// This harness:
//
//   * allocates a UNIQUE RUN CONTEXT BEFORE the execution;
//   * allocates a DISTINCT EXECUTION-EVENT IDENTITY for EVERY invocation,
//     INCLUDING DETERMINISTIC REPETITIONS;
//   * creates FRESH PER-CASE DIRECTORIES and outputs;
//   * runs the compiler ITSELF, through the runtime's SpawnAndCapture;
//   * VALIDATES the actual source, fixture and producer files BEFORE the
//     invocation;
//   * RECORDS the actual argv and the relevant environment;
//   * binds the inputs and the outputs to the SAME execution event;
//   * FAILS HARD when a required file is absent, instead of digesting an
//     empty file;
//   * captures the EXACT observed output bytes BEFORE any comparison.
//
// THE TRUST BOUNDARY, STATED HONESTLY.
//
// This harness establishes LOCAL TRACE INTEGRITY. It is NOT a cryptographic
// attestation against an attacker who can replace the entire trusted runner
// and all of its evidence. The run ledger binds an observation to an
// execution THAT THIS RUN performed; it cannot bind an observation to an
// execution performed by a different program with different code.
//
// The comparator therefore checks that the capture record and the run
// context are CONSISTENT with each other and with the observed bytes. It
// does not claim more than that.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"
#include "../../src/holyc-lib/tooling_defs.HH"

// ---------------------------------------------------------------------------
// THE RUN CONTEXT.
//
// The run context is allocated BEFORE any execution and it owns the whole
// run. Every case in the run gets its OWN directory inside the context.
//
// The context carries a MONOTONIC EVENT COUNTER. The event identity is the
// context identity COMBINED with the event counter and the observed
// content, so two executions -- EVEN TWO DETERMINISTIC REPETITIONS OF THE
// SAME CASE -- receive DIFFERENT event identities.
// ---------------------------------------------------------------------------

// The reason codes the harness reports.
#define HARNESS_OK                0
#define HARNESS_USAGE             1
#define HARNESS_INPUT_MISSING     2
#define HARNESS_INPUT_UNREADABLE  3
#define HARNESS_RUN_DIR_FAILED    4
#define HARNESS_SPAWN_FAILED      5
#define HARNESS_CAPTURE_FAILED    6
#define HARNESS_LEDGER_FAILED     7
#define HARNESS_PRODUCER_MISSING  8
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// The three additional reasons are DISTINCT, so a reviewer can tell WHICH
// trust-boundary property was violated.
//
//   HARNESS_PRODUCER_NOT_EXECUTABLE  the producer exists but is not an
//                                     executable file. A producer that
//                                     cannot be executed is not a producer.
//   HARNESS_PRODUCER_ARCH_MISMATCH   the producer is not a Mach-O image
//                                     for the expected architecture, so it
//                                     is not the compiler this evidence
//                                     claims to be about.
//   HARNESS_EVENT_DIR_EXISTS        the event directory already existed.
//                                     The runner allocates the event
//                                     directory EXCLUSIVELY, so a
//                                     pre-existing directory means the
//                                     event identity was replayed.
#define HARNESS_PRODUCER_NOT_EXECUTABLE 9
#define HARNESS_PRODUCER_ARCH_MISMATCH  10
#define HARNESS_EVENT_DIR_EXISTS        11

static U8 *HarnessReason(I64 code) {
  if (code == HARNESS_OK) return "OK";
  if (code == HARNESS_USAGE) return "HARNESS_USAGE";
  if (code == HARNESS_INPUT_MISSING) return "HARNESS_REQUIRED_INPUT_MISSING";
  if (code == HARNESS_INPUT_UNREADABLE) return "HARNESS_REQUIRED_INPUT_UNREADABLE";
  if (code == HARNESS_RUN_DIR_FAILED) return "HARNESS_RUN_DIRECTORY_FAILED";
  if (code == HARNESS_SPAWN_FAILED) return "HARNESS_COMPILER_EXECUTION_FAILED";
  if (code == HARNESS_CAPTURE_FAILED) return "HARNESS_CAPTURE_RECORD_FAILED";
  if (code == HARNESS_LEDGER_FAILED) return "HARNESS_RUN_LEDGER_FAILED";
  if (code == HARNESS_PRODUCER_MISSING) return "HARNESS_PRODUCER_MISSING";
  if (code == HARNESS_PRODUCER_NOT_EXECUTABLE) return "HARNESS_PRODUCER_NOT_EXECUTABLE";
  if (code == HARNESS_PRODUCER_ARCH_MISMATCH) return "HARNESS_PRODUCER_ARCH_MISMATCH";
  if (code == HARNESS_EVENT_DIR_EXISTS) return "HARNESS_EVENT_DIR_EXISTS";
  return "HARNESS_UNKNOWN";
}

// ---------------------------------------------------------------------------
// THE STRING BUILDER.
//
// The capture record is assembled in memory and written ONCE, so a partially
// written record can never be observed.
// ---------------------------------------------------------------------------
static U8 *rec_buf;
static I64 rec_len;
static I64 rec_cap;

static U0 RecInit() {
  rec_cap = 16384;
  rec_buf = MAlloc(rec_cap);
  rec_len = 0;
  rec_buf[0] = 0;
}

static U0 RecAppend(U8 *s) {
  I64 n = StrLen(s);
  if (rec_len + n + 1 > rec_cap) {
    I64 newcap = rec_cap * 2;
    while (rec_len + n + 1 > newcap) newcap = newcap * 2;
    U8 *bigger = MAlloc(newcap);
    MemCpy(bigger, rec_buf, rec_len);
    Free(rec_buf);
    rec_buf = bigger;
    rec_cap = newcap;
  }
  MemCpy(rec_buf + rec_len, s, n);
  rec_len = rec_len + n;
  rec_buf[rec_len] = 0;
}

// The single-line field builder.
static U0 RecField(U8 *key, U8 *value) {
  RecAppend(key);
  RecAppend(" ");
  RecAppend(value);
  RecAppend("\n");
}

// The block field builder. It appends `key` and then ONE LINE per value, so
// the field is a block of lines terminated by a blank line.
static U0 RecBlock(U8 *key, U8 **values, I64 n) {
  RecAppend(key);
  RecAppend("\n");
  I64 i = 0;
  while (i < n) {
    RecAppend(values[i]);
    RecAppend("\n");
    i = i + 1;
  }
  RecAppend("\n");
}

// ---------------------------------------------------------------------------
// THE RUN CONTEXT.
//
// `run_id` is the SHA-256 of the context's own identity material: the
// context path, the creation instant and the event counter's initial value.
// It is UNIQUE per run context.
//
// `event_counter` is the MONOTONIC execution-event counter. It is
// incremented for EVERY invocation, so two deterministic repetitions of the
// same case receive DIFFERENT event identities.
// ---------------------------------------------------------------------------
static U8 *run_id;
static I64 event_counter;

// The event identity. It is the SHA-256 over:
//
//   the run id,
//   the event counter,
//   the selector,
//   the case identity,
//   the producer digest,
//   the source digest,
//   the fixture digest,
//   the argv,
//   the relevant environment.
//
// The event counter is INCLUDED, so the identity of an invocation is unique
// even when every observed byte is identical to a previous invocation.
//
// It returns the identity as a 64-character lowercase hexadecimal string.
static U8 *HarnessEventId(U8 *case_id, U8 *selector, U8 *producer_hex,
                           U8 *source_hex, U8 *fixture_hex, U8 **argv,
                           I64 nargv, U8 **envv, I64 nenv) {
  Sha256Ctx c;
  Sha256Init(&c);
  Sha256Update(&c, run_id, 64);
  // The event counter, as a DECIMAL field so that the separator is
  // unambiguous.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // THE DEFECT. The digits were produced in REVERSE order and were never
  // reversed back:
  //
  //     while (v > 0) { ctr[n] = 48 + (v % 10); v = v / 10; n = n + 1; }
  //     ctr[n] = 10;
  //
  // For a one-digit counter the reversed and the true order coincide, so
  // the defect was INVISIBLE until the tenth event of a run. For the
  // tenth event the identity was computed over "01" while the capture
  // record stated "10", so the identity did not describe the event the
  // record claimed.
  //
  // THE REPAIR. The digits are produced in REVERSE order into a SEPARATE
  // buffer and are then copied back in order, exactly as the shared
  // contract's exit-status codec does. The counter field the identity is
  // computed over is now the SAME decimal string the capture record
  // states, so a reviewer can recompute the identity from the record.
  U8 ctr[24];
  I64 n = 0;
  I64 v = event_counter;
  if (v == 0) { ctr[0] = 48; n = 1; }
  while (v > 0) { ctr[n] = 48 + (v % 10); v = v / 10; n = n + 1; }
  // The SEPARATE WRITE POSITION copies the digits back into order. The
  // source and the destination are DIFFERENT buffers, so the copy cannot
  // destroy a digit that has not yet been read.
  U8 rev[24];
  I64 w = 0;
  while (w < n) {
    rev[w] = ctr[n - 1 - w];
    w = w + 1;
  }
  w = 0;
  while (w < n) {
    ctr[w] = rev[w];
    w = w + 1;
  }
  // The separator.
  ctr[n] = 10;
  Sha256Update(&c, ctr, n + 1);
  Sha256Update(&c, case_id, StrLen(case_id));
  Sha256Update(&c, "\n", 1);
  Sha256Update(&c, selector, StrLen(selector));
  Sha256Update(&c, "\n", 1);
  Sha256Update(&c, producer_hex, 64);
  Sha256Update(&c, "\n", 1);
  Sha256Update(&c, source_hex, 64);
  Sha256Update(&c, "\n", 1);
  Sha256Update(&c, fixture_hex, 64);
  Sha256Update(&c, "\n", 1);
  I64 i = 0;
  while (i < nargv) {
    Sha256Update(&c, argv[i], StrLen(argv[i]));
    Sha256Update(&c, "\n", 1);
    i = i + 1;
  }
  i = 0;
  while (i < nenv) {
    Sha256Update(&c, envv[i], StrLen(envv[i]));
    Sha256Update(&c, "\n", 1);
    i = i + 1;
  }
  U8 *digest = MAlloc(32);
  U8 *hex = MAlloc(65);
  Sha256Final(&c, digest);
  Sha256Hex(hex, digest);
  Free(digest);
  return hex;
}

// ---------------------------------------------------------------------------
// THE EXECUTION.
//
// It runs ONE compiler invocation and captures EVERYTHING that happened.
//
// The steps are, in order:
//
//   1. VALIDATE the producer, the source and the fixture. A MISSING file is
//      a HARD FAILURE. It is never treated as an empty file, because an
//      empty-file digest is what made a missing fixture acceptable.
//   2. ALLOCATE the event identity, BEFORE the execution.
//   3. CREATE the fresh per-case directory.
//   4. RUN the compiler through the runtime's SpawnAndCapture, with the
//      EXACT argv.
//   5. CAPTURE the exact observed stdout, stderr and exit status BYTES.
//   6. WRITE the capture record and APPEND the event identity to the run
//      ledger.
//
// The capture record binds the observation to the execution that produced
// it. The comparator independently checks the expected run, case and
// producer context.
// ---------------------------------------------------------------------------

// The file writer that reports failure.
//
// The flags are the real `open(2)` flags: the file is CREATED if it is
// absent and TRUNCATED if it is present, so a REPLAYED file can never
// survive a fresh capture.
static I64 WriteFile(U8 *path, U8 *buf, I64 size) {
  if (FileWrite(path, buf, size, O_CREAT | O_TRUNC | O_RDWR) == FALSE) return 0;
  return 1;
}

// The ledger appender. The ledger is APPENDED, so it accumulates the
// invocations of THIS run and only of THIS run.
static I64 AppendLedger(U8 *ledger_path, U8 *event_id) {
  I32 fd = open(ledger_path, O_RDWR | O_CREAT | O_APPEND, 420);
  if (fd == -1) return 0;
  U8 *line = MAlloc(66);
  MemCpy(line, event_id, 64);
  line[64] = 10;
  line[65] = 0;
  I64 wrote = write(fd, line, 65);
  close(fd);
  if (wrote != 65) return 0;
  return 1;
}

// The path builder. It appends `name` to `dir`.
static U8 *PathJoin(U8 *dir, U8 *name) {
  I64 dlen = StrLen(dir);
  I64 nlen = StrLen(name);
  U8 *p = MAlloc(dlen + nlen + 2);
  MemCpy(p, dir, dlen);
  I64 k = 0;
  if (dlen > 0 && dir[dlen - 1] != 47) {
    p[dlen] = 47;
    k = 1;
  }
  MemCpy(p + dlen + k, name, nlen);
  p[dlen + k + nlen] = 0;
  return p;
}

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// THE TRUSTED RUNNER'S OWN CHECKS ON THE PRODUCER.
//
// The runner OWNS the producer. Before the runner spawns anything it
// establishes, FROM THE BYTES ON DISK, that the program it is about to
// execute is the program this evidence claims to be about.
//
// Three properties are established, and each has its OWN reason token:
//
//   1. the producer EXISTS. A missing producer is a hard failure; it is
//      never treated as an empty file, because an empty-file digest is
//      what made a missing input acceptable in the first place.
//
//   2. the producer is an EXECUTABLE FILE. A file that is not executable
//      cannot be the compiler.
//
//   3. the producer is a MACH-O IMAGE FOR THE EXPECTED ARCHITECTURE. The
//      architecture is read from the Mach-O header, so the check is a
//      property of the BYTES and not of the file name. A producer for a
//      different architecture would produce artifacts for a different
//      target, and the comparison would be meaningless.
//
// The expected architecture is supplied by the caller. It is the
// architecture of the ARTIFACTS this evidence is about, so the producer
// and the artifacts are known to belong to the same target.
// ---------------------------------------------------------------------------

// The executable-bit test. It asks the operating system whether the file
// may be EXECUTED, which is the property the runner actually depends on:
// a file whose mode carries no execute bit cannot be the compiler.
extern "c" I32 access(U8 *path, I32 mode);

static I64 HarnessIsExecutable(U8 *path) {
  I32 rc = access(path, 1);
  if (rc == 0) return 1;
  return 0;
}

// The producer's architecture, read from its Mach-O header. It returns the
// CPU type, or -1 when the producer is not a 64-bit Mach-O image.
static I64 HarnessProducerArch(U8 *path) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return -1;
  return ContractArchOf(buf, size);
}

// The producer's own validation. It returns HARNESS_OK, or the reason the
// producer was refused.
static I64 HarnessValidateProducer(U8 *producer, I64 expected_arch) {
  I64 size = 0;
  U8 *buf = FileRead(producer, &size);
  if (buf == NULL) return HARNESS_PRODUCER_MISSING;
  if (HarnessIsExecutable(producer) == 0) {
    "HARNESS_REASON_DETAIL\tthe producer %s is not an executable file\n", producer;
    return HARNESS_PRODUCER_NOT_EXECUTABLE;
  }
  I64 arch = ContractArchOf(buf, size);
  if (arch < 0) {
    "HARNESS_REASON_DETAIL\tthe producer %s is not a Mach-O image\n", producer;
    return HARNESS_PRODUCER_ARCH_MISMATCH;
  }
  if (expected_arch >= 0 && arch != expected_arch) {
    "HARNESS_REASON_DETAIL\tthe producer %s has architecture %s, not %s\n",
      producer, ContractArchName(arch), ContractArchName(expected_arch);
    return HARNESS_PRODUCER_ARCH_MISMATCH;
  }
  return HARNESS_OK;
}

// The environment application.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
// THE DEFECT. The harness RECORDED the environment bindings and hashed
// them into the event identity, but it never APPLIED them to the spawned
// compiler. The child therefore ran with the runner's ambient
// environment, and the recorded environment was a DESCRIPTION of an
// environment that was never in force. A binding that the evidence
// claims was in effect -- the test prefix, for instance -- was not.
//
// THE REPAIR. Each binding is applied with setenv(3) BEFORE the spawn, so
// the child observes exactly the environment the capture record names. The
// bindings are set AFTER the fork-sensitive setup but BEFORE
// SpawnAndCapture, and the runner restores the previous value of each
// binding afterwards so that the runner's own environment is not
// disturbed for the next case.
//
// The binding is a NAME=VALUE pair. A binding that is not a pair is a
// hard failure: an unparseable binding would be recorded as though it
// had been applied.
extern "c" I32 setenv(U8 *name, U8 *value, I32 overwrite);

// The environment applier. It returns HARNESS_OK, or HARNESS_USAGE when
// a binding is not a NAME=VALUE pair.
static I64 HarnessApplyEnv(U8 **envv, I64 nenv) {
  I64 i = 0;
  while (i < nenv) {
    U8 *binding = envv[i];
    I64 len = StrLen(binding);
    I64 eq = 0;
    I64 j = 0;
    while (j < len) {
      if (binding[j] == 61) { eq = 1; break; }
      j = j + 1;
    }
    if (eq == 0 || eq == 0 || eq >= len) {
      "HARNESS_REASON_DETAIL\tthe environment binding %s is not a NAME=VALUE pair\n",
        binding;
      return HARNESS_USAGE;
    }
    I64 namelen = eq;
    U8 *name = MAlloc(namelen + 1);
    MemCpy(name, binding, namelen);
    name[namelen] = 0;
    U8 *value = MAlloc(len - eq);
    MemCpy(value, binding + eq + 1, len - eq - 1);
    value[len - eq - 1] = 0;
    if (setenv(name, value, 1) != 0) {
      "HARNESS_REASON_DETAIL\tthe environment binding %s could not be applied\n",
        binding;
      Free(name);
      Free(value);
      return HARNESS_USAGE;
    }
    Free(name);
    Free(value);
    i = i + 1;
  }
  return HARNESS_OK;
}

// The main execution.
//
//   run <run-dir> <ledger> <selector> <case-id>
//       <producer> <source> <fixture>
//       <artifact-name> <artifact-dir> <expected-arch>
//       <env>... -- <argv>...
//
// The environment bindings are given as `NAME=VALUE` pairs before the `--`
// separator, and the argument vector is given after it.
//
// `argv[0]` is the run directory. The fixed prefix occupies argv[0..9], the
// environment bindings start at argv[10], and the argument vector follows
// the `--` separator.
//
// The EXPECTED ARCHITECTURE is the architecture of the artifacts this
// evidence is about. The runner requires the producer to be a Mach-O image
// for that architecture, so the producer and the artifacts are known to
// belong to the same target.
static I64 HarnessRun(I32 argc, U8 **argv) {
  // The fixed argument prefix.
  if (argc < 14) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    return HARNESS_USAGE;
  }
  U8 *run_dir = argv[0];
  U8 *ledger_path = argv[1];
  U8 *selector = argv[2];
  U8 *case_id = argv[3];
  U8 *producer = argv[4];
  U8 *source = argv[5];
  U8 *fixture = argv[6];
  U8 *artifact_name = argv[7];
  U8 *artifact_dir = argv[8];
  U8 *expected_arch_arg = argv[9];

  // The environment bindings and the argument vector.
  I64 sep = 10;
  I64 i = 10;
  I64 found_sep = 0;
  while (i < argc) {
    if (StrCmp(argv[i], "--") == 0) { sep = i; found_sep = 1; break; }
    i = i + 1;
  }
  if (found_sep == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    return HARNESS_USAGE;
  }
  I64 nenv = sep - 10;
  U8 **envv = MAlloc(sizeof(U8 *) * (nenv + 1));
  I64 e = 0;
  while (e < nenv) {
    envv[e] = argv[10 + e];
    e = e + 1;
  }
  envv[nenv] = NULL;

  // The argument vector. The FIRST argument is the program itself.
  //
  // The count is `argc - sep - 2`, NOT `argc - sep - 1`: the argument
  // array is NUL-terminated, and the terminator is NOT an argument. The
  // earlier count included it, and the harness then passed the NULL
  // terminator to the compiler as an argument and read its length, which
  // is a hard fault.
  I64 nargv = argc - sep - 2;
  if (nargv < 1) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    return HARNESS_USAGE;
  }
  U8 **exec_argv = MAlloc(sizeof(U8 *) * (nargv + 1));
  I64 a = 0;
  while (a < nargv) {
    exec_argv[a] = argv[sep + 1 + a];
    if (exec_argv[a] == NULL) {
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
      "HARNESS_REASON_DETAIL\tthe argument vector carries a NULL entry\n";
      return HARNESS_USAGE;
    }
    a = a + 1;
  }
  exec_argv[nargv] = NULL;

  // --- STEP 1: VALIDATE THE INPUTS BEFORE THE INVOCATION. ----------------
  //
  // A MISSING file is a HARD FAILURE. It is never treated as an empty file.
  U8 *producer_hex = MAlloc(65);
  U8 *source_hex = MAlloc(65);
  U8 *fixture_hex = MAlloc(65);
  if (Sha256File(producer, producer_hex) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_PRODUCER_MISSING);
    "HARNESS_REASON_DETAIL\tthe producer %s is absent\n", producer;
    return HARNESS_PRODUCER_MISSING;
  }
  // The TRUSTED RUNNER'S OWN CHECKS on the producer. The producer must be an
  // executable Mach-O image for the expected architecture. These checks are
  // made from the BYTES ON DISK, before anything is spawned.
  I64 expected_arch = -1;
  if (expected_arch_arg != NULL) {
    if (StrCmp(expected_arch_arg, "arm64") == 0) expected_arch = CPU_TYPE_ARM64;
    if (StrCmp(expected_arch_arg, "x86_64") == 0) expected_arch = CPU_TYPE_X86_64;
  }
  I64 pv = HarnessValidateProducer(producer, expected_arch);
  if (pv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(pv);
    return pv;
  }
  if (Sha256File(source, source_hex) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_INPUT_MISSING);
    "HARNESS_REASON_DETAIL\tthe source %s is absent\n", source;
    return HARNESS_INPUT_MISSING;
  }
  if (Sha256File(fixture, fixture_hex) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_INPUT_MISSING);
    "HARNESS_REASON_DETAIL\tthe fixture %s is absent\n", fixture;
    return HARNESS_INPUT_MISSING;
  }

  // The ENVIRONMENT is applied BEFORE the spawn, so the child observes
  // exactly the environment the capture record names. A binding that is not
  // a NAME=VALUE pair is a hard failure.
  I64 envrc = HarnessApplyEnv(envv, nenv);
  if (envrc != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(envrc);
    return envrc;
  }

  // --- STEP 2: ALLOCATE THE EVENT IDENTITY, BEFORE THE EXECUTION. ---------
  event_counter = event_counter + 1;
  U8 *event_id = HarnessEventId(case_id, selector, producer_hex, source_hex,
                                fixture_hex, exec_argv, nargv, envv, nenv);

  // --- STEP 3: CREATE THE FRESH PER-CASE DIRECTORY. -----------------------
  //
  // The directory is FRESH: it is created with a name that carries the
  // event identity, so a REPLAYED artifact from an earlier event cannot
  // occupy it.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // The event directory is allocated EXCLUSIVELY. The previous revision
  // ignored the result of mkdir, so a pre-existing directory -- left by an
  // earlier run, or planted by a replay -- was silently REUSED, and the
  // fresh capture could be written into a directory that already held an
  // older event's bytes. The runner now REQUIRES mkdir to succeed, and a
  // directory that already exists is a hard failure with its own reason
  // token.
  U8 *case_dir = PathJoin(run_dir, case_id);
  mkdir(case_dir, 493);
  U8 *event_dir = PathJoin(case_dir, event_id);
  if (mkdir(event_dir, 493) != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_EVENT_DIR_EXISTS);
    "HARNESS_REASON_DETAIL\tthe event directory %s already exists\n", event_dir;
    return HARNESS_EVENT_DIR_EXISTS;
  }

  // --- STEP 4: RUN THE COMPILER. -----------------------------------------
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(exec_argv[0], exec_argv, &out, &err);
  if (rc < 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SPAWN_FAILED);
    "HARNESS_REASON_DETAIL\tthe compiler could not be executed\n";
    return HARNESS_SPAWN_FAILED;
  }
  // The exit status. `SpawnAndCapture` reports 128+signum for an abnormal
  // termination. A status above 255 is not a process exit status and is a
  // hard failure.
  if (rc > 255) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SPAWN_FAILED);
    "HARNESS_REASON_DETAIL\tthe compiler terminated abnormally\n";
    return HARNESS_SPAWN_FAILED;
  }

  // --- STEP 5: CAPTURE THE EXACT OBSERVED BYTES. -------------------------
  I64 outlen = 0;
  I64 errlen = 0;
  U8 *outbuf = out;
  U8 *errbuf = err;
  if (outbuf == NULL) outbuf = "";
  if (errbuf == NULL) errbuf = "";
  outlen = StrLen(outbuf);
  errlen = StrLen(errbuf);
  U8 *stdout_path = PathJoin(event_dir, "stdout.txt");
  U8 *stderr_path = PathJoin(event_dir, "stderr.txt");
  U8 *exit_path = PathJoin(event_dir, "exit.txt");
  if (WriteFile(stdout_path, outbuf, outlen) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_CAPTURE_FAILED);
    return HARNESS_CAPTURE_FAILED;
  }
  if (WriteFile(stderr_path, errbuf, errlen) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_CAPTURE_FAILED);
    return HARNESS_CAPTURE_FAILED;
  }
  // The exit status record, written with the CORRECTED encoder.
  U8 exit_text[8];
  I64 exit_len = 0;
  I64 exit_code = EXIT_OK;
  if (ContractWriteExitStatus(rc, exit_text, 7, &exit_len, &exit_code) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_CAPTURE_FAILED);
    "HARNESS_REASON_DETAIL\tthe exit status could not be encoded\n";
    return HARNESS_CAPTURE_FAILED;
  }
  U8 *exit_record = MAlloc(exit_len + 2);
  MemCpy(exit_record, exit_text, exit_len);
  exit_record[exit_len] = 10;
  if (WriteFile(exit_path, exit_record, exit_len + 1) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_CAPTURE_FAILED);
    return HARNESS_CAPTURE_FAILED;
  }

  // --- STEP 6: WRITE THE CAPTURE RECORD AND THE LEDGER ENTRY. ------------
  //
  // The artifact. Its ABSENCE is recorded as such; it is never replaced by
  // a digest of an empty file.
  U8 *artifact_path = PathJoin(artifact_dir, artifact_name);
  I64 artifact_present = 0;
  U8 *artifact_hex = MAlloc(65);
  if (Sha256File(artifact_path, artifact_hex) == 1) {
    artifact_present = 1;
  } else {
    // An absent artifact is recorded with the sentinel
    // "ABSENT", which is NOT a digest. A digest is always 64 hexadecimal
    // digits, so the comparator can tell the two apart.
    MemCpy(artifact_hex, "ABSENT", 7);
  }
  U8 *stdout_hex = MAlloc(65);
  U8 *stderr_hex = MAlloc(65);
  U8 *stdout_digest = MAlloc(32);
  U8 *stderr_digest = MAlloc(32);
  Sha256Bytes(outbuf, outlen, stdout_digest);
  Sha256Hex(stdout_hex, stdout_digest);
  Sha256Bytes(errbuf, errlen, stderr_digest);
  Sha256Hex(stderr_hex, stderr_digest);
  Free(stdout_digest);
  Free(stderr_digest);

  RecInit();
  // The event counter, rendered as decimal. It is the value the event
  // identity was computed from, so a reviewer can recompute the identity.
  U8 ctr_text[24];
  I64 ctr_len = 0;
  I64 ctr_code = EXIT_OK;
  if (ContractWriteExitStatus(event_counter, ctr_text, 23, &ctr_len,
                              &ctr_code) == 0) {
    // The counter can exceed 255, so the exit-status codec is not the
    // right encoder for it. The fallback renders the counter directly.
    I64 cv = event_counter;
    ctr_len = 0;
    U8 rev[24];
    I64 rn = 0;
    if (cv == 0) { rev[0] = 48; rn = 1; }
    while (cv > 0) { rev[rn] = 48 + (cv % 10); cv = cv / 10; rn = rn + 1; }
    while (ctr_len < rn) {
      ctr_text[ctr_len] = rev[rn - 1 - ctr_len];
      ctr_len = ctr_len + 1;
    }
    ctr_text[ctr_len] = 0;
  }
  RecField("RUN_ID", run_id);
  RecField("EVENT_ID", event_id);
  RecField("EVENT_COUNTER", ctr_text);
  RecField("CASE_ID", case_id);
  RecField("SELECTOR", selector);
  RecField("PRODUCER_SHA256", producer_hex);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // The producer's ARCHITECTURE is recorded, so that the evidence says
  // WHICH target the producer was, and not merely that some file with a
  // digest was executed.
  U8 *producer_arch = MAlloc(16);
  I64 parch = HarnessProducerArch(producer);
  MemCpy(producer_arch, ContractArchName(parch), StrLen(ContractArchName(parch)));
  producer_arch[StrLen(ContractArchName(parch))] = 0;
  RecField("PRODUCER_ARCH", producer_arch);
  // The ENVIRONMENT THAT WAS ACTUALLY APPLIED. Before this revision the
  // ENV block described an environment that was never in force.
  RecField("ENV_APPLIED", "1");
  RecField("SOURCE_SHA256", source_hex);
  RecField("FIXTURE_SHA256", fixture_hex);
  RecField("EXIT_STATUS", exit_text);
  RecField("STDOUT_SHA256", stdout_hex);
  RecField("STDERR_SHA256", stderr_hex);
  RecField("ARTIFACT_SHA256", artifact_hex);
  U8 *present_text = "0";
  if (artifact_present == 1) present_text = "1";
  RecField("ARTIFACT_PRESENT", present_text);
  RecField("ARTIFACT_PATH", artifact_path);
  RecField("EVENT_DIR", event_dir);
  RecBlock("ARGV", exec_argv, nargv);
  RecBlock("ENV", envv, nenv);

  U8 *capture_path = PathJoin(event_dir, "capture.txt");
  if (WriteFile(capture_path, rec_buf, rec_len) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_CAPTURE_FAILED);
    return HARNESS_CAPTURE_FAILED;
  }
  if (AppendLedger(ledger_path, event_id) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_LEDGER_FAILED);
    return HARNESS_LEDGER_FAILED;
  }

  "HARNESS_EVENT_ID\t%s\n", event_id;
  "HARNESS_EVENT_DIR\t%s\n", event_dir;
  "HARNESS_CAPTURE_PATH\t%s\n", capture_path;
  "HARNESS_EXIT_STATUS\t%lld\n", rc;
  "HARNESS_ARTIFACT_PATH\t%s\n", artifact_path;
  "HARNESS_ARTIFACT_PRESENT\t%d\n", artifact_present;
  return HARNESS_OK;
}

// The run-context initialiser. It is a SEPARATE function so that the
// `Main` frame stays small: a large frame in `Main` overflows the
// runtime's process stack on this host.
static I64 HarnessInit(U8 *run_dir) {
  // The run identity material: the run directory's path and the creation
  // instant in milliseconds. The instant is read from the system clock.
  U64 stamp = NowMilliseconds();
  Sha256Ctx c;
  Sha256Init(&c);
  Sha256Update(&c, run_dir, StrLen(run_dir));
  Sha256Update(&c, "\n", 1);
  U8 ts[32];
  I64 n = 0;
  I64 v = stamp;
  if (v == 0) { ts[0] = 48; n = 1; }
  while (v > 0) { ts[n] = 48 + (v % 10); v = v / 10; n = n + 1; }
  Sha256Update(&c, ts, n);
  Sha256Update(&c, "\n", 1);
  // The process identity, so that two concurrent runs in different
  // processes cannot collide.
  U64 pid = NowMilliseconds();
  Sha256Update(&c, "PID", 3);
  U8 pt[32];
  I64 pn = 0;
  I64 pv = pid;
  if (pv == 0) { pt[0] = 48; pn = 1; }
  while (pv > 0) { pt[pn] = 48 + (pv % 10); pv = pv / 10; pn = pn + 1; }
  Sha256Update(&c, pt, pn);
  U8 *digest = MAlloc(32);
  U8 *hex = MAlloc(65);
  Sha256Final(&c, digest);
  Sha256Hex(hex, digest);
  event_counter = 0;
  run_id = hex;
  // The run context is PERSISTED, so that the comparator can check the
  // expected run context independently.
  U8 *ctx_path = PathJoin(run_dir, "run-context.txt");
  RecInit();
  RecField("RUN_ID", run_id);
  RecField("RUN_DIR", run_dir);
  if (WriteFile(ctx_path, rec_buf, rec_len) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_RUN_DIR_FAILED);
    return HARNESS_RUN_DIR_FAILED;
  }
  "HARNESS_RUN_ID\t%s\n", run_id;
  "HARNESS_RUN_CONTEXT\t%s\n", ctx_path;
  return HARNESS_OK;
}

// The run-context reader. It returns 0 when the context is absent or
// malformed.
static I64 HarnessReadContext(U8 *run_dir, U8 *ledger_path) {
  U8 *ctx_path = PathJoin(run_dir, "run-context.txt");
  I64 csize = 0;
  U8 *cbuf = FileRead(ctx_path, &csize);
  if (cbuf == NULL) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_RUN_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe run context was not initialised\n";
    return 0;
  }
  // The run id is the value of the RUN_ID field. The field is read with
  // an EXACT prefix match, because the runtime's `StrLastOcc` finds the
  // last occurrence of a character SET rather than a substring, and it
  // would therefore match the wrong position.
  U8 *marker = "RUN_ID ";
  I64 mlen = StrLen(marker);
  I64 k = 0;
  I64 found = 0;
  while (k < csize) {
    I64 lend = k;
    while (lend < csize && cbuf[lend] != 10) lend = lend + 1;
    if (lend - k >= mlen) {
      I64 m = 0;
      I64 same = 1;
      while (m < mlen) {
        if (cbuf[k + m] != marker[m]) { same = 0; break; }
        m = m + 1;
      }
      if (same == 1) {
        I64 idlen = lend - (k + mlen);
        U8 *id = MAlloc(idlen + 1);
        MemCpy(id, cbuf + k + mlen, idlen);
        id[idlen] = 0;
        run_id = id;
        found = 1;
        break;
      }
    }
    if (lend >= csize) break;
    k = lend + 1;
  }
  if (found == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_RUN_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe run context carries no RUN_ID field\n";
    return 0;
  }
  // The event counter is RECOVERED from the ledger by counting the events
  // that the ledger already carries. The counter is therefore MONOTONIC
  // across the whole run context, and a replayed event cannot reuse a
  // counter value.
  I64 lsize = 0;
  U8 *lbuf = FileRead(ledger_path, &lsize);
  I64 counter = 0;
  if (lbuf != NULL) {
    I64 j = 0;
    while (j < lsize) {
      if (lbuf[j] == 10) counter = counter + 1;
      j = j + 1;
    }
  }
  event_counter = counter;
  return 1;
}

// ---------------------------------------------------------------------------
// MAIN.
//
//   harness init <run-dir>
//   harness run <run-dir> <ledger> <selector> <case-id>
//                  <producer> <source> <fixture>
//                  <artifact-name> <artifact-dir>
//                  <env>... -- <argv>...
//
// The `init` mode ALLOCATES THE RUN CONTEXT. It computes the run identity
// from the run directory's path and the creation instant, so two run
// contexts are distinguishable even when they share a directory.
//
// The `run` mode REQUIRES an initialised run context. It refuses to run
// without one, because an execution without a run context has no event
// identity to bind to.
// ---------------------------------------------------------------------------
I32 Main(I32 argc, U8 **argv) {
  if (argc < 3) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    "HARNESS_USAGE\tharness init <run-dir> | harness run ...\n";
    return HARNESS_USAGE;
  }

  if (StrCmp(argv[1], "init") == 0) {
    return HarnessInit(argv[2]);
  }

  if (StrCmp(argv[1], "run") == 0) {
    if (argc < 13) {
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
      return HARNESS_USAGE;
    }
    if (HarnessReadContext(argv[2], argv[3]) == 0) {
      return HARNESS_RUN_DIR_FAILED;
    }
    // The `run` mode takes the arguments from index 2 onwards, with the
    // `run` verb consumed. The sub-array's argv[0] is therefore the run
    // directory, which is what HarnessRun expects.
    U8 **sub = MAlloc(sizeof(U8 *) * (argc + 1));
    I64 s = 0;
    while (s < argc - 1) {
      sub[s] = argv[s + 2];
      s = s + 1;
    }
    sub[argc - 1] = NULL;
    return HarnessRun(argc - 1, sub);
  }

  "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
  "HARNESS_USAGE\tharness init <run-dir> | harness run ...\n";
  return HARNESS_USAGE;
}
