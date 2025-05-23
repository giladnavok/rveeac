`timescale 1ns / 1ps

import hea_func_pack::*;

module tb_mix_columns;

  // Test inputs and outputs
  logic [127:0] s_i;
  logic [127:0] s_o_enc;
  logic [127:0] s_o_dec;
  
  // Instantiate MixColumns units
  mix_columns #(.OP(1'b1)) uut_enc (
    .s_i (s_i),
    .s_o (s_o_enc)
  );
    
  mix_columns #(.OP(1'b0)) uut_dec (
    .s_i (s_i),
    .s_o (s_o_dec)
  );

  initial begin
    // Waveform dump
    $dumpfile("tb_mix_columns.vcd");
    $dumpvars(0, tb_mix_columns);

    // Test vector 1: all zeros
    s_i = 128'h63fcac161bee28c3c4c193f54b8233ea;
    #10;
    $display("Input   = 0x%032h", s_i);
    $display("Output Enc  = 0x%032h", s_o_enc);
    $display("Output Dec  = 0x%032h", s_o_dec);

    $finish;
  end

endmodule
