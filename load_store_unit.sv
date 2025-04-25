import typedefs::*;

module load_store_unit (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,

	// Input Controls //
	// -------------- //
		
	input logic start_i,
	input logic dir_i,
	input cs_size write_size_i,
	input cs_ext load_ext_i,

	apb_if.master dmem_apb,

	// Input Data //
	// -------------- //
	input logic [31:0] reg1_i,
	input logic [31:0] addr_i,

	// Output Controls //
	// --------------- //
	output logic ready_o,
	output logic valid_o,
	output logic err_o,

	// Output Data //
	// ----------- //
	output logic [15:0] ldata_o
);
// Add mux to execution stage to mux wdata to 16 bit regfile read port for
// SH/SB

logic [31:0] ldata;
logic [15:0] ldata_lh;
always_comb begin
	case (write_size_i) 
		SIZE_W, SIZE_H: ldata_lh = ldata[15:0];
		SIZE_B: begin
			if (load_ext_i == EXT_Z) begin
				ldata_lh = {8'b0, ldata[7:0]};
			end else begin
				ldata_lh = {{8{ldata[7]}}, ldata[7:0]};
			end
		end
	endcase
end

logic [15:0] ldata_uh_d;

logic valid;
logic valid_d;
assign valid_o = valid | valid_d;

assign ldata_o = valid_d ? ldata_uh_d : ldata_lh;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ldata_uh_d <= '0;
		valid_d <= '0;
	end else begin
		valid_d <= valid;
		if (valid) begin
			case (write_size_i) 
				SIZE_W: ldata_uh_d <= ldata[31:16];
				SIZE_H, SIZE_B: ldata_uh_d <= 
					(load_ext_i == EXT_Z) ?
				   	16'b0 : {16{ldata[15]}};
			endcase
		end
	end
end

apb_controller_sbm dmem_apb_controller (
	.clk(clk),
	.rst_n(rst_n),

	.start_i(start_i),
	.dir_i(dir_i),
	.write_size_i(write_size_i),

	.apb(dmem_apb),

	.wdata_i(reg1_i),
	.addr_i(addr_i),

	.ready_o(ready_o),
	.valid_o(valid),
	.err_o(err_o),

	.rdata_o(ldata)
);
endmodule

