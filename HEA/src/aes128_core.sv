module aes128_core #(

    parameter SBOX_PAR_KEY = 4,
    parameter SBOX_PAR_ROUND = 16,
    parameter SBOX_PAR_INV_ROUND = 16

)
(
    // General Signals
    input  logic          clk,
    input  logic          rst_n,

    // Input Controls
    input  logic          start_enc_i,
    input  logic          start_dec_i,
    input  logic          load_key_i,
    // Input Data
    // input  logic [127:0]  key_i,

    input  logic [127:0]  data_i,

    // Output Data
    output logic [127:0]  data_o,
    output logic          ready_o,
    output logic          done_o
);

    // State encoding
    typedef enum logic [2:0] { IDLE, ENCRYPT, DECRYPT } aes_state_t;
    aes_state_t aes_s;

    // Internal wires
    logic [127:0] enc_text_o, dec_text_o;
    logic [127:0] key;
    logic         enc_ready, enc_done;
    logic         dec_ready, dec_done;
    
    logic done_pulse;
    
    // Encryption unit
    aes128_encrypt #(.SBOX_PAR_KEY(SBOX_PAR_KEY),.SBOX_PAR_ROUND(SBOX_PAR_ROUND))
    u_enc_unit (
        .clk            (clk),
        .rst_n          (rst_n),
        .start_i        (start_enc_i),
        .key_i          (key),
        .plain_text_i   (data_i),
        .cipher_text_o  (enc_text_o),
        .done_o         (enc_done),
        .ready_o        (enc_ready)
    );

    // Decryption unit
    aes128_decrypt #(.SBOX_PAR_KEY(SBOX_PAR_KEY),.SBOX_PAR_INV_ROUND(SBOX_PAR_INV_ROUND))
    u_dec_unit (
        .clk             (clk),
        .rst_n           (rst_n),
        .start_i         (start_dec_i),
        .key_i           (key),
        .cipher_text_i   (data_i),
        .plain_text_o    (dec_text_o),
        .done_o          (dec_done),
        .ready_o         (dec_ready)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ready_o   <= 1'b0;
            key       <= 128'b0;
            aes_s     <= IDLE;
        end else begin
            // drive ready/done
            ready_o <= enc_ready && dec_ready;  // only valid when neither unit is running

            case (aes_s)
                IDLE: begin
                    if (load_key_i) key <= data_i;
                    else if (start_enc_i && ready_o)
                        aes_s <= ENCRYPT;
                    else if (start_dec_i && ready_o)
                        aes_s <= DECRYPT;
                end

                ENCRYPT: begin
                    if (enc_done) begin
                        aes_s     <= IDLE;
                    end
                end

                DECRYPT: begin
                    if (dec_done) begin
                        aes_s     <= IDLE;
                    end
                end

                default: aes_s <= IDLE;
            endcase
        end
    end
    
    always_comb begin
        data_o = 128'b0;
        done_o = enc_done || dec_done;
        if (enc_done) data_o = enc_text_o;
        else if (dec_done) data_o = dec_text_o;
    end


endmodule
