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

    // State encoding
    typedef enum logic [2:0] { IDLE, ENCRYPT, DECRYPT } aes_state_t;
    aes_state_t aes_state;

    // Internal wires
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

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            text_o    <= 128'b0;
            done_o    <= 1'b0;
            ready_o   <= 1'b0;
            aes_state <= IDLE;
        end else begin
            // drive ready/done
            ready_o <= enc_ready && dec_ready;  // only valid when neither unit is running
            done_o  <= enc_done  || dec_done;

            case (aes_state)
                IDLE: begin
                    if (start_enc_i)
                        aes_state <= ENCRYPT;
                    else if (start_dec_i)
                        aes_state <= DECRYPT;
                end

                ENCRYPT: begin
                    if (enc_done) begin
                        text_o    <= enc_text_o;
                        aes_state <= IDLE;
                    end
                end

                DECRYPT: begin
                    if (dec_done) begin
                        text_o    <= dec_text_o;
                        aes_state <= IDLE;
                    end
                end

                default: aes_state <= IDLE;
            endcase
        end
    end

endmodule
