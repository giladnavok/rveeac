import typedefs::*;

module alu_sbm (
	// ------- General Signals -------

	input logic clk, 					///< Rising-edge refernce clock
	input logic rst_n, 					///< Async active-low reset

	// ----------- Input Controls --------
		
	input logic first_cycle,			///< Is first execution cycle
	input cs_alu_op op_i, 				///< Arithmetic operation selector
	input logic cmp_req_i, 				///< Compare result request 
	input logic cmp_flip_i, 			///< Flip compare result (BEQ->BNE)

	// ----------- Input Data --------
		
	input logic [15:0] a_i, 			///< Input data A
	input logic [15:0] b_i, 			///< Input data B

	// ----------- Output Data --------

	output logic shift_bigger_then_16_o, ///< Signal ID stage to not forward lower half
	output logic [15:0] result_o, 		 ///< Operation result
	output logic cmp_result_o,			 ///<  Comparison result
	output logic cmp_result_valid_o 	 ///< Is comparison result is valid
);

// ===============================
//			Internal Wires        
// ===============================

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
logic early_cmp_verdict;
logic early_cmp_result;


// ===============================
//			Internal Registers        
// ===============================
logic [15:0] shift_in_d;
logic carry_in;
logic early_cmp_verdict_d;
logic early_cmp_result_d;

// ===============================
//			Sequential Logic        
// ===============================

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		carry_in <= 1'b0;
	end else if (adder_used && first_cycle) begin
		carry_in <= add_out[16];
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n || !first_cycle) begin
		shift_in_d <= 1'b0;
		early_cmp_verdict_d <= 1'b0;
		early_cmp_result_d <= 1'b0;
	end else if (first_cycle /*//! should gate? */ ) begin
		shift_in_d <= shift_in;
		early_cmp_verdict_d <= early_cmp_verdict;
		early_cmp_result_d <= early_cmp_result;
	end
end

// ===============================
//		Combinatorical Logic        
// ===============================

assign adder_used =
	op_i inside {ALU_OP_ADD, ALU_OP_SUB, ALU_OP_EQ, ALU_OP_LT, ALU_OP_LTU};
assign add_out = add_a + add_b + add_carry_in;
assign not_out = ~not_in;
assign or_out = or_a | or_b;
assign xor_out = xor_a ^ xor_b;
assign and_out = and_a & and_b;
assign reduction_or_out = |reduction_or_in;
assign shift_amount = b_i[3:0];
assign shift_bigger_then_16 = shift_used && b_i[4];
assign shift_out = shift_in >> shift_amount;
assign shift_used = op_i inside {ALU_OP_SRA, ALU_OP_SRL, ALU_OP_SLL};
//assign shift_filler_out = {shift_filler_fill[0 +: shift_amount], shift_filler_in[0 +: 15 - shift_amount]};
assign reverse_a_out = {<<{reverse_a_in}};
assign reverse_b_out = {<<{reverse_b_in}};

//! Chat says this synthesies 16 muxes
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


assign shift_bigger_then_16_o = shift_bigger_then_16;
assign cmp_result_valid_o = cmp_req_i && (early_cmp_verdict || !first_cycle);

always_comb begin
	if (early_cmp_verdict_d) cmp_result_o = early_cmp_result_d ^ cmp_flip_i;
	else if (early_cmp_verdict) cmp_result_o = early_cmp_result ^ cmp_flip_i;
	else if (!first_cycle) cmp_result_o = result_o[0] ^ cmp_flip_i;
end

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
	early_cmp_verdict = 1'b0;
	add_carry_in = 1'b0;
	result_o = 16'b0;
	case (op_i)
		ALU_OP_ADD: begin 
			add_a = a_i;
			add_b = b_i;
			add_carry_in = first_cycle ? 1'b0 : carry_in;
			result_o = add_out;
		end
		ALU_OP_SUB: begin
			add_a = a_i;
			not_in = b_i;
			add_b = not_out;
			add_carry_in = first_cycle ? 1'b1 : carry_in;
			result_o = add_out;
		end
		ALU_OP_PLUS_4: begin
			add_a = b_i;
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
			result_o = 16'b0;
			if (!early_cmp_verdict_d) begin
				xor_a = a_i;
				xor_b = b_i;
				reduction_or_in = xor_out;
				if (first_cycle && (reduction_or_out == 1'b1)) begin
					early_cmp_verdict = 1'b1;
					early_cmp_result = 1'b0;
				end else if (!first_cycle) begin
					result_o[0] = !reduction_or_out;
				end
			end else begin
				result_o[0] = early_cmp_result_d;
			end
		end
		ALU_OP_LT: begin 
			result_o = 16'b0;
			if (!early_cmp_verdict_d) begin
				add_a = a_i;
				not_in = b_i;
				add_b = not_out;
				add_carry_in = 1'b1;
				reduction_or_in = add_out;
				if (first_cycle) begin
					early_cmp_verdict = ((a_i[15] != b_i[15]) || (reduction_or_out == 1'b1));
					early_cmp_result = ((a_i[15] != b_i[15]) ? a_i[15] : !add_out[16]);
				end else begin
					result_o[0] = !add_out[16];
				end
			end else begin
				result_o[0] = early_cmp_result_d;
			end
		end
		ALU_OP_LTU: begin 
			result_o = 16'b0;
			if (!early_cmp_verdict_d) begin
				add_a = a_i;
				not_in = b_i;
				add_b = not_out;
				add_carry_in = 1'b1;
				reduction_or_in = add_out;
				if (first_cycle && (reduction_or_out == 1'b1)) begin
					early_cmp_verdict = 1'b1;
					early_cmp_result = !add_out[16];
				end else if (!first_cycle) begin
					result_o[0] = !add_out[16];
				end
			end else begin
				result_o[0] = early_cmp_result_d;
			end
		end
		ALU_OP_SRL: begin
			if (shift_bigger_then_16 && first_cycle) begin
				shift_in = 16'b0;
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
				shift_in = {16{a_i[15]}};
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
				shift_in = 16'b0;
				result_o = 16'b0;
			end else begin
				reverse_a_in = a_i;
				shift_in = reverse_a_out;
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
