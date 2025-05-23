module aes128_encrypt(
    // General Signals //
	// --------------- //
    input  logic clk,
    input  logic rst_n,

    // Input Controls //
	// -------------- //	
    input  logic start_i,

    // Input Data //
	// ---------- //
    input  logic [127:0] key_i,
    input  logic [127:0] plain_text_i,

    // Output Data //
	// ----------- //
    output logic [127:0] cipher_text_o,
    output logic ready_o,
    output logic done_o
    );

    // Internal Wires //
	// -------------- //

    typedef enum logic [2:0] { IDLE_S, INIT_S, ROUND_S, FIN_S } aes_state_t;
    aes_state_t aes_s;
    
    logic [3:0] round_counter;
    logic [127:0] round_key, nxt_round_key;
    logic start_round_key, start_round_enc;
    logic done_key_gen, done_enc_round;
    logic [127:0] encryption_reg, nxt_encryption_reg, nxt_encryption_reg_sr;

    // Components //
	// ---------- //
    round_key_tf u_nxt_key_gen(
        .clk          (clk),
        .rst_n        (rst_n),
        .start_i      (start_round_key),
        .key_i        (round_key),
        .round_count_i(round_counter),
        .key_o        (nxt_round_key),
        .done_o       (done_key_gen)
    );
    
    round_tf u_nxt_enc_gen(
        .clk    (clk),
        .rst_n  (rst_n),
        .start_i(start_round_enc),
        .s_i    (encryption_reg),
        .s_sr_o (nxt_encryption_reg_sr),
        .s_o    (nxt_encryption_reg),
        .done_o (done_enc_round)
    );
  
    // FSM Logic //
	// --------- //
    /*  AES-128 block encryption summary:
        1. Key schedule: expand 16-byte key into 11 round keys (one for pre-round + 10 rounds)
        2. Initial AddRoundKey: state ⊕= RoundKey[0]
        3. Rounds 1–9:
            • SubBytes   – byte-wise S-box substitution
            • ShiftRows  – rotate rows of the 4×4 state
            • MixColumns – mix each column via Galois-field math
            • AddRoundKey– state ⊕= RoundKey[r]
        4. Final Round (10):
            • SubBytes
            • ShiftRows
            • AddRoundKey (no MixColumns)
        5. Output the resulting 16-byte state as ciphertext
    */
    always_ff @( posedge clk or negedge rst_n ) begin : fsm_control
        if (!rst_n) begin
            done_o           <= 1'b0;
            ready_o          <= 1'b1;
            cipher_text_o    <= 128'b0;
            encryption_reg   <= 128'b0;
            round_key        <= 128'b0;
            round_counter    <= 4'b0;
            start_round_enc  <= 1'b0;
            start_round_key  <= 1'b0;
            aes_s            <= IDLE_S;
        end else begin

            start_round_key <= 1'b0; 
            start_round_enc <= 1'b0;

            case (aes_s)
            IDLE_S: begin
                done_o <= 1'b0;
                if (start_i) begin
                    round_key       <= key_i;
                    encryption_reg  <= plain_text_i;
                    round_counter   <= 0;
                    ready_o         <= 1'b0;
                    aes_s           <= INIT_S;
                end
            end
            
            INIT_S: begin // Round 0 
                encryption_reg  <= encryption_reg ^ round_key; // First round Operation includes just a xor Op.
                start_round_key <= 1'b1;
                start_round_enc <= 1'b1;
                aes_s           <= ROUND_S;
            end

            ROUND_S: begin // Round 1-9
                if(done_enc_round) begin // round_tf takes 16 cycles 
                    encryption_reg    <= nxt_encryption_reg ^ nxt_round_key; 
                    round_key         <= nxt_round_key;
                    round_counter     <= round_counter + 1;
                    start_round_key   <= 1'b1;
                    start_round_enc   <= 1'b1;
                end

                aes_s <= (round_counter == 9) ? FIN_S : ROUND_S; 
            end

            FIN_S: begin // Round 10
                if(done_enc_round) begin
                    cipher_text_o <= nxt_encryption_reg_sr ^ nxt_round_key; // Final round doesn't use Mix Columns
                    done_o        <= 1'b1;
                    ready_o       <= 1'b1;
                    round_counter <= 0;
                    aes_s         <= IDLE_S;
                end
            end

            default: aes_s <= IDLE_S;

        endcase
        end
    end

endmodule
