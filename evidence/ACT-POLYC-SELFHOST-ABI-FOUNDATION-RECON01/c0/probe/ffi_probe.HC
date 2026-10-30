// C0 RED dialect/FFI probe: can PolyC call a C host and echo an opaque token?
extern "c" I64 AbiHostEchoI64(I64 token);
extern "c" I64 AbiHostSizes(I64 which);
extern "c" Bool AbiHostBool(Bool value);

I64 AbiProbeEcho(I64 token) {
  return AbiHostEchoI64(token);
}

I64 AbiProbeSizes(I64 which) {
  return AbiHostSizes(which);
}

Bool AbiProbeBool(Bool value) {
  return AbiHostBool(value);
}
