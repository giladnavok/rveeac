
.text
.align 2

.global read_mscratch
read_mscratch:
	csrr a0, mscratch
	ret

.global write_mscratch
write_mscratch:
	csrw mscratch, a0
	ret

.global read_write_mscratch
read_write_mscratch:
	csrrw a0, mscratch, a0
	ret

.global read_set_mscratch
read_set_mscratch:
	csrrs a0, mscratch, a0
	ret

.global read_clear_mscratch
read_clear_mscratch:
	csrrc a0, mscratch, a0
	ret

.global read_write_imm_mscratch
read_write_imm_mscratch:
	csrrwi a0, mscratch, 15
	ret

.global read_set_imm_mscratch
read_set_imm_mscratch:
	csrrsi a0, mscratch, 15
	ret

.global read_clear_imm_mscratch
read_clear_imm_mscratch:
	csrrci a0, mscratch, 9
	ret

.global test_sequential_csr
test_sequential_csr:
	addi t0, t0, 2
	mv a0, x0
T1:
	csrw mscratch, t0
	csrr t1, mscratch
	bne t0, t1, T2
	addi a0, a0, 1
T2:
	csrw mscratch, x0
	csrsi mscratch, 1
	csrr t0, mscratch

	addi t1, x0, 1
	bne t0, t1, T3
	addi a0, a0, 1
T3:
	csrw mscratch, x0
	csrsi mscratch, 1
	csrsi mscratch, 2
	csrsi mscratch, 4
	csrsi mscratch, 8
	csrsi mscratch, 16
	csrr t0, mscratch

	addi t1, x0, 31
	bne t0, t1, T4
	addi a0, a0, 1
T4:
	csrw mscratch, x0
	csrsi mscratch, 1
	csrci mscratch, 1
	csrsi mscratch, 2
	csrci mscratch, 2
	csrsi mscratch, 4
	csrci mscratch, 4
	csrsi mscratch, 8
	csrci mscratch, 8
	csrsi mscratch, 16
	csrci mscratch, 16
	csrr t0, mscratch

	bne t0, x0, T5
	addi a0, a0, 1
T5:

	ret

