`include "typedefs.sv"

module ExtenderSubmodule (
	input logic [31:0] in,
	input ExtenderSelector sel,

	output logic [31:0] out
);

always_comb begin
	out = in;
	case (sel)
		EXT_SEL_SB:
			out = {{24{in[7]}}, in[7:0]};
		EXT_SEL_UB:
			out = { 24'b0, in[7:0]};
		EXT_SEL_SH:
			out = {{16{in[15]}}, in[15:0]};
		EXT_SEL_UH:
			out = { 16'b0, in[15:0]};
		EXT_SEL_W:
			out = in;
	endcase
end

endmodule