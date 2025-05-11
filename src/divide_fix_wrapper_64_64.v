
module divide_fix_wrapper_64_64 (
    input wire aclk,
    input wire s_axis_a_tvalid,
    input wire [64-1:0] s_axis_a_tdata,
    input wire s_axis_b_tvalid,
    input wire [64-1:0] s_axis_b_tdata,
    output wire m_axis_result_tvalid,
    output wire [8-1:0] m_axis_result_tdata
);

wire [128-1:0] temp_result_tdata;


divide_fix_64_64 divide_fix_inst(
    .aclk(aclk),
    .s_axis_divisor_tvalid(s_axis_b_tvalid),
    .s_axis_divisor_tdata(s_axis_b_tdata),
    .s_axis_dividend_tvalid(s_axis_a_tvalid),
    .s_axis_dividend_tdata(s_axis_a_tdata),
    .m_axis_dout_tvalid(m_axis_result_tvalid),
    .m_axis_dout_tdata(temp_result_tdata)
);

wire [8-1:0] pre_result;
assign pre_result = temp_result_tdata[7:0];
assign m_axis_result_tdata = pre_result==0 ? 1 : pre_result;
endmodule