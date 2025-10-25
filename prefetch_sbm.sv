module prefetch_sbm #(
	CAPACITY = 2
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
	output logic full_o,
);

localparam LOG2_CAPACITY = $clog2(CAPACITY);
localparam COUNT_FULL_CAPACITY = CAPACITY - 1;
localparam VALID = 1'b1;
localparam INVALID = 1'b0;

prefetch_entry [CAPACITY - 1 : 0] entries;
logic [LOG2_CAPACITY - 1:0] head, tail;
logic [LOG2_CAPACITY - 1:0] count;

assign full_o = (count == COUNT_FULL_CAPACITY);

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
			head <= '0;
			tail <= '0;
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

			count <= count + write_i - read_i;
		end
	end
end

always_comb begin
	if (!flush_i && read_i) begin
		assert(entries[tail].valid);
		pc_o = entries[tail].pc;
		inst_o = entries[tail].inst;
	end
end

endmodule
