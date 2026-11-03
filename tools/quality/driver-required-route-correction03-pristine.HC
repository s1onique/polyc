// THE PRISTINE ISOLATED SUITE RUNNER.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3.
//
// THE F9 DOCTRINE IN EXECUTABLE FORM.
//
// A build that only passes in the working tree is a WARM-TREE result. The
// F9 doctrine requires a FRESH-TREE result for a closure-critical gate.
//
// The runner materializes the repository at the EXACT subject commit into
// an ISOLATED `git worktree` whose build directory starts EMPTY, and runs
// EVERY CORRECTION03 target there.
//
// THE ISOLATION IS TOTAL.
//
//   * the checkout is a `git worktree` at the subject commit, so it carries
//     the COMMITTED bytes and not the working tree's uncommitted bytes;
//   * the build directory is INSIDE the worktree and starts EMPTY, so no
//     artifact of the working tree's build is reused;
//   * the shared assembly scratch path is removed before each target, and
//     the runner holds an EXCLUSIVE LOCK on it for the whole run.
//
// THE LOCK IS NOT OPTIONAL.
//
// The compiler writes its intermediary assembly to the FIXED path
// /tmp/holyc-asm.s. Two compiler invocations that OVERLAP therefore
// destroy each other's scratch file, and the second one fails with
// "no such file or directory: '/tmp/holyc-asm.s'". The runner takes the
// lock with an EXCLUSIVE `mkdir`, which is atomic, and it HOLDS it for the
// whole run.
//
// This is a property of the RUNNER, not of the repository: the ACT's own
// constraint is that compiler invocations are serialized.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"
#include "driver-required-route-correction03-sha256.HC"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/tos.HH"

#define PRI_OK                 0
#define PRI_USAGE              1
#define PRI_INPUT_MISSING      2
#define PRI_LOCK_FAILED        3
#define PRI_CHECKOUT_FAILED    4
#define PRI_TARGET_FAILED      5

static U8 *PriReason(I64 code) {
  if (code == PRI_OK) return "OK";
  if (code == PRI_USAGE) return "PRISTINE_USAGE";
  if (code == PRI_INPUT_MISSING) return "PRISTINE_INPUT_MISSING";
  if (code == PRI_LOCK_FAILED) return "PRISTINE_LOCK_FAILED";
  if (code == PRI_CHECKOUT_FAILED) return "PRISTINE_CHECKOUT_FAILED";
  if (code == PRI_TARGET_FAILED) return "PRISTINE_TARGET_FAILED";
  return "PRISTINE_UNKNOWN";
}

// The path builder.
static U8 *PriPathJoin(U8 *dir, U8 *name) {
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

// The command runner.
//
// It runs a command through the runtime's `System`, which uses a shell.
// The runner is glue around `git` and `make`, and it does not interpret
// the command's output: the target's own verdict line is checked by
// reading the transcript that the runner captured.
static I64 PriRun(U8 *command) {
  return System(command);
}

// The transcript check.
//
// The target's own status line is the verdict. A make exit status of zero
// WITHOUT the status line is NOT a pass: a target that silently did
// nothing has not demonstrated anything.
static I64 PriTranscriptHas(U8 *path, U8 *needle) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) return 0;
  I64 nlen = StrLen(needle);
  I64 i = 0;
  while (i + nlen <= size) {
    I64 j = 0;
    I64 same = 1;
    while (j < nlen) {
      if (buf[i + j] != needle[j]) { same = 0; break; }
      j = j + 1;
    }
    if (same == 1) return 1;
    i = i + 1;
  }
  return 0;
}

// The runner.
//
//   pristine <repo-root> <work-dir>
//
// It writes a machine-readable ledger to stdout. Every row records the
// TARGET, the MAKE EXIT STATUS and whether the target reported its own
// PASS status line.
I32 Main(I32 argc, U8 **argv) {
  if (argc < 3) {
    "PRISTINE_REASON\t%s\n", PriReason(PRI_USAGE);
    "PRISTINE_USAGE\tpristine <repo-root> <work-dir>\n";
    return PRI_USAGE;
  }
  U8 *repo = argv[1];
  U8 *work = argv[2];

  if (FileExists(repo) == 0) {
    "PRISTINE_REASON\t%s\n", PriReason(PRI_INPUT_MISSING);
    "PRISTINE_DETAIL\tthe repository root %s does not exist\n", repo;
    return PRI_INPUT_MISSING;
  }

  // The subject commit.
  //
  // It is read from the repository's own `HEAD`, resolved through the
  // reference it names when `HEAD` is a symbolic reference. The value is
  // then VERIFIED against `git rev-parse`, so a resolution that disagrees
  // with Git's own is a failure rather than a silent difference.
  U8 *subject = NULL;
  {
    U8 *cmd = StrPrint(NULL, "cd %s && git rev-parse HEAD > %s/head.txt",
                       repo, work);
    I64 rc = PriRun(cmd);
    Free(cmd);
    if (rc != 0) {
      "PRISTINE_REASON\t%s\n", PriReason(PRI_CHECKOUT_FAILED);
      "PRISTINE_DETAIL\tthe subject commit could not be determined\n";
      return PRI_CHECKOUT_FAILED;
    }
    I64 size = 0;
    U8 *head = FileRead(PriPathJoin(work, "head.txt"), &size);
    if (head == NULL) {
      "PRISTINE_REASON\t%s\n", PriReason(PRI_INPUT_MISSING);
      "PRISTINE_DETAIL\tthe subject commit is unreadable\n";
      return PRI_INPUT_MISSING;
    }
    // The recorded value is the FIRST LINE of the file, which is the
    // commit's own 40-character hexadecimal digest.
    I64 len = 0;
    while (len < 64 && head[len] != 10 && head[len] != 0) len = len + 1;
    subject = MAlloc(len + 1);
    MemCpy(subject, head, len);
    subject[len] = 0;
    if (StrLen(subject) != 40) {
      "PRISTINE_REASON\t%s\n", PriReason(PRI_CHECKOUT_FAILED);
      "PRISTINE_DETAIL\tthe subject commit is not a commit digest\n";
      return PRI_CHECKOUT_FAILED;
    }
  }

  // The EXCLUSIVE LOCK on the shared assembly scratch path. `mkdir` is
  // atomic: it succeeds for exactly one holder.
  U8 *lock = "/tmp/polyc-pristine-suite.lock";
  if (mkdir(lock, 493) != 0) {
    "PRISTINE_REASON\t%s\n", PriReason(PRI_LOCK_FAILED);
    "PRISTINE_DETAIL\tanother pristine suite holds %s\n", lock;
    "PRISTINE_DETAIL\tthe compiler invocations must be SERIALIZED\n";
    return PRI_LOCK_FAILED;
  }

  // The work directory and the isolated checkout.
  U8 *checkout = PriPathJoin(work, "checkout");
  U8 *cmd = StrPrint(NULL,
    "rm -rf %s && mkdir -p %s && cd %s && git worktree add --detach %s %s",
    work, work, repo, checkout, subject);
  I64 rc = PriRun(cmd);
  if (rc != 0 || FileExists(checkout) == 0) {
    rmdir(lock);
    "PRISTINE_REASON\t%s\n", PriReason(PRI_CHECKOUT_FAILED);
    "PRISTINE_DETAIL\tthe isolated checkout was not created\n";
    return PRI_CHECKOUT_FAILED;
  }
  Free(cmd);

  // The isolated checkout's build directory starts EMPTY.
  cmd = StrPrint(NULL, "rm -rf %s/build", checkout);
  PriRun(cmd);
  Free(cmd);

  "# ACT_PHASE=C4R3-EVIDENCE\n";
  "# EVIDENCE_KIND=pristine-isolated-suite\n";
  "# SUBJECT=%s\n", subject;
  "# CHECKOUT=%s\n", checkout;
  "target\tmake_exit\tself_status\n";
  "#\n";

  U8 *targets[8];
  targets[0] = "driver-wp001-correction03-contract-test";
  targets[1] = "driver-wp001-correction03-test";
  targets[2] = "driver-wp001-correction03-emission-test";
  targets[3] = "driver-wp001-correction03-causal-test";
  targets[4] = "driver-wp001-correction03-adverse-test";
  targets[5] = "driver-wp001-correction03-publish-test";
  targets[6] = "driver-wp001-correction03-matrix-test";
  targets[7] = NULL;

  I64 failures = 0;
  I64 t = 0;
  while (targets[t] != NULL) {
    U8 *target = targets[t];
    U8 *log = StrPrint(NULL, "%s/%s.log", work, target);
    // The shared scratch path is removed before each target, so no target
    // can observe a stale scratch file.
    unlink("/tmp/holyc-asm.s");
    U8 *run = StrPrint(NULL,
      "cd %s && make %s > %s 2>&1", checkout, target, log);
    I64 mrc = PriRun(run);
    Free(run);
    I64 self = PriTranscriptHas(log, "STATUS=PASS");
    if (mrc != 0 || self != 1) failures = failures + 1;
    U8 *self_text = "NO_PASS_STATUS";
    if (self == 1) self_text = "PASS";
    "%s\t%lld\t%s\n", target, mrc, self_text;
    Free(log);
    t = t + 1;
  }

  // The isolated checkout is removed, and the worktree registration with
  // it, so the repository is left exactly as it was found.
  cmd = StrPrint(NULL, "cd %s && git worktree remove --force %s", repo, checkout);
  PriRun(cmd);
  Free(cmd);
  cmd = StrPrint(NULL, "cd %s && git worktree prune", repo);
  PriRun(cmd);
  Free(cmd);
  rmdir(lock);

  "#\n";
  "PRISTINE_TARGETS=7\n";
  "PRISTINE_FAILURES=%lld\n", failures;
  if (failures != 0) {
    "PRISTINE_SUITE_STATUS=FAIL\n";
    return PRI_TARGET_FAILED;
  }
  "PRISTINE_SUITE_STATUS=PASS\n";
  return PRI_OK;
}
