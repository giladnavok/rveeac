`include "typedefs.sv"

module RegfileSubmodule (
	input logic clk,
	input logic resetN,
	input logic [4:0] rs1,
	input logic [4:0] rs2,
	input logic [4:0] rd,

	input logic write,
	input logic [31:0] registerDataIn,
	input RegfileWriteSize writeSize,
	input RegfileWriteExtend writeExtend,

	output logic [31:0] registerDataA,
	output logic [31:0] registerDataB
);

logic [31:0] registers [31:0];

assign registerDataA = registers[rs1];
assign registerDataB = registers[rs2];

always_ff @(posedge clk or negedge resetN) begin
	if (!resetN) begin
		for (int i = 1; i < 32; ++i) begin
			registers[i] <= 32'b0;
		end
	end else begin
		if (write && rd != 0) begin
			case (writeSize)
				RF_WR_SIZE_BIT: begin
					registers[rd] <= {31'b0, registerDataIn[0]};
				end
				RF_WR_SIZE_B: begin
					case (writeExtend)
						RF_WR_Z_EXT: registers[rd] <= { 24'b0, registerDataIn[7:0] };
						RF_WR_S_EXT: registers[rd] <= { {24{registerDataIn[7]}}, registerDataIn[7:0] };
					endcase
				end
				RF_WR_SIZE_H: begin
					case (writeExtend)
						RF_WR_Z_EXT: registers[rd] <= { 16'b0, registerDataIn[15:0] };
						RF_WR_S_EXT: registers[rd] <= { {16{registerDataIn[15]}}, registerDataIn[7:0] };
					endcase
				end
				RF_WR_SIZE_W: 
					registers[rd] <= registerDataIn;
			endcase
		end
	end
end

endmodule