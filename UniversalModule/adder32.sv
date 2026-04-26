

module Carry_adder_4bit (
    input  logic [3:0] a, b,
    input  logic       cin,
    output logic [3:0] sum,
    output logic       cout
);

    logic [3:0] g, p;
    logic [4:0] carry;

    assign g = a & b;
    assign p = a | b;
    assign carry[0] = cin;

    assign carry[1] = g[0] | (p[0] & carry[0]);
    assign carry[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & carry[0]);
    assign carry[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & carry[0]);
    assign carry[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & carry[0]);
    
    assign sum = carry[3:0] ^ a ^ b;
    assign cout = carry[4];
endmodule


module adder32 
#(  parameter N = 32 )
(
    input logic [N-1:0] a, b,
    input logic cin,
    output logic [N-1:0] sum,
    output logic cout
);

    localparam Des = N / 4;
    logic [Des:0] carry;
    assign carry[0] = cin;


    generate
        genvar i;
        for (i = 0; i < Des; i++) begin
            
            localparam int iend = i * 4;
            localparam int ihead = iend + 3;
            
            Carry_adder_4bit adder(
                .a(a[ihead:iend]),
                .b(b[ihead:iend]),
                .cin(carry[i]),
                .sum(sum[ihead:iend]),
                .cout(carry[i + 1])
            );
        end
    endgenerate

    assign cout = carry[Des];
    
endmodule
