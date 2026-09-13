// ERR03: identifier-start byte is a digit.
// The lexer's dispatcher gate at lexCore is:
//   if (isalpha(ch) || ch == '_') {
//       ... call lexIdentifier ...
//   }
// A digit at identifier-start position does NOT
// enter lexIdentifier (no B1 vs legacy divergence
// here). The dispatcher's `default` case breaks,
// which leads the while(1) loop to read the next
// char; if the next byte is also a digit the
// `case '0'..'9'` numeric lexer is invoked. The
// resulting numeric literal will then collide with
// the trailing alphabetic part and produce a
// deterministic parse error.
//
// This exercises the dispatcher-gate behaviour
// around lexIdentifier on both compilers, ensuring
// no B1-vs-legacy divergence in the surrounding
// control flow.

I64 Main() {
  I64 9bad = 1;
  return 9bad;
}
