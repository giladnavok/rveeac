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

    typedef enum logic [2:0] { IDLE, INIT, ROUND, FIN, DONE } aes_state_t;
    aes_state_t aes_state;
    logic [3:0] round_counter;
    // logic [127:0] round_key [10:0];
    logic [127:0] round_key, nxt_round_key;
    logic [127:0] encryption_reg, nxt_encryption_reg, reg_sr;

    // genvar i;
    generate
        // for (i = 0; i < 10; i++) begin
        //     round_tf u_nxt_key_gen(
        //         .b_i(round_key[i]),
        //         .en_mc(1'b1),
        //         .b_sr_o(/* Unused */)
        //         .b_o(round_key[i+1])
        //     );
        // end    
        round_tf u_nxt_key_gen(
            .b_i(round_key),
            .b_sr_o(/* Unused */),
            .b_o(nxt_round_key)
        );
        
        round_tf u_nxt_enc_gen(
            .b_i(encryption_reg),
            .b_sr_o(reg_sr),
            .b_o(nxt_encryption_reg)
        );
    endgenerate
  
    // FSM Logic //
	// --------- //

    always_ff @( posedge clk or negedge rst_n ) begin : fsm_control
        if (!rst_n) begin
            done_o             <= 1'b0;
            ready_o            <= 1'b1;
            cipher_text_o      <= 128'b0;
            encryption_reg     <= 128'b0;
            round_key          <= 128'b0;
//            nxt_encryption_reg <= 128'b0;
//            reg_sr             <= 128'b0;
            aes_state          <= IDLE;
        end else begin
            case (aes_state)
            IDLE: begin
                done_o <= 1'b0;
                if (start_i) begin
                    round_key      <= key_i;
                    encryption_reg <= plain_text_i;
                    round_counter  <= 0;
                    aes_state      <= INIT;
                end
            end
            
            INIT: begin
                encryption_reg <= encryption_reg ^ round_key;
                round_counter  <= round_counter + 1;
                aes_state      <= ROUND;
            end

            ROUND: begin
                encryption_reg <= nxt_encryption_reg ^ round_key;
                round_key <= nxt_round_key;
                round_counter <= round_counter + 1;
                if (round_counter == 9) begin
                    aes_state <= FIN;
                end
            end

            FIN: begin
                encryption_reg <= reg_sr ^ round_key; // Final round doesn't use Mix Columns
                aes_state <= DONE;
            end

            DONE: begin
                done_o        <= 1'b1;
                ready_o       <= 1'b1;
                cipher_text_o <= encryption_reg;
                round_counter <= 0;
                aes_state     <= IDLE;
            end

            default: aes_state <= IDLE;

        endcase
        end
    end

endmodule
