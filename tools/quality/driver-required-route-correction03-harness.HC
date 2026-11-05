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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6.
//
// The five reasons that the C4 ROUND 5 independent review established.
//
//   HARNESS_SOURCE_CONTRADICTED    the caller's argument vector names a
//                                  SOURCE that contradicts the source the
//                                  runner staged. The runner owns the
//                                  source argument, so a contradiction is
//                                  refused rather than resolved.
//
//   HARNESS_OUTPUT_ESCAPED          the caller's argument vector names an
//                                  OUTPUT that is not the runner-owned
//                                  destination. An absolute path, a
//                                  parent-directory component, a path
//                                  separator in a basename field, or any
//                                  other spelling that leaves the
//                                  runner's directory is refused.
//
//   HARNESS_OUTPUT_AMBIGUOUS        the caller's argument vector carries
//                                  MORE THAN ONE output option, so the
//                                  runner cannot tell which one the
//                                  caller meant.
//
//   HARNESS_SOURCE_AMBIGUOUS        the caller's argument vector carries
//                                  MORE THAN ONE source argument.
//
//   HARNESS_PRODUCER_STAGE_FAILED   the runner could not stage the
//                                  validated producer into its own
//                                  private directory.
#define HARNESS_SOURCE_CONTRADICTED   17
#define HARNESS_OUTPUT_ESCAPED         18
#define HARNESS_OUTPUT_AMBIGUOUS       19
#define HARNESS_SOURCE_AMBIGUOUS       20
#define HARNESS_PRODUCER_STAGE_FAILED  21
// HARNESS_PRODUCER_STAGE_MISMATCH -- the STAGED producer's digest differs
// from the digest of the producer the runner qualified. The staging copy
// is therefore not a copy of the qualified bytes, and the runner refuses
// to execute it.
#define HARNESS_PRODUCER_STAGE_MISMATCH 22
// HARNESS_ENV_BINDING_NOT_IN_FORCE -- the environment binding that the
// production applier applied was NOT observed inside a real child. The
// binding helper is the production one, and the observation is made by a
// real probe process, so this reason means the applier itself is wrong.
#define HARNESS_ENV_BINDING_NOT_IN_FORCE 23
// HARNESS_OUTPUT_NOT_INSIDE -- the resolved output destination is not
// inside the runner-owned directory. It is the LAST defence, after the
// lexical checks, and it is what makes a symlinked path component
// detectable.
#define HARNESS_OUTPUT_NOT_INSIDE     24
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7.
//
// HARNESS_ARGV_CAPACITY -- the argument vector exceeded the capacity that
// the builder computed from its own planned insertions. The builder
// checks the capacity BEFORE every append, so this reason is a REFUSAL
// and never an out-of-bounds write. A correct plan cannot reach it; a
// plan that is one slot short can, and it is reported rather than
// silently overflowed.
#define HARNESS_ARGV_CAPACITY         25
// HARNESS_OUTPUT_VALUE_MISSING -- an output option was supplied WITHOUT a
// value. The vector is malformed, and the runner refuses it rather than
// treating the missing value as a filename.
#define HARNESS_OUTPUT_VALUE_MISSING  26
// HARNESS_SOURCE_NOT_STABLE -- the source changed between the moment the
// runner read it and the moment the snapshot was written, so the runner
// cannot demonstrate a CONSISTENT snapshot. The run is refused rather
// than continued with an ambiguous input.
#define HARNESS_SOURCE_NOT_STABLE     27
// HARNESS_STDOUT_EMPTY -- the stdout emission produced NO bytes, while a
// nonempty emission was expected. The captured stdout IS the artifact in
// this mode, so an empty capture is a missing artifact.
#define HARNESS_STDOUT_EMPTY          28
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-01 -- THE UNPOPULATED-PREFIX REASON.
//
// The prefix is CONFIGURED (the variable is set and non-empty) but the
// header it must supply is ABSENT. The runner refuses, because the
// alternative -- letting the child fall back to `/usr/local` -- is
// exactly the defect this repair removes.
#define HARNESS_PREFIX_UNPOPULATED  29

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
  if (code == HARNESS_SOURCE_CONTRADICTED) return "HARNESS_SOURCE_CONTRADICTED";
  if (code == HARNESS_OUTPUT_ESCAPED) return "HARNESS_OUTPUT_ESCAPED";
  if (code == HARNESS_OUTPUT_AMBIGUOUS) return "HARNESS_OUTPUT_AMBIGUOUS";
  if (code == HARNESS_SOURCE_AMBIGUOUS) return "HARNESS_SOURCE_AMBIGUOUS";
  if (code == HARNESS_PRODUCER_STAGE_FAILED) return "HARNESS_PRODUCER_STAGE_FAILED";
  if (code == HARNESS_PRODUCER_STAGE_MISMATCH) return "HARNESS_PRODUCER_STAGE_MISMATCH";
  if (code == HARNESS_ENV_BINDING_NOT_IN_FORCE) return "HARNESS_ENV_BINDING_NOT_IN_FORCE";
  if (code == HARNESS_OUTPUT_NOT_INSIDE) return "HARNESS_OUTPUT_NOT_INSIDE";
  if (code == HARNESS_ARGV_CAPACITY) return "HARNESS_ARGV_CAPACITY";
  if (code == HARNESS_OUTPUT_VALUE_MISSING) return "HARNESS_OUTPUT_VALUE_MISSING";
  if (code == HARNESS_SOURCE_NOT_STABLE) return "HARNESS_SOURCE_NOT_STABLE";
  if (code == HARNESS_STDOUT_EMPTY) return "HARNESS_STDOUT_EMPTY";
  if (code == HARNESS_PREFIX_UNPOPULATED) return "HARNESS_PREFIX_UNPOPULATED";
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
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6.
//
// THE SINGLE EXECUTION CONTEXT.
//
// THE ORIGINAL DEFECT. The C4 ROUND 5 independent review found five
// substantive failures whose common cause was that the harness TRUSTED
// CALLER-SUPPLIED FIELDS that were supposed to DESCRIBE one compiler
// execution:
//
//   R5-01  the runner hashed one source and compiled a differently
//          resolved pathname;
//   R5-02  the runner owned the output DIRECTORY but not the output PATH;
//   R5-04  the runner validated a producer and executed a PATHNAME, so
//          the bytes that ran were not the bytes that were qualified;
//   R5-05  the runner RECORDED environment bindings that were never
//          OBSERVED to be in force.
//
// The repair is architectural, not a fourth layer of checks. There is ONE
// context, it is OWNED by the runner, and the runner CONSTRUCTS the
// executable path, the argument vector and the output destinations FROM
// it. A caller may SUPPLY a value; the runner CHECKS it against the
// context and refuses a contradiction. Caller-provided provenance
// metadata never substitutes for an execution-owned fact.
//
// The context is a CLASS, not a parameter list. The production compiler's
// calling convention does not agree with itself about a
// POINTER-TO-POINTER argument at parameter position EIGHT or later, so a
// long parameter list is not usable here.
// ---------------------------------------------------------------------------

class HarnessExecCtx
{
  U8 *producer_path;
  U8 *producer_hex;
  U8 *staged_producer;
  U8 *staged_producer_hex;
  U8 *source_original;
  U8 *source_hex;
  U8 *staged_source;
  U8 *staged_source_hex;
  U8 *output_path;
  U8 *output_basename;
  I64 stdout_mode;
  U8 *install_dir;
  I64 install_dir_supplied;
  U8 **argv;
  I64 nargv;
  U8 **envv;
  I64 nenv;
};

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-01 -- THE HERMETIC INSTALL PREFIX.
//
// THE ORIGINAL DEFECT.
//
// The runner spawned the compiler WITHOUT an `--install-dir` option. The
// production compiler's install prefix therefore fell back to its
// compile-time default, `/usr/local`, and the child failed with
//
//     ERROR: Failed to open file: /usr/local/include/tos.HH
//
// In an isolated checkout with an EMPTY build directory, the local test
// prefix is not populated, so EVERY child failed and eleven of the
// thirty-three positive controls failed with it.
//
// The suite only ever passed in a working tree that a previous
// `make test-prefix-install` had left WARM. That is the warm-tree
// assumption the Factory forbids.
//
// THE REPAIR.
//
// The runner reads the CONFIGURED test prefix from the environment
// variable `HCC_TEST_PREFIX`, and it INJECTS `--install-dir=<prefix>`
// into the child's argument vector when the caller did not already
// supply one.
//
// The channel is the repository's EXISTING convention: `capture.HC`
// already binds `HCC_TEST_PREFIX`, and the Makefile already exports
// `HCC_TEST_PREFIX=$(TEST_PREFIX)` for the capture tool. No competing
// prefix mechanism is introduced.
//
// The injected element is part of the EXECUTED argument vector, so it is
// bound by the event identity and it is recorded verbatim in the capture
// record's ARGV block. A reviewer can therefore READ the child's real
// argv and confirm that the child received the configured prefix and no
// other.
//
// A caller that DOES supply its own `--install-dir` keeps it: the runner
// never overrides an explicit request.
//
// A prefix that is CONFIGURED but ABSENT is a REFUSAL, not a fallback to
// `/usr/local`. Silently degrading to the compile-time default is the
// defect this repair removes, so the runner fails closed instead.
// ---------------------------------------------------------------------------

// The environment variable that carries the CONFIGURED test prefix.
#define HARNESS_PREFIX_ENV "HCC_TEST_PREFIX"

// The platform's own environment reader. It is the FALLBACK channel for
// the configured prefix: the runner's own BINDING LIST is the explicit
// channel, and the process environment is consulted only when the
// binding list carries no prefix.
extern "c" I8 *getenv(U8 *buf);

// The prefix resolver.
//
// It returns the CONFIGURED prefix, or NULL when no prefix is
// configured.
//
// The prefix is read from the RUNNER'S OWN BINDING LIST FIRST, and from
// the runner's PROCESS ENVIRONMENT second. Both channels are the
// repository's existing convention: the Makefile already passes
// `HCC_TEST_PREFIX=$(TEST_PREFIX)` in the binding list of every harness
// invocation, and it exports `HCC_TEST_PREFIX` for the callers that
// drive the probe.
//
// The binding list is preferred because it is EXPLICIT: it is part of the
// invocation, so it is visible in the transcript and it cannot be
// changed by an ambient environment.
//
// The variable's VALUE is returned verbatim. It is NOT resolved to an
// absolute path here: the Makefile already exports an absolute prefix,
// and a relative prefix would be resolved against the CHILD's working
// directory, which is the runner's output directory rather than the
// repository root.
//
// The returned buffer is ALWAYS a fresh allocation, so the caller owns
// it.
static U8 *HarnessConfiguredPrefix(U8 **envv, I64 nenv) {
  // The BINDING LIST is the explicit channel.
  I64 i = 0;
  while (i < nenv) {
    U8 *binding = envv[i];
    if (binding != NULL) {
      U8 *name = NULL;
      U8 *value = NULL;
      if (ContractSplitBinding(binding, &name, &value) != 0) {
        if (StrCmp(name, HARNESS_PREFIX_ENV) == 0) {
          U8 *prefix = value;
          Free(name);
          return prefix;
        }
        Free(name);
        Free(value);
      }
    }
    i = i + 1;
  }
  // The PROCESS ENVIRONMENT is the fallback channel.
  U8 *ambient = getenv(HARNESS_PREFIX_ENV);
  if (ambient == NULL) return NULL;
  I64 len = StrLen(ambient);
  if (len <= 0) return NULL;
  U8 *prefix = MAlloc(len + 1);
  MemCpy(prefix, ambient, len);
  prefix[len] = 0;
  return prefix;
}

// The prefix's POPULATION check.
//
// The prefix is populated when the RUNTIME HEADER it must supply is
// present and non-empty. The header is the artifact the compiler
// actually reads (`<prefix>/include/tos.HH`), so its absence is the
// precise condition under which the child would fail.
//
// It returns 1 when the prefix is populated, and 0 when it is not.
static I64 HarnessPrefixIsPopulated(U8 *prefix) {
  I64 plen = StrLen(prefix);
  U8 *header = MAlloc(plen + 16);
  MemCpy(header, prefix, plen);
  MemCpy(header + plen, "/include/tos.HH", 15);
  I64 ok = 0;
  I64 size = 0;
  U8 *buf = FileRead(header, &size);
  if (buf != NULL) {
    if (size > 0) ok = 1;
    Free(buf);
  }
  Free(header);
  return ok;
}

// The caller's OPTION SCAN.
//
// It finds, in the supplied argument vector, the OUTPUT option and the
// SOURCE argument. It reports how many of each it found, so that an
// AMBIGUOUS vector is refused rather than silently resolved.
//
// The scan recognises the platform's own spellings:
//
//   the output option   `-o <name>`, `--output <name>`, `--output=<name>`
//   the stdout output   `-o-`, `--output=-`
//   the source argument every remaining argument that is not an option's
//                       value and does not begin with `-`
//
// A source argument is any argument that does not begin with `-` and is
// not the value of an option. The scan therefore finds the SOURCE the way
// the compiler does: it is the positional argument.
//
// It returns 0 when the scan is well formed, and a reason code when it
// is not.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-03 -- THE OUTPUT MODE IS A PROPERTY OF THE OPTION, NOT OF ITS VALUE.
//
// THE ORIGINAL DEFECT.
//
// The scan reported the output option's VALUE and nothing else, and the
// caller derived the output MODE from that value:
//
//   if (StrCmp(out_value, "-") == 0) stdout_mode = 1;
//
// The two CLI forms are DIFFERENT:
//
//   -o-     the compiler's OWN zero-argument option. It means "write the
//           assembly to the standard output". It is NOT a path.
//
//   -o -    the ordinary output option with the VALUE "-". The compiler
//           writes a FILE whose name is "-".
//
// The scan set `out_value = "-"` for BOTH, because the `-o-` spelling was
// modelled as an inline value. The caller therefore classified a
// genuine `-o -` request as a STDOUT emission, and the runner REWROTE
// the child's option: the child wrote a file named "-", the runner
// recorded `OUTPUT_MODE STDOUT`, and the capture claimed that the
// standard output carried the artifact.
//
// The mode is now reported by the SCAN, and it is derived from the
// option's SPELLING: the zero-argument stdout spellings are the stdout
// mode, and every other spelling is the file mode.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
// R8-01 -- THE CALLER'S OWN INSTALL PREFIX IS DETECTED.
//
// The scan also reports whether the caller supplied an `--install-dir`
// option of its own, in EITHER spelling:
//
//   --install-dir <path>       the two-element form
//   --install-dir=<path>       the inline form
//
// The runner uses that report to decide whether it must APPEND the
// CONFIGURED prefix. A caller that supplied its own prefix keeps it.
static I64 HarnessScanOptions(U8 **argv, I64 nargv, I64 *n_output,
                               I64 *n_source, U8 **out_value,
                               U8 **src_value, I64 *out_index,
                               I64 *out_value_index, I64 *src_index,
                               I64 *n_install, I64 *out_stdout_mode) {
  *n_output = 0;
  *n_source = 0;
  *out_value = NULL;
  *src_value = NULL;
  *out_index = -1;
  *out_value_index = -1;
  *src_index = -1;
  *n_install = 0;
  *out_stdout_mode = 0;
  I64 i = 0;
  while (i < nargv) {
    U8 *arg = argv[i];
    if (arg == NULL) break;
    // The output option, in its spellings.
    I64 is_output = 0;
    I64 has_inline_value = 0;
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
    // R8-03 -- THE STDOUT SPELLINGS ARE MARKED AS SUCH.
    //
    // The compiler's own zero-argument options are `-o-` and
    // `--output=-`. They are the ONLY spellings that select the stdout
    // mode. Every other spelling -- including `-o -`, whose VALUE is "-"
    // -- selects the file mode.
    I64 is_stdout_spelling = 0;
    if (StrCmp(arg, "-o") == 0) is_output = 1;
    if (StrCmp(arg, "--output") == 0) is_output = 1;
    if (StrCmp(arg, "-o-") == 0) {
      is_output = 1; has_inline_value = 1; is_stdout_spelling = 1;
    }
    if (StrCmp(arg, "--output=-") == 0) {
      is_output = 1; has_inline_value = 1; is_stdout_spelling = 1;
    }
    // The `--output=<name>` spelling carries its value INLINE.
    I64 alen = StrLen(arg);
    if (alen > 8) {
      I64 m = 0;
      I64 same = 1;
      while (m < 8) {
        if (arg[m] != "--output="[m]) { same = 0; break; }
        m = m + 1;
      }
      if (same == 1) { is_output = 1; has_inline_value = 1; }
    }
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
    // R8-01 -- THE INLINE INSTALL-PREFIX SPELLING IS COUNTED.
    //
    // `--install-dir=<path>` is a single element that carries its own
    // value. The scan does not treat it as an output option and does not
    // consume the next element, so it only has to be COUNTED here.
    if (alen > 13) {
      I64 m = 0;
      I64 same = 1;
      while (m < 13) {
        if (arg[m] != "--install-dir="[m]) { same = 0; break; }
        m = m + 1;
      }
      if (same == 1) *n_install = *n_install + 1;
    }
    if (is_output == 1) {
      *n_output = *n_output + 1;
      *out_index = i;
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
      // R8-03 -- THE STDOUT MODE IS SET FROM THE SPELLING.
      //
      // The mode is recorded HERE, where the spelling is known. It is NOT
      // derived later from the option's value, because the value "-" does
      // not distinguish the two CLI forms.
      if (is_stdout_spelling == 1) *out_stdout_mode = 1;
      if (has_inline_value == 1) {
        *out_value_index = i;
        if (alen > 8 && arg[7] == '=') {
          *out_value = arg + 8;
        } else {
          *out_value = "-";
        }
      } else {
        if (i + 1 < nargv) {
          *out_value = argv[i + 1];
          *out_value_index = i + 1;
          i = i + 1;
        } else {
          // An output option with NO value. The vector is malformed.
          //
          // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03,
          // C4 ROUND 7, R6-01 -- THE MALFORMED VECTOR FAILS CLOSED WITH
          // ITS OWN REASON.
          //
          // The previous revision returned the generic usage code, which
          // does not distinguish "the output option has no value" from
          // "the command line is malformed in some other way". The
          // rejection is now SPECIFIC.
          return HARNESS_OUTPUT_VALUE_MISSING;
        }
      }
      i = i + 1;
      continue;
    }
    // A POSITIONAL argument is a source argument. An argument that begins
    // with `-` is an option, and an option's value is consumed with it.
    if (arg[0] != 45) {
      *n_source = *n_source + 1;
      *src_value = arg;
      *src_index = i;
    } else {
      // An option that TAKES A VALUE consumes the next argument, so that
      // the value is not mistaken for a source argument.
      I64 takes_value = 0;
      if (StrCmp(arg, "--install-dir") == 0) takes_value = 1;
      if (StrCmp(arg, "--target") == 0) takes_value = 1;
      if (StrCmp(arg, "-lib") == 0) takes_value = 1;
      if (StrCmp(arg, "-clibs") == 0) takes_value = 1;
      if (StrCmp(arg, "-D") == 0) takes_value = 1;
      // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
      // R8-01 -- THE CALLER'S OWN PREFIX IS COUNTED.
      //
      // The two-element form, `--install-dir <path>`, is counted here. The
      // INLINE form, `--install-dir=<path>`, is counted by the block above,
      // because that block already recognises every `--...=...` spelling.
      if (StrCmp(arg, "--install-dir") == 0) *n_install = *n_install + 1;
      if (takes_value == 1) {
        if (i + 1 < nargv) i = i + 1;
      }
    }
    i = i + 1;
  }
  return HARNESS_OK;
}

// The OUTPUT BASENAME VALIDATOR.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6, R5-02.
//
// The runner GENERATES the basename, so this validator exists for the
// case where the caller supplies one that the runner must agree with.
//
// A basename is valid when:
//
//   * it is NOT EMPTY;
//   * it is NOT an ABSOLUTE path;
//   * it carries NO path separator at all;
//   * it is not the parent-directory component;
//   * it is not the current-directory component;
//   * it is not a name made only of dots.
//
// The check is LEXICAL, and the lexical check alone is not sufficient: a
// path component that is a SYMLINK can redirect the write. The
// containment is therefore established by RESOLUTION as well, in
// `HarnessOutputInside`, which compares the resolved destination against
// the resolved runner-owned directory.
static I64 HarnessValidBasename(U8 *name) {
  if (name == NULL) return HARNESS_OUTPUT_ESCAPED;
  I64 len = StrLen(name);
  if (len == 0) return HARNESS_OUTPUT_ESCAPED;
  // An absolute path.
  if (name[0] == 47) return HARNESS_OUTPUT_ESCAPED;
  // A path separator ANYWHERE in the basename. The basename is a NAME, not
  // a path, so a separator is refused outright rather than normalised.
  I64 k = 0;
  while (k < len) {
    if (name[k] == 47) return HARNESS_OUTPUT_ESCAPED;
    k = k + 1;
  }
  // The parent-directory component and the current-directory component.
  if (StrCmp(name, "..") == 0) return HARNESS_OUTPUT_ESCAPED;
  if (StrCmp(name, ".") == 0) return HARNESS_OUTPUT_ESCAPED;
  // An unsupported path spelling: a name made only of dots.
  I64 dots = 0;
  while (dots < len && name[dots] == 46) dots = dots + 1;
  if (dots == len) return HARNESS_OUTPUT_ESCAPED;
  return HARNESS_OK;
}


// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6, R5-05.
//
// THE PRODUCTION ENVIRONMENT-BINDING QUALIFICATION.
//
// THE ORIGINAL DEFECT. The C4 ROUND 5 review found that the ambient
// `envcheck` mode could not detect a WRONG environment application. The
// mode OBSERVED the ambient environment and never called the production
// applier, so a mutation of `HarnessApplyEnv` that set the WRONG VARIABLE
// NAME left all four of the ambient cases PASSING, while the real `run`
// mode recorded `GOOD=NEEDLE` in the capture record and the child
// observed that `GOOD` was ABSENT.
//
// The defect was in the DETECTOR, not in the committed binding helper:
// the committed helper was correct, and the committed tests could not
// prove it.
//
// THE REPAIR. This mode exercises the SAME `HarnessApplyEnv()`
// IMPLEMENTATION that the production `run` mode uses. There is NO second
// environment-binding implementation: the mode calls the production
// function, and it observes the result in a REAL child process.
//
// THE SEQUENCE, EXACTLY AS THE ACT REQUIRES.
//
//   1. A controlled child execution is STARTED -- the probe is spawned.
//
//   2. The requested environment binding is applied through the REAL
//      production helper, `HarnessApplyEnv()`.
//
//   3. A REAL probe executable is SPAWNED.
//
//   4. The variable NAME and the EXACT VALUE are observed inside the
//      child.
//
//   5. The child's EXIT STATUS is verified.
//
//   6. The observed values are compared against INDEPENDENTLY FROZEN
//      expectations.
//
// The expectations are FROZEN by the caller: the mode is given the
// expected variable name and the expected value, and it observes what the
// child actually saw. A mutation of the production applier therefore
// changes the OBSERVATION, and the mode FAILS.
//
//   harness envbind <probe> <variable-name> <expected-value>
//
// The mode exits 0 when the binding was observed to be in force, and
// non-zero with `HARNESS_ENV_BINDING_NOT_IN_FORCE` when it was not.
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

// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6.
//
// The platform's own path-resolution and mode-change calls.
//
//   realpath(3)  resolves a path to its target, following SYMLINKS. It is
//                what makes the OUTPUT CONTAINMENT check detect a
//                symlinked path component.
//   lstat(2)     reads a path's own metadata, without following a final
//                symlink.
//   chmod(2)     sets the staged producer's executable bit.
extern "c" U8 *realpath(U8 *path, U8 *resolved);
extern "c" I32 lstat(U8 *path, U0 *st);
extern "c" I32 chmod(U8 *path, I32 mode);

// The CONTAINMENT CHECK.
//
// It compares the RESOLVED output destination against the RESOLVED
// runner-owned directory and requires the destination to be INSIDE it.
//
// The resolution is the platform's own `realpath(3)`, so a path component
// that is a SYMLINK is followed to its target and the comparison is made
// against the TARGET. A lexical `..` check alone would not detect a
// symlinked component, because the redirection happens in the filesystem
// and not in the spelling.
//
// It returns 1 when the destination is inside the directory, and 0 when
// it is not.
static I64 HarnessOutputInside(U8 *dir, U8 *dest) {
  U8 *dbuf = MAlloc(4096);
  U8 *pbuf = MAlloc(4096);
  I64 inside = 0;
  // The runner's own directory, resolved. A SYMLINKED component is
  // followed, so the resolved form is the TARGET. On this platform the
  // resolution also normalises `/tmp` to `/private/tmp`, so the resolved
  // form and the SPELLING differ, and the comparison below is made
  // between two RESOLVED forms.
  U8 *rdir = realpath(dir, dbuf);
  // The DESTINATION'S PARENT. The destination itself does not exist yet --
  // it is the file the execution will create -- so `realpath(3)` cannot
  // resolve it, and the PARENT is what carries the containment.
  //
  // The parent is resolved, so a SYMLINKED parent directory is detected:
  // the parent resolves to its TARGET, and the TARGET is compared with
  // the runner's own resolved directory.
  U8 *pparent = realpath(dir, pbuf);
  if (rdir != NULL && pparent != NULL) {
    if (StrCmp(rdir, pparent) == 0) {
      // The destination's parent IS the runner's own directory. The
      // destination's basename was already checked to carry no path
      // separator, and the destination was CONSTRUCTED by the runner as
      // the directory followed by that basename, so the destination IS
      // inside the directory.
      //
      // The destination's own SPELLING is checked against the runner's
      // directory spelling, because the spelling is what the compiler
      // will be given.
      I64 dlen = StrLen(dir);
      I64 slen = StrLen(dest);
      if (dlen > 0 && slen > dlen + 1) {
        I64 m = 0;
        I64 same = 1;
        while (m < dlen) {
          if (dest[m] != dir[m]) { same = 0; break; }
          m = m + 1;
        }
        if (same == 1 && dest[dlen] == 47) inside = 1;
      }
    }
  }
  Free(dbuf);
  Free(pbuf);
  return inside;
}

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
// `lstat(2)`, `realpath(3)` and `stat(2)`. They are declared ABOVE, with
// the other platform declarations.
// The working-directory declarations. They are the platform's own
// `getcwd(3)` and `chdir(2)`.
extern "c" U8 *getcwd(U8 *buf, I64 size);
extern "c" I32 chdir(U8 *path);
// The environment reader, `getenv`, is declared with the CONFIGURED
// PREFIX section above, because that section is where it is used.

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

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6, R5-04.
//
// THE PRODUCER STAGING.
//
// THE ORIGINAL DEFECT. The runner VALIDATED the producer's bytes and then
// SPAWNED a PATHNAME. Between the two there is a window in which the file
// at that pathname can be replaced, and the child then executes bytes the
// runner never qualified. The capture record names the digest the runner
// QUALIFIED, so the record describes an execution that did not happen.
//
// A pathname digest taken BEFORE the spawn does not prove that the bytes
// that eventually executed are those bytes. The reviewer's concurrent
// writer demonstrated exactly that.
//
// THE MECHANISM. The ACT's ordered preference is:
//
//   1. descriptor-backed executable identity;
//   2. a private, runner-owned STAGED executable, copied from the
//      validated producer, whose digest is checked and whose path is used
//      for the invocation;
//   3. an explicitly weaker policy.
//
// MECHANISM (1) IS NOT AVAILABLE TO PolyC. The platform's `fexecve(3)`
// and `execveat(2)` bind an executable to a DESCRIPTOR, and there is NO
// PolyC binding for either: the runtime's `SpawnAndCapture` calls
// `execv(3)`, which takes a PATHNAME, and no `fexecve`/`execveat`
// declaration exists anywhere in `src/`. The mechanism is therefore
// INFEASIBLE in scope, and the runner proceeds to mechanism (2).
//
// MECHANISM (2) IS A REAL BYTE COPY, NOT A HARD LINK. A hard link shares
// the original file's INODE, so the original file's bytes can change
// underneath the link, and the link's digest would change with it. A copy
// has its OWN inode and its OWN bytes.
//
// THE EXECUTABLE BIT IS PRESERVED. The staged copy is made executable, so
// the producer's runtime dependencies and its expected behaviour are
// unchanged. The producer's `--install-dir` and other options travel in
// the ARGUMENT VECTOR, which the runner preserves, so a staged producer
// resolves its headers and its libraries exactly as the original did.
//
// THE THREAT MODEL, STATED.
//
// The guarantee is:
//
//   "The process whose output is accepted executes the SAME PRODUCER BYTES
//    that the harness qualified."
//
// It is established by copying the qualified bytes into the runner's own
// private directory and executing the COPY. The ORIGINAL pathname is no
// longer consulted between the qualification and the execution, so
// replacing the original -- including through a SYMLINKED ANCESTOR --
// cannot change what runs.
//
// A same-user adversary who can modify the runner's OWN private staging
// directory between the copy and the spawn remains OUTSIDE the supported
// trust model. The staging directory is created EXCLUSIVELY by the
// runner, inside the event directory, and the copy is digested
// IMMEDIATELY before the spawn. An adversary with write access to the
// runner's private directory is the adversary who can already replace
// the runner itself.
// ---------------------------------------------------------------------------

// The byte copy. It copies `size` bytes from `buf` into `path`, and it
// makes the destination EXECUTABLE.
//
// The mode is applied with the platform's own `chmod(2)`. The file is
// created with the owner's read and write bits, and the executable bits
// are added afterwards, so the file is never briefly world-writable.
static I64 HarnessStageCopy(U8 *path, U8 *buf, I64 size) {
  I32 fd = open(path, O_RDWR | O_CREAT | O_EXCL, 384); // 0600
  if (fd == -1) return 0;
  I64 written = 0;
  while (written < size) {
    I64 n = write(fd, buf + written, size - written);
    if (n <= 0) { close(fd); return 0; }
    written = written + n;
  }
  close(fd);
  // The executable bit. The owner, group and other execute bits are set,
  // so the staged producer is executable exactly as the original was.
  if (chmod(path, 493) != 0) return 0; // 0755
  return 1;
}

// The producer staging.
//
// It copies the qualified producer's bytes into the runner's own private
// directory, verifies the copy's digest against the qualified digest, and
// returns the staged path.
//
// It returns HARNESS_OK, or the reason the staging failed.
static I64 HarnessStageProducer(U8 *producer, U8 *stage_dir, U8 *expected_hex,
                                U8 **out_path) {
  *out_path = NULL;
  // The source bytes. They are the SAME bytes the runner digested, and
  // they are read AFTER the revalidation, so a producer that changed in
  // between is caught by the digest comparison below.
  I64 size = 0;
  U8 *buf = FileRead(producer, &size);
  if (buf == NULL) return HARNESS_PRODUCER_MISSING;
  // The staged path. The name is fixed, so a REPLAYED staged file cannot
  // occupy it: the file is created EXCLUSIVELY.
  U8 *staged = PathJoin(stage_dir, "producer");
  if (HarnessStageCopy(staged, buf, size) == 0) {
    Free(buf);
    return HARNESS_PRODUCER_STAGE_FAILED;
  }
  Free(buf);
  // The staged copy's digest must be the qualified digest.
  U8 *got = MAlloc(65);
  if (Sha256File(staged, got) == 0) {
    Free(got);
    return HARNESS_PRODUCER_STAGE_FAILED;
  }
  I64 same = 0;
  if (StrCmp(got, expected_hex) == 0) same = 1;
  Free(got);
  if (same == 0) {
    "HARNESS_REASON_DETAIL\tthe staged producer %s does not carry the "
      "qualified digest\n", staged;
    return HARNESS_PRODUCER_STAGE_MISMATCH;
  }
  *out_path = staged;
  return HARNESS_OK;
}

// ---------------------------------------------------------------------------
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
// R5-01 AND R5-02 -- THE ARGUMENT-VECTOR CONSTRUCTION.
//
// THE ORIGINAL DEFECT. The runner COPIED the source into its own
// directory and then compiled the CALLER's pathname. The runner also
// owned the output DIRECTORY but let the CALLER name the output PATH.
// Both were contradictions between what the evidence named and what the
// compiler consumed.
//
// THE REPAIR. The runner CONSTRUCTS the argument vector:
//
//   * the SOURCE argument is the runner's STAGED source;
//   * the OUTPUT option is the runner's OWN output destination;
//   * every other argument is the caller's, unchanged.
//
// The caller's vector is CHECKED against the context before the vector is
// built, and a contradiction is REFUSED. The runner never silently
// resolves a contradiction: it refuses it, because a silent resolution
// would make the evidence describe an execution the caller did not ask
// for.
//
// It returns HARNESS_OK, or the reason the vector was refused.
// ---------------------------------------------------------------------------

// The SOURCE-ARGUMENT REWRITER.
//
// The caller's vector carries a source argument at some position. The
// runner replaces it with the staged source. The caller's source may be
// ABSENT -- the runner then APPENDS the staged source -- because the
// runner owns the source argument and the caller's spelling of it is
// only a statement of intent.
//
// The caller may supply MORE THAN ONE source argument. That is
// ambiguous, and it is refused with `HARNESS_SOURCE_AMBIGUOUS`.
//
// The position of the source argument is found by the SAME scan that
// `HarnessScanOptions` performs, so the two cannot disagree about which
// argument is the source.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
// R6-01 -- THE ARGUMENT-INDEX CONTRACT AND THE OUTPUT-VECTOR CAPACITY.
//
// THE ORIGINAL DEFECT.
//
// The caller converted the scan's indices into the built vector's
// coordinates with `index + 1`. That conversion DESTROYED THE MISSING
// SENTINEL: an absent source or an absent output option carries the
// index `-1`, and `-1 + 1` is `0`, which is a VALID index. The absent
// option therefore became "the executable name at index 0", and the
// runner silently DROPPED the caller's request:
//
//   * an absent SOURCE argument was never injected, so the compiler was
//     executed with no input at all and terminated on a signal (the
//     observed child status was 139);
//   * an absent OUTPUT option was never injected, so the compiler wrote
//     no artifact and the expected artifact was absent.
//
// The capacity was a FIXED `nsupplied + 3`, which is a magic number
// rather than a count of the insertions the builder actually performs.
//
// THE REPAIR.
//
//   * The index contract is ZERO-BASED over the SUPPLIED vector, whose
//     element 0 is the executable name, and `-1` means ABSENT. The
//     conversion is performed ONCE, by `HarnessArgvIndex`, whose ONLY
//     job is to add the offset and which PRESERVES the absent sentinel.
//
//   * The capacity is COMPUTED from the planned insertions BEFORE the
//     allocation:
//
//       CAPACITY =
//         retained_original_arguments
//         + injected_source_arguments
//         + injected_output_arguments
//         + terminating_NULL
//
//   * Every append CHECKS the capacity before it writes.
//
//   * The STDOUT emission is PRESERVED VERBATIM. The compiler's own
//     `-o-` spelling is a first-class output mode, and it is NOT
//     rewritten into a generated filesystem output path.
//
// It returns HARNESS_OK, or the reason the vector was refused.
// ---------------------------------------------------------------------------

// The INDEX CONVERTER.
//
// It converts a scan index -- which is an index into the CALLER's
// arguments, whose element 0 is the FIRST ARGUMENT and not the
// executable name -- into an index into the BUILT vector, whose element 0
// IS the executable name.
//
// The conversion is `scan index + 1`. The ABSENT sentinel is `-1`, and
// the conversion PRESERVES it: an absent index stays absent.
//
// It returns the converted index, or `-1` when the input was absent.
static I64 HarnessArgvIndex(I64 scan_index) {
  if (scan_index < 0) return -1;
  return scan_index + 1;
}

// The OUTPUT-VECTOR BUILDER.
//
// It writes the new vector into the context.
//
// The `src_index`, `out_index` and `out_value_index` are indices into
// the SUPPLIED vector, whose element 0 is the executable name, and `-1`
// means ABSENT. They are produced by `HarnessArgvIndex`.
static I64 HarnessBuildArgv(HarnessExecCtx *ctx, U8 **supplied, I64 nsupplied,
                             I64 src_index, I64 out_index, I64 out_value_index,
                             I64 stdout_mode) {
  // The runner OWNS the output destination. The child's WORKING DIRECTORY
  // is the runner's own output directory, so the destination is named
  // RELATIVELY: the BASENAME, which the compiler resolves inside the
  // child's working directory, and therefore inside the runner's own
  // directory.
  //
  // A RELATIVE name is used deliberately. The production compiler
  // prefixes an ABSOLUTE output path with `./`, so an absolute `-o`
  // argument would not name the runner's destination at all. The
  // containment does not depend on the spelling: the runner constructs
  // the name, the name carries no path separator, and the child's working
  // directory is the runner's own directory.
  //
  // --- THE PLANNED WRITTEN ELEMENTS. --------------------------------------
  //
  // The capacity is computed from the elements the builder WRITES, and it
  // is computed BEFORE the allocation.
  //
  // The accounting is per supplied element, because every supplied element
  // is either RETAINED, REPLACED by an equal number of elements, or
  // EXPANDED into more elements.
  //
  //   the executable name           -> 1 element (the staged producer)
  //   every other retained element  -> 1 element
  //   the source argument           -> 1 element (the staged source);
  //                                    REPLACES the caller's source
  //   the output option             -> 1 element in the FILE mode with a
  //                                    SEPARATE value (`-o name`), 2
  //                                    elements in the FILE mode with an
  //                                    INLINE value (`--output=name`), and
  //                                    1 element in the STDOUT mode
  //                                    (`-o-`), which is retained verbatim
  //   the output option's VALUE     -> 1 element in the FILE mode with a
  //                                    SEPARATE value, 0 otherwise
  //   an APPENDED output option     -> 2 elements, when the caller
  //                                    supplied none
  //   an APPENDED source argument   -> 1 element, when the caller
  //                                    supplied none
  //   an APPENDED install-dir option -> 1 element, when the caller
  //                                    supplied none and a prefix is
  //                                    CONFIGURED
  I64 written = 0;
  // The executable name.
  written = written + 1;
  // The supplied elements, one by one, EXCLUDING the executable name and
  // EXCLUDING the elements that the builder replaces or expands.
  I64 i_plan = 1;
  while (i_plan < nsupplied) {
    // The SOURCE argument. It is REPLACED by one element.
    if (i_plan == src_index && src_index >= 0) {
      written = written + 1;
      i_plan = i_plan + 1;
      continue;
    }
    // The OUTPUT OPTION.
    if (i_plan == out_index && out_index >= 0) {
      if (stdout_mode == 1) {
        // The STDOUT emission. The element is retained verbatim.
        written = written + 1;
      } else {
        // The FILE emission. The option becomes `-o`, and the runner's
        // own destination follows it.
        written = written + 1;
        if (out_value_index >= 0 && out_value_index == i_plan) {
          // The INLINE value. The single supplied element becomes TWO
          // written elements.
          written = written + 1;
        }
      }
      i_plan = i_plan + 1;
      continue;
    }
    // The OUTPUT OPTION'S SEPARATE VALUE. It becomes the runner's own
    // destination: one written element.
    if (out_value_index >= 0 && i_plan == out_value_index && out_index >= 0) {
      written = written + 1;
      i_plan = i_plan + 1;
      continue;
    }
    // Every other element is retained.
    written = written + 1;
    i_plan = i_plan + 1;
  }
  // The APPENDED output option and its value, when the caller supplied
  // no output option at all. The STDOUT mode contributes NOTHING: the
  // caller's `-o-` is preserved verbatim and the runner appends no output
  // option at all.
  I64 inject_output = 0;
  if (stdout_mode == 0) {
    if (out_index < 0) inject_output = 2;
  }
  written = written + inject_output;
  // The APPENDED source argument, when the caller supplied none.
  I64 inject_source = 0;
  if (src_index < 0) inject_source = 1;
  written = written + inject_source;
  // The APPENDED install-dir option.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE PREFIX REACHES THE CHILD.
  //
  // The option is appended ONLY when the caller supplied no
  // `--install-dir` of its own. The caller's own request is never
  // overridden: the runner's job is to make the CONFIGURED prefix reach
  // a child that was given none, not to second-guess a caller that did.
  //
  // It is TWO elements, because the production compiler's option table
  // declares `--install-dir` with arity ONE and no inline value form.
  I64 inject_install = 0;
  if (ctx->install_dir != NULL && ctx->install_dir[0] != 0) {
    if (ctx->install_dir_supplied == 0) inject_install = 2;
  }
  written = written + inject_install;
  //
  // The capacity, and the terminating NULL.
  I64 cap = written + 1;
  if (cap < 1) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    "HARNESS_REASON_DETAIL\tthe argument vector has no capacity\n";
    return HARNESS_USAGE;
  }
  U8 **built = MAlloc(sizeof(U8 *) * cap);
  I64 n = 0;
  I64 i = 0;
  I64 overflow = 0;
  while (i < nsupplied) {
    // The EXECUTABLE NAME. The runner replaces it with the staged
    // producer, so the executed path is the runner's own.
    if (i == 0) {
      if (n + 1 > cap - 1) { overflow = 1; break; }
      built[n] = ctx->staged_producer;
      n = n + 1;
      i = i + 1;
      continue;
    }
    // The SOURCE argument. It becomes the runner's staged source.
    if (i == src_index && src_index >= 0) {
      if (n + 1 > cap - 1) { overflow = 1; break; }
      built[n] = ctx->staged_source;
      n = n + 1;
      i = i + 1;
      continue;
    }
    // The OUTPUT OPTION. Its VALUE becomes the runner's destination.
    //
    // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
    // R6-02 -- THE STDOUT EMISSION IS PRESERVED VERBATIM.
    //
    // The compiler's own `-o-` spelling means "write to the standard
    // output". It is NOT a filesystem path, and it is NOT a request for
    // a generated destination. The runner therefore RETAINS the caller's
    // element unchanged, and it writes NO output option of its own.
    //
    // The previous revision rewrote the option into `-o <basename>`, so
    // the compiler wrote an assembly FILE where the caller had asked for
    // the standard output. The captured stdout was empty, an unintended
    // artifact appeared, and the capture record nevertheless claimed
    // `OUTPUT_MODE STDOUT`.
    if (i == out_index && out_index >= 0) {
      if (stdout_mode == 1) {
        // The STDOUT emission. The element is retained verbatim.
        if (n + 1 > cap - 1) { overflow = 1; break; }
        built[n] = supplied[i];
        n = n + 1;
        i = i + 1;
        continue;
      }
      if (n + 1 > cap - 1) { overflow = 1; break; }
      built[n] = "-o";
      n = n + 1;
      // The option's VALUE is skipped: it is replaced below.
      if (out_value_index >= 0) {
        if (out_value_index == i) {
          // The `--output=<name>` spelling: the value is INLINE, so the
          // whole option is replaced by the runner's own two elements.
          if (n + 1 > cap - 1) { overflow = 1; break; }
          built[n] = ctx->output_basename;
          n = n + 1;
          i = i + 1;
          continue;
        }
        i = i + 1;
        continue;
      }
      i = i + 1;
      continue;
    }
    // The OUTPUT OPTION'S VALUE, when the option was `--output <name>`.
    if (out_value_index >= 0 && i == out_value_index && out_index >= 0) {
      if (n + 1 > cap - 1) { overflow = 1; break; }
      built[n] = ctx->output_basename;
      n = n + 1;
      i = i + 1;
      continue;
    }
    if (n + 1 > cap - 1) { overflow = 1; break; }
    built[n] = supplied[i];
    n = n + 1;
    i = i + 1;
  }
  if (overflow == 1) {
    Free(built);
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ARGV_CAPACITY);
    "HARNESS_REASON_DETAIL\tthe argument vector exceeded its computed "
      "capacity\n";
    return HARNESS_ARGV_CAPACITY;
  }
  // The STDOUT emission is PRESERVED. The caller's `-o-` was already
  // carried in the supplied vector, and it was RETAINED verbatim by the
  // loop above. The runner appends NO output option and NO output value,
  // because the stdout emission is not a filesystem destination.
  //
  // The FILE emission is different. The caller supplied NO output option,
  // so the runner supplies its own, and the destination is always the
  // runner's.
  if (stdout_mode == 0) {
    if (out_index < 0) {
      if (n + 1 > cap - 1) {
        Free(built);
        "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ARGV_CAPACITY);
        "HARNESS_REASON_DETAIL\tthe argument vector exceeded its computed "
          "capacity\n";
        return HARNESS_ARGV_CAPACITY;
      }
      built[n] = "-o";
      n = n + 1;
      if (n + 1 > cap - 1) {
        Free(built);
        "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ARGV_CAPACITY);
        "HARNESS_REASON_DETAIL\tthe argument vector exceeded its computed "
          "capacity\n";
        return HARNESS_ARGV_CAPACITY;
      }
      built[n] = ctx->output_basename;
      n = n + 1;
    }
  }
  // The caller supplied NO source argument. The runner supplies its own.
  if (src_index < 0) {
    if (n + 1 > cap - 1) {
      Free(built);
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ARGV_CAPACITY);
      "HARNESS_REASON_DETAIL\tthe argument vector exceeded its computed "
        "capacity\n";
      return HARNESS_ARGV_CAPACITY;
    }
    built[n] = ctx->staged_source;
    n = n + 1;
  }
  // The APPENDED install-dir option.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX REACHES THE CHILD.
  //
  // The option is emitted in the production compiler's OWN TWO-ELEMENT
  // form, `--install-dir <path>`. The production option table declares
  // `--install-dir` with arity ONE and no INLINE value form, so the
  // single-element spelling `--install-dir=<path>` is REFUSED by the
  // compiler with "Unknown commandline options". The runner therefore
  // emits the form the compiler accepts.
  //
  // The option is appended only when the caller supplied no
  // `--install-dir` of its own AND a prefix is CONFIGURED. A caller that
  // supplied its own keeps it: the runner never overrides an explicit
  // request.
  //
  // This is the whole hermetic repair: the child receives the CONFIGURED
  // test prefix, so the runtime header and the runtime archive it reads
  // come from the LOCAL prefix and never from `/usr/local`.
  if (ctx->install_dir != NULL && ctx->install_dir[0] != 0) {
    if (ctx->install_dir_supplied == 0) {
      if (n + 2 > cap - 1) {
        Free(built);
        "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ARGV_CAPACITY);
        "HARNESS_REASON_DETAIL\tthe argument vector exceeded its computed "
          "capacity\n";
        return HARNESS_ARGV_CAPACITY;
      }
      built[n] = "--install-dir";
      n = n + 1;
      built[n] = ctx->install_dir;
      n = n + 1;
    }
  }
  // The terminating NULL. The capacity reserved it.
  built[n] = NULL;
  ctx->argv = built;
  ctx->nargv = n;
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
  // The caller's ARGUMENTS, without the executable name. The executable is
  // the runner's own staged copy, and the runner builds the final vector.
  U8 **caller_args = MAlloc(sizeof(U8 *) * (nargv + 1));
  a = 1;
  while (a < nargv) {
    caller_args[a - 1] = supplied_argv[a];
    a = a + 1;
  }
  caller_args[nargv - 1] = NULL;
  I64 ncaller = nargv - 1;

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-01 AND R5-02 -- THE CALLER'S VECTOR IS SCANNED AND CHECKED.
  //
  // The scan finds the caller's OUTPUT option and SOURCE argument. An
  // AMBIGUOUS vector -- more than one output option, or more than one
  // source argument -- is REFUSED, because the runner cannot tell which
  // one the caller meant, and a silent resolution would make the evidence
  // describe an execution the caller did not ask for.
  I64 n_output = 0;
  I64 n_source = 0;
  U8 *out_value = NULL;
  U8 *src_value = NULL;
  I64 out_index = -1;
  I64 out_value_index = -1;
  I64 src_index = -1;
  I64 n_install = 0;
  I64 out_stdout_mode = 0;
  I64 sc = HarnessScanOptions(caller_args, ncaller, &n_output, &n_source,
                              &out_value, &src_value, &out_index,
                              &out_value_index, &src_index, &n_install,
                              &out_stdout_mode);
  if (sc != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(sc);
    return sc;
  }
  if (n_output > 1) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_AMBIGUOUS);
    "HARNESS_REASON_DETAIL\tthe argument vector carries %lld output options\n",
      n_output;
    return HARNESS_OUTPUT_AMBIGUOUS;
  }
  if (n_source > 1) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SOURCE_AMBIGUOUS);
    "HARNESS_REASON_DETAIL\tthe argument vector carries %lld source "
      "arguments\n", n_source;
    return HARNESS_SOURCE_AMBIGUOUS;
  }

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX IS RESOLVED AND CHECKED.
  //
  // The prefix is resolved from the CONFIGURED environment variable, and
  // it is checked for POPULATION before the child is spawned.
  //
  // A CONFIGURED but UNPOPULATED prefix is a REFUSAL. The alternative --
  // spawning the child and letting it fall back to `/usr/local` -- is
  // the defect this repair removes, and a fallback would also make the
  // evidence depend on the host's ambient installation.
  //
  // The caller's OWN prefix, when it supplied one, is left alone: the
  // runner does not re-check a prefix it did not configure.
  U8 *configured_prefix = HarnessConfiguredPrefix(envv, nenv);
  I64 caller_supplied_install = 0;
  if (n_install > 0) caller_supplied_install = 1;
  if (configured_prefix != NULL) {
    if (caller_supplied_install == 0) {
      if (HarnessPrefixIsPopulated(configured_prefix) == 0) {
        "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_PREFIX_UNPOPULATED);
        "HARNESS_REASON_DETAIL\tthe configured prefix %s does not supply "
          "include/tos.HH\n", configured_prefix;
        Free(configured_prefix);
        return HARNESS_PREFIX_UNPOPULATED;
      }
    }
  }

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

  // --- STEP 2: ALLOCATE THE EVENT DIRECTORY, BEFORE THE EXECUTION. ------
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6.
  //
  // THE ORDERING. The event identity is computed over the EXECUTED
  // argument vector, and the executed argument vector names the runner's
  // own STAGED paths, which live INSIDE the event directory. The identity
  // therefore cannot be computed before the event directory exists.
  //
  // The event directory is therefore allocated FIRST, under a name that is
  // UNIQUE within the run context: the MONOTONIC EVENT COUNTER, which is
  // already part of the event identity. The directory is still allocated
  // EXCLUSIVELY, so a replayed directory is refused, and the identity is
  // still computed over the executed argument vector and is still unique
  // per event.
  //
  // The counter is rendered as decimal. It is the SAME value the identity
  // is computed from, so a reviewer can recompute the identity.
  event_counter = event_counter + 1;
  U8 ctr_text[24];
  I64 ctr_len = 0;
  {
    I64 v = event_counter;
    I64 n = 0;
    if (v == 0) { ctr_text[0] = 48; n = 1; }
    while (v > 0) { ctr_text[n] = 48 + (v % 10); v = v / 10; n = n + 1; }
    U8 rev[24];
    I64 w = 0;
    while (w < n) { rev[w] = ctr_text[n - 1 - w]; w = w + 1; }
    w = 0;
    while (w < n) { ctr_text[w] = rev[w]; w = w + 1; }
    ctr_text[n] = 0;
    ctr_len = n;
  }

  // --- STEP 3: CREATE THE FRESH PER-CASE DIRECTORY. -----------------------
  //
  // The directory is FRESH: it is created with a name that carries the
  // event counter, so a REPLAYED artifact from an earlier event cannot
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
  U8 *event_dir = PathJoin(case_dir, ctr_text);
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
  // The runner's OWN output destination. It is the ABSOLUTE path inside
  // the runner's own directory.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-02 -- THE RUNNER OWNS THE OUTPUT PATH, NOT MERELY THE DIRECTORY.
  //
  // THE ORIGINAL DEFECT. The runner allocated the output directory and
  // then let the CALLER name the output PATH. A caller could therefore
  // name `-o ../../../escaped.o`, the compiler would write OUTSIDE the
  // runner's directory, and the runner would look for the artifact where
  // the caller said it would be.
  //
  // THE REPAIR.
  //
  //   * The runner GENERATES the output basename. The caller's
  //     `<artifact-name>` argument is the EXPECTED artifact's name, and it
  //     is used as the basename only when it is a valid basename; the
  //     runner refuses a name that could escape.
  //
  //   * The runner CONSTRUCTS the `-o` argument, and the constructed value
  //     is the ABSOLUTE path of the destination inside the runner's own
  //     directory.
  //
  //   * The caller's output option, when it supplies one, is CHECKED
  //     against the runner's destination. A caller's value that does not
  //     name the runner's own basename is REFUSED with
  //     `HARNESS_OUTPUT_ESCAPED`.
  //
  //   * The STDOUT emission (`-o-`) is an EXPLICITLY MODELLED SPECIAL
  //     CASE. It is not a filesystem path, so the runner writes no output
  //     option and the artifact is absent by construction.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-03 -- THE MODE COMES FROM THE SCAN, NOT FROM THE VALUE.
  //
  // The previous revision derived the mode from the option's VALUE:
  //
  //   if (StrCmp(out_value, "-") == 0) stdout_mode = 1;
  //
  // That conflated the two CLI forms. `-o -` names a FILE whose name is
  // "-", and the compiler writes that file; `-o-` is the compiler's own
  // zero-argument option and it writes to the standard output. The
  // value "-" does not distinguish them, but the SPELLING does, and the
  // scan has already reported it.
  //
  // The mode is therefore taken from the scan's report. A `-o -` request
  // is now the FILE mode: the runner owns the output path, and the
  // child's `-o -` is rewritten into the runner's own destination.
  I64 stdout_mode = out_stdout_mode;
  // The runner's BASENAME. The runner OWNS the basename, and the
  // caller's output option, when it supplies one, must AGREE with it.
  //
  // The agreement is on the BASENAME: the caller names the artifact it
  // expects, and the runner refuses a name that could leave the runner's
  // directory. The runner's own artifact name is the one the caller
  // NAMED, because the caller is the one that will look for it.
  //
  // A caller that supplies NO output option leaves the runner with the
  // `<artifact-name>` argument, which is the runner's own default.
  if (stdout_mode == 0 && out_value != NULL && n_output == 1) {
    I64 bval = HarnessValidBasename(out_value);
    if (bval != HARNESS_OK) {
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_ESCAPED);
      "HARNESS_REASON_DETAIL\tthe output option names %s, which is not a "
        "plain file name\n", out_value;
      return HARNESS_OUTPUT_ESCAPED;
    }
    // The caller's basename becomes the runner's basename. The runner
    // then constructs the `-o` argument from it, so the destination is
    // ALWAYS inside the runner's own directory.
    artifact_name = out_value;
  }
  // The artifact name itself must be a valid basename.
  if (HarnessValidBasename(artifact_name) != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_ESCAPED);
    "HARNESS_REASON_DETAIL\tthe artifact name %s is not a plain file name\n",
      artifact_name;
    return HARNESS_OUTPUT_ESCAPED;
  }
  U8 *artifact_path = PathJoin(out_dir, artifact_name);
  // The CONTAINMENT is established by RESOLUTION, not only by the lexical
  // checks above. A path component that is a SYMLINK would redirect the
  // write, and the resolution is what detects it.
  if (HarnessOutputInside(out_dir, artifact_path) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_NOT_INSIDE);
    "HARNESS_REASON_DETAIL\tthe output destination %s does not resolve "
      "inside %s\n", artifact_path, out_dir;
    return HARNESS_OUTPUT_NOT_INSIDE;
  }
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

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-01 -- THE SOURCE IS AN EXECUTION-OWNED SNAPSHOT.
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE STAGED SNAPSHOT IS THE AUTHORITATIVE COMPILATION INPUT.
  //
  // THE ORIGINAL DEFECT. The runner hashed the ORIGINAL source, and it
  // staged a SEPARATE snapshot. The compiler consumed the snapshot, but
  // the capture record and the event identity authenticated the ORIGINAL
  // digest. A source that changed between the two observations therefore
  // produced evidence that described a compilation of bytes the
  // compilation never used.
  //
  // The reviewer's counterexample was:
  //
  //   ORIGINAL_SOURCE_BEHAVIOR=return 0
  //   COMPILED_SNAPSHOT_BEHAVIOR=return 42
  //   COMPARATOR=PASS 29/29
  //
  // THE REPAIR -- THE REQUIRED SEQUENCE.
  //
  //   1. Read the requested source.
  //   2. Create the runner-owned snapshot.
  //   3. Hash the ACTUAL STAGED BYTES -- read back from the staged file,
  //      not from the original path.
  //   4. Confirm that the staged file matches the bytes intended for
  //      execution.
  //   5. Construct the argv using that staged source.
  //   6. Execute the compiler.
  //   7. Record the staged-source digest in the event identity.
  //   8. Preserve the distinction between the original requested source
  //      and the compiled snapshot.
  //   9. Independently validate the compiled snapshot identity during
  //      comparison.
  //
  // The ORIGINAL source's digest is recorded as the ORIGINAL's digest.
  // It is NEVER recorded as the compiled-source digest unless equality
  // has actually been established.
  U8 *source_copy = PathJoin(out_dir, "source.HC");
  I64 ssize = 0;
  U8 *sbuf = FileRead(source, &ssize);
  if (sbuf == NULL) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_INPUT_UNREADABLE);
    "HARNESS_REASON_DETAIL\tthe source %s could not be read\n", source;
    return HARNESS_INPUT_UNREADABLE;
  }
  // The snapshot is written into the runner's own FRESH directory, and the
  // compiler's source argument is that path.
  if (WriteFile(source_copy, sbuf, ssize) == 0) {
    Free(sbuf);
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_OUTPUT_DIR_FAILED);
    "HARNESS_REASON_DETAIL\tthe source copy could not be written\n";
    return HARNESS_OUTPUT_DIR_FAILED;
  }
  // STEP 3 -- THE DIGEST OF THE ACTUAL STAGED BYTES.
  //
  // The digest is computed from the file that was WRITTEN, read back from
  // the disk. It is therefore the digest of the bytes the compiler will
  // consume, and not of the file the caller named.
  U8 *snapshot_hex = MAlloc(65);
  if (Sha256File(source_copy, snapshot_hex) == 0) {
    Free(sbuf);
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SOURCE_NOT_STABLE);
    "HARNESS_REASON_DETAIL\tthe staged source %s could not be read back\n",
      source_copy;
    return HARNESS_SOURCE_NOT_STABLE;
  }
  // STEP 4 -- THE STAGED FILE MUST MATCH THE BYTES INTENDED FOR EXECUTION.
  //
  // The bytes that were read are hashed and compared with the digest of
  // the file that was written. A write that did not land, or a file that
  // was replaced between the write and the read-back, is REFUSED: the
  // runner cannot demonstrate a CONSISTENT snapshot, and it will not
  // compile an input whose identity it cannot establish.
  U8 *intended_hex = MAlloc(65);
  U8 *intended_digest = MAlloc(32);
  Sha256Bytes(sbuf, ssize, intended_digest);
  Sha256Hex(intended_hex, intended_digest);
  Free(intended_digest);
  Free(sbuf);
  I64 snapshot_consistent = 0;
  if (StrCmp(intended_hex, snapshot_hex) == 0) snapshot_consistent = 1;
  Free(intended_hex);
  if (snapshot_consistent == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SOURCE_NOT_STABLE);
    "HARNESS_REASON_DETAIL\tthe staged source %s does not carry the bytes "
      "that were read\n", source_copy;
    return HARNESS_SOURCE_NOT_STABLE;
  }
  // The ORIGINAL source's digest is the digest of the file at the path
  // the caller named. It is recorded as such, and NEVER as the compiled
  // source's digest.
  //
  // The equality between the original and the snapshot is ESTABLISHED
  // here, by comparing the two digests, and it is recorded as its own
  // fact, so that a reviewer can see whether the two are the same file
  // or two different ones.
  I64 original_equals_snapshot = 0;
  if (StrCmp(source_hex, snapshot_hex) == 0) original_equals_snapshot = 1;
  // The caller's SOURCE argument must AGREE with the source the runner
  // staged. The runner owns the source argument, so a contradiction is
  // REFUSED rather than resolved: the evidence would otherwise describe
  // a compilation of a file the caller did not name.
  if (n_source == 1 && src_value != NULL) {
    I64 agrees = 0;
    if (StrCmp(src_value, source) == 0) agrees = 1;
    if (agrees == 0) {
      // The two are compared by their RESOLVED forms, so that the same
      // file named in two different ways is recognised as the same file.
      U8 *rbuf_a = MAlloc(4096);
      U8 *rbuf_b = MAlloc(4096);
      U8 *resolved = realpath(src_value, rbuf_a);
      if (resolved != NULL) {
        U8 *presolved = realpath(source, rbuf_b);
        if (presolved != NULL) {
          if (StrCmp(resolved, presolved) == 0) agrees = 1;
        }
      }
      Free(rbuf_a);
      Free(rbuf_b);
    }
    if (agrees == 0) {
      "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_SOURCE_CONTRADICTED);
      "HARNESS_REASON_DETAIL\tthe argument vector names the source %s, but "
        "the recorded source is %s\n", src_value, source;
      return HARNESS_SOURCE_CONTRADICTED;
    }
  }

  // --- STEP 3C: RE-VALIDATE AND STAGE THE PRODUCER. -----------------------
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-04 -- THE EXECUTED PRODUCER IS A RUNNER-OWNED STAGED COPY.
  //
  // The producer's identity, architecture and digest are established from
  // the BYTES ON DISK one more time, at the last possible moment before
  // the staging, and the digest is compared with the digest that was
  // recorded at the start of the run. A producer whose bytes were
  // REPLACED in between is refused.
  I64 rv = HarnessRevalidateProducer(producer, expected_arch, producer_hex);
  if (rv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(rv);
    return rv;
  }
  // The STAGING directory. It is inside the runner's own event directory
  // and it is created EXCLUSIVELY.
  U8 *stage_dir = PathJoin(event_dir, "stage");
  if (mkdir(stage_dir, 493) != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_PRODUCER_STAGE_FAILED);
    "HARNESS_REASON_DETAIL\tthe staging directory %s already exists\n",
      stage_dir;
    return HARNESS_PRODUCER_STAGE_FAILED;
  }
  U8 *staged_producer = NULL;
  I64 sv = HarnessStageProducer(producer, stage_dir, producer_hex,
                                &staged_producer);
  if (sv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(sv);
    return sv;
  }
  // The staged producer's digest is re-read IMMEDIATELY before the spawn,
  // so that a modification of the staged copy is detected.
  U8 *stage_now = MAlloc(65);
  I64 stage_ok = 0;
  if (Sha256File(staged_producer, stage_now) == 1) {
    if (StrCmp(stage_now, producer_hex) == 0) stage_ok = 1;
  }
  Free(stage_now);
  if (stage_ok == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_PRODUCER_STAGE_MISMATCH);
    "HARNESS_REASON_DETAIL\tthe staged producer %s changed between the "
      "staging and the invocation\n", staged_producer;
    return HARNESS_PRODUCER_STAGE_MISMATCH;
  }

  // --- STEP 3D: BUILD THE EXECUTION CONTEXT'S ARGUMENT VECTOR. -----------
  //
  // The runner CONSTRUCTS the vector: the executable is the staged
  // producer, the source is the staged source, and the output is the
  // runner's own destination.
  HarnessExecCtx ctx;
  ctx.producer_path = producer;
  ctx.producer_hex = producer_hex;
  ctx.staged_producer = staged_producer;
  ctx.staged_producer_hex = producer_hex;
  ctx.source_original = source;
  ctx.source_hex = source_hex;
  ctx.staged_source = source_copy;
  ctx.staged_source_hex = snapshot_hex;
  ctx.output_path = artifact_path;
  ctx.output_basename = artifact_name;
  ctx.stdout_mode = stdout_mode;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE CONFIGURED PREFIX ENTERS THE EXECUTION CONTEXT.
  //
  // The prefix is the CONFIGURED one, and it is handed to the builder
  // only when the caller supplied none of its own.
  ctx.install_dir = configured_prefix;
  ctx.install_dir_supplied = caller_supplied_install;
  ctx.envv = envv;
  ctx.nenv = nenv;
  // The caller's ARGUMENTS, with the executable name restored at the
  // front, so that the builder's indices line up with the caller's
  // vector.
  U8 **full_args = MAlloc(sizeof(U8 *) * (ncaller + 2));
  full_args[0] = producer;
  a = 0;
  while (a < ncaller) {
    full_args[a + 1] = caller_args[a];
    a = a + 1;
  }
  full_args[ncaller + 1] = NULL;
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-01 -- THE INDEX CONVERSION IS EXPLICIT AND SENTINEL-PRESERVING.
  //
  // The scan ran over `caller_args`, whose element 0 is the FIRST
  // ARGUMENT. The builder works over `full_args`, whose element 0 is the
  // EXECUTABLE NAME. The conversion is `scan index + 1`, and the ABSENT
  // sentinel `-1` is PRESERVED by `HarnessArgvIndex`.
  //
  // The previous revision performed the addition INLINE, so an absent
  // source and an absent output option both became the valid index 0.
  I64 argv_src_index = HarnessArgvIndex(src_index);
  I64 argv_out_index = HarnessArgvIndex(out_index);
  I64 argv_out_value_index = HarnessArgvIndex(out_value_index);
  I64 bv = HarnessBuildArgv(&ctx, full_args, ncaller + 1, argv_src_index,
                            argv_out_index, argv_out_value_index, stdout_mode);
  if (bv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(bv);
    return bv;
  }
  U8 **exec_argv = ctx.argv;
  I64 exec_argc = ctx.nargv;

  // --- STEP 3E: ALLOCATE THE EVENT IDENTITY, BEFORE THE EXECUTION. --------
  //
  // The identity is computed over the EXECUTED argument vector, so it
  // binds the exact bytes that will be executed and the exact arguments
  // they are given. It is allocated BEFORE the execution, and the event
  // counter is part of it, so two executions -- even two deterministic
  // repetitions of the same case -- receive different identities.
  //
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
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE IDENTITY BINDS THE COMPILED BYTES.
  //
  // `source_hex` is the ORIGINAL source's digest and
  // `compiled_source_hex` is the STAGED SNAPSHOT's digest: the bytes the
  // compiler ACTUALLY consumed. Both are in the identity, in separate
  // tagged fields, so an identity can never authenticate a file that the
  // compilation did not use.
  id_ctx.compiled_source_hex = snapshot_hex;
  id_ctx.fixture_hex = fixture_hex;
  id_ctx.argv = exec_argv;
  id_ctx.nargv = exec_argc;
  id_ctx.envv = NULL;
  id_ctx.nenv = 0;
  EventIdEnvCtx id_env;
  id_env.envv = envv;
  id_env.nenv = nenv;
  U8 *event_id = HarnessEventId(&id_ctx, &id_env);

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
  //
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-02 -- THE STDOUT MODE'S ARTIFACT IS THE CAPTURED STDOUT STREAM.
  //
  // In the STDOUT mode there is NO filesystem artifact: the compiler
  // wrote to its standard output, and the runner captured those bytes.
  // The artifact of this mode is therefore the CAPTURED STDOUT, and its
  // presence and its digest are derived from the ACTUAL captured bytes.
  //
  // The previous revision read the filesystem path in BOTH modes, so a
  // STDOUT run recorded the digest of an unintended assembly FILE and
  // claimed the mode was STDOUT.
  I64 artifact_present = 0;
  U8 *artifact_hex = MAlloc(65);
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
  if (stdout_mode == 1) {
    // The STDOUT artifact. Its digest is the digest of the CAPTURED
    // STDOUT bytes, which were measured above.
    MemCpy(artifact_hex, stdout_hex, 65);
    if (outlen > 0) artifact_present = 1;
  } else {
    if (Sha256File(artifact_path, artifact_hex) == 1) {
      artifact_present = 1;
    } else {
      // An absent artifact is recorded with the sentinel
      // "ABSENT", which is NOT a digest. A digest is always 64 hexadecimal
      // digits, so the comparator can tell the two apart.
      MemCpy(artifact_hex, "ABSENT", 7);
    }
  }

  RecInit();
  // The event counter was rendered as decimal in STEP 2. It is the value
  // the event identity was computed from, so a reviewer can recompute the
  // identity from the record.
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
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE COMPILED SOURCE'S DIGEST IS ITS OWN FIELD.
  //
  // `SOURCE_SHA256` is the ORIGINAL source's digest: the file at the path
  // the caller named. It is NOT the digest of the bytes that were
  // compiled, and it never was.
  //
  // `COMPILED_SOURCE_SHA256` is the digest of the STAGED snapshot -- the
  // bytes the compiler actually consumed -- and it is the digest that the
  // event identity binds.
  RecField("SOURCE_SHA256", source_hex);
  RecField("COMPILED_SOURCE_SHA256", snapshot_hex);
  // The equality between the original and the compiled snapshot is a
  // separate, ESTABLISHED fact, and not an inference a reader has to
  // make.
  U8 *equals_text = "0";
  if (original_equals_snapshot == 1) equals_text = "1";
  RecField("ORIGINAL_EQUALS_COMPILED", equals_text);
  RecField("FIXTURE_SHA256", fixture_hex);
  RecField("EXIT_STATUS", exit_text);
  RecField("STDOUT_SHA256", stdout_hex);
  RecField("STDERR_SHA256", stderr_hex);
  RecField("ARTIFACT_SHA256", artifact_hex);
  U8 *present_text = "0";
  if (artifact_present == 1) present_text = "1";
  RecField("ARTIFACT_PRESENT", present_text);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-02 -- THE ARTIFACT PATH NAMES THE ARTIFACT THAT WAS ACTUALLY
  // PRODUCED.
  //
  // In the FILE mode the artifact is the filesystem path inside the
  // runner's own directory. In the STDOUT mode the artifact IS the
  // captured standard output, so the path that is recorded is the
  // stdout capture file. Recording the filesystem path in the STDOUT
  // mode would name a file that the execution did not produce.
  if (stdout_mode == 1) {
    RecField("ARTIFACT_PATH", stdout_path);
  } else {
    RecField("ARTIFACT_PATH", artifact_path);
  }
  RecField("EVENT_DIR", event_dir);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 5, R4-03.
  //
  // The RUNNER-CONTROLLED OUTPUT DIRECTORY and the EXECUTED EXECUTABLE are
  // recorded, so that a reviewer can see that the observation came from the
  // runner's own directory and that the executable the runner spawned is
  // the producer it validated.
  RecField("OUTPUT_DIR", out_dir);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6,
  // R5-01, R5-02 AND R5-04 -- THE EXECUTION-OWNED FACTS.
  //
  // The capture record names the facts the runner OWNED, and it
  // distinguishes the ROLES of the original and the staged identities, so
  // that a reviewer can see exactly which bytes were compiled and which
  // bytes were executed.
  //
  //   STAGED_PRODUCER      the runner-owned copy that was EXECUTED
  //   STAGED_PRODUCER_SHA256 its digest, which equals the qualified digest
  //   ORIGINAL_SOURCE      the source the caller NAMED
  //   ORIGINAL_SOURCE_SHA256 the digest of the file at that path
  //   STAGED_SOURCE        the runner-owned snapshot that was COMPILED
  //   STAGED_SOURCE_SHA256 the digest of the snapshot bytes
  //   OUTPUT_MODE          FILE for a filesystem destination, STDOUT for
  //                        the `-o-` emission, which is not a path at all
  RecField("EXECUTED_EXECUTABLE", staged_producer);
  RecField("STAGED_PRODUCER", staged_producer);
  RecField("STAGED_PRODUCER_SHA256", producer_hex);
  RecField("ORIGINAL_SOURCE", source);
  RecField("ORIGINAL_SOURCE_SHA256", source_hex);
  RecField("STAGED_SOURCE", source_copy);
  RecField("STAGED_SOURCE_SHA256", snapshot_hex);
  U8 *output_mode_text = "FILE";
  if (stdout_mode == 1) output_mode_text = "STDOUT";
  RecField("OUTPUT_MODE", output_mode_text);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 7,
  // R6-03 -- THE SCHEMA VERSION IS TAKEN FROM THE SHARED CONTRACT.
  //
  // The previous revision wrote a HARDCODED "2", so a record could claim
  // a schema that the identity did not use. The version is now rendered
  // from `EVENT_ID_SCHEMA_VERSION`, which is the SAME constant the
  // identity computation uses, so the record and the identity can never
  // disagree about the schema.
  U8 schema_text[8];
  I64 schema_len = 0;
  I64 schema_v = EVENT_ID_SCHEMA_VERSION;
  if (schema_v == 0) { schema_text[0] = 48; schema_len = 1; }
  while (schema_v > 0) {
    schema_text[schema_len] = 48 + (schema_v % 10);
    schema_v = schema_v / 10;
    schema_len = schema_len + 1;
  }
  U8 schema_rev[8];
  I64 schema_w = 0;
  while (schema_w < schema_len) {
    schema_rev[schema_w] = schema_text[schema_len - 1 - schema_w];
    schema_w = schema_w + 1;
  }
  schema_rev[schema_len] = 0;
  schema_text[schema_len] = 0;
  MemCpy(schema_text, schema_rev, schema_len + 1);
  RecField("EVENT_ID_SCHEMA", schema_text);
  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 8,
  // R8-01 -- THE PREFIX THE CHILD RECEIVED IS RECORDED.
  //
  // The field names the prefix that the EXECUTED argument vector carried.
  // A reviewer reads it to confirm that the child was pointed at the
  // CONFIGURED local prefix and not at the host's ambient installation.
  //
  // The value is `NONE` when the child received no `--install-dir` at
  // all, which happens only when no prefix was configured AND the caller
  // supplied none.
  U8 *install_dir_text = "NONE";
  if (configured_prefix != NULL) install_dir_text = configured_prefix;
  if (caller_supplied_install == 1) install_dir_text = "CALLER_SUPPLIED";
  RecField("INSTALL_DIR", install_dir_text);
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
static I64 HarnessEnvBind(I32 argc, U8 **argv) {
  if (argc < 7) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_USAGE);
    "HARNESS_USAGE\tharness envbind <probe> <bind-name> <bind-value> "
      "<observe-name> <expect-value>\n";
    return HARNESS_USAGE;
  }
  U8 *probe = argv[2];
  U8 *varname = argv[3];
  U8 *bind_value = argv[4];
  U8 *observe_name = argv[5];
  U8 *expected = argv[6];

  // The probe is a Mach-O image for the expected architecture.
  I64 pv = HarnessValidateProducer(probe, CPU_TYPE_ARM64);
  if (pv != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(pv);
    return pv;
  }

  // STEP 2 -- THE PRODUCTION APPLIER. The binding is applied by the SAME
  // `HarnessApplyEnv()` that the `run` mode calls. A mutation of that
  // function therefore changes this mode's behaviour, which is what makes
  // this mode a real detector.
  I64 vlen = StrLen(varname);
  I64 elen = StrLen(bind_value);
  U8 *binding = MAlloc(vlen + elen + 2);
  MemCpy(binding, varname, vlen);
  binding[vlen] = 61;                       // '='
  MemCpy(binding + vlen + 1, bind_value, elen);
  binding[vlen + 1 + elen] = 0;
  U8 *bindings[1];
  bindings[0] = binding;
  I64 applied = HarnessApplyEnv(bindings, 1);
  if (applied != HARNESS_OK) {
    "HARNESS_REASON\t%s\n", HarnessReason(applied);
    return applied;
  }

  // STEP 3 -- A REAL PROBE EXECUTABLE IS SPAWNED. The probe is given the
  // OBSERVATION name, so it reports what it observed under that exact
  // name.
  U8 *args[3];
  args[0] = probe;
  args[1] = observe_name;
  args[2] = NULL;
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = SpawnAndCapture(probe, args, &out, &err);
  U8 *outbuf = out;
  if (outbuf == NULL) outbuf = "";
  I64 outlen = StrLen(outbuf);

  // STEP 4 -- THE OBSERVATION. The name and the exact value are read from
  // the child's own output.
  U8 *name_field = HarnessEnvProbeField(outbuf, outlen, "ENVPROBE_NAME=");
  U8 *value_field = HarnessEnvProbeField(outbuf, outlen, "ENVPROBE_VALUE=");

  // STEP 5 -- THE CHILD'S EXIT STATUS IS VERIFIED.
  if (rc != 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_BINDING_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe exited with %lld\n", rc;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_BINDING_NOT_IN_FORCE;
  }

  // STEP 6 -- THE OBSERVED VALUES ARE COMPARED AGAINST THE FROZEN
  // EXPECTATIONS.
  //
  // The variable NAME must be EXACTLY the OBSERVATION name, so a
  // value observed under a DIFFERENT name is REFUSED.
  if (HarnessExactEqual(name_field, observe_name) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_BINDING_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe reported a different variable name than "
      "the one the binding applied\n";
    "HARNESS_ENV_DIAG\texpected_name=[%s]\n", observe_name;
    "HARNESS_ENV_DIAG\tobserved_name=[%s]\n", name_field;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_BINDING_NOT_IN_FORCE;
  }
  // The VALUE must be EXACTLY the expected value, so a value that merely
  // CONTAINS the expected value is REFUSED, and an ABSENT value is
  // REFUSED.
  if (HarnessExactEqual(value_field, expected) == 0) {
    "HARNESS_REASON\t%s\n", HarnessReason(HARNESS_ENV_BINDING_NOT_IN_FORCE);
    "HARNESS_ENV_DIAG\tthe probe observed a different value than the "
      "expected one\n";
    "HARNESS_ENV_DIAG\texpected=[%s]\n", expected;
    "HARNESS_ENV_DIAG\tobserved=[%s]\n", value_field;
    "HARNESS_ENV_DIAG\tprobe_stdout=[%s]\n", outbuf;
    return HARNESS_ENV_BINDING_NOT_IN_FORCE;
  }
  "HARNESS_ENVBIND_STATUS=PASS\n";
  "HARNESS_ENVBIND_NAME=[%s]\n", name_field;
  "HARNESS_ENVBIND_VALUE=[%s]\n", value_field;
  return HARNESS_OK;
}

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

  // ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 ROUND 6, R5-05.
  //
  // The PRODUCTION environment-binding qualification. It applies the
  // binding through the production `HarnessApplyEnv()` and observes the
  // result in a REAL child, so a mutation of the production applier is
  // DETECTED.
  if (StrCmp(argv[1], "envbind") == 0) {
    return HarnessEnvBind(argc, argv);
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
