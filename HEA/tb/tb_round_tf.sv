`timescale 1ns / 1ps

module tb_round_tf;

  // Clock & Reset
  logic clk;
  logic rst_n;
  logic start;
  logic done;
  
  // Test inputs
  logic [127:0] s_i;

  logic [127:0] s_sr;
  logic [127:0] s_o;
  
  logic [127:0] expected_sb = 128'h638293c31bfc33f5c4eeacea4bc12816;
  logic [127:0] expected_sr = 128'h63fcac161bee28c3c4c193f54b8233ea;
  logic [127:0] expected_mc = 128'h6379e6d9f467fb76ad063cf4d2eb8aa3;
  
  // Clock generation: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  // Instantiate with MixColumns enabled
  round_tf uut (
    .clk(clk),
    .rst_n(rst_n),
    .start_i(start),
    .s_i    (s_i),
    // .b_sb_o (b_sb),
    .s_sr_o (s_sr),
    .s_o    (s_o),
    .done_o(done)
  );

  initial begin
    // Dump waves
    $dumpfile("tb_round_tf.vcd");
    $dumpvars(0, tb_round_tf);
    
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
    repeat (2) @(posedge clk);

    // assert (b_sb == expected_sb) else $error("Failed S-Box");
    // assert (b_sr == expected_sr) else $error("Failed Shift Rows");
    // assert (b_o == expected_mc)  else $error("Failed Mix Columns");
    
    $finish;
  end

endmodule
