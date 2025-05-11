import typedefs::*;

module decode_unit (
	// --------- General Signals --------
	input logic clk, 							///< Rising-edge reference clock
	input logic rst_n, 							///< Async active-low reset

	// --------- Input Controls  --------
	input logic ready_i, 						///< Execution stage can accept controls and data
	input logic valid_i, 						///< Input data from IF stage is valid
	input logic exe_dmem_apb_ready_i, 				///<  !!!!
	input logic misspredict_i, 				///<  !!!!
	

	// --------- Input Data  ------------
	input logic [31:0] inst_i, 					///< Instruction from IF stage
	input logic [31:0] pc_i, 					///< Instruction's PC from IF stage
	input logic [31:0] reg32_i, 				///< 32 bit register port data.

	// --------- Output Controls --------
	output cs_exe_s cs_exe_o, 					///< Control signals for execution stage
	output logic jmp_o, 						///< Jump signal for IF stage.
	output logic branch_o, 						///< Branch signal for IF stage
	output logic ready_o, 						///< Instruction decode finished, ready for next instruction
	output logic valid_o, 						///< Control signals and output data for execution stage are valid
	output logic dmem_load_bypass_o, 			///< Bypass to execution stage - start read transfer
	output logic exe_first_cycle_o, 			///< First cycle signal for execution stage

	// --------- Output Data  -----------
	output logic [31:0] lsu_store_addr_o, 		///< Store address for LSU - FF
	output logic [31:0] lsu_load_addr_bypass_o, ///< Bypass to execution stage - Load address for LSU - Combinatorical
	output logic [31:0] jmp_target_o, 			///< Jump target for IF stage.
	output logic [15:0] alu_b_o, 				///< ALU input b data for execution stage.
	output logic [15:0] wb_o, 					///< WB data fro execution stage.
	output logic [4:0] rd_o, 					///< Register file write port index.
	output logic [4:0] rs32_o, 					///< Register file 32 bit read port index.
	output logic [4:0] rs16_o, 					///< Register file 16 bit read port index.
	output logic inst31_o 					///< Register file 16 bit read port index.
);

// ===============================
//			Internal Wires        
// ===============================
	
logic first_cycle;
logic reg32_used_in_first_cycle;

logic stall_one_cycle;
logic store_load_stall;
logic full_read_after_write;
logic half_read_after_write;
logic issue;

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


// ===============================
//			Internal Registers        
// ===============================

logic [31:0] inst;
logic [31:0] pc;
logic [4:0] rs32_d;
logic ready_i_d;
logic valid_i_d;
logic stall_one_cycle_d;
logic state_e_d;



// ===============================
//			Sub-modules
// ===============================

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
	.inst_i(inst),
	.imm_o(imm)
);

// ===============================
//			Seqential Logic
// ===============================
//

// -------------------------------
// 		Decode unit FSM
// -------------------------------
// * ST_ISSUE_FIRST:  Issue first batch of controls and data to exe if it is ready, otherwise stall.
// * ST_ISSUE_SECOND: Issue the second batch, and sample next instruction if ready, 
// 	 				  otherwise switch to ST_WAIT_FETCH to wait for IF.
// * ST_WAIT_FETCH: Wait for IF stage to finish fetching.

enum logic [1:0] {ST_ISSUE_FIRST, ST_ISSUE_SECOND, ST_WAIT_FETCH} state_e;

localparam logic [31:0] NOP = 32'h00000013;
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_WAIT_FETCH;
		inst <= NOP;
		pc <= '0;
	end else begin
		case (state_e)
			ST_ISSUE_FIRST: begin
				if (ready_i) begin
					state_e <= misspredict_i ? ST_WAIT_FETCH :
						stall_one_cycle ? ST_ISSUE_FIRST : ST_ISSUE_SECOND;
				end
			end
			ST_ISSUE_SECOND, ST_WAIT_FETCH: begin
				if (misspredict_i) begin
					state_e <= ST_WAIT_FETCH;
				end else if (valid_i) begin
					inst <= inst_i;
					pc <= pc_i;
					state_e <= ST_ISSUE_FIRST;
				end else begin
					state_e <= ST_WAIT_FETCH;
				end
					
			end
		endcase
	end
end

// Sample delayed signals
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e_d <= '0;
		stall_one_cycle_d <= 1'b0;
		ready_i_d <= 1'b0;
		valid_i_d <= 1'b0;
		rs32_d <= 5'b0;
	end else begin
		state_e_d <= state_e;
		stall_one_cycle_d <= stall_one_cycle;
		rs32_d <= rs32_o;
	end
end

// Output Sequential //
// ----------------- //

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		lsu_store_addr_o <= '0;
		alu_b_o <= '0;
		wb_o <= '0;
		rd_o <= '0;
		rs16_o <= '0;
		cs_exe_o <= '0;
		exe_first_cycle_o <= 1'b0;
	end else begin
		if (issue) begin
			exe_first_cycle_o <= first_cycle;
			if (first_cycle && cs.dec.en.lsu_addr) begin
				lsu_store_addr_o <= add_out;
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
		end else if (misspredict_i) begin
			cs_exe_o <= CS_EXE_EN_DEFAULT;
			exe_first_cycle_o <= 1'b0;
		end else if (state_e == ST_WAIT_FETCH) begin
			cs_exe_o <= ready_i ? CS_EXE_EN_DEFAULT : cs_exe_o;
		end 
	end
end


// ===============================
//		Combinatorical Logic
// ===============================

// Adder Logic  //
// ------------ //
assign add_b = imm;
assign add_a = (cs.dec.sel.add_sel == DEC_ADD_SEL_PC) ? pc : reg32_i;
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
		ALU_WB_SEL_PC: serializer_in = pc;
		ALU_WB_SEL_ADDER: serializer_in = add_out;
	endcase
end

// Stall logic //
// ----------- //
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
		!ready_i
	);

assign full_read_after_write = 
	((rd_o != 5'b0) && 
		(
			(rd_o == rs1) && 
			ready_i && 
			cs_exe_o.en.rf_write && 
			reg32_used_in_first_cycle
		)
	);

assign half_read_after_write = 
	((rd_o != 5'b0) && 
		(
			(rd_o == rs2) && 
			ready_i && 
			cs.dec.en.alu_b && 
			(cs_exe_o.en.wb_order_flip != (cs.dec.sel.ser_start == SER_START_UH))
		)
	);
		
assign stall_one_cycle = 
	(store_load_stall ||
	full_read_after_write ||
	half_read_after_write)
	&& !stall_one_cycle_d && valid_o;

// Decode Logic //
// ------------ //
assign opcode = opcode_e'(inst[6:0]);
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];


// Output Combinatorical //
// --------------------- //
assign first_cycle = (state_e == ST_ISSUE_FIRST);
assign issue = (((state_e == ST_ISSUE_FIRST) && ready_i && !stall_one_cycle) || (state_e ==  ST_ISSUE_SECOND)) && !misspredict_i;
always_comb begin
	inst31_o = inst[31];
	valid_o = 1'b0;
	ready_o = 1'b0;
	jmp_o = 1'b0;
	branch_o = 1'b0;
	jmp_target_o = '0;
	lsu_load_addr_bypass_o = '0;
	dmem_load_bypass_o = 1'b0;
	rs32_o = rs32_d;
	case (state_e)
		ST_ISSUE_FIRST: begin
			if (ready_i || !stall_one_cycle || misspredict_i) begin
				jmp_o = cs.dec.en.jmp;
				branch_o = cs.dec.en.branch;
				jmp_target_o = (cs.dec.en.jmp || cs.dec.en.branch) ? add_out : '0;
			end
			if (ready_i) begin
				if (!stall_one_cycle) begin
					if (misspredict_i) begin
						valid_o = 1'b0;
					end else begin
						valid_o = 1'b1;
						dmem_load_bypass_o = cs.dec.en.dmem_load_bypass;
						lsu_load_addr_bypass_o = cs.dec.en.dmem_load_bypass ? add_out : '0;
						rs32_o = cs.dec.en.reg32_use ? ((cs.dec.en.lsu_addr || cs.dec.en.dmem_load_bypass || cs.dec.en.jmp) ? rs1 : rs2) : rs32_d;
					end
				end else begin
					valid_o = 1'b1;
				end
			end else begin
				rs32_o = cs_exe_o.en.dmem_store ? rs2 : rs32_o;
				valid_o = 1'b1;
			end
		end
		ST_ISSUE_SECOND: begin
			if (misspredict_i) begin
				valid_o = 1'b0;
			end else begin
				rs32_o = cs.exe.en.dmem_store ? rs2 : rs32_o;
				valid_o = 1'b1;
				ready_o = 1'b1;
			end
		end
		ST_WAIT_FETCH: begin
			ready_o = 1'b1;
			valid_o = (state_e_d != ST_WAIT_FETCH);
		end
	endcase
end


endmodule
