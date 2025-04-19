module F_case4 #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1
)(
    input clk,
    input [J*64-1:0] H,
    input H_tvalid,

    input [64-1:0] y,
    input y_tvalid,

    input [J*AWIDTH-1:0] x,
    input x_tvalid,

    output [J*AWIDTH-1:0] F_value,
    output F_value_tvalid
);




endmodule

