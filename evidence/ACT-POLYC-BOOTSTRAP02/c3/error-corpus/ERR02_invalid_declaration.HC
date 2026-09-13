// ERR02: identifier followed by malformed declaration.
// An identifier followed by `:::` which is not a valid
// punctuator triple in HolyC.
I64 Main() {
  I64 foo :::;
  return foo;
}
