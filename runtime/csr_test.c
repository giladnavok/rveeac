#include <stdio.h>
#include <stdint.h>
#include "csr.h"
#include "syscalls.h"


void test1();
		
int main() {
	test1();
}
void test1() {
	for (int i = 2; i < 9999999; i*=2) {
		printf("%d: ", i-1);
		if ((i/2)-1 != read_write_mscratch(i-1)) {
			printf("F\n");
			return;
		} else {
			printf ("S\n");
		}
	}
	printf("Done\n");
}

