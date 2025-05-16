//------------------------------------------------------------------------------
// Package: my_package
// Purpose: Collection of common types, parameters, and utility functions
//------------------------------------------------------------------------------
package hea_func_pack;

function logic [7:0] gfmul2(
  input logic [7:0] b
);
  gfmul2 = {b[6:0],1'b0} ^ (8'h1B & {8{b[7]}});
endfunction

function logic [7:0] gfmul3(
  input logic [7:0] b
);
  gfmul3 = gfmul2(b) ^ b;
endfunction

// helper for 4×: two 2× in GF(2^8)
function logic [7:0] gfmul4(input logic [7:0] b);
  gfmul4 = gfmul2(gfmul2(b));
endfunction

// helper for 8×: 2× applied to 4×
function logic [7:0] gfmul8(input logic [7:0] b);
  gfmul8 = gfmul2(gfmul4(b));
endfunction

// 9× = 8× ⊕ 1×
function logic [7:0] gfmul9(input logic [7:0] b);
  gfmul9 = gfmul8(b) ^ b;
endfunction

// 11× = 8× ⊕ 2× ⊕ 1×
function logic [7:0] gfmul11(input logic [7:0] b);
  gfmul11 = gfmul8(b) ^ gfmul2(b) ^ b;
endfunction

// 13× = 8× ⊕ 4× ⊕ 1×
function logic [7:0] gfmul13(input logic [7:0] b);
  gfmul13 = gfmul8(b) ^ gfmul4(b) ^ b;
endfunction

// 14× = 8× ⊕ 4× ⊕ 2×
function logic [7:0] gfmul14(input logic [7:0] b);
  gfmul14 = gfmul8(b) ^ gfmul4(b) ^ gfmul2(b);
endfunction

endpackage : hea_func_pack