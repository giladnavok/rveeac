module shift_rows #( 
    parameter bit OP = 1 // 1 - Encrypt , 0 - Decrypt
  )(
    input  logic [127:0] s_i,
    output logic [127:0] s_o
  );
    // break state into bytes s[0]…s[15]
    logic [7:0] b [0:15];
  
    // unpack : MSB if first Byte s[0], LSB is the last Byte s[15]
    genvar i;
    for (i = 0; i < 16; i++) begin
      assign b[i] = s_i[8*(15-i) +: 8];
    end
    
    // apply shifts: row r bytes are at positions 4*r + c
    if (OP) begin // Encrypt
      assign s_o =  { b[0] ,b[5] ,b[10],b[15],
                      b[4] ,b[9] ,b[14],b[3],
                      b[8] ,b[13],b[2] ,b[7],
                      b[12],b[1] ,b[6] ,b[11]};
    end else begin // Decrypt
      assign s_o =  { b[0] ,b[13],b[10],b[7],
                      b[4] ,b[1] ,b[14],b[11],
                      b[8] ,b[5] ,b[2] ,b[15],
                      b[12],b[9] ,b[6] ,b[3]};
    end
 
  endmodule
