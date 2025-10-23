import typedefs::*;

module tb_core_c_program (
);

localparam IMEM_SIZE = 1 << 17;
localparam DMEM_SIZE = 1 << 17;
localparam DMEM_SIZE_BYTES = 4*DMEM_SIZE;
localparam DMEM_OFFSET = 32'h20000;
localparam PERIPHERAL_BASE = 32'h1000_0000;
localparam UART_ADDR = 32'h1000_0000;
localparam CLEAR_ME_IRQ = 32'h1000_0001;

logic clk;
logic rst_n;
logic interrupt_req_ext;
logic trigger_interrupt_req_ext;
logic [31:0] inst;
logic [31:0] inst_d;
logic [15:0] registers_halfs [1:0][31:0];
logic [31:0] registers [31:0];
logic [7:0] mem [DMEM_SIZE*4 - 1:0];
logic [31:0] imem [IMEM_SIZE - 1:0];

genvar i;
generate 
for (i = 0;i < 32;i++) begin
	assign registers[i] = {registers_halfs[1][i], registers_halfs[0][i]};
end
endgenerate



apb_if imem_apb();
apb_if router_apb();
apb_if dmem_apb();
apb_if uart_apb();

apb_slave # (
	.SIZE(IMEM_SIZE),
	.INIT_FILENAME("imem.hex"),
	.POSSIBLE_WAITS(1'b1)
)  imem_inst (
	.clk(clk),
	.rst_n(rst_n),
	.apb(imem_apb.slave),
	.mem_o(imem)
);

apb_slave_byte # (
	.SIZE(DMEM_SIZE),
	.INIT_FILENAME("dmem.hex"),
	.POSSIBLE_WAITS(1'b1),
	.OFFSET(0)
) dmem_inst (
	.clk(clk),
	.rst_n(rst_n),
	.apb(dmem_apb.slave),
	.mem_o(mem)
);

apb_router # (
	.DMEM_BASE(DMEM_OFFSET),
	.DMEM_BYTES(DMEM_SIZE_BYTES),
	.PERIPHERAL_BASE(PERIPHERAL_BASE)
) apb_router_inst (
	.s_core(router_apb.slave),
	.m_dmem(dmem_apb.master),
	.m_uart(uart_apb.master)
);

core core_inst (
	.clk(clk),
	.rst_n(rst_n),
	.imem_apb(imem_apb.master),
	.dmem_apb(router_apb.master),
	.registers_od(registers_halfs),
	.interrupt_req_ext_i(interrupt_req_ext)
);

assign uart_apb.ready = 1'b1;
assign uart_apb.slverr = 1'b0;
assign uart_apb.rdata = 32'b0;
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		interrupt_req_ext <= 1'b0;
	end else begin
		if (trigger_interrupt_req_ext) interrupt_req_ext <= 1'b1;
		if (uart_apb.sel && !uart_apb.enable && uart_apb.write) begin
			if (uart_apb.addr == UART_ADDR) begin
				static byte ch;
				ch = uart_apb.wdata[7:0];
				$write("%c", ch);
			end else if (uart_apb.addr == CLEAR_ME_IRQ) begin
				interrupt_req_ext <= 1'b0;
			end
		end
	end
end




always #2 clk = ~clk;

initial begin
	rst_n = 1'b0;
	clk = 1'b0;
	trigger_interrupt_req_ext = 1'b0;
	#1 rst_n = 1'b1;
end

always begin
	#4 if ((imem_apb.rdata == 32'h0000006f)) begin
		# 32;
		$stop;
	end
end

always begin
	#400000;
	trigger_interrupt_req_ext = 1'b0;
	#4 trigger_interrupt_req_ext = 1'b0;
end

endmodule
