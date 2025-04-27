import typedefs::*;

module apb_controller_sbm #(
	parameter int DAT_W = 32,
	parameter int ADDR_W = 32
) (
	
	
	// General Signals //
	// --------------- // 
	input logic clk,
	input logic rst_n,
		
	// Control Inputs  // 
	// --------------- // 
	input logic start_i,
	input logic dir_i,
	input cs_size write_size_i,

	// Interface
	apb_if.master apb,
	
	// Data Inputs // 
	// ----------- // 
	input logic [DAT_W - 1: 0] wdata_i,
	input logic [ADDR_W - 1: 0] addr_i,

	// Control Outputs  // 
	// --------------- // 
	output logic ready_o,
	output logic valid_o,
	output logic err_o,

	// Data Outputs // 
	// ------------ // 
	output logic [DAT_W - 1:0] rdata_o
);

enum logic [1:0] {
	ST_READY,
	ST_TRANS
} state_e;

localparam READ = 1'b0;
localparam WRITE = 1'b1;

always_comb begin
	ready_o = (state_e == ST_READY) ? 1'b1 : apb.ready;
	valid_o = (state_e == ST_TRANS) && apb.ready && !apb.slverr;
	err_o = apb.slverr;
	apb.addr = addr_i;
	apb.wdata = (dir_i == WRITE)? wdata_i : {DAT_W{1'b0}};
	apb.write = dir_i;

	if (dir_i) begin
		case (write_size_i) 
			SIZE_W: apb.strb = 4'b1111;
			SIZE_H: apb.strb = 4'b0011;
			SIZE_B: apb.strb = 4'b0001;
			default: apb.strb = 4'b1111;
		endcase
	end else apb.strb = 4'b0000;

	if (state_e == ST_READY) begin
		apb.sel = start_i;
		apb.enable = ~start_i;
	end else begin
		apb.sel = 1'b1;
		apb.enable = 1'b1;
	end

	rdata_o = apb.rdata;
end
		

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_READY;
	end else begin
		case (state_e)
			ST_READY: begin
				if (start_i) begin
					state_e <= ST_TRANS;
				end
			end
			ST_TRANS: begin
				if (apb.ready) begin
					state_e <= ST_READY;
				end
			end
		endcase
	end
end
endmodule
