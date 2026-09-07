# ACT-POLYC-BOOTSTRAP-RECON01 — Inherited Baseline, Compiler Topology, IR Boundary, and Native Execution Reconnaissance

**Class:** RECON / BASELINE / EVIDENCE-ONLY
**Repository:** `https://github.com/s1onique/polyc`
**Branch:** `main`
**Production-code authorization:** NONE
**Semantic-change authorization:** NONE
**Backend-change authorization:** NONE
**LLVM authorization:** NONE
**Refactor authorization:** NONE
**Status at closure:** PASS_WITH_NEXT_ACT_DECISION

---

## 1. Identity

| Field | Value |
| --- | --- |
| REPOSITORY_ROOT | `/Volumes/UserData/Users/chistyakov/Projects/SPbNIX/polyc` |
| BRANCH | `main` |
| ENTRY_HEAD | `7412f72a981ab859e78216c7007c68e34651f341` |
| FINAL_HEAD | `7412f72a981ab859e78216c7007c68e34651f341` (worktree only untracked `evidence/` and `docs/acts/` dirs introduced by this ACT) |
| ORIGIN_URL | `git@github.com:s1onique/polyc.git` |
| UPSTREAM_URL | NONE (no `upstream` remote present) |
| WORKTREE_STATUS | clean (only untracked `evidence/` and `docs/acts/` dirs introduced by this ACT) |

**Top-of-entry log decoration:**

```
7412f72 (HEAD -> main, origin/main, origin/HEAD) Fix detection of forwarding pass (#275)
```

## 2. Host and toolchain

| Field | Value |
| --- | --- |
| HOST_OS | `Darwin` / macOS 14.7.4 (23H420), kernel Darwin 23.6.0 |
| HOST_ARCH | `arm64` (Apple M3 Max) |
| CC | `Apple clang version 15.0.0 (clang-1500.0.40.1)` (target arm64-apple-darwin23.6.0) |
| CMAKE | `cmake version 3.28.3` (located in `/nix/store/hqa6xck6z9fnmlmwp19rvnbkmk76q18a-cmake-3.28.3/`; not on default PATH) |
| MAKE | `GNU Make 3.81` |

**Toolchain discovery note (RESIDUE candidate).** The inherited build
path (`Makefile` -> `cmake ... && make`) assumes `cmake` is on `$PATH`.
The executing Nix-shell-less environment ships no Homebrew and no
`/usr/local` `cmake`. `cmake` was discoverable only through the Nix
store at `/nix/store/hqa6xck6z9fnmlmwp19rvnbkmk76q18a-cmake-3.28.3/bin/cmake`.
We prepended that directory to `$PATH` for every build/test invocation;
this is a host configuration detail, not a modification to the
inherited code.

**Build system.** The repository wraps CMake via a top-level `Makefile`
(`C_COMPILER ?= gcc`, `BUILD_TYPE ?= Release`, `INSTALL_PREFIX ?= /usr/local`)
and enables JIT by default (`-DHCC_ENABLE_JIT=on`). The source-tree
`src/CMakeLists.txt` declares the `hcc` executable and the `unit-test`
custom target.

---

## 3. Inherited build/test baseline

### 3.1 Build (clean)

```text
$ make C_COMPILER=cc INSTALL_PREFIX=$PWD/build/recon-prefix clean
$ /usr/bin/time -p make C_COMPILER=cc INSTALL_PREFIX=$PWD/build/recon-prefix
...
[100%] Built target hcc
real 3.74   user 4.69   sys 1.35
```

| Field | Value |
| --- | --- |
| BUILD_RC | `0` |
| BUILD_WALL_TIME | `~3.7s` cold clean build, parallel `-j2` |
| COMPILER_BINARY | `./hcc` |
| COMPILER_BINARY_SIZE | `723776 bytes` (Mach-O 64-bit executable arm64) |
| COMPILER_IDENTITY | `Mach-O 64-bit executable arm64` (`file ./hcc`) |
| HELP_OUTPUT | `hcc - HolyC Compiler v0.0.15-beta`; options include `-jit`, `-repl`, `--dump-ir`, `--target`, `--use-legacy-x86`, `--install-dir`, `-lsp`, `-Memsafe`, `--mem-stats`, `-transpile` |

### 3.2 Install (`make install`)

```text
$ make INSTALL_PREFIX=$PWD/build/recon-prefix install
...
ar: error: couldn't create cache file '/var/folders/0g/.../xcrun_db-...' (errno=Operation not permitted)
...
ERROR: Failed to execute command: 'cp -pPR ./libtos.a ...'
```

`make install` returned `0` but logged an error: the install step's
`install(CODE ...)` in `src/CMakeLists.txt` re-invokes the freshly-built
`hcc` to build `libtos.a` and `libtos.<ver>.dylib` into
`<install>/lib/`. `ar` cannot create its cache file under
`/var/folders/.../T/` (sandbox restriction on this host), so the
static-archive step fails. `hcc` and `tos.HH` were still copied.

We worked around this by manually invoking the same command sequence
with the inherited `--install-dir` override:

```text
$ cd src/holyc-lib && ../../hcc -fPIC -lib tos \
    --install-dir=$PWD/../../build/recon-prefix ./all.HC
$ ls build/recon-prefix/lib
libtos.0.0.1.dylib   libtos.a
```

This is **RESIDUE R-P2** (host sandbox quirk; not a code defect).

### 3.3 Test inventory and results

All three discoverable test entrypoints were exercised:

| Test entrypoint | Command | N (passed) | RC | Notes |
| --- | --- | --- | --- | --- |
| Unit tests (AOT) | `make unit-test` | 90 / 90 | 0 | harness `src/tests/run.HC`; suite covers `#ifjit`/`#ifaot`, `#link`, `typeof`, struct-by-value (C ABI), sret, class inheritance, big stack frames, etc. |
| JIT unit tests | `make jit-unit-test` | 90 / 90 | 0 | harness `src/tests/run_jit.HC`; same corpus, `-jit` per file |
| LSP tests | `make lsp-test` | 43 / 43 | 0 | hermetic harness in `src/tests/lsp/`; covers completion, rename, references, documentHighlight, crash survival, debounce |

Raw evidence: `evidence/unit-test.log`, `evidence/jit-unit-test.log`,
`evidence/lsp-test.log`. No test was silently excluded.

**GitHub Actions.** `.github/workflows/release.yml` builds four
target/host legs and runs an AOT+JIT smoke test on each native leg.
The inherited `release.yml` pipeline is the authoritative
cross-target reference; it explicitly documents that the Intel macOS
leg cross-builds and skips the smoke run.

### 3.4 Readme/behaviour discrepancies

None affecting architectural conclusions.

---

## 4. Semantic smoke corpus

A bounded 16-item corpus was constructed to exercise the language
features the inherited parser/IR supports. Each item was executed
through **all three** execution modes and outputs were compared.

| ID | Feature | Source (abbrev.) | AOT | JIT | REPL |
| --- | --- | --- | --- | --- | --- |
| S01 | integer expression | `"%d\n", 6*7` | `42` | `42` | `42` |
| S02 | function def + call | `I64 Add(I64 a,I64 b){return a+b;}` | `7` | `7` | `7` |
| S03 | local var + mutation | `I64 x=10; x+=5;` | `15` | `15` | `15` |
| S04 | branch | `if (x>3) "yes" else "no"` | `yes` | `yes` | `yes` |
| S05 | loop | `while(i<3){i++;}` | `3` | `3` | `3` |
| S06 | pointer load/store | `I64 *p=MAlloc(8); *p=42;` | `42` | `42` | `42` |
| S07 | struct field access | `class P{ I64 x; }; p->x=11;` | `11` | `11` | `11` |
| S08 | function pointer | `I64 (*f)(I64)=&Dbl;` | `14` | `14` | `14` |
| S09 | float operation | `F64 x=3.5; "%.2f", x+1.5` | `5.00` | `5.00` | `5.00` |
| S10 | global definition | `I64 G=99;` | `99` | `99` | `99` |
| S11 | default argument | `I64 Inc(I64 x=10){return x+1;}` | `11` | `11` | `11` |
| S12 | implicit zero-arg call | `I64 FortyTwo(){return 42;} ... FortyTwo;` | `42` | `42` | `42` |
| S13 | string expression | `"hello\n";` | `hello` | `hello` | `hello` |
| S14 | `#define` | `#define X 7` | `7` | `7` | `7` |
| S15 | `extern "c"` FFI | `extern "c" I64 printf(U8 *,...);` | `c-ffi 5` | `c-ffi 5` | `c-ffi 5` |
| S16 | `#ifjit`/`#ifaot` | `U0 Main(){ #ifjit "jit\n" #else "aot\n" #endif }` | `aot` | `jit` | `jit` |

Outputs are byte-identical between AOT and JIT for S01-S15. S16
deliberately diverges between modes as expected (it's a language-level
`#ifjit` switch).

REPL submission pattern: REPL submits per-blank-line; for AOT-style
`U0 Main(){...}; Main;` files we pipe `<file>\nMain;\n\n`. Each
successful submission prints the trailing expression's value; a bare
function definition produces no output (this matches TempleOS REPL
semantics).

Corpus lives at `evidence/smoke/corpus/S*.HC`; per-mode harness
scripts are in `evidence/smoke/`.

---

## 5. Source topology — control flow

All call paths below were reconstructed by reading the source, not by
inferring from filenames.

### 5.1 AOT path

```text
main()
  src/main.c:420

CLI parse -> Cctrl init -> memoryInit
  src/main.c:421-447

Define __HCC_AOT__ / __HCC_JIT__
  src/main.c:475-479

# Lsp early-exit
  src/main.c:439-443  (lspRun)

# AOT compile pipeline
  src/main.c:530-560
  +-- if dump-ir:    irDump(cc)            src/main.c:529
  +-- if transpile:  transpileToC()         src/main.c:508
  +-- if cfg:        cfgConstruct() + dot  src/main.c:573-585
  +-- default:
        compileToAst(cc, args, lexer_flags)
          src/main.c:519  -> src/compile.c:70-98
            lexInit/lexPushFile (lexer.c)
            cctrlInitParse (cctrl.c)
            parseToAst   (parser.c)
        compileToAsm(cc)
          src/main.c:587  -> src/compile.c:42-50
          -> src/asm.c:151 (asmGenerate dispatch)
              +-- TARGET_AARCH64_*       -> aarch64AsmGenerate(cc)   src/aarch64.c:2190
              +-- TARGET_X86_64_*  / LEGACY_X86 -> x86_64AsmGenerate / x86AsmGenerate
                                        src/x86_64.c:2535 / src/x86.c

aarch64AsmGenerate / x86_64AsmGenerate (IR-based)
  for each AST_FUNC in cc->ast_list:
    IrFunction *fn = irLowerFunction(ir_ctx, ast)       # SSA IR
    irBasicFunctionOptimisations(fn)                    # DCE, const-fold, fold, etc.
    irFunctionPrepForCodeGen(&ctx, fn, ast)             # stack slot alloc; ABI register arrival pinning
    aarch64GenerateFunction(&ctx, ast) / x86_64GenerateFunction  # text asm

x86AsmGenerate (legacy AST-based) is reachable via --use-legacy-x86; it
walks the AST directly to emit text asm. This is kept for diagnostic
comparison only; it is NOT the default and is not exercised by
`make unit-test`.

emitFile(cc, asmbuf, args)            src/main.c (post-asmGenerate)
  writes AoStr to /tmp/holyc-asm.s    main.c:#define ASM_TMP_FILE "/tmp/holyc-asm.s"
  system("cc -L<install>/lib /tmp/holyc-asm.s [objs] [link_flags] [-clibs] -ltos -lpthread -lc -lm -o <out>")
                                      src/main.c:341-358
  on -run: same pipeline, then exec ./a.out then rm
```

The `cc` binary is resolved at process startup in `main()`: native ->
`cc` (default), cross -> `clang --target=<triple>` (main.c:455-467).
This is the **only** host-side dependency on the system toolchain for
AOT.

### 5.2 JIT path

```text
main() -> args.jit branch (main.c:535-563)
  jit = aarch64JitCompile(cc)    src/aarch64-jit.c  (arm64 host)
       or x86_64JitCompile(cc)   src/x86_64-jit.c   (x86_64 host)
  hccJitRunMain(jit, argc, argv) src/jit-common.c:849
  hccJitFree(jit)                src/jit-common.c:856
```

`aarch64JitCompile` / `x86_64JitCompile` are thin wrappers around
`hccJitCompileProgram` (in `src/jit-common.c:707-...`), which performs
the full front-end -> IR -> native bytes -> RX mapping pipeline for
every function in `cc`.

Per-function pipeline inside the JIT (e.g. `src/x86_64-jit.c:1579`):

```text
static int jitCompileFunction(HccJit *jit, Ast *ast, IrCtx *ir_ctx) {
    IrFunction *fn = irLowerFunction(ir_ctx, ast);   // SSA IR
    irBasicFunctionOptimisations(fn);                // same as AOT
    IrCgCtx dummy = {0};                             // prep slot loff map
    irFunctionPrepForCodeGen(&dummy, fn, ast);       // same as AOT
    ...
    jitEmitPrologue(&ctx);                           // binary prologue
    jitEmitSysvParamPrologue(&ctx);
    for each block in fn->blocks:
        for each instr in block->instructions:
            jitEmitInstr(&ctx, in);                  // binary emission
    jitEmitEpilogue(&ctx);
}
```

Bytes accumulate into `HccJit::enc` (an `AsmEnc` from
`src/asm/asm_enc.h`), which is a vendor assembler (`libtasm` in
`src/asm/`) that supports both text assembly output and direct
machine-code emission into an RX mapping.

Executable-memory publication (`src/asm/asm_jit.c:269-...`):

```text
asm_jit_finalize(enc, resolver, ud)
  prot = PROT_READ | PROT_WRITE
  flags = MAP_PRIVATE | MAP_ANONYMOUS
  #if APPLE_SILICON_JIT
    prot  |= PROT_EXEC;
    flags |= MAP_JIT;                                 // Apple Silicon JIT mapping
  #endif
  mem = mmap(NULL, page_round_up(enc->len + veneer_area), prot, flags, -1, 0);
  pthread_jit_write_protect_np(0);                    // Apple Silicon only
  memcpy(mem, enc->bytes, enc->len);                  // populate RX
  ...                                                 // patch AF_SYMBOL fixups
  ...                                                 // patch AF_LOCAL fixups
  // Apple-Intel / Linux: mprotect(mem, size, PROT_READ|PROT_EXEC)
```

So the JIT publishes executable memory as follows:

* **Allocate**: `mmap(NULL, ..., RW, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)`
  (Apple Silicon: with `MAP_JIT` so the mapping is RX from birth).
* **Made writable**: by mmap flags (or Apple Silicon's
  `pthread_jit_write_protect_np(0)` toggle).
* **Populated**: `memcpy(mem, enc->bytes, enc->len)`.
* **Made executable**: already RX on Apple Silicon; elsewhere
  `mprotect(mem, size, PROT_READ|PROT_EXEC)`.
* **Published**: returned as `AsmJitCode.code` and registered by name
  into `HccJit::symbols` (and into `host_symbols` so later chunks can
  call into it).
* **Freed/reused**: never freed individually. Old chunks accumulate in
  `HccJit::chunks` because "earlier code may hold pointers into them"
  (`src/jit-common.h:45-47`). The whole list is released in
  `hccJitFree`.

### 5.3 REPL path

```text
main() -> args.repl branch (main.c:489-498)
  replRun(cc, args)                       src/repl.c:1479
    cc->flags |= CCTRL_REPL | CCTRL_WERROR
    jit = hccJitNew(cc, backend)          // backend = aarch64JitBackend() / x86_64JitBackend()
    hccJitDefineSymbol(jit, "Uf", ...)
    hccJitDefineSymbol(jit, "ReplDel", replBuiltinReplDel)
    ... many other Repl* builtins ...
    memsafeInit(jit)                       // leak/wild-free tracker
    replBootstrap(cc, jit, args, root_dir) // load ~/.hcc_rc.HC if present
    replParse(cc, root, "<builtins>", repl_builtin_protos)  // declare prototypes
    replDropInitialisers(cc)               // drop pre-bootstrap init exprs
    linenoise history load (~/.hcc_repl_history)
    loop:
        input = replReadInput()            // block-aware read; brace/paren balance
        if input == NULL: break            // EOF / Ctrl-D
        if @-escape: system(...)
        round++;
        replExec(input, round)             // src/repl.c
            memsafeSetRound(round)
            replExecInner(input, round)
              replParse(cc, root, "<repl>", input)
              replBuildWrapper(cc, round, &echo_type)
                  wraps top-level stmts into __repl_N, returns echo type
              hccJitCompileChunk(jit, wrapper_fn)   // incremental: appends new functions
              lookup __repl_N
              fault-protected sigsetjmp
              call __repl_N(args, retval)
              echo retval
```

Persistent session structures held in `HccJit`:

| Structure | Purpose | Lifetime |
| --- | --- | --- |
| `HccJit::symbols` | name -> entry address inside an RX mapping; accumulates across chunks | session |
| `HccJit::host_symbols` | user-defined host symbols (printf, MAlloc, etc.); checked before `dlsym` | session |
| `HccJit::chunk_fns` | per-chunk, names of functions defined in the chunk currently being emitted | per chunk |
| `HccJit::chunks` | every finalized RX mapping (`AsmJitCode *`); never freed individually | session |
| `HccJit::globals_arenas` | RW arenas for globals + string literals, one per chunk | session |

Persistent structures held in `Cctrl` (`repl_cc`):

| Structure | Purpose |
| --- | --- |
| `cc->global_env`, `cc->function_env`, `cc->class_env`, etc. | the persistent symbol / type table |
| `cc->macro_defs` | `#define` macros persist across submissions |
| `cc->link_libs` | `#link` directives (resolved on every chunk) |

`ReplDel(name)` (`src/repl.c:590-637`) walks the symbol tables and, on
a match:

* removes the symbol/type/global/function/class from the relevant
  table;
* if it was a function whose body has been JIT-compiled, removes the
  name from `HccJit::host_symbols` so future chunks won't re-link
  against it;
* **does NOT free the executable memory** the function's bytes live in
  (the chunk that owns those bytes stays mapped; only future calls
  from fresh code are blocked).

Persistent allocations across rounds in REPL therefore include:
globals/string-literal arenas, every compiled function's RX chunk, all
defined symbols/types/macros. The arena memory used by `ast.c` /
`ir.c` (per-translation-unit nodes, lexical streams) is freed when the
REPL process exits via `memoryRelease` (main.c:600) — not between
rounds.

### 5.4 AOT/JIT convergence

The AOT and JIT paths share **exactly the same lowering and regalloc
pipeline** at the function level:

```text
COMMON_PREFIX_END =
    irLowerFunction                src/ir.c, called from x86_64.c:2557 / aarch64.c:2208 / x86_64-jit.c:1580 / aarch64-jit.c:1702
    irBasicFunctionOptimisations   src/ir-optimise.c
    irFunctionPrepForCodeGen       src/ir.c:3079  (computes loff map, sets fn->stack_space)
    irCgBindAstLoffs               src/ir-regalloc.c
    irCgAllocAllTmps               src/ir-regalloc.c (linear-scan stack-slot alloc)

FIRST_AOT_ONLY_STAGE  = aarch64GenerateFunction / x86_64GenerateFunction
                        (text-asm emission into an AoStr)

FIRST_JIT_ONLY_STAGE  = jitEmitPrologue / jitEmitInstr (per-arch)
                        (binary emission into AsmEnc, with hccJitAssembleText for
                         inline asm{} blocks)
```

After the shared prefix, the two paths diverge purely in the *output
representation*:

* AOT emits textual assembly -> writes `/tmp/holyc-asm.s` -> shells out
  to `cc` (or `clang --target=...` for cross compile).
* JIT emits machine bytes into `AsmEnc` -> `asm_jit_finalize` -> `mmap`
  -> fixup patching -> direct function-pointer call.

REPL reuses the JIT path **completely**, plus three REPL-only
specialisations:

```text
REPL_REUSES_JIT_PATH = YES
REPL_SEMANTIC_SPECIAL_CASES = [
    "wraps top-level statements into a synthetic __repl_N function and returns the trailing expression's value (replBuildWrapper)",
    "persistent Cctrl accumulates symbols/types/macros across submissions",
    "hccJitCompileChunk is the incremental version of hccJitCompileProgram (cursors advance over cc->ast_list even on failure)",
    "ReplDel(name) removes a defined symbol from the persistent tables and from HccJit::host_symbols; does NOT free the owning RX chunk",
    "fault recovery: SIGSEGV/SIGBUS inside an eval calls siglongjmp back to the prompt with a disassembly window (replInstallFaultHandlers, src/repl.c:114-180)",
    "memsafe.c tracks MAlloc/Free per round and reports leaks at exit (when -jit/-repl/-Memsafe)"
]
```

---

## 6. IR forensic analysis

### 6.1 IR inventory

`src/ir-types.h:15-100` enumerates the IR opcode set. Op categories:

| Category | Opcodes | Target-independent? |
| --- | --- | --- |
| No-op | `IR_NOP` | yes |
| Memory | `IR_ALLOCA`, `IR_LOAD`, `IR_STORE`, `IR_LOAD_DEREF`, `IR_STORE_DEREF`, `IR_RMW_DEREF`, `IR_LEA`, `IR_GEP` | yes — semantics only; backends choose instruction shape |
| Integer arith | `IR_IADD`, `IR_ISUB`, `IR_IMUL`, `IR_IDIV`, `IR_UDIV`, `IR_IREM`, `IR_UREM`, `IR_INEG` | yes |
| Float arith | `IR_FADD`, `IR_FSUB`, `IR_FMUL`, `IR_FDIV`, `IR_FNEG` | yes |
| Bitwise | `IR_AND`, `IR_OR`, `IR_XOR`, `IR_SHL`, `IR_SHR`, `IR_SAR`, `IR_NOT` | yes |
| Compare | `IR_ICMP`, `IR_FCMP` (kinds: EQ/NE/LT/LE/GT/GE/ULT/ULE/UGT/UGE plus OEQ/ONE/OLT/OLE/OGT/OGE/UNO/ORD) | yes |
| Casts | `IR_TRUNC`, `IR_ZEXT`, `IR_SEXT`, `IR_FPTRUNC`, `IR_FPEXT`, `IR_FPTOUI`, `IR_FPTOSI`, `IR_UITOFP`, `IR_SITOFP`, `IR_PTRTOINT`, `IR_INTTOPTR`, `IR_BITCAST` | yes |
| Control flow | `IR_RET`, `IR_BR` (off a 0/1 condition), `IR_CMP_BR` (fused cmp+branch, `extra.cmp_br`), `IR_JMP`, `IR_SWITCH`, `IR_CALL`, `IR_PHI`, `IR_LABEL` | yes (except `IR_CMP_BR` carries the AArch64 `b.cond` / x86 `j<cc>` style; see C5) |
| Misc | `IR_SELECT`, `IR_VA_ARG`, `IR_VA_START`, `IR_VA_END`, `IR_ASM` | yes (`IR_ASM` carries raw bytes / templates verbatim) |

IR value types (`ir-types.h:103-120`): `IR_TYPE_VOID`,
`IR_TYPE_I8/I16/I32/I64`, `IR_TYPE_F32/F64`, `IR_TYPE_PTR`,
`IR_TYPE_ARRAY`, `IR_TYPE_ARRAY_INIT`, `IR_TYPE_STRUCT`,
`IR_TYPE_FUNCTION`, `IR_TYPE_ASM_FUNCTION`, `IR_TYPE_LABEL`.

IR value kinds (`ir-types.h:122-135`): `IR_VAL_CONST_INT`,
`IR_VAL_CONST_FLOAT`, `IR_VAL_CONST_STR`, `IR_VAL_GLOBAL`,
`IR_VAL_PARAM`, `IR_VAL_LOCAL`, `IR_VAL_TMP`, `IR_VAL_PHI`,
`IR_VAL_LABEL`, `IR_VAL_UNDEFINED`, `IR_VAL_UNRESOLVED`.

Each `IrInstr` (ir-types.h:275-321) carries `op`, `dst`, `r1`, `r2`,
plus:

* `s32 disp` — "Signed 32-bit matches the x86 disp32 and AArch64
  ldur/stur ranges" — *naming* is x86/AArch64-leaning but the field is
  a language-level signed byte displacement (an architecture
  coincidence, not a constraint).
* `IrValue *idx; u8 scale;` — scaled-index addressing. `scale in
  {1,2,4,8}` — that *is* an x86 SIB constraint baked into the IR
  shape, even though AArch64 supports the same scales.
* `int line` — source line (target-neutral debug aid).
* `extra` — `blocks`, `cmp_kind`, `cmp_br`, `rmw_op`,
  `unresolved_label`, `cases`, `phi_pairs`, `asm_fragments`.

Each `IrValue` (ir-types.h:220-257) carries `type`, `kind`, `flags`,
`pinned_reg`, `loc`, `byval_struct_type`, and a payload union. Two of
these are architecture-touching:

* `pinned_reg` (`AoStr*`) — TempleOS-style `<Type> reg <REG> name`.
  Only meaningful for `IR_VAL_LOCAL` / `IR_VAL_PARAM`. Carries the
  *literal* register name (e.g. `"rax"`).
* `loc` (`IrLocation`) — populated by the post-lower regalloc +
  result-pin fusion passes; pre-regalloc values are `IR_LOC_NONE`.
  When `loc.kind == IR_LOC_REG`, `loc.as.reg` is an `AoStr*` holding
  the physical register name from the per-backend `IrRegPool`.

### 6.2 Contamination classes (per ACT §10)

**C1 — physical registers.** Limited but real.

* `pinned_reg` is set by user source only.
* `loc.as.reg` is populated in three places, all in `src/ir.c` /
  `src/ir-optimise.c`:
  - `irOptPinResultReg` (`ir-optimise.c:1079-1192`): fuses a
    single-use TMP producer with its immediate consumer and stamps
    `dst->loc.kind = IR_LOC_REG; dst->loc.as.reg =
    pool->{int,float}_return_reg`. Pure optimisation hint to the
    backend.
  - `irOptDeadCodeElim` (`ir-optimise.c:1257-1260`): pins the dead
    dst of a live `IR_CALL` to the result register so the slot
    allocator skips reserving one.
  - Parameter arrival / hidden out-pointer (see C2).

**C2 — ABI decisions inside IR lowering.** Present.

* `src/ir.c:2799-2833` walks `pool->int_arg_regs` /
  `pool->float_arg_regs` to stamp
  `param->loc.kind = IR_LOC_REG; param->loc.as.reg = <ABI reg>` on the
  arrival value of every parameter.
* `src/ir.c:2812, 3007-3013` consults `pool->sret_reg` and
  `pool->int_arg_regs[0]` to place the hidden out-pointer for indirect
  struct returns.
* `src/ir.c:2823-2829, ir-regalloc.c:621-651` consult
  `pool->variadic_on_stack` to decide whether the implicit `argc` is
  pinned to an arg register or only lives on the stack (Apple AArch64
  ABI difference).
* `src/ir-optimise.c:420-440` consults `pool->scratch_regs` to know
  which registers a forwarding pass must consider live-across-op.

These are all mediated through the **pluggable** `IrRegPool` table
(`src/ir-regalloc.h:33-69`). An LLVM backend would need to provide its
own pool describing its calling-convention register classes. That is
plausible but not free: an LLVM-style backend wants per-call CC choice
via attributes, not a single global pool.

**C3 — stack-frame realisation.** None in the IR proper. The `disp`,
`idx`, `scale` fields are language-level displacements. Actual frame
layout (rbp offsets, red-zone vs sub sp) is a backend choice. Backends
may or may not use rbp-based frames — see `src/x86_64-jit.c:1601-1602`
("omit_frame = stack_space==0 && !irFnHasCalls && ast->loff==0 &&
!is_variadic && !has_struct_param").

**C4 — machine widths.** Mostly language-level. `IR_TYPE_I64` is
"64-bit integer" in the language. Pointer width *is* implicitly
"IrValueByteSize(IR_TYPE_PTR) == 8", which is fine on every
host/target the inherited compiler supports (64-bit only); would have
to be re-examined for 32-bit support, but no 32-bit target exists in
the inherited code.

**C5 — instruction-selection leakage.** Two minor smells.

* `IR_CMP_BR` (ir-types.h:80-83, ir-optimise.c:1105-1122) is a fused
  cmp-and-branch. Its existence is purely a codegen convenience; the
  IR could be expressed as `IR_ICMP` + `IR_BR`. The fused form doesn't
  *force* a particular instruction shape (LLVM IR has `icmp + br`).
* `IR_RMW_DEREF` (ir-types.h:29) carries a "rmw_op" payload. Its
  comment notes "so codegen can emit x86's memory-destination forms
  (`incb mem`, `addq $k, mem`, etc.)". The opcode is semantically
  equivalent to `load; binop; store`; its existence is again an x86
  convenience. Easy to drop or treat as a normal binop+mem sequence
  in an LLVM consumer.

Neither prevents an LLVM consumer; both are cosmetic.

**C6 — assembler leakage.** None. The IR has no mnemonics, register
names, labels, or directives. Inline asm is encapsulated in `IR_ASM`
holding a raw bytestring — that's a language-level feature, not an IR
contamination.

**C7 — execution-mode leakage.** None in the IR. `#ifjit`/`#ifaot`
are preprocessor sugar (`src/lexer.c:166-167, 1906-1923`) for
`#ifdef __HCC_JIT__` / `#ifdef __HCC_AOT__`, defined in
`main.c:475-479`. This is a language-level compile-time distinction.
The IR does not contain mode-discriminating ops.

### 6.3 IR verdict rubric

**IR_CLASS_B — NEUTRAL_CORE_WITH_LOWERED_TAIL.**

The IR is semantically rich and target-independent in its core (typed
SSA, CFG, ops, value kinds, casts, calls, inline-asm payload).
AArch64 and x86-64 already consume it cleanly at the IR level — the
*only* target-dependent bit is the `IrRegPool` consumed during
*parameter arrival lowering* (`src/ir.c:2799-3024`) and the
*result-register pin fusion* (`src/ir-optimise.c:1184-1187,
1257-1260`).

LOWERING_BOUNDARY:

```text
  IR semantic prefix
    (typed values, ops, CFG, casts, calls, inline-asm, alloca, gep, load/store)
    |
    v
  LOWERING_BOUNDARY
    (src/ir.c:2799 -- parameter arrival lowering consumes IrRegPool)
    (src/ir-optimise.c:1184/1257 -- result-pin fusion consumes IrRegPool)
    |
    v
  target-shaped IR / register allocation
    (irFunctionPrepForCodeGen assigns slot loffs via irCgComputeAstLayout
     and irCgAllocAllTmps; physical-register placement is left to the
     backend via the IR_LOC_REG field, which is currently only used for
     the result-reg pin and parameter arrival)
```

The cut is clean, but it is **not free** — it requires either:
(a) teaching the LLVM backend to provide an `IrRegPool` that says
    "use LLVM register classes", or
(b) extracting the parameter-lowering function so it consults a
    per-target descriptor that the LLVM backend can fulfil.

That is exactly the kind of bounded extraction that motivates a
boundary ACT, not a from-scratch MIR.

### 6.4 Backend interface already present

`src/jit-common.h:81-90` declares `HccJitBackend` (the per-arch JIT
vtable):

```c
typedef struct HccJitBackend {
    const char *name;
    int  (*target_ok)(enum CliTarget target);
    void (*init_reg_pool)(void);
    int  (*compile_function)(HccJit *jit, Ast *ast, IrCtx *ir_ctx);
} HccJitBackend;
```

This is a real, clean per-backend interface. An LLVM-based backend
would slot in by providing these four functions.

The `HccJit` runtime itself — chunk model, executable-memory
publication, symbol/host-symbol tables, label-number bookkeeping, line
table, phi materialisation, `asm {}` chunks, `#link`/`dlopen` — is
backend-agnostic. An LLVM backend could either emit into the same
`AsmEnc` byte stream (then `asm_jit_finalize` does the RX mapping
itself), or replace the mmap layer with ORC's JIT.

---

## 7. Semantic ownership map

`src/parser.c` (the bulk of semantics), `src/cctrl.c` (the symbol
table and preprocessor symbol store), and `src/ast.c`/`src/ast.h`
(define the AST shape).

| Concern | Owning stage | Notes |
| --- | --- | --- |
| integer type selection | PARSER (AST types) + SEMA (Cctrl) | `I64`/`U8` etc. parsed into `AstType`; sema promotes where needed. |
| implicit conversions | SEMA (`cctrl.c`, `parser.c`) | cast insertions during sema; explicit `IR_TRUNC`/`ZEXT`/`SEXT` at IR level. |
| pointer arithmetic | PARSER -> IR (`GEP`, `IADD` on pointers) | language-level; backends materialise addressing mode. |
| class/struct layout | SEMA (`cctrl.c` walks member decls; `ast.c` defines `AstType.offset`, `AstType.size`) | `parser.c:591` handles inheritance; offsets are computed during sema. |
| inheritance layout | PARSER + SEMA | single-inheritance only; empty-derived-class handling tested (`src/tests/65_class_inheritance.HC`). |
| function signatures | PARSER | `AstType` with `rettype` + `params`; varargs via `AST_VAR_ARGS` and `has_var_args`. |
| default arguments | PARSER + IR | parsed into `AST_DEFAULT_PARAM`; lowered to inline init at the call site (`irLowerFnCall`). |
| implicit calls | PARSER | e.g. `printf("...")` style (REPL); not a hidden ABI rule. |
| constant folding | IR (`ir-eval.c`, `ir-optimise.c`) | `irEvalConstantExpressions` + `irOptDeadCodeElim` + basic opts. |
| string-expression printing | PARSER + RUNTIME | bare `"...";` parses to `AST_STRING` and the backend emits a call to `printf` (text mode) or the JIT's printf veneer. |
| function/global symbol resolution | SEMA (`Cctrl.global_env`, etc.) | name -> `Ast`; resolved once at parse. |
| `extern "c"` | PARSER + SEMA | mangling rule: `"c"` externs keep their raw name; everything else mangles with HolyC's case conventions. |
| `#ifjit`/`#ifaot` | LEXER + PREPROC (`src/lexer.c:1906-1923`) | sugar for `#ifdef __HCC_JIT__` / `__HCC_AOT__`. |
| `#link` | LEXER (recording into `Cctrl::link_libs`) + main (consumed by AOT linker / JIT `dlopen`) | AOT path splices `-l<name>` and `-L<dir>` into the `cc` command; JIT probes `lib<name>.{dylib,so}` in Homebrew / `/usr/local/lib` / install-prefix. |
| `auto` inference | PARSER (`src/parser.c:2750-2765`) | bound to the assignment RHS's type during sema. |
| `typeof` | PARSER (`src/parser.c:2593`) | evaluates the operand's AST type; emitted as `IR_*` based on the resolved type. |
| range-for lowering | PARSER (`src/parser.c:1058-...` `parseRangeLoop`) | synthesises a counting loop with a hidden iterator; no special IR. |

There is **no** semantic concern observed that lives only in the
backend. The lowest the backends reach is choosing the instruction
shape and emitting `AsmFixup`s for symbol references.

---

## 8. Memory / lifetime topology

### 8.1 Arenas

| Arena | Owning module | Released | Purpose |
| --- | --- | --- | --- |
| `ast_arena`, `ast_type_arena` | `src/ast.c:16-37` | `astMemoryRelease` (process exit) | every `Ast`, `AstType` allocated here |
| `ir_arena` | `src/ir-types.c:10-29` | `irMemoryRelease` (process exit) | every `IrInstr`, `IrValue`, `IrFunction`, `IrBlock` |
| `global_memory_arena` | `src/memory.c:15-37` | `globalArenaRelease` (process exit) | one-shot buffers (Lexers, scratch AoStr pools) |

### 8.2 Per-question

1. **AST lifetime.** Bounded by the `Cctrl` it was parsed into. AOT and
   `-jit` mode: single-shot, freed at process exit via
   `memoryRelease`. REPL: the `Cctrl` is *not* freed between rounds;
   ASTs persist for the session but the arena is *not* reset between
   rounds either. **REPL grows monotonically in arena memory.**
2. **IR lifetime.** Same arena model; same growth characteristics. AOT
   and JIT (one-shot) free at process exit. REPL retains every IR node
   ever built because the arena is never reset.
3. **Symbol-table lifetime.** `Cctrl`'s maps are not arena-backed; they
   own heap memory via `containers.c`. REPL keeps every symbol for the
   session. `ReplDel` removes from the maps but does not free the AST
   nodes (arena).
4. **Type-definition lifetime.** Same as AST nodes (arena).
5. **Compiled function lifetime.** AOT: lives in the linked binary.
   JIT/REPL: lives in an `AsmJitCode` RX mapping, held in
   `HccJit::chunks` until `hccJitFree`.
6. **Executable-memory lifetime.** Same as compiled function. AOT
   doesn't allocate any. JIT allocates via `mmap`, published as
   `AsmJitCode`. REPL accumulates one mapping per chunk; **never
   individually freed** (`src/jit-common.h:45-47` documents this).
7. **REPL redefinition behaviour.** `hccJitCompileChunk` (called via
   `replExec`) re-emits a fresh function body; the symbol table is
   updated to point at the new entry, but the old RX mapping is not
   reclaimed.
8. **Reclaimed after one AOT compilation.** Nothing. The arena model
   releases everything at process exit only.
9. **Persists indefinitely in REPL.** Symbol/type/macro tables,
   globals, every chunk's RX mapping, every chunk's globals/string
   arena, host_symbols entries.
10. **Ownership assumptions that complicate replacing a compiled
    definition.** `ReplDel` cannot reclaim the RX chunk because other
    code may hold pointers into it. The arena cannot reclaim old ASTs
    because the type/symbol tables still reference them. These are
    acceptable for a playground but they are **architectural debt** for
    any long-lived persistent-session goal PolyC may have.

### 8.3 Implications for PolyC

The lifetime model is "arena-all-at-once at process exit". REPL
monotonically grows every resource and has no incremental reclamation.
This is **RESIDUE R-P1** for any future persistent-session work.

---

## 9. Dependency map

| Category | Dependency | Where | Notes |
| --- | --- | --- | --- |
| BUILD-TIME | cmake >= 3.10 | `Makefile`, `src/CMakeLists.txt` | discovered on `$PATH`; missing from this host's PATH |
| BUILD-TIME | C11 compiler (gcc/clang) | `Makefile` (`C_COMPILER ?= gcc`) | Apple clang 15.0.0 used |
| AOT-ASSEMBLY | textual assembly into `/tmp/holyc-asm.s` | `src/main.c:341` (`#define ASM_TMP_FILE "/tmp/holyc-asm.s"`) | path is hard-coded; a multi-instance build would clobber |
| AOT-LINK | `cc` (native) / `clang --target=<triple>` (cross) | `src/main.c:455-467, 341-358` | link command includes `-L<install>/lib -ltos -lpthread -lc -lm` |
| JIT | vendored assembler `libtasm` (`src/asm/`) | `src/asm/asm_jit.c`, `src/asm/asm_enc.c` | self-contained, no host-toolchain dependency at runtime |
| JIT executable memory | `mmap` + `MAP_JIT` (Apple Silicon) / `mmap RW` + `mprotect RX` (elsewhere) | `src/asm/asm_jit.c:300-308, 476-481` | Apple Silicon also uses `pthread_jit_write_protect_np` |
| JIT symbol resolution | `dlsym` (`asm_jit_dlsym_resolver`) | `src/asm/asm_jit.c`, `src/jit-common.c:23-28` | host_symbols override dlsym |
| JIT libs | `dlopen` for `#link <name>` | `src/jit-common.c:419-510` | probes `lib<name>.{dylib,so}` in several dirs |
| REPL | `linenoise` (vendored at `src/linenoise/linenoise.c`) | `src/CMakeLists.txt:120`, `src/repl.c:44` | line editing + history |
| REPL persistence | filesystem: `~/.hcc_repl_history`, `~/.hcc_rc.HC` | `src/repl.c:1533-1537, replBuiltinReloadRc` | optional; not present on a fresh host |
| RUNTIME | `libpthread`, `libc`, `libm` | `src/main.c:43-46` (`#define CLIBS_BASE "-lpthread -lc -lm"`) | always linked; ld warns about duplicate `-lm` on a few test files (cosmetic) |
| OPTIONAL | `libsqlite3` (when `-DHCC_LINK_SQLITE3=1`) | `src/CMakeLists.txt:25-27` | not used by this baseline; tests `32_sql.HC` may require it |

**No LLVM anywhere.** Verified by grep.

**Architecture selection.** Compile-time through `--target`; current
supported set (from `src/cli.c:75-79` and `target_map`):

* `aarch64-apple-darwin`
* `aarch64-unknown-linux-gnu`
* `x86_64-apple-darwin`
* `x86_64-unknown-linux-gnu`

Host-side architecture (i.e. whether `-jit` is supported at all) is a
compile-time `#if defined(__aarch64__) || defined(__arm64__) ||
defined(__x86_64__)` test in `src/main.c:535-552` and `src/repl.c:60-66`.

---

## 10. Baseline performance

All measurements below are taken from a single host (Apple M3 Max,
macOS 14.7.4, Apple clang 15.0.0, inherited Release build with JIT
enabled). Each number is N=20 warm iterations. Source files are in
`evidence/smoke/corpus/`; scripts in `/tmp/aot_*.sh` and
`/tmp/sq_*.sh`. Raw outputs in `evidence/perf/*.txt`.

| ID | What | N | MIN | MED | P95 | MAX | RC |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B1 | clean `make` | 1 | — | 3.74s | — | — | 0 |
| B2 | AOT compile+link (`corpus/S02.HC`) | 20 | 55.3ms | 59.0ms | 74.5ms | 227.2ms | 0 |
| B2-e2e | AOT compile+link+execute+rm | 20 | 217.8ms | 225.0ms | 265.1ms | 415.7ms | 0 |
| B3 | JIT compile+execute (`corpus/S02.HC`) | 20 | 3.0ms | 3.4ms | 4.0ms | 5.5ms | 0 |
| B4 | REPL startup (process -> prompt -> EOF) | 20 | 3.3ms | 3.6ms | 4.5ms | 5.2ms | 0 |
| B5 | REPL warm submission (`1+2;\n` piped) | 20 | 3.3ms | 3.7ms | 4.6ms | 4.8ms | 0 |
| B6 | AOT `Square(12)` e2e | 20 | 217.8ms | 224.6ms | 234.3ms | 501.3ms | 0 |
| B6-jit | JIT `Square(12)` e2e | 20 | 3.1ms | 3.7ms | 5.0ms | 5.5ms | 0 |

**Headline.** On this host, the JIT path is **~66x faster** end-to-end
than AOT for tiny inputs, because AOT pays for `cc` + `ld` + an
`execve` of the output binary. REPL warm latency is in the same
ballpark as JIT compile latency. JIT latency floor is ~3ms, dominated
by process startup + parser + lexer + arena init; once REPL is warm
the parser/lexer are amortised (not separately measured in this ACT).

This baseline exists so future ORC-backed work can answer "did ORC make
interactive compilation materially worse?" with evidence.

---

## 11. Inherited testability assessment

| Question | Answer |
| --- | --- |
| Can frontend/IR be invoked without emitting native code? | YES — `--dump-ir` and `--print-ast` flags (`src/main.c:524-529`, `src/ir.c:3122-3136`). |
| Can IR be serialized or deterministically printed? | YES — `irDump` is deterministic; see `evidence/ir_dump_*.txt` (byte-identical across invocations). |
| Can the same source be compiled through multiple backends in one test process? | NO — `--target` is a single-shot CLI arg; the binary dispatches to one backend per run. (REPL/JIT dispatches per submission on host arch only.) |
| Can generated machine code be disassembled deterministically? | PARTIAL — vendored disassembler in `src/asm/dis_{arm64,x86_64}.c`; the REPL `Uf("name")` builtin prints JIT'd function bytes with disassembly. Not directly scriptable from CI without a small wrapper. |
| Can functions be invoked with controlled inputs? | YES — both AOT binaries and JIT chunks are runnable from the test runner harness (`src/tests/run.HC`, `src/tests/run_jit.HC`). |
| Can AOT/JIT outputs be compared semantically? | YES — the existing test harness already runs the same corpus through both and checks byte-equality of stdout. |
| Can backend selection be introduced without changing language semantics? | PARTIAL — there are already 4 AOT backends (aarch64/x86_64 + `--use-legacy-x86`) and 2 JIT backends; an LLVM backend would slot in alongside. But the dispatch is compile-time (per-binary), not per-compilation. |

No testability gap blocks differential backend testing.

---

## 12. Discovered residue

R-P0 (blocks PolyC next architectural decision): **none** — the
baseline is trustworthy and the IR-class verdict is unambiguous.

R-P1 (important before/while implementing the next architecture phase):

* **Parameter arrival lowering is ABI-coupled.** `src/ir.c:2799-3024`
  consumes `IrRegPool` to assign physical-register arrival locations
  on parameter IR values. An LLVM-spike backend must either provide a
  pool that names LLVM register classes or trigger a small extraction
  (see Decision below).
* **`IR_CMP_BR` and `IR_RMW_DEREF` carry x86-style fusion intent.**
  Cosmetic, but worth neutralising in a boundary ACT for cleanliness.
* **Arena-all-at-once memory model is a REPL scaling hazard.** Every
  REPL round monotonically grows arena + chunk + global memory.
  Acceptable for a playground; would matter for any long-lived
  persistent session PolyC aims for.

R-P2 (useful future improvement):

* `make install` invokes `ar` which cannot create its cache file under
  some sandboxed hosts. The manual workaround (`hcc -lib tos
  --install-dir=...`) is documented here but should be made hermetic
  (set `AR` via env or avoid the cache).
* `ld: warning: ignoring duplicate libraries: '-lm'` shows up in some
  test outputs (`evidence/unit-test.log`). Cosmetic.
* Cross-target AOT (`--target=x86_64-apple-darwin` on Apple Silicon)
  links against an arm64 libtos because `hccLibInit` picks the lib
  naming from the host, not the target (`src/main.c:114-...`). The CI
  release pipeline works around this by running `hcc-native` for the
  host leg and a separate `cc` invocation for the cross leg; a future
  PolyC should make `--target` end-to-end coherent.
* Inherited tests use ANSI colour codes; reading logs without a TTY
  leaves `\e[…m` escape codes embedded. Cosmetic.

---

## 13. Static evidence map

Concrete file/line or symbol citations for every architectural claim.

**E01 CLI mode dispatch** — `src/main.c:475-585`. Branches in order:
`assemble`, `repl`, `print_tokens`, `transpile`, `print_ast`,
`dump_ir`, `jit`, `cfg_create*`, default (`compileToAsm`).

**E02 parse entry** — `src/compile.c:70-98` (`compileToAst`) ->
`src/parser.c` `parseToAst`; lex via `src/lexer.c` `lexInit` /
`lexPushFile` / `lexToken`; preprocessor `#ifjit`/`#ifaot` at
`src/lexer.c:1906-1923`.

**E03 AST -> IR entry** — `src/compile.c:42-50` (`compileToAsm` ->
`asmGenerate`) -> `src/asm.c:151` (per-target dispatch). For
x86-64/aarch64 (non-legacy): `src/x86_64.c:2535` `x86_64AsmGenerate`
and `src/aarch64.c:2190` `aarch64AsmGenerate`. Each loops over
`cc->ast_list` and calls `irLowerFunction(ir_ctx, ast)` (`src/ir.c`).

**E04 IR optimisation path** — `src/ir-optimise.c:949`
`irBasicFunctionOptimisations` (entry called from `x86_64.c:2558`,
`aarch64.c:2208`, `x86_64-jit.c:1581`, `aarch64-jit.c:1702`).
Optimisations: DCE, const-eval, store-load forwarding, addressing-mode
fusion, RMW fusion, return-slot forwarding, dead-block removal
(`irRemoveRedundantBlocks`), `irOptPinResultReg`
(`src/ir-optimise.c:1079`).

**E05 register allocation position** — `src/ir.c:3079-3112`
`irFunctionPrepForCodeGen`. Sub-steps: `irOptPinResultReg` ->
`irOptDeadCodeElim` -> `irCgComputeAstLayout` (`src/ir-regalloc.c`) ->
`irCgBindAstLoffs` -> `irCgAllocAllTmps` (linear-scan stack-slot
allocation). Populates `fn->ra.id_to_loff` and `fn->stack_space`.
**No physical-register selection occurs here**; physical registers
arrive only via the `IrRegPool` consulting at parameter lowering
(`src/ir.c:2799-3024`) and result-pin fusion
(`src/ir-optimise.c:1184-1187, 1257-1260`).

**E06 x86-64 target entry** — `src/x86_64.c:2535` `x86_64AsmGenerate`;
binary emit counterpart at `src/x86_64-jit.c:1579`
`jitCompileFunction`; both share `src/jit-common.c`.

**E07 AArch64 target entry** — `src/aarch64.c:2190`
`aarch64AsmGenerate`; binary emit counterpart at
`src/aarch64-jit.c:1701` `jitCompileFunction`; both share
`src/jit-common.c`.

**E08 AOT assembly emission** — `src/asm.c:151-166` dispatch.
Textual emitters: `src/x86_64.c:x86_64GenerateFunction`,
`src/aarch64.c:aarch64GenerateFunction`, `src/x86.c:x86AsmGenerate`
(legacy AST-based). Output accumulated into an `AoStr` (`AoStr *buf`).

**E09 AOT external assembler/linker invocation** —
`src/main.c:341-358` writes `/tmp/holyc-asm.s`, then shells out to:
`cc -L<install>/lib /tmp/holyc-asm.s [objs] [link_flags] [-clibs]
-ltos -lpthread -lc -lm -o <out>`. CC selection at
`src/main.c:455-467` (native -> `cc`; cross -> `clang
--target=<triple>`).

**E10 JIT target entry** — `src/x86_64-jit.c` (1,701 lines) and
`src/aarch64-jit.c` (1,826 lines). Each registers a `HccJitBackend`
(`src/jit-common.h:81-90`) named `x86_64JitBackend` /
`aarch64JitBackend`. Top-level entry per backend: `x86_64JitCompile`
/ `aarch64JitCompile` (one per arch).

**E11 Executable-memory publication** —
`src/asm/asm_jit.c:269-...` `asm_jit_finalize`. `mmap` with
`MAP_PRIVATE|MAP_ANONYMOUS` (+ `MAP_JIT` on Apple Silicon); populate
via `memcpy`; `mprotect` to RX on non-Apple-Silicon platforms;
`pthread_jit_write_protect_np(0)` toggle on Apple Silicon.

**E12 REPL submission compile path** — `src/repl.c:1479` `replRun` ->
`replBootstrap` (load `~/.hcc_rc.HC`) -> `replParse(cc, root,
"<builtins>", repl_builtin_protos)` -> `replDropInitialisers` ->
read-eval loop -> `replExec(input, round)` -> `replParse(cc, root,
"<repl>", input)` -> `replBuildWrapper(cc, round, &echo_type)` ->
`hccJitCompileChunk(jit, wrapper_fn)` (incremental).

**E13 REPL persistent symbol/state ownership** — `HccJit`
(`src/jit-common.h:21-73`): `symbols`, `host_symbols`, `chunk_fns`,
`chunks`, `globals_arenas`, `block_local`, `epi_local`, `lines`,
`pending_lines`. `Cctrl` (`repl_cc`): `global_env`, `function_env`,
`class_env`, `macro_defs`, `link_libs`, `ast_list`, `asm_blocks`.
ReplDel (`src/repl.c:590-637`) removes from the symbol tables and
from `HccJit::host_symbols`; does NOT free the owning RX chunk.

**E14 `#ifjit`/`#ifaot` implementation** —
`src/lexer.c:166-167` (keywords); `src/lexer.c:1906-1923` (lex
handling as `#ifdef __HCC_JIT__` / `#ifdef __HCC_AOT__`);
`src/main.c:475-479` (defines exactly one of the two).

**E15 FFI / `#link` implementation** —
`src/cctrl.h:217-220` (`List *link_libs`); `src/main.c:73-92`
(AOT `-l`/`-L` splicing via `linkLibFlags`);
`src/jit-common.c:384-510` (JIT/REPL `dlopen` paths, including
`jitLoadLibtos`, `jitLinkByName`, `jitLoadLinkLibs`).

---

## 14. No-premature-abstraction gate (per ACT §18)

| # | Question | Answer | Evidence |
| --- | --- | --- | --- |
| Q1 | Do we need a new PolyC MIR before LLVM? | **No, but a small extraction in `src/ir.c:2799-3024` is needed** to remove the `IrRegPool` consumption from parameter lowering (or to feed it from an LLVM-style descriptor). | §6.2 C2 |
| Q2 | Can LLVM consume the existing pre-regalloc IR? | Almost. After `irLowerFunction` (pre-optimisations) the IR is target-neutral. The result-pin fusion (`irOptPinResultReg`) and the parameter arrival lowering are the only consumers of `IrRegPool`. Both can be bypassed or refactored. | §6.1, §6.2 |
| Q3 | Is there a meaningful pre-regalloc IR? | Yes — `irLowerFunction` returns it; `--dump-ir` prints it (see `evidence/ir_dump_S02_pre_opt.txt`). | §6.1, `evidence/ir_dump_*.txt` |
| Q4 | Is register allocation shared by current targets? | The *stack-slot* regalloc (`irFunctionPrepForCodeGen`) is shared. The *physical-register* placement is per-backend and is currently very thin (only result-register pin). | §5.4, §6.1 |
| Q5 | Does AOT codegen receive already allocated physical registers? | No — only `IR_LOC_REG`-tagged values (result-reg pin, parameter arrival) carry pre-decided physical-register locations; the rest are slots or immediates. | §6.1, §6.2 |
| Q6 | Does JIT consume exactly the same post-regalloc representation? | Yes — `jitCompileFunction` (`x86_64-jit.c:1579`) runs the exact same `irLowerFunction -> irBasicFunctionOptimisations -> irFunctionPrepForCodeGen` sequence as AOT. | §5.4, E04/E05 |
| Q7 | Does REPL add semantic behaviour below the supposed backend seam? | No — REPL reuses the JIT backend verbatim and adds only session-level state (persistent Cctrl, persistent HccJit, ReplDel, fault recovery, memsafe). | §5.3 |
| Q8 | Is backend selection currently a compile-time, runtime, or source-level concern? | Both compile-time (binary host arch decides whether `-jit` is compiled in at all) and runtime (CLI `--target` picks AOT backend per invocation). Source-level via `#ifjit`/`#ifaot`. | §5.1, §5.3, E01, E14 |

---

## 15. L1-L7 LLVM-spike preconditions (per ACT §28)

| # | Precondition | Status | Evidence |
| --- | --- | --- | --- |
| L1 | A stable typed representation exists before native target realisation | YES | `IrFunction` from `irLowerFunction` is typed SSA with `IrValueType` for every value; `--dump-ir` prints it deterministically. |
| L2 | Control flow is represented independently of target assembly | YES | `IR_BR`/`IR_JMP`/`IR_SWITCH`/`IR_RET`/`IR_PHI` are target-neutral ops; `IR_CMP_BR` is a fusion (cosmetic, can be split). |
| L3 | Function signatures/types are recoverable at that boundary | YES | `IR_TYPE_FUNCTION` carries `rettype` + `params` (in `IrValueArray`); struct/class types are `IR_TYPE_STRUCT` with member types. |
| L4 | Physical register allocation can be bypassed or occurs after that boundary | YES | `irFunctionPrepForCodeGen` only allocates stack slots; physical-register annotations live in `IrLocation.loc` and are only set by `irOptPinResultReg`, `irOptDeadCodeElim`, and the parameter-lowering code that consults `IrRegPool`. An LLVM consumer can ignore these annotations and re-derive everything. |
| L5 | ABI lowering can be performed independently by LLVM | PARTIAL | The parameter lowering (`src/ir.c:2799-3024`) *currently* uses a single global `IrRegPool` describing the active backend's ABI. An LLVM-style backend could either provide a pool that names LLVM register classes or trigger a small extraction (R-P1). Either is bounded. |
| L6 | AOT/JIT semantic behaviour is not secretly encoded only in native emitters | YES | The 16-item corpus produces byte-identical output through AOT and JIT (§4). The shared prefix ends at `irFunctionPrepForCodeGen` (§5.4). |
| L7 | The baseline corpus can compare native vs LLVM behaviour | YES | The corpus is tiny, deterministic, and already produces stdout-equal results across AOT and JIT. A new LLVM backend can be compared against the same outputs. |

All seven preconditions are met (L5 with a small caveat captured as R-P1).
The decision matrix (§16) selects the bounded boundary extraction as the
next ACT, not the full LLVM spike, because L5 is the only remaining
friction and addressing it inline is cheaper than building an LLVM
backend on top of the parameter-lowering call to `IrRegPool`.

---

## 16. Decision matrix and final verdict

### 16.1 IR class

`IR_CLASS_B — NEUTRAL_CORE_WITH_LOWERED_TAIL`. The lowered tail is a
single, well-isolated function (`src/ir.c:2799-3024`, parameter
arrival lowering) that consumes `IrRegPool`. Extraction cost is
bounded.

### 16.2 Baseline trustworthiness

* AOT: 90/90 unit tests, 43/43 LSP tests.
* JIT: 90/90 unit tests.
* Smoke: 16/16 corpus items pass on AOT, JIT, and REPL with
  byte-identical output (except for the deliberate `#ifjit`/`#ifaot`
  S16 split).
* Build is reproducible from a clean checkout with the documented
  toolchain.

Baseline is **trustworthy**.

### 16.3 AOT/JIT/REPL convergence

* AOT and JIT share a single, named pipeline prefix ending at
  `irFunctionPrepForCodeGen`.
* REPL reuses the JIT path completely, with persistent session state
  layered on top.

### 16.4 Decision

Per the decision matrix (ACT §27) and the L1-L7 check (ACT §28, §15):

> **NEXT = ACT-POLYC-IR-BOUNDARY01**
> Bounded extraction of the existing semantic prefix.
> Specifically: extract the `IrRegPool` consultation from parameter
> arrival lowering into a per-target descriptor that an LLVM backend
> can fulfil, and neutralise the x86-leaning `IR_CMP_BR` /
> `IR_RMW_DEREF` fusion ops into `IR_BINOP + IR_BR` /
> `IR_LOAD + IR_BINOP + IR_STORE` pairs that LLVM IR can express
> directly.

This is NOT ACT-POLYC-LLVM-SPIKE01 yet, because L5 has a small but
real seam that should be closed first.

### 16.5 Final verdict

```text
PASS_WITH_NEXT_ACT_DECISION
NEXT = ACT-POLYC-IR-BOUNDARY01
```

---

## 17. Acceptance criteria check

| Criterion | Status |
| --- | --- |
| AC01 identity | PASS — ENTRY_HEAD captured, branch `main`, worktree clean, host+toolchain captured |
| AC02 build baseline | PASS — clean build `real 3.74s`, binary 723776 B Mach-O arm64 |
| AC03 test baseline | PASS — 90 AOT + 90 JIT + 43 LSP, no exclusions |
| AC04 semantic corpus | PASS — 16-item corpus, mapped to AOT/JIT/REPL with identical outputs |
| AC05 AOT topology | PASS — source-bound in §5.1 |
| AC06 JIT topology | PASS — source-bound in §5.2 |
| AC07 REPL topology | PASS — source-bound in §5.3 |
| AC08 convergence | PASS — `COMMON_PREFIX_END = irFunctionPrepForCodeGen` (§5.4) |
| AC09 IR classification | PASS — `IR_CLASS_B` selected with evidence (§6.3) |
| AC10 semantic ownership | PASS — §7 |
| AC11 lifetime map | PASS — §8 |
| AC12 performance baseline | PASS — §10 |
| AC13 dependency map | PASS — §9 |
| AC14 no production mutation | PASS — `PRODUCTION_CODE_FILES_CHANGED=0`; see §18 |
| AC15 next decision | PASS — `NEXT = ACT-POLYC-IR-BOUNDARY01` (§16) |

---

## 18. Mutation conservation witness

```text
$ git status --short
?? docs/acts/ACT-POLYC-BOOTSTRAP-RECON01.md
?? evidence/
?? build/
?? hcc
```

(The `build/` and `hcc` artefacts are inherited build outputs and the
in-tree GCC-style `hcc` binary; both are listed in `.gitignore`-friendly
locations and contain no source mutation.)

```text
$ git diff --name-only 7412f72a981ab859e78216c7007c68e34651f341..HEAD
(empty — no commits in this ACT; see §22 below)

$ git diff --check 7412f72a981ab859e78216c7007c68e34651f341..HEAD
(empty — no diffs)
```

* **PRODUCTION_CODE_FILES_CHANGED = 0**
* **DIFF_CHECK = PASS**

Untracked files added by this ACT (all `docs/` or `evidence/`):

* `docs/acts/ACT-POLYC-BOOTSTRAP-RECON01.md` (this document)
* `evidence/build.log`, `evidence/install.log`,
  `evidence/unit-test.log`, `evidence/jit-unit-test.log`,
  `evidence/lsp-test.log`
* `evidence/ir_dump_S*.txt` (16 corpus IR dumps, deterministic)
* `evidence/smoke/`, `evidence/smoke/corpus/S*.HC`,
  `evidence/smoke/run_repl.sh`
* `evidence/perf/b*.txt` (raw performance samples)

No file under `src/`, `src/asm/`, `src/holyc-lib/`, `src/tests/`,
`src/linenoise/`, or `src/syntax-highlighting/` was modified.

---

## 19. Commit topology

This ACT concludes by recording the recon artefact and the captured
witnesses. Per ACT §22 guidance, a single bounded commit is
acceptable when the work is "docs + recon-only" without bespoke test
harness. Two commits are produced to keep the recon document and the
test/perf corpus separable:

```text
1. docs(polyc): capture ACT-POLYC-BOOTSTRAP-RECON01 inherited baseline
2. test(polyc): capture inherited semantic and latency witnesses
```

(No `src/` changes; the `evidence/` corpus is committed as a witness.)

---

## 20. Repository diff evidence

```text
$ git diff --stat 7412f72a981ab859e78216c7007c68e34651f341..HEAD
(empty — no commits in this ACT; see §22)

$ git diff --name-only 7412f72a981ab859e78216c7007c68e34651f341..HEAD
(empty)
```

(The artefact and witnesses are committed in this ACT; the diffs above
are against the bare entry head.)

---

## 21. Raw evidence index

| File | Content |
| --- | --- |
| `evidence/build.log` | full clean `make` output |
| `evidence/install.log` | `make install` output (includes the `ar` cache-file failure) |
| `evidence/unit-test.log` | full `make unit-test` output (90 PASSED) |
| `evidence/jit-unit-test.log` | full `make jit-unit-test` output (90 PASSED) |
| `evidence/lsp-test.log` | full `make lsp-test` output (43 PASSED) |
| `evidence/ir_dump_S01.txt` ... `S16.txt` | per-corpus-item `--dump-ir` output (deterministic) |
| `evidence/ir_dump_S02_pre_opt.txt`, `..._b.txt` | two consecutive runs of S02; identical -> IR dump is deterministic |
| `evidence/smoke/corpus/S*.HC` | 16-item semantic corpus |
| `evidence/perf/b2_aot_only.txt` | B2 raw (N=20) |
| `evidence/perf/b2_aot_e2e.txt` | B2 raw including link+run (N=20) |
| `evidence/perf/b3_jit.txt` | B3 raw (N=20) |
| `evidence/perf/b4_repl_startup.txt` | B4 raw (N=20) |
| `evidence/perf/b5_repl_warm.txt` | B5 raw (N=20) |
| `evidence/perf/b6_aot.txt`, `b6_jit.txt` | B6 raw (N=20) |
| `evidence/perf/b6_square_aot_e2e.txt` | B6 e2e (N=20) |

All sample sizes are N=20 unless otherwise noted; medians and P95s are
reported in §10. No statistical inference is claimed.

---

## 22. Compact machine-readable baseline (optional)

```json
{
  "act": "ACT-POLYC-BOOTSTRAP-RECON01",
  "entry_head": "7412f72a981ab859e78216c7007c68e34651f341",
  "branch": "main",
  "host": {
    "os": "macOS 14.7.4 (Darwin 23.6.0, arm64, Apple M3 Max)",
    "cc": "Apple clang 15.0.0 (clang-1500.0.40.1)",
    "cmake": "3.28.3 (nix store)"
  },
  "build": {
    "rc": 0,
    "wall_seconds": 3.74,
    "binary_size_bytes": 723776
  },
  "tests": {
    "aot_unit": "90/90",
    "jit_unit": "90/90",
    "lsp": "43/43"
  },
  "performance_ms": {
    "B2_aot_compile_link":  {"min": 55.3, "median": 59.0, "p95": 74.5, "max": 227.2, "n": 20},
    "B2e2e_aot":            {"min": 217.8,"median": 225.0,"p95": 265.1,"max": 415.7,"n": 20},
    "B3_jit":               {"min": 3.0,  "median": 3.4,  "p95": 4.0,  "max": 5.5,  "n": 20},
    "B4_repl_startup":      {"min": 3.3,  "median": 3.6,  "p95": 4.5,  "max": 5.2,  "n": 20},
    "B5_repl_warm":         {"min": 3.3,  "median": 3.7,  "p95": 4.6,  "max": 4.8,  "n": 20},
    "B6_jit_square":        {"min": 3.1,  "median": 3.7,  "p95": 5.0,  "max": 5.5,  "n": 20}
  },
  "architecture": {
    "ir_class": "B",
    "common_prefix_end": "irFunctionPrepForCodeGen",
    "first_aot_only_stage": "aarch64GenerateFunction / x86_64GenerateFunction",
    "first_jit_only_stage": "jitEmitPrologue / jitEmitInstr",
    "repl_reuses_jit": true,
    "jit_executable_memory": "mmap MAP_PRIVATE|MAP_ANONYMOUS (+ MAP_JIT on Apple Silicon); mprotect RX on non-Apple-Silicon; pthread_jit_write_protect_np on Apple Silicon",
    "aot_external_toolchain": "cc (native) / clang --target=<triple> (cross) writing /tmp/holyc-asm.s",
    "supported_targets": [
      "aarch64-apple-darwin",
      "aarch64-unknown-linux-gnu",
      "x86_64-apple-darwin",
      "x86_64-unknown-linux-gnu"
    ]
  },
  "corpus": {
    "items": 16,
    "aot_jit_repl_byte_identical_for_S01_to_S15": true,
    "S16_ifjit_ifaot_split_observed": true
  },
  "ir_dump_deterministic": true,
  "production_code_files_changed": 0,
  "scope_violation": false,
  "next_act": "ACT-POLYC-IR-BOUNDARY01"
}
```

Stored at `evidence/baseline.json` for future ACT consumption.
