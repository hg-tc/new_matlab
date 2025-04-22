`timescale 1ns/1ps

module F_case4_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 2;
localparam AWIDTH = $clog2(A)+1;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [J*64-1:0] H;
reg H_tvalid;
reg [63:0] y;
reg y_tvalid;
reg [J*AWIDTH-1:0] x;
reg x_tvalid;
reg [63:0] sigma;
reg sigma_tvalid;

// 输出信号
wire [J*AWIDTH-1:0] F_value;
wire F_value_tvalid;

// 实例化被测模块
F_case4 #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .H(H),
    .H_tvalid(H_tvalid),
    .y(y),
    .y_tvalid(y_tvalid),
    .x(x),
    .x_tvalid(x_tvalid),
    .sigma(sigma),
    .sigma_tvalid(sigma_tvalid),
    .F_value(F_value),
    .F_value_tvalid(F_value_tvalid)
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
    H = 0;
    H_tvalid = 0;
    y = 0;
    y_tvalid = 0;
    x = 0;
    x_tvalid = 0;
    sigma = 0;
    sigma_tvalid = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置H值（J个元素）
    H = {
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
    H_tvalid = 1;
    
    // 设置y值
    y = 64'h4020000000000000;  // 8.0
    y_tvalid = 1;
    
    // 设置x值（J个元素）
    x = {
        // 前7个元素
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        // 其余元素填充0
        {(J-7)*AWIDTH{1'b0}}
    };
    x_tvalid = 1;
    
    // 设置sigma值
    sigma = 64'h3FF0000000000000;  // 1.0
    sigma_tvalid = 1;
    
    @(posedge clk);
    H_tvalid = 0;
    y_tvalid = 0;
    x_tvalid = 0;
    sigma_tvalid = 0;
    
    // 等待计算完成
    wait(F_value_tvalid);
    #50;
    
    // 测试用例2：不同的输入值
    @(posedge clk);
    // 设置新的H值
    H = {
        // 前7个元素
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        64'h4020000000000000,  // 8.0
        // 其余元素填充0
        {(J-7)*64{1'b0}}
    };
    H_tvalid = 1;
    
    // 设置新的y值
    y = 64'h4024000000000000;  // 10.0
    y_tvalid = 1;
    
    // 设置新的x值
    x = {
        // 前7个元素
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        {AWIDTH{1'b0}},  // 0
        {AWIDTH{1'b1}},  // 1
        // 其余元素填充0
        {(J-7)*AWIDTH{1'b0}}
    };
    x_tvalid = 1;
    
    // 设置新的sigma值
    sigma = 64'h4000000000000000;  // 2.0
    sigma_tvalid = 1;
    
    @(posedge clk);
    H_tvalid = 0;
    y_tvalid = 0;
    x_tvalid = 0;
    sigma_tvalid = 0;
    
    // 等待计算完成
    wait(F_value_tvalid);
    #50;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (F_value_tvalid) begin
        $display("Time=%t: F_value=%h", $time, F_value);
    end
end

// 波形输出
initial begin
    $dumpfile("F_case4_tb.vcd");
    $dumpvars(0, F_case4_tb);
end

endmodule 