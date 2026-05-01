#include <stdint.h>

#define CSR_ACCEL_STATUS 0xFC0

#define AES_LOAD_KEY() __asm__(".word 0x0000003b")
#define AES_ENC()   __asm__(".word 0x0000103b")
#define AES_DEC()   __asm__(".word 0x0000203b")

#define AES_SYNC() { \
	__asm__( \
		".word 0x0000403b" \
		: \
		: \
		: "t3", "t4", "t5", "t6"); \
}\

#define AES_ENC_S() { \
	__asm__( \
		".word 0x0000503b" \
		: \
		: \
		: "t3", "t4", "t5", "t6"); \
}\

#define AES_DEC_S() { \
	__asm__( \
		".word 0x0000603b" \
		: \
		: \
		: "t3", "t4", "t5", "t6"); \
}\

#define LOAD_BLOCK_TO_REGS(ptr){ \
	__asm__ volatile ( \
		"lw t3, 0(%0)\n" \
		"lw t4, 4(%0)\n" \
		"lw t5, 8(%0)\n" \
		"lw t6, 12(%0)\n" \
		: \
		: "r"(ptr)\
		: "t3", "t4", "t5", "t6", "memory"); \
}\

#define STORE_BLOCK_FROM_REGS(ptr){ \
	__asm__ volatile ( \
		"sw t3, 0(%0)\n" \
		"sw t4, 4(%0)\n" \
		"sw t5, 8(%0)\n" \
		"sw t6, 12(%0)\n" \
		: \
		: "r"(ptr)\
		: "t3", "t4", "t5", "t6", "memory"); \
}\

static inline bool ACCEL_IS_READY() {
	uint32_t status;
	__asm__ volatile (
		"csrr %0, %1"
		: "=r" (status)
		: "i" (CSR_ACCEL_STATUS)
	);
	return (status & 0x1) == 1;
}



void aes128_encrypt_block_hardware(uint8_t out[16], const uint8_t in[16]);
void aes128_decrypt_block_hardware(uint8_t out[16], const uint8_t in[16]);
void aes128_load_key(uint8_t key[16]);
