import typedefs::*;
module fetch_unit # (
	parameter ADDR_W = 32,
	parameter INIT_PC = 0
) (

	// General Signals //
	// -------------- //
	input logic clk,
	input logic rst_n,

	// Control Inputs //
	// -------------- //
	input logic jmp_i,
	input logic branch_i,
	input logic ready_i,
	input logic branch_cmp_result_valid_i,

	apb_if.master imem_apb,

	// Input Data //
	// ---------- //
	input logic branch_cmp_result_i,
	input logic [ADDR_W - 1:0] jmp_target_i,

	// Output Controls //
	// --------------- //
	output logic valid_o,
	output logic branch_taken_o,

	// Output Data //
	// ---------- //
	output logic [31:0] pc_o,
	output logic [31:0] inst_o
);


// Internal Wires //
// -------------- //

logic imem_apb_start;
logic imem_apb_valid;
logic imem_apb_err;
logic imem_apb_ready;
logic [31:0] imem_apb_rdata;


logic [31:0] fetch_address;
logic [31:0] pc_next;

logic take_branch;

// Internal Registers //
// ------------------ //
	
logic [31:0] pc_current;
logic [31:0] branch_alternative;
logic [31:0] inst_buffer;
logic inst_in_buffer_branch_jmp;

enum logic [2:0] {
	ST_INIT_FETCH, ST_FETCH,
	ST_INIT_FETCH_SPEC, ST_FETCH_SPEC,
	ST_FETCH_DISCARD,
	ST_FULL_BUFFER, ST_FULL_BUFFER_SPEC
} state_e;

// Submodule Instances //
// ------------------- //

apb_controller_sbm #
(.DAT_W(32), .ADDR_W(ADDR_W))
imem_apb_controller (
	.clk(clk),
	.rst_n(rst_n),
	.start_i(imem_apb_start),
	.dir_i(1'b0), // read only 
	.write_size_i(cs_size'(SIZE_W)), 
	.wdata_i(32'b0),
	.addr_i(fetch_address),

	.apb(imem_apb),

	.ready_o(imem_apb_ready),
	.valid_o(imem_apb_valid),
	.err_o(imem_apb_err),

	.rdata_o(imem_apb_rdata)
);

branch_predictor_sbm branch_predictor (
	.imm_sign_i(inst_o[31]),
	.take_branch_o(take_branch)
);


always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_INIT_FETCH;
		pc_current <= INIT_PC;
		pc_o <= '0;
		inst_o <= '0;
		valid_o <= 1'b0;
		branch_taken_o <= 1'b0;
		inst_buffer <= '0;
		branch_alternative <= '0;
	end else begin
		case (state_e)
			ST_INIT_FETCH: begin
				pc_current <= fetch_address;
				if (branch_i) begin
					state_e <= ST_FETCH_SPEC;
					branch_taken_o <= take_branch;
					branch_alternative <= take_branch ? pc_current : jmp_target_i;
				end else begin
					state_e <= ST_FETCH;
				end
			end
			ST_INIT_FETCH_SPEC: begin
				if (branch_cmp_result_valid_i & (branch_taken_o != branch_cmp_result_i)) begin
					pc_current <= fetch_address;
					valid_o <= 1'b0;
					state_e <= ST_FETCH;
				end else if (branch_cmp_result_valid_i) begin
					pc_current <= fetch_address;
					if (branch_i) begin 
						state_e <= ST_FETCH_SPEC;
						branch_taken_o <= take_branch;
						branch_alternative <= take_branch ? pc_current : jmp_target_i;
					end else begin
						state_e <= ST_FETCH;
					end
				end else begin
					pc_current <= fetch_address;
					state_e <= ST_FETCH_SPEC;
				end
			end

			ST_FULL_BUFFER: begin
				if (branch_i) begin //maybe currently impossible
					if (take_branch) begin
						valid_o <= 1'b0;
						pc_current <= fetch_address;
						state_e <= ST_FETCH_SPEC;
					end else begin 
						if (ready_i) begin
							inst_o <= inst_buffer;
							valid_o <= 1'b1;
							pc_current <= fetch_address;
							state_e <= ST_FETCH_SPEC;
						end else begin
							state_e <= ST_FULL_BUFFER_SPEC;
						end
					end
				end else if (ready_i) begin
					inst_o <= inst_buffer;
					pc_o <= pc_current;
					valid_o <= 1'b1;
					pc_current <= fetch_address;
					state_e <= inst_in_buffer_branch_jmp? ST_INIT_FETCH : ST_FETCH;
				end
			end
			ST_FETCH: begin
				//! Make sure can't reach here with branch_i
				if (imem_apb_valid) begin
					if (ready_i) begin
						pc_o <= pc_current;
						pc_current <= pc_next;
						inst_o <= imem_apb_rdata;
						valid_o <= 1'b1;
						// state_e <= branch_i ? ST_INIT_FETCH_SPEC : ST_INIT_FETCH;
						state_e <= ST_INIT_FETCH;
					end else begin
						inst_buffer <= imem_apb_rdata;
						//state_e <= branch_i ? ST_FULL_BUFFER_SPEC : ST_FULL_BUFFER;
						state_e <= ST_FULL_BUFFER;
					end
				end else if (!imem_apb_ready) begin
					if (ready_i) begin
						valid_o <= 1'b0;
					end
				end else begin // apb error
					valid_o <= 1'b0;
				end
			end
			ST_FETCH_SPEC: begin
				if (branch_cmp_result_valid_i & (branch_taken_o != branch_cmp_result_i)) begin
					if (imem_apb_ready) begin
						valid_o <= 1'b0;
						pc_current <= branch_alternative;
						state_e <= ST_INIT_FETCH;
					end else begin 
						state_e <= ST_FETCH_DISCARD;
					end
				end else if (imem_apb_valid) begin
					if (ready_i) begin
						pc_o <= pc_current;
						pc_current <= pc_next;
						inst_o <= imem_apb_rdata;
						valid_o <= 1'b1;
						state_e <= branch_cmp_result_valid_i ? 
							ST_INIT_FETCH : ST_INIT_FETCH_SPEC;
					end else begin
						inst_buffer <= imem_apb_rdata;
						state_e <= branch_cmp_result_valid_i ? 
							ST_FULL_BUFFER : ST_FULL_BUFFER_SPEC;
					end
				end else if (!imem_apb_ready) begin
					if (ready_i) begin
						valid_o <= 1'b0;
					end
				end else begin // apb error
					valid_o <= 1'b0;
				end
			end
			ST_FETCH_DISCARD: begin
				if (imem_apb_ready) begin
					state_e <= ST_INIT_FETCH;
				end
			end
			ST_FULL_BUFFER_SPEC: begin
				if (branch_cmp_result_valid_i) begin
					if (branch_taken_o != branch_cmp_result_i) begin
						valid_o <= 1'b0;
						pc_current <= fetch_address;
						state_e <= ST_FETCH;
					end else begin
						inst_o <= inst_buffer;
						pc_o <= pc_current;
						valid_o <= 1'b1;
						pc_current <= fetch_address;
						state_e <= inst_in_buffer_branch_jmp? ST_INIT_FETCH : ST_FETCH;
					end
				end else if (ready_i) begin
					inst_o <= inst_buffer;
					pc_o <= pc_current;
					valid_o <= 1'b1;
					pc_current <= fetch_address;
					if (inst_in_buffer_branch_jmp) begin
						state_e <= branch_cmp_result_valid_i ? 
							ST_INIT_FETCH : ST_INIT_FETCH_SPEC;
					end else begin
						state_e <= branch_cmp_result_valid_i ? 
							ST_FETCH : ST_FETCH_SPEC;
					end
				end else begin
					state_e <= branch_cmp_result_valid_i ? 
						ST_FULL_BUFFER : ST_FULL_BUFFER_SPEC;
				end
			end
		endcase
	end
end


assign pc_next = pc_current + 4;
assign inst_in_buffer_branch_jmp = (inst_buffer[6:0] inside {OPC_BRANCH, OPC_JAL, OPC_JALR});
always_comb begin
	case (state_e)
		ST_INIT_FETCH: begin
			imem_apb_start = 1'b1;
			if (jmp_i | (branch_i & take_branch)) begin
				fetch_address = jmp_target_i;
			end else begin
				fetch_address = pc_current;
			end
		end
		ST_FULL_BUFFER: begin
			imem_apb_start = ready_i && !inst_in_buffer_branch_jmp;
			if (jmp_i | (branch_i & take_branch)) begin
				fetch_address = jmp_target_i;
			end else begin
				fetch_address = pc_next;
			end
		end
		ST_INIT_FETCH_SPEC: begin
			imem_apb_start = 1'b1;
			if (branch_cmp_result_valid_i) begin
				if (branch_cmp_result_i == branch_taken_o) begin
					fetch_address = (jmp_i || branch_i)  ? jmp_target_i : pc_current;
				end else begin
					fetch_address = branch_alternative;
				end
			end else begin
				fetch_address = pc_current;
			end
		end
		ST_FULL_BUFFER_SPEC: begin
			imem_apb_start = ready_i;
			if (branch_cmp_result_valid_i) begin
				if (branch_cmp_result_i == branch_taken_o) begin 
					fetch_address = (jmp_i || branch_i)  ? jmp_target_i : pc_next;
				end else begin
					fetch_address = branch_alternative;
				end
			end else begin
				fetch_address = pc_next;
			end
		end
		default: begin
			imem_apb_start = 1'b0;
			fetch_address = pc_current;
		end
	endcase
end


endmodule
