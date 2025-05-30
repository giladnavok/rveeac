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
    aes_state_t aes_s;

    // Internal wires
    logic [127:0] enc_text_o, dec_text_o;
    logic         enc_ready, enc_done;
    logic         dec_ready, dec_done;
    
    logic done_pulse;
    
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
            ready_o   <= 1'b0;
            aes_s     <= IDLE;
        end else begin
            // drive ready/done
            ready_o <= enc_ready && dec_ready;  // only valid when neither unit is running

            case (aes_s)
                IDLE: begin
                    if (start_enc_i && ready_o)
                        aes_s <= ENCRYPT;
                    else if (start_dec_i && ready_o)
                        aes_s <= DECRYPT;
                end

                ENCRYPT: begin
                    if (enc_done) begin
                        text_o    <= enc_text_o;
                        aes_s     <= IDLE;
                    end
                end

                DECRYPT: begin
                    if (dec_done) begin
                        text_o    <= dec_text_o;
                        aes_s     <= IDLE;
                    end
                end

                default: aes_s <= IDLE;
            endcase
        end
    end
    
    always_ff @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        done_pulse <= 1'b0;
      end else begin
      
        done_pulse <= 1'b0;
        
        if (enc_done || dec_done) begin
            done_pulse <= 1'b1;
        end   
      end     
    end

    assign done_o = done_pulse;

endmodule
