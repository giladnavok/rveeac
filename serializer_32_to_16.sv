import typedefs::*;

module serializer_32_to_16 #(
	SAMPLE_ON_START = 1
)(
	input logic clk,
	input logic rst_n,

	input logic start_i,
	input cs_ser_start start_half_i,
	input logic [31:0] data_i,

	output logic [15:0] data_o
);

logic start_i_d;
logic start_half_i_d;
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		start_i_d <= '0;
		start_half_i_d <= '0;
	end else begin
		start_i_d <= start_i;
		start_half_i_d <= start_half_i;
	end
end

logic [15:0] lower_half;
logic [15:0] upper_half;
assign lower_half = data_i[15:0];
assign upper_half = data_i[31:16];

logic [15:0] first_half;
logic [15:0] second_half;
generate 
if (SAMPLE_ON_START == 1) begin : sample_serializer

	logic start_i_d;

	always_comb begin
		first_half = '0;
		case (start_half_i) 
			SER_START_LH: first_half = lower_half;
			SER_START_UH: first_half = upper_half;
		endcase
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			start_i_d <= '0;
			second_half <= '0;
		end else begin
			if (start_i) begin
				case (start_half_i) 
					SER_START_LH: second_half <= upper_half;
					SER_START_UH: second_half <= lower_half;
					default: second_half <= '0;
				endcase
			end
			start_i_d <= start_i;
		end
	end

	assign data_o = start_i_d ? second_half : first_half;

end else begin : no_sample_serializer
	always_comb begin
		first_half = '0;
		case (start_half_i) 
			SER_START_LH: first_half = lower_half;
			SER_START_UH: first_half = upper_half;
		endcase
	end
	always_comb begin
		second_half = '0;
		case (start_half_i) 
			SER_START_LH: second_half = upper_half;
			SER_START_UH: second_half = lower_half;
		endcase
	end
	assign data_o = start_i ? first_half : second_half;
end
endgenerate
endmodule
