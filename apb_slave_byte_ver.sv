
module apb_slave_byte # (
	SIZE = 64,
	INIT_FILENAME = "",
	SET_INDEX = 1'b0,
	POSSIBLE_WAITS = 1'b0
) (
	input logic clk,
	input logic rst_n,
	apb_if.slave apb,
	output logic [7:0] mem_o [SIZE*4 - 1:0]
);

int wait_counter;

logic [7:0] mem [SIZE * 4 - 1:0];
assign mem_o = mem;

initial begin
	if (INIT_FILENAME != "") begin
		$readmemh(INIT_FILENAME, mem);
	end 
end 
assign apb.rdata = (apb.sel && apb.enable && (apb.write == 1'b0) && (wait_counter == 0)) ? { mem[apb.addr + 3], mem[apb.addr + 2], mem[apb.addr + 1], mem[apb.addr] } :  32'bx;
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
				for (int i = 0; i < SIZE * 4 - 1; i++) begin
					mem[i] = i;
				end
			end else begin
				for (int i = 0; i < SIZE * 4 - 1; i++) begin
					mem[i] = '0;
				end
			end
		end
	end else begin
		if (apb.sel && apb.enable && apb.write && (wait_counter == 0)) begin
			if ( apb.strb[0] ) mem[apb.addr]     <= apb.wdata[7:0];
			if ( apb.strb[1] ) mem[apb.addr + 1] <= apb.wdata[15:8];
			if ( apb.strb[2] ) mem[apb.addr + 2] <= apb.wdata[23:16];
			if ( apb.strb[3] ) mem[apb.addr + 3] <= apb.wdata[31:24];
		end
	end
end
endmodule
