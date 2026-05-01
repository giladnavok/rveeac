# RVEEAC: RISC-V with Embedded Encryption Accelerator

A low-power RISC-V processor designed for IoT and edge computing devices, featuring a tightly coupled, hardware-accelerated AES-128 engine. 

This project explores micro-architectural optimizations for area and power efficiency by implementing a custom staggered 16-bit internal datapath to hide the latency of a low-cost, 2-cycle AMBA APB memory interface.

## Core Features & Architecture

* **Instruction Set:** Implements the unprivileged `RV32I_Zicsr` ISA with Machine-mode CSRs and interrupts, extended with custom cryptographic instructions.
* **Pipeline Design:** An in-order, three-stage pipeline (Instruction Fetch, Instruction Decode, Execution) featuring non-uniform stage lengths. 
* **16-bit Micro-architecture:** To optimize area and power, the core utilizes 16-bit internal data paths and a 16-bit ALU. 
* **Staggered Execution:** Instructions are processed in 16-bit halves across overlapping execution cycles to maintain instruction throughput and hide memory latency.
* **Memory Interface:** Optimized around a low-cost AMBA APB interface where every memory transfer takes a minimum of two cycles. This allows resource sharing, such as multiplexing IMEM and DMEM traffic on a single memory component.
* **Hazard Resolution:** Utilizes half-word forwarding for arithmetic Read-After-Write hazards and injects hardware stalls for 2-cycle Load-Use dependencies.

## Embedded AES-128 Accelerator

The cryptographic accelerator implements the AES-128 block cipher (128-bit key, 10 rounds) and is tightly coupled directly into the core's Execution stage. 

* **Zero-Overhead Interface:** Eliminates bus communication overhead by utilizing General Purpose Registers `x28-x31` as the shared memory space for plaintext, ciphertext, and keys.
* **Parallel Execution ("Swap-on-Start"):** When an encryption/decryption instruction is issued, the accelerator atomically swaps the contents of `x28-x31` with its internal buffers. This allows the CPU to load the next block of data while the accelerator processes the current block in the background.
* **Flexible Synchronization:** Supports multiple synchronization methods depending on the software scenario, including Polling, hardware "Stall-on-Busy" Waiting, and Asynchronous Interrupts for long-running operations.

## Custom Cryptographic Extension (ISA)

To control the accelerator, the processor supports the following custom machine instructions:

| Mnemonic | Description | Behavior |
| :--- | :--- | :--- |
| `AES_LOAD_KEY` | Key Load | Loads `x28-x31` to the internal key register. Stalls if the accelerator is busy. |
| `AES_ENC` | Encrypt Block | Copies `x28-x31` to the internal buffer and starts encryption. |
| `AES_DEC` | Decrypt Block | Copies `x28-x31` to the internal buffer and starts decryption. |
| `AES_SYNC` | Sync & Retrieve | Stalls the processor until the accelerator is idle. Copies the accelerator's output buffer into `x28-x31`. |
| `AES_ENC_S` | Swap & Encrypt | Stalls until idle, swaps `x28-x31` with the internal buffer, and starts encryption. |
| `AES_DEC_S` | Swap & Decrypt | Stalls until idle, swaps `x28-x31` with the internal buffer, and starts decryption. |

## Verification Methodology

The core and accelerator were verified using a hybrid bottom-up and top-down approach:

* **Module-Level Fuzzing:** The ALU and critical combinational logic were verified using a constrained-random fuzzer in SystemVerilog, checking 200,000+ iterations against a behavioral model.
* **Directed Pipeline Verification:** Directed SystemVerilog testbenches validated pipeline hazard resolution (RAW dependencies, Load-Use stalls) and branch prediction flushing.
* **System-Level Software Verification:** Compiled C programs validated standard runtime execution, CSR atomic operations, and AES correctness. The memory models injected random wait states (IMEM/DMEM delays) to ensure robust pipeline stalling and resumption.

## Repository Structure
```text
├── HEA/                        # Hardware Encryption Accelerator
│   ├── screenshots/            # Waveforms and architectural diagrams
│   ├── src/                    # AES-128 SystemVerilog sources
│   └── tb/                     # AES module-level testbenches & Python models
├── runtime/                    # Software & Execution Environment
│   ├── accel.h / accel.c       # C-library for AES custom instructions
│   ├── crt0.S / trap.S         # Startup code and low-level trap handlers
│   ├── linker.ld               # Linker script for RISC-V memory mapping
│   ├── test_*.c                # System-level C tests (AES, CSR, Interrupts)
│   └── tb_core_c_program.sv    # Testbench for running compiled C code on the core
├── test/                       # Core SystemVerilog Testbenches
│   ├── tb_core.sv              # Top-level pipeline and hazard verification
│   ├── tb_alu_sbm.sv           # ALU constrained-random fuzzer
│   └── tb_*.sv                 # Module-level unit tests for IF, ID, and CSR
├── doc/                        # Documentation and .drawio source files
├── resources/                  # Architecture specs and ISA documentation
├── core.sv                     # Top-level RISC-V processor wrapper
├── fetch_unit.sv               # IF Stage: APB controller & prefetch buffer
├── decode_unit.sv              # ID Stage: Decoder & hazard logic
├── exe_mem_wb_stage.sv         # EXE Stage: ALU, LSU, and Accel Integration
├── alu_sbm.sv                  # Arithmetic Logic Unit
├── csr_sbm.sv                  # Control and Status Registers (M-mode)
├── interrupt_sbm.sv            # Interrupt controller
├── regfile_sbm.sv              # Register File (16-bit split-write ports)
├── load_store_unit.sv          # Data Memory APB interface
├── typedefs.sv                 # Global SystemVerilog type definitions
└── README.md
```
