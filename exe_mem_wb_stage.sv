import typedefs::*;

module exe_mem_wb_stage #(
	parameter DAT_W = 32, 
	parameter ADDR_W = 32
) (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,
	input logic first_cycle,

	// Input Controls //
	// -------------- //
	input logic valid_i,
	input logic dmem_load_bypass_i,
	input cs_exe_s cs_i,

	apb_if.master dmem_apb,

	// Input Data //
	// ---------- //
		
	input logic [31:0] lsu_addr_i,
	input logic [31:0] load_addr_bypass_i,
	input logic [15:0] alu_b_i,
	input logic [15:0] wb_i,
	input logic [4:0] rd_i,
	input logic [4:0] rs32_i,
	input logic [4:0] rs16_i,

	// Output Controls //
	// --------------- //
	output logic ready_o,

	// Output Data //
	// ----------- //
	output logic [31:0] reg32_o,
	output logic cmp_result_o,
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	output logic cmp_result_valid_o,
	output logic shift_bigger_then_16_o

);

// Internal Wires //
// -------------- //
//logic first_cycle;

// LSU 
logic load_store_ready;
logic load_store_valid;
logic load_store_err;
logic load_store_load_data;
logic transfer_start;
logic [15:0] lsu_out;
logic [31:0] lsu_addr;

// ALU
logic [15:0] alu_out;
//logic alu_cmp_result;
//logic alu_cmp_result_valid;

// Regfile
logic [31:0] reg32_data;
logic [15:0] reg16_data;
logic rd_h_sel;
logic rs16_h_sel;
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

	.dmem_apb(dmem_apb),

	.reg1_i(reg32_data),
	.addr_i(lsu_addr),

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
	.a_i(reg16_data),
	.b_i(alu_b_i),
	.result_o(alu_out),
	.cmp_result_o(cmp_result_o),
	.cmp_result_valid_o(cmp_result_valid_o),
	.shift_bigger_then_16_o(shift_bigger_then_16_o)
);


regfile_sbm regfile (
	.clk(clk),
	.rst_n(rst_n),

	.rs32_i(rs32_i),
	.rs16_i(rs16_i),
	.rd_i(rd_i),
	.write_i(regfile_write_en),
	.write_data_i(regfile_write_data),
	.rd_h_sel_i(rd_h_sel),
	.rs16_h_sel_i(rs16_h_sel),

	`ifdef DEBUG
		.registers_od(registers_od),
	`endif

	.rs32_do(reg32_data),
	.rs16_do(reg16_data)

);

// Logic // 
// ----- // 

//// Generate first_cycle signal
//always_ff @(posedge clk or negedge rst_n) begin
//	if (!rst_n) first_cycle <= 1'b0;
//	else if (!valid_i) first_cycle <= 1'b1;
//	else if (ready_o && valid_i) first_cycle <= 1'b1;
//	else first_cycle <= 1'b0;
//end

// Regfile WB data mux
always_comb begin
	case (cs_i.sel.wb)
		WB_SEL_ALU: regfile_write_data = alu_out;
		WB_SEL_LSU: regfile_write_data = lsu_out;
		WB_SEL_WB: regfile_write_data = wb_i;
	endcase
end

assign ready_o = load_store_ready;
assign transfer_start = (valid_i && (first_cycle && cs_i.en.dmem_store)) | dmem_load_bypass_i;
assign regfile_write_en = valid_i && cs_i.en.rf_write;
assign rd_h_sel = !first_cycle ^ cs_i.en.wb_order_flip; 
assign rs16_h_sel = (!first_cycle && !shift_bigger_then_16_o) ^ cs_i.en.rs16_half_order_flip;
assign reg32_o = reg32_data;
assign lsu_addr = dmem_load_bypass_i ? load_addr_bypass_i : lsu_addr_i;

endmodule


