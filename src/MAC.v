module MAC #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [64-1:0] vinput,
    input vinput_tvalid,
    input vinput_tlast,

    input [A*64-1:0] M_row,
    input M_row_tvalid,
    input M_row_tlast,
    output beta_tvalid,
    output [A*64-1:0] beta
);


wire [A-1:0] pre_beta_tvalid;
wire [A-1:0] pre_beta_tlast;
wire [A*64-1:0] pre_beta;
genvar i;
generate
    for(i=0;i<A;i=i+1) begin
        wire multiply_out_tvalid;
        wire [63:0] multiply_out;
        multiply multiply_inst(
            .aclk(clk),
            .s_axis_a_tvalid(vinput_tvalid),
            .s_axis_a_tdata(vinput),
            .s_axis_b_tvalid(M_row_tvalid),
            .s_axis_b_tdata(M_row[i*64 +: 64]),
            .m_axis_result_tvalid(multiply_out_tvalid),
            .m_axis_result_tdata(multiply_out)
        );  

        wire multiply_out_tlast;
        easy_fifo #(
            .DATAWIDTH(1),
            .SIZE(64),
            .IN_SIZE(1),
            .OUT_SIZE(1)
        ) fifo_tlast (
            .clk(clk),
            .rst_n(rst_n),
            .din(vinput_tlast & M_row_tlast),
            .din_valid(vinput_tvalid & M_row_tvalid),
            .request(multiply_out_tvalid),
            .dout(multiply_out_tlast),
            .out_valid(),
            .empty()
        );

        accumulator accumulator_inst(
            .aclk(clk),
            .s_axis_a_tvalid(multiply_out_tvalid),
            .s_axis_a_tdata(multiply_out),
            .s_axis_a_tlast(multiply_out_tlast),
            .m_axis_result_tvalid(pre_beta_tvalid[i]),
            .m_axis_result_tlast(pre_beta_tlast[i]),
            .m_axis_result_tdata(pre_beta[i*64 +: 64]) 
        );
    end
endgenerate

assign beta_tvalid = pre_beta_tvalid[A-1] & pre_beta_tlast[A-1];
assign beta = pre_beta;
endmodule