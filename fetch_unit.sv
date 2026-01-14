import typedefs::*;
module fetch_unit # (
	parameter ADDR_W = 32,
	parameter INIT_PC = 0,
	parameter PREFETCH_BUFFER_CAPACITY = 2
) (
	// --------- General ---------
	
	input logic clk, 						///< Rising-edge refernce clock
	input logic rst_n, 						///< Async active-low reset

	// --------- Control Inputs -------
	
	input logic jmp_i,						///< Valid jump decoded in ID stage
	input logic branch_i,			 		///< Valid branch decoded in ID stage
	input logic ready_i, 					///< Downstream stage can accept inst
	input logic branch_cmp_result_valid_i,  ///< Comperator result valid
	input logic stall_for_jmp_target_i,     ///< Stall fetching when asserted
	input logic interrupt_i,				///< Interrupt triggered. Used to distinguish interrupt jumps.

	apb_if.master imem_apb, 				///< IMEM APB Interface

	// --------- Input Data -------
	
	input logic branch_cmp_result_i, 		///< Comperator result
	input logic [ADDR_W - 1:0] jmp_target_i,///< Jump target PC computed in ID stage
	input logic inst31_i, 					///< Last bit of outputed instruction from ID stage, used by the branch predictor.

	// --------- Control Outputs ------- 
	output logic valid_o, 					///< Output instruction and pc are valid
	output logic misspredict_o, 		 	///< Indicate misspredicted branch and thus last outputed instruction is invalid

	// --------- Output Data --------
	output logic [31:0] inst_o, 			///< Output fetched instruction
	output logic [31:0] pc_o, 				///< Output PC of fetched instruction
	output logic [31:0] pc_next_o 			///< Output PC of currently fetched instruction
);

// ===============================
//			Internal Wires        
// ===============================


logic imem_apb_start, imem_apb_valid, 
	  imem_apb_err, imem_apb_ready;
logic [31:0] imem_apb_rdata;


logic [31:0] imem_apb_fetch_address;
logic [31:0] pc_next;

logic take_branch;
logic in_speculative_state;
logic redirect;
logic misspredict;
logic interrupt;

logic prefetch_enqueue;
logic prefetch_dequeue;
logic prefetch_flush;
logic [31:0] prefetch_inst;
logic [31:0] prefetch_pc;
logic prefetch_full;
logic prefetch_full_next;
logic prefetch_count;


// ===============================
//			Internal Registers        
// ===============================
	
logic [31:0] pc_current;
logic [31:0] branch_alternative;
logic [31:0] jmp_target_requested;
logic inst_in_buffer_branch_jmp;
logic branch_taken;
logic jmp_requested;

enum logic [2:0] {
	ST_INIT_FETCH, ST_FETCH,
	ST_INIT_FETCH_SPEC, ST_FETCH_SPEC,
	ST_FETCH_DISCARD,
	ST_FULL_BUFFER, ST_FULL_BUFFER_SPEC
} state_e;

// ===============================
//			Sub-modules
// ===============================
//
//

apb_controller_sbm #
(.DAT_W(32), .ADDR_W(ADDR_W))
imem_apb_controller (
	.clk(clk),
	.rst_n(rst_n),
	.start_i(imem_apb_start),
	.dir_i(1'b0), // read only 
	.write_size_i(cs_size'(SIZE_W)), 
	.wdata_i(32'b0),
	.addr_i(imem_apb_fetch_address),

	.apb(imem_apb),

	.ready_o(imem_apb_ready),
	.valid_o(imem_apb_valid),
	.err_o(imem_apb_err),

	.rdata_o(imem_apb_rdata)
);

branch_predictor_sbm branch_predictor (
	.imm_sign_i(inst31_i),
	.take_branch_o(take_branch)
);

prefetch_buffer_sbm # (
	.CAPACITY(PREFETCH_BUFFER_CAPACITY)
) prefetch_buffer (
	.clk(clk),
	.rst_n(rst_n),

	.inst_i(imem_apb_rdata),
	.pc_i(pc_current),
	.enqueue_i(prefetch_enqueue),
	.dequeue_i(prefetch_dequeue),
	.flush_i(prefetch_flush),

	.inst_o(prefetch_inst),
	.pc_o(prefetch_pc),
	.full_o(prefetch_full),
	.full_next_o(prefetch_full_next),
	.empty_o(prefetch_empty)
);


// ===============================
//			Seqential Logic
// ===============================
//

// -------------------------------
// 		Fetch unit FSM
// -------------------------------
//
// * ST_INIT_FETCH: First cycle of APB read transfer.
// * ST_FETCH: Complete APB read transfer. Buffer instruction if
// 				downstream is not ready.
// * ST_FULL_BUFFER: Stop fetching while buffer is full.
// * _SPEC: Speculative fetching - In addition, act when comperator result is ready.
// * ST_FETCH_DISCARD: Wait for a mispredicted fetch to complete before
// 					   discarding it.
//

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_INIT_FETCH;
		pc_current <= INIT_PC;
		branch_taken <= 1'b0;
		branch_alternative <= '0;
		jmp_requested <= '0;
		jmp_target_requested <= '0;
	end else begin
		case (state_e)
			ST_INIT_FETCH: begin
				if (interrupt) begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;
				end else if (stall_for_jmp_target_i) begin
					state_e <= ST_INIT_FETCH;
				end else begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;

					if (branch_i) begin
						state_e <= ST_FETCH_SPEC;
						branch_taken <= take_branch;
						branch_alternative <= take_branch ? pc_next_o : jmp_target_i;
					end

				end 
				jmp_requested <= 1'b0;
			end
			ST_INIT_FETCH_SPEC: begin
				if (interrupt) begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;
				end else if (misspredict) begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;
				end else if (branch_cmp_result_valid_i) begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;

					if (branch_i) begin 
						state_e <= ST_FETCH_SPEC;
						branch_taken <= take_branch;
						branch_alternative <= take_branch ? pc_next_o : jmp_target_i;
					end 
				end else begin 
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH_SPEC;
				end

				jmp_requested <= 1'b0;
			end

			ST_FULL_BUFFER: begin
				assert(!branch_i);
				assert(!(jmp_i && !interrupt));
				if (interrupt) begin
					state_e <= ST_FETCH;
					pc_current <= imem_apb_fetch_address;
				end else if (ready_i) begin
					if (inst_in_buffer_branch_jmp) begin
						pc_current <= pc_next;
						state_e <= ST_INIT_FETCH;
					end else begin
						state_e <= ST_FETCH;
						pc_current <= imem_apb_fetch_address;
					end
				end
			end
			ST_FETCH: begin
				assert(!prefetch_full);
				if (jmp_i) begin
					jmp_requested <= 1'b1;
					jmp_target_requested <= jmp_target_i;
					state_e <= ST_FETCH_DISCARD;
				end else if (imem_apb_valid) begin

					if (branch_i) begin
						branch_taken <= 1'b0;
						branch_alternative <= jmp_target_i;
					end

					if (!prefetch_empty && prefetch_full_next) begin
						state_e <= branch_i ? ST_FULL_BUFFER_SPEC : ST_FULL_BUFFER;
					end else begin
						pc_current <= pc_next;
						state_e <= branch_i ? ST_INIT_FETCH_SPEC : ST_INIT_FETCH;
					end
				end else if (branch_i) begin
					branch_taken <= 1'b0;
					branch_alternative <= jmp_target_i;
					state_e <= ST_FETCH_SPEC;
				end
			end
			ST_FETCH_SPEC: begin
				assert(!prefetch_full);
				if (jmp_i) begin // must come from an interrupt?, in that case the branch is re executed 
					//assert(interrupt);
					jmp_requested <= !misspredict;
					jmp_target_requested <= jmp_target_i;
					state_e <= ST_FETCH_DISCARD;
				end else if (misspredict) begin
					pc_current <= branch_alternative;
					if (imem_apb_ready) begin
						state_e <= ST_INIT_FETCH;
					end else begin 
						state_e <= ST_FETCH_DISCARD;
					end
				end else if (imem_apb_valid) begin
					if (branch_i) begin
						branch_taken <= 1'b0;
						branch_alternative <= jmp_target_i;
					end
					// TODO: try removing this !prefetch_empty condition it
					// looks redundent
					if (!prefetch_empty) begin
						assert(!(prefetch_full_next && branch_i));
						if (prefetch_full_next) begin
							state_e <= (branch_i || !branch_cmp_result_valid_i) ? ST_FULL_BUFFER_SPEC : ST_FULL_BUFFER;
						end else begin
							pc_current <= pc_next;
							state_e <= (branch_i || !branch_cmp_result_valid_i) ? ST_INIT_FETCH_SPEC : ST_INIT_FETCH;
						end
					end else begin
						pc_current <= pc_next;
						state_e <= (branch_i || !branch_cmp_result_valid_i) ? ST_INIT_FETCH_SPEC : ST_INIT_FETCH;
					end
				end else if (branch_cmp_result_valid_i) begin
					state_e <= ST_FETCH;
				end
			end
			ST_FETCH_DISCARD: begin
				if (jmp_i) begin
					jmp_requested <= 1'b1;
					jmp_target_requested <= jmp_target_i;
				end
				if (imem_apb_ready) begin
					state_e <= ST_INIT_FETCH;
				end
			end
			ST_FULL_BUFFER_SPEC: begin
				assert(!branch_i);
				assert(!jmp_i);
				if (interrupt) begin
					pc_current <= imem_apb_fetch_address;
					state_e <= ST_FETCH;
				end else if (ready_i) begin
					if (redirect) begin
						pc_current <= imem_apb_fetch_address;
						state_e <= ST_FETCH;
					end else if (branch_cmp_result_valid_i) begin
						if (inst_in_buffer_branch_jmp) begin
							state_e <= ST_INIT_FETCH;
							pc_current <= pc_next;
						end else begin
							state_e <= ST_FETCH;
							pc_current <= imem_apb_fetch_address;
						end
					end else begin
						if (inst_in_buffer_branch_jmp) begin
							state_e <= ST_INIT_FETCH_SPEC;
							pc_current <= pc_next;
						end else begin
							state_e <= ST_FETCH_SPEC;
							pc_current <= imem_apb_fetch_address;
						end
					end
				end else begin
					state_e <= branch_cmp_result_valid_i ? 
						ST_FULL_BUFFER : ST_FULL_BUFFER_SPEC;
				end
			end
		endcase
	end
end
// ===============================
//		Combinatorical Logic
// ===============================

assign redirect = misspredict ||
				  jmp_i || 
				  (branch_i && take_branch && !(state_e inside {ST_FETCH, ST_FETCH_SPEC}));
assign interrupt = interrupt_i && jmp_i;
assign in_speculative_state = state_e inside {ST_INIT_FETCH_SPEC, ST_FETCH_SPEC, ST_FULL_BUFFER_SPEC};
assign pc_next = pc_current + 4;
assign inst_in_buffer_branch_jmp = (prefetch_inst[6:0] inside {OPC_BRANCH, OPC_JAL, OPC_JALR});
assign misspredict = in_speculative_state && (branch_cmp_result_valid_i && (branch_taken != branch_cmp_result_i));
assign misspredict_o = misspredict;

always_comb begin
	pc_next_o = (!prefetch_empty) ? prefetch_pc : pc_current; 
	if (misspredict && interrupt) begin
		pc_next_o = branch_alternative;
	end
end

always_comb begin
	prefetch_enqueue = 1'b0;
	case (state_e)
		ST_INIT_FETCH: begin
			imem_apb_start = !stall_for_jmp_target_i;
			if (interrupt) begin
				//assert(1'b0);
				imem_apb_fetch_address = jmp_target_i;
			end else if (jmp_requested) begin
				imem_apb_fetch_address = jmp_target_requested;
			end else if (jmp_i || (branch_i && take_branch)) begin
				imem_apb_fetch_address = jmp_target_i;
			end else begin
				imem_apb_fetch_address = pc_current;
			end
		end
		ST_FULL_BUFFER: begin
			imem_apb_start = 1'b0;
			imem_apb_fetch_address = 32'bx;
			if (interrupt) begin
				imem_apb_start = 1'b1;
				imem_apb_fetch_address = jmp_target_i;
			end else if (ready_i) begin
				imem_apb_start = !inst_in_buffer_branch_jmp;
				imem_apb_fetch_address = pc_next;
			end
		end
		ST_INIT_FETCH_SPEC: begin
			imem_apb_start = 1'b1;
			if (interrupt) begin
				imem_apb_fetch_address = jmp_target_i;
			end else if (branch_cmp_result_valid_i) begin
				if (branch_cmp_result_i == branch_taken) begin
					imem_apb_fetch_address = (jmp_i || (branch_i && take_branch))  ? jmp_target_i : pc_current;
				end else begin
					imem_apb_fetch_address = branch_alternative;
				end
			end else begin
				imem_apb_fetch_address = pc_current;
			end
		end
		ST_FULL_BUFFER_SPEC: begin
			if (interrupt) begin
				imem_apb_start = 1'b1;
				imem_apb_fetch_address = jmp_target_i;
			end else if (branch_cmp_result_valid_i) begin
				if (branch_cmp_result_i == branch_taken) begin 
					imem_apb_start = !inst_in_buffer_branch_jmp;
					imem_apb_fetch_address = (jmp_i || branch_i)  ? jmp_target_i : pc_next;
				end else begin
					imem_apb_start = 1'b1;
					imem_apb_fetch_address = branch_alternative;
				end
			end else begin
				imem_apb_start = ready_i && !inst_in_buffer_branch_jmp;
				imem_apb_fetch_address = pc_next;
			end
		end
		ST_FETCH_DISCARD: begin
			imem_apb_start = 1'b0;
			imem_apb_fetch_address = pc_current;
		end
		default: begin // ST_FETCH / ST_FETCH_SPEC
			assert(!prefetch_full);
			imem_apb_start = 1'b0;
			imem_apb_fetch_address = pc_current;
			if (imem_apb_valid && (!prefetch_empty || !ready_i)) begin
				prefetch_enqueue = 1'b1;
			end
		end
	endcase
end


always_comb begin
	prefetch_dequeue = 1'b0;
	prefetch_flush = 1'b0;
	valid_o = 1'b0;

	pc_o = 32'hxxxxxxxx;
	inst_o = 32'hxxxxxxxx;

	if (redirect) begin
		prefetch_flush = 1'b1;
	end else begin
		if (!prefetch_empty) begin
			pc_o = prefetch_pc;
			inst_o = prefetch_inst;
			valid_o = 1'b1;
			if (ready_i) begin
				prefetch_dequeue = 1'b1;
			end
		end else begin
			if (imem_apb_valid && ready_i && (state_e != ST_FETCH_DISCARD)) begin
				valid_o = 1'b1;
				pc_o = pc_current;
				inst_o = imem_apb_rdata;
			end
		end
	end
end

endmodule
