module F_case4 #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1
)(
    input clk,
    input [J*64-1:0] H,
    input H_tvalid,

    input [J*AWIDTH-1:0] x,
    input x_tvalid,

    output [J*AWIDTH-1:0] F_value,
    output F_value_tvalid
);

easy_fifo #(
    .DATAWIDTH(64),
    .SIZE(J*2),
    .IN_SIZE(J),
    .OUT_SIZE(1)
) fifo_H (
    .clk(clk),
    .rst_n(rst_n),
    .din(H),
    .din_valid(H_tvalid),
    .request(H_empty & x_empty),
    .dout(H_fifo_out),
    .out_valid(H_fifo_out_tvalid),
    .empty(H_empty)
);

easy_fifo #(
    .DATAWIDTH(AWIDTH),
    .SIZE(J*2),
    .IN_SIZE(J),
    .OUT_SIZE(1)
) fifo_x ( 
    .clk(clk),
    .rst_n(rst_n),
    .din(x),
    .din_valid(x_tvalid),
    .request(H_empty & x_empty),
    .dout(x_fifo_out),
    .out_valid(x_fifo_out_tvalid),
    .empty(x_empty)
);

int8_double int8_double (
    .s_axis_a_tvalid(x_fifo_out_tvalid),
    .s_axis_a_tdata(x_fifo_out),
    .m_axis_result_tvalid(x_double_tvalid),
    .m_axis_result_tdata(x_double)
);



endmodule

