//------------------------------------------------------------------------------
// Package: my_package
// Purpose: Collection of common types, parameters, and utility functions
//------------------------------------------------------------------------------
package hea_func_pack;

localparam logic [9:0] round_consts [0:10] = '{
  10'h400,  // 1024
  10'h200,  // 512
  10'h100,  // 256
  10'h080,  // 128
  10'h040,  //  64
  10'h020,  //  32
  10'h010,  //  16
  10'h008,  //   8
  10'h004,  //   4
  10'h002,  //   2
  10'h001   //   1
};

function automatic logic [31:0] rot_word
  (
    input logic [31:0] w
  );
    rot_word =  {w[23:0], w[31:24]};
endfunction


// 4-bit carry-less multiply in GF(2^4) mod x^4+x+1 (0x13)
function automatic logic [3:0] gf16_mul(
  input logic [3:0] a,
  input logic [3:0] b
);
  logic [7:0] prod;
  integer i;
  begin
    prod = 8'h00;
    // schoolbook carry-less multiply
    for (i = 0; i < 4; i = i + 1) begin
      if (b[i])
        prod = prod ^ (a << i);
    end
    // reduce mod x^4 + x + 1 (0x13)
    for (i = 7; i >= 4; i = i - 1) begin
      if (prod[i])
        prod = prod ^ (8'h13 << (i - 4));
    end
    gf16_mul = prod[3:0];
  end
endfunction

function logic [7:0] gfmul2(
  input logic [7:0] b
);
  gfmul2 = {b[6:0],1'b0} ^ (8'h1B & {8{b[7]}});
endfunction

function logic [7:0] gfmul3(
  input logic [7:0] b
);
  gfmul3 = {b[6:0],1'b0} ^ (8'h1B & {8{b[7]}}) ^ b;
endfunction

endpackage : hea_func_pack