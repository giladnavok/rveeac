import typedefs::*;

module ControlSubmodule (
	input logic [6:0] opcode,
	input logic [2:0] funct3,
	input logic [6:0] funct7,

	input logic comparerLT,
	input logic comparerLTU,
	input logic comparerEQ,

	output InstructionType instructionType,

	output ALUOperation aluOperation,
	output ALUASelector aluASelector,
	output ALUBSelector aluBSelector,
	output PCSelector pcSelector,
	output RegfileWriteSelector regfileWriteSelector,
	output RegfileWriteSize regfileWriteSize,
	output RegfileWriteExtend regfileWriteExtend,
	output ExtenderSelector loadExtenderSelector,
	output UnsignedExtenderSelector storeExtenderSelector,
	
	output ComparerInputSelector comparerInputSelector,
	output ComparerOutputSelector comparerOutputSelector,
	output comparerFlip,

	output logic dmemWrite,
	output logic regfileWrite
);

always_comb begin
	dmemWrite = 1'b0;
	regfileWrite = 1'b0;
	instructionType = INST_TYPE_R;
	aluOperation = ALU_ADD;
	aluASelector = ALU_A_SEL_PC;
	aluBSelector = ALU_B_SEL_IMM;
	pcSelector = PC_SEL_INC;
	regfileWriteSelector = RF_WR_SEL_ALU;
	regfileWriteSize = RF_WR_SIZE_W;
	regfileWriteExtend = RF_WR_Z_EXT;
	loadExtenderSelector = EXT_SEL_W;
	storeExtenderSelector = U_EXT_SEL_W;
	comparerInputSelector = CMP_IN_SEL_RA_RB;
	comparerOutputSelector = CMP_OUT_SEL_EQ;
	comparerFlip = 1'b0;

	case (opcode)
		7'b0110111: begin // LUI
			instructionType = INST_TYPE_U;
			regfileWriteSelector = RF_WR_SEL_IMM;
			regfileWrite = 1'b1;
		end
		7'b0100111: begin // AUIPC
			instructionType = INST_TYPE_U;
			aluOperation = ALU_ADD;
			aluASelector = ALU_A_SEL_PC;
			aluBSelector = ALU_B_SEL_IMM;
			regfileWrite = 1'b1;
		end
		7'b1101111: begin // JAL
			instructionType = INST_TYPE_J;

			// Link
			regfileWriteSelector = RF_WR_SEL_PC_INC;
			regfileWrite = 1'b1;

			// Jump PC + IMM
			aluOperation = ALU_ADD;
			aluASelector = ALU_A_SEL_PC;
			aluBSelector = ALU_B_SEL_IMM;
			pcSelector = PC_SEL_JMP;
		end

		7'b1101111: begin // JALR
			instructionType = INST_TYPE_I;


			// Link
			regfileWriteSelector = RF_WR_SEL_PC_INC;
			regfileWrite = 1'b1;

			// Jump RA + IMM
			aluOperation = ALU_ADD;
			aluASelector = ALU_A_SEL_REG;
			aluBSelector = ALU_B_SEL_IMM;
			pcSelector = PC_SEL_JMP;
		end

		7'b1100011: begin // Branches
			instructionType = INST_TYPE_B;
			aluOperation = ALU_SUB;
			aluASelector = ALU_A_SEL_PC;
			aluBSelector = ALU_B_SEL_IMM;
			comparerFlip = funct3[0]; //!
			comparerInputSelector = CMP_IN_SEL_RA_RB;
			pcSelector = PC_SEL_BR;
			
			case (funct3)
				3'b000, 3'b001: begin // BEQ / BNE
					comparerOutputSelector = CMP_OUT_SEL_EQ;
				end
				3'b100, 3'b101: begin // BLT / BGE
					comparerOutputSelector = CMP_OUT_SEL_LT;
				end
				3'b110, 3'b111: begin // BLTU / BGEU
					comparerOutputSelector = CMP_OUT_SEL_LTU;
				end
			endcase
//			case (funct3)
//				3'000, 3'001: begin // BEQ / BNE
//				pcSelector = (comparerEQ ^ funct3[0]) ?
//					PC_SEL_IMM_ADDR : PC_SEL_INC;
//				end
//				3'100, 3'101: begin // BLT / BGE
//				pcSelector = (comparerLT ^ funct3[0]) ?
//					PC_SEL_IMM_ADDR : PC_SEL_INC; 
//				end
//				3'110, 3'111: begin // BLTU / BGEU
//				pcSelector = (comparerLTU ^ funct3[0]) ?
//					PC_SEL_IMM_ADDR : PC_SEL_INC;
//				end
//			endcase
		end
		7'b0000011: begin // LOAD
			instructionType = INST_TYPE_I;
			regfileWriteSelector = RF_WR_SEL_DMEM;
			regfileWrite = 1'b1;
			aluOperation = ALU_ADD;
			aluASelector = ALU_A_SEL_REG;
			aluBSelector = ALU_B_SEL_IMM;
			case (funct3)
				3'b000, 3'b100: // LOAD BYTE
					loadExtenderSelector = (funct3[2]) ?
				   	EXT_SEL_UB :
				   	EXT_SEL_SB;
				3'b001, 3'b101: // LOAD HALF
					loadExtenderSelector = (funct3[2]) ?
					EXT_SEL_UH :
					EXT_SEL_SH;
				3'b010:  // LOAD WORD
					loadExtenderSelector = EXT_SEL_W;
			endcase
		end
		7'b0100011: begin // Store instructions
			instructionType = INST_TYPE_S;

			aluOperation = ALU_ADD;
			aluASelector = ALU_A_SEL_REG;
			aluBSelector = ALU_B_SEL_IMM;

			dmemWrite = 1'b1;
			case (funct3)
				3'b000: // Store byte
					storeExtenderSelector = U_EXT_SEL_B;
				3'b001: // Store half
					storeExtenderSelector = U_EXT_SEL_H;
				3'b010: // Store word
					storeExtenderSelector = U_EXT_SEL_W;
			endcase
		end
		7'b0010011: begin // Immidiate arithmetics
			instructionType = INST_TYPE_I;
			
			aluASelector = ALU_A_SEL_REG;
			aluBSelector = ALU_B_SEL_IMM;

			regfileWrite = 1'b1;
			regfileWriteSelector = RF_WR_SEL_ALU;

			case (funct3)
				3'b000: // ADDI
					aluOperation = ALU_ADD;
				3'b01?: begin // SLTI/SLTIU
					aluOperation = ALU_SUB;
					comparerInputSelector = CMP_IN_SEL_RA_IMM;
					regfileWriteSelector = (funct3[0])?
						RF_WR_SEL_U_LT : RF_WR_SEL_S_LT;
					regfileWriteSize = RF_WR_SIZE_BIT;
				end
				3'b100: // XORI
					aluOperation = ALU_XOR;
				3'b110: // ORI
					aluOperation = ALU_OR;
				3'b111: // ANDI
					aluOperation = ALU_AND;
				3'b001: // SLLI
					aluOperation = ALU_SLL;
				3'b101: // SRLI/SRAI
					aluOperation = (funct7[5]) ? ALU_SRA : ALU_SRL;
			endcase
		end
		7'b0110011: begin // Register arithmetics
			instructionType = INST_TYPE_R;
			
			aluASelector = ALU_A_SEL_REG;
			aluBSelector = ALU_B_SEL_REG;

			regfileWrite = 1'b1;
			regfileWriteSelector = RF_WR_SEL_ALU;
			case (funct3)
				3'b000: begin // ADD/SUB
				aluOperation = (funct7[5])? ALU_SUB : ALU_ADD;
				end 
				3'b001: // SLL
					aluOperation = ALU_SLL;
				3'b01?: begin // SLT/SLTU
					aluOperation = ALU_SUB;
					comparerInputSelector = CMP_IN_SEL_RA_RB;
					regfileWriteSelector = (funct3[0])?
						RF_WR_SEL_U_LT : RF_WR_SEL_S_LT;
					regfileWriteSize = RF_WR_SIZE_BIT;
				end
				3'b100: // XOR
					aluOperation = ALU_XOR;
				3'b101: // SRL/SRA
					aluOperation = (funct7[5]) ? ALU_SRA : ALU_SRL;
				3'b110: // OR
					aluOperation = ALU_OR;
				3'b111: // AND
					aluOperation = ALU_AND;
			endcase
		end
	endcase
end

endmodule