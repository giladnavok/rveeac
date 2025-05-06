module round_tf #( 
    parameter bit EN_MC = 1 // enable mix columns
  )(
    input  logic [127:0] b_i,
    output logic [127:0] b_sr_o,
    output logic [127:0] b_o
  );
    logic [127:0] b_sb; // b_sb = in s-box
  
    genvar i;
    generate
      for (i = 0; i < 16; i++) begin
        sub_bytes u_sbox(
          .b(b_i[8*(15-i) +: 8]),
          .b_sb(b_sb[8*(15-i) +: 8])
        );
      end
    endgenerate

    logic [127:0] b_sr; // b_sr = b_sb shift rows
    shift_rows u_sr(
        .b(b_sb),
        .b_sr(b_sr)
    );

    assign b_sr_o = b_sr;
    
    generate
      if (EN_MC) begin
        mix_columns u_mc (
          .b    (b_sr),
          .b_mc (b_o)
        );
      end else begin : MC_BYPASS
        assign b_o = b_sr;
      end
    endgenerate

  endmodule