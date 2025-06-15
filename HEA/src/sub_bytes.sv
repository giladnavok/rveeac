module sub_bytes #(
    parameter WIDTH = 128,
    // PARALLELISM: number of bytes processed per cycle (1,2,4,8,16)
    //   - Throughput: performs PAR simultaneous S-box lookups each cycle, increasing bytes/cycle.
    //   - Resource tradeoff: S-box ROM is replicated PAR times, so memory/LUT usage scales linearly with PAR.
    parameter PAR = 16,
    parameter OP = 1
)
(

    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] s_i,
    input  logic start_i,
    output logic [WIDTH-1:0] s_o,
    output logic done_o

);


    // Parameter sanity checks
    initial begin
        if (WIDTH % 8 != 0) begin
            $error("WIDTH (%0d) must be a multiple of 8", WIDTH);
        end
        if (!(PAR == 1 || PAR == 2 || PAR == 4 || PAR == 8 || PAR == 16)) begin
            $error("Invalid PAR=%0d, must be one of {1,2,4,8,16}", PAR);
        end
        if (PAR > num_of_bytes) begin
            $error("PAR (%0d) cannot exceed NUM_BYTES (%0d)", PAR, num_of_bytes);
        end
        if (num_of_bytes % PAR != 0) begin
            $error("num_of_bytes (%0d) must be divisible by PAR (%0d)", num_of_bytes, PAR);
        end
    end

    
    logic [7:0] sbox_table [0:255];

    // Initialize ROM
    initial begin
        if (OP) // Encrypt
            $readmemh("sbox_table.mem", sbox_table);
        else   // Decrypt
            $readmemh("inv_sbox_table.mem", sbox_table);
    end

    typedef enum logic [2:0] { IDLE_S, RUN_S, DONE_S} s_box_t;
    s_box_t s_box_s;

    logic [3:0] byte_idx;
    localparam num_of_bytes = WIDTH / 8;
    logic [WIDTH-1:0] temp_res;
    
    always_ff @( posedge clk or negedge rst_n ) begin : s_box
        if (!rst_n) begin
            byte_idx <= 4'h0;
            temp_res <= 0;
            s_o      <= 0;
            done_o   <= 1'b0;
            s_box_s  <= IDLE_S;
        end else begin
            case (s_box_s)
                IDLE_S: begin
                    done_o <= 1'b0;
                    if (start_i) begin
                        byte_idx <= 4'h0;
                        temp_res <= 0;
                        s_box_s  <= RUN_S;
                    end
                end 

                RUN_S: begin
                    integer k;
                    for (k = 0;k < PAR; k++) begin
                        temp_res[(byte_idx+k)*8 +: 8] <= sbox_table[s_i[(byte_idx+k)*8 +: 8]];
                    end
                    byte_idx <= byte_idx + PAR;
                    s_box_s  <= (byte_idx == num_of_bytes - PAR) ? DONE_S : RUN_S;
                end

                DONE_S: begin
                    s_o     <= temp_res;
                    done_o  <= 1'b1;
                    s_box_s <= IDLE_S;
                end

                default: s_box_s <= IDLE_S; 
            endcase
        end
    end
    
// Optional combinatorical solution, less memory but more complex to implement 
//        logic [7:0] inv_b;
//        inv_byte u_inv_byte(.b(b), .inv_b(inv_b));

//        // Affine: sb = A·inv_b ⊕ 0x63
//        logic [7:0] t1 = inv_b ^ {inv_b[6:0],inv_b[7]};        // rol1
//        logic [7:0] t2 = t1 ^ {t1[5:0],t1[7:6]};               // rol2
//        logic [7:0] t3 = inv_b  ^ {inv_b[4:0],inv_b[7:5]};     // rol3
//        logic [7:0] t4 = inv_b  ^ {inv_b[3:0],inv_b[7:4]};     // rol4
//        assign b_sb = t2 ^ t3 ^ t4 ^ 8'h63;

endmodule
