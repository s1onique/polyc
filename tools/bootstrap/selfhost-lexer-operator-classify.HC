// tools/bootstrap/selfhost-lexer-operator-classify.HC
//
// ACT-POLYC-SELFHOST-LEXER01 C2 IMPL — PolyC operator /
// punctuation classification component.
//
// This file is the WINNER SUBJECT (operator_punctuation_recognizer).
// It is a self-contained compiler-shaped executable proof:
// bytes in, (kind, length) out, written in PolyC, allocation-free,
// no AST, no parser mutation.
//
// Frozen ABI (must match winner-abi-contract.txt):
//
//   I64 BootstrapClassifyOperator(
//       U8  *src,
//       I64  src_len,
//       I64  cursor,
//       I64  flags,
//       I64 *out_kind,
//       I64 *out_length
//   );
//
// Returns 1 if src[cursor] is an operator/punctuation byte;
// on success *out_kind and *out_length are populated.
//
// Returns 0 if src[cursor] is NOT an operator/punctuation byte;
// the caller falls through to the next dispatcher arm.
//
// Character domain (binding):
//   B_LEXER_OPERATOR_CHARACTER_DOMAIN     = ASCII
//   B_LEXER_OPERATOR_CTYPE_DEPENDENCY      = NONE
//   B_LEXER_OPERATOR_NON_ASCII_EQUIVALENCE = NOT_CLAIMED
//
// Implementation requirements (all met):
//   - single forward scan (no recursion, no backtracking)
//   - no dynamic allocation
//   - no source mutation
//   - no global mutable state
//   - bounded reads (peek past end returns 0)
//   - deterministic result
//   - explicit byte comparisons; no <ctype.h> dependency

// Frozen operator / punctuation token-kind constants
// (from src/lexer.h, included here for self-containment)

#define OP_TK_EQU_EQU       0x30B
#define OP_TK_NOT_EQU       0x30C
#define OP_TK_LESS_EQU      0x30D
#define OP_TK_GREATER_EQU   0x30E
#define OP_TK_AND_AND       0x30F
#define OP_TK_OR_OR         0x310
#define OP_TK_SHL_EQU       0x312
#define OP_TK_SHR_EQU       0x313
#define OP_TK_MUL_EQU       0x314
#define OP_TK_DIV_EQU       0x315
#define OP_TK_AND_EQU       0x316
#define OP_TK_OR_EQU        0x317
#define OP_TK_XOR_EQU       0x318
#define OP_TK_ADD_EQU       0x319
#define OP_TK_SUB_EQU       0x31A
#define OP_TK_PLUS_PLUS     0x305
#define OP_TK_MINUS_MINUS   0x306
#define OP_TK_DBL_COLON     0x308
#define OP_TK_SHL           0x309
#define OP_TK_SHR           0x30A
#define OP_TK_MOD_EQU       0x322
#define OP_TK_ELLIPSIS      0x324
#define OP_TK_ARROW         0x328

// Flag bits (matching src/lexer.h CCF_* definitions; the
// wrapper forwards l->flags unchanged, so the bit positions
// here MUST match the host-C definitions exactly).
#define OP_CCF_ASM_BLOCK    (1 << 4)
#define OP_CCF_MULTI_COLON  (1 << 3)

// ASCII byte predicate: is ch an operator/punctuation trigger?
I64 OpIsOpTrigger(U8 c)
{
  if (c == '=') return 1;
  if (c == '<') return 1;
  if (c == '>') return 1;
  if (c == '+') return 1;
  if (c == '-') return 1;
  if (c == '!') return 1;
  if (c == '&') return 1;
  if (c == '|') return 1;
  if (c == '*') return 1;
  if (c == '%') return 1;
  if (c == '^') return 1;
  if (c == '$') return 1;
  if (c == '@') return 1;
  if (c == '.') return 1;
  if (c == '\\') return 1;
  if (c == ':') return 1;
  if (c == '#') return 1;
  if (c == '~') return 1;
  if (c == '(') return 1;
  if (c == ')') return 1;
  if (c == ',') return 1;
  if (c == ';') return 1;
  if (c == '[') return 1;
  if (c == ']') return 1;
  if (c == '{') return 1;
  if (c == '}') return 1;
  if (c == '/') return 1;
  return 0;
}

// BootstrapClassifyOperator: the WINNER subject proper.
// Allocation-free, single-pass, deterministic, ASCII-only.
public I64 BootstrapClassifyOperator(
    U8 *src, I64 src_len,
    I64 cursor, I64 flags,
    I64 *out_kind, I64 *out_length)
{
  if (src == NULL)              return 0;
  if (out_kind == NULL)         return 0;
  if (out_length == NULL)       return 0;
  if (cursor < 0)               return 0;
  if (cursor >= src_len)        return 0;

  U8 ch = src[cursor];
  if (!OpIsOpTrigger(ch))       return 0;

  // Safe peek: returns 0 if past end
  U8 peek1 = 0;
  if (cursor + 1 < src_len) peek1 = src[cursor + 1];
  U8 peek2 = 0;
  if (cursor + 2 < src_len) peek2 = src[cursor + 2];

  if (ch == '=') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_EQU_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '<') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_LESS_EQU;
      *out_length = 2;
    } else if (peek1 == '<') {
      if (peek2 == '=') {
        *out_kind   = OP_TK_SHL_EQU;
        *out_length = 3;
      } else {
        *out_kind   = OP_TK_SHL;
        *out_length = 2;
      }
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '>') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_GREATER_EQU;
      *out_length = 2;
    } else if (peek1 == '>') {
      if (peek2 == '=') {
        *out_kind   = OP_TK_SHR_EQU;
        *out_length = 3;
      } else {
        *out_kind   = OP_TK_SHR;
        *out_length = 2;
      }
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '+') {
    if (peek1 == '+') {
      *out_kind   = OP_TK_PLUS_PLUS;
      *out_length = 2;
    } else if (peek1 == '=') {
      *out_kind   = OP_TK_ADD_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '-') {
    if (peek1 == '-') {
      *out_kind   = OP_TK_MINUS_MINUS;
      *out_length = 2;
    } else if (peek1 == '>') {
      *out_kind   = OP_TK_ARROW;
      *out_length = 2;
    } else if (peek1 == '=') {
      *out_kind   = OP_TK_SUB_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '!') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_NOT_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '&') {
    if (peek1 == '&') {
      *out_kind   = OP_TK_AND_AND;
      *out_length = 2;
    } else if (peek1 == '=') {
      *out_kind   = OP_TK_AND_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '|') {
    if (peek1 == '|') {
      *out_kind   = OP_TK_OR_OR;
      *out_length = 2;
    } else if (peek1 == '=') {
      *out_kind   = OP_TK_OR_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '*') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_MUL_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '%') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_MOD_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '^') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_XOR_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '$') {
    if (!(flags & OP_CCF_ASM_BLOCK)) return 0;
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == '@') {
    if (!(flags & OP_CCF_ASM_BLOCK)) return 0;
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == '#') {
    if (!(flags & OP_CCF_ASM_BLOCK)) return 0;
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == '.') {
    if (peek1 >= '0' && peek1 <= '9') {
      return 0;
    }
    if (peek1 == '.' && peek2 == '.') {
      *out_kind   = OP_TK_ELLIPSIS;
      *out_length = 3;
      return 1;
    }
    if (peek1 == '.') {
      return 0;
    }
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == '\\') {
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == ':') {
    if ((flags & OP_CCF_MULTI_COLON) && peek1 == ':') {
      *out_kind   = OP_TK_DBL_COLON;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  if (ch == '~' || ch == '(' || ch == ')' ||
      ch == ',' || ch == ';' ||
      ch == '[' || ch == ']' ||
      ch == '{' || ch == '}') {
    *out_kind   = ch;
    *out_length = 1;
    return 1;
  }
  if (ch == '/') {
    if (peek1 == '=') {
      *out_kind   = OP_TK_DIV_EQU;
      *out_length = 2;
    } else {
      *out_kind   = ch;
      *out_length = 1;
    }
    return 1;
  }
  return 0;
}
