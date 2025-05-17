`timescale 1ns / 1ps

module tb_aes128_core;

    // Clock and reset
    logic clk = 0;
    always #5 clk = ~clk;

    logic rst_n;

    // Control signals
    logic start_enc_i;
    logic start_dec_i;

    // Data signals
    logic [127:0] key_i;
    logic [127:0] text_i;
    logic [127:0] text_o;
    logic ready_o;
    logic done_o;

    // Instantiate AES core
    aes128_core uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .start_enc_i   (start_enc_i),
        .start_dec_i   (start_dec_i),
        .key_i         (key_i),
        .text_i        (text_i),
        .text_o        (text_o),
        .ready_o       (ready_o),
        .done_o        (done_o)
    );

    initial begin
        // Initialize signals
        rst_n = 0;
        start_enc_i = 0;
        start_dec_i = 0;

        // Test vector from AES specification
        key_i  = 128'h2b7e151628aed2a6abf7158809cf4f3c;
        text_i = 128'h3243f6a8885a308d313198a2e0370734;

        // Release reset
        #20;
        rst_n = 1;

        // --- Encryption ---
        @(posedge clk);
        start_enc_i = 1;
        @(posedge clk);
        start_enc_i = 0;

        // Wait for encryption to complete
        wait (done_o == 1);
        $display("Encryption result: %h", text_o);
        assert (text_o == 128'h3925841d02dc09fbdc118597196a0b32) else begin
            $error("Encryption failed: expected 3925841d02dc09fbdc118597196a0b32, got %h", text_o);
        end

        // --- Decryption ---
        text_i = text_o;
        @(posedge clk);
        start_dec_i = 1;
        @(posedge clk);
        start_dec_i = 0;

        // Wait for decryption to complete
        wait (done_o == 1);
        $display("Decryption result: %h", text_o);
        assert (text_o == 128'h3243f6a8885a308d313198a2e0370734) else begin
            $error("Decryption failed: expected 3243f6a8885a308d313198a2e0370734, got %h", text_o);
        end

        $display("AES core encrypt-decrypt test PASSED");
        $finish;
    end

endmodule
