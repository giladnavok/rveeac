`timescale 1ns / 1ps

module sub_bytes(

        input  logic [7:0] b,
        output logic [7:0] b_sb

    );

// Current working s-box using a simple 256x8 ROM, simpler to implement but more expensive
    logic [7:0] aes_inv_table [0:255];
    initial $readmemh("aes_inv.mem", aes_inv_table);
    assign b_sb = aes_inv_table[b];
    
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
