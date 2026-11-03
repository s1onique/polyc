// THE ATOMIC RUNTIME-ARCHIVE PUBLISHER.
//
// ACT-POLYC-SELFHOST-DRIVER-REQUIRED-ROUTE-CORRECTION03, C4 REMEDIATION
// ROUND 3, FINDING F6.
//
// THE F6 DEFECT.
//
// The runtime archive was published into its FINAL path by a build step
// that wrote the archive FIRST and validated it LATER. When the
// validation failed, the INVALID archive was already occupying the final
// path. The next unchanged retry then saw the final path "up to date" and
// SUCCEEDED, so a build that had never produced a valid archive reported
// success.
//
// THE REQUIRED ADVERSE EXPERIMENT.
//
//     INVALID_ARCHIVE -> FIRST_BUILD_FAIL -> RETRY_FAIL
//
// The experiment must be EXECUTED, not merely documented. A repair that is
// only described is not a repair.
//
// THE REPAIR.
//
// The archive is built into a TEMPORARY path on the SAME FILESYSTEM as the
// final path, it is VALIDATED there, and only a VALID archive is published
// to the final path. The publication is ATOMIC: the final path either
// holds the previous archive or the new one, never a partial file and never
// an invalid one.
//
// The validation is the SHARED CONTRACT's: the archive is decoded with the
// shared archive decoder and every REQUIRED MEMBER is located with the
// shared member lookup. The publisher and the comparator therefore agree
// on what a valid archive is.
//
// THE TRUST BOUNDARY, STATED HONESTLY.
//
// This publisher establishes that the published archive is a VALID archive
// at the moment of publication. It does not attest that the archive
// remains valid afterwards, and it is not a cryptographic attestation
// against an attacker who can replace the whole build.
//
// F-POLYC-TOOLS: PolyC source. No Python, no shell, no dependency.

#include "driver-required-route-correction03-contract.HC"
#include "driver-required-route-correction03-sha256.HC"
#include "../../src/holyc-lib/tooling_defs.HH"
#include "../../src/holyc-lib/tos.HH"

// The atomic publication is a RENAME within one filesystem. The runtime
// does not export `rename`, so the tool declares it. The declaration is
// the POSIX one; the tool links against the C library that the runtime
// already links.
public extern "c" I32 rename(U8 *oldpath, U8 *newpath);

#define PUB_OK                    0
#define PUB_USAGE                 1
#define PUB_INPUT_MISSING         2
#define PUB_BUILD_FAILED          3
#define PUB_VALIDATION_FAILED     4
#define PUB_PUBLICATION_FAILED    5

static U8 *PubReason(I64 code) {
  if (code == PUB_OK) return "OK";
  if (code == PUB_USAGE) return "PUBLISH_USAGE";
  if (code == PUB_INPUT_MISSING) return "PUBLISH_INPUT_MISSING";
  if (code == PUB_BUILD_FAILED) return "PUBLISH_BUILD_FAILED";
  if (code == PUB_VALIDATION_FAILED) return "PUBLISH_VALIDATION_FAILED";
  if (code == PUB_PUBLICATION_FAILED) return "PUBLISH_PUBLICATION_FAILED";
  return "PUBLISH_UNKNOWN";
}

// The path builder. It appends `name` to `dir`.
static U8 *PubPathJoin(U8 *dir, U8 *name) {
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

// The directory of a path.
//
// The temporary path MUST be on the same filesystem as the final path, so
// the directory is the final path's OWN directory. The directory part is
// everything up to the last '/'. A path with no '/' is in the current
// directory, which is written as ".".
static U8 *PubPathDirName(U8 *path) {
  I64 len = StrLen(path);
  I64 i = len - 1;
  while (i >= 0 && path[i] != 47) i = i - 1;
  if (i < 0) {
    U8 *dot = MAlloc(2);
    dot[0] = 46;
    dot[1] = 0;
    return dot;
  }
  if (i == 0) {
    U8 *root = MAlloc(2);
    root[0] = 47;
    root[1] = 0;
    return root;
  }
  U8 *d = MAlloc(i + 1);
  MemCpy(d, path, i);
  d[i] = 0;
  return d;
}

// The archive builder.
//
// It runs the `ar` invocation that produces the archive from the object
// files. The archive is built AT THE TEMPORARY PATH, so the final path is
// never occupied by an unvalidated archive.
//
// The command is spawned DIRECTLY, with an explicit argv and NO shell, so
// the argument vector is exactly what is recorded.
//
// The builder's PATH IS AN EXPLICIT ARGUMENT, because the runtime spawns
// with `execv`, which does NOT search the PATH. A hard-coded absolute path
// would make the tool depend on the build host's layout.
static I64 PubBuildArchive(U8 *builder, U8 *ar_path, U8 *obj1, U8 *obj2,
                           U8 *obj3, U8 **out, U8 **err) {
  U8 *argv[7];
  argv[0] = builder;
  argv[1] = "rcs";
  argv[2] = ar_path;
  argv[3] = obj1;
  argv[4] = obj2;
  argv[5] = obj3;
  argv[6] = NULL;
  return SpawnAndCapture(builder, argv, out, err);
}

// The validation of the temporary archive.
//
// It uses the SHARED archive decoder and the SHARED member lookup, so the
// publisher and the comparator agree on what a valid archive is.
//
// Every required member must be PRESENT. The archive must also carry at
// least one REAL member: an archive that carries only the symbol-index
// bookkeeping member does not satisfy a member requirement.
static I64 PubValidateArchive(U8 *path, U8 **required, I64 nrequired,
                              U8 *detail) {
  I64 size = 0;
  U8 *buf = FileRead(path, &size);
  if (buf == NULL) {
    StrCpy(detail, "the temporary archive is ABSENT");
    return PUB_VALIDATION_FAILED;
  }
  ArArchive ar;
  I64 code = ContractDecodeArchive(buf, size, &ar);
  if (code != AR_OK) {
    StrCpy(detail, ContractArReason(code));
    return PUB_VALIDATION_FAILED;
  }
  if (ar.count < 1) {
    StrCpy(detail, "ARCHIVE_HAS_NO_REAL_MEMBER");
    return PUB_VALIDATION_FAILED;
  }
  I64 i = 0;
  while (i < nrequired) {
    // The shared member check returns AREQ_OK -- which is ZERO -- on
    // success. A non-zero value is a reason code.
    if (ContractArRequireMember(&ar, required[i], StrLen(required[i])) != AREQ_OK) {
      StrCpy(detail, "ARCHIVE_REQUIRED_MEMBER_MISSING");
      return PUB_VALIDATION_FAILED;
    }
    i = i + 1;
  }
  return PUB_OK;
}

// The publisher.
//
//   publish <builder> <final-archive> <obj1> <obj2> <obj3> <required>...
//
// The archive is built at a temporary path in the final archive's OWN
// directory -- therefore on the SAME FILESYSTEM -- it is validated there,
// and only then is it published to the final path.
//
// The publication is atomic: the temporary archive is RENAMED onto the
// final path. A rename within one filesystem is atomic, so a reader of the
// final path observes either the previous archive or the new one.
//
// The temporary path is REMOVED on every failure path, so a failed build
// leaves no residue that a later run could mistake for a published
// archive.
I32 Main(I32 argc, U8 **argv) {
  if (argc < 7) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_USAGE);
    "PUBLISH_USAGE\tpublish <builder> <final-archive> <obj1> <obj2> <obj3> <required>...\n";
    return PUB_USAGE;
  }
  U8 *builder = argv[1];
  U8 *final_path = argv[2];
  U8 *obj1 = argv[3];
  U8 *obj2 = argv[4];
  U8 *obj3 = argv[5];

  // Every required INPUT must be PRESENT. A missing object file is a hard
  // failure and is never treated as an empty file.
  //
  // The REQUIRED MEMBERS are the archive's MEMBER NAMES, not file paths.
  // They are therefore NOT checked for existence here: their presence is
  // checked by the VALIDATION, after the archive has been built.
  if (FileExists(builder) == 0 || FileExists(obj1) == 0 ||
      FileExists(obj2) == 0 || FileExists(obj3) == 0) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_INPUT_MISSING);
    "PUBLISH_DETAIL\ta required input file is absent\n";
    return PUB_INPUT_MISSING;
  }
// The publisher.

  // The temporary path is in the FINAL ARCHIVE'S OWN DIRECTORY, so the
  // publication is a same-filesystem rename.
  //
  // `TmpFile` allocates a UNIQUELY NAMED path by `mkstemp`, which both
  // reserves the name and creates the file. The file is then REMOVED, so
  // that the archive builder CREATES it: `ar` refuses to write over an
  // existing file that is not an archive. The name remains unique, because
  // `mkstemp` has already reserved it.
  U8 *dir = PubPathDirName(final_path);
  U8 *tmp_path = NULL;
  I32 fd = TmpFile(dir, ".libtos.publish.", &tmp_path);
  if (fd < 0) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_PUBLICATION_FAILED);
    "PUBLISH_DETAIL\ta temporary path could not be allocated\n";
    return PUB_PUBLICATION_FAILED;
  }
  close(fd);
  unlink(tmp_path);

  // The archive is built AT THE TEMPORARY PATH.
  U8 *out = NULL;
  U8 *err = NULL;
  I64 rc = PubBuildArchive(builder, tmp_path, obj1, obj2, obj3, &out, &err);
  if (rc != 0) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_BUILD_FAILED);
    "PUBLISH_DETAIL\tthe archive builder exited with %lld\n", rc;
    if (err != NULL) "PUBLISH_BUILDER_STDERR\t%s\n", err;
    unlink(tmp_path);
    return PUB_BUILD_FAILED;
  }

  // The validation happens BEFORE the publication.
  U8 *required[16];
  I64 nrequired = 0;
  I64 i = 6;
  while (i < argc && nrequired < 16) {
    required[nrequired] = argv[i];
    nrequired = nrequired + 1;
    i = i + 1;
  }
  U8 detail[128];
  detail[0] = 0;
  I64 vrc = PubValidateArchive(tmp_path, required, nrequired, detail);
  if (vrc != PUB_OK) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_VALIDATION_FAILED);
    "PUBLISH_DETAIL\t%s\n", detail;
    unlink(tmp_path);
    return PUB_VALIDATION_FAILED;
  }

  // The atomic publication.
  if (rename(tmp_path, final_path) != 0) {
    "PUBLISH_REASON\t%s\n", PubReason(PUB_PUBLICATION_FAILED);
    "PUBLISH_DETAIL\tthe archive could not be published\n";
    unlink(tmp_path);
    return PUB_PUBLICATION_FAILED;
  }
  "PUBLISH_REASON\t%s\n", PubReason(PUB_OK);
  "PUBLISH_FINAL\t%s\n", final_path;
  return PUB_OK;
}
