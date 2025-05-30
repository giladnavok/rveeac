module round_key_tf #( 
    parameter bit EN_MC = 1 // enable mix columns
  )(
    input  logic clk,
    input  logic rst_n,
    input  logic start_i,
    input  logic [127:0] key_i,
    input  logic [3:0]   round_count_i,
    output logic [127:0] key_o,
    output logic done_o
  );
  
  // 32-bit Rcon words
  localparam logic [31:0] RCON [0:9] = '{32'h01000000, 32'h02000000, 32'h04000000, 32'h08000000,
                                         32'h10000000, 32'h20000000, 32'h40000000, 32'h80000000,
                                         32'h1b000000, 32'h36000000
  };

    logic [31:0] w [3:0];
    logic [31:0] w_tf [3:0];
    logic done_reg;

    // unpack key_i into w[0]…w[3]
    genvar i;
    for (i = 0; i < 4; i++) begin
      assign w[i] = key_i[127 - 32*i -: 32];
    end
    
    // schedule core
    logic [31:0] rot_w , sb_w;

    assign rot_w = {w[3][23:0],w[3][31:24]};

    sub_bytes #(
      .WIDTH(32),
      .OP(1'b1)
    ) u_sbox (
      .clk(clk),
      .rst_n(rst_n),
      .start_i(start_i),
      .s_i(rot_w),
      .s_o(sb_w),
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

    // Check Timing here, may need to split into stages
    assign w_tf[0] = w[0] ^ sb_w ^ RCON[round_count_i];
    assign w_tf[1] = w[1] ^ w_tf[0];
    assign w_tf[2] = w[2] ^ w_tf[1];
    assign w_tf[3] = w[3] ^ w_tf[2];
    
    assign key_o = {w_tf[0], w_tf[1], w_tf[2], w_tf[3]};

  endmodule