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
  gfmul3 = {b[6:0],1'b0} ^ (8'h1B & {8{b[7]}}) ^ b;
endfunction

endpackage : hea_func_pack