import typedefs::*;

localparam N_FUZZ = 1000000;

module tbRegfileSubmodule;


interface RegfileInterface;
	logic clk;
	logic resetN;
	logic write;

	RegfileWriteSize writeSize;
	RegfileWriteExtend writeExtend;

	logic [4:0] rs1;
	logic [4:0] rs2;
	logic [4:0] rd;
	logic [31:0] writeData;

	logic [31:0] registerDataA;
	logic [31:0] registerDataB;
endinterface

RegfileInterface regfileInterface();


RegfileSubmodule
regfileSubmodule (
	.clk(regfileInterface.clk),
	.resetN(regfileInterface.resetN),
	.write(regfileInterface.write),
	.writeSize(regfileInterface.writeSize),
	.writeExtend(regfileInterface.writeExtend),
	.rs1(regfileInterface.rs1),
	.rs2(regfileInterface.rs2),
	.rd(regfileInterface.rd),
	.writeData(regfileInterface.writeData),
	.registerDataA(regfileInterface.registerDataA),
	.registerDataB(regfileInterface.registerDataB)
);


task automatic clkEdge(ref logic clk);
	clk = ~clk; #1 clk = ~clk;
endtask

task readTest(
	virtual RegfileInterface intf,
	input [31:0] tbRegisters [31:0],
	input [4:0] rs1,
	input [4:0] rs2
);
	intf.write = $random;
	intf.rs1 = rs1;
	intf.rs2 = rs2;
	#1 assert(intf.registerDataA == tbRegisters[rs1]);
	assert(intf.registerDataB == tbRegisters[rs2]);
endtask

task automatic writeTest(
	virtual RegfileInterface intf,
	ref logic [31:0] tbRegisters [31:0],
	input [31:0] writeData,
	input [4:0] rd
);
	intf.write = 1;
	intf.rd = rd;
	intf.writeData = writeData;
	if (rd == 0) begin
		writeData = 0;
	end 

	// Bit
	intf.writeSize = RF_WR_SIZE_BIT;
	// Zero extend
	intf.writeExtend = RF_WR_Z_EXT;
	//intf.clk = ~intf.clk; #1 intf.clk = ~intf.clk;
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert (intf.registerDataA == writeData[0]);
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert (intf.registerDataB == writeData[0]);

	// Sign extend, shouldn't make a difference
	intf.writeExtend = RF_WR_S_EXT; 
	//intf.clk = ~intf.clk; #1 intf.clk = ~intf.clk;
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert (intf.registerDataA == writeData[0]);
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert (intf.registerDataB == writeData[0]);

	// Byte
	intf.writeSize = RF_WR_SIZE_B;
	// Zero extend
	intf.writeExtend = RF_WR_Z_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA[7:0]) == $signed(writeData[7:0]));
	assert (intf.registerDataA[31:8] == '0);
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB[7:0]) == $signed(writeData[7:0]));
	assert (intf.registerDataB[31:8] == '0);

	// Sign extend
	intf.writeExtend = RF_WR_S_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA) == $signed(writeData[7:0]));
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB) == $signed(writeData[7:0]));

	// Half
	intf.writeSize = RF_WR_SIZE_H;
	// Zero extend
	intf.writeExtend = RF_WR_Z_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA[15:0]) == $signed(writeData[15:0]));
	assert (intf.registerDataA[31:16] == '0);
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB[15:0]) == $signed(writeData[15:0]));
	assert (intf.registerDataB[31:16] == '0);

	// Sign extend
	intf.writeExtend = RF_WR_S_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA) == $signed(writeData[15:0]));
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB) == $signed(writeData[15:0]));

	// Word
	intf.writeSize = RF_WR_SIZE_W;
	// Zero extend shouldn't make a difference
	intf.writeExtend = RF_WR_Z_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA) == $signed(writeData));
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB) == $signed(writeData));

	// Sign extend shouldn't make a difference
	intf.writeExtend = RF_WR_S_EXT; 
	clkEdge(intf.clk);

	intf.rs1 = rd;
	intf.rs2 = $random;
	#1 assert ($signed(intf.registerDataA) == $signed(writeData));
	intf.rs1 = $random;
	intf.rs2 = rd;
	#1 assert ($signed(intf.registerDataB) == $signed(writeData));

	tbRegisters[rd] = writeData;
endtask



logic [31:0] tbRegisters [31:0];
initial begin
	for (int i = 0; i < 32; i++) begin
		tbRegisters[i] = '0;
	end
end

initial begin
	regfileInterface.resetN = 0;
	#1 regfileInterface.resetN = 1;
	regfileInterface.clk = 0;
	regfileInterface.write = 0;
	regfileInterface.writeExtend = RF_WR_Z_EXT;
	regfileInterface.writeSize = RF_WR_SIZE_W;
	regfileInterface.writeData = 0;
	regfileInterface.rs1 = 0;
	regfileInterface.rs2 = 0;
	regfileInterface.rd = 0;

	repeat (N_FUZZ) begin
		readTest(regfileInterface, tbRegisters, $random, $random);
		writeTest(regfileInterface, tbRegisters, $random, $random);
	end
end




endmodule
