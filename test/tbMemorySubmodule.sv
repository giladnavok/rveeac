localparam MEM_SIZE = 256;
localparam LOG_MEM_SIZE = $clog2(MEM_SIZE);

interface MemoryInterface(input logic clk);
	logic [LOG_MEM_SIZE - 1:0] addr;
	logic write;
	logic [31:0] din, dout;
endinterface


module tbMemorySubmodule;
	logic clk;
	MemoryInterface intf(clk);
	MemoryInterface intfInitialized(clk);

	MemorySubmodule mem (
		.clk(intf.clk),
		.dout(intf.dout),
		.din(intf.din),
		.write(intf.write),
		.addr(intf.addr)
	);

	MemorySubmodule 
	#(.INIT_FILENAME("tbMemorySubmodule.init"))
	memInitialized (
		.clk(intfInitialized.clk),
		.dout(intfInitialized.dout),
		.din(intfInitialized.din),
		.write(intfInitialized.write),
		.addr(intfInitialized.addr)
	);

	always #5 clk = ~clk;

	task write( virtual MemoryInterface intf, logic [LOG_MEM_SIZE - 1: 0] addr, logic [31:0] data );
		intf.addr = addr;
		intf.write = 1;
		intf.din = data;
		@(posedge clk);
		@(posedge clk);
		#1 assert (intf.din == intf.dout) else $fatal("write value %d to address %d failed. dout = %d", addr, data, intf.dout);
	endtask

	task readExpected( virtual MemoryInterface intf, logic [LOG_MEM_SIZE - 1: 0] addr, logic [31:0] expected );
		intf.addr = addr;
		intf.write = 0;
		intf.din = 0;
		#1 assert (expected == intf.dout) else $fatal("unexpected data in address %d: expected: 0x%0h actual: 0x%0h ", addr, expected, intf.dout);

	endtask

	initial begin
		clk = 0;
		for (int addr = 0; addr < MEM_SIZE; addr++) begin
			write(intf, addr, addr);
		end
		for (int addr = 0; addr < MEM_SIZE; addr++) begin
			readExpected(intf, addr, addr);
		end
		for (int addr = 0; addr < MEM_SIZE; addr++) begin
			readExpected(intfInitialized, addr, addr);
		end
		$display("done");
		$stop;
	end
endmodule


