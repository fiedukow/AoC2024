#include <stdbool.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

bool ret(long a) {
  long initiala = a;
  int expected[] = {2,4,1,3,7,5,4,1,1,3,0,3,5,5,3,0};
  // int expected[] = {0,3,5,4,3,0};

  int expected_count = 16;
  // int expected_count = 6;

  long  b = 0, c = 0;
  
  int i = 0;

  while (a > 0 && i < expected_count) {
    b = a % 8; // 2 4
    b = b ^ 3; // 1 3
    c = a / (1 << b); // 7 5
    b = b ^ c; // 4 1
    b = b ^ 3; // 1 3
    a = a / 8; // 0 3
    if (i >= 11) { printf("mached %d in %ld\n", i, initiala); }
    if ((b % 8) != expected[i]) { return false; } // 5 5
    ++i;
  } // 3 0

  return a == 0 && i == expected_count;
}

long scan(long at, long interval) {
  for (long i = 0; i < LONG_MAX; ++i) {
    long actual_i = at + interval * i;
    // if (i % 1000000 == 0) { printf("%ld\n", actual_i); }
    if (ret(actual_i)) return actual_i;
  }
  return -1;
}

int main(int argc, char *argv[]) {
  if (argc != 3) {
    printf("Usage: %s <int1> <int2>\n", argv[0]);
    return 1;
  }

  long at = strtol(argv[1], NULL, 10);
  long jump = strtol(argv[2], NULL, 10);

  printf("%ld", scan(at, jump));
}