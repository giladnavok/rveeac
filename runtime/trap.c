#include <stdint.h>
#include <stdio.h>

#define MCAUSE_INT (1u<<31)
#define MCAUSE_CODE(x) ((x) & 0x7fffffff)
#define MCAUSE_MEI (11u)
#define MCAUSE_AES (16u)

uintptr_t trap_handler(uintptr_t mcause, uintptr_t mepc, uintptr_t mstatus) {
	if (mcause & MCAUSE_INT) {
		uint32_t code = MCAUSE_CODE(mcause);
		if (code == MCAUSE_MEI) {
			printf("MEI interrupt! \n");
			return mepc;
		}
		return mepc;
	} else { // For exeptions, not implemented 
		return mepc + 4;
	}
}
		




