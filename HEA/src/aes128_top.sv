module aes128_top (
    input  logic        clk,        // 100 MHz system clock
    input  logic        rst,        // Active-high reset
    input  logic [3:0]  sw,         // Switches: text_i[3:0]
    input  logic        btn_enc,    // Button to start encryption
    input  logic        btn_dec,    // Button to start decryption
    output logic [3:0]  led,         // LED output: text_o[3:0]
    output logic ready_o,
    output logic done_o
);

    logic [127:0] text_i;
    logic [127:0] text_o;
    logic start_enc;
    logic start_dec;
    logic done;
    logic ready;
    
    logic rst_n;
    assign rst_n = !rst;
    
    // Hardcoded key and top part of text input
    assign text_i = {124'h3243f6a8885a308d313198a2e037071, sw}; // last 4 bits from switches

    // Simple button press detection (rising edge)
    logic btn_enc_sync_0, btn_enc_sync_1, btn_enc_prev;
    always_ff @(posedge clk) begin
        btn_enc_sync_0 <= btn_enc;
        btn_enc_sync_1 <= btn_enc_sync_0;
        btn_enc_prev   <= btn_enc_sync_1;
    end
    assign start_enc = (btn_enc_sync_1 && !btn_enc_prev); // rising edge
    
    // Simple button press detection (rising edge)
    logic btn_dec_sync_0, btn_dec_sync_1, btn_dec_prev;
    always_ff @(posedge clk) begin
        btn_dec_sync_0 <= btn_dec;
        btn_dec_sync_1 <= btn_dec_sync_0;
        btn_dec_prev   <= btn_dec_sync_1;
    end
    assign start_dec = (btn_dec_sync_1 && !btn_dec_prev); // rising edge

    aes128_core u_core (
        .clk(clk),
        .rst_n(rst_n),
        .start_enc_i(start_enc),
        .start_dec_i(start_dec),
        .key_i(128'h2b7e151628aed2a6abf7158809cf4f3c),
        .text_i(text_i),
        .text_o(text_o),
        .ready_o(ready),
        .done_o(done)
    );
    
    logic done_latched;
    logic [26:0] done_counter;  // Enough for up to 134M counts

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_latched <= 1'b0;
            done_counter <= 0;
        end else if (done) begin
            done_latched <= 1'b1;
            done_counter <= 27'd100_000_000;  // 1 second at 100 MHz
        end else if (done_latched && done_counter > 0) begin
            done_counter <= done_counter - 1;
            if (done_counter == 1)
                done_latched <= 1'b0;
        end
    end
    
    assign ready_o = ready;
    assign done_o  = done_latched;
    assign led     = text_o[3:0];

endmodule
