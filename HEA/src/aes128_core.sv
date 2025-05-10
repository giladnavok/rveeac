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
    logic [3:0] sub_round_counter;
    // logic [127:0] round_key [10:0];
    logic [127:0] round_key, nxt_round_key;
    logic start_round_key, start_round_enc;
    logic done_key_gen, done_enc_round;
    logic [127:0] encryption_reg, nxt_encryption_reg, reg_sr;

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
    
    round_tf u_nxt_enc_gen(
        .clk   (clk),
        .rst_n (rst_n),
        .start (tart_round_enc),
        .b_i   (encryption_reg),
        .b_sr_o(reg_sr),
        .b_o   (nxt_encryption_reg),
        .done_o(done_enc_round)
    );
  
    // FSM Logic //
	// --------- //

    always_ff @( posedge clk or negedge rst_n ) begin : fsm_control
        if (!rst_n) begin
            done_o             <= 1'b0;
            ready_o            <= 1'b1;
            cipher_text_o      <= 128'b0;
            encryption_reg     <= 128'b0;
            round_key          <= 128'b0;
            round_counter      <= 4'b0;
            sub_round_counter  <= 4'b0;
            start_round_enc    <= 1'b0;
            start_round_key    <= 1'b0;
            aes_state          <= IDLE;
        end else begin

            start_round_key <= 1'b0; 
            start_round_enc <= 1'b0;

            case (aes_state)
            IDLE: begin
                done_o <= 1'b0;
                if (start_i) begin
                    round_key       <= key_i;
                    encryption_reg  <= plain_text_i;
                    round_counter   <= 0;
                    start_round_key <= 1'b1;
                    ready_o         <= 1'b0;
                    aes_state       <= INIT;
                end
            end
            
            INIT: begin
                if (done_key_gen) begin
                    encryption_reg  <= encryption_reg ^ round_key; // First round Operation includes just a xor Op.
                    round_counter   <= round_counter + 1;
                    round_key       <= nxt_round_key;
                    start_round_key <= 1'b1;
                    start_round_enc <= 1'b1;
                    aes_state       <= ROUND;
                end
            end

            ROUND: begin
                if(done_key_gen && done_key_gen) begin // round_tf takes 16 cycles 
                    encryption_reg    <= nxt_encryption_reg ^ round_key; 
                    round_key         <= nxt_round_key;
                    round_counter     <= round_counter + 1;
                    start_round_key   <= 1'b1;
                    start_round_enc   <= 1'b1;
                end

                aes_state <= (round_counter == 9) ? FIN : ROUND;

            end

            FIN: begin
                if(done_key_gen && done_key_gen) begin
                    encryption_reg <= reg_sr ^ round_key; // Final round doesn't use Mix Columns
                    aes_state      <= DONE;
                end
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
