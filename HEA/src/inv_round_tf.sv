module inv_round_tf (
    input  logic clk,
    input  logic rst_n,
    input  logic start_i,
    input  logic bypass_mc_i,
    input  logic [127:0] s_i,
    output logic [127:0] s_o,
    output logic done_o
  );
    
    logic [127:0] s_mc; 
    logic [127:0] s_sr_in;
    logic [127:0] s_sr_out_reg;
    
    mix_columns  #(
        .OP(1'b0)
    ) u_mc(
        .s_i (s_i),
        .s_o (s_mc)
    );


    assign s_sr_in = (bypass_mc_i) ? s_i : s_mc;

    shift_rows #(
        .OP(1'b0)
    ) u_sr (
        .s_i(s_sr_in),
        .s_o(s_sr_out_reg)
    );
    
    // In case of timing problems add a pipe after the sub bytes

    sub_bytes #(
      .WIDTH(128),
      .OP(1'b0)
    )  u_sbox(
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_i),
      .s_i(s_sr_out_reg),
      .s_o(s_o),
      .done_o(done_o)
    );

  endmodule