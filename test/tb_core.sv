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
int auipc_pc;
int jmp_pc;
int branch_pc;

initial begin
	rst_n = 1'b0;
	clk = 1'b0;
	inst = NOP;

    /* Test Immediate ops */

	// Test ADDI
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

	#8 inst = 32'h004cffb7; // lui x31, 1231
	#8 inst = 32'h78bf8f93; // addi x31, x31, 1931
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[31] == 5044107);
	// Test SLLI 
	#8 inst = 32'h009f9f93; // slli x31, x31, 9
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[31] == (5044107 << 9) );
	// Test SRLI
	#8 inst = 32'h009fdf13; // srli x30, x31, 9
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[30] == (5044107) );
	// Test SRAI
	#8 inst = 32'h409fde93; // srai x29, x31, 9
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert($signed(registers[29]) == ($signed(5044107 << 9) >>> 9) );

	// Test ANDI
	#8 inst = 32'h4cfff193; // andi x3, x31, 1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == (registers[31] & 1231));

	// Test ORI
	#8 inst = 32'h4cffe193; // ori x3, x31, 1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == (registers[31] | 1231));

	// Test XORI
	#8 inst = 32'h4cffc193; // xor x3, x31, 1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == (registers[31] ^ 1231));

	// Test SLTI positive (x31 is a large negative)
	#8 inst = 32'h4cffa193; // SLTI x3, x31, 1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == 1);

	// Test SLTI negative
	#8 inst = 32'hb31fa193; // SLTI x3, x31, -1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == 1);

	// Test SLTIU positive (x31 is a large positive)
	#8 inst = 32'h4cffb193; // SLTIU x3, x31, 1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == 0);

	// Test SLTIU negative
	#8 inst = 32'hb31fb193; // SLTIU x3, x31, -1231
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[3] == 1); // apparently -1231 should be sign extented and treated as unsigned!

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

	// Test AUIPC
	#8 inst = 32'h004cf717; // auipc x14, 1231 /* x14  = current_pc +  5042176 */
	#4 auipc_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[14] == auipc_pc + 5042176);

    /* Test ADD */
	#8 inst = 32'h000087b3; // add x15, x1, x0 /* x15  = 66408 */
	#8 inst = 32'h00108833; // add x16, x1, x1 /* x16  = 66408 + 66408 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[15] == 66408);
	assert(registers[16] == 2*66408);
	#8 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 4*66408 */
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	assert(registers[16] == 4*66408);

    /* Test JAL */
	#8 inst = 32'h0640006f; // jal x0, 100
	#4 jmp_pc = pc;
	#4 inst = NOP; // 4/8 depends if instruction was buffer in fetch stage
	#4 assert(pc == jmp_pc + 100); #4;

	#8 inst = 32'h00080067; // jalr x0, 0(x16)
	#8 inst = NOP;
	#4 assert(pc == 4*66408); #4;

	#8 inst = 32'h000808e7; // jalr x17, 0(x16)
	#4 jmp_pc = pc;
	#4 inst = NOP;
	#4 assert(pc == 4*66408); #4;
	#4 assert(registers[17] == jmp_pc + 4); #4;

    /* Test BEQ */

	// Should predict not taken and not take - not equal on first cycle
	#8 inst = 32'h01078c63; // BEQ x15, x16, 24
	#4 branch_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#4 assert(pc == branch_pc + 12); #4;

	// Should not predict taken and not take - not equal on second cycle
	#8 inst = 32'h00c68c63; // BEQ x12, x13, 24
	#4 branch_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#4 assert(pc == branch_pc + 12); #4;

	// Should not predict taken but take
	#8 inst = 32'h01080c63; // BEQ x16, x16, 24
	#4 branch_pc = pc;
	// This instruction should enter the pipe but not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 28);
	#4 assert(registers[16] == 4*66408);

	// Should predict taken and take
	#8 inst = 32'hff0804e3; // BEQ x16, x16, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 20);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 16);
	#4 assert(registers[16] == 8*66408);

	// Should predict taken but not take - not equal on first cycle
	#8 inst = 32'hff0784e3; // BEQ x15, x16, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 8);
	#4 assert(registers[16] == 8*66408);

	// Should predict taken but not take - not equal on second cycle
	#8 inst = 32'hfec684e3; // BEQ x12, x13, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 8);
	#4 assert(registers[16] == 8*66408);

    /* Test BNE */

	// Should predict not taken but take - not equal on first cycle
	#8 inst = 32'h01079c63; // BNE x15, x16, 24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 24);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 28);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 32);
	#4 assert(registers[16] == 8*66408);

	// Should predict not taken but take - not equal on second cycle
	#8 inst = 32'h00c69c63; // BNE x12, x13, 24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 24);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 28);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 32);
	#4 assert(registers[16] == 8*66408);

	// Should predict not taken and not take
	#8 inst = 32'h01081c63; // BNE x16, x16, 24
	#4 branch_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#4 assert(pc == branch_pc + 12); #4;


	// Should predict taken and not take
	#8 inst = 32'hff0814e3; // BNE x16, x16, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 8);
	#4 assert(registers[16] == 8*66408);

	// Should predict taken and take - not equal on first cycle
	#8 inst = 32'hff0794e3; // BNE x15, x16, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 20);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 16);
	#4 assert(registers[16] == 16*66408);

	// Should predict taken and take - not equal on second cycle
	#8 inst = 32'hfec694e3; // BNE x12, x13, -24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc - 24);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 20);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc - 16);
	#4 assert(registers[16] == 32*66408);


    /* Test BLT */

	// Current registers state
	// x15 < x16 both positive
	// x13 < x12 both positive
	// x31 < x29 both negative
	// x31 < x15 neg < positive

	// LT - both positive
	// Should predict not taken and not take - not lower then on first cycle
	#8 inst = 32'h00f84c63; // BLT x16, x15, 24
	#4 branch_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#4 assert(pc == branch_pc + 12); #4;

	// Should predict not taken and not take - not lower then on second cycle
	#8 inst = 32'h00d64c63; // BLT x12, x13, 24
	#4 branch_pc = pc;
	#4 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#4 assert(pc == branch_pc + 12); #4;

	// Should predict not taken but take  - not lower then on first cycle
	#8 inst = 32'h0107cc63; // BLT x15, x16, 24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 24);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 28);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 32);
	#4 assert(registers[16] == 32*66408);

	// Should predict not taken but take  - not lower then on second cycle
	#8 inst = 32'h00c6cc63; // BLT x13, x12, 24
	#4 branch_pc = pc;
	// This instruction should enter the pipe and not execute
	#4 inst = 32'h01080833; // add x16, x16, x16 /* x16  = 8*66408 */
	#4 assert(pc == branch_pc + 4);
	#4 inst = NOP; 
	#4 assert(pc == branch_pc + 24);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 28);
	#4 inst = NOP;
	#4 assert(pc == branch_pc + 32);
	#4 assert(registers[16] == 32*66408);

	//!Cont : taken - not taken ; taken - taken


	// stalls

	#8 inst = 32'h00102023; // sw x1, 0(x0)
	#8 inst = 32'h00002103; // lw x2, 0(x0)
	#8 inst = NOP;
	#8 inst = NOP;
	#8 inst = NOP;
	#8 assert(mem[0] == registers[1]);
	#8 assert(registers[2] == registers[1]);
	

	$stop;

end

endmodule
