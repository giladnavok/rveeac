import typedefs::*;

module csr_sbm (
	input logic clk,
	input logic rst_n,

	input logic write_i,
	input logic h_sel_i,

	input logic [CSR_ADDR_LEN-1:0] addr_i,
	input logic [HALF_XLEN-1:0] write_data_i,

	input logic mepc_write_i,
	input logic [XLEN-1:0] mepc_write_data_i,

	input logic mcause_write_i,
	input logic [XLEN-1:0] mcause_write_data_i,

	input logic mip_set_i,
	input logic [XLEN-1:0] mip_set_write_data_i,

	output logic valid_o, /// <<< Used to prevent intermediary values to get sampled
	output logic [HALF_XLEN-1:0] read_data_o,

	output logic [XLEN-1:0] mepc_o,
	output logic [XLEN-1:0] mie_o,
	output logic [XLEN-1:0] mip_o,
	output logic [XLEN-1:0] mtvec_o
);

localparam bit [31:0] WMASK_DEFAULT = '1;

// CSR Parameters Definition // //! Continue
// ------------------------- //

localparam bit [11:0] ADDR_MSTATUS = 12'h300;
localparam bit [31:0] WMASK_MSTATUS = 32'h888, // Assign
					  RESET_MSTATUS = (32'b11 << 11);

localparam bit [11:0] ADDR_MIE = 12'h304;
localparam logic [31:0] WMASK_MIE = '0, // Assign
					  RESET_MIE = (32'b1 << 16) | (32'b1 << 11);

localparam bit [11:0] ADDR_MTVEC = 12'h305;
localparam logic [31:0] WMASK_MTVEC = '1 ^ 2'b11,
						RESET_MTVEC = '0; // Assign


localparam bit [11:0] ADDR_MSCRATCH = 12'h340;

localparam bit [11:0] ADDR_MEPC = 12'h341;

localparam bit [11:0] ADDR_MCAUSE = 12'h342;

localparam bit [11:0] ADDR_MTVAL = 12'h343;

localparam bit [11:0] ADDR_MIP = 12'h344;

localparam bit [11:0] ADDR_MTINST = 12'h34A;
//localparam bit [11:0] ADDR_MTVAL2 = 12'h34B;

// ----------------------------- //
// CSR Parameters Definition END //


logic [1:0][HALF_XLEN-1:0]
	mstatus,
	mie,
	mtvec,

	mscratch,
	mepc,
	mcause,
	mtval,
	mip,
	mtinst;


// Masked Write Logic //
// ------------------ //
logic [31:0] mask;
logic [15:0] mask_half;
logic [15:0] mask_old_value;
logic [15:0] mask_new_value;
logic [15:0] mask_o;
logic mask_h_sel;

assign mask_old_value = write_i ? read_data_o : '0;
assign mask_new_value = write_i ? write_data_i : '0;
assign mask_half = mask_h_sel? mask[31:16] : mask[15:0];
assign mask_o = (mask_old_value & ~mask_half) | (mask_new_value & mask_half);
always_comb begin
	unique case (addr_i)
		ADDR_MSTATUS: mask = WMASK_MSTATUS;
		ADDR_MIE: mask = WMASK_MIE;
		ADDR_MTVEC: mask = WMASK_MTVEC;

		default: mask = WMASK_DEFAULT;
	endcase
end

logic write_allowed;

always_comb begin
	unique case (addr_i)
		//ADDR_MEPC: write_allowed = 
		default:
			write_allowed = 1'b1;
	endcase
end


always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		mstatus <= RESET_MSTATUS;
		mtvec <= RESET_MTVEC;
		mie <= RESET_MIE;
		mscratch <= '0;
		mepc <= '0;
		mcause <= '0;
		mtval <= '0;
		mip <= '0;
		mtinst <= '0;
	end else begin
		if (write_i) begin
			if (write_allowed) begin
				unique case (addr_i)
					ADDR_MSTATUS: mstatus[h_sel_i] <= mask_o;
					ADDR_MIE: mie[h_sel_i] <= mask_o;
					ADDR_MTVEC: mtvec[h_sel_i] <= mask_o;

					ADDR_MSCRATCH: mscratch[h_sel_i] <= mask_o;
					ADDR_MEPC: mepc[h_sel_i] <= mask_o;
					ADDR_MCAUSE: mcause[h_sel_i] <= mask_o;
					ADDR_MTVAL: mtval[h_sel_i] <= mask_o;
					ADDR_MIP: mip[h_sel_i] <= mask_o;
					ADDR_MTINST: mtinst[h_sel_i] <= mask_o;
				endcase
			end //else write is not allowed
			// Trap? atleast not on mepc_write_i
		//end
		end
		if (mepc_write_i) mepc <= mepc_write_data_i;
		if (mcause_write_i) mcause <= mcause_write_data_i;
		if (mip_set_i) mip <= mip | mip_set_write_data_i; //! same cycle mip set by interrupt sbm and write by user problematic
	end
end


always_comb begin
	unique case (addr_i)
		ADDR_MSTATUS: read_data_o =  mstatus[h_sel_i];
		ADDR_MIE: read_data_o =  mie[h_sel_i];
		ADDR_MTVEC: read_data_o =  mtvec[h_sel_i];

		ADDR_MSCRATCH: read_data_o = mscratch[h_sel_i];
		ADDR_MEPC: read_data_o = mepc[h_sel_i];
		ADDR_MCAUSE: read_data_o =  mcause[h_sel_i];
		ADDR_MTVAL: read_data_o =  mtval[h_sel_i];
		ADDR_MIP: read_data_o =  mip[h_sel_i];
		ADDR_MTINST: read_data_o =  mtinst[h_sel_i];
		default:
			// Maybe trap
			read_data_o = 'x;
	endcase
end

assign mepc_o = mepc;
assign mie_o = mie;
assign mip_o = mip;
assign mtvec_o = mtvec;


endmodule




