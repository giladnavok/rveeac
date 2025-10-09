#include <stdio.h>
#include <stdint.h>
#include "csr.h"
#include "syscalls.h"

void myPrintf(int n) {
	char buf[1];
	while (n > 0) {
		buf[0] = (n % 10) + '0';
		_write(1, buf, 1);
		n /= 10;
	}
	_write(1, "\n", 1);
}
		
int main() {
	for (int i = 0; i < 1000; i++) {
		printf("%d\n", 12312312);
	}
}

