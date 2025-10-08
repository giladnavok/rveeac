
.text
.align 2

.global read_mstatus
read_mstatus:
	csrr a0, mstatus
	ret
