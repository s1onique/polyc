// ERR04: identifier followed by an intentional parser error.
// An identifier followed by an unclosed `(` without
// closing `)`.
I64 Main() {
  foo(;
  return 1;
}
