// ERR01: unterminated string literal
// Stage0 reports an unterminated-string error.
// Stage1 must report the same error class.
I64 Main() {
  U8 *s = "hello
  return 1;
}
