`timescale 1ns/1ps

module top_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 2;
localparam J_WIDTH = $clog2(J)+1;
localparam A_WIDTH = $clog2(A)+1;
localparam I_WIDTH = $clog2(I)+1;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [J*64-1:0] H_row;
reg H_row_tvalid;
reg [J*64-1:0] y;
reg y_tvalid;
reg [63:0] sigma;
reg sigma_tvalid;
reg [J*64-1:0] alpha_u_col;
reg alpha_u_col_tvalid;
reg alpha_u_col_tlast;

// 实例化被测模块
top #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .H_row(H_row),
    .H_row_tvalid(H_row_tvalid),
    .y(y),
    .y_tvalid(y_tvalid),
    .sigma(sigma),
    .sigma_tvalid(sigma_tvalid),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast)
);

// 时钟生成
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz时钟
end

// 测试过程
initial begin
    // 初始化
    rst_n <= 0;
    H_row <= 0;
    H_row_tvalid <= 0;
    y <= 0;
    y_tvalid <= 0;
    sigma <= 0;
    sigma_tvalid <= 0;
    alpha_u_col <= 0;
    alpha_u_col_tvalid <= 0;
    alpha_u_col_tlast <= 0;
    
    // 复位
    #20;
    rst_n <= 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置H_row值
    H_row <= {
        // 前7个元素
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        // 其余元素填充0
        {(J-7)*64{1'b0}}
    };
    H_row_tvalid <= 1;
    
    // 设置y值
    y <= {
        // 前7个元素
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        // 其余元素填充0
        {(J-7)*64{1'b0}}
    };
    y_tvalid <= 1;
    
    // 设置sigma值
    sigma <= 64'h3FF0000000000000;  // 1.0
    sigma_tvalid <= 1;
    
    // 设置alpha_u_col值 - 第一周期
    alpha_u_col <= {
        64'h4020000000000000,  // 8.0
        64'h3FF0000000000000,  // 1.0
        64'h4024000000000000,  // 10.0
        64'h4000000000000000,  // 2.0
        64'h4028000000000000,  // 12.0
        64'h4008000000000000,  // 3.0
        64'h402C000000000000,  // 14.0
        64'h4010000000000000,  // 4.0
        64'h4030000000000000,  // 16.0
        64'h4014000000000000,  // 5.0
        64'h4034000000000000,  // 18.0
        64'h4018000000000000,  // 6.0
        64'h4038000000000000,  // 20.0
        64'h401C000000000000   // 7.0
    };
    alpha_u_col_tvalid <= 1;
    alpha_u_col_tlast <= 0;
    
    @(posedge clk);
    // 设置alpha_u_col值 - 第二周期
    alpha_u_col <= {
        64'h3FF0000000000000,  // 1.0
        64'h4020000000000000,  // 8.0
        64'h4000000000000000,  // 2.0
        64'h4024000000000000,  // 10.0
        64'h4008000000000000,  // 3.0
        64'h4028000000000000,  // 12.0
        64'h4010000000000000,  // 4.0
        64'h402C000000000000,  // 14.0
        64'h4014000000000000,  // 5.0
        64'h4030000000000000,  // 16.0
        64'h4018000000000000,  // 6.0
        64'h4034000000000000,  // 18.0
        64'h401C000000000000,  // 7.0
        64'h4038000000000000   // 20.0
    };
    alpha_u_col_tvalid <= 1;
    alpha_u_col_tlast <= 1;
    
    @(posedge clk);
    H_row_tvalid <= 0;
    y_tvalid <= 0;
    sigma_tvalid <= 0;
    alpha_u_col_tvalid <= 0;
    alpha_u_col_tlast <= 0;
    
    // 等待状态机完成
    #100;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge clk) begin
    // 可以添加更多的监控点
    $display("Time=%t: State=%b", $time, dut.state);
end

// 波形输出
initial begin
    $dumpfile("top_tb.vcd");
    $dumpvars(0, top_tb);
end

endmodule 