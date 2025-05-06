import typedefs::*;

module decode_unit (
	// General Signals //
	// --------------- //
	input logic clk,
	input logic rst_n,

	// Input Controls //
	// -------------- //
	input logic ready_i,
	input logic valid_i,
	
	// Input Data //
	// ---------- //
		
	input logic [31:0] inst_i,
	input logic [31:0] pc_i,
	input logic [31:0] reg32_i,

	// Output Controls //
	// --------------- //
	output cs_exe_s cs_exe_o,
	output logic jmp_o,
	output logic branch_o,
	output logic ready_o,
	output logic valid_o,
	output logic dmem_load_bypass_o,
	output logic exe_first_cycle_o,

	// Output Data //
	// ----------- //
	output logic [31:0] lsu_addr_o,
	output logic [31:0] dmem_load_addr_bypass_o,
	output logic [31:0] jmp_target_o,
	output logic [15:0] alu_b_o,
	output logic [15:0] wb_o,
	output logic [4:0] rd_o,
	output logic [4:0] rs32_o,
	output logic [4:0] rs16_o
);

// Internal Wires //
// -------------- //
	
logic first_cycle;
logic reg32_used_in_first_cycle;

logic stall;
logic store_load_stall;
logic full_read_after_write;
logic half_read_after_write;

// Decode 
opcode_e opcode;
logic [2:0] funct3;
logic [6:0] funct7;
logic [4:0] rd, rs1, rs2;
logic [31:0] imm;

// Control Signals
cs_s cs;

// Adder
logic [31:0] add_a, add_b, add_out;

// Serializer
logic [31:0] serializer_in;
logic [15:0] serializer_out;
logic serializer_en, forward_lower_half;

logic is_immediate_op;


// Internal Registers //
// ----------------- //

logic [4:0] rs32_d;
logic [4:0] rs16_d;
logic stall_d;
logic ready_i_d;
logic valid_i_d;


// Submodule Instances //
// ------------------- //

control_unit control (
	.clk(clk),
	.rst_n(rst_n),
	.first_cycle(first_cycle),
	
	.opcode_i(opcode),
	.funct3_i(funct3),
	.funct7_i(funct7),
	.exe_sel_d_i(cs_exe_o.sel),

	.cs_o(cs)
);

imm_gen_sbm imm_gen (
	.inst_type_i(cs.dec.sel.inst_type),
	.inst_i(inst_i),
	.imm_o(imm)
);

// Adder Logic  //
// ------------ //
assign add_b = imm;
assign add_a = (cs.dec.sel.add_sel == DEC_ADD_SEL_PC) ? pc_i : reg32_i;
assign add_out = add_a + add_b;


// Serializer Logic //
// ---------------- //
assign serializer_en = (cs.dec.en.alu_b || cs.dec.en.wb);
assign forward_lower_half = (cs.dec.sel.ser_start == SER_START_LH) ? 
	first_cycle : ~first_cycle;
assign serializer_out = (serializer_en && forward_lower_half) ? 
	serializer_in[15:0] : serializer_in[31:16];

always_comb begin
	case (cs.dec.sel.alu_wb_sel)
		ALU_WB_SEL_IMM: serializer_in = imm;
		ALU_WB_SEL_REG: serializer_in = reg32_i;
		ALU_WB_SEL_PC: serializer_in = pc_i;
		ALU_WB_SEL_ADDER: serializer_in = add_out;
	endcase
end

assign reg32_used_in_first_cycle = 
	cs.dec.en.dmem_load_bypass ||
	cs.dec.en.lsu_addr ||
	cs.dec.en.jmp ||
	cs.dec.en.branch
;
assign store_load_stall = 
	( 
		cs.dec.en.dmem_load_bypass && 
		cs_exe_o.en.dmem_store && 
		!ready_i_d
	);

assign full_read_after_write = 
	((rd_o != 5'b0) && 
		(
			(rd_o == rs1) && 
			first_cycle && 
			cs_exe_o.en.rf_write && 
			reg32_used_in_first_cycle
		)
	);

assign half_read_after_write = 
	((rd_o != 5'b0) && 
		(
			(rd_o == rs2) && 
			first_cycle && 
			cs.dec.en.alu_b && 
			(cs_exe_o.en.wb_order_flip != (cs.dec.sel.ser_start == SER_START_UH))
		)
	);
		
assign stall = 
	(store_load_stall ||
	full_read_after_write ||
	half_read_after_write)
	&& !stall_d && valid_o;
;

assign is_immediate_op = cs.dec.en.alu_b && (cs.dec.sel.alu_wb_sel == ALU_WB_SEL_IMM);
assign dmem_load_addr_bypass_o = add_out;

// Generate first_cycle
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n || !valid_i) first_cycle <= 1'b1;
	else if (stall) first_cycle <= first_cycle;
	else if (ready_o) first_cycle <= 1'b1; 
	else first_cycle <= 1'b0;
end

// Sample delayed signals
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		stall_d <= 1'b0;
		ready_i_d <= 1'b0;
		valid_i_d <= 1'b0;
		rs16_d <= 5'b0;
		rs32_d <= 5'b0;
	end else begin
		stall_d <= stall;
		ready_i_d <= ready_i;
		valid_i_d <= valid_i;
		rs16_d <= rs16_o;
		rs32_d <= rs32_o;
	end
end

// Decode Logic //
// ------------ //
assign opcode = opcode_e'(inst_i[6:0]);
assign funct3 = inst_i[14:12];
assign funct7 = inst_i[31:25];
assign rd = inst_i[11:7];
assign rs1 = inst_i[19:15];
assign rs2 = inst_i[24:20];


// Output Interface //
// ---------------- //

assign valid_o = valid_i && valid_i_d;
assign ready_o = ( !first_cycle || !valid_i ) && !stall && !stall_d;
assign jmp_o = first_cycle && cs.dec.en.jmp && valid_i;
assign branch_o = first_cycle && !stall_d && cs.dec.en.branch && valid_i;
assign dmem_load_bypass_o = cs.dec.en.dmem_load_bypass && valid_i && first_cycle && !stall;
assign jmp_target_o = add_out;

always_comb begin
	if (cs.dec.en.reg32_use && !store_load_stall) begin
		if (cs.exe.en.dmem_store && !first_cycle) begin
			rs32_o = rs2;
		end else begin
			rs32_o = (cs.dec.en.lsu_addr || cs.dec.en.dmem_load_bypass || cs.dec.en.jmp) ? rs1 : rs2;
		end
	end else begin
		rs32_o = rs32_d;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		lsu_addr_o <= '0;
		alu_b_o <= '0;
		wb_o <= '0;
		rd_o <= '0;
		rs16_o <= '0;
		cs_exe_o <= '0;
		exe_first_cycle_o <= 1'b0;
	end else begin
		if ((!stall && (ready_i || ready_i_d) && (valid_i || valid_i_d))) begin
			exe_first_cycle_o <= first_cycle;
			if (first_cycle && cs.dec.en.lsu_addr) begin
				lsu_addr_o <= add_out;
			end
			if (cs.dec.en.alu_b && !(cs.dec.en.forward_just_one_half && !first_cycle)) begin 
				alu_b_o <= serializer_out;
			end
			if (cs.dec.en.wb) begin
				wb_o <= serializer_out;
			end
			if (cs.dec.en.cs_exe) begin
				cs_exe_o <= cs.exe;
			end
			if (cs.dec.en.reg16_use && first_cycle) begin
				rs16_o <= rs1;
			end
			if (cs.exe.en.rf_write) begin
				rd_o <= rd;
			end
		end else begin
			exe_first_cycle_o <= 1'b0;
		end
	end
end

endmodule
