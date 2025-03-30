import typedefs::*;

module ImmGenSubmodule (
	input InstructionType instructionType,
	input logic [31:0] inst,

	output logic [31:0] imm
);

always_comb begin
	case (instructionType) 
		INST_TYPE_R: imm = 32'b0;
		INST_TYPE_I: imm = { {20{inst[31]}} , inst[31:20] };
		INST_TYPE_S: imm = { {20{inst[31]}} , inst[31:25], inst[11:7] };
		INST_TYPE_B: imm = { {19{inst[31]}} , inst[31], inst[7], inst[30:25], inst[11:8], inst[31]};
		INST_TYPE_U: imm = { inst[31:12], 12'b0 };
		INST_TYPE_J: imm = { {19{inst[31]}}, inst[31], inst[19:12], inst[20] ,inst[30:21], inst[31] };
		default: imm = 32'b0;
	endcase
end

endmodule




