`include "typedefs.sv"

module DecodeControlUnit (
	input logic [31:0] inst,

	output InstructionType instructionType,
	output ALUOperation aluOperation,
	output ALUASelector aluASelector,
	output ALUBSelector aluBSelector,
	output PCSelector pcSelector,
	output RegfileWriteSelector regfileWriteSelector,
	output RegfileWriteSize regfileWriteSize,
	output RegfileWriteExtend regfileWriteExtend,
	output ExtenderSelector loadExtenderSelector,
	output UnsignedExtenderSelector storeExtenderSelector,
	output logic [4:0] rd,
	output logic [4:0] rs1,
	output logic [4:0] rs2,
	output ComparerInputSelector comparerInputSelector,
	output ComparerOutputSelector comparerOutputSelector,
	output logic comparerFlip,
	output logic dmemWrite,
	output logic regfileWrite,

	output logic [31:0] immGenOut
);

logic [6:0] opcode;
logic [2:0] funct3;
logic [6:0] funct7;


DecodeSubmodule decodeSubmodule (
	.inst(inst),
	
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.rd(rd),
	.rs1(rs1),
	.rs2(rs2)
);

ImmGenSubmodule immGenSubmodule (
	.instructionType(instructionType),
	.inst(inst),

	.imm(immGenOut)
);


ControlSubmodule controlSubmodule (
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),

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
	.comparerInputSelector(comparerInputSelector),
	.comparerOutputSelector(comparerOutputSelector),
	.comparerFlip(comparerFlip),
	.dmemWrite(dmemWrite),
	.regfileWrite(regfileWrite)
);

endmodule