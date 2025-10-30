import typedefs::*;

module decode_unit (
	// --------- General Signals --------
	input logic clk, 							///< Rising-edge reference clock
	input logic rst_n, 							///< Async active-low reset

	// --------- Input Controls  --------
	input logic ready_i, 						///< Execution stage can accept controls and data
	input logic valid_i, 						///< Input data from IF stage is valid
	input logic exe_dmem_apb_ready_d_i, 		///< If the dmem apb interface in EXE stage is ready
												///	 indicates whether a load bypass is possible
												
	input logic misspredict_i, 					///< Signals the current instruction was misspredicted 
												///  and should be flushed.
	input logic interrupt_i, 					///< Triggers an interrupt when asserted.
	
	input logic accel_ready_i,					///< Signals if the accelerator in EXE stage is ready.
												///  Used for a `wait for accelerator` instruction

	// --------- Input Data  ------------
	input logic [31:0] inst_i, 					///< Instruction from IF stage
	input logic [31:0] pc_i, 					///< Instruction's PC from IF stage
	input logic [31:0] reg32_i, 				///< 32 bit register port data.
	input logic [31:0] interrupt_jmp_target_i, 	///< Valid when an interrupt is asserted and contains the interrupt 		
												///  jump target.
	input logic [31:0] mepc_i, 					///< The value of the MEPC CSR. Used as a jump target in MRET.
	input logic [15:0] exe_regfile_write_half_i,///< Forwarded Value of the half currently written to the regfile in EXE stage.
												///	 Used to deal with a full read after write of rs2 hazard.

	// --------- Output Controls --------
	output cs_exe_s cs_exe_o, 					///< Control signals for EXE stage
	output logic jmp_o, 						///< Jump signal for IF stage.
	output logic branch_o, 						///< Branch signal for IF stage
	output logic ready_o, 						///< Instruction decode finished, ready for next instruction
	output logic valid_o, 						///< Control signals and output data for EXE stage are valid
	output logic dmem_load_bypass_o, 			///< Bypass to EXE stage - start read transfer
	output logic exe_first_cycle_o, 			///< First cycle signal for EXE stage
	output logic fetch_stall_for_jmp_target_o,	///< Asserted when the IF stage should pause fetching, until the 
												///  correct jump target is outputed.
	output logic resume_execution_from_dec_inst_o, ///< Execution after interrupt handling should resume from the 
												   ///  instruction currently in ID stage. 
												
	output logic ready_for_interrupt_o,			///< Asserted when the ID is ready to recieve an interrupt.
	output logic accel_rf_write_o,			

	// --------- Output Data  -----------
	output logic [31:0] lsu_store_addr_o, 		///< Store address for LSU - FF
	output logic [31:0] lsu_load_addr_bypass_o, ///< Bypass to EXE stage - Load address for LSU - Combinatorical
	output logic [31:0] jmp_target_o, 			///< Jump target for IF stage.
	output logic [15:0] alu_a_o, 				///< ALU input a data register for EXE stage.
	output logic [15:0] alu_b_o, 				///< ALU input b data register for EXE stage.
	output logic [15:0] wb_o, 					///< WB data from EXE stage.
	output logic [4:0] rd_o, 					///< Register file write port index.
	output logic [4:0] rs32_o, 					///< Register file 32 bit read port index.
	output logic [4:0] rs16_o, 					///< Register file 16 bit read port index.
	output logic inst31_o, 					

	output logic [11:0] csr_addr_o,				///< CSR Address register for EXE stage.
	output logic [31:0] pc_o					///< Program counter of currently decoded instruction
);

// ===============================
//			Internal Wires        
// ===============================
	
logic reg32_used_in_first_cycle;

logic full_read_after_write_rs1_hazard;
logic full_read_after_write_rs2_hazard;
logic half_read_after_write_hazard;
logic trigger_stall_when_ready;
logic stall_one_cycle;
logic store_load_hazard;

logic signal_jmp_issue_first;
logic signal_jmp_wait_fetch_or_interrupt;
logic signal_branch_issue_first;

logic inst_jmp_or_branch;

logic [31:0] jmp_target;
logic [31:0] reg32_i_first_cycle;

logic first_cycle;
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

// Serializers
logic [31:0] ser_alu_a_data_in;
logic [15:0] ser_alu_a_data_out;
logic ser_alu_a_start;
cs_ser_start ser_alu_a_start_half;

logic [31:0] ser_alu_b_wb_data_in;
logic [15:0] ser_alu_b_wb_data_out;
logic ser_alu_b_wb_start;
cs_ser_start ser_alu_b_wb_start_half;


// ===============================
//			Internal Registers        
// ===============================

logic [31:0] inst;
logic [31:0] pc;

logic signaled_jmp;
logic signaled_branch;

logic ready_i_d;
logic valid_i_d;

logic stall_one_cycle_d;
logic rs16_half_order_flip_d;

logic [4:0] rs32_o_d;
logic [31:0] reg32_i_d;
logic valid_o_d;



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

	.funct12_least_5_i(rs2),

	.exe_sel_d_i(cs_exe_o.sel),

	.cs_o(cs)
);

imm_gen_sbm imm_gen (
	.inst_type_i(cs.dec.sel.inst_type),
	.inst_i(inst),
	.imm_o(imm)
);

serializer_32_to_16 #(
	.SAMPLE_ON_START(1)
) sample_ser_alu_a (
	.clk(clk),
	.rst_n(rst_n),
	
	.data_i(ser_alu_a_data_in),
	.start_i(ser_alu_a_start),
	.start_half_i(ser_alu_a_start_half),
	
	.data_o(ser_alu_a_data_out)
);

serializer_32_to_16 #(
	.SAMPLE_ON_START(0)
) no_sample_ser_alu_b_wb (
	.clk(clk),
	.rst_n(rst_n),
	
	.data_i(ser_alu_b_wb_data_in),
	.start_i(ser_alu_b_wb_start),
	.start_half_i(ser_alu_b_wb_start_half),
	
	.data_o(ser_alu_b_wb_data_out)
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
// * ST_WAIT_FETCH:   Wait for the IF stage to finish fetching.
// * ST_WAIT_FOR:     Wait for certain signals before resuming execution.

enum logic [1:0] {ST_ISSUE_FIRST, ST_ISSUE_SECOND, ST_WAIT_FETCH, ST_WAIT_FOR} state_e, state_e_d;

localparam logic [31:0] NOP = 32'h00000013;
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e <= ST_WAIT_FETCH;
		inst <= NOP;
		pc <= '0;
	end else begin
		case (state_e)
			ST_ISSUE_FIRST: begin
				if (cs.dec.en.wait_for_interrupt || cs.dec.en.wait_for_accel) begin
					state_e <= ST_WAIT_FOR;
				end else if (ready_i) begin
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
			ST_WAIT_FOR: begin
				if (interrupt_i) begin
					state_e <= ST_WAIT_FETCH;
				end

				if (cs.dec.en.wait_for_accel && accel_ready_i) begin
					if (valid_i) begin
						inst <= inst_i;
						pc <= pc_i;
						state_e <= ST_ISSUE_FIRST;
					end else begin
						state_e <= ST_WAIT_FETCH;
					end
				end
			end
		endcase
	end
end

// Sample delayed signals
always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		state_e_d <= ST_WAIT_FETCH;
		stall_one_cycle_d <= 1'b0;
		ready_i_d <= 1'b0;
		valid_i_d <= 1'b0;
		rs32_o_d <= 5'b0;
		valid_o_d <= 1'b0;
		rs16_half_order_flip_d <= '0;
		reg32_i_d <= '0;
	end else begin
		state_e_d <= state_e;
		stall_one_cycle_d <= stall_one_cycle;
		rs32_o_d <= rs32_o;
		valid_o_d <= valid_o;
		rs16_half_order_flip_d <= cs.dec.en.rs16_half_order_flip;

		if (cs.dec.en.rs1_in_second_cycle) begin
			if (issue && first_cycle) begin
				if (full_read_after_write_rs2_hazard) begin
					if (!cs_exe_o.en.wb_order_flip) begin
						reg32_i_d[15:0] <= reg32_i[15:0];
						reg32_i_d[31:16] <= exe_regfile_write_half_i;
					end else begin
						reg32_i_d[15:0] <= exe_regfile_write_half_i;
						reg32_i_d[31:16] <= reg32_i[31:16];
					end
				end else begin
					reg32_i_d <= reg32_i;
				end
			end
		end

	end
end

// Sample signaled_jmp and signaled_branch

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		signaled_jmp <= 1'b0;
		signaled_branch <= 1'b0;
	end else begin
		case (state_e) 
			ST_ISSUE_FIRST: begin
				signaled_jmp <= signal_jmp_issue_first;
				signaled_branch <= signal_branch_issue_first;
			end
			ST_ISSUE_SECOND: begin
				signaled_jmp <= 1'b0;
				signaled_branch <= 1'b0;
			end
			ST_WAIT_FETCH, ST_WAIT_FOR: signaled_jmp <= !valid_i && signal_jmp_wait_fetch_or_interrupt;
		endcase
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
				alu_b_o <= ser_alu_b_wb_data_out;
			end
			if (cs.dec.en.wb) begin
				wb_o <= ser_alu_b_wb_data_out;
			end
			if (cs.dec.en.cs_exe) begin
				cs_exe_o <= cs.exe;
			end
			if (cs.exe.en.reg16_use && first_cycle) begin
				rs16_o <= rs1;
			end
			if (cs.exe.en.rf_write) begin
				rd_o <= rd;
			end
			if (cs.dec.en.csr_addr) begin
				csr_addr_o <= imm;
			end
		end else if (misspredict_i) begin
			cs_exe_o.en <= CS_EXE_EN_DEFAULT;
			exe_first_cycle_o <= 1'b0;
		end else if (state_e == ST_WAIT_FETCH) begin
			cs_exe_o.en <= ready_i ? CS_EXE_EN_DEFAULT : cs_exe_o;
		end 
	end
end


// ===============================
//		Combinatorical Logic
// ===============================

// Adder Logic  //
// ------------ //
assign add_a = (cs.dec.sel.add_sel == DEC_ADD_SEL_PC) ? pc : reg32_i;
assign add_b = imm;
assign add_out = add_a + add_b;


// Serializers Logic //
// ---------------- //

assign ser_alu_a_data_in = reg32_i;
assign ser_alu_a_start = issue && !first_cycle;
assign ser_alu_a_start_half = cs.dec.en.rs16_half_order_flip ? SER_START_UH : SER_START_LH;

always_comb begin
	case (cs.dec.sel.alu_wb_sel)
		ALU_WB_SEL_IMM: ser_alu_b_wb_data_in = imm;
		ALU_WB_SEL_REG: ser_alu_b_wb_data_in = reg32_i_first_cycle;
		ALU_WB_SEL_PC: ser_alu_b_wb_data_in = pc;
		ALU_WB_SEL_ADDER: ser_alu_b_wb_data_in = add_out;
	endcase
end
assign ser_alu_b_wb_start = (cs.dec.en.alu_b || cs.dec.en.wb) && first_cycle;
assign ser_alu_b_wb_start_half = cs.dec.sel.ser_start;

// Hazard Detection and Stall Logic //
// -------------------------------- //
	
// Hazards 
assign reg32_used_in_first_cycle = 
	cs.dec.en.dmem_load_bypass ||
	cs.dec.en.lsu_addr ||
	cs.dec.en.jmp ||
	cs.dec.en.branch
;
assign store_load_hazard = 
	( 
		cs.dec.en.dmem_load_bypass && 
		cs_exe_o.en.dmem_store &&
		!exe_dmem_apb_ready_d_i
	);

assign full_read_after_write_rs1_hazard = 
	((rd_o != 5'b0) && 
		(
			cs_exe_o.en.rf_write && 
			(
				((rd_o == rs1) && 
				reg32_used_in_first_cycle)
			)
		)
	);

assign half_read_after_write_hazard = 
	((rd_o != 5'b0) && 
		(
			(rd_o == rs2) && 
			cs_exe_o.en.rf_write && 
			cs.dec.en.alu_b && 
			cs_exe_o.en.rf_write && 
			(cs_exe_o.en.wb_order_flip != (cs.dec.sel.ser_start == SER_START_UH))
		)
	);

assign full_read_after_write_rs2_hazard = 
		((rd_o != 5'b0) && 
		cs_exe_o.en.rf_write && 
		((rd_o == rs2) &&
		(cs.dec.sel.alu_wb_sel == ALU_WB_SEL_REG)));


// Stall

assign trigger_stall_when_ready =
	(store_load_hazard ||
	full_read_after_write_rs1_hazard ||
	half_read_after_write_hazard);
		
assign stall_one_cycle = 
	trigger_stall_when_ready
	&& ready_i && !stall_one_cycle_d && valid_o;

// Jump Logic //
// ---------- //

assign signal_jmp_issue_first = 
	(state_e == ST_ISSUE_FIRST) && 
	(interrupt_i || (fetch_stall_for_jmp_target_o ? 1'b0 : cs.dec.en.jmp));

assign signal_branch_issue_first = 
	(state_e == ST_ISSUE_FIRST) && 
	(cs.dec.en.branch);

assign signal_jmp_wait_fetch_or_interrupt = 
	(state_e inside {ST_WAIT_FETCH, ST_WAIT_FOR}) && 
	(interrupt_i);

always_comb begin
	case (cs.dec.sel.jmp_target) 
		JMP_TARGET_SEL_ADDER: jmp_target = add_out;
		JMP_TARGET_SEL_MEPC: jmp_target = mepc_i;
	endcase
end

// Decode Logic //
// ------------ //
assign opcode = opcode_e'(inst[6:0]);
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign rd = inst[11:7];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];

// Misc //
// ---- //
	
assign first_cycle = (state_e == ST_ISSUE_FIRST);
assign inst_jmp_or_branch = (opcode inside {OPC_BRANCH, OPC_JAL, OPC_JALR});
assign reg32_i_first_cycle = first_cycle ? reg32_i : reg32_i_d;
always_comb begin
	case (state_e)
		ST_ISSUE_FIRST: issue = !misspredict_i &&
								ready_i && 
								!stall_one_cycle && 
								!cs.dec.en.wait_for_interrupt;
		ST_ISSUE_SECOND: issue = !misspredict_i;
		default: issue = 1'b0;
	endcase
end

// Output Combinatorical //
// --------------------- //

assign resume_execution_from_dec_inst_o = inst_jmp_or_branch || cs.dec.en.wait_for_accel;
assign ready_for_interrupt_o = (state_e != ST_ISSUE_SECOND);
assign pc_o = pc;
assign alu_a_o = ser_alu_a_data_out;
assign jmp_o = !signaled_jmp && (signal_jmp_issue_first || signal_jmp_wait_fetch_or_interrupt);
assign branch_o = !signaled_branch && signal_branch_issue_first;

always_comb begin
	inst31_o = inst[31];
	valid_o = 1'b0;
	ready_o = 1'b0;
	jmp_target_o = '0;
	lsu_load_addr_bypass_o = '0;
	dmem_load_bypass_o = 1'b0;
	rs32_o = cs.dec.en.reg32_use ? 
		((cs.dec.en.lsu_addr || cs.dec.en.dmem_load_bypass || cs.dec.en.jmp) ? rs1 : rs2) 
		: rs32_o_d;
	fetch_stall_for_jmp_target_o = cs.dec.en.jmp && full_read_after_write_rs1_hazard && !issue;
	accel_rf_write_o = 1'b0;
	jmp_target_o = '0;

	if (cs.dec.en.branch) begin
		jmp_target_o = jmp_target;
	end else if (cs.dec.en.jmp && !fetch_stall_for_jmp_target_o) begin
		jmp_target_o = jmp_target;
	end

	case (state_e)
		ST_ISSUE_FIRST: begin
			valid_o = !misspredict_i;
			if (issue) begin
				dmem_load_bypass_o = cs.dec.en.dmem_load_bypass;
				lsu_load_addr_bypass_o = cs.dec.en.dmem_load_bypass ? add_out : '0;
			end

			if (interrupt_i) begin
				jmp_target_o = interrupt_jmp_target_i;
			end
		end
		ST_ISSUE_SECOND: begin
			valid_o = 1'b1;
			ready_o = 1'b1;
			if (valid_o_d) begin
				if (cs.exe.en.dmem_store) begin
					rs32_o = rs2;
				end else if (cs.dec.en.rs1_in_second_cycle) begin
					rs32_o = rs1;
				end 
			end
		end
		ST_WAIT_FETCH: begin
			ready_o = 1'b1;
			valid_o = !ready_i_d && valid_o_d;

			if (interrupt_i) begin
				jmp_target_o = interrupt_jmp_target_i;
			end
		end
		ST_WAIT_FOR: begin
			if (cs.dec.en.wait_for_accel && accel_ready_i) begin
				ready_o = valid_i;
				accel_rf_write_o = 1'b1;
			end

			if (interrupt_i) begin
				jmp_target_o = interrupt_jmp_target_i;
			end
		end
	endcase
end

endmodule
