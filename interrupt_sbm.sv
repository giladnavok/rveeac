import typedefs::*;

module interrupt_sbm (
	input logic clk,
	input logic rst_n,

	input logic interrupt_req_ext_i,
	input logic interrupt_req_aes_i,

	input logic [31:0] fetch_pc_current_i,
	input logic [31:0] dec_pc_i,
	input logic dec_inst_jmp_or_branch_i,
	input logic dec_ready_for_interrupt_i,

	input logic [31:0] mip_i,
	input logic [31:0] mie_i,
	input logic [31:0] mtvec_i,
	input logic mstatus_mie_i,

	output logic mepc_write_o,
	output logic [31:0] mepc_write_data_o,

	output logic mcause_write_o,
	output logic [31:0] mcause_write_data_o,

	output logic mip_set_o,
	output logic [31:0] mip_set_data_o,

	output logic [31:0] interrupt_jmp_target_o,
	output logic interrupt_o
);

logic interrupt;


always_comb begin
	mepc_write_o = 1'b0;
	mcause_write_o = 1'b0;
	mip_set_o = 1'b0;

	mepc_write_data_o = 32'b0;
	mcause_write_data_o = 32'b0;
	mip_set_data_o = 32'b0;


	interrupt = 1'b0;

	if (interrupt_req_aes_i || (mip_i[16] && mie_i[16])) begin
		if (mie_i[16]) begin
			mepc_write_o = dec_ready_for_interrupt_i;
			mepc_write_data_o = dec_inst_jmp_or_branch_i ? dec_pc_i : fetch_pc_current_i;

			mcause_write_o = dec_ready_for_interrupt_i;
			mcause_write_data_o = {1'b1, 31'd16};

			interrupt = 1'b1;

			//! Maybe need to also set mip
		end else begin
			mip_set_o = 1'b1;
			mip_set_data_o = 1 << 16;
		end
	end

	//! Make sure the difference is only in the cause code
	if (interrupt_req_ext_i || (mip_i[11] && mie_i[11])) begin
		if (mie_i[11]) begin
			mepc_write_o = dec_ready_for_interrupt_i;
			mepc_write_data_o = dec_inst_jmp_or_branch_i ? dec_pc_i : fetch_pc_current_i;

			mcause_write_o = dec_ready_for_interrupt_i;
			mcause_write_data_o = {1'b1, 31'd11};

			interrupt = 1'b1;

			//! Maybe need to also set mip
		end else begin
			mip_set_o = 1'b1;
			mip_set_data_o = 1 << 11;
		end
	end

	interrupt_o = mstatus_mie_i ? 
		(dec_ready_for_interrupt_i ? interrupt : 1'b0 ) :
	   	1'b0;
	interrupt_jmp_target_o = interrupt_o ? mtvec_i : 32'b0;
end

endmodule 
