module divide_fix_wrapper #(
    localparam DATAWIDTH_IN = 32,         // 数据位宽
    localparam DATAWIDTH_OUT = 32         // 数据位宽

)(
    input wire aclk,
    input wire s_axis_a_tvalid,
    input wire [DATAWIDTH_IN-1:0] s_axis_a_tdata,
    input wire s_axis_b_tvalid,
    input wire [DATAWIDTH_IN-1:0] s_axis_b_tdata,
    output wire m_axis_result_tvalid,
    output wire [DATAWIDTH_OUT-1:0] m_axis_result_tdata
);

wire [DATAWIDTH_IN*2-1:0] temp_result_tdata;


divide_fix divide_fix_inst(
    .aclk(aclk),
    .s_axis_divisor_tvalid(s_axis_b_tvalid),
    .s_axis_divisor_tdata(s_axis_b_tdata),
    .s_axis_dividend_tvalid(s_axis_a_tvalid),
    .s_axis_dividend_tdata(s_axis_a_tdata),
    .m_axis_dout_tvalid(m_axis_result_tvalid),
    .m_axis_dout_tdata(temp_result_tdata)
);

wire [DATAWIDTH_OUT-1:0] pre_result;
assign pre_result = temp_result_tdata[40:12];

assign m_axis_result_tdata = pre_result==0 ? 1 : pre_result;
endmodule