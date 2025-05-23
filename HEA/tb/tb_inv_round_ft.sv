`timescale 1ns / 1ps

module tb_inv_round_tf;

  // Clock & Reset
  logic clk;
  logic rst_n;
  logic start;
  logic done;
  
  // Test inputs
  logic [127:0] s_i;

  logic [127:0] s_sr;
  logic [127:0] s_o;
  
  // Clock generation: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // Instantiate with MixColumns enabled
  inv_round_tf uut_en (
    .clk        (clk),
    .rst_n      (rst_n),
    .start_i    (start),
    .s_i        (s_i),
    .bypass_mc_i(1'b0),
    .s_o        (s_o),
    .done_o     (done)
  );

  initial begin
    // Dump waves
    $dumpfile("tb_inv_round_tf.vcd");
    $dumpvars(0, tb_inv_round_tf);
    
    // Initialize
    rst_n = 0;
    start = 0;
    s_i   = 128'h0;
    #20;
    rst_n = 1;

    // Test vector 1
    s_i = 128'h00112233445566778899aabbccddeeff;
    
    // Pulse start
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;
    
    // Wait for completion
    wait (done == 1'b1);    
    repeat (5) @(posedge clk);
    
    $finish;
  end

endmodule
