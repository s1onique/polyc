#include <stdio.h>
#include <stdint.h>

extern long long BootstrapAbiProbe3(unsigned char *src,
                                     long long src_len,
                                     long long start,
                                     long long *out_end);

int main(void) {
  unsigned char buf[] = "12345abc";
  long long len = 8;
  long long start = 0;
  long long end = -1;
  long long ret = BootstrapAbiProbe3(buf, len, start, &end);
  printf("ret=%lld end=%lld (expected ret=1 end=5)\n", ret, end);
  printf("STATUS=%s\n", (ret == 1 && end == 5) ? "PASS" : "FAIL");
  return (ret == 1 && end == 5) ? 0 : 1;
}
