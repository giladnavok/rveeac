`timescale 1ns / 1ps

module tb_round_tf;

  // Test inputs
  logic [127:0] b_i;

  // Outputs for EN_MC = 1 (MixColumns enabled)
  logic [127:0] b_sr_en;
  logic [127:0] b_o_en;

  // Outputs for EN_MC = 0 (MixColumns bypass)
  logic [127:0] b_sr_bypass;
  logic [127:0] b_o_bypass;

  // Instantiate with MixColumns enabled
  round_tf #(.EN_MC(1)) uut_en (
    .b_i    (b_i),
    .b_sr_o (b_sr_en),
    .b_o    (b_o_en)
  );

  // Instantiate with MixColumns bypassed
  round_tf #(.EN_MC(0)) uut_bp (
    .b_i    (b_i),
    .b_sr_o (b_sr_bypass),
    .b_o    (b_o_bypass)
  );

  initial begin
    // Dump waves
    $dumpfile("tb_round_tf.vcd");
    $dumpvars(0, tb_round_tf);

    // Test vector 1
    b_i = 128'h01234567_89ABCDEF_FEDCBA98_76543210;
    #10;
    $display("Input: 0x%032h", b_i);
    $display("ShiftRows: 0x%032h", b_sr_en);
    $display("With MixColumns: 0x%032h", b_o_en);
    $display("Bypass MixColumns: 0x%032h", b_o_bypass);

    // Add additional test vectors as needed

    $finish;
  end

endmodule
