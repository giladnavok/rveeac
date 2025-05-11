import typedefs::*;

module load_store_unit (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,
	input logic first_cycle,

	// Input Controls //
	// -------------- //
		
	input logic start_i,
	input logic dir_i,
	input cs_size size_i,
	input cs_ext load_ext_i,

	apb_if.master dmem_apb,

	// Input Data //
	// -------------- //
	input logic [31:0] reg1_i,
	input logic [31:0] addr_i,

	// Output Controls //
	// --------------- //
	output logic half_o,
	output logic apb_ready_o,
	output logic done_o,
	output logic valid_o,
	output logic err_o,

	// Output Data //
	// ----------- //
	output logic [15:0] ldata_o
);

logic [31:0] write_data;
logic [31:0] addr;
logic apb_controller_transfer_dir;

// Internal Registers //

logic [31:0] reg1_or_load_addr_d;
logic transfer_dir;
assign apb_controller_transfer_dir = start_i ? dir_i : transfer_dir;


localparam READ = 1'b0;
localparam WRITE = 1'b1;
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		reg1_or_load_addr_d <= '0;
		transfer_dir <= READ;
	end else if (start_i) begin 
		transfer_dir <= dir_i;
		if (dir_i == WRITE) begin
			reg1_or_load_addr_d <= reg1_i;
		end else begin
			reg1_or_load_addr_d <= addr_i;
		end
	end
end

always_comb begin
	write_data = '0;
	if (apb_controller_transfer_dir == WRITE) begin
		write_data = first_cycle ? reg1_i : reg1_or_load_addr_d; 
	end
end

always_comb begin
	addr = addr_i;
	if ((apb_controller_transfer_dir == READ) && !start_i) begin
		addr = reg1_or_load_addr_d;
	end
end


// Add mux to execution stage to mux wdata to 16 bit regfile read port for
// SH/SB

logic [31:0] ldata;
logic [15:0] ldata_lh;
always_comb begin
	case (size_i) 
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
assign half_o = valid_d;
assign done_o = valid_o ? half_o : apb_ready_o;

assign ldata_o = valid_d ? ldata_uh_d : ldata_lh;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		ldata_uh_d <= '0;
		valid_d <= '0;
	end else begin
		valid_d <= valid;
		if (valid) begin
			case (size_i) 
				SIZE_W: ldata_uh_d <= ldata[31:16];
				SIZE_H: ldata_uh_d <= 
					(load_ext_i == EXT_Z) ?
				   	16'b0 : {16{ldata[15]}};
				SIZE_B: ldata_uh_d <= 
					(load_ext_i == EXT_Z) ?
				   	16'b0 : {16{ldata[7]}};
			endcase
		end
	end
end

apb_controller_sbm dmem_apb_controller (
	.clk(clk),
	.rst_n(rst_n),

	.start_i(start_i),
	.dir_i(apb_controller_transfer_dir),
	.write_size_i(size_i),

	.apb(dmem_apb),

	.wdata_i(write_data),
	.addr_i(addr),

	.ready_o(apb_ready_o),
	.valid_o(valid),
	.err_o(err_o),

	.rdata_o(ldata)
);
endmodule

