`include "typedefs.sv"

module ExecutionUnit (
	input logic clk,
	input logic resetN,

	// Regfile inputs
	input logic [4:0] rs1,
	input logic [4:0] rs2,
	input logic [4:0] rd,

	input logic regfileWrite,
	input RegfileWriteSize regfileWriteSize,
	input RegfileWriteExtend regfileWriteExtend,
	input RegfileWriteSelector regfileWriteSelector,

	input logic [31:0] pcIncremented,
	input logic [31:0] immGenOut,

	// ALU inputs
	input ALUOperation aluOperation,
	input ALUASelector aluASelector,
	input ALUBSelector aluBSelector,

	input ExtenderSelector loadExtenderSelector,
	input UnsignedExtenderSelector storeExtenderSelector,
	
	// Dmem inputs
	input logic dmemWrite,

	// Comparer inputs
	input ComparerInputSelector comparerInputSelector,
	input ComparerOutputSelector comparerOutputSelector,
	input logic comparerFlip,

	// Outputs
	output logic [31:0] aluOut,
	output logic comparerOut
);


logic [31:0] registerDataA;
logic [31:0] registerDataB;
logic [31:0] storeExtendedRegisterDataB;
logic [31:0] loadExtendedDmemOut;

logic [31:0] dmemOut;
logic [31:0] regfileWriteMuxOut;

RegfileSubmodule
regfile (
	.clk(clk),
	.resetN(resetN),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),

	.write(regfileWrite),
	.registerDataIn(regfileWriteMuxOut),
	.writeSize(regfileWriteSize),
	.writeExtend(regfileWriteExtend),

	.registerDataA(registerDataA),
	.registerDataB(registerDataB)
);

RegfileWriteMuxSubmodule 
regfileWriteMux (
	.dmemOut(loadExtendedDmemOut),
	.aluOut(aluOut),
	.pcIncremented(pcIncremented),
	.immGenOut(immGenOut),
	.comparerSLT(comparerSLT),
	.comparerULT(comparerULT),
	.sel(regfileWriteSelector),

	.out(regfileWriteMuxOut)
);

UnsignedExtenderSubmodule
storeExtender (
	.in(registerDataB),
	.sel(storeExtenderSelector),

	.out(storeExtendedRegisterDataB)
);

ExtenderSubmodule
loadExtender (
	.in(dmemOut),
	.sel(loadExtenderSelector),

	.out(loadExtendedDmemOut)
);

logic comparerSLT;
logic comparerULT;

ComparerSubmodule
comparer (
	.subResult(aluOut),
	.rA(registerDataA),
	.rB(registerDataB),
	.imm(immGenOut),
	.inputSel(comparerInputSelector),
	.outputSel(comparerOutputSelector),
	.flip(comparerFlip),

	.signedLT(comparerSLT),
	.unsignedLT(comparerULT),
	.out(comparerOut)
);

MemorySubmodule 
dmem (
	.clk(clk),
	.addr(aluOut),
	.write(dmemWrite),
	.din(storeExtendedRegisterDataB),
	.dout(dmemOut)
);

endmodule
