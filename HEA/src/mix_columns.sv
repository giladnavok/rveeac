`timescale 1ns / 1ps

import hea_func_pack::*;

module mix_columns (
  input  logic [127:0] b,
  output logic [127:0] b_mc
);
  logic [7:0] s_in  [0:15];
  logic [7:0] s_out [0:15];

  // unpack bytes
  genvar i;
  for (i = 0; i < 16; i++) begin
    assign s_in[i] = b[8*i +: 8];
  end

  // operate on each of the 4 columns
  genvar c;
  for (c = 0; c < 4; c++) begin : COL
    // local “nets” for this column
    logic [7:0] a0, a1, a2, a3;

    // continuous wiring from s_in[]
    assign a0 = s_in[4*c + 0];
    assign a1 = s_in[4*c + 1];
    assign a2 = s_in[4*c + 2];
    assign a3 = s_in[4*c + 3];

    assign s_out[4*c + 0] = gfmul2(a0) ^ gfmul3(a1) ^ a2       ^ a3;
    assign s_out[4*c + 1] = a0       ^ gfmul2(a1) ^ gfmul3(a2) ^ a3;
    assign s_out[4*c + 2] = a0       ^ a1       ^ gfmul2(a2) ^ gfmul3(a3);
    assign s_out[4*c + 3] = gfmul3(a0) ^ a1       ^ a2       ^ gfmul2(a3);
  end

  // pack back to 128-bit state
  for (i = 0; i < 16; i++) begin
    assign b_mc[8*i +: 8] = s_out[i];
  end
endmodule
