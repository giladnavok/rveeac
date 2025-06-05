`timescale 1ns/1ps

module tb_aes128_core;
    // Clock & reset
    logic clk;
    logic rst_n;

    // Control signals
    logic        load_key_i;
    logic        start_enc_i;
    logic        start_dec_i;

    // Data bus
    logic [127:0] data_i;
    logic [127:0] data_o;

    // Status outputs from DUT
    logic ready_o;
    logic done_o;

    // Instantiate the DUT
    aes128_core dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .load_key_i  (load_key_i),
        .start_enc_i (start_enc_i),
        .start_dec_i (start_dec_i),
        .data_i      (data_i),
        .data_o      (data_o),
        .ready_o     (ready_o),
        .done_o      (done_o)
    );

    //--------------------------------------------------------------------------
    // Clock generation: 100 MHz → period = 10 ns
    //--------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    //--------------------------------------------------------------------------
    // Test vectors (NIST AES‐128)
    //--------------------------------------------------------------------------
    // 128‐bit key: 00 01 02 … 0e 0f
    localparam logic [127:0] KEY         = 128'h000102030405060708090a0b0c0d0e0f;
    // 128‐bit plaintext: 00 11 22 … ee ff
    localparam logic [127:0] PLAINTEXT   = 128'h00112233445566778899aabbccddeeff;
    // Expected AES‐128 ciphertext for above key/plaintext
    localparam logic [127:0] EXP_CIPHERTEXT = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;

    //--------------------------------------------------------------------------
    // Reset + stimulus sequence
    //--------------------------------------------------------------------------
    initial begin
        // Initialize inputs
        rst_n        = 1'b0;
        load_key_i   = 1'b0;
        start_enc_i  = 1'b0;
        start_dec_i  = 1'b0;
        data_i       = 128'b0;

        // Wait for a few cycles, then deassert reset
        #20;
        rst_n = 1'b1;

        // Wait until DUT reports ready_o = 1 (both encryption/decryption units idle)
        wait (ready_o == 1'b1);

        //--------------------------------------------------------------------------
        // 1) Load the key
        //--------------------------------------------------------------------------
        @(posedge clk);
        data_i     = KEY;
        load_key_i = 1'b1;
        @(posedge clk);
        load_key_i = 1'b0;
        // Give a couple cycles for key to be registered internally
        repeat (2) @(posedge clk);

        //--------------------------------------------------------------------------
        // 2) Start encryption with PLAINTEXT
        //--------------------------------------------------------------------------
        @(posedge clk);
        data_i      = PLAINTEXT;
        start_enc_i = 1'b1;
        @(posedge clk);
        start_enc_i = 1'b0;

        // Wait for done_o (encryption done)
        wait (done_o == 1'b1);
        @(posedge clk);  // capture data_o on next clock

//        $display("[%0t] Encryption done. "
//                 "Output ciphertext = 0x%032h  (expected 0x%032h)",
//                 $time, data_o, EXP_CIPHERTEXT);

        // Sanity check (optional):
        if (data_o !== EXP_CIPHERTEXT) begin
            $error("[%0t] ERROR: ciphertext mismatch!", $time);
        end else begin
            $display("[%0t] Ciphertext matches expected value.", $time);
        end

        //--------------------------------------------------------------------------
        // 3) Start decryption with the ciphertext just produced
        //--------------------------------------------------------------------------
        @(posedge clk);
        data_i       = data_o;
        start_dec_i  = 1'b1;
        @(posedge clk);
        start_dec_i  = 1'b0;

        // Wait for done_o (decryption done)
        wait (done_o == 1'b1);
        @(posedge clk);  // capture decrypted data_o

//        $display("[%0t] Decryption done. "
//                 "Output plaintext = 0x%032h  (expected 0x%032h)",
//                 $time, data_o, PLAINTEXT);

        // Sanity check (optional):
        if (data_o !== PLAINTEXT) begin
            $error("[%0t] ERROR: decrypted plaintext mismatch!", $time);
        end else begin
            $display("[%0t] Decrypted plaintext matches original.", $time);
        end

        // Finish simulation
        #10;
        $display("[%0t] Testbench complete.", $time);
        $finish;
    end

    //--------------------------------------------------------------------------
    // Optional: Monitor ready_o and done_o
    //--------------------------------------------------------------------------
    initial begin
        $display("Time\tready_o\tdone_o");
        $monitor("%0t\t%b\t%b", $time, ready_o, done_o);
    end

endmodule
