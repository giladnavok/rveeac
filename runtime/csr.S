
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
