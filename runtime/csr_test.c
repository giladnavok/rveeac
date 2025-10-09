#include <stdio.h>
#include <stdint.h>
#include "csr.h"
#include "syscalls.h"


void test1();
void test2();
		
int main() {
	test2();
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

void test2() {
	uint32_t t = 0;
	for (int i = 1; i < 9999999; i*=2) {
		printf("%d: ", i);
		uint32_t read = read_set_mscratch(i);
		printf("Read: %d, %d\n", read, t);
		if (t != read) {
			printf("F\n");
			return;
		} else {
			printf ("S\n");
		}
		t |= i;
	}
	printf("Done2\n");
}
