module aes128_core(
    // General Signals //
	// --------------- //
    input  logic clk,
    input  logic rst_n,

    // Input Controls //
	// -------------- //	
    input  logic start_i,

    // Input Data //
	// ---------- //
    input  logic [127:0] modulus_i,
    input  logic [127:0] exponent_i,
    input  logic [127:0] message_i, // This is the sym_key

    // Output Data //
	// ----------- //
    output logic [127:0] header_o,
    output logic done_o
    );

endmodule 