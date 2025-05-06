import hea_func_pack::*;

module inv_byte(

        input  logic [7:0] b,
        output logic [7:0] inv_b

    );
    // 4-bit GF(2^4) inverse table for p(x)=x^4+x+1 (0x13)
    localparam logic [3:0] gf16_inv_table [0:15] = '{
    4'h0, // 0 → 0 (convention)
    4'h1, // 1 → 1
    4'h9, // 2 → 9
    4'he, // 3 → E
    4'hd, // 4 → D
    4'hb, // 5 → B
    4'h7, // 6 → 7
    4'h6, // 7 → 6
    4'hf, // 8 → F
    4'h2, // 9 → 2
    4'hc, // A → C
    4'h5, // B → 5
    4'ha, // C → A
    4'h4, // D → 4
    4'h3, // E → 3
    4'h8  // F → 8
    };

    always_comb begin 
        logic [3:0] u, v, v_inv, u2, t, den, den_inv, c, d;
        u = b[3:0];
        v = b[7:4];

        if(b == 8'h00) begin

            inv_b = 8'h00;
            
        end else begin
            if (v == 4'h0) begin

                inv_b = {4'h0, gf16_inv_table[u]};

            end else begin

                // 1) inverse the upper half byte
                v_inv = gf16_inv_table[v];

                // 2) Calculate denominator
                u2 = gf16_mul(u,u);
                t  = gf16_mul(v_inv, u2);
                den  = u ^ t ^ gf16_mul(v, 4'h1);

                // 3) Invert denominator
                den_inv = gf16_inv_table[den];

                // 4) return inverted byte
                c = den_inv;
                d = gf16_mul(den_inv, (4'h1 ^ gf16_mul(v_inv, u)));
                inv_b = {d,c};
                
            end
        end
    end

endmodule