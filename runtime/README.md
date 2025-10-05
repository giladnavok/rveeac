
# Runtime (RISC-V core)

## Prerequisites

-   **Toolchain:** `riscv32-unknown-elf-gcc` with **newlib** (bare-metal)
    
-   **Host:** Linux/WSL with Bash
    
-   A Verilog simulator with the testbench `tb_core_c_program`
    

## Quick start

    # From runtime/
    ./gen_imem_dmem.sh hello.c 
    # 1) builds and splits sections  
    # outputs:  
    #   imem.hex   # instruction memory image  
    #   dmem.hex   # data memory image  
    # 2) Copy imem.hex and dmem.hex into your simulator’s run directory  
    # 3) Run the testbench: tb_core_c_program

### Example program
`hello.c`
 

    #include  <stdio.h>  
        int  main(void) { 
    	    printf("Hello from RV!\n"); // note the newline to flush stdout  return  0;
        } 

## What’s implemented (syscalls)

-   ✅ `write` to **stdout** only (file descriptor `1`)
    
-   ✅ `sbrk` (basic heap for `malloc`/`newlib`)
    
-   ⛔️ No `stdin`, `stderr`, files, or `exit` yet.
    

## How the build works

The script compiles and links with the project’s `crt0.S`, `syscalls.c`, and your C files, then splits the ELF into:

-   `.text/.rodata` → `imem.hex`
    
-   `.data/.sdata` (and zero-init `.bss` at startup) → `dmem.hex`
