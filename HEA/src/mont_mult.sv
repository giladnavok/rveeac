module mont_mult #(
    parameter int WIDTH = 128
)(
    // Test //
    // ---- //
    output logic [7:0] cnt_o,
    // General Signals //
	// --------------- //
    input  logic clk,
    input  logic rst_n,

    // Input Controls //
    // -------------- //	
    input  logic start_i,

    // Input Data //
    // ---------- //
    input  logic [WIDTH-1:0] N,
    input  logic [WIDTH-1:0] N_prime,
    input  logic [WIDTH-1:0] x_i, 
    input  logic [WIDTH-1:0] y_i, 

    // Output Data //
    // ----------- //
    output logic [WIDTH-1:0] z_o,
    output logic done_o
);

    logic [2 * WIDTH - 1:0] T;
    logic [WIDTH-1:0] U;
    logic [7:0] cnt;
    
    assign cnt_o = cnt;
    
    // Naive implementation , WIDTH cycles to complete
    always_ff @( posedge clk or negedge rst_n ) begin : mult_proc
        if (!rst_n) begin
            cnt    <= 0;
            U      <= 0;
            T      <= 0;
            done_o <= 0;
            z_o    <= 128'b0;
        end else begin
            if (start_i) begin
                T      <= x_i * y_i;
                cnt    <= 0;
                done_o <= 0;
            end else if (cnt < WIDTH) begin
                U <= (T[WIDTH-1:0] * N_prime) & 128'hffff_ffff_ffff_ffff;
                T <= (T+U*N) >> 1;
                cnt <= cnt + 1;
            end else begin
                z_o <= (T >= N) ? T - N : T;
                done_o <= 1;
            end
        end
    end
endmodule