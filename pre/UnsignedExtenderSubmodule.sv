import typedefs::*;

module UnsignedExtenderSubmodule (
	input logic [31:0] in,
	input UnsignedExtenderSelector sel,

	output logic [31:0] out
);

always_comb begin
	out = in;
	case (sel)
		U_EXT_SEL_B: out = {{24{1'b0}}, in[7:0]};
		U_EXT_SEL_H: out = {{16{1'b0}}, in[15:0]};
		U_EXT_SEL_W: out = in;
	endcase
end

endmodule