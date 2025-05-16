module round_tf (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic bypass_mc,
    input  logic [127:0] b_i,
    output logic [127:0] b_sr_o,
    output logic [127:0] b_o,
    output logic done_o
  );
    
    logic [127:0] b_mc; 

    mix_columns  #(
        .OP(1'b0)
    ) u_mc(
        .b    (b_i),
        .b_mc (b_mc)
    );

 
    logic [127:0] b_sr_in;
    logic [127:0] b_sr;

    always_comb begin
      b_sr_in <= (bypass_mc) b_i ? b_mc;
    end

    shift_rows #(
        .OP(1'b0)
    ) u_sr (
        .b(b_sr_in),
        .b_sr(b_sr)
    );

    assign b_sr_o = b_sr;
    
    sub_bytes #(
      .WIDTH(128),
      .OP(1'b0)
    )  
    u_sbox(
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .b(b_sr),
      .b_sb(b_o),
      .done(done_o)
    );

  endmodule