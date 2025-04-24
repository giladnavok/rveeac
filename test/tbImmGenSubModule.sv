import typedefs::*;

localparam N_FUZZ = 1000000;

module tbImmGenSubmodule;

InstructionType instructionType;
logic [31:0] inst;
logic [31:0] imm;

ImmGenSubmodule 
immGenSubmodule (
	.instructionType(instructionType),
	.inst(inst),
	.imm(imm)
);

initial begin
	for (int i = 0; i < N_FUZZ; i++) begin
		inst = $random;
		instructionType = INST_TYPE_I;
		#1 assert ($signed(imm) == $signed(inst[31:20])) else $fatal("INST_TYPE_I");
		instructionType = INST_TYPE_S;
		#1 assert ($signed(imm) == $signed({inst[31:25], inst[11:7]})) else $fatal("INST_TYPE_S");
		instructionType = INST_TYPE_B;
		#1 assert ($signed(imm) == $signed({inst[31], inst[7],inst[30:25],inst[11:8], 1'b0})) else $fatal("INST_TYPE_B");
		instructionType = INST_TYPE_U;
		#1 assert ($signed(imm) == $signed({inst[31:12], 12'b0})) else $fatal("INST_TYPE_U");
		instructionType = INST_TYPE_J;
		#1 assert ($signed(imm) == $signed({inst[31], inst[19:12],inst[20],inst[30:21],1'b0})) else $fatal("INST_TYPE_J");
	end
end


endmodule

