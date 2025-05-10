`timescale 1ns / 1ps

module tb_round_key_tf;
  // Clock and reset
  logic clk;
  logic rst_n;

  // DUT inputs
  logic        start;
  logic [127:0] key_i;
  logic [3:0]  round_count_i;

  // DUT outputs
  logic [127:0] key_o;
  logic        done_o;

  // Instantiate Device Under Test
  round_key_tf dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .key_i(key_i),
    .round_count_i(round_count_i),
    .key_o(key_o),
    .done_o(done_o)
  );

  // Clock generation: 100 MHz => 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    // Initial values
    rst_n           = 0;
    start           = 0;
    key_i           = 128'h2b7e151628aed2a6abf7158809cf4f3c; // Example master key
    round_count_i   = 4'd1;

    // Apply reset
    #20;
    rst_n = 1;
    #20;

    // First round key generation
    start = 1;
    #10;
    start = 0;
    #10;
    wait (done_o == 1'b1);
    $display("Round %0d key: %h", round_count_i, key_o);

    // Generate rounds 2 through 10 by chaining
    for (int i = 2; i <= 10; i++) begin
      key_i         = key_o;
      round_count_i = i;
      #10;
      start = 1;
      #10;
      start = 0;
      #10;

      wait (done_o == 1'b1);
      $display("Round %0d key: %h", round_count_i, key_o);
    end

    // Finish simulation
    #20;
    $finish;
  end

endmodule
