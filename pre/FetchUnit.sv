module FetchUnit (
	input logic clk,
	input logic resetN,
	input logic [31:0] aluOut,
	input PCSelector pcSelector,
	input logic comparerOut,

	output logic [31:0] pcIncremented,
	output logic [31:0] inst
);


logic [31:0] pc;

PCSubmodule
pcSubmodule (
	.clk(clk),
	.resetN(resetN),
	.pcSelector(pcSelector),
	.aluOut(aluOut),
	.comparerOut(comparerOut),

	.pcIncremented(pcIncremented),
	.pc(pc)
);

MemorySubmodule
# (.INIT_FILENAME("instructions.txt"))
imem (
	.clk(clk),
	.addr(pc),
	.write(1'b0),
	.din(32'b0),
	.dout(inst)
);

endmodule