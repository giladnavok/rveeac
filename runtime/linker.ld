OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
  IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 128K
  DMEM (rw) : ORIGIN = 0x00020000, LENGTH = 128K
}

SECTIONS {
  /* ---- IMEM ---- */
  . = ORIGIN(IMEM);
  .init : { KEEP(*(.init)) } > IMEM

  .text : ALIGN(4) {
    *(.text.startup*)
    *(.text*)
  } > IMEM
  __text_end__ = .;

  /* ---- DMEM ---- */
 	. = ORIGIN(DMEM);

	.rodata : AT(ADDR(.rodata)) ALIGN(4) {
	  __rodata_start__ = .;
	  *(.rodata*) *(.srodata*)
	  __rodata_end__ = .;
	} > DMEM
  /* For your TB, LMA == VMA so no runtime copy needed */
  .data : ALIGN(4) {
    __data_start__ = .;
    *(.data*)
    *(.sdata*)
    __data_end__ = .;
  } > DMEM
  __data_load__ = LOADADDR(.data);
  __data_size__ = SIZEOF(.data);

  .bss (NOLOAD) : ALIGN(4) {
    __bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(COMMON)
    _end = .;
  } > DMEM
  __bss_size__ = SIZEOF(.bss);

  .heap (NOLOAD) : ALIGN(4) {
	  __heap_start__ = .;
	  . = . + 0x4000;
	  __heap_end__ = .;
  } > DMEM

  .stack (NOLOAD) : {
    . = ORIGIN(DMEM) + LENGTH(DMEM);
    __stack_top__ = .;
  } > DMEM

  PROVIDE(__global_pointer$ = __data_start__ + 0x800);
}

