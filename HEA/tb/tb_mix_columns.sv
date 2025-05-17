`timescale 1ns / 1ps

import hea_func_pack::*;

module tb_mix_columns;

  // Test inputs and outputs
  logic [127:0] b;
  logic [127:0] b_mc_enc;
  logic [127:0] b_mc_dec;
  
  // Instantiate MixColumns units
  mix_columns #(.OP(1'b1)) uut_enc (
    .b    (b),
    .b_mc(b_mc_enc)
  );
    
  mix_columns #(.OP(1'b0)) uut_dec (
    .b    (b),
    .b_mc(b_mc_dec)
  );

  initial begin
    // Waveform dump
    $dumpfile("tb_mix_columns.vcd");
    $dumpvars(0, tb_mix_columns);

    // Test vector 1: all zeros
    b = 128'h63fcac161bee28c3c4c193f54b8233ea;
    #10;
    $display("Input   = 0x%032h", b);
    $display("Output Enc  = 0x%032h", b_mc_enc);
    $display("Output Dec  = 0x%032h", b_mc_dec);

    $finish;
  end

endmodule
