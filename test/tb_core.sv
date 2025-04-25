import typedefs::*;

module tb_core (
);

logic clk;
logic rst_n;

apb_if imem_apb();
apb_if dmem_apb();

apb_slave # (
	.INIT_FILENAME( "instructions.txt" )
) imem (
	.clk(clk),
	.rst_n(rst_n),
	.apb(imem_apb.slave)
);

apb_slave dmem (
	.clk(clk),
	.rst_n(rst_n),
	.apb(dmem_apb.slave)
);

core core_inst (
	.clk(clk),
	.rst_n(rst_n),
	.imem_apb(imem_apb.master),
	.dmem_apb(dmem_apb.master)
);


endmodule
