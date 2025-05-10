`timescale 1ns / 1ps

module sub_bytes #(
    parameter WIDTH = 128
)
(

    input  logic clk,
    input  logic rst_n,
    input  logic [WIDTH-1:0] b,
    input  logic start,
    output logic [WIDTH-1:0] b_sb,
    output logic done

    );

// Current working s-box using a simple 256x8 ROM, simpler to implement but more expensive
    logic [7:0] aes_inv_table [0:255];
    initial $readmemh("aes_inv.mem", aes_inv_table);

    typedef enum logic [2:0] { IDLE_S, RUN_S, DONE_S} s_box_t;
    s_box_t s_box_s;

    localparam num_of_bytes = WIDTH / 8;
    logic [3:0] byte_idx;

    logic [WIDTH-1:0] temp_res;
    
    always_ff @( posedge clk or negedge rst_n ) begin : s_box
        if (!rst_n) begin
            byte_idx <= 4'h0;
            temp_res <= 0;
            b_sb     <= 0;
            done     <= 1'b0;
            s_box_s  <= IDLE_S;
        end else begin
            case (s_box_s)
                IDLE_S: begin
                    done <= 1'b0;
                    if (start) begin
                        byte_idx <= 4'h0;
                        temp_res <= 0;
                        s_box_s  <= RUN_S;
                    end
                end 

                RUN_S: begin
                    temp_res[byte_idx*8 +: 8] <= aes_inv_table[b[byte_idx*8 +: 8]];
                    byte_idx <= byte_idx + 1;
                    s_box_s  <= (byte_idx == num_of_bytes-1) ? DONE_S : RUN_S;
                end

                DONE_S: begin
                    b_sb    <= temp_res;
                    done    <= 1'b1;
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
