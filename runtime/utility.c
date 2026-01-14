#include <stdio.h>
#include "utility.h"
bool test_equal(uint8_t a[16], uint8_t b[16]) {
	for (int i = 0; i < 16; i++) {
		if (a[i] != b[i]) return false;
	}
	return true;
}

void print_chars(uint8_t a[16]) {
	for (int i = 0; i < 16; i++) {
		printf("%02x",(unsigned int)a[i]); 
	}
	printf("\n");
}


