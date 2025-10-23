#include <stdint.h>
#include "accel.h"

void aes128_encrypt_block_hardware(uint8_t out[16], const uint8_t in[16]) {
	_LOAD_BLOCK_TO_REGS(in);
	_ACCEL_ST_ENC();
	_ACCEL_SYNC();
	_STORE_BLOCK_FROM_REGS(out);
}

void aes128_decrypt_block_hardware(uint8_t out[16], const uint8_t in[16]) {
	_LOAD_BLOCK_TO_REGS(in);
	_ACCEL_ST_DEC();
	_ACCEL_SYNC();
	_STORE_BLOCK_FROM_REGS(out);
}

void aes128_load_key(uint8_t key[16]) {
	_LOAD_BLOCK_TO_REGS(key);
	_ACCEL_LOAD_KEY();
}
