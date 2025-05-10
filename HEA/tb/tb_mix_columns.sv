`timescale 1ns / 1ps

import hea_func_pack::*;

module tb_mix_columns;

  // Test inputs and outputs
  logic [127:0] b;
  logic [127:0] b_mc;
  logic [127:0] expected = 128'h6379e6d9f467fb76ad063cf4d2eb8aa3;
  // Instantiate MixColumns unit
  mix_columns uut (
    .b    (b),
    .b_mc(b_mc)
  );

  initial begin
    // Waveform dump
    $dumpfile("tb_mix_columns.vcd");
    $dumpvars(0, tb_mix_columns);

    // Test vector 1: all zeros
    b = 128'h63fcac161bee28c3c4c193f54b8233ea;
    #10;
    $display("Input   = 0x%032h", b);
    $display("Output  = 0x%032h", b_mc);
    $display("expect  = 0x%032h", expected);

    assert (b_mc == expected)  else $error("Failed Mix Columns");

    $finish;
  end

endmodule
