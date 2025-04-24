
module apb_slave # (
	INIT_FILENAME = ""
) (
	input logic clk,
	input logic rst_n,
	apb_if.slave apb
);

logic [31:0] mem [63:0];

initial begin
	if (INIT_FILENAME != "") begin
		$readmemh(INIT_FILENAME, mem);
	end 
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		apb.ready <= '0;
		apb.slverr <= '0;
		apb.rdata <= '0;
		for (int i = 0; i < 64; i++) begin
			mem[i] = i + 32'hffff0000;
		end
	end else begin
		if (apb.sel && !apb.enable) begin
			apb.ready <= 1'b1;
			if (apb.write) begin
				case (apb.strb) 
					4'b1111: mem[apb.addr/4] <= apb.wdata;
					4'b0011: mem[apb.addr/4][15:0] <= apb.wdata[15:0];
					4'b0001: mem[apb.addr/4][7:0] <= apb.wdata[7:0];
					default: mem[apb.addr/4] <= apb.wdata;
				endcase
			end else begin
				apb.rdata <= mem[(apb.addr/4) % 64];
			end
		end else if (apb.ready) begin
			apb.ready <= 1'b0;
			apb.rdata <= 32'bx;
		end else begin
			apb.rdata <= 32'bx;
		end
	end
end
endmodule
