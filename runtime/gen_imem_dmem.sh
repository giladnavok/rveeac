
FILENAME=$1

CROSS=riscv32-unknown-elf

$CROSS-gcc -march=rv32i_zicsr -mabi=ilp32 -ffreestanding \
  -nostartfiles -ffunction-sections -fdata-sections \
  -Wl,-T,linker.ld -Wl,--gc-sections -Wl,-Map=hello.map \
  -specs=nano.specs \
  csr.S trap.S crt0.S syscalls.c trap.c accel.c aes_software.c $FILENAME -o hello.elf -lgcc -lc

riscv64-unknown-elf-objcopy -O binary \
  --only-section .init --only-section .text \
  --change-addresses -0x00000000 --gap-fill 0x00 \
  hello.elf imem.bin


riscv64-unknown-elf-objcopy -O binary \
  --only-section .rodata --only-section .srodata \
  --only-section .data --only-section .sdata \
  --change-addresses -0x00020000 --gap-fill 0x00 \
  hello.elf dmem.bin

truncate -s 128K imem.bin
truncate -s 128K dmem.bin

hexdump -v -e '1/4 "%08x\n"' imem.bin > imem.hex
hexdump -v -e '1/1 "%02x\n"' dmem.bin > dmem.hex

riscv32-unknown-elf-objdump -d hello.elf > tmp
