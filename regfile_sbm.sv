import typedefs::*;

module regfile_sbm (
	// General Signals // 
	// --------------- // 
	input logic clk,
	input logic rst_n,
	//input logic second_cycle, // if used change to first

	// Input Controls //
	// -------------- //
	input logic write_i,
	//input cs_size write_size_i,
	//input cs_ext write_ext_i,

	// Input Data //
	// ---------- //
	input logic [4:0] rs1_i,
	input logic [4:0] rs2_i,
	input logic [4:0] rd_i,
	input logic [15:0] write_data_i,
	input logic rd_h_sel_i,
	input logic rs2_h_sel_i,

	// Output Data //
	// ----------- //
	output logic [31:0] rs1_do,
	output logic [15:0] rs2_do
);

//!Cont Move extention logic outside to reuse for load/stores

logic [15:0] registers [1:0][31:0];
assign rs1_do = { registers[1][rs1_i], registers[0][rs1_i] };
assign rs2_do = registers[rs2_h_sel_i][rs2_i];

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (int i = 0; i < 32; i++) begin
			registers[0][i] <= '0;
			registers[1][i] <= '0;
		end
	end else begin
		if (write_i && rd_i != 1'b0) begin
			registers[rd_h_sel_i][rd_i] <= write_data_i;
		end
	end
end


// EXT in regfile version //
// ---------------------- //
//always_ff @(posedge clk or negedge rst_n) begin
//	if (!rst_n) begin
//		for (int i = 0; i < 32; i++) begin
//			registers[0][i] <= '0;
//			registers[1][i] <= '0;
//		end
//	end else begin 
//		if (write_i && rd_i != 0) begin
//			case (write_size_i) 
//				SIZE_W: begin
//					registers[rd_h_sel_i][rd_i] <= write_data_i;
//				end
//				SIZE_H: begin
//					if (!second_cycle_i) begin
//						registers[rd_h_sel_i][rd_i] <= write_data_i;
//					end else begin
//						registers[rd_h_sel_i][rd_i] <= (write_ext_i == EXT_Z) ?
//							16'b0 : {16{registers[0][rd_i]}};
//					end
//				end
//				SIZE_B: begin
//					if (!second_cycle_i) begin
//						registers[rd_h_sel_i][rd_i][7:0] <= write_data_i[7:0];
//						registers[rd_h_sel_i][rd_i][15:8] <= (write_ext_i == EXT_Z) ?
//							8'b0 : {8{registers[0][rd_i][7]}};
//					end else begin
//						registers[rd_h_sel_i][rd_i] <= (write_ext_i == EXT_Z) ?
//							16'b0 : {16{registers[0][rd_i][15]}};
//					end
//				end
//				SIZE_BIT: begin // BIT writes start with zeroing the upper half
//					if (!second_cycle_i) begin
//						registers[rd_h_sel_i][rd_i] <= registers[0][0];
//					end else begin
//						registers[rd_h_sel_i][rd_i] <= { 15'b0 , write_data_i[0] };
//					end
//				end
//			endcase
//		end
//	end
//end
endmodule
