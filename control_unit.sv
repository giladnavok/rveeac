import typedefs::*;

module control_unit (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,
	input logic first_cycle,

	// Input Data //
	// ---------- //
	logic [6:0] opcode_i,
	input logic [2:0] funct3_i,
	input logic [6:0] funct7_i,

	input cs_exe_sel_s exe_sel_d_i,

	// Output Controls //
	// --------------- //
	output cs_s cs_o
);

cs_dec_sel_s dec_sel_d;
always_ff @(negedge first_cycle or negedge rst_n) begin
	if (!rst_n) begin
		dec_sel_d <= '0;
	end else begin
		dec_sel_d <= cs_o.dec.sel;
	end
end
		
always_comb begin
	cs_o.dec.sel = dec_sel_d;
	cs_o.dec.en = CS_DEC_EN_DEFAULT;
	cs_o.exe.sel = exe_sel_d_i;
	cs_o.exe.en = CS_EXE_EN_DEFAULT;

	case (opcode_e'(opcode_i))
		OPC_LUI: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_U;
			cs_o.dec.sel.alu_wb_sel = ALU_WB_SEL_IMM;
			// Enable //
			cs_o.dec.en.wb = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.wb = WB_SEL_WB;
			cs_o.exe.sel.wb_store_size = SIZE_W;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;
		end
		OPC_AUIPC: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_U;
			cs_o.dec.sel.alu_wb_sel = ALU_WB_SEL_IMM;
			// Enable //
			cs_o.dec.en.alu_a = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.alu_op = ALU_OP_ADD;
			cs_o.exe.sel.wb = WB_SEL_ALU;
			cs_o.exe.sel.wb_store_size = SIZE_W;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;
		end
		OPC_JAL: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_J;
			cs_o.dec.sel.add_sel = DEC_ADD_SEL_PC;
			cs_o.dec.sel.alu_wb_sel = ALU_WB_SEL_PC;
			// Enable //
			cs_o.dec.en.alu_a = ENABLE;
			cs_o.dec.en.jmp = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.alu_op = ALU_OP_PLUS_4;
			cs_o.exe.sel.wb = WB_SEL_ALU;
			cs_o.exe.sel.wb_store_size = SIZE_W;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;
		end
		OPC_JALR: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_I;
			cs_o.dec.sel.add_sel = DEC_ADD_SEL_REG;
			cs_o.dec.sel.alu_wb_sel = ALU_WB_SEL_PC;
			// Enable //
			cs_o.dec.en.wb = ENABLE;
			cs_o.dec.en.jmp = ENABLE;
			cs_o.dec.en.reg_use = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.alu_op = ALU_OP_PLUS_4;
			cs_o.exe.sel.wb = WB_SEL_ALU;
			cs_o.exe.sel.wb_store_size = SIZE_W;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;
		end

		OPC_BRANCH: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_B;
			cs_o.dec.sel.alu_wb_sel = ALU_WB_SEL_REG;
			// Enable //
			cs_o.dec.en.alu_a = ENABLE;
			cs_o.dec.en.reg_use = ENABLE;
			cs_o.dec.en.branch = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.en.cmp_flip = funct3_i[0];
			case (funct3_branch_e'(funct3_i))
				FNC3_BEQ, FNC3_BNE: begin
					cs_o.exe.sel.alu_op = ALU_OP_EQ;
				end
				FNC3_BLT, FNC3_BGE: begin
					cs_o.exe.sel.alu_op = ALU_OP_LT;
				end
				FNC3_BLTU, FNC3_BGEU: begin
					cs_o.exe.sel.alu_op = ALU_OP_LTU;
				end
			endcase
		end

		OPC_LOAD: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_I;
			cs_o.dec.sel.add_sel = DEC_ADD_SEL_REG;
			// Enable //
			cs_o.dec.en.dmem_load_bypass = ENABLE;
			cs_o.dec.en.reg_use = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.wb = WB_SEL_LSU;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;

			case (funct3_load_e'(funct3_i))
				FNC3_LB: begin  
					cs_o.exe.sel.wb_store_size = SIZE_B;
					cs_o.exe.sel.wb_ext = EXT_S;
				end
				FNC3_LH: begin  
					cs_o.exe.sel.wb_store_size = SIZE_H;
					cs_o.exe.sel.wb_ext = EXT_S;
				end
				FNC3_LW: begin  
					cs_o.exe.sel.wb_store_size = SIZE_W;
				end
				FNC3_LBU: begin  
					cs_o.exe.sel.wb_store_size = SIZE_B;
					cs_o.exe.sel.wb_ext = EXT_Z;
				end
				FNC3_LHU: begin  
					cs_o.exe.sel.wb_store_size = SIZE_H;
					cs_o.exe.sel.wb_ext = EXT_Z;
				end
			endcase
		end
		OPC_STORE: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = INST_TYPE_S;
			cs_o.dec.sel.add_sel = DEC_ADD_SEL_REG;
			// Enable //
			cs_o.dec.en.lsu_addr = ENABLE;
			cs_o.dec.en.reg_use = ENABLE;

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.wb = WB_SEL_LSU;
			// Enable //
			cs_o.exe.en.dmem_store = ENABLE;
			case (funct3_store_e'(funct3_i))
				FNC3_SB: begin  
					cs_o.exe.sel.wb_store_size = SIZE_B;
				end
				FNC3_SH: begin  
					cs_o.exe.sel.wb_store_size = SIZE_H;
				end
				FNC3_SW: begin  
					cs_o.exe.sel.wb_store_size = SIZE_W;
				end
			endcase
		end
		OPC_OP_IMM, OPC_OP_REG: begin
			// Decode Stage //
			// ------------ //
			// Sel //
			cs_o.dec.sel.inst_type = opcode_i[5] ? INST_TYPE_R : INST_TYPE_I;
			cs_o.dec.sel.alu_wb_sel = opcode_i[5] ? ALU_WB_SEL_REG : ALU_WB_SEL_IMM;
			// Enable //
			cs_o.dec.en.alu_a = ENABLE;
			cs_o.dec.en.reg_use = opcode_i[5];

			// Execution Stage //
			// --------------- //
			// Sel //
			cs_o.exe.sel.wb = WB_SEL_ALU;
			cs_o.exe.sel.wb_store_size = SIZE_W;
			// Enable //
			cs_o.exe.en.rf_write = ENABLE;
			case (funct3_operation_e'(funct3_i))
				FNC3_OP_ADD: begin  
					cs_o.exe.sel.alu_op = ALU_OP_ADD;
				end
				FNC3_OP_SLT: begin  
					cs_o.exe.sel.alu_op = ALU_OP_LT;
					cs_o.exe.en.wb_order_flip = ENABLE;
				end
				FNC3_OP_SLTU: begin  
					cs_o.exe.sel.alu_op = ALU_OP_LTU;
					cs_o.exe.en.wb_order_flip = ENABLE;
				end
				FNC3_OP_XOR: begin  
					cs_o.exe.sel.alu_op = ALU_OP_XOR;
				end
				FNC3_OP_AND: begin  
					cs_o.exe.sel.alu_op = ALU_OP_AND;
				end
				FNC3_OP_AND: begin  
					cs_o.exe.sel.alu_op = ALU_OP_OR;
				end
				FNC3_OP_SLL: begin  
					cs_o.exe.sel.alu_op = ALU_OP_SLL;
					cs_o.exe.en.just_first_rs2_half = ENABLE;
				end
				FNC3_OP_SRL_SRA: begin  
					cs_o.dec.sel.ser_start = SER_START_UH;
					cs_o.exe.en.wb_order_flip = ENABLE;
					cs_o.exe.en.just_first_rs2_half = ENABLE;
					cs_o.exe.sel.alu_op = funct7_i[5] ?
					   	ALU_OP_SRA : ALU_OP_SRL;
				end
			endcase
		end
	endcase
end

endmodule
