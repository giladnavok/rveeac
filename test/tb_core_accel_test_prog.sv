import typedefs::*;

module tb_core_accel_test_prog (
);

localparam IMEM_SIZE = 1024;
localparam DMEM_SIZE = 4096;

logic clk;
logic rst_n;
logic [31:0] inst;
logic [31:0] inst_d;
logic [15:0] registers_halfs [1:0][31:0];
logic [31:0] registers [31:0];
logic [7:0] mem [DMEM_SIZE*4 - 1:0];
logic [31:0] imem [IMEM_SIZE - 1:0];

genvar i;
generate 
for (i = 0;i < 32;i++) begin
	assign registers[i] = {registers_halfs[1][i], registers_halfs[0][i]};
end
endgenerate



apb_if imem_apb();
apb_if dmem_apb();

apb_slave # (
	.SIZE(IMEM_SIZE),
	.INIT_FILENAME("test_core_accel_prog.rv"),
	.POSSIBLE_WAITS(1'b1)
)  imem_inst (
	.clk(clk),
	.rst_n(rst_n),
	.apb(imem_apb.slave),
	.mem_o(imem)
);

apb_slave_byte # (
	.SIZE(DMEM_SIZE),
	.POSSIBLE_WAITS(1'b1)
) dmem_inst (
	.clk(clk),
	.rst_n(rst_n),
	.apb(dmem_apb.slave),
	.mem_o(mem)
);

core core_inst (
	.clk(clk),
	.rst_n(rst_n),
	.imem_apb(imem_apb.master),
	.dmem_apb(dmem_apb.master),
	.registers_od(registers_halfs)
);

always #2 clk = ~clk;

initial begin
	rst_n = 1'b0;
	clk = 1'b0;
	#1 rst_n = 1'b1;

end

always begin
	#4 if ((imem_apb.rdata == 32'h0000006f)) begin
		# 32;

		$display ("%d\n", mem[registers[8] - 20]);
		$stop;
	end
		
end

endmodule
