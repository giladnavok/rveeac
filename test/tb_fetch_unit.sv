import typedefs::*;

module tb_fetch_unit;

logic clk;
logic rst_n;
logic jmp;
logic branch;
logic ready;
logic branch_cmp_result_valid;

apb_if apb();
apb_if dummy();

logic branch_cmp_result;
logic [31:0] jmp_target;

logic valid;
logic branch_taken;

logic [31:0] pc;
logic [31:0] inst;

fetch_unit fetch (
	.clk(clk),
	.rst_n(rst_n),

	.jmp_i(jmp),
	.branch_i(branch),

	.ready_i(ready),
	.branch_cmp_result_valid_i(branch_cmp_result_valid),

	.imem_apb(apb),
	.branch_cmp_result_i(branch_cmp_result),
	.jmp_target_i(jmp_target),
	.valid_o(valid),
	.branch_taken_o(branch_taken),
	.pc_o(pc),
	.inst_o(inst)
);

apb_slave apb_slave_inst (
	.clk(clk),
	.rst_n(rst_n),
	.apb(apb)
);

always begin
	#2 clk = ~clk;
end
int counter;

always begin
	#8 ready = ~ready;
end

always begin
	#8 counter += 1;
	if (counter == 8 && ready == 0) begin
		$display("HEELO");
		branch = 1'b1;
		#4 branch = 1'b0;
		#8 branch_cmp_result = 1'b0;
		branch_cmp_result_valid = 1'b1;
	end
end
	
initial begin
	counter = 0;
	clk = 0;
	rst_n = 0;
	#1 rst_n = 1;
	ready = 1'b0;
	jmp = 1'b0;
	branch = 1'b0;
	branch_cmp_result = 1'b0;
	branch_cmp_result_valid = 1'b0;
	jmp_target = '0;
end




endmodule
