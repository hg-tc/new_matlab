module F_case2 #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1,
    localparam J_WIDTH = $clog2(J)+1
)(
    input clk,
    input rst_n,

    input [J*64-1:0] H,
    input H_tvalid,

    input [J*AWIDTH-1:0] x,
    input x_tvalid,

    output [63:0] F_value,
    output F_value_tvalid
);

reg [J*64-1:0] H_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_reg <= 0;
    end
    else begin
        if (H_tvalid) begin
            H_reg <= H;
        end
    end
end


wire [AWIDTH-1:0] x_fifo_out;
wire x_fifo_out_tvalid;
wire x_empty;

wire [64-1:0] x_double;
wire x_double_tvalid;


easy_fifo #(
    .DATAWIDTH(AWIDTH),
    .SIZE(32),
    .IN_SIZE(J),
    .OUT_SIZE(1)
) fifo_x ( 
    .clk(clk),
    .rst_n(rst_n),
    .din(x),
    .din_valid(x_tvalid),
    .request(!x_empty),
    .dout(x_fifo_out),
    .out_valid(x_fifo_out_tvalid),
    .empty(x_empty)
);

int8_double int8_double (
    .s_axis_a_tvalid(x_fifo_out_tvalid),
    .s_axis_a_tdata({0,x_fifo_out}),
    .m_axis_result_tvalid(x_double_tvalid),
    .m_axis_result_tdata(x_double)
);
reg [J_WIDTH-1:0] H_cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_cnt <= 0;
    end
    else begin
        if(x_double_tvalid) begin
            if(H_cnt < J-1) begin
                H_cnt <= H_cnt + 1;
            end
            else begin
                H_cnt <= 0;
            end
        end
    end
end
wire [64-1:0] F_element;
wire F_element_tvalid;
multiply multiply (
    .aclk(clk),
    .s_axis_a_tvalid(x_double_tvalid),
    .s_axis_a_tdata(H_reg[H_cnt*64+:64]),
    .s_axis_b_tvalid(x_double_tvalid),
    .s_axis_b_tdata(x_double),
    .m_axis_result_tvalid(F_element_tvalid),
    .m_axis_result_tdata(F_element)
);

wire F_element_tlast;
reg [J_WIDTH-1:0] cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cnt <= 0;
    end else if(F_element_tvalid)begin
        if(cnt < J-1)begin
            cnt <= cnt + 1;
        end else begin
            cnt <= 0;
        end
    end
end
assign F_element_tlast = (cnt == J-1);

wire pre_F_value_tvalid;
wire pre_F_value_tlast;
accumulator accumulator (
  .aclk(clk),
  .s_axis_a_tvalid(F_element_tvalid),
  .s_axis_a_tdata(F_element),
  .s_axis_a_tlast(F_element_tlast),
  .m_axis_result_tvalid(pre_F_value_tvalid),
  .m_axis_result_tdata(F_value),
  .m_axis_result_tlast(pre_F_value_tlast)
);

assign F_value_tvalid = pre_F_value_tvalid & pre_F_value_tlast;
endmodule
