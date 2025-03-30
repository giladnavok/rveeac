`include "../typedefs.sv";

import typedefs::*;

localparam N = 10;

interface ComparerInterface;
	logic [31:0] subResult;
	logic [31:0] rA;
	logic [31:0] rB;
	logic [31:0] imm;
	ComparerInputSelector inputSel;
	ComparerOutputSelector outputSel;
	logic flip;

	logic signedLT;
	logic unsignedLT;
	logic eq;
	logic out;
endinterface

class Transaction;
	rand logic [31:0] rA, rB, imm;
	rand logic flip;
	logic [31:0] subResult;
	logic [3:0] rnd;
endclass

class Stimulus;
	virtual ComparerInterface intf;
	function new(virtual ComparerInterface intf);
		this.intf = intf;
	endfunction

	task run();
		Transaction txn;
		txn = new();
		repeat (N) begin
			intf.rA = $random;
			intf.rB = $random;
			if ($random > 1_500_000_000) intf.rA = intf.rB;
			intf.imm = $random;
			intf.subResult = intf.rA - intf.rB;
			intf.flip = $random > 0;

			#2;
			intf.inputSel = CMP_IN_SEL_RA_RB;
			intf.outputSel = CMP_OUT_SEL_EQ;
			#2;
			assert (intf.out == ((intf.rA == intf.rB) ^ intf.flip)) else $fatal("eq");
			#2;
			intf.inputSel = CMP_IN_SEL_RA_RB;
			intf.outputSel = CMP_OUT_SEL_LT;
			#2;
			assert (intf.out == (($signed(intf.rA) < $signed(intf.rB) ^ intf.flip))) else $fatal("RA RB signedLT");
			#2;
			intf.inputSel = CMP_IN_SEL_RA_RB;
			intf.outputSel = CMP_OUT_SEL_LTU;
			#2;
			assert (intf.out == ((intf.rA < intf.rB)) ^ intf.flip) else $fatal("RA RB unsignedLT");
			#2;
			intf.inputSel = CMP_IN_SEL_RA_IMM;
			intf.outputSel = CMP_OUT_SEL_LT;
			#2;
			assert (intf.out == (($signed(intf.rA) < $signed(intf.imm)) ^ intf.flip)) else $fatal("RA IMM signedLT");
			#2;
			intf.inputSel = CMP_IN_SEL_RA_IMM;
			intf.outputSel = CMP_OUT_SEL_LTU;
			#2;
			assert (intf.out == ((intf.rA < intf.imm) ^ intf.flip)) else $fatal("RA IMM signedLT");
		end
	endtask
endclass



module tbComparerSubmodule;

	ComparerInterface intf();
	Stimulus stim;

	ComparerSubmodule inst (
		.subResult(intf.subResult),
		.rA(intf.rA),
		.rB(intf.rB),
		.imm(intf.imm),
		.inputSel(intf.inputSel),
		.outputSel(intf.outputSel),
		.flip(intf.flip),
		.signedLT(intf.signedLT),
		.unsignedLT(intf.unsignedLT),
		.eq(intf.eq),
		.out(intf.out)
	);

	initial begin
		stim = new(intf);
		stim.run();
		$stop;
	end

endmodule


