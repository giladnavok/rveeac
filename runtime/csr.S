
.text
.align 2

.global read_mscratch
read_mscratch:
	csrr a0, mscratch
	ret

.global read_write_mscratch
read_write_mscratch:
	csrrw a0, mscratch, a0
	ret

.global read_set_mscratch
read_set_mscratch:
	csrrs a0, mscratch, a0
	ret
