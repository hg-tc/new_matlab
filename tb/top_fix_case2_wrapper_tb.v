`timescale 1ns/1ps

module top_fix_case2_wrapper_tb;

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
reg start;

// 实例化被测模块
top_fix_case2_wrapper #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start)
);

// 时钟生成
initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 100MHz时钟
end

// 测试过程
initial begin
    // 初始化
    rst_n = 0;
    start = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    start = 1;
    
    @(posedge clk);
    start = 0;
    
    // 等待状态机完成
    #500;
    
    
    // 结束仿真
    $finish;
end


endmodule 