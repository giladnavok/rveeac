#include <stdio.h>

int main() {
	unsigned int a = 0;
	while (true) {
		a += 1;
		if ((a % 10) == 0) {
			printf(".");
		}
		if ((a % 80) == 0) {
			printf("\n");
		}
	}
}

