module F_case4_fix #(
    parameter J = 4,
    parameter I = 8, 
    parameter A = 4,
    localparam AWIDTH = $clog2(A)+1,
    localparam J_WIDTH = $clog2(J)+1
)(
    input clk,
    input rst_n,

    input [J*64-1:0] H,
    input [128-1:0] y,
    input H_tvalid,

    input [J*AWIDTH-1:0] x,
    input x_tvalid,

    output [63:0] F_value,
    output F_value_tvalid
);

reg [J*64-1:0] H_reg;
reg [128-1:0] y_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_reg <= 0;
        y_reg <= 0;
    end
    else begin
        if (H_tvalid) begin
            H_reg <= H;
            y_reg <= y;
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
    .SIZE(512),
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



reg [J_WIDTH-1:0] H_cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_cnt <= 0;
    end
    else begin
        if(x_fifo_out_tvalid) begin
            if(H_cnt < J-1) begin
                H_cnt <= H_cnt + 1;
            end
            else begin
                H_cnt <= 0;
            end
        end
    end
end

//----parameter----
reg [63:0] sigma2 = 0;
reg [128 * A - 1 : 0] Aset = 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sigma2 <= 64'h4000000000000000;
        Aset <= {64'hBFE6A0902DE00D1B, 64'h3FE6A0902DE00D1B,
                 64'hBFE6A0902DE00D1B, 64'hBFE6A0902DE00D1B,
                 64'h3FE6A0902DE00D1B, 64'hBFE6A0902DE00D1B,
                 64'h3FE6A0902DE00D1B, 64'h3FE6A0902DE00D1B};

        // y_reg <= {64'h3FF80ADBAC00BEA0, 64'h400AE682B28C422A,
        //           64'h3FFBBFCEF1883FA6, 64'hC004B736E000F043,
        //           64'h3FF57222CB9D877A, 64'hBFE815F9F9DFEBBA,
        //           64'h3FFB2DB0BB2BC3B4, 64'h40038A0CFABB192A,
        //           64'h3FFD8E079EFDD764, 64'hC0018DB882926B5D,
        //           64'h4000D420EC64DB14, 64'hBFDD5A50254EF3FD,
        //           64'h3FE317DDCF6D579A, 64'h3FF379058737F844,
        //           64'h3FE21B141554CC6F, 64'hC0042CAFE382D2CB};
                  //  i, real
    end 
end

wire [64-1:0] F_element_real,F_element_imag;
wire F_element_real_tvalid,F_element_imag_tvalid;

multiply multiply_real (
    .aclk(clk),
    .s_axis_a_tvalid(x_fifo_out_tvalid),
    .s_axis_a_tdata(H_reg[H_cnt*64+:64]),
    .s_axis_b_tvalid(x_fifo_out_tvalid),
    .s_axis_b_tdata(Aset[128*x_fifo_out+:64]),
    .m_axis_result_tvalid(F_element_real_tvalid),
    .m_axis_result_tdata(F_element_real)
);

multiply multiply_imag (
    .aclk(clk),
    .s_axis_a_tvalid(x_fifo_out_tvalid),
    .s_axis_a_tdata(H_reg[H_cnt*64+:64]),
    .s_axis_b_tvalid(x_fifo_out_tvalid),
    .s_axis_b_tdata(Aset[128*x_fifo_out + 64+:64]),
    .m_axis_result_tvalid(F_element_imag_tvalid),
    .m_axis_result_tdata(F_element_imag)
);

assign F_element_tvalid = F_element_real_tvalid & F_element_imag_tvalid;

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





wire [63:0] acc_result_real;
wire [63:0] acc_result_imag;
wire acc_real_valid;
wire acc_imag_valid;
wire acc_real_last;
wire acc_imag_last;

accumulator accumulator_real (
    .aclk(clk),
    .s_axis_a_tvalid(F_element_real_tvalid),
    .s_axis_a_tdata(F_element_real),
    .s_axis_a_tlast(F_element_tlast),
    .m_axis_result_tvalid(acc_real_valid),
    .m_axis_result_tdata(acc_result_real),
    .m_axis_result_tlast(acc_real_last)
);

accumulator accumulator_imag (
    .aclk(clk),
    .s_axis_a_tvalid(F_element_imag_tvalid),
    .s_axis_a_tdata(F_element_imag),
    .s_axis_a_tlast(F_element_tlast),
    .m_axis_result_tvalid(acc_imag_valid),
    .m_axis_result_tdata(acc_result_imag),
    .m_axis_result_tlast(acc_imag_last)
);

wire F_value_real_tvalid;
wire F_value_imag_tvalid;
wire [63:0] F_value_real;
wire [63:0] F_value_imag;
subtract subtract_real (
    .aclk(clk),
    .s_axis_a_tvalid(acc_real_valid & acc_real_last),
    .s_axis_a_tdata(y_reg[63:0]),
    .s_axis_b_tvalid(acc_real_valid & acc_real_last),
    .s_axis_b_tdata(acc_result_real),
    .m_axis_result_tvalid(F_value_real_tvalid),
    .m_axis_result_tdata(F_value_real)
);
subtract subtract_imag (
    .aclk(clk),
    .s_axis_a_tvalid(acc_imag_valid & acc_imag_last),
    .s_axis_a_tdata(y_reg[127:64]),
    .s_axis_b_tvalid(acc_imag_valid & acc_imag_last),
    .s_axis_b_tdata(acc_result_imag),
    .m_axis_result_tvalid(F_value_imag_tvalid),
    .m_axis_result_tdata(F_value_imag)
);

wire F_value_real2_tvalid;
wire F_value_imag2_tvalid;
wire [63:0] F_value_real2;
wire [63:0] F_value_imag2;
multiply multiply_F_value_real (
    .aclk(clk),
    .s_axis_a_tvalid(F_value_real_tvalid ),
    .s_axis_a_tdata(F_value_real),
    .s_axis_b_tvalid(F_value_real_tvalid ),
    .s_axis_b_tdata(F_value_real),
    .m_axis_result_tvalid(F_value_real2_tvalid),
    .m_axis_result_tdata(F_value_real2)
);

multiply multiply_F_value_imag (
    .aclk(clk),
    .s_axis_a_tvalid(F_value_imag_tvalid),
    .s_axis_a_tdata(F_value_imag),
    .s_axis_b_tvalid(F_value_imag_tvalid),
    .s_axis_b_tdata(F_value_imag),
    .m_axis_result_tvalid(F_value_imag2_tvalid),
    .m_axis_result_tdata(F_value_imag2)
);

wire pre_F_value_tvalid;
wire [63:0] pre_F_value;
add add_F_value (
    .aclk(clk),
    .s_axis_a_tvalid(F_value_real2_tvalid && F_value_imag2_tvalid),
    .s_axis_a_tdata(F_value_real2),
    .s_axis_b_tvalid(F_value_real2_tvalid && F_value_imag2_tvalid),
    .s_axis_b_tdata(F_value_imag2),
    .m_axis_result_tvalid(pre_F_value_tvalid),
    .m_axis_result_tdata(pre_F_value)
);
wire pre_F_value2_tvalid;
wire [63:0] pre_F_value2;
divide divide_F_value (
    .aclk(clk),
    .s_axis_a_tvalid(pre_F_value_tvalid),
    .s_axis_a_tdata(pre_F_value),
    .s_axis_b_tvalid(pre_F_value_tvalid),
    .s_axis_b_tdata(sigma2),
    .m_axis_result_tvalid(pre_F_value2_tvalid),
    .m_axis_result_tdata(pre_F_value2)
);

exp exp_F_value (
    .aclk(clk),
    .s_axis_a_tvalid(pre_F_value2_tvalid),
    .s_axis_a_tdata({~pre_F_value2[63], pre_F_value2[62:0]}),
    .m_axis_result_tvalid(F_value_tvalid),
    .m_axis_result_tdata(F_value)
);

endmodule
