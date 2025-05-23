`timescale 1ns / 1ps

module tb_shift_rows;
  // Inputs
  logic [127:0] s_i;

  // Outputs
  logic [127:0] s_o_enc;
  logic [127:0] s_o_dec;
 
  // Instantiate MixColumns units
  shift_rows #(.OP(1'b1)) uut_enc (
    .s_i (s_i),
    .s_o (s_o_enc)
  );
    
  shift_rows #(.OP(1'b0)) uut_dec (
    .s_i (s_i),
    .s_o (s_o_dec)
  );

  initial begin
    // Dump waves for visual inspection (optional)
    $dumpfile("tb_shift_rows.vcd");
    $dumpvars(0, tb_shift_rows);

    s_i = 128'h00010203_04050607_08090A0B_0C0D0E0F;

    #1;
    $finish;
  end
endmodule
