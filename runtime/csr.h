#include <stdint.h>

uint32_t read_mscratch(void);
void write_mscratch(uint32_t);
uint32_t read_write_mscratch(uint32_t);
uint32_t read_set_mscratch(uint32_t);
uint32_t read_clear_mscratch(uint32_t);

uint32_t read_write_imm_mscratch();
uint32_t read_set_imm_mscratch();
uint32_t read_clear_imm_mscratch();

uint32_t test_sequential_csr();



