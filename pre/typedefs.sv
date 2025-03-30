`ifndef TYPEDEFS_SV
`define TYPEDEFS_SV

package typedefs;
	typedef enum logic [2:0] {
		INST_TYPE_R,
		INST_TYPE_I,
		INST_TYPE_S,
		INST_TYPE_B,
		INST_TYPE_U,
		INST_TYPE_J
	} InstructionType;

	//! update sizes..
	typedef enum logic [2:0] {
		ALU_A_SEL_REG,
		ALU_A_SEL_PC
	} ALUASelector;

	typedef enum logic [2:0] {
		ALU_B_SEL_REG,
		ALU_B_SEL_IMM
	} ALUBSelector;

	typedef enum logic [2:0] {
		PC_SEL_INC,
		PC_SEL_JMP,
		PC_SEL_BR
	} PCSelector;

	typedef enum logic [2:0] {
		RF_WR_SEL_DMEM,
		RF_WR_SEL_IMM,
		RF_WR_SEL_ALU,
		RF_WR_SEL_PC_INC,
		RF_WR_SEL_U_LT,
		RF_WR_SEL_S_LT
	} RegfileWriteSelector;

	typedef enum logic [1:0] {
		RF_WR_SIZE_BIT,
		RF_WR_SIZE_B,
		RF_WR_SIZE_H,
		RF_WR_SIZE_W
	} RegfileWriteSize;

	typedef enum logic {
		RF_WR_Z_EXT,
		RF_WR_S_EXT
	} RegfileWriteExtend;

	typedef enum logic [2:0] {
		EXT_SEL_SB,
		EXT_SEL_UB,
		EXT_SEL_SH,
		EXT_SEL_UH,
		EXT_SEL_W
	} ExtenderSelector;

	typedef enum logic [1:0] {
		U_EXT_SEL_B,
		U_EXT_SEL_H,
		U_EXT_SEL_W
	} UnsignedExtenderSelector;

	typedef enum logic [2:0] {
		ALU_ADD = 3'b000,
		ALU_SUB = 3'b001,
		ALU_AND,
		ALU_OR,
		ALU_XOR,
		ALU_SLL,
		ALU_SRL,
		ALU_SRA

	} ALUOperation;

	typedef enum logic [2:0] {
		CMP_IN_SEL_RA_RB,
		CMP_IN_SEL_RA_IMM
	} ComparerInputSelector;

	typedef enum logic [2:0] {
		CMP_OUT_SEL_EQ,
		CMP_OUT_SEL_LT,
		CMP_OUT_SEL_LTU
	} ComparerOutputSelector;
endpackage

`endif
