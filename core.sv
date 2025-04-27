import typedefs::*;

module core (
	input logic clk,
	input logic rst_n,

	apb_if.master imem_apb,
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	apb_if.master dmem_apb

);

// Internal Wires //
// -------------- //

logic fetch_valid;
logic [31:0] fetch_pc_out;
logic [31:0] fetch_inst_out;
logic fetch_branch_taken;

logic dec_ready;
logic dec_valid;
logic dec_jmp;
logic dec_branch;
logic dec_dmem_load_bypass;
logic [31:0] dec_dmem_load_addr_bypass;
cs_exe_s dec_cs_exe_out;
logic [31:0] dec_jmp_target_out;
logic [31:0] dec_lsu_addr_out;
logic [15:0] dec_alu_a_out;
logic [15:0] dec_wb_data_out;
logic [4:0] dec_rd_out;
logic [4:0] dec_rs1_out;
logic [4:0] dec_rs2_out;

logic exe_ready;
logic exe_cmp_result_valid;
logic exe_cmp_result;
logic [31:0] exe_reg1_out;
logic exe_first_cycle;
logic exe_shift_bigger_then_16;

//logic dec_flush;
//logic [1:0] speculative_cycle_counter;
//always_ff @(posedge clk or negedge rst_n) begin
//	if (!rst_n) begin
//		speculative_cycle_counter <= 2'b0;
//	end else begin
//		if ((branch_i && exe_ready) || speculative_cycle_counter) begin
//			speculative_cycle_counter <= speculative_cycle_counter + 1'b1;
//			if (exe_cmp_result_valid) begin
//				if (exe_cmp_result == fetch_branch_taken) begin
//					speculative_cycle_counter <= 2'b0;
//				end else begin
//					if (speculative_cycle_counter == 2'b10) begin
//						dec_flush <= 1'b1;
//					end
//				end
//			end
//		else 
	//

// Submodule Instantiation // 
// ----------------------- // 

fetch_unit fetch (
	.clk(clk),
	.rst_n(rst_n),

	.jmp_i(dec_jmp),
	.branch_i(dec_branch),
	.ready_i(dec_ready),
	.branch_cmp_result_valid_i(exe_cmp_result_valid),

	.imem_apb(imem_apb),

	.branch_cmp_result_i(exe_cmp_result),
	.jmp_target_i(dec_jmp_target_out),

	.valid_o(fetch_valid),
	.branch_taken_o(fetch_branch_taken),

	.pc_o(fetch_pc_out),
	.inst_o(fetch_inst_out)
);

decode_unit decode (
	.clk(clk),
	.rst_n(rst_n),

	.ready_i(exe_ready),
	.valid_i(fetch_valid),

	.inst_i(fetch_inst_out),
	.pc_i(fetch_pc_out),
	.reg1_i(exe_reg1_out),
	.shift_bigger_then_16_i(exe_shift_bigger_then_16),

	.cs_exe_o(dec_cs_exe_out),
	.jmp_o(dec_jmp),
	.branch_o(dec_branch),
	.ready_o(dec_ready),
	.valid_o(dec_valid),
	.dmem_load_bypass_o(dec_dmem_load_bypass),
	.exe_first_cycle_o(exe_first_cycle),

	.lsu_addr_o(dec_lsu_addr_out),
	.dmem_load_addr_bypass_o(dec_dmem_load_addr_bypass),
	.jmp_target_o(dec_jmp_target_out),
	.alu_a_o(dec_alu_a_out),
	.wb_o(dec_wb_data_out),
	.rd_o(dec_rd_out),
	.rs1_o(dec_rs1_out),
	.rs2_o(dec_rs2_out)
);

exe_mem_wb_stage exe_mem_wb (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(exe_first_cycle),

	.valid_i(dec_valid),
	.dmem_load_bypass_i(dec_dmem_load_bypass),
	.cs_i(dec_cs_exe_out),

	.dmem_apb(dmem_apb),

	.lsu_addr_i(dec_lsu_addr_out),
	.load_addr_bypass_i(dec_dmem_load_addr_bypass),
	.alu_a_i(dec_alu_a_out),
	.wb_i(dec_wb_data_out),
	.rd_i(dec_rd_out),
	.rs1_i(dec_rs1_out),
	.rs2_i(dec_rs2_out),

	.ready_o(exe_ready),
	.reg1_o(exe_reg1_out),
	.cmp_result_o(exe_cmp_result),
	.shift_bigger_then_16_o(exe_shift_bigger_then_16),

	`ifdef DEBUG
		.registers_od(registers_od),
	`endif

	.cmp_result_valid_o(exe_cmp_result_valid)
);
endmodule





	
