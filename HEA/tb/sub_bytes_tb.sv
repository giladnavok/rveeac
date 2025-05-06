`timescale 1ns / 1ps

module sub_bytes_tb;

  // 200 MHz clock generation (period = 5 ns)
  logic clk = 0;
  always #2.5 clk = ~clk;

  // DUT inputs
  logic [7:0] b;
  // DUT outputs
  logic [7:0] sb;

  // Instantiate Device Under Test (DUT)
  sub_bytes uut (
    .b   (b),
    .sb  (sb)
  );

  // Waveform dump for post-simulation analysis
  initial begin
    $dumpfile("tb_sub_bytes.vcd");
    $dumpvars(0, sub_bytes_tb);
  end

  // Test stimulus
  initial begin
    // Wait a few cycles for initialization
    #10;

    // Test vector 1
    b = 8'h00; #10;
    $display("b = 0x%0h, sb = 0x%0h", b, sb);

    // Test vector 2
    b = 8'h53; #10;
    $display("b = 0x%0h, sb = 0x%0h", b, sb);

    // Test vector 3
    b = 8'hFF; #10;
    $display("b = 0x%0h, sb = 0x%0h", b, sb);

    // Add more test vectors as needed

    $display("Testbench complete.");
    $finish;
  end

endmodule
