`timescale 1ns/1ps

module alpha2xinitial_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 2;
localparam AWIDTH = $clog2(A)+1;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [J*64-1:0] alpha_u_col;
reg alpha_u_col_tvalid;
reg alpha_u_col_tlast;

// 输出信号
wire [J*AWIDTH-1:0] x_initial;
wire x_initial_tvalid;

// 实例化被测模块
alpha2xinitial #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid)
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
    alpha_u_col = 0;
    alpha_u_col_tvalid = 0;
    alpha_u_col_tlast = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：正常数据
    @(posedge clk);
    alpha_u_col = {
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        {7*64{1'b0}}          // 其余位置0
    };
    alpha_u_col_tvalid = 1;
    alpha_u_col_tlast = 0;
    @(posedge clk);
    alpha_u_col = {
        64'h4014000000000000,  // 1.0
        64'h4014000000000000,  // 2.0
        64'h4014000000000000,  // 3.0
        64'h4014000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4014000000000000,  // 6.0
        64'h4014000000000000,  // 7.0
        {7*64{1'b0}}          // 其余位置0
    };
    alpha_u_col_tvalid = 1;
    alpha_u_col_tlast = 1;
    @(posedge clk);
    alpha_u_col_tvalid = 0;
    alpha_u_col_tlast = 0;
    
    // 等待结果
    #100;
    
    // 测试用例2：随机数据
    // repeat(5) begin
    //     @(posedge clk);
    //     alpha_u_col = {$random, $random, $random, $random, $random, $random, $random, {7*64{1'b0}}};
    //     alpha_u_col_tvalid = 1;
    //     alpha_u_col_tlast = 1;
    //     @(posedge clk);
    //     alpha_u_col_tvalid = 0;
    //     alpha_u_col_tlast = 0;
    //     #100;
    // end
    
    // 结束仿真
    #100;
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (x_initial_tvalid) begin
        $display("Time=%t: x_initial=%h", $time, x_initial);
    end
end

// // 波形输出
// initial begin
//     $dumpfile("alpha2xinitial_tb.vcd");
//     $dumpvars(0, alpha2xinitial_tb);
// end

endmodule 