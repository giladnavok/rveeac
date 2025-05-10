module round_tf #( 
    parameter bit EN_MC = 1 // enable mix columns
  )(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic [127:0] b_i,
    output logic [127:0] b_sb_o,
    output logic [127:0] b_sr_o,
    output logic [127:0] b_o,
    output logic done_o
  );
  
    logic [127:0] b_sb; // b_sb = in s-box
    
    sub_bytes u_sbox(
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .b(b_i),
      .b_sb(b_sb),
      .done(done_o)
    );
    
    assign b_sb_o = b_sb;
    
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