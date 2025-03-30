import typedefs::*;
module ALUSubmodule (
	input logic [31:0] A,
	input logic [31:0] B,
	input ALUOperation op,

	output logic [31:0] out
);

always_comb begin
	case (op) 
		ALU_ADD, ALU_SUB: out = A + (op[0]? B : (~B + 1);
		ALU_AND: out = A & B;
		ALU_OR : out = A | B;
		ALU_SLL: out = A <<  B[4:0];
		ALU_SRL: out = A >>  B[4:0];
		ALU_SRA: out = A >>> B[4:0];
	endcase
end

endmodule
