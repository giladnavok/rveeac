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
    logic start_reg;

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
    
    always_ff @( posedge clk ) begin
      if (!rst_n) begin
        start_reg <= 1'b0;
      end else begin
        start_reg <= start_i;  
      end
    end

    sub_bytes #(
      .WIDTH(128),
      .OP(1'b0)
    )  u_sbox(
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_reg),
      .s_i(s_sr_out_reg),
      .s_o(s_o),
      .done_o(done_o)
    );

  endmodule