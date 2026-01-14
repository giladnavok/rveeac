import typedefs::*;

module exe_mem_wb_stage #(
	parameter DAT_W = 32, 
	parameter ADDR_W = 32
) (
	// ------- General Signals -------
	input logic clk, 							///< Rising-edge reference clock
	input logic rst_n, 							///< Async active-low reset

	// --------- Input Controls //
	input logic first_cycle, 					///< Is first instrucion execution cycle
	input logic valid_i, 						///< Are input control signals and data from ID stage are valid
	input logic dmem_load_bypass_i, 			///< Bypass from ID stage - Start early load if possible
	input cs_exe_s cs_i, 						///< Control signals
	
	input logic interrupt_req_ext_i, 			///< External interrupt request.
	input logic dec_ready_for_interrupt_i,		///< Indicates whether ID stage can be interrupted
	input logic accel_rf_write_i,				///< Writes the Accelerator output to the Register File.
	input logic accel_start_enc_bypass_i,		///< Initiates an Accelerator encryption
	input logic accel_start_dec_bypass_i,		///< Initiates an Accelerator decryption


	//--
	apb_if.master dmem_apb, 					///< DMEM APB Interface

	// ----------- Input Data --------
		
	input logic [31:0] lsu_store_addr_i, 		///< Store addres
	input logic [31:0] load_addr_bypass_i, 		///< Bypass from ID Stage - early load address
	input logic [15:0] alu_a_i, 				///< ALU b data from ID stage
	input logic [15:0] alu_b_i, 				///< ALU b data from ID stage
	input logic [15:0] wb_i, 					///< WB data from ID stage
	input logic [4:0] rd_i, 					///< Register file write port index
	input logic [4:0] rs32_i, 					///< Register file 32 bit read port index
	input logic [4:0] rs16_i, 					///< Register file 16 bit read port index
	input logic [11:0] csr_addr_i, 				///< CSR Address
	input logic [31:0] fetch_pc_next_i, 		///< PC of currently fetched instruction in IF stage
	input logic [31:0] dec_pc_i,				///< PC of currently decoded instruction in ID stage
	input logic dec_resume_execution_from_dec_inst_i, ///< Determines whether execution after an 
													  ///  interrupt should be resumed from the
													  ///  instruction currently fetched or the 
													  ///  instruction currently in decode.

	// --------- Output Controls --------
	output logic ready_o, 						///< Execution stage ready for new controls and data
	output logic dmem_apb_ready_d_o, 			///< Indicates whether the dmem APB interface was 
												///  ready at the end of the last cycle.
	output logic interrupt_o,					///< Triggers an interrupt when asserted

	// --------- Output Data --------- 
	output logic [31:0] reg32_o, 				///< Register file 32 bit read port data
	output logic cmp_result_o, 					///< Comperator result is ready for IF stage
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	output logic cmp_result_valid_o, 			///< Comperator result is valid for IF stage
	output logic shift_bigger_then_16_o, 		///< Signal ID to not forward lower half. //! shift_bigger_than
	output logic [31:0] interrupt_jmp_target_o, ///< Interrupt jump target
	output logic [31:0] mepc_o, 				///< CSR MEPC data
	output logic [15:0] regfile_write_half_o, 	///< Value of the half currently written to the register file.
												///  Used for forwarding.
	output logic accel_ready_o					///< Accelerator is ready; Used in ID stage for the implementation of `wait for accel` instruction.

);

// ===============================
//			Internal Wires        
// ===============================

// LSU 
logic load_store_write;
logic load_store_apb_ready;
logic load_store_valid;
logic load_store_half;
logic load_store_err;
logic load_store_load_data;
logic transfer_start;
logic [15:0] lsu_out;
logic [31:0] lsu_addr;

logic load_store_ready;

// ALU
logic [15:0] alu_a;
logic [15:0] alu_b;
logic [15:0] alu_out;
logic alu_cmp_result_valid;

// Regfile
logic [31:0] reg32_data;
logic [15:0] reg16_data;
logic rd_h_sel;
logic rs16_h_sel;
logic regfile_write_en;
logic [15:0] regfile_write_data;

// Accel
logic accel_load_key;
logic accel_start_enc;
logic accel_start_dec;
logic [127:0] accel_data_in;
logic [127:0] accel_data_out;
logic accel_ready;
logic accel_done; //! Maybe remove

// CSR
logic csr_write;
logic csr_h_sel;
logic [11:0] csr_addr;
logic [15:0] csr_write_data;
logic csr_valid;
logic [15:0] csr_read_data_out;
logic [15:0] csr_imm_ext;
logic [31:0] csr_mepc;
logic [31:0] csr_mip;
logic [31:0] csr_mie;
logic [31:0] csr_mtvec;
logic csr_mstatus_mie;

logic restore_mstatus_mie;

// Interrupt

logic interrupt_req_aes;

logic int_mepc_write;
logic [31:0] int_mepc_write_data;
logic int_mcause_write;
logic [31:0] int_mcause_write_data;
logic int_store_clear_mstatus_mie;

// Misc
logic first_two_cycles;

// ===============================
//			Internal Registers        
// ===============================

logic first_cycle_d;

// ===============================
//			Sub-modules
// ===============================

load_store_unit load_store (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(first_cycle),

	.start_i(transfer_start),
	.dir_i(load_store_write),
	.size_i(cs_i.sel.wb_store_size),
	.load_ext_i(cs_i.sel.wb_ext),

	.dmem_apb(dmem_apb),

	.reg1_i(reg32_data),
	.addr_i(lsu_addr),

	.apb_ready_o(load_store_apb_ready),
	.ready_o(load_store_ready),
	.valid_o(load_store_valid),
	.half_o(load_store_half),
	.err_o(load_store_err),

	.ldata_o(lsu_out)
);

alu_sbm alu (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(first_cycle),

	.op_i(cs_i.sel.alu_op),
	.cmp_req_i(cs_i.en.cmp_req),
	.cmp_flip_i(cs_i.en.cmp_flip),
	.a_i(alu_a),
	.b_i(alu_b),
	.result_o(alu_out),
	.cmp_result_o(cmp_result_o),
	.cmp_result_valid_o(alu_cmp_result_valid),
	.shift_bigger_then_16_o(shift_bigger_then_16_o)
);


regfile_sbm regfile (
	.clk(clk),
	.rst_n(rst_n),

	.rs32_i(rs32_i),
	.rs16_i(rs16_i),
	.rd_i(rd_i),
	.write_i(regfile_write_en),
	.accel_write_en_i(accel_rf_write_i),
	.write_data_i(regfile_write_data),
	.rd_h_sel_i(rd_h_sel),
	.rs16_h_sel_i(rs16_h_sel),
	.accel_di(accel_data_out),

	`ifdef DEBUG
		.registers_od(registers_od),
	`endif

	.rs32_do(reg32_data),
	.rs16_do(reg16_data),
	.accel_do(accel_data_in)

);

aes128_core accel (
    .clk(clk),
    .rst_n(rst_n),

    .load_key_i(accel_load_key),
    .start_enc_i(accel_start_enc),
    .start_dec_i(accel_start_dec),
	.data_i(accel_data_in),

	.data_o(accel_data_out),
	.ready_o(accel_ready),
	.done_o(accel_done) //! Maybe remove
);

csr_sbm csr (
    .clk(clk),
    .rst_n(rst_n),
	
	.write_i(csr_write),
	.h_sel_i(csr_h_sel),

	.interrupt_req_ext_i(interrupt_req_ext_i),
	.interrupt_req_aes_i(interrupt_req_aes),

	.addr_i(csr_addr),
	.write_data_i(csr_write_data),

	.mepc_write_i(int_mepc_write),
	.mepc_write_data_i(int_mepc_write_data),

	.mcause_write_i(int_mcause_write),
	.mcause_write_data_i(int_mcause_write_data),

	.store_clear_mstatus_mie_i(int_store_clear_mstatus_mie),
	.restore_mstatus_mie_i(restore_mstatus_mie),

	.valid_o(csr_valid),
	.read_data_o(csr_read_data_out), 

	.mstatus_mie_o(csr_mstatus_mie),
	.mepc_o(csr_mepc),
	.mie_o(csr_mie),
	.mip_o(csr_mip),
	.mtvec_o(csr_mtvec)
);

interrupt_sbm interrupt (
	.clk(clk),
	.rst_n(rst_n),

	.fetch_pc_next_i(fetch_pc_next_i),
	.dec_pc_i(dec_pc_i),
	.dec_resume_execution_from_dec_inst_i(dec_resume_execution_from_dec_inst_i),
	.dec_ready_for_interrupt_i(dec_ready_for_interrupt_i),

	.mip_i(csr_mip),
	.mie_i(csr_mie),
	.mtvec_i(csr_mtvec),
	.mstatus_mie_i(csr_mstatus_mie),

	.mepc_write_o(int_mepc_write),
	.mepc_write_data_o(int_mepc_write_data),

	.mcause_write_o(int_mcause_write),
	.mcause_write_data_o(int_mcause_write_data),

	.store_clear_mstatus_mie_o(int_store_clear_mstatus_mie),
	.interrupt_jmp_target_o(interrupt_jmp_target_o),
	.interrupt_o(interrupt_o)
);


// ===============================
//			Internal Logic
// ===============================

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) first_cycle_d <= 1'b0;
	else first_cycle_d <= first_cycle;
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		dmem_apb_ready_d_o <= 1'b1;
	end else begin
		dmem_apb_ready_d_o <= !transfer_start && load_store_apb_ready;
	end
end

// CSR Imm extender
assign csr_imm_ext = first_cycle ? {11'b0, rs16_i} : 16'b0;

// Regfile WB data mux
always_comb begin
	case (cs_i.sel.wb)
		WB_SEL_ALU: regfile_write_data = alu_out;
		WB_SEL_LSU: regfile_write_data = lsu_out;
		WB_SEL_WB: regfile_write_data = wb_i;
		WB_SEL_CSR: regfile_write_data = csr_read_data_out;
	endcase
end

// ALU A Mux
always_comb begin
	case (cs_i.sel.alu_a)
		ALU_A_SEL_REG: alu_a = alu_a_i;
		ALU_A_SEL_CSR_IMM: alu_a = csr_imm_ext;
	endcase
end

// ALU B Mux
always_comb begin
	case (cs_i.sel.alu_b)
		ALU_B_SEL_DEC: alu_b = alu_b_i;
		ALU_B_SEL_CSR: alu_b = csr_read_data_out;
	endcase
end

// CSR Write Mux
always_comb begin
	case (cs_i.sel.csr_write)
		CSR_W_SEL_REG: csr_write_data = alu_a_i;
		CSR_W_SEL_ALU: csr_write_data = alu_out;
		CSR_W_SEL_IMM: csr_write_data = csr_imm_ext;
	endcase
end

assign transfer_start = load_store_apb_ready && ((valid_i && (first_cycle && cs_i.en.dmem_store)) || dmem_load_bypass_i);
assign rs16_h_sel = cs_i.en.reg16_use && (!first_cycle && !shift_bigger_then_16_o);
assign lsu_addr = (cs_i.en.dmem_store && !dmem_load_bypass_i) ? lsu_store_addr_i : load_addr_bypass_i;
assign load_store_write = cs_i.en.dmem_store && !dmem_load_bypass_i;

assign accel_load_key = cs_i.en.accel_load_key && valid_i && first_cycle;
assign accel_start_enc = accel_start_enc_bypass_i || (cs_i.en.accel_start_enc && valid_i && first_cycle);
assign accel_start_dec = accel_start_dec_bypass_i || (cs_i.en.accel_start_dec && valid_i && first_cycle);

assign csr_write = valid_i && cs_i.en.csr_write;
assign csr_h_sel = cs_i.en.csr_req && !first_cycle;
assign csr_addr = csr_addr_i;

assign restore_mstatus_mie = first_cycle && cs_i.en.csr_restore_mstatus_mie;

assign first_two_cycles = first_cycle || first_cycle_d;


always_comb begin
	regfile_write_en = 1'b0;
	rd_h_sel = 1'b0;
	if (valid_i && cs_i.en.rf_write) begin
		if (cs_i.sel.wb == WB_SEL_LSU) begin
			regfile_write_en = load_store_valid;
			rd_h_sel = load_store_half;
		end else begin
			regfile_write_en = first_two_cycles;
			rd_h_sel = !first_cycle ^ cs_i.en.wb_order_flip; 
		end
	end
end

assign cmp_result_valid_o = alu_cmp_result_valid && first_two_cycles;
assign ready_o = alu_cmp_result_valid || (load_store_ready && !first_cycle);
assign reg32_o = reg32_data;
assign mepc_o = csr_mepc;
assign regfile_write_half_o = regfile_write_data;
assign accel_ready_o = accel_ready;

// TMP:
assign interrupt_req_aes = 1'b0;

endmodule


