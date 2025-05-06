import typedefs::*;

localparam N_FUZZ = 200000;

module tb_alu_sbm;

cs_alu_op op;
logic clk;
logic rst_n;
logic flip;
logic cmp_result;
logic first_cycle;
logic cmp_result_valid;
logic [15:0] ah;
logic [15:0] bh;
logic [15:0] outh;
logic [31:0] A;
logic [31:0] B;
logic [31:0] C;
logic shift_bigger_then_16;
int out;
int flip_half_order;
int flip_out_half_order;
logic [31:0] exp;

task automatic serialize(
	input cs_alu_op op,
	input logic [31:0] A, 
	input logic [31:0] B,
	ref logic [15:0] outh,
	ref logic clk,
	ref logic [15:0] ah,
	ref logic [15:0] bh,
	ref logic first_cycle,
	ref logic shift_bigger_then_16,
	ref int out,
	int flip_half_order,
	int flip_out_half_order
);
	out = '0;
	first_cycle = 1'b1;
	clk = 1'b0;
	if (flip_half_order) begin
		ah = A[31:16];
		bh = B[31:16];
	end else begin
		ah = A[15:0];
		bh = B[15:0];
	end
	#1;
	if (flip_half_order | flip_out_half_order) begin
		out = (outh << 16);
	end else begin
		out = outh;
	end
	if (op inside {ALU_OP_EQ, ALU_OP_LT, ALU_OP_LTU} && cmp_result_valid) begin
		assert (cmp_result == exp);
	end
	#1 clk = ~clk;
	#2 clk = ~clk;

	first_cycle = 1'b0;
	if (!shift_bigger_then_16) begin
		if (flip_half_order) begin
			ah = A[15:0];
			bh = B[15:0];
		end else begin
			ah = A[31:16];
			bh = B[31:16];
		end
	end
	#1;
	if (flip_half_order | flip_out_half_order) begin
		out |= outh;
	end else begin
		out |= (outh << 16);
	end
	if (op inside {ALU_OP_EQ, ALU_OP_LT, ALU_OP_LTU}) begin
		assert (cmp_result_valid == 1'b1);
		assert (cmp_result == out[0]);
		assert (cmp_result == exp);
	end
	#1 clk = ~clk;
	#2 clk = ~clk;
	first_cycle = 1'b1;
endtask


alu_sbm 
alu (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(first_cycle),
	.op_i(op),
	.cmp_flip_i(flip),

		
	.a_i(ah),
	.b_i(bh),

	.result_o(outh),
	.cmp_result_o(cmp_result),
	.cmp_result_valid_o(cmp_result_valid),
	.shift_bigger_then_16_o(shift_bigger_then_16)
);


initial begin
	rst_n = 1'b0;
	flip = '0;
	first_cycle = '0;
	ah = '0;
	bh = '0;
	clk = '0;
	flip_half_order = '0;
	flip_out_half_order = '0;
	#1 rst_n = 1'b1;
	repeat (N_FUZZ) begin
		//A = -1206952848;
		//B = -1206929393;
		//A = -1321271710;
		//B = -1321291458;
		//A = 32'h7fff1000;
		//B = 32'h7fff0000;
		A = $random;
		B = $random;
		flip_half_order = '0;
		flip_out_half_order = '0;
		#1 op = ALU_OP_ADD;
		exp = A+B;
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_SUB;
		exp = A-B;
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_AND;
		exp = A&B;
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);
		
		#1 op = ALU_OP_OR;
		exp = A|B;
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);
		B[31:16] = B[15:0];

		#1 op = ALU_OP_SLL;
		exp = A<<B[4:0];
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);
		flip_half_order = 1;
		
		#1 op = ALU_OP_SRL;
		exp = A>>B[4:0];
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_SRA;
		exp = $signed(A)>>>B[4:0];
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		flip_half_order = 1;
		flip_out_half_order = 1;
		#1 op = ALU_OP_EQ; flip = 1'b0;
		C = ($random % 4) ? B : A;
		exp = A==C;
		serialize(op, A, C, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_EQ; flip = 1'b1;
		exp = A!=C;
		serialize(op, A, C, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_LT; flip = 1'b0;
		if ($random % 4) begin
			A[31:15] = B[31:15];
		end
		exp = $signed(A) < $signed(B);
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_LT; flip = 1'b1;
		exp = $signed(A) >= $signed(B);
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_LTU; flip = 1'b0;
		exp = $unsigned(A) < $unsigned(B);
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);

		#1 op = ALU_OP_LTU; flip = 1'b1;
		exp = $unsigned(A) >= $unsigned(B);
		serialize(op, A, B, outh, clk, ah, bh, first_cycle, shift_bigger_then_16, out, flip_half_order, flip_out_half_order);
		#1 assert (out == exp);
	end
end


endmodule
