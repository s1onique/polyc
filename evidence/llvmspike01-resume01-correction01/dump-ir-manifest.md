# Dump-IR transcript manifest (raw + normalised)
#
# Each .dump-ir.txt file in this directory is the NORMALISED
# textual transcript of `hcc --dump-ir` on the named
# fixture. The normalisation strips trailing horizontal
# whitespace per line (F13: production output is data;
# the normalisation is local, reversible, and does not
# alter any non-whitespace bytes).
#
# The byte-faithful original is preserved in two places:
#   1. <name>.dump-ir.txt.sha256
#        SHA256 of the original raw bytes.
#   2. <name>.dump-ir.txt.b64
#        Base64 encoding of the original raw bytes.
#
# Verification procedure (manual, F2/F13):
#   $ base64 -d <name>.dump-ir.txt.b64 | shasum -a 256
#   $ # must match <name>.dump-ir.txt.sha256
#
# Local source of the trailing-space emission (F2 / F13):
#     src/ir.c:3311
#         printf("===== After basic optimisations ===== \n");
#
# (The literal text after `basic optimisations ` is followed
# by a single space before `\n`.)
#

| Label      | Source fixture                                  | Raw bytes | raw_sha256                       |
|------------|-------------------------------------------------|-----------|----------------------------------|
| red-1A     | `src/tests/llvm-spike/04_cmp_branch.HC` | 1501 | `b27037913d296f6ecc5a5662b6f35296e8c5621424563a328b48b67f05c50842` |
| red-6.eq   | `src/tests/llvm-spike/red_pred_eq.HC` | 1501 | `f42fecea73449f196e2e9f3119c53dfee735146489f9287a81527dcd9ea86751` |
| red-6.ne   | `src/tests/llvm-spike/red_pred_ne.HC` | 1501 | `b54f1c3217418f106ac63030f83d08fee61e68a9ad6830120577eae5bad73c09` |
| red-6.slt  | `src/tests/llvm-spike/red_pred_slt.HC` | 1501 | `704d818d6f5f5b56a52bdafc06286f47862bca9007420b4130692d9c19d2c6c9` |
| red-6.sle  | `src/tests/llvm-spike/red_pred_sle.HC` | 1501 | `bda73645909f1057a24dae4fbdbfec0d22d6b04afae3eb65c4c15e8cd18ebe4c` |
| red-6.sgt  | `src/tests/llvm-spike/red_pred_sgt.HC` | 1501 | `f4ca36cafde1b5e5305acf18061766761c37589988d177afc88b1c60c27ffd19` |
| red-6.sge  | `src/tests/llvm-spike/red_pred_sge.HC` | 1501 | `41f267f812f0f6dd0597c1c08fd4460a189dd58546e707ecdb2251a84a088fbe` |

## Verification command

```sh
base64 -d evidence/llvmspike01-resume01-correction01/red-1A.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_eq.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_ne.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_slt.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_sle.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_sgt.dump-ir.txt.b64 | shasum -a 256
base64 -d evidence/llvmspike01-resume01-correction01/red-6.red_pred_sge.dump-ir.txt.b64 | shasum -a 256
```

Each line above must print the corresponding raw_sha256
from the manifest table.
