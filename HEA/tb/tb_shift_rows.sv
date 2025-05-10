`timescale 1ns / 1ps

module tb_shift_rows;
  // Inputs
  logic [127:0] b;

  // Outputs
  logic [127:0] b_sr;
  // Instantiate DUT
  shift_rows uut (
    .b    (b),
    .b_sr (b_sr)
  );

  // Expected value for our test vector
  logic [127:0] expected;

  initial begin
    // Dump waves for visual inspection (optional)
    $dumpfile("shift_rows_tb.vcd");
    $dumpvars(0, tb_shift_rows);

    // Test 1: simple increasing bytes 0x00-0x0F
    b        = 128'h00010203_04050607_08090A0B_0C0D0E0F;
    // After ShiftRows:
    // Row 0 (no shift):    0x00, 0x04, 0x08, 0x0C
    // Row 1 (shift by 1):   0x05, 0x09, 0x0D, 0x01
    // Row 2 (shift by 2):   0x0A, 0x0E, 0x02, 0x06
    // Row 3 (shift by 3):   0x0F, 0x03, 0x07, 0x0B
    expected = 128'h00050A0F_04090E03_080D0207_0C01060B;

    #1;  // let combinational logic settle
    if (b_sr === expected) begin
      $display("PASS: shift_rows output = 0x%032h", b_sr);
    end else begin
      $error("FAIL: shift_rows output = 0x%032h, expected = 0x%032h", b_sr, expected);
    end

    // You can add more randomized or edge-case tests here...
    // e.g., all zeros, all ones, checkerboard pattern, etc.

    #1;
    $finish;
  end
endmodule
