`timescale 1ns / 1ps

import hea_func_pack::*;

/*
  Encryption:
    |d0|    |2 3 1 1] |b0|
    |d1|    |1 2 3 1| |b1|
    |d2|  = |1 1 2 3| |b2| 
    |d3|    |3 1 1 2| |b3|
*/

/*
  Decryption:
    |d0|    |14 11 13 9| |b0|
    |d1|    |9 14 11 13| |b1|
    |d2|  = |13 9 14 11| |b2| 
    |d3|    |11 13 9 14| |b3|
*/
module mix_columns #( 
    parameter bit OP = 1 // 1 - Encrypt , 0 - Decrypt
)(
  input  logic [127:0] b,
  output logic [127:0] b_mc
);
  logic [7:0] s_in  [0:15];
  logic [7:0] s_out [0:15];

  // unpack bytes
  genvar i;
  for (i = 0; i < 16; i++) begin
    assign s_in[i] = b[8*(15-i) +: 8];
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

    if (OP) begin // Encrypt

      assign s_out[4*c + 0] = gfmul2(a0) ^ gfmul3(a1) ^ a2         ^ a3;
      assign s_out[4*c + 1] = a0         ^ gfmul2(a1) ^ gfmul3(a2) ^ a3;
      assign s_out[4*c + 2] = a0         ^ a1         ^ gfmul2(a2) ^ gfmul3(a3);
      assign s_out[4*c + 3] = gfmul3(a0) ^ a1         ^ a2         ^ gfmul2(a3);

    end else begin // Decrypt

      assign s_out[4*c + 0] = gfmul14(a0) ^ gfmul11(a1)  ^ gfmul13(a2)  ^ gfmul9(a3);
      assign s_out[4*c + 1] = gfmul9(a0)  ^ gfmul14(a1)  ^ gfmul11(a2)  ^ gfmul13(a3);
      assign s_out[4*c + 2] = gfmul13(a0) ^ gfmul9(a1)   ^ gfmul14(a2)  ^ gfmul11(a3);
      assign s_out[4*c + 3] = gfmul11(a0) ^ gfmul13(a1)  ^ gfmul9(a2)   ^ gfmul14(a3);

    end

  end

  // pack back to 128-bit state
  for (i = 0; i < 16; i++) begin
    assign b_mc[8*(15-i) +: 8] = s_out[i];
  end
endmodule
