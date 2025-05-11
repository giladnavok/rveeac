
module apb_slave # (
	SIZE = 64,
	INIT_FILENAME = "",
	SET_INDEX = 1'b0,
	POSSIBLE_WAITS = 1'b0
) (
	input logic clk,
	input logic rst_n,
	apb_if.slave apb,
	output logic [31:0] mem_o [SIZE - 1:0]
);

int wait_counter;

logic [31:0] mem [SIZE - 1:0];
assign mem_o = mem;

initial begin
	if (INIT_FILENAME != "") begin
		$readmemh(INIT_FILENAME, mem);
	end 
end

assign apb.rdata = (apb.sel && apb.enable && (apb.write == 1'b0) && (wait_counter == 0)) ? mem[(apb.addr/4) % SIZE] : 32'bx;
assign apb.ready = (apb.sel && apb.enable && (wait_counter == 0));
assign apb.slverr = 1'b0;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		wait_counter <= 0;
	end else if (apb.sel && !apb.enable) begin
		if (POSSIBLE_WAITS) begin
			if (($urandom % 10) == 0) begin
				wait_counter = ($urandom % 10) + 1;
			end
		end
	end else if (wait_counter > 0) begin
		wait_counter <= wait_counter - 1;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		if (INIT_FILENAME == "") begin
			if (SET_INDEX) begin
				for (int i = 0; i < SIZE; i++) begin
					mem[i] = i + 32'hffff0000;
				end
			end else begin
				for (int i = 0; i < SIZE; i++) begin
					mem[i] = '0;
				end
			end
		end
	end else begin
		if (apb.sel && apb.enable && (wait_counter == 0)) begin
			if (apb.write) begin
				case (apb.strb) 
					4'b1111: mem[apb.addr/4] <= apb.wdata;
					4'b0011: mem[apb.addr/4][15:0] <= apb.wdata[15:0];
					4'b0001: mem[apb.addr/4][7:0] <= apb.wdata[7:0];
					default: mem[apb.addr/4] <= apb.wdata;
				endcase
			end
		end
	end
end
endmodule
