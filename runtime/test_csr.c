#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "csr.h"
#include "syscalls.h"

const int N = 999999;

void reset();
void test1();
void test2();
void test3();
void test4();
void test5();
		
int main() {
	test1();
	reset();
	test2();
	reset();
	test3();
	reset();
	test4();
	reset();
	test5();
	reset();
}

void reset() {
	write_mscratch(0);
	assert(read_mscratch()==0);
}

void test1() {
	for (int i = 2; i < N; i*=2) {
		assert(((i/2)-1) == read_write_mscratch(i-1));
		printf(".");
	}
	printf(" Done 1\n");
}

void test2() {
	uint32_t t = 0;
	for (int i = 1; i < N; i*=2) {
		assert(t==read_set_mscratch(i));
		t |= i;
		printf(".");
	}
	printf(" Done 2\n");
}

void test3() {
	for (int i = 1; i < N; i*=2) {
		assert(read_set_mscratch(i) == 0);
		assert(read_clear_mscratch(i) == i);
		printf(".");
	}
	printf(" Done 3\n");
}

void test4() {
	assert(read_write_imm_mscratch() == 0);
	assert(read_write_mscratch(0) == 15);

	assert(read_set_imm_mscratch() == 0);
	assert(read_write_mscratch(0) == 15);

	assert(read_clear_imm_mscratch() == 0);
	assert(read_write_mscratch(0) == 0);

	assert(read_set_imm_mscratch() == 0);
	assert(read_clear_imm_mscratch() == 15);
	assert(read_clear_imm_mscratch() == (15 & (~9)));
	assert(read_clear_imm_mscratch() == (15 & (~9)));
	assert(read_clear_imm_mscratch() == (15 & (~9)));
	assert(read_set_imm_mscratch() == (15 & (~9)));
	assert(read_write_mscratch(0xff) == 15);
	assert(read_clear_imm_mscratch() == 0xff);
	assert(read_mscratch() == (0xff & (~9)));
	printf(" Done 4\n");
}

void test5() {
	assert(test_sequential_csr() == 4);
	printf(" Done 5\n");
}
