
## LUI
| Cycle\Stage | IF / ID                                          | EXE/MEM/WB                       |
| ----------- | ------------------------------------------------ | -------------------------------- |
| 2           | Forward first immediate half through WB register |                                  |
| 3           | Forward second half                              | Write back first immediate half  |
| 4           |                                                  | Write back second immediate half |
## AUIPC
| Cycle\Stage | IF / ID                                                                | EXE/MEM/WB              |
| ----------- | ---------------------------------------------------------------------- | ----------------------- |
| 2           | Compute PC + immediate.<br>Forward its first half through WB register. |                         |
| 3           | Forward second half                                                    | Write back first half   |
| 4           |                                                                        | Write back second  half |
## JAL
| Cycle\Stage | IF / ID                                                                                           | EXE/MEM/WB              |
| ----------- | ------------------------------------------------------------------------------------------------- | ----------------------- |
| 2           | Compute PC + immediate.<br>Set PC to it.<br>Forward previous PC's first half through WB register. |                         |
| 3           | Forward second half                                                                               | Write back first half   |
| 4           |                                                                                                   | Write back second  half |

## JALR
| Cycle\Stage | IF / ID                                                                                            | EXE/MEM/WB              |
| ----------- | -------------------------------------------------------------------------------------------------- | ----------------------- |
| 2           | Compute RS1 + immediate.<br>Set PC to it.<br>Forward previous PC's first half through WB register. |                         |
| 3           | Forward second half                                                                                | Write back first half   |
| 4           |                                                                                                    | Write back second  half |

## Branches

| Cycle\Stage | IF / ID                                                                                                   | EXE/MEM/WB                                                                                  |
| ----------- | --------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| 2           | Compute PC + immediate.<br>Store it.<br>Branch predict.<br>Forward RS1's first half through ALU register. |                                                                                             |
| 3           | Forward second half                                                                                       | Read RS2's first half.<br>Compare first halves of RS1's and RS2's<br>If decisive, alert IF. |
| 4           | If alerted, **act** if needed                                                                             | Compare second halves of RS1's and RS2's<br>Alert BP                                        |
| 5           | Act if needed.                                                                                            |                                                                                             |
## Loads
| Cycle\Stage | IF / ID                                                                                                                       | EXE/MEM/WB                                                                      |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| 2           | Compute load address RS1 + immediate.<br>Start APB read request with it. (HAZARD if previous instruction was a store - stall) |                                                                                 |
| 3+          | ~ free slot ~                                                                                                                 | Receive APB read response, extend it, write back first half (store second half) |
| 4           |                                                                                                                               | Write back second half                                                          |
## Stores
| Cycle\Stage | IF / ID                                                                       | EXE/MEM/WB                                                                                                                      |
| ----------- | ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| 2           | Compute store address RS1 + immediate and forward to to LSU address register. |                                                                                                                                 |
| 3           | (Lend 32 bit register file port)                                              | Read the value to be stored from the 32 bit register file port ( IF SW, otherwise the 16 bit port).<br>Start APB write request. |
| 4+          |                                                                               | Finish APB write request                                                                                                        |

## Immediate Arithmetic: ADDI, SUBI, XORI, ORI, ANDI
| Cycle\Stage | IF / ID                  | EXE/MEM/WB                                                                |
| ----------- | ------------------------ | ------------------------------------------------------------------------- |
| 2           | Forward immediate first. |                                                                           |
| 3           | Forward second half.     | Read RS1 first half.<br>Operate on first halves and write back the result |
| 4           |                          | Same for second halves                                                    |
## Immediate Arithmetic: SLTI, SLTIU
| Cycle\Stage | IF / ID                                 | EXE/MEM/WB                                                                             |
| ----------- | --------------------------------------- | -------------------------------------------------------------------------------------- |
| 2           | Forward RS1 and immediate first halves. |                                                                                        |
| 3           | Forward second halves.                  | Compare first halves.<br>Write back zeros to second half of target register.           |
| 4           |                                         | Compare second halves.<br>Write back the result to the second half of target register. |

## ==Immediate Arithmetic: SLLI==

| Cycle\Stage | IF / ID                                                                                          | EXE/MEM/WB                                                                                                           |
| ----------- | ------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------- |
| 2           | Forward RS1 and immediate first halves.<br>Zero WB register ( will be used for shift operations) |                                                                                                                      |
| 3           | Forward RS1 second half only.                                                                    | (maybe)<br>Shift left the first half, filling using the WB register, store it both in WB register and write back it. |
| 4           |                                                                                                  | Shift the second half, filling using the WB register and write back the result.                                      |
## ==Immediate Arithmetic: SRLI, SRAI==

| Cycle\Stage | IF / ID                                                                                                                                                                              | EXE/MEM/WB                                                                                                             |
| ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| 2           | Forward RS1's **second** half and immediate's first half.<br>If arithmetic fill WB register with RS1's last bit, other wise fill it with zeros. ( will be used for shift operations) |                                                                                                                        |
| 3           | Forward RS1 first half only.                                                                                                                                                         | (maybe)<br>Shift right the second half, filling using the WB register, store it both in WB register and write back it. |
| 4           |                                                                                                                                                                                      | Shift the second half, filling using the WB register and write back the result.                                        |
## Register Arithmetic: ADD, SUB, XOR, OR, AND
| Cycle\Stage | IF / ID                  | EXE/MEM/WB                                                                                |
| ----------- | ------------------------ | ----------------------------------------------------------------------------------------- |
| 2           | Forward RS1's first half |                                                                                           |
| 3           | Forward second half      | Read RS2's first half.<br>Operate on RS1 and RS2's first halves and write back the result |
| 4           |                          | Same for second halves                                                                    |
## Register Arithmetic: SLT, SLTU
| Cycle\Stage | IF / ID                  | EXE/MEM/WB                                                                                             |
| ----------- | ------------------------ | ------------------------------------------------------------------------------------------------------ |
| 2           | Forward RS1's first half |                                                                                                        |
| 3           | Forward second half      | Read RS2's first half.<br>Compare first halves.<br>Write back zeros to second half of target register. |
| 4           |                          | Compare second halves.<br>Write back the result to the second half of target register.                 |


## System
#TODO 

## Hazards
- LW - SW Hazard:

| Cycle\Stage | IF / ID                                                        | EXE/MEM/WB                                                   |
| ----------- | -------------------------------------------------------------- | ------------------------------------------------------------ |
| 2           | SW - decode step 1                                             | -                                                            |
| 3           | SW - decode step 2                                             | SW - mem step 1                                              |
| 4           | LW - decode step 1 - Needs APB DMEM Interface to request read. | SW - mem step 2 - Needs APB DMEM Interface to finish writing |

	Must stall I think.
- RaW - only where the reading command needs to read the whole register in it's first decode cycle.

| Cycle\Stage | IF / ID                                                | EXE/MEM/WB                                     |
| ----------- | ------------------------------------------------------ | ---------------------------------------------- |
| 2           | ADDI - decode step 1                                   | -                                              |
| 3           | ADDI - decode step 2                                   | ADDI - exe step 1                              |
| 4           | LW - needs full register value to calculate rs1 + imm. | ADDI - exe step 2 - still computes second half |
	Forwarding adds a full compute step to an already long combinatoric chain of LW f.e.:
	ALU computation in parallel to cs + register read + imm gen -> mux for rs1 half -> addr = rs1 + imm -> interface with APB.
	Should probably just stall then. 