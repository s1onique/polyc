// src/holyc-lib/memory_defs.HH
//
// ACT-POLYC-INTEGRATION-PREBOOTSTRAP-GATES01-CORRECTION01 C2 IMPL.
//
// Declaration-only header exposing the public surface of
// `memory.HC` so that test harnesses can consume the API
// without dragging in implementation source.
//
// This header MUST NOT include any libtos source. It is
// pure declarations matching the bodies in `memory.HC`
// verbatim. Definitions resolve at link time via `-ltos`.

// C-library memory functions (mirror memory.HC).
public extern "c" U0 *memchr(U0 *__s, I32 __c, U64 __n);
public extern "c" I32 memcmp(U0 *__s1, U0 *__s2, U64 __n);
public extern "c" U0 *memmove(U0 *__dst, U0 *__src, U64 __len);
public extern "c" U0 free(U0 *ptr);
public extern "c" U0 *malloc(U64 size);
public extern "c" U0 *calloc(U64 count, U64 size);
public extern "c" U0 *realloc(U0 *ptr, U64 size);
public extern "c" U0 *memset(U0 *__dst, I32 __c, U64 __n);
public extern "c" U0 *memcpy(U0 *__dst, U0 *__src, U64 __n);

// libtos wrappers (mirror memory.HC public surface).
public _extern _MALLOC U0 *MAlloc(U64 size);
public _extern _FREE U0 Free(U0 *ptr);
public _extern _MSIZE U64 MSize(U0 *ptr);
public _extern _MEMSET U0 *MemSet(U0 *dst, I32 ch, U64 len);
public _extern _MEMCPY U0 *MemCpy(U0 *dst, U0 *src, U64 len);
public _extern _CALLOC U0 *CAlloc(U64 new_size);
public _extern _REALLOC U0 *ReAlloc(U0 *ptr, U64 new_size);

// String helpers used by tooling.hC and harnesses.
//
// NOTE: hcc has built-in knowledge of StrLen, StrCmp,
// StrNCmp, StrFirstOcc, StrPrint, etc. and maps them to
// the canonical libtos symbols (_STRLEN_FAST, _STRCMP,
// _STRNCMP, _StrFirstOcc, _StrPrint) at codegen time.
// We therefore do NOT redeclare them here — that would
// shadow the built-ins and force compilation against
// the redeclared names (e.g. _StrLen, which does NOT
// exist in libtos). The harness calls these symbols
// successfully without any prototype in this header.

// String helpers that are NOT hcc built-ins and are
// declared here for harness consumption. These resolve
// against libtos at link time.
public U8 *StrLastOcc(U8 *haystack, U8 *needle);
public U8 *StrLastRem(U8 *haystack, U8 *suffix);
public U8 *StrNCpy(U8 *dst, U8 *src, U64 n);
public U8 *StrNew(U8 *src);
