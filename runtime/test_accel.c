#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "accel.h"
#include "aes_software.h"


uint8_t key[16] = { 0x2b,0x7e,0x15,0x16,0x28,0xae,0xd2,0xa6,0xab,0xf7,0x15,0x88,0x09,0xcf,0x4f,0x3c };
uint8_t pt [16] = { 0x32,0x43,0xf6,0xa8,0x88,0x5a,0x30,0x8d,0x31,0x31,0x98,0xa2,0xe0,0x37,0x07,0x11 };
uint8_t ct_software[16];
uint8_t ct_hardware[16];
uint8_t pt_recon_software [16];
uint8_t pt_recon_hardware [16];

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

int main() {
	printf("%s\n", pt);
	aes128_load_key(key);

	for (int i = 0; i<12; i++) {
		pt[0] += i;

		if ((i % 3) == 0) {
			key[0] += i;
			aes128_load_key(key);
		}

		aes128_encrypt_block_hardware(ct_hardware, pt);
		aes128_encrypt_block_software(ct_software, pt, key);

		assert(test_equal(ct_hardware, ct_software));

		aes128_decrypt_block_hardware(pt_recon_hardware, ct_hardware);
		aes128_decrypt_block_software(pt_recon_software, ct_software, key);

		assert(test_equal(pt_recon_hardware, pt_recon_software));
	}

	printf("passed\n");
}
