import typedefs::*;

module exe_mem_wb_stage #(
	parameter DAT_W = 32, 
	parameter ADDR_W = 32
) (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,

	// Input Controls //
	// -------------- //
	input logic valid_i,
	input logic dmem_load_bypass_i,
	input cs_exe_s cs_i,

	apb_if.master dmem_apb,

	// Input Data //
	// ---------- //
		
	input logic [31:0] lsu_addr_i,
	input logic [15:0] alu_a_i,
	input logic [15:0] wb_i,
	input logic [4:0] rd_i,
	input logic [4:0] rs1_i,
	input logic [4:0] rs2_i,

	// Output Controls //
	// --------------- //
	output logic ready_o,

	// Output Data //
	// ----------- //
	output logic [31:0] reg1_o,
	output logic cmp_result_o,
	output logic cmp_result_valid_o
);

// Internal Wires //
// -------------- //
logic first_cycle;

// LSU 
logic load_store_ready;
logic load_store_valid;
logic load_store_err;
logic load_store_load_data;
logic transfer_start;

// ALU
logic [15:0] alu_out;
logic alu_cmp_result;
logic alu_cmp_result_valid;

// Regfile
logic [31:0] reg1_data;
logic [15:0] reg2_data;
logic rd_h_sel;
logic rs2_h_sel;
logic regfile_write_en;
logic [15:0] regfile_write_data;

// Submodule Instances //
// ------------------- //

load_store_unit load_store (
	.clk(clk),
	.rst_n(rst_n),

	.start_i(transfer_start),
	.dir_i(cs_i.en.dmem_store),
	.size_i(cs_i.sel.wb_store_size),
	.load_ext_i(cs_i.sel.wb_ext),

	.apb(dmem_apb),

	.reg1_i(reg1_data),
	.addr_i(lsu_addr_i),

	.ready_o(load_store_ready),
	.valid_o(load_store_valid),
	.err_o(load_store_err),

	.ldata_o(lsu_out)
);

alu_sbm alu (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(first_cycle),

	.op_i(cs_i.sel.alu_op),
	.cmp_flip_i(cs_i.en.cmp_flip),
	.a_i(alu_a_i),
	.b_i(reg2_data),
	.result_o(alu_out),
	.cmp_result_o(cmp_result_o),
	.cmp_result_valid_o(cmp_result_valid_o)
);


regfile_sbm regfile (
	.clk(clk),
	.rst_n(rst_n),

	.rs1_i(rs1_i),
	.rs2_i(rs2_i),
	.rd_i(rd_i),
	.write_i(regfile_write_en),
	.write_data_i(regfile_write_data),
	.rd_h_sel_i(rd_h_sel),
	.rs2_h_sel_i(rs2_h_sel),

	.rs1_do(reg1_data),
	.reg2_do(reg2_data)
);

// Logic // 
// ----- // 

// Generate first_cycle signal
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n || !valid_i) first_cycle <= 1'b1;
	else if (ready_o && valid_i) first_cycle <= 1'b1;
	else first_cycle <= 1'b0;
end

// Regfile WB data mux
always_comb begin
	case (cs_i.sel.wb)
		WB_SEL_ALU: regfile_write_data = alu_out;
		WB_SEL_LSU: regfile_write_data = lsu_out;
		WB_SEL_WB: regfile_write_data = wb_i;
	endcase
end

assign ready_o = !first_cycle && load_store_ready;
assign transfer_start = valid_i && (first_cycle & cs_i.en.dmem_store) | dmem_load_bypass_i;
assign regfile_write_en = valid_i && cs_i.en.rf_write;
assign rd_h_sel = !first_cycle ^ cs_i.en.wb_order_flip;
assign rs2_h_sel = !first_cycle && !cs_i.en.just_first_rs2_half;
assign reg1_o = reg1_data;

endmodule


