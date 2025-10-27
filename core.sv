import typedefs::*;

module core (
	input logic clk,
	input logic rst_n,

	apb_if.master imem_apb,
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	apb_if.master dmem_apb,

	input logic interrupt_req_ext_i

);

// Internal Wires //
// -------------- //

logic fetch_valid;
logic [31:0] fetch_pc_out;
logic [31:0] fetch_inst_out;
logic fetch_misspredict;
logic [31:0] fetch_pc_next;

logic dec_ready;
logic dec_valid;
logic dec_jmp;
logic dec_branch;
logic dec_dmem_load_bypass;
logic [31:0] dec_lsu_load_addr_bypass;
cs_exe_s dec_cs_exe_out;
logic [31:0] dec_jmp_target_out;
logic [31:0] dec_lsu_store_addr_out;
logic [15:0] dec_alu_b_out;
logic [15:0] dec_alu_a_out;
logic [11:0] dec_csr_addr_out;
logic [15:0] dec_wb_data_out;
logic [4:0] dec_rd_out;
logic [4:0] dec_rs16_out;
logic [4:0] dec_rs32_out;
logic dec_inst31_out;
logic dec_stall_for_jmp_target;
logic dec_resume_execution_from_dec_inst;
logic dec_ready_for_interrupt;
logic dec_accel_rf_write;
logic [31:0] dec_pc;

logic exe_ready;
logic exe_cmp_result_valid;
logic exe_cmp_result;
logic [31:0] exe_reg32_out;
logic exe_first_cycle;
logic exe_shift_bigger_then_16;
logic exe_dmem_apb_ready_d;
logic [31:0] exe_mepc;

logic exe_interrupt;
logic exe_accel_ready;
logic [31:0] exe_interrupt_jmp_target;

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
	.inst31_i(dec_inst31_out),
	.stall_for_jmp_target_i(dec_stall_for_jmp_target),
	.interrupt_i(exe_interrupt),

	.imem_apb(imem_apb),

	.branch_cmp_result_i(exe_cmp_result),
	.jmp_target_i(dec_jmp_target_out),

	.valid_o(fetch_valid),
	.misspredict_o(fetch_misspredict),

	.pc_o(fetch_pc_out),
	.inst_o(fetch_inst_out),
	.pc_next_o(fetch_pc_next)
);

decode_unit decode (
	.clk(clk),
	.rst_n(rst_n),

	.ready_i(exe_ready),
	.valid_i(fetch_valid),
	.exe_dmem_apb_ready_d_i(exe_dmem_apb_ready_d),
	.misspredict_i(fetch_misspredict),
	.interrupt_i(exe_interrupt),
	.accel_ready_i(exe_accel_ready),

	.inst_i(fetch_inst_out),
	.pc_i(fetch_pc_out),
	.reg32_i(exe_reg32_out),
	.interrupt_jmp_target_i(exe_interrupt_jmp_target),
	.mepc_i(exe_mepc),

	.cs_exe_o(dec_cs_exe_out),
	.jmp_o(dec_jmp),
	.branch_o(dec_branch),
	.ready_o(dec_ready),
	.valid_o(dec_valid),
	.dmem_load_bypass_o(dec_dmem_load_bypass),
	.exe_first_cycle_o(exe_first_cycle),
	.fetch_stall_for_jmp_target_o(dec_stall_for_jmp_target),
	.resume_execution_from_dec_inst_o(dec_resume_execution_from_dec_inst),
	.ready_for_interrupt_o(dec_ready_for_interrupt),
	.accel_rf_write_o(dec_accel_rf_write),

	.lsu_store_addr_o(dec_lsu_store_addr_out),
	.lsu_load_addr_bypass_o(dec_lsu_load_addr_bypass),
	.jmp_target_o(dec_jmp_target_out),
	.alu_a_o(dec_alu_a_out),
	.alu_b_o(dec_alu_b_out),
	.csr_addr_o(dec_csr_addr_out),
	.wb_o(dec_wb_data_out),
	.rd_o(dec_rd_out),
	.rs16_o(dec_rs16_out),
	.rs32_o(dec_rs32_out),
	.inst31_o(dec_inst31_out),
	.pc_o(dec_pc)
);

exe_mem_wb_stage exe_mem_wb (
	.clk(clk),
	.rst_n(rst_n),

	.first_cycle(exe_first_cycle),
	.valid_i(dec_valid),
	.dmem_load_bypass_i(dec_dmem_load_bypass),
	.cs_i(dec_cs_exe_out),

	.interrupt_req_ext_i(interrupt_req_ext_i),
	.dec_ready_for_interrupt_i(dec_ready_for_interrupt),
	.accel_rf_write_i(dec_accel_rf_write),

	.dmem_apb(dmem_apb),

	.lsu_store_addr_i(dec_lsu_store_addr_out),
	.load_addr_bypass_i(dec_lsu_load_addr_bypass),
	.alu_a_i(dec_alu_a_out),
	.alu_b_i(dec_alu_b_out),
	.wb_i(dec_wb_data_out),
	.rd_i(dec_rd_out),
	.rs16_i(dec_rs16_out),
	.rs32_i(dec_rs32_out),
	.csr_addr_i(dec_csr_addr_out),
	.fetch_pc_next_i(fetch_pc_next),
	.dec_pc_i(dec_pc),
	.dec_resume_execution_from_dec_inst_i(dec_resume_execution_from_dec_inst),

	.ready_o(exe_ready),
	.reg32_o(exe_reg32_out),
	.cmp_result_o(exe_cmp_result),
	.shift_bigger_then_16_o(exe_shift_bigger_then_16),

	`ifdef DEBUG
		.registers_od(registers_od),
	`endif

	.cmp_result_valid_o(exe_cmp_result_valid),
	.dmem_apb_ready_d_o(exe_dmem_apb_ready_d),
	.interrupt_o(exe_interrupt),
	.accel_ready_o(exe_accel_ready),
	.interrupt_jmp_target_o(exe_interrupt_jmp_target),
	.mepc_o(exe_mepc)
);
endmodule





	
