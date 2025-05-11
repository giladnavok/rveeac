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
	input logic [127:0] accel_di,
	input logic accel_write_en_i,

	// --------- Output Data-------
	output logic [31:0] rs32_do,
	`ifdef DEBUG
		output logic [15:0] registers_od [1:0][31:0],
	`endif
	output logic [15:0] rs16_do,
	output logic [127:0] accel_do

);

logic [15:0] registers [1:0][31:0];
assign rs32_do = { registers[1][rs32_i], registers[0][rs32_i] };
assign rs16_do = registers[rs16_h_sel_i][rs16_i];

// assign accel's registers to be x31-x28 (t6-t3)
assign accel_do = {
	registers[1][31], registers[0][31],
	registers[1][30], registers[0][30],
	registers[1][29], registers[0][29],
	registers[1][28], registers[0][28]
};

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
		if (accel_write_en_i) begin
			registers[1][31] <= accel_di[127:112];
			registers[0][31] <= accel_di[111:96];
			registers[1][30] <= accel_di[95:80];
			registers[0][30] <= accel_di[79:64];
			registers[1][29] <= accel_di[63:48];
			registers[0][29] <= accel_di[47:32];
			registers[1][28] <= accel_di[31:16];
			registers[0][28] <= accel_di[15:0];
		end
	end
end

endmodule
