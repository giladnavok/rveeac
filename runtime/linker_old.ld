OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
	IMEM(rx) : ORIGIN = 0x0, LENGTH = 16K
	DMEM(rx) : ORIGIN = 0x4000, LENGTH = 16K
}

SECTIONS {
	. = ORIGIN(IMEM);
	.init : {
		KEEP(*(.init))
	} > IMEM

	.text : {
		*(.text.startup*)
		*(.text*)
		*(.rodata*)
		*(.srodata*)
	} > IMEM

	. = ORIGIN(DMEM);
	.data : {
		__data_start__ = .;
		*(.data*)
		*(.sdata*)
		__data_end__ = .;
	} > DMEM

	__data_load__ = LOADADDR(.data);
	__data_size__ = SIZEOF(.data);

	.bss (NOLOAD) : {
		__bss_start__ = .;
		*(.bss*)
		*(.sbss*)
		*(COMMON)
		__bss_end__ = .;
	} > DMEM

	__bss_size__ = SIZEOF(.bss);

	.heap (NOLOAD) : {
		__bss_start__ = .;
		. = . + 0x4000;
		__bss_end__ = .;
	} > DMEM

	.stack (NOLOAD) : {
		. = ORIGIN(DMEM) + LENGTH(DMEM);
		__stack_top__ = .;
	} > DMEM

	PROVIDE(__global_pointer$ = __data_start__ + 0x800);
}



	

