
module branch_predictor_sbm (
	// Data Inputs // 
	// ----------- // 
	input logic imm_sign_i,

	// Control Outputs //
	// --------------- //
	output logic take_branch_o
);

assign take_branch_o = imm_sign_i;

endmodule

