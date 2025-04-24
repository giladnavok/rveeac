import typedefs::*;

module top;

apb_if imem_apb();
apb_if dmem_apb();

tb_core i1(
	.imem_apb(imem_apb),
	.dmme_apb(dmem_apb)
);
endmodule
