import typedefs::*;
module tb_csr_sbm();

logic clk;
logic rst_n;
logic write_i;
logic h_sel_i;
logic [CSR_ADDR_LEN-1:0] addr_i;
logic [HALF_XLEN-1:0] write_data_i;
logic valid_o; /// <<< Used to prevent intermediary values to get sampled
logic [HALF_XLEN-1:0] read_data_o;

csr_sbm
csr_sbm_inst (
	.clk(clk),
	.rst_n(rst_n),
	.write_i(write_i),
	.h_sel_i(h_sel_i),
	.addr_i(addr_i),
	.write_data_i(write_data_i),
	.valid_o(valid_o),
	.read_data_o(read_data_o)
);

always begin
	#2 clk = ~clk;
end

initial begin
	rst_n = 1'b0;
	clk = 1'b0;
	write_i = 1'b0;
	h_sel_i = 1'b0;
	addr_i = '0;
	write_data_i = '0;
	#4 rst_n = 1'b1;

	addr_i = 12'h341;
	h_sel_i = 1'b0;
	write_data_i = 16'b0;
	write_i = 1'b0;
	#2 assert(read_data_o == 16'b0);
	h_sel_i = 1'b1;
	#2 assert(read_data_o == 16'b0);

	addr_i = 12'h341;
	h_sel_i = 1'b0;
	write_data_i = 16'd1;
	write_i = 1'b1;
	#1 assert(read_data_o == 16'd0);
	#3 assert(read_data_o == 16'd1);

	h_sel_i = 1'b0;
	write_data_i = 16'd2;
	#1 assert(read_data_o == 16'd1);
	#3 assert(read_data_o == 16'd2);

	h_sel_i = 1'b1;
	write_data_i = 16'd3;
	#1 assert(read_data_o == 16'd0);
	#3 assert(read_data_o == 16'd3);
end

endmodule
