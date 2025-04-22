module F_case4_flow #(
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

    input [64-1:0] y,
    input y_tvalid,

    input [AWIDTH-1:0] x,
    input x_tvalid,

    input [63:0] sigma,
    input sigma_tvalid,

    output [63:0] F_value,
    output F_value_tvalid
);

reg [J*64-1:0] H_reg;
reg [63:0] y_reg;
reg [63:0] sigma_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_reg <= 0;
        y_reg <= 0;
        sigma_reg <= 0;
    end
    else begin
        if (H_tvalid) begin
            H_reg <= H;
        end
        if (y_tvalid) begin
            y_reg <= y;
        end
        if (sigma_tvalid) begin
            sigma_reg <= sigma;
        end
    end
end


wire [AWIDTH-1:0] x_fifo_out;
wire x_fifo_out_tvalid;
wire x_empty;

wire [64-1:0] x_double;
wire x_double_tvalid;

wire [64-1:0] Hx;
wire Hx_tvalid;
wire Hx_tlast;

assign x_fifo_out = x;
assign x_fifo_out_tvalid = x_tvalid;

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

accumulator accumulator (
  .aclk(clk),
  .s_axis_a_tvalid(F_element_tvalid),
  .s_axis_a_tdata(F_element),
  .s_axis_a_tlast(F_element_tlast),
  .m_axis_result_tvalid(Hx_tvalid),
  .m_axis_result_tdata(Hx),
  .m_axis_result_tlast(Hx_tlast)
);

wire [63:0] y_fifo_out;
wire y_fifo_out_tvalid;
wire y_empty;

// easy_fifo #(
//     .DATAWIDTH(64),
//     .SIZE(64),
//     .IN_SIZE(1),
//     .OUT_SIZE(1)
// ) fifo_y (
//     .clk(clk),
//     .rst_n(rst_n),
//     .din(y),
//     .din_valid(y_tvalid),
//     .request(HX_tvalid),
//     .dout(y_fifo_out),
//     .out_valid(y_fifo_out_tvalid),
//     .empty(y_empty)
// );

wire [63:0] yHx;
wire yHx_tvalid;
subtract subtract (
    .aclk(clk),
    .s_axis_a_tvalid(Hx_tvalid & Hx_tlast),
    .s_axis_a_tdata(y_reg),
    .s_axis_b_tvalid(Hx_tvalid & Hx_tlast),
    .s_axis_b_tdata(Hx),
    .m_axis_result_tvalid(yHx_tvalid),
    .m_axis_result_tdata(yHx)
);

wire [63:0] yHx2;
wire yHx2_tvalid;
multiply ymultiply (
    .aclk(clk),
    .s_axis_a_tvalid(yHx_tvalid),
    .s_axis_a_tdata(yHx),
    .s_axis_b_tvalid(yHx_tvalid),
    .s_axis_b_tdata(yHx),
    .m_axis_result_tvalid(yHx2_tvalid),
    .m_axis_result_tdata(yHx2)
);
wire [63:0] yHx2_sigma;
wire yHx2_sigma_tvalid;
divide divide (
    .aclk(clk),
    .s_axis_a_tvalid(yHx2_tvalid),
    .s_axis_a_tdata(yHx2),
    .s_axis_b_tvalid(yHx2_tvalid),
    .s_axis_b_tdata(sigma_reg),
    .m_axis_result_tvalid(yHx2_sigma_tvalid),
    .m_axis_result_tdata(yHx2_sigma)
);

exp exp (
    .aclk(clk),
    .s_axis_a_tvalid(yHx2_sigma_tvalid),
    .s_axis_a_tdata({0,yHx2_sigma[62:0]}),
    .m_axis_result_tvalid(F_value_tvalid),
    .m_axis_result_tdata(F_value)
);
endmodule

