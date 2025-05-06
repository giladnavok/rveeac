`timescale 1ns / 1ps

import hea_func_pack::*;

module tb_mix_columns;

  // Test inputs and outputs
  logic [127:0] b;
  logic [127:0] b_mc;

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
    b = 128'h0000_0000_0000_0000_0000_0000_0000_0000;
    #10;
    $display("Input   = 0x%032h", b);
    $display("Output  = 0x%032h", b_mc);

    // Test vector 2: AES sample column (FIPS-A.1)
    b = 128'hd4bf5d30_e0b452ae_b84111f1_1e2798e5;
    #10;
    $display("Input   = 0x%032h", b);
    $display("Output  = 0x%032h", b_mc);

    $finish;
  end

endmodule
