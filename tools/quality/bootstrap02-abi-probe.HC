// U8* ABI probe
public I64 BootstrapAbiProbe3(U8 *src, I64 src_len, I64 start, I64 *out_end)
{
  I64 i = start;
  I64 n = src_len;
  while (i < n) {
    U8 c = src[i];
    if (c < '0') break;
    if (c > '9') break;
    i = i + 1;
  }
  *out_end = i;
  return 1;
}
