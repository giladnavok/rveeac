#include <stdio.h>
#include "accel.h"

int main() {
	while (true) {
		printf("Starting encode\n");
		_ACCEL_ST_ENC();
		_ACCEL_SYNC();
		printf("Synced!\n");
	}
}
