import typedefs::*;
module prefetch_buffer_sbm #(
	CAPACITY = 2,
	LOG2_CAPACITY = $clog2(CAPACITY)
)(
	input logic clk,
	input logic rst_n,

	input logic [31:0] inst_i,
	input logic [31:0] pc_i,
	input logic write_i,
	input logic read_i,
	input logic flush_i,

	output logic [31:0] inst_o,
	output logic [31:0] pc_o,
	output logic [31:0] pc_next_o,
	output logic full_o,
	output logic full_next_o,
	output logic [LOG2_CAPACITY:0] count_o
);

localparam VALID = 1'b1;
localparam INVALID = 1'b0;

prefetch_entry_s [CAPACITY - 1 : 0] entries;
logic [LOG2_CAPACITY - 1:0] head, tail;
logic [LOG2_CAPACITY:0] count, count_next;

assign count_next = flush_i ? '0 : count + write_i - read_i;
assign pc_next_o = entries[tail].pc;

always_ff @(posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		head <= '0;
		tail <= '0;
		count <= '0;
		for (int i = 0; i < CAPACITY; i++) begin
			entries[i] <= '0;
		end
	end else begin
		if (flush_i) begin
			for (int i = 0; i < CAPACITY; i++) begin
				entries[i].valid <= INVALID;
			end
			head <= tail;
			count <= '0;
		end else begin
			if (write_i) begin
				assert(!full_o);
				entries[head].pc <= pc_i;
				entries[head].inst <= inst_i;
				entries[head].valid <= VALID;
				head <= head + 1;
			end
			if (read_i) begin
				assert(count != 0);
				tail <= tail + 1;
			end

			count <= count_next;
		end
	end
end

assign full_o = (count == CAPACITY);
assign full_next_o = (count_next == CAPACITY);
assign count_o = count;
always_comb begin
	pc_o = 32'hxxxxxxxx;
	inst_o = 32'hxxxxxxxx;
	if (!flush_i && entries[tail].valid) begin
		pc_o = entries[tail].pc;
		inst_o = entries[tail].inst;
	end
end

endmodule
