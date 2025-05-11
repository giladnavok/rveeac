
module accel_dummy_sbm (
	input logic clk,
	input logic rst_n,

	input logic load_key_i,
	input logic start_enc_i,
	input logic start_dec_i,

	input logic [127:0] data_i,

	output logic [127:0] data_o,
	output logic ready_o,
	output logic done_o,
	output logic rf_en_o
);

logic [127:0] key;
logic [127:0] stage_in;
logic [127:0] stage_out;

enum logic [2:0] { ST_IDLE, ST_ENC_DEC } state_e;

int counter;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_IDLE;
		ready_o <= 1'b1;
		done_o <= 1'b0;
		key	<= '0;
	end else begin
		case (state_e)
			ST_IDLE: begin
				done_o <= 1'b0;
				if (load_key_i) key <= data_i;
				else if (start_enc_i || start_dec_i) begin
					state_e <= ST_ENC_DEC;
					ready_o <= 1'b0;
					counter <= 64;
				end
			end
			ST_ENC_DEC: begin
				counter <= counter - 1;
				if (counter == 1) begin 
					state_e <= ST_IDLE;
					done_o <= 1'b1;
					ready_o <= 1'b1;
				end
			end
		endcase
	end
end

			

assign stage_out = (stage_in << 1);
always_comb begin
	stage_in = '0;
	data_o = '0;
	rf_en_o = '0;
	if (state_e == ST_ENC_DEC) begin
		stage_in = data_i;
		data_o = stage_out;
		rf_en_o = 1'b1;
	end
end

endmodule
