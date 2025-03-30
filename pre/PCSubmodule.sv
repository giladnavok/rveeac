
import typedefs::*;
module PCSubmodule (
	input logic clk,
	input logic resetN,
	input PCSelector pcSelector,

	input logic [31:0] aluOut,
	input logic [31:0] comparerOut,

	output logic [31:0] pc,
	output logic [31:0] pcIncremented
);

assign pcIncremented = pc + 4;

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		pc <= 32'b0;
	end else begin
		case (pcSelector) 
			PC_SEL_INC: pc <= pcIncremented;
			PC_SEL_JMP: pc <= aluOut;
			PC_SEL_BR: pc <= (comparerOut)? aluOut : pcIncremented;
		endcase
	end
end
		
endmodule