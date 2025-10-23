#include <stdint.h>

#define _ACCEL_LOAD_KEY() __asm__(".word 0x0000003b")
#define _ACCEL_ST_ENC()   __asm__(".word 0x0000103b")
#define _ACCEL_ST_DEC()   __asm__(".word 0x0000203b")

#define _ACCEL_SYNC() { \
	__asm__( \
		".word 0x0000403b" \
		: \
		: \
		: "t3", "t4", "t5", "t6"); \
}\

#define _LOAD_BLOCK_TO_REGS(ptr){ \
	__asm__ volatile ( \
		"lw t3, 0(%0)\n" \
		"lw t4, 4(%0)\n" \
		"lw t5, 8(%0)\n" \
		"lw t6, 12(%0)\n" \
		: \
		: "r"(ptr)\
		: "t3", "t4", "t5", "t6", "memory"); \
}\

#define _STORE_BLOCK_FROM_REGS(ptr){ \
	__asm__ volatile ( \
		"sw t3, 0(%0)\n" \
		"sw t4, 4(%0)\n" \
		"sw t5, 8(%0)\n" \
		"sw t6, 12(%0)\n" \
		: \
		: "r"(ptr)\
		: "t3", "t4", "t5", "t6", "memory"); \
}\



void aes128_encrypt_block_hardware(uint8_t out[16], const uint8_t in[16]);
void aes128_decrypt_block_hardware(uint8_t out[16], const uint8_t in[16]);
void aes128_load_key(uint8_t key[16]);
