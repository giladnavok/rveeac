import typedefs::*;

localparam N_FUZZ = 1000000;

module tbALUSubmodule;

ALUOperation op;
logic [31:0] A;
logic [31:0] B;
logic [31:0] out;

ALUSubmodule 
alu (
	.op(op),
	.A(A),
	.B(B),
	.out(out)
);

initial begin
	repeat (N_FUZZ) begin
		A = $random;
		B = $random;
		op = ALU_ADD;
		#1 assert (out == (A + B));
		op = ALU_SUB;
		#1 assert (out == (A - B));
		op = ALU_AND;
		#1 assert (out == (A & B));
		op = ALU_OR;
		#1 assert (out == (A | B));
		op = ALU_SLL;
		#1 assert (out == (A << B[4:0]));
		op = ALU_SRL;
		#1 assert (out == (A >> B[4:0]));
		op = ALU_SRA;
		#1 assert (out == (A >>> B[4:0]));
	end
end


endmodule
