import typedefs::*;

module tb_core (
);

logic clk;
logic rst_n;
logic [31:0] inst;
logic [31:0] pc;
logic [15:0] registers_halfs [1:0][31:0];
logic [31:0] registers [31:0];
logic [31:0] mem [63:0];

genvar i;
generate 
for (i = 0;i < 32;i++) begin
	assign registers[i] = {registers_halfs[1][i], registers_halfs[0][i]};
end
endgenerate


apb_if imem_apb();
apb_if dmem_apb();

apb_forwarding_slave imem (
	.clk(clk),
	.rst_n(rst_n),
	.apb(imem_apb.slave),
	.forward(inst),
	.requested(pc)
);

apb_slave dmem (
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

localparam logic [31:0] NOP = 32'h00000013;

initial begin
	rst_n = 1'b0;
	clk = 1'b0;

    /* Test ADDI */

	#4 rst_n = 1'b1;
	inst = 32'h3e800093;    // addi x1 , x0,   1000  /* x1  = 1000 0x3E8 */
	#8 inst = 32'h7d008113; // addi x2 , x1,   2000  /* x2  = 3000 0xBB8 */
	#8 inst = 32'hc1810193; // addi x3 , x2,  -1000  /* x3  = 2000 0x7D0 */
	#8 inst = 32'h83018213; // addi x4 , x3,  -2000  /* x4  = 0    0x000 */
	#8 inst = 32'h3e820293; // addi x5 , x4,   1000  /* x5  = 1000 0x3E8 */
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[1] == 1000);
	assert(registers[2] == 3000);
	assert(registers[3] == 2000);
	assert(registers[4] == 0);
	assert(registers[5] == 1000);

    /* Test STORE */

	#8 inst = 32'hc212a023; // sw x1 , -992(x5)  /* mem[2] = 1000 */
	#8 inst = NOP;
	#8 inst = NOP;

	assert(mem[2] == 1000);

end

endmodule
