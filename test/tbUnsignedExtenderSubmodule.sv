import typedefs::*;
localparam N_FUZZ = 10000000;

module tbUnsignedExtenderSubmodule;

logic [31:0] in;
UnsignedExtenderSelector sel; 
logic [31:0] out;

UnsignedExtenderSubmodule u_ext (
	.in(in),
	.sel(sel),
	.out(out)
);

// Basic test
initial begin
	sel = U_EXT_SEL_B;

	// Extend positive byte
	in = 32'haaaaaa7a; 
	#1
	assert (out == 32'h0000007a) else $fatal("U_EXT_SEL_B");

	// Extend negative byte
	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'h000000aa) else $fatal("U_EXT_SEL_B");

	sel = U_EXT_SEL_H;

	// Extend positive word
	in = 32'haaaa7aaa; 
	#1
	assert (out == 32'h00007aaa) else $fatal("U_EXT_SEL_H");

	// Extend negative word
	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'h0000aaaa) else $fatal("U_EXT_SEL_W");

	sel = U_EXT_SEL_W;
	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'haaaaaaaa) else $fatal("EXT_SEL_UW");
end


// Fuzzing
logic [7:0] b;
assign b = in[7:0];
logic [15:0] h;
assign h = in[15:0];
initial begin
	#100
	//b = in[7:0];
	//w = in[15:0];
	for (int i = 0; i < N_FUZZ; ++i) begin
		in = $random;
		sel = U_EXT_SEL_H;
		#1 assert ($unsigned(out) == $unsigned(h)) else $fatal("U_EXT_SEL_H");
		sel = U_EXT_SEL_B;
		#1 assert ($unsigned(out) == $unsigned(b)) else $fatal("U_EXT_SEL_B");
		sel = U_EXT_SEL_W;
		#1 assert (out == in) else $fatal("U_EXT_SEL_W");
	end
end
endmodule
