import typedefs::*;

module regfile_sbm (
	// --------- General Signals -------
	input logic clk,
	input logic rst_n,

	// --------- Input Controls-------
	input logic write_i,

	// --------- Input Data-------
	input logic [4:0] rs32_i,
	input logic [4:0] rs16_i,
	input logic [4:0] rd_i,
	input logic [15:0] write_data_i,
	input logic rd_h_sel_i,
	input logic rs16_h_sel_i,

	// --------- Output Data-------
	output logic [31:0] rs32_do,
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	output logic [15:0] rs16_do

);

logic [15:0] registers [1:0][31:0];
assign rs32_do = { registers[1][rs32_i], registers[0][rs32_i] };
assign rs16_do = registers[rs16_h_sel_i][rs16_i];

`ifdef DEBUG
	assign registers_od = registers;
`endif

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		for (int i = 0; i < 32; i++) begin
			registers[0][i] <= '0;
			registers[1][i] <= '0;
		end
	end else begin
		if (write_i && rd_i != 5'b0) begin
			registers[rd_h_sel_i][rd_i] <= write_data_i;
		end
	end
end

endmodule
