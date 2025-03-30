import typedefs::*;

module ComparerSubmodule (
	input logic signed [31:0] subResult,
	input logic [31:0] rA,
	input logic [31:0] rB,
	input logic [31:0] imm,
	input ComparerInputSelector inputSel,
	input ComparerOutputSelector outputSel,
	input logic flip,

	output logic signedLT,
	output logic unsignedLT,
	output logic eq,
	output logic out
);

logic innerOut;
assign out = (innerOut ^ flip);

always_comb begin
	signedLT = ~subResult[31];
	eq = (subResult == 0);
	case (inputSel)
		CMP_IN_SEL_RA_RB: 
			unsignedLT = (rA < rB);
		CMP_IN_SEL_RA_IMM: 
			unsignedLT = (rA < imm);
	endcase
	case (outputSel)
		CMP_OUT_SEL_EQ:
			innerOut = eq;
		CMP_OUT_SEL_LT:
			innerOut = signedLT;
		CMP_OUT_SEL_LTU:
			innerOut = unsignedLT;
	endcase
end

endmodule
