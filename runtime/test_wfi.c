#include <stdio.h>
#include "trap.h"

int main() {
	while(true) {
		printf("Waiting for interrupt!\n");
		_WAIT_FOR_INTERRUPT();
	}
}
