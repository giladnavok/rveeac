import typedefs::*;

module imm_gen_sbm (
	input cs_inst_type inst_type_i,
	input logic [31:0] inst_i,

	output logic [31:0] imm_o
);

always_comb begin
	case (inst_type_i) 
		INST_TYPE_R: imm_o = 32'b0;
		INST_TYPE_I: imm_o = { {20{inst_i[31]}} , inst_i[31:20] };
		INST_TYPE_S: imm_o = { {20{inst_i[31]}} , inst_i[31:25], inst_i[11:7] };
		INST_TYPE_B: imm_o = { {19{inst_i[31]}} , inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0 };
		INST_TYPE_U: imm_o = { inst_i[31:12], 12'b0 };
		INST_TYPE_J: imm_o = { {11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20] ,inst_i[30:21], 1'b0 };
		default: imm_o = 32'b0;
	endcase
end

endmodule




