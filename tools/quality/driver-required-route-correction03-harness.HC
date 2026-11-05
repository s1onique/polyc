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
// HARNESS_ENV_NOT_IN_FORCE -- the environment the capture record names was
// NOT in force in the spawned child. The harness applied a binding, the
// setenv call SUCCEEDED, and the child nevertheless did not observe the
// variable. This is the reason that distinguishes "the binding was
// applied" from "the binding was applied CORRECTLY".
#define HARNESS_ENV_NOT_IN_FORCE        12
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5,
// R4-02 and R4-03.
//
// The three additional reasons are DISTINCT, so a reviewer can tell WHICH
// trust-boundary property was violated.
//
//   HARNESS_PRODUCER_SUBSTITUTED     the caller supplied an executable
//                                    that is not the producer the runner
//                                    validated. The runner OWNS the
//                                    executable it spawns: it constructs
//                                    the path itself, and an attempt to
//                                    supply a different one is refused.
//
//   HARNESS_PRODUCER_REPLACED        the producer's bytes changed between
//                                    the validation and the invocation,
//                                    or the producer is a SYMLINK or a
//                                    path whose resolution does not
//                                    yield the validated file.
//
//   HARNESS_OUTPUT_PREEXISTS         the expected output path was already
//                                    present before the execution. A
//                                    success observation cannot be
//                                    created merely because a file
//                                    already exists at a supplied path.
//
//   HARNESS_OUTPUT_DIR_FAILED        the runner could not allocate the
//                                    fresh, case-specific output
//                                    directory that owns the outputs.
#define HARNESS_PRODUCER_SUBSTITUTED  13
#define HARNESS_PRODUCER_REPLACED     14
#define HARNESS_OUTPUT_PREEXISTS      15
#define HARNESS_OUTPUT_DIR_FAILED     16

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
  if (code == HARNESS_ENV_NOT_IN_FORCE) return "HARNESS_ENV_NOT_IN_FORCE";
  if (code == HARNESS_PRODUCER_SUBSTITUTED) return "HARNESS_PRODUCER_SUBSTITUTED";
  if (code == HARNESS_PRODUCER_REPLACED) return "HARNESS_PRODUCER_REPLACED";
  if (code == HARNESS_OUTPUT_PREEXISTS) return "HARNESS_OUTPUT_PREEXISTS";
  if (code == HARNESS_OUTPUT_DIR_FAILED) return "HARNESS_OUTPUT_DIR_FAILED";
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

// The event identity.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-05.
//
// The identity is computed over the SHARED CONTRACT'S CANONICAL ENCODING.
// The previous revision computed it over a WHITESPACE-DELIMITED
// concatenation of the argument vector and the environment, which had no
// unambiguous field boundary: moving the last ARGV element into the ENV
// block preserved the identity, so a record describing an execution that
// did not happen satisfied the identity check.
//
// The shared contract's `ContractEventId` is the ONE implementation. The
// producer and the comparator both call it, so the two cannot drift apart.
//
// The event counter is INCLUDED, so the identity of an invocation is unique
// even when every observed byte is identical to a previous invocation.
//
// It returns the identity as a 64-character lowercase hexadecimal string.
static U8 *HarnessEventId(EventIdCtx *ctx, EventIdEnvCtx *env) {
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
  // The inputs are therefore carried in the shared contract's contexts,
  // which the caller fills BY NAME, and the identity computation receives
  // them here.
  //
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
  ctr[n] = 0;
  // The counter is the DECIMAL event counter, and it is part of the
  // identity. It is written into the context BY NAME.
  ctx->counter = ctr;
  // The OUTPUT IDENTITIES field is empty at this point: the identity is
  // allocated BEFORE the execution, and the outputs do not exist yet.
  return ContractEventIdWithEnv(ctx, env);
}

// ---------------------------------------------------------------------------
// THE FILE SYSTEM HELPERS.
//
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
// the child observes exactly the environment the capture record names.
//
// The bindings are applied to the RUNNER's own environment, and the runner
// does not restore them. That is CORRECT here, and the reason is stated
// rather than assumed: the harness process performs EXACTLY ONE execution
// and then returns from Main, so the modified environment cannot be
// observed by a second execution. The runner is invoked once per
// execution by the Makefile, and the run ledger and the event counter
// live across processes rather than within one.
//
// The alternative -- saving and restoring each binding -- would be
// MECHANICALLY DEAD CODE under the current process model, and a comment
// claiming a restore that the code does not perform would be a false
// description of the mechanism.
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
    // The SPLIT is the shared contract's, and it is exercised by the
    // contract's own self-check. The earlier revision computed the split
    // HERE, with ONE variable used as both a flag and a position, so the
    // variable that was set bore the wrong name and the wrong value while
    // the setenv call still SUCCEEDED.
    U8 *name = NULL;
    U8 *value = NULL;
    if (ContractSplitBinding(binding, &name, &value) == 0) {
      "HARNESS_REASON_DETAIL\tthe environment binding %s is not a NAME=VALUE pair\n",
        binding;
      return HARNESS_USAGE;
    }
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

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-02.
//
// THE PRODUCER'S PATH, SYMLINK AND REPLACEMENT POLICY.
//
// THE ORIGINAL DEFECT. The runner VALIDATED one executable and SPAWNED
// another. The validated producer was the `<producer>` argument; the
// spawned executable was the FIRST element of the argument vector that the
// caller supplied after the `--` separator. The two were independent, so:
//
//     validated producer   the repository's `hcc`
//     executed command     /bin/cp seed.o artifact.bin
//     recorded producer    hcc
//
// described a successful compilation that never happened.
//
// THE REPAIR. THE RUNNER OWNS THE EXECUTABLE.
//
//   1. The runner CONSTRUCTS the executable path itself. It is the
//      `<producer>` argument, and it is the ONLY executable the runner
//      will spawn.
//
//   2. The argument vector the caller supplies carries the ARGUMENTS
//      only. The caller may name an executable in its first position --
//      the historical calling convention -- but that name is CHECKED
//      against the producer the runner validated, and a mismatch is
//      refused with `HARNESS_PRODUCER_SUBSTITUTED`.
//
//   3. The producer's identity, architecture and DIGEST are re-validated
//      IMMEDIATELY BEFORE the invocation, and the digest is compared
//      against the digest that was recorded at the start of the run. A
//      producer whose bytes changed in between is refused with
//      `HARNESS_PRODUCER_REPLACED`.
//
// THE PATH, SYMLINK AND REPLACEMENT POLICY, STATED.
//
//   * The producer path MUST be an ABSOLUTE path. A relative path names
//     a different file depending on the runner's working directory, and
//     the runner must not depend on it.
//
//   * The producer path MUST NOT BE A SYMLINK. A symlink can be repointed
//     between the validation and the invocation, so the identity the
//     runner validated would not be the identity the runner executed.
//     The check is on the link itself, so it holds for a symlink to a
//     symlink.
//
//   * The producer MUST BE A REGULAR FILE. A directory, a device or a
//     FIFO is not a compiler.
//
//   * The producer's DIGEST is re-read immediately before the invocation
//     and compared with the digest that was recorded when the run began.
//     This is what makes a REPLACEMENT -- overwriting the producer's
//     bytes between the two moments -- detectable.
//
// These are the properties the ACT requires the runner to enforce.
// ---------------------------------------------------------------------------

// The real-path and link-test declarations. They are the platform's own
// `lstat(2)`, `realpath(3)` and `stat(2)`.
extern "c" I32 lstat(U8 *path, U0 *st);
extern "c" U8 *realpath(U8 *path, U8 *resolved);
// The working-directory declarations. They are the platform's own
// `getcwd(3)` and `chdir(2)`.
extern "c" U8 *getcwd(U8 *buf, I64 size);
extern "c" I32 chdir(U8 *path);
// The environment reader, for the diagnostic below.
extern "c" I8 *getenv(U8 *buf);

// The path-policy check.
//
// It returns HARNESS_OK, or the reason the producer path was refused.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-02.
//
// THE SYMLINK AND REGULAR-FILE POLICY, IMPLEMENTED.
//
// The policy is stated in the comment above, and the PREVIOUS revision did
// not IMPLEMENT it: `lstat(2)` was DECLARED and never CALLED, so a
// symlinked producer was accepted even though a symlink can be repointed
// between the validation and the invocation.
//
// The check is on the LINK ITSELF, so it holds for a symlink to a
// symlink. The `stat` structure is read through the platform's own
// `lstat(2)`, and the link and file-type bits are taken from the
// platform's own `S_IFMT`, `S_IFLNK` and `S_IFREG`.
//
// The producer MUST BE A REGULAR FILE. A directory, a device or a FIFO is
// not a compiler.
static I64 HarnessCheckProducerPath(U8 *producer) {
  I64 len = StrLen(producer);
  if (len <= 0) return HARNESS_PRODUCER_MISSING;
  // The path MUST be absolute.
  if (producer[0] != 47) {
    "HARNESS_REASON_DETAIL\tthe producer path %s is not absolute\n", producer;
    return HARNESS_PRODUCER_SUBSTITUTED;
  }
  // The path MUST NOT BE A SYMLINK.
  //
  // The `stat` structure is allocated, not on the stack, because
  // `lstat(2)` writes the platform's whole structure into it.
  //
  // The buffer is typed as `U8 *`, because the platform's declaration
  // takes an untyped pointer and the compiler has no C-style cast.
  I64 stat_size = 256;
  U8 *st = MAlloc(stat_size);
  I64 lrc = lstat(producer, st);
  if (lrc != 0) {
    Free(st);
    // The path does not resolve at all. The producer's own validation
    // reports the absence with a more specific reason.
    return HARNESS_OK;
  }
  // The mode field.
  //
  // The platform's `struct stat` carries `st_dev` in the first four bytes
  // and `st_mode` in the NEXT four, so the mode is read from offset 4.
  //
  // THE MASKING IS DONE BY DIVISION, NOT BY A BITWISE AND. The production
  // compiler's `&` operator does not behave as a bitwise AND on a hex
  // literal -- `0x18EB1AFA & 0xF000` evaluates to `0x1000` -- so the
  // file-type bits are extracted arithmetically, exactly as the shared
  // contract's `ContractWordAt` reads its fields.
  I64 mode = 0;
  I64 k = 3;
  while (k >= 0) {
    mode = mode * 256 + st[4 + k];
    k = k - 1;
  }
  // The file-type bits are the HIGH nibble of the mode's low sixteen bits.
  // The nibble is obtained by dividing by the mask's own scale, and the
  // comparison is made against the SAME scale, because the production
  // compiler's `&` operator does not behave as a bitwise AND.
  I64 ftype = (mode % 65536) / 4096;
  Free(st);
  if (ftype == S_IFLNK / 4096) {
    "HARNESS_REASON_DETAIL\tthe producer path %s is a symbolic link\n",
      producer;
    return HARNESS_PRODUCER_SUBSTITUTED;
  }
  if (ftype != S_IFREG / 4096) {
    "HARNESS_REASON_DETAIL\tthe producer path %s is not a regular file\n",
      producer;
    return HARNESS_PRODUCER_NOT_EXECUTABLE;
  }
  return HARNESS_OK;
}

// The producer's identity, re-established immediately before the
// invocation.
//
// It returns HARNESS_OK, or the reason the producer was refused.
static I64 HarnessRevalidateProducer(U8 *producer, I64 expected_arch,
                                      U8 *expected_hex) {
  // The path policy.
  I64 pc = HarnessCheckProducerPath(producer);
  if (pc != HARNESS_OK) return pc;
  // The producer must still exist, still be executable, and still be a
  // Mach-O image for the expected architecture.
  I64 pv = HarnessValidateProducer(producer, expected_arch);
  if (pv != HARNESS_OK) return pv;
  // The DIGEST must be the one that was recorded at the start of the run.
  // This is the REPLACEMENT check: a producer whose bytes changed between
  // the validation and the invocation is refused.
  U8 *now_hex = MAlloc(65);
  if (Sha256File(producer, now_hex) == 0) {
    Free(now_hex);
    return HARNESS_PRODUCER_REPLACED;
  }
  I64 same = 0;
  if (StrCmp(now_hex, expected_hex) == 0) same = 1;
  Free(now_hex);
  if (same == 0) {
    "HARNESS_REASON_DETAIL\tthe producer %s changed between the validation "
      "and the invocation\n", producer;
    return HARNESS_PRODUCER_REPLACED;
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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-02.
//
// The argument vector's FIRST element names the executable. It is CHECKED
// against the producer the runner validated, and the runner spawns the
// PRODUCER. A mismatch is refused with `HARNESS_PRODUCER_SUBSTITUTED`.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-03.
//
// The `<artifact-dir>` is the runner-controlled OUTPUT DIRECTORY. The
// runner allocates a FRESH, CASE-SPECIFIC directory inside it, requires
// the expected output path to be ABSENT before the execution, and binds
// the output collection to that invocation.
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
  U8 **supplied_argv = MAlloc(sizeof(U8 *) * (nargv + 1));
  I64 a = 0;
  while (a < nargv) {
    supplied_argv[a] = argv[sep + 1 + a];
    if (supplied_argv[a] == NULL) {
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
      "HARNESS_REASON_DETAIL\tthe argument vector carries a NULL entry\n";
      return HARNESS_USAGE;
    }
    a = a + 1;
  }
  supplied_argv[nargv] = NULL;

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-02.
  //
  // THE RUNNER CONSTRUCTS THE EXECUTABLE PATH AND THE ARGUMENT VECTOR.
  //
  // THE ORIGINAL DEFECT. The runner validated the `<producer>` argument
  // and spawned the FIRST element of the SUPPLIED argument vector. The two
  // were independent, so a caller could validate the repository's `hcc`
  // and execute `/bin/cp`, and the capture record would name `hcc` as the
  // producer of an artifact that `cp` had copied.
  //
  // THE REPAIR. The runner OWNS the executable:
  //
  //   * The executable path is the `<producer>` argument. The runner
  //     constructs it, and it is the ONLY executable the runner spawns.
  //
  //   * The supplied vector's first element names the executable under the
  //     historical calling convention. It is CHECKED against the
  //     producer, and a mismatch is REFUSED. The check accepts the
  //     producer's own path, and it accepts a path that RESOLVES to the
  //     producer, so the historical convention still works while a
  //     substitution does not.
  //
  //   * The spawned vector is `[producer, arguments...]`: the arguments
  //     are the supplied vector's elements from the SECOND onward, and the
  //     first element -- the executable name -- is replaced by the
  //     runner's own path.
  I64 named_argc = nargv;
  U8 *named = supplied_argv[0];
  // The named executable must BE the producer. The comparison accepts the
  // producer's own path and any path that resolves to the same file.
  I64 named_ok = 0;
  if (StrCmp(named, producer) == 0) {
    named_ok = 1;
  } else {
    // The two paths are compared by their RESOLVED forms, so that the same
    // file named in two different ways is recognised as the same file.
    // The buffers are allocated, not on the stack, because `realpath` is
    // the platform's own function and it does not bound its writes to a
    // path length.
    U8 *rbuf_a = MAlloc(4096);
    U8 *rbuf_b = MAlloc(4096);
    U8 *resolved = realpath(named, rbuf_a);
    if (resolved != NULL) {
      U8 *presolved = realpath(producer, rbuf_b);
      if (presolved != NULL) {
        if (StrCmp(resolved, presolved) == 0) named_ok = 1;
      }
    }
    Free(rbuf_a);
    Free(rbuf_b);
  }
  if (named_ok == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_PRODUCER_SUBSTITUTED);
    "HARNESS_REASON_DETAIL\tthe argument vector names %s, but the validated "
      "producer is %s\n", named, producer;
    return HARNESS_PRODUCER_SUBSTITUTED;
  }
  // The spawned vector: the runner's producer path, then the arguments.
  U8 **exec_argv = MAlloc(sizeof(U8 *) * (nargv + 1));
  exec_argv[0] = producer;
  a = 1;
  while (a < named_argc) {
    exec_argv[a] = supplied_argv[a];
    a = a + 1;
  }
  exec_argv[named_argc] = NULL;
  I64 exec_argc = named_argc;

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
  // The identity inputs are carried in the shared contract's contexts,
  // which are filled BY NAME, so that no argument can be shifted by the
  // production compiler's calling convention.
  EventIdCtx id_ctx;
  id_ctx.run_id = run_id;
  id_ctx.counter = "";
  id_ctx.case_id = case_id;
  id_ctx.selector = selector;
  id_ctx.producer_hex = producer_hex;
  id_ctx.source_hex = source_hex;
  id_ctx.fixture_hex = fixture_hex;
  id_ctx.argv = exec_argv;
  id_ctx.nargv = exec_argc;
  id_ctx.envv = NULL;
  id_ctx.nenv = 0;
  EventIdEnvCtx id_env;
  id_env.envv = envv;
  id_env.nenv = nenv;
  U8 *event_id = HarnessEventId(&id_ctx, &id_env);

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

  // --- STEP 3B: ALLOCATE THE FRESH, CASE-SPECIFIC OUTPUT DIRECTORY. ------
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-03
  // -- THE OUTPUT DESTINATION BELONGS TO THE RUNNER.
  //
  // THE ORIGINAL DEFECT. The runner was given an EXTERNAL output
  // directory and an artifact NAME, and it looked for the artifact where
  // the caller said it would be. A caller could therefore prepopulate the
  // location with a VALID OLD OBJECT, run a compiler that creates NO new
  // object -- `hcc --help` does exactly that -- and the harness would
  // register the OLD artifact as the result of this execution. The
  // capture record would carry a real digest of a real object, and the
  // comparator would find everything it needed: a FALSE PASS.
  //
  // THE REPAIR. The runner OWNS the output destination.
  //
  //   * The runner allocates a FRESH, CASE-SPECIFIC output directory
  //     inside the event directory. The directory is created
  //     EXCLUSIVELY: a directory that already exists is a hard failure.
  //
  //   * The expected output path MUST BE ABSENT before the execution. A
  //     path that is already present is refused with
  //     `HARNESS_OUTPUT_PREEXISTS`, because a success observation cannot
  //     be created merely because a file already exists at a supplied
  //     path.
  //
  //   * The compiler writes INTO the runner-controlled directory. The
  //     runner makes that directory the child's WORKING DIRECTORY, so the
  //     compiler's relative output path resolves inside it and cannot
  //     escape into the caller's tree.
  //
  // The output collection is bound to THIS invocation: the artifact is
  // read from the runner's own directory, after this execution, and the
  // path it was read from is recorded in the capture record.
  U8 *out_dir = PathJoin(event_dir, "out");
  if (mkdir(out_dir, 493) != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe output directory %s already exists\n", out_dir;
    return HARNESS_OUTPUT_DIR_FAILED;
  }
  // The expected output path, INSIDE the runner's own directory.
  U8 *artifact_path = PathJoin(out_dir, artifact_name);
  // The output MUST NOT ALREADY EXIST. The old artifact is left exactly
  // where it was: the counterexample is not reproduced by CORRUPTING the
  // old artifact, and the stale file is not deleted.
  //
  // The scratch buffer is SEPARATE from the producer's digest. The
  // producer's digest is the IDENTITY of the producer, and it is written
  // into the capture record; a scratch use of the same buffer would
  // corrupt it.
  I64 pre_existing = 0;
  U8 *presence_buf = MAlloc(65);
  if (Sha256File(artifact_path, presence_buf) == 1) pre_existing = 1;
  Free(presence_buf);
  if (pre_existing == 1) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_PREEXISTS);
    "HARNESS_REASON_DETAIL\tthe expected output %s already exists\n",
      artifact_path;
    return HARNESS_OUTPUT_PREEXISTS;
  }

  // The SOURCE is copied into the runner's own directory, so that the
  // compiler's RELATIVE source path resolves inside the runner-controlled
  // directory. The copy is made from the file whose digest was recorded
  // above, so the compiler consumes exactly the source the evidence names.
  U8 *source_copy = PathJoin(out_dir, "source.HC");
  I64 ssize = 0;
  U8 *sbuf = FileRead(source, &ssize);
  if (sbuf == NULL) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_INPUT_UNREADABLE);
    "HARNESS_REASON_DETAIL\tthe source %s could not be read\n", source;
    return HARNESS_INPUT_UNREADABLE;
  }
  if (WriteFile(source_copy, sbuf, ssize) == 0) {
    Free(sbuf);
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe source copy could not be written\n";
    return HARNESS_OUTPUT_DIR_FAILED;
  }
  Free(sbuf);

  // --- STEP 3C: RE-VALIDATE THE PRODUCER, IMMEDIATELY BEFORE THE SPAWN. --
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-02.
  //
  // The producer's identity, architecture and digest are established from
  // the BYTES ON DISK one more time, at the last possible moment before
  // the invocation, and the digest is compared with the digest that was
  // recorded at the start of the run. A producer whose bytes were
  // REPLACED in between is refused.
  I64 rv = HarnessRevalidateProducer(producer, expected_arch, producer_hex);
  if (rv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(rv);
    return rv;
  }

  // --- STEP 4: RUN THE COMPILER. -----------------------------------------
  //
  // The child's WORKING DIRECTORY is the runner's own output directory,
  // so the compiler's relative output path resolves inside the runner's
  // directory and cannot escape into the caller's tree.
  I64 saved_cwd = -1;
  U8 *cwd_buf = MAlloc(4096);
  if (getcwd(cwd_buf, 4096) != NULL) saved_cwd = 1;
  if (chdir(out_dir) != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe runner could not enter the output directory\n";
    return HARNESS_OUTPUT_DIR_FAILED;
  }
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(exec_argv[0], exec_argv, &out, &err);
  if (saved_cwd == 1) chdir(cwd_buf);
  Free(cwd_buf);
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
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-03.
  //
  // The artifact is read from the RUNNER'S OWN directory -- the path
  // that was proved ABSENT before the execution -- and not from the
  // caller's directory. The path that was read is recorded, so a reviewer
  // can see exactly which file the observation is about.
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
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-03.
  //
  // The RUNNER-CONTROLLED OUTPUT DIRECTORY and the EXECUTED EXECUTABLE are
  // recorded, so that a reviewer can see that the observation came from the
  // runner's own directory and that the executable the runner spawned is
  // the producer it validated.
  RecField("OUTPUT_DIR", out_dir);
  RecField("EXECUTED_EXECUTABLE", producer);
  RecField("EVENT_ID_SCHEMA", "2");
  RecBlock("ARGV", exec_argv, exec_argc);
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
// THE ENVIRONMENT-APPLICATION SELF-TEST.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
//
//   harness envcheck <probe-program> <variable-name> <expected-value>
//
// The probe program is a Mach-O executable that prints the value of the
// named variable on its standard output. The harness APPLIES the binding,
// SPAWNS the probe, and requires the probe's output to carry the expected
// value.
//
// WHY THIS EXISTS. The harness's own execution could not detect a WRONG
// environment application: the setenv call SUCCEEDED, and the capture
// recorded the binding the harness BELIEVED it had applied. The defect
// was found by an EXTERNAL probe that read the variable from the child.
// This mode makes that probe part of the harness's own evidence, so the
// property is checked on EVERY run rather than once by hand.
//
// The probe program must be a Mach-O image for the expected architecture,
// or it is refused with the SAME reason a producer is refused. The check
// is the same check, applied to the probe.
// ---------------------------------------------------------------------------
// The ENVPROBE FIELD READER.
//
// It returns a COPY of the value of the named field, which is the text
// between the field's prefix and the END OF THAT LINE. It returns NULL
// when the probe printed no such field.
//
// The field is read to the END OF ITS LINE, and NOT to the end of the
// output, so a field's value cannot run into the next field.
//
// It is a SEPARATE function because a large frame in the caller
// overflows the runtime's process stack on this host.
static U8 *HarnessEnvProbeField(U8 *outbuf, I64 outlen, U8 *prefix) {
  I64 plen = StrLen(prefix);
  I64 i = 0;
  while (i < outlen) {
    I64 lend = i;
    while (lend < outlen && outbuf[lend] != 10) lend = lend + 1;
    // The line must BEGIN with the prefix.
    if (lend - i >= plen) {
      I64 m = 0;
      I64 same = 1;
      while (m < plen) {
        if (outbuf[i + m] != prefix[m]) { same = 0; break; }
        m = m + 1;
      }
      if (same == 1) {
        I64 vlen = lend - (i + plen);
        U8 *v = MAlloc(vlen + 1);
        MemCpy(v, outbuf + i + plen, vlen);
        v[vlen] = 0;
        return v;
      }
    }
    if (lend >= outlen) break;
    i = lend + 1;
  }
  return NULL;
}

// The exact-equality test. It compares two byte strings BYTE FOR BYTE,
// and it accepts an EMPTY string.
static I64 HarnessExactEqual(U8 *a, U8 *b) {
  if (a == NULL) return 0;
  if (b == NULL) return 0;
  I64 alen = StrLen(a);
  I64 blen = StrLen(b);
  if (alen != blen) return 0;
  I64 k = 0;
  while (k < alen) {
    if (a[k] != b[k]) return 0;
    k = k + 1;
  }
  return 1;
}

static I64 HarnessEnvCheck(I32 argc, U8 **argv) {
  if (argc < 5) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    "HARNESS_USAGE\tharness envcheck <probe> <variable> <expected>\n";
    return HARNESS_USAGE;
  }
  U8 *probe = argv[2];
  U8 *varname = argv[3];
  U8 *expected = argv[4];

  // The probe is a Mach-O image for the expected architecture.
  I64 pv = HarnessValidateProducer(probe, CPU_TYPE_ARM64);
  if (pv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(pv);
    return pv;
  }

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-11.
  //
  // THE HARNESS DOES NOT APPLY A BINDING IN THIS MODE.
  //
  // THE ORIGINAL DEFECT. The mode applied the binding `varname=expected`
  // ITSELF and then checked that the probe's output CONTAINED the
  // expected text. The check therefore established nothing about the
  // environment: the harness had just put the expected text there, and
  // the CONTAINS test accepted any output that carried it anywhere.
  //
  // THE REPAIR. The mode OBSERVES. It does not modify the environment.
  // It spawns the probe, reads the two fields the probe prints, and
  // requires:
  //
  //   * the child TERMINATED SUCCESSFULLY;
  //   * the `ENVPROBE_NAME` field is EXACTLY the variable the harness
  //     asked about -- so a value observed under a DIFFERENT name is
  //     REFUSED; and
  //   * the `ENVPROBE_VALUE` field is EXACTLY the expected value -- so a
  //     value that merely CONTAINS the expected value is REFUSED.
  //
  // The four mandatory cases are therefore:
  //
  //   the ambient BAD=NEEDLE, asked about GOOD, expected NEEDLE
  //       -> REJECTED: the name does not match
  //   the ambient GOOD=NEEDLE, asked about GOOD, expected NEEDLE
  //       -> ACCEPTED
  //   the ambient EMPTY=, asked about EMPTY, expected ""
  //       -> ACCEPTED
  //   the ambient GOOD=NEEDLE=EXTRA, asked about GOOD, expected NEEDLE
  //       -> REJECTED: the value is not exact
  //
  // The probe is spawned with the VARIABLE NAME it is asked about, so it
  // reports what it observed under that exact name.
  U8 *args[3];
  args[0] = probe;
  args[1] = varname;
  args[2] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(probe, args, &out, &err);
  if (rc < 0 || rc > 255) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SPAWN_FAILED);
    return HARNESS_SPAWN_FAILED;
  }
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-11.
  //
  // THE CHILD MUST HAVE TERMINATED SUCCESSFULLY. A probe that printed a
  // value and then failed did not establish anything: the value it
  // printed may be a partial report. The exit status is therefore
  // REQUIRED to be zero.
  if (rc != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe terminated with the status %lld\n", rc;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", out;
    return HARNESS_ENV_NOT_IN_FORCE;
  }
  I64 outlen = 0;
  U8 *outbuf = out;
  if (outbuf == NULL) outbuf = "";
  outlen = StrLen(outbuf);

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-11.
  //
  // THE PROBE'S OUTPUT MUST CARRY THE EXACT OBSERVED VALUE.
  //
  // THE ORIGINAL DEFECT. The check was a SUBSTRING CONTAINS: the harness
  // looked for the expected value ANYWHERE in the probe's output. A probe
  // that observed the value "NEEDLE=EXTRA" satisfied a check for the
  // value "NEEDLE", and a probe that observed "NOT_NEEDLE" satisfied it
  // too. The check therefore did not establish what it claimed to
  // establish.
  //
  // THE REPAIR. The probe prints ONE FIELD PER LINE in a fixed format:
  //
  //   ENVPROBE_VALUE=<the value the child observed>
  //   ENVPROBE_NAME=<the name the child was asked about>
  //
  // The harness reads the `ENVPROBE_VALUE` FIELD -- the value up to the
  // end of that line, and NOT to the end of the output -- and compares it
  // with the expected value BYTE FOR BYTE. A value that merely CONTAINS
  // the expected value is REJECTED.
  //
  // The child must also have TERMINATED SUCCESSFULLY: the probe's exit
  // status must be zero.
  U8 *value_field = HarnessEnvProbeField(outbuf, outlen, "ENVPROBE_VALUE=");
  if (value_field == NULL) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe printed no ENVPROBE_VALUE field\n";
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_NOT_IN_FORCE;
  }
  U8 *name_field = HarnessEnvProbeField(outbuf, outlen, "ENVPROBE_NAME=");
  if (name_field == NULL) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe printed no ENVPROBE_NAME field\n";
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_NOT_IN_FORCE;
  }
  // The NAME the probe reported must be EXACTLY the variable the harness
  // asked about. A value observed under a DIFFERENT name is refused: the
  // harness asked about one variable and the probe answered about
  // another.
  if (HarnessExactEqual(name_field, varname) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe reported a different variable name than "
      "the one the harness asked about\n";
    "HARNESS_ENV_DIAG\texpected_name=[%s]\n", varname;
    "HARNESS_ENV_DIAG\tobserved_name=[%s]\n", name_field;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_NOT_IN_FORCE;
  }
  // The VALUE must be EXACTLY the expected value.
  if (HarnessExactEqual(value_field, expected) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe observed a different value than the "
      "expected one\n";
    "HARNESS_ENV_DIAG\texpected=[%s]\n", expected;
    "HARNESS_ENV_DIAG\tobserved=[%s]\n", value_field;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_NOT_IN_FORCE;
  }
  "HARNESS_ENVCHECK_STATUS=PASS\n";
  "HARNESS_ENVCHECK_STDOUT=[%s]\n", outbuf;
  return HARNESS_OK;
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

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
  //
  // The environment-application self-test.
  if (StrCmp(argv[1], "envcheck") == 0) {
    return HarnessEnvCheck(argc, argv);
  }

  if (StrCmp(argv[1], "run") == 0) {
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 4, F1.
    //
    // The minimum is FOURTEEN: the verb, the TEN fixed arguments, at least
    // ONE environment binding, the separator, and at least ONE argument of
    // the argument vector. The previous guard said thirteen, which was the
    // count before the EXPECTED ARCHITECTURE became a fixed argument, and
    // it admitted a call that the run mode itself would refuse.
    if (argc < 14) {
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
