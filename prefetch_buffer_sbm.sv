import typedefs::*;
module prefetch_buffer_sbm #(
	CAPACITY = 2,
	LOG2_CAPACITY = $clog2(CAPACITY)
)(
	input logic clk,
	input logic rst_n,

	input logic enqueue_i,
	input logic dequeue_i,
	input logic flush_i,

	input logic [31:0] inst_i,
	input logic [31:0] pc_i,

	output logic [31:0] inst_o,
	output logic [31:0] pc_o,
	output logic full_o,
	output logic full_next_o,
	output logic empty_o
);

localparam VALID = 1'b1;
localparam INVALID = 1'b0;

prefetch_entry_s [CAPACITY - 1 : 0] entries;
logic [LOG2_CAPACITY - 1:0] head, tail;
logic [LOG2_CAPACITY:0] count, count_next;

assign count_next = flush_i ? '0 : count + enqueue_i - dequeue_i;

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
			tail <= head;
			count <= '0;
		end else begin
			if (enqueue_i) begin
				assert(!full_o);
				entries[tail].pc <= pc_i;
				entries[tail].inst <= inst_i;
				entries[tail].valid <= VALID;
				tail <= tail + 1;
			end
			if (dequeue_i) begin
				assert(count != 0);
				head <= head + 1;
			end

			count <= count_next;
		end
	end
end

assign full_o = (count == CAPACITY);
assign full_next_o = (count_next == CAPACITY);
assign empty_o = (count == 0);
always_comb begin
	pc_o = 32'hxxxxxxxx;
	inst_o = 32'hxxxxxxxx;
	if (entries[head].valid) begin
		pc_o = entries[head].pc;
		inst_o = entries[head].inst;
	end
end

endmodule
