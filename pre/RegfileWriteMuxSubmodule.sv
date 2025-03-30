`include "typedefs.sv"

module RegfileWriteMuxSubmodule (
	input logic [31:0] dmemOut,
	input logic [31:0] aluOut,
	input logic [31:0] pcIncremented,
	input logic [31:0] immGenOut,
	input logic comparerSLT,
	input logic comparerULT,
	input RegfileWriteSelector sel,

	output logic[31:0] out
);


always_comb begin
	out = aluOut;
	case (sel)
		RF_WR_SEL_DMEM: out = dmemOut;
		RF_WR_SEL_IMM : out = immGenOut;
		RF_WR_SEL_ALU : out = aluOut;
		RF_WR_SEL_PC_INC: out = pcIncremented;
		RF_WR_SEL_U_LT: out[0] = comparerULT;
		RF_WR_SEL_S_LT: out[0] = comparerSLT;
		default: out = aluOut;
	endcase
end
endmodule
