module aes_wrapper(
    // General Signals //
	// --------------- //
    input  logic clk,
    input  logic rst_n,

    // Input Controls //
    // -------------- //	
    input  logic start_i,

    // Input Data //
    // ---------- //
    input  logic [127:0] plain_text_i, // This should be 32 bit in order to connect to the CPU

    // Output Data //
    // ----------- //
    output logic [127:0] cipher_text_o, // This should be 32 bit in order to connect to the CPU
    output logic [127:0] header_o, // This should be 32 bit in order to connect to the CPU
    output logic done_o
);


    // Internal Wires //
	// -------------- //

    typedef enum logic [2:0] { IDLE_S, RSA_S, AES128_S, DONE_S} aes_state_t;
    aes_state_t aes_state;

    /* 
       All the following assignments can AND should done with dynamic calculations in order add randomness and robustness. 
       For testing purposes they will be consts.
    */
    logic [127:0] modulus, modulus_inv ,enc_exponent, dec_exponent;
    assign modulus = 77; // For simplicity p = 7 & q = 11 ===> modulus = p * q = 77
    assign modulus_inv = 60;// modulus_inv = (1-p)(1-q) = 60
    assign enc_exponent = 17; // Random selection such that gcd(modulus_inv,enc_exponent) = 1
    assign dec_exponent = 53; // Calculated using Extended Euclidean Algorithm. TODO add elaboration

    // This key should be generate and not be constant. It's const for testing only.
    logic [127:0] sym_key;
    assign sym_key = 128'hA5A5_5A5A_F0F0_0F0F_1234_5678_9ABC_DEF0;

    logic rsa_done,aes128_done;

    rsa_core header_gen(
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .modulus_i(modulus),// Depends on the op, could be modulus or modulus_inv
        .exponent_i(enc_exponent), // Depends on the op, could be enc_exponent or dec_exponent
        .message_i(sym_key),
        .header_o(header_o), // should be outputed 32 bit at a time
        .done_o(rsa_done)
    );

    aes128_core cipher_text_gen( 
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .key_i(modulus),// Depends on the op, could be modulus or modulus_inv
        .plain_text_i(enc_exponent), // Depends on the op, could be enc_exponent or dec_exponent
        .cipher_text_o(sym_key),
        .ready_o(/*Unused?*/), // should be outputed 32 bit at a time
        .done_o(aes128_done)
    );

    // FSM template
    always_ff @( posedge clk or negedge rst_n ) begin : fsm_control
        if (!rst_n) begin
            aes_state <= IDLE_S;
        end else begin
            case (aes_state)
                IDLE_S: begin
                    if (start_i) begin
                        aes_state <= RSA_S;
                    end
                end

                RSA_S : begin
                    if (rsa_done) begin
                        aes_state <= AES128_S;
                    end
                end

                AES128_S : begin
                    if (aes128_done) begin
                        aes_state <= DONE_S;
                    end
                end

                DONE_S : begin
                    aes_state <= IDLE_S;
                end
                default: aes_state <= IDLE_S;
            endcase
        end
    end

endmodule
