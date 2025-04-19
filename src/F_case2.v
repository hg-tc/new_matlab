module F_case4 #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1,
    localparam J_WIDTH = $clog2(J)
)(
    input clk,
    input rst_n,
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

wire [J*64-1:0] F_element;
wire F_element_tvalid;
multiply multiply (
    .aclk(clk),
    .s_axis_a_tvalid(H_fifo_out_tvalid),
    .s_axis_a_tdata(H_fifo_out),
    .s_axis_b_tvalid(x_double_tvalid),
    .s_axis_b_tdata(x_double),
    .m_axis_result_tvalid(F_element_tvalid),
    .m_axis_result_tdata(F_element)
);

reg F_element_tlast = 0;
reg [J_WIDTH-1:0] cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        F_element_tlast <= 0;
        cnt <= 0;
    end else if(F_element_tvalid)begin
        if(cnt < J-1)begin
            cnt <= cnt + 1;
            F_element_tlast <= 0;
        end else begin
            F_element_tlast <= 1;
            cnt <= 0;
        end
    end
end
accumulator accumulator (
  .aclk(clk),
  .s_axis_a_tvalid(F_element_tvalid),
  .s_axis_a_tdata(F_element),
  .s_axis_a_tlast(F_element_tlast),
  .m_axis_result_tvalid(F_value_tvalid_temp),
  .m_axis_result_tdata(F_value),
  .m_axis_result_tlast(F_value_tlast_temp)
);

assign F_value_tvalid = F_value_tvalid_temp & F_value_tlast_temp;

endmodule

