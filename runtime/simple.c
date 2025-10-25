
#include <stdint.h>
#include <stdio.h>
#include <reent.h>
#include <stdlib.h>
#include <string.h>
#include "syscalls.h"

const int A[] = {1, 2, 3, 4};
int B[] = {1, 2, 3, 4};
int C[] = {0, 0, 0, 0};

int mul(int a, int b) {
	if (b<0) {
		b = -b;
		a = -a;
	}
	int res = 0;
	while (b --> 0) {
		res += a;
	}
	return res;
}

volatile char* SIM_UART_TX_TEST= (char*)0x10000000;

static int must_be_zero;

int f() {
	return 10;
}

int test() {
	int res = 0;
	int C[] = {10, 11, 12, 13};
	for (int i = 0; i < 4; i++) {
		C[i] = A[i];
		B[i] = mul(B[i], B[i]);
	}

	res += (B[0] == 1);
	res += (B[1] == 4);
	res += (B[2] == 9);
	res += (B[3] == 16);
	res += (C[0] == 1);
	res += (C[1] == 2);
	res += (C[2] == 3);
	res += (C[3] == 4);

	printf((res == 8)? "SUCCESS\n" : "FAILED\n");
}


		
	

char* non_const_global = "non const global\n";
int main() {
	char local[] = "local\n";
	printf("const string\n");
	printf(non_const_global);
	printf(local);
	printf("Number: %d\n", 5);
	char *s = malloc(32);
	strcpy(s, "heap\n");
	printf(s);
	test();
	while (1) {};
}

