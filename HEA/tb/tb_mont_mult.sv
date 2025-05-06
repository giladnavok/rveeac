`timescale 1ns / 1ps

module tb_mont_mult;
  // Parameter for data-path width
  localparam int WIDTH = 64;

  // Clock and reset
  logic clk = 0;
  always #5 clk = ~clk;    // 100 MHz clock
  logic rst_n;

  // DUT inputs
  logic                     start;
  logic [WIDTH-1:0]         N;
  logic [WIDTH-1:0]         N_PRIME;
  logic [WIDTH-1:0]         X;
  logic [WIDTH-1:0]         Y;

  // DUT outputs
  logic [WIDTH-1:0]         Z;
  logic                     done;
  
  // DUT test output
  logic [7:0] cnt;

  // Instantiate the Montgomery multiplier with small WIDTH for testing
  mont_mult #(
    .WIDTH(WIDTH)
  ) uut (
    .clk     (clk),
    .rst_n   (rst_n),
    .start_i (start),
    .N       (N),
    .N_prime (N_PRIME),
    .x_i     (X),
    .y_i     (Y),
    .z_o     (Z),
    .done_o  (done),
    .cnt_o(cnt)
  );

  initial begin
    // Waveform dump
    $dumpfile("tb_mont_mult.vcd");
    $dumpvars(0, tb_mont_mult);

    // Initialize
    rst_n  = 0;
    start  = 0;
    N      = 4'h7;    // modulus
    N_PRIME= 4'h9;    // -N^{-1} mod 16
    X      = 4'h3;    // operand X
    Y      = 4'h5;    // operand Y

    // Release reset after a few cycles
    #20;
    rst_n = 1;

    // Wait one clock
    @(posedge clk);

    // Start the multiplication
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait for completion
    wait (done == 1);
    
    #10;    
    
    // Display results
    $display("Test vector: X=0x%0h, Y=0x%0h, N=0x%0h", X, Y, N);
    $display("Montgomery product Z = 0x%0h", Z);
    // Expected Z = X*Y*R^{-1} mod N = 3*5*4 mod 7 = 60 mod 7 = 4
    $display("Expected Z = 0x4");

    $finish;
  end
endmodule
