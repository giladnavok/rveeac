module aes128_decrypt(
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
    input  logic [127:0] cipher_text_i,

    // Output Data //
	// ----------- //
    output logic [127:0] plain_text_o,
    output logic ready_o,
    output logic done_o
    );

    // Internal Wires //
	// -------------- //

    typedef enum logic [2:0] { IDLE, GEN_ROUND_KEYS, INV_FIN_ROUND ,INV_ROUND} aes_state_t;
    aes_state_t aes_state;

    logic [127:0] round_keys_table [0:10];


    logic [3:0] round_counter;
    logic [127:0] round_key, nxt_round_key;
    logic start_round_key, done_key_gen;
    
    logic start_round_dec, done_dec_round, bypass_mc;
    logic [127:0] decryption_reg, nxt_decryption_reg;

    // Components //
	// ---------- //
    round_key_tf u_nxt_key_gen(
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (start_round_key),
        .key_i        (round_key),
        .round_count_i(round_counter),
        .key_o        (nxt_round_key),
        .done_o       (done_key_gen)
    );

    inv_round_tf u_nxt_dec_gen( 
         .clk      (clk),
         .rst_n    (rst_n),
         .start    (start_round_dec),
         .bypass_mc(bypass_mc),
         .b_i      (decryption_reg),
         .b_o      (nxt_decryption_reg),
         .done_o   (done_dec_round)
    );
  
    // FSM Logic //
	// --------- //
    /*  AES-128 block decryption summary:
        1. Key schedule
        • Expand the 16-byte key into roundKeys[0..10] exactly as in encryption.
        • (Optionally) Precompute “decryption round keys” by applying InvMixColumns
            to roundKeys[1..9] so you don’t have to do it on-the-fly.
    
        2. Initial AddRoundKey
        // “Undo” the last encryption AddRoundKey
        state ⊕= roundKeys[10]
    
        3. Rounds 9 down to 1 (for r = 9,8,…,1):
        InvShiftRows   – rotate rows right by offsets [0, 1, 2, 3]
        InvSubBytes    – apply the inverse S-box to every byte
        AddRoundKey    – state ⊕= roundKeys[r]
        InvMixColumns  – multiply each column by the inverse mix-matrix
    
        4. Final Round (r = 0):
        InvShiftRows
        InvSubBytes
        AddRoundKey (state ⊕= roundKeys[0])
    
        5. Output the resulting 16-byte state as plaintext
    */
    always_ff @( posedge clk or negedge rst_n ) begin : fsm_control
        if (!rst_n) begin
            done_o            <= 1'b0;
            ready_o           <= 1'b1;
            plain_text_o      <= 128'b0;
            decryption_reg    <= 128'b0;
            round_key         <= 128'b0;
            round_counter     <= 4'b0;
            bypass_mc         <= 1'b0;
            start_round_dec   <= 1'b0;
            start_round_key   <= 1'b0;
            round_keys_table  <= '{ default: 128'h0 };
            aes_state         <= IDLE;
        end else begin

            start_round_key <= 1'b0; 
            start_round_dec <= 1'b0;
            bypass_mc       <= 1'b0;

            case (aes_state)
            IDLE: begin
                done_o <= 1'b0;
                if (start_i) begin
                    round_key           <= key_i;
                    round_keys_table[0] <= key_i;
                    decryption_reg      <= cipher_text_i;
                    round_counter       <= 0;
                    start_round_key     <= 1'b1;
                    ready_o             <= 1'b0;
                    aes_state           <= GEN_ROUND_KEYS;
                end
            end
            
            GEN_ROUND_KEYS: begin // Generate round keys table 
                if (done_key_gen && round_counter < 10) begin
                    round_keys_table[round_counter+1] <= nxt_round_key;
                    round_counter                     <= round_counter + 1;
                    if (round_counter < 9) begin
                        round_key       <= nxt_round_key;
                        start_round_key <= 1'b1;
                    end
                end

                if (round_counter == 10) begin
                    round_counter   <= round_counter - 1; // Keep at 10
                    decryption_reg  <= decryption_reg ^ round_keys_table[round_counter];
                    start_round_dec <= 1'b1;
                    bypass_mc       <= 1'b1;
                    aes_state       <= INV_FIN_ROUND;
                end
            end

            INV_FIN_ROUND: begin // Round 10 
                bypass_mc       <= 1'b1;
                if(done_dec_round) begin // round_tf takes 16 cycles 
                    decryption_reg    <= nxt_decryption_reg ^ round_keys_table[round_counter]; // Bypassing the inv_mix_columns
                    round_key         <= nxt_round_key;
                    round_counter     <= round_counter - 1;
                    start_round_dec   <= 1'b1;
                    bypass_mc         <= 1'b0;
                    aes_state         <= INV_ROUND;
                end
            end

            INV_ROUND: begin // Round 9 - 0

                if(done_dec_round) begin
                    if (round_counter != 0) begin
                        decryption_reg  <= nxt_decryption_reg ^ round_keys_table[round_counter];
                        start_round_dec <= 1'b1;
                        round_counter   <= round_counter - 1;
                    end else begin
                        plain_text_o <= nxt_decryption_reg ^ round_keys_table[round_counter]; 
                        done_o       <= 1'b1;
                        ready_o      <= 1'b1; 
                        aes_state    <= IDLE;
                    end
                end

            end

            default: aes_state <= IDLE;
            
        endcase
        end
    end

endmodule
