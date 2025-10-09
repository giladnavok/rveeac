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
	

	//--
	apb_if.master dmem_apb, 					///< DMEM APB Interface

	// ----------- Input Data --------
		
	input logic [31:0] lsu_store_addr_i, 		///< Store addres
	input logic [31:0] load_addr_bypass_i, 		///< Bypass from ID Stage - early load address
	input logic [15:0] alu_b_i, 				///< ALU b data from ID stage
	input logic [15:0] wb_i, 					///< WB data from ID stage
	input logic [4:0] rd_i, 					///< Register file write port index
	input logic [4:0] rs32_i, 					///< Register file 32 bit read port index
	input logic [4:0] rs16_i, 					///< Register file 16 bit read port index
	input logic [11:0] csr_addr_i, 				
	input logic [15:0] csr_imm_bypass_i,

	// --------- Output Controls --------
	output logic ready_o, 						///< Execution stage ready for new controls and data
	output logic dmem_apb_ready_d_o, 						///< Execution stage ready for new controls and data

	// --------- Output Data --------- 
	output logic [31:0] reg32_o, 				///< Register file 32 bit read port data
	output logic cmp_result_o, 					///< Comperator result is ready for IF stage
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	output logic cmp_result_valid_o, 			///< Comperator result is valid for IF stage
	output logic shift_bigger_then_16_o 		///< Signal ID to not forward lower half.

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
logic accel_rf_write_en;
logic [127:0] accel_data_in;
logic [127:0] accel_data_out;
logic accel_ready;
logic accel_done;

// CSR
logic csr_write;
logic csr_h_sel;
logic [11:0] csr_addr;
logic [15:0] csr_write_data;
logic csr_valid;
logic [15:0] csr_read_data_out;

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
	.accel_write_en_i(accel_rf_write_en),
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
	.done_o(accel_rf_write_en)
);

csr_sbm csr (
    .clk(clk),
    .rst_n(rst_n),
	
	.write_i(csr_write),
	.h_sel_i(csr_h_sel),

	.addr_i(csr_addr),
	.write_data_i(csr_write_data),

	.valid_o(csr_valid),
	.read_data_o(csr_read_data_out)
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
		ALU_A_SEL_REG: alu_a = reg16_data;
		ALU_A_SEL_CSR_IMM: alu_a = first_cycle ? csr_imm_bypass_i : 16'b0;
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
		CSR_W_SEL_REG: csr_write_data = reg16_data;
		CSR_W_SEL_ALU: csr_write_data = alu_out;
	endcase
end

assign transfer_start = load_store_apb_ready && ((valid_i && (first_cycle && cs_i.en.dmem_store)) || dmem_load_bypass_i);
assign rs16_h_sel = cs_i.en.reg16_use && (!first_cycle && !shift_bigger_then_16_o) ^ cs_i.en.rs16_half_order_flip;
assign lsu_addr = (cs_i.en.dmem_store && !dmem_load_bypass_i) ? lsu_store_addr_i : load_addr_bypass_i;
assign load_store_write = cs_i.en.dmem_store && !dmem_load_bypass_i;

assign accel_load_key = cs_i.en.accel_load_key && valid_i && first_cycle;
assign accel_start_enc = cs_i.en.accel_start_enc && valid_i && first_cycle;
assign accel_start_dec = cs_i.en.accel_start_dec && valid_i && first_cycle;

assign csr_write = valid_i && cs_i.en.csr_write;
assign csr_h_sel = cs_i.en.csr_req && !first_cycle;
assign csr_addr = csr_addr_i;

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
assign ready_o = alu_cmp_result_valid || (accel_ready && load_store_ready && !first_cycle);
assign reg32_o = reg32_data;

endmodule


