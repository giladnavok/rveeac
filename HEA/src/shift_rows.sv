`timescale 1ns / 1ps
module shift_rows (
    input  logic [127:0] b,
    output logic [127:0] b_sr
  );
    // break state into bytes s[0]…s[15]
    logic [7:0] s [0:15];
  
    // unpack
    genvar i;
    for (i = 0; i < 16; i++) begin
      assign s[i] = b[8*i +: 8];
    end
  
    // apply shifts: row r bytes are at positions 4*r + c
    assign b_sr = {
      s[0],  s[5],  s[10], s[15],
      s[4],  s[9],  s[14], s[3],
      s[8],  s[13], s[2],  s[7],
      s[12], s[1],  s[6],  s[11]
    };
    
  endmodule
