import typedefs::*;

module alu_sbm (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,
	input logic first_cycle,

	// Input Controls //
	// -------------- //
		
	input cs_alu_op op_i,
	input cmp_flip_i,

	// Input Data //
	// ---------- //
		
	input logic [15:0] a_i,
	input logic [15:0] b_i,

	// Output Data //
	// ----------- //
		
	
	output logic [15:0] result_o,
	output logic cmp_result_o,
	output logic cmp_result_valid_o
);

// Internal Wires //
// -------------  // 

logic [15:0] 
	add_a, add_b;
logic add_carry_in, adder_used;
logic [16:0] add_out;

logic [15:0] 
	not_in, not_out,
	or_a, or_b, or_out,
	xor_a, xor_b, xor_out,
	and_a, and_b, and_out,
	reverse_a_in, reverse_a_out,
	reverse_b_in, reverse_b_out,
	shift_in, shift_out;
logic [3:0] shift_amount;
logic shift_bigger_then_16, shift_used;
logic [15:0] 
	shift_filler_in, shift_filler_fill, shift_filler_out,
	reduction_or_in;

logic [15:0] shift_filler_combinations [15:0];
logic reduction_or_out;
logic cmp_result_valid;
logic cmp_op;


// Internal Registers //
// ------------------  // 
logic [15:0] shift_in_d;
logic ne_decided;
logic carry_in;

// Sequential Logic // 
// ---------------- // 

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n | (first_cycle == 1'b0)) begin
		carry_in <= 1'b0;
	end else if (adder_used) begin
		carry_in <= add_out[16];
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		shift_in_d <= 1'b0;
	end else if (first_cycle && shift_used) begin
		shift_in_d <= shift_in;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ne_decided <= 1'b0;
	end else if ((op_i == ALU_OP_EQ) && (first_cycle == 1'b1)) begin
		if (cmp_result_valid == 1'b1) begin
			ne_decided <= 1'b1;
		end
	end
end

// Combinatorical  Logic // 
// --------------------- // 

assign adder_used =
	op_i inside {ALU_OP_ADD, ALU_OP_SUB, ALU_OP_EQ, ALU_OP_LT, ALU_OP_LTU};
assign cmp_op =
	op_i inside {ALU_OP_EQ, ALU_OP_LT, ALU_OP_LTU};
assign add_out = add_a + add_b + add_carry_in;
assign not_out = ~not_in;
assign or_out = or_a | or_b;
assign xor_out = xor_a ^ xor_b;
assign and_out = and_a & and_b;
assign reduction_or_out = |reduction_or_in;
assign shift_amount = b_i[3:0];
assign shift_bigger_then_16 = b_i[4];
assign shift_out = shift_in >> shift_amount;
assign shift_used = op_i inside {ALU_OP_SRA, ALU_OP_SRL, ALU_OP_SLL};
//assign shift_filler_out = {shift_filler_fill[0 +: shift_amount], shift_filler_in[0 +: 15 - shift_amount]};
assign reverse_a_out = {<<{reverse_a_in}};
assign reverse_b_out = {<<{reverse_b_in}};

genvar i;
generate 
for (i = 0; i < 16; i++) begin
	if (i == 0) begin
		assign shift_filler_combinations[i] = shift_filler_in;
	end else begin
		assign shift_filler_combinations[i] = {shift_filler_fill [i - 1 :0], shift_filler_in [15 - i : 0] };
	end
end
endgenerate
assign shift_filler_out = shift_filler_combinations[shift_amount];


assign cmp_result_valid_o = ne_decided ? 1'b1 : cmp_result_valid | ((first_cycle == 1'b0) && cmp_op);
assign cmp_result_o = (ne_decided ? 1'b0 : result_o[0]) ^ cmp_flip_i;
always_comb begin
	add_a = 16'b0;
	add_b = 16'b0;
	xor_a = 16'b0;
	xor_b = 16'b0;
	or_a = 16'b0;
	or_b = 16'b0;
	and_a = 16'b0;
	and_b = 16'b0;
	shift_in = 16'b0;
	not_in = 16'b0;
	reduction_or_in = 16'b0;
	reverse_a_in = 16'b0;
	reverse_b_in = 16'b0;
	shift_filler_in = 16'b0;
	shift_filler_fill = 16'b0;
	cmp_result_valid = 1'b0;
	add_carry_in = 1'b0;
	result_o = 16'b0;
	case (op_i)
		ALU_OP_ADD: begin 
			add_a = a_i;
			add_b = b_i;
			add_carry_in = carry_in;
			result_o = add_out;
		end
		ALU_OP_SUB: begin
			add_a = a_i;
			not_in = b_i;
			add_b = not_out;
			add_carry_in = ~carry_in;
			result_o = add_out;
		end
		ALU_OP_PLUS_4: begin
			add_a = a_i;
			add_b = first_cycle ? 16'd4 : 16'b0;
			result_o = add_out;
		end
		ALU_OP_AND: begin
			and_a = a_i;
			and_b = b_i;
			result_o = and_out;
		end
		ALU_OP_OR: begin
			or_a = a_i;
			or_b = b_i;
			result_o = or_out;
		end
		ALU_OP_XOR: begin
			xor_a = a_i;
			xor_b = b_i;
			result_o = xor_out;
		end
		ALU_OP_EQ: begin 
			xor_a = a_i;
			xor_b = b_i;
			reduction_or_in = xor_out;
			result_o[0] = (reduction_or_out == 0) ^ cmp_flip_i;
			cmp_result_valid = reduction_or_out ? 1'b1 : 1'b0;
		end
		ALU_OP_LT, ALU_OP_LTU: begin 
			add_a = a_i;
			not_in = b_i;
			add_b = not_out;
			add_carry_in = ~carry_in;
			if (first_cycle == 1'b0) begin
				result_o[0] = ((op_i == ALU_OP_LT) ? 
					((a_i[15] != b_i[15])? a_i[15] : add_out[15])
					: add_out[15] ) ^ cmp_flip_i;
			end
		end
		ALU_OP_SRL: begin
			if (shift_bigger_then_16 && first_cycle) begin
				shift_in = a_i;
				result_o = 16'b0;
			end else begin
				shift_in = a_i;
				if (first_cycle) begin
					result_o = shift_out;
				end else begin
					shift_filler_in = shift_out;
					shift_filler_fill = shift_in_d;
					result_o = shift_filler_out;
				end
			end
		end
		ALU_OP_SRA: begin
			if (shift_bigger_then_16 && first_cycle) begin
				shift_in = a_i;
				result_o = {16{a_i[15]}};
			end else begin
				shift_in = a_i;
				if (first_cycle) begin
					shift_filler_in = shift_out;
					shift_filler_fill = {16{a_i[15]}};
					result_o = shift_filler_out;
				end else begin
					shift_filler_in = shift_out;
					shift_filler_fill = shift_in_d;
					result_o = shift_filler_out;
				end
			end
		end
		ALU_OP_SLL: begin
			if (shift_bigger_then_16 && first_cycle) begin
				shift_in = a_i;
				result_o = 16'b0;
			end else begin
				reverse_a_in = a_i;
				shift_in = reverse_a_in;
				if (first_cycle) begin
					reverse_b_in = shift_out;
					result_o = reverse_b_out;
				end else begin
					shift_filler_in = shift_out;
					shift_filler_fill = shift_in_d;
					reverse_b_in = shift_filler_out;
					result_o = reverse_b_out;
				end
			end
		end
	endcase
end

endmodule
