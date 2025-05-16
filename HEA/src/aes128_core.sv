module aes128_core (
    // General Signals
    input  logic          clk,
    input  logic          rst_n,

    // Input Controls
    input  logic          start_enc_i,
    input  logic          start_dec_i,

    // Input Data
    input  logic [127:0]  key_i,
    input  logic [127:0]  text_i,

    // Output Data
    output logic [127:0]  text_o,
    output logic          ready_o,
    output logic          done_o
);

    // Internal wires to capture outputs from each unit
    logic [127:0] enc_text_o, dec_text_o;
    logic         enc_ready, enc_done;
    logic         dec_ready, dec_done;

    // Encryption unit
    aes128_encrypt u_enc_unit (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_i        (start_enc_i),
        .key_i          (key_i),
        .plain_text_i   (text_i),
        .cipher_text_o  (enc_text_o),
        .done_o         (enc_done),
        .ready_o        (enc_ready)
    );

    // Decryption unit
    aes128_decrypt u_dec_unit (
        .clk             (clk),
        .rst_n           (rst_n),
        .start_i         (start_dec_i),
        .key_i           (key_i),
        .cipher_text_i   (text_i),
        .plain_text_o    (dec_text_o),
        .done_o          (dec_done),
        .ready_o         (dec_ready)
    );

    // Mux outputs based on which operation is started
    assign text_o  = start_enc_i ? enc_text_o : dec_text_o;
    assign done_o  = start_enc_i ? enc_done   : dec_done;
    assign ready_o = start_enc_i ? enc_ready  : dec_ready;

endmodule
