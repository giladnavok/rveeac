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
	} cs_inst_type;

	//! update sizes..

	typedef enum logic [2:0] {
		PC_SEL_INC,
		PC_SEL_JMP
	} cs_pc_sel;

	typedef enum logic [2:0] {
		WB_SEL_ALU,
		WB_SEL_LSU,
		WB_SEL_WB
	} cs_wb_sel;

	typedef enum logic [1:0] {
		SIZE_W,
		SIZE_H,
		SIZE_B,
		SIZE_BIT
	} cs_size;

	typedef enum logic {
		EXT_Z,
		EXT_S
	} cs_ext;

	typedef enum logic [1:0] {
		WB_NO_FILL,
		WB_FILL_ZEROS,
		WB_FILL_ONES
	} cs_wb_fill;

	typedef enum logic [2:0] {
		EXT_SEL_W,
		EXT_SEL_SH,
		EXT_SEL_UH,
		EXT_SEL_SB,
		EXT_SEL_UB
	} cs_ext_sel;

	typedef enum logic [1:0] {
		U_EXT_SEL_W,
		U_EXT_SEL_H,
		U_EXT_SEL_B
	} cs_uext_sel;

	typedef enum logic [4:0] {
		ALU_OP_ADD,
		ALU_OP_SUB,
		ALU_OP_AND,
		ALU_OP_OR,
		ALU_OP_XOR,
		ALU_OP_SLL,
		ALU_OP_SRL,
		ALU_OP_SRA,
		ALU_OP_EQ,
		ALU_OP_LT,
		ALU_OP_LTU,
		ALU_OP_PLUS_4
	} cs_alu_op;

	typedef enum logic [1:0] {
		ALU_WB_SEL_IMM,
		ALU_WB_SEL_REG,
		ALU_WB_SEL_PC,
		ALU_WB_SEL_ADDER
	} cs_alu_wb_sel;

	typedef enum logic [2:0] {
		CMP_OUT_SEL_EQ,
		CMP_OUT_SEL_LT,
		CMP_OUT_SEL_LTU
	} cs_alu_b_sel;

	typedef enum logic {
		SER_START_LH = 1'b0,
		SER_START_UH = 1'b1
	} cs_ser_start;

	typedef enum logic [2:0] {
		DEC_ADD_SEL_PC,
		DEC_ADD_SEL_REG
	} cs_dec_add_sel;

	typedef struct packed {
		logic pff_lsu_addr_en;
		logic pff_alu_b_en;
		logic pff_cs_exe_en;
	} cs_pff_s;

	typedef struct packed {
		cs_inst_type inst_type;
		cs_alu_wb_sel alu_wb_sel;
		cs_dec_add_sel add_sel;
		cs_ser_start ser_start;
		cs_size dmem_load_size;
		cs_ext dmem_load_ext;
	} cs_dec_sel_s;

	typedef struct packed {
		logic lsu_addr;
		logic alu_b;
		logic wb;
		logic cs_exe;
		logic reg32_use;
		logic dmem_load_bypass;
		logic jmp;
		logic branch;
		logic forward_just_one_half;
	} cs_dec_en_s;

	typedef struct packed {
		cs_dec_sel_s sel;
		cs_dec_en_s en;
	} cs_dec_s;

	typedef struct packed {
		cs_alu_op alu_op;
		cs_wb_sel wb;
		cs_size wb_store_size;
		cs_ext wb_ext;
	} cs_exe_sel_s;

	typedef struct packed {
		logic rf_write;
		logic dmem_store;
		logic cmp_req;
		logic cmp_flip;
		logic wb_order_flip;
		logic reg16_use;
		logic rs16_half_order_flip;
		logic accel_start_enc;
		logic accel_start_dec;
		logic accel_load_key;
	} cs_exe_en_s;

	typedef struct packed {
		cs_exe_sel_s sel;
		cs_exe_en_s en;
	} cs_exe_s;

	typedef struct packed {
		cs_dec_s dec;
		cs_exe_s exe;
	} cs_s;


	//typedef logic [31:0] xlen;
	//
	
	typedef enum logic [6:0] {
		OPC_LOAD = 7'b00_000_11,
		OPC_STORE = 7'b01_000_11,
		OPC_OP_IMM = 7'b00_100_11,
		OPC_OP_REG = 7'b01_100_11,
		OPC_JAL = 7'b11_011_11,
		OPC_JALR = 7'b11_001_11,
		OPC_BRANCH = 7'b11_000_11,
		OPC_AUIPC = 7'b00_101_11,
		OPC_LUI = 7'b01_101_11,
		OPC_SYSTEM = 7'b11_100_11,
		OPC_FENCE = 7'b00_011_11,
		OPC_ACCEL = 7'b01_110_11
	} opcode_e;

	typedef enum logic [2:0] {
		FNC3_LB = 3'b000,
		FNC3_LH = 3'b001,
		FNC3_LW = 3'b010,
		FNC3_LBU = 3'b100,
		FNC3_LHU = 3'b101
	} funct3_load_e;

	typedef enum logic [2:0] {
		FNC3_SB = 3'b000,
		FNC3_SH = 3'b001,
		FNC3_SW = 3'b010
	} funct3_store_e;


	typedef enum logic [2:0] {
		FNC3_BEQ = 3'b000,
		FNC3_BNE = 3'b001,
		FNC3_BLT = 3'b100,
		FNC3_BGE = 3'b101,
		FNC3_BLTU = 3'b110,
		FNC3_BGEU = 3'b111
	} funct3_branch_e;

	typedef enum logic [2:0] {
		FNC3_OP_ADD = 3'b000,
		FNC3_OP_SLT = 3'b010,
		FNC3_OP_SLTU = 3'b011,
		FNC3_OP_XOR = 3'b100,
		FNC3_OP_OR = 3'b110,
		FNC3_OP_AND = 3'b111,
		FNC3_OP_SLL = 3'b001,
		FNC3_OP_SRL_SRA = 3'b101
	} funct3_operation_e;

	typedef enum logic [2:0] {
		FNC3_LD_KEY = 3'b000,
		FNC3_ST_ENC = 3'b001,
		FNC3_ST_DEC = 3'b010
	} funct3_accel_e;

//	typedef enum logic [2:0] {
//		FNC3_JALR = 3'b000,
//		FNC3_FENCE = 3'b000,
//		FNC3_SYSTEM = 3'b000
//	} Funct3Other;

	typedef logic [2:0] funct3_t;
	typedef logic [6:0] funct7_t;

	localparam ENABLE = 1'b1;
	localparam DISABLE = 1'b0;

	parameter cs_dec_en_s 
	CS_DEC_EN_DEFAULT = '{
			lsu_addr: DISABLE,
			alu_b: DISABLE,
			wb: DISABLE,
			reg32_use: DISABLE,
			cs_exe: ENABLE,
			dmem_load_bypass: DISABLE,
			jmp: DISABLE,
			branch: DISABLE,
			forward_just_one_half: DISABLE
		};
	parameter cs_exe_en_s 
	CS_EXE_EN_DEFAULT = '{
			rf_write: DISABLE,
			dmem_store: DISABLE,
			cmp_req: DISABLE,
			cmp_flip: DISABLE,
			wb_order_flip: DISABLE,
			reg16_use: DISABLE,
			rs16_half_order_flip: DISABLE,
			accel_start_enc: DISABLE,
			accel_start_dec: DISABLE,
			accel_load_key: DISABLE
		};
endpackage

interface apb_if;
	logic sel;
	logic enable;
	logic write;
	logic [31:0] addr;
	logic [31:0] wdata;
	logic [3:0] strb;

	logic ready;
	logic slverr;
	logic [31:0] rdata;

	modport master (
		input ready, slverr, rdata,
		output sel, enable, write, addr, wdata, strb
	);

	modport slave (
		input sel, enable, write, addr, wdata, strb,
		output ready, slverr, rdata
	);
endinterface

//interface apb_if #(parameter DAT_W = 32, parameter ADDR_W = 32);
//	logic sel;
//	logic enable;
//	logic write;
//	logic [ADDR_W - 1: 0 ] addr;
//	logic [DAT_W - 1 : 0] wdata;
//	logic [DAT_W/8 - 1 : 0] strb;
//
//	logic ready;
//	logic slverr;
//	logic [DAT_W - 1 : 0] rdata;
//
//	modport master (
//		input ready, slverr, rdata,
//		output sel, enable, write, addr, wdata, strb
//	);
//
//	modport slave (
//		input sel, enable, write, addr, wdata, strb,
//		output ready, slverr, rdata
//	);
//endinterface




`endif
