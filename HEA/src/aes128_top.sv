module aes128_top (
    input  logic        clk,        // 100 MHz
    input  logic        rst,        // active-high pushbutton reset
    input  logic [3:0]  sw,         // lower nibble of plaintext
    input  logic        btn_key,    // load the 128-bit key
    input  logic        btn_enc,    // start encryption
    input  logic        btn_dec,    // start decryption
    output logic [3:0]  led,        // lower nibble of data_o
    output logic        ready_o,    // core ready indicator
    output logic        done_o      // pulse when op finishes
);

    // Invert reset for core
    logic rst_n = ~rst;

    // Straight‐through plaintext input (upper bits fixed zero)
    logic [127:0] text_i;
    assign text_i = {124'h3243f6a8885a308d313198a2e037071, sw};

    // Synchronize and edge-detect all three buttons
    logic key_s0, key_s1, key_prev;
    logic enc_s0, enc_s1, enc_prev;
    logic dec_s0, dec_s1, dec_prev;

    always_ff @(posedge clk) begin
        // key load
        key_s0   <= btn_key;
        key_s1   <= key_s0;
        key_prev <= key_s1;
        // encrypt
        enc_s0   <= btn_enc;
        enc_s1   <= enc_s0;
        enc_prev <= enc_s1;
        // decrypt
        dec_s0   <= btn_dec;
        dec_s1   <= dec_s0;
        dec_prev <= dec_s1;
    end

    // Rising‐edge pulses
    logic load_key =  key_s1 & ~key_prev;
    logic start_enc = enc_s1 & ~enc_prev;
    logic start_dec = dec_s1 & ~dec_prev;

    // Core wires
    logic [127:0] data_o;
    logic         core_ready, core_done;

    // Instantiate AES core
    aes128_core #(
        .SBOX_PAR_KEY       (4),
        .SBOX_PAR_ROUND     (16),
        .SBOX_PAR_INV_ROUND (16)
    ) u_core (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_key_i  (load_key),
        .start_enc_i (start_enc),
        .start_dec_i (start_dec),
        .data_i      (text_i),
        .data_o      (data_o),
        .ready_o     (core_ready),
        .done_o      (core_done)
    );

    // Stretch done pulse to ~1 s at 100 MHz for visibility
    logic done_latched;
    logic [26:0] countdown;
    logic [3:0] latched_result;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_latched <= 1'b0;
            countdown    <= 27'd0;
        end else if (core_done) begin
            latched_result <= data_o[3:0];
            done_latched <= 1'b1;
            countdown    <= 27'd100_000_000;  // 1 s @100 MHz
        end else if (done_latched && countdown != 0) begin
            countdown    <= countdown - 1;
            if (countdown == 1)
                done_latched <= 1'b0;
        end
    end

    // Drive outputs
    assign ready_o = core_ready;
    assign done_o  = done_latched;
    assign led     = latched_result;

endmodule
