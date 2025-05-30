module round_tf (
    input  logic clk,
    input  logic rst_n,
    input  logic start_i,
    input  logic [127:0] s_i,
    output logic [127:0] s_sr_o,
    output logic [127:0] s_o,
    output logic done_o
  );
  
    logic [127:0] s_sb; // s_sb = in s-box
    
    logic done_reg;

    sub_bytes #(
      .WIDTH(128),
      .OP(1'b1)
    )  
    u_sbox(
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_i),
      .s_i(s_i),
      .s_o(s_sb),
      .done_o(done_reg)
    );
    
    // Added pipe to insure timing 
    always_ff @( posedge clk ) begin
      if (!rst_n) begin
        done_o <= 1'b0;
      end else begin
        done_o <= done_reg;  
      end
    end
    
    logic [127:0] s_sr; 

    shift_rows #(.OP(1'b1)) u_sr(
        .s_i(s_sb),
        .s_o(s_sr)
    );
    
    assign s_sr_o = s_sr;
    
    mix_columns #(.OP(1'b1)) u_mc (
      .s_i (s_sr),
      .s_o (s_o)
    );

  endmodule