`timescale 1ns/1ps

module MAC_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 2;
localparam J_WIDTH = $clog2(J)+1;
localparam A_WIDTH = $clog2(A)+1;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [63:0] vinput;
reg vinput_tvalid;
reg vinput_tlast;
reg [A*64-1:0] M_row;
reg M_row_tvalid;
reg M_row_tlast;

// 输出信号
wire beta_tvalid;
wire [A*64-1:0] beta;

// 实例化被测模块
MAC #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .vinput(vinput),
    .vinput_tvalid(vinput_tvalid),
    .vinput_tlast(vinput_tlast),
    .M_row(M_row),
    .M_row_tvalid(M_row_tvalid),
    .M_row_tlast(M_row_tlast),
    .beta_tvalid(beta_tvalid),
    .beta(beta)
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
    vinput = 0;
    vinput_tvalid = 0;
    vinput_tlast = 0;
    M_row = 0;
    M_row_tvalid = 0;
    M_row_tlast = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置vinput值
    vinput = 64'h3FF0000000000000;  // 1.0
    vinput_tvalid = 1;
    vinput_tlast = 0;
    
    // 设置M_row值
    M_row = {
        64'h4000000000000000,  // M_row[0] = 2.0
        64'h4008000000000000   // M_row[1] = 3.0
    };
    M_row_tvalid = 1;
    M_row_tlast = 0;
    
    @(posedge clk);
    vinput_tvalid = 0;
    M_row_tvalid = 0;
    
    // 等待几个时钟周期
    #30;
    
    // 发送最后一组数据
    @(posedge clk);
    vinput = 64'h4000000000000000;  // 2.0
    vinput_tvalid = 1;
    vinput_tlast = 1;
    
    M_row = {
        64'h4008000000000000,  // M_row[0] = 3.0
        64'h4010000000000000   // M_row[1] = 4.0
    };
    M_row_tvalid = 1;
    M_row_tlast = 1;
    
    @(posedge clk);
    vinput_tvalid = 0;
    M_row_tvalid = 0;
    
    // 等待计算完成
    wait(beta_tvalid);
    #50;
    
    // 测试用例2：不同的输入值
    @(posedge clk);
    // 设置新的vinput值
    vinput = 64'h4008000000000000;  // 3.0
    vinput_tvalid = 1;
    vinput_tlast = 0;
    
    // 设置新的M_row值
    M_row = {
        64'h4010000000000000,  // M_row[0] = 4.0
        64'h4014000000000000   // M_row[1] = 5.0
    };
    M_row_tvalid = 1;
    M_row_tlast = 0;
    
    @(posedge clk);
    vinput_tvalid = 0;
    M_row_tvalid = 0;
    
    // 等待几个时钟周期
    #30;
    
    // 发送最后一组数据
    @(posedge clk);
    vinput = 64'h4010000000000000;  // 4.0
    vinput_tvalid = 1;
    vinput_tlast = 1;
    
    M_row = {
        64'h4014000000000000,  // M_row[0] = 5.0
        64'h4018000000000000   // M_row[1] = 6.0
    };
    M_row_tvalid = 1;
    M_row_tlast = 1;
    
    @(posedge clk);
    vinput_tvalid = 0;
    M_row_tvalid = 0;
    
    // 等待计算完成
    wait(beta_tvalid);
    #50;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (beta_tvalid) begin
        $display("Time=%t: beta[0]=%h, beta[1]=%h", 
            $time, beta[0*64 +: 64], beta[1*64 +: 64]);
    end
end

// 波形输出
initial begin
    $dumpfile("MAC_tb.vcd");
    $dumpvars(0, MAC_tb);
end

endmodule 