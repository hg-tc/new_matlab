module multiply_single_fix #(
    parameter DATAWIDTH = 32          // 数据位宽
)(
    input wire aclk,
    input wire s_axis_a_tvalid,
    input wire [DATAWIDTH-1:0] s_axis_a_tdata,
    input wire s_axis_b_tvalid,
    input wire s_axis_b_tdata,
    output reg m_axis_result_tvalid,
    output reg [DATAWIDTH-1:0] m_axis_result_tdata
);

always @(posedge aclk) begin
    if(s_axis_a_tvalid & s_axis_b_tvalid) begin
        m_axis_result_tdata <= s_axis_b_tdata ? s_axis_a_tdata : 1;
        m_axis_result_tvalid <= 1;
    end else begin
        m_axis_result_tdata <= 0;
        m_axis_result_tvalid <= 0;
    end
end

// assign m_axis_result_tdata = s_axis_b_tdata ? s_axis_a_tdata : 1;
// assign m_axis_result_tvalid = s_axis_a_tvalid & s_axis_b_tvalid;
endmodule