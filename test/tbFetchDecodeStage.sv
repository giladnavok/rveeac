
module tbFetchDecodeStage;



logic clk;
logic resetN;
logic comparerOut;
logic [31:0] pc;
logic [31:0] inst;
logic [31:0] registerWriteData;
ExecutionWriteBackStageControlSignals executionWriteBackControlSignals;
ExecutionWriteBackStageData executionWriteBackData;

FetchDecodeStage
fethcDecodeStage (
	.clk(clk),
	.resetN(resetN),
	.comparerOut(comparerOut),
	.inst(inst),
	.registerWriteData(registerWriteData),
	.executionWriteBackControlSignals(executionWriteBackControlSignals),
	.executionWriteBackData(executionWriteBackData),
	.pc(pc)
);


//MemorySubmodule 
//
//imem (
//	.clk(clk),
//	.resetN(resetN),
//	.addr(pc),
//	.write(1'b0),
//	.din(32'b0),
//	.dout(inst)
//);

initial begin
	inst = 



endmodule
