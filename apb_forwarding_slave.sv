
module apb_forwarding_slave
 (
	input logic clk,
	input logic rst_n,
	apb_if.slave apb,

	input logic [31:0] forward,

	output logic [31:0] requested
);


always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		apb.ready <= '0;
		apb.slverr <= '0;
		apb.rdata <= '0;
		requested <= '0;
	end else begin
		if (apb.sel && !apb.enable) begin
			apb.ready <= 1'b1;
			apb.rdata <= forward;
			requested <= apb.addr;
		end else if (apb.ready) begin
			apb.ready <= 1'b0;
			apb.rdata <= 32'bx;
		end else begin
			apb.rdata <= 32'bx;
		end
	end
end
endmodule
