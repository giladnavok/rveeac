`include "typedefs.sv"

module top (
);


PCSelector pcSelector;
logic [31:0] aluOut;
logic [31:0] pcIncremented;
logic [31:0] inst;

FetchUnit
fetchUnit (
	.clk(clk),
	.resetN(resetN),
	.aluOut(aluOut),
	.pcSelector(pcSelector),
	.comparerOut(comparerOut),

	.pcIncremented(pcIncremented),
	.inst(inst)
);

InstructionType instructionType;
ALUOperation aluOperation;
ALUASelector aluASelector;
ALUBSelector aluBSelector;
RegfileWriteSelector regfileWriteSelector;
RegfileWriteSize regfileWriteSize;
RegfileWriteExtend regfileWriteExtend;
ExtenderSelector loadExtenderSelector;
UnsignedExtenderSelector storeExtenderSelector;
ComparerInputSelector comparerInputSelector;
ComparerOutputSelector comparerOutputSelector;
logic comparerFlip;

logic dmemWrite;
logic regfileWrite;
logic [31:0] immGenOut;

logic [4:0] rd;
logic [4:0] rs1;
logic [4:0] rs2;

DecodeControlUnit
decodeControlUnit (
	.inst(inst),

	.instructionType(instructionType),
	.aluOperation(aluOperation),
	.aluASelector(aluASelector),
	.aluBSelector(aluBSelector),
	.pcSelector(pcSelector),
	.regfileWriteSelector(regfileWriteSelector),
	.regfileWriteSize(regfileWriteSize),
	.regfileWriteExtend(regfileWriteExtend),
	.loadExtenderSelector(loadExtenderSelector),
	.storeExtenderSelector(storeExtenderSelector),
	.rd(rd),
	.rs1(rs1),
	.rs2(rs2),
	.comparerInputSelector(comparerInputSelector),
	.comparerOutputSelector(comparerOutputSelector),
	.comparerFlip(comparerFlip),
	.dmemWrite(dmemWrite),
	.regfileWrite(regfileWrite),

	.immGenOut(immGenOut)
);

logic comparerOut;

ExecutionUnit
executionUnit (
	.clk(clk),
	.resetN(resetN),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.regfileWrite(regfileWrite),
	.regfileWriteSize(regfileWriteSize),
	.regfileWriteExtend(regfileWriteExtend),
	.regfileWriteSelector(regfileWriteSelector),
	.pcIncremented(pcIncremented),
	.immGenOut(immGenOut),
	.aluOperation(aluOperation),
	.aluASelector(aluASelector),
	.aluBSelector(aluBSelector),
	.loadExtenderSelector(loadExtenderSelector),
	.storeExtenderSelector(storeExtenderSelector),
	.comparerInputSelector(comparerInputSelector),
	.comparerOutputSelector(comparerOutputSelector),
	.comparerFlip(comparerFlip),
	.dmemWrite(dmemWrite),


	.aluOut(aluOut),

	.comparerOut(comparerOut)
);

endmodule
