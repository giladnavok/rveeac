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
	#8 inst = NOP;
	assert(registers[1] == 1000);
	assert(registers[2] == 3000);
	assert(registers[3] == 2000);
	assert(registers[4] == 0);
	assert(registers[5] == 1000);

	#8 inst = 32'h000100b7;    // lui x1 , 16 /* x1 = 65536 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[1] == 65536);
	#8 inst = 32'h36808093;    // addi x1 , x1, 872 /* x1 = 66536 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[1] == 66408);

    /* Test STORE */

	#8 inst = 32'hc212a023; // sw x1 , -992(x5)  /* mem[2] = 66536 */
	#8 inst = 32'hc2129223; // sh x1, -988(x5)   /* mem[3] = 1000 */
	#8 inst = 32'hc2128423; // sb x1, -984(x5) /* mem[4] = 104 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;

	assert(mem[2] == 66408);
	assert(mem[3] == 872);
	assert(mem[4] == 104);

	// Unaligned writes
//	#8 inst = 32'hc2128423; // sb x1, -983(x5) /* mem[4][15:8]  = 232 */
//	#8 inst = 32'hc2128423; // sb x1, -982(x5) /* mem[4][23:16] = 232 */
//	#8 inst = 32'hc2128423; // sb x1, -981(x5) /* mem[4][31:24] = 232 */
//	#8 inst = NOP;
//	#8 inst = NOP;
//	#8 inst = NOP;
//	assert(mem[4][7:0] == 232);
//	assert(mem[4][15:8] == 232);
//	assert(mem[3][23:16] == 232);
//	assert(mem[4][31:24] == 232);

	#8 inst = 32'haaaaa337; // lui x6, 699050 /* x6  = 0xaaaaa000 */
	#8 inst = 32'h55530313; // addi x6, x6, 1365 
	#8 inst = 32'h55530313; // addi x6, x6, 1365 /* x6  = 0xaaaaaaaa */
	#8 inst = 32'h00602c23; // sw x6 , 24(x0)  /* mem[6] = 0xaaaaaaaa */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;

	assert(mem[6] == 32'haaaaaaaa);
	
    /* Test LOAD */

	#8 inst = 32'h01802383; // lw x7, 24(x0) /* x7  = 0xaaaaaaaa */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[7] == 32'haaaaaaaa);

	#8 inst = 32'h01802383; // lw x7, 24(x0) /* x7  = 0xaaaaaaaa */
	#8 inst = 32'h01801403; // lh x8, 24(x0) /* x8  = 0xffffaaaa */
	#8 inst = 32'h01800483; // lb x9, 24(x0) /* x9  = 0xffffffaa */
	#8 inst = 32'h01805503; // lhu x10, 24(x0) /* x10  = 0x0000aaaa */
	#8 inst = 32'h01804583; // lbu x11, 24(x0) /* x11  = 0x000000aa */
	#8 inst = 32'h00801603; // lh x12, 8(x0) /* x12  = 0x00000368 */ 
	#8 inst = 32'h00800683; // lb x13, 8(x0) /* x13  = 0x00000068 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[7] == 32'haaaaaaaa);
	assert(registers[8] == 32'hffffaaaa);
	assert(registers[9] == 32'hffffffaa);
	assert(registers[10] == 32'h0000aaaa);
	assert(registers[11] == 32'h000000aa);
	assert(registers[12] == 32'h00000368);
	assert(registers[13] == 32'h00000068);

end

endmodule
