parameter MEM_SIZE = 256;
localparam LOG_MEM_SIZE = $clog2(MEM_SIZE);

module MemorySubmodule (
	input logic clk,
	input logic [LOG_MEM_SIZE - 1:0] addr,
	input logic write,
	input logic [31:0] din,

	output logic [31:0] dout
);

parameter INIT_FILENAME = "";


logic [31:0] mem [0:MEM_SIZE - 1];

initial begin
	if (INIT_FILENAME != "") begin
		$readmemh(INIT_FILENAME, mem);
	end
end

always_ff @(posedge clk) begin
	if (write) begin
		mem[addr] <= din;
	end
end

assign dout = mem[addr];

endmodule
