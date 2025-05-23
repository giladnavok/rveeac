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
  input  logic [127:0] s_i,
  output logic [127:0] s_o
);
  logic [7:0] b_in  [0:15];
  logic [7:0] b_out [0:15];

  // unpack bytes
  genvar i;
  for (i = 0; i < 16; i++) begin
    assign b_in[i] = s_i[8*(15-i) +: 8];
  end

  // operate on each of the 4 columns
  genvar c;
  for (c = 0; c < 4; c++) begin 
  
    logic [7:0] b0, b1, b2, b3;

    // continuous wiring from b_in[]
    assign b0 = b_in[4*c + 0];
    assign b1 = b_in[4*c + 1];
    assign b2 = b_in[4*c + 2];
    assign b3 = b_in[4*c + 3];

    if (OP) begin // Encrypt

      assign b_out[4*c + 0] = gfmul2(b0) ^ gfmul3(b1) ^ b2         ^ b3;
      assign b_out[4*c + 1] = b0         ^ gfmul2(b1) ^ gfmul3(b2) ^ b3;
      assign b_out[4*c + 2] = b0         ^ b1         ^ gfmul2(b2) ^ gfmul3(b3);
      assign b_out[4*c + 3] = gfmul3(b0) ^ b1         ^ b2         ^ gfmul2(b3);

    end else begin // Decrypt

      assign b_out[4*c + 0] = gfmul14(b0) ^ gfmul11(b1)  ^ gfmul13(b2)  ^ gfmul9(b3);
      assign b_out[4*c + 1] = gfmul9(b0)  ^ gfmul14(b1)  ^ gfmul11(b2)  ^ gfmul13(b3);
      assign b_out[4*c + 2] = gfmul13(b0) ^ gfmul9(b1)   ^ gfmul14(b2)  ^ gfmul11(b3);
      assign b_out[4*c + 3] = gfmul11(b0) ^ gfmul13(b1)  ^ gfmul9(b2)   ^ gfmul14(b3);

    end

  end

  // pack back to 128-bit state
  for (i = 0; i < 16; i++) begin
    assign s_o[8*(15-i) +: 8] = b_out[i];
  end
endmodule
