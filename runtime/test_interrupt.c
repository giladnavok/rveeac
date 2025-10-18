#include <stdio.h>
#include "trap.h"

int main() {
	unsigned int a = 0;
	while (true) {
		_DISABLE_INTERRUPTS();
		a += 1;
		if ((a % 10) == 0) {
			printf(".");
		}
		if ((a % 80) == 0) {
			printf("\n");
			_ENABLE_INTERRUPTS();
		}
	}
}

