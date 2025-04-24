import typedefs::*;

localparam N_FUZZ = 10000000;

module tbExtenderSubmodule;

logic [31:0] in;
ExtenderSelector sel;
logic [31:0] out;

ExtenderSubmodule ext (
	.in(in),
	.sel(sel),
	.out(out)
);

// Basic test
initial begin
	sel = EXT_SEL_SB;

	// Extend positive byte
	in = 32'haaaaaa7a; 
	#1
	assert (out == 32'h0000007a) else $fatal("EXT_SEL_SB positive");

	// Extend negative byte
	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'hffffffaa) else $fatal("EXT_SEL_SB negative");

	sel = EXT_SEL_UB;

	// Extend unsigned byte
	in = 32'haaaaaa7a; 
	#1
	assert (out == 32'h0000007a) else $fatal("EXT_SEL_SB");

	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'h000000aa) else $fatal("EXT_SEL_SB");

	sel = EXT_SEL_SH;

	// Extend positive word
	in = 32'haaaa7aaa; 
	#1
	assert (out == 32'h00007aaa) else $fatal("EXT_SEL_SH positive");

	// Extend negative word
	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'hffffaaaa) else $fatal("EXT_SEL_SW negative");

	sel = EXT_SEL_UH;

	// Extend unsigned word
	in = 32'haaaa7aaa; 
	#1
	assert (out == 32'h00007aaa) else $fatal("EXT_SEL_SW");

	in = 32'haaaaaaaa; 
	#1
	assert (out == 32'h0000aaaa) else $fatal("EXT_SEL_UW");

	sel = EXT_SEL_W;
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
	for (int i = 0; i < N_FUZZ; ++i) begin
		in = $random;
		sel = EXT_SEL_SH;
		#1 assert ($signed(out) == $signed(h)) else $fatal("EXT_SEL_SH");
		sel = EXT_SEL_UH;
		#1 assert ($unsigned(out) == $unsigned(h)) else $fatal("EXT_SEL_UH");
		sel = EXT_SEL_UB;
		#1 assert ($unsigned(out) == $unsigned(b)) else $fatal("EXT_SEL_UB");
		sel = EXT_SEL_SB;
		#1 assert ($signed(out) == $signed(b)) else $fatal("EXT_SEL_SB");
		sel = EXT_SEL_W;
		#1 assert (out == in) else $fatal("EXT_SEL_W");
	end
end

endmodule
