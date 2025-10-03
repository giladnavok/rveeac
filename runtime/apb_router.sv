
module apb_router #(
	parameter DMEM_BASE = 32'h0000_4000,
	parameter DMEM_BYTES = 4*(1<<16),
	parameter UART_ADDR = 32'h1000_0000
) (
	apb_if.slave s_core,
	apb_if.master m_dmem,
	apb_if.master m_uart
);

localparam DMEM_LIMIT = DMEM_BASE + DMEM_BYTES;
logic sel_dmem;
logic sel_uart;
logic [31:0] dmem_addr_offset;
assign dmem_addr_offset = s_core.addr - DMEM_BASE;

assign sel_dmem = s_core.sel && (s_core.addr >= DMEM_BASE) && (s_core.addr <= DMEM_LIMIT);
assign sel_uart = s_core.sel && (s_core.addr == UART_ADDR);

// Broadcast all signals but sel
assign m_dmem.enable = s_core.enable;
assign m_dmem.write = s_core.write;
assign m_dmem.addr = dmem_addr_offset;
assign m_dmem.wdata = s_core.wdata;
assign m_dmem.strb = s_core.strb;

assign m_uart.enable = s_core.enable;
assign m_uart.write = s_core.write;
assign m_uart.addr = s_core.addr;
assign m_uart.wdata = s_core.wdata;
assign m_uart.strb = s_core.strb;

// Assign sel
assign m_dmem.sel = sel_dmem;
assign m_uart.sel = sel_uart;
assign s_core.ready = sel_dmem ? m_dmem.ready : m_uart.ready;
assign s_core.slverr = sel_dmem ? m_dmem.slverr : m_uart.slverr;
assign s_core.rdata = sel_dmem ? m_dmem.rdata : m_uart.rdata;

endmodule
