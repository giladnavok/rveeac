`timescale 1ns / 1ps

module sub_bytes_tb;

  // Clock & Reset
  logic clk;
  logic rst_n;

  // DUT I/O
  logic [127:0] s_i;
  logic start;
  logic [127:0] s_o;
  logic done;
  logic [127:0] expected=128'h638293c31bfc33f5c4eeacea4bc12816;
  
  // Instantiate SubBytes module
  sub_bytes uut (
    .clk    (clk),
    .rst_n  (rst_n),
    .s_i    (s_i),
    .start_i(start),
    .s_o    (s_o),
    .done_o (done)
  );

  // Clock generation: 100 MHz
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // Dump waves
    $dumpfile("sub_bytes_tb.vcd");
    $dumpvars(0, sub_bytes_tb);

    // Initialize
    rst_n = 0;
    start = 0;
    s_i   = 128'h0;
    #20;
    rst_n = 1;

    // Test vector: known plaintext
    s_i = 128'h00112233445566778899aabbccddeeff;

    // Pulse start
    @(posedge clk);
    start = 1;
    @(posedge clk);
    start = 0;

    // Wait for 17 cycles (16 bytes + done cycle)
    repeat (20) @(posedge clk);

    assert (s_o == expected)

    // Display results
    $display("Input State : 0x%032h", s_i);
    $display("SubBytes Out: 0x%032h", s_o);

    $finish;
  end

endmodule
