import typedefs::*;

module interrupt_sbm (
	input logic clk,
	input logic rst_n,

	input logic [31:0] fetch_pc_current_i,
	input logic [31:0] dec_pc_i,
	input logic dec_resume_execution_from_dec_inst_i,
	input logic dec_ready_for_interrupt_i,

	input logic [31:0] mip_i,
	input logic [31:0] mie_i,
	input logic [31:0] mtvec_i,
	input logic mstatus_mie_i,

	output logic mepc_write_o,
	output logic [31:0] mepc_write_data_o,

	output logic mcause_write_o,
	output logic [31:0] mcause_write_data_o,

	output logic store_clear_mstatus_mie_o,
	output logic [31:0] interrupt_jmp_target_o,
	output logic interrupt_o
);

logic interrupt;
logic [4:0] cause;

localparam bit [4:0] CAUSE_MEI = 5'd11;
localparam bit [4:0] CAUSE_AES = 5'd16;

always_comb begin
	cause = 5'b0;
	interrupt = 1'b0;
	if (mstatus_mie_i) begin
		if ((mip_i[11] && mie_i[11])) begin
			cause = CAUSE_MEI;
			interrupt = 1'b1;
		end else if ((mip_i[16] && mie_i[16])) begin
			cause = CAUSE_AES;
			interrupt = 1'b1;
		end
	end
end

always_comb begin
	mepc_write_o = 1'b0;
	mepc_write_data_o = 32'b0;
	mcause_write_o = 1'b0;
	mcause_write_data_o = 32'b0;
	interrupt_o = 1'b0;
	interrupt_jmp_target_o = 32'b0;
	store_clear_mstatus_mie_o = 1'b0;

	if (interrupt && dec_ready_for_interrupt_i) begin
		mepc_write_o = 1'b1;
		mepc_write_data_o = dec_resume_execution_from_dec_inst_i ? dec_pc_i : fetch_pc_current_i;
		mcause_write_o = 1'b1;
		mcause_write_data_o = {1'b1, 26'b0, cause};
		interrupt_o = 1'b1;
		interrupt_jmp_target_o = mtvec_i;
		store_clear_mstatus_mie_o = 1'b1;
	end
end
endmodule 
