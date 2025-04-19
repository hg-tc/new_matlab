`timescale 1ns/1ps

module M_gen_case2_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 2;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [J*64-1:0] H_row;
reg H_row_tvalid;
reg [J*64-1:0] alpha_u_col;
reg alpha_u_col_tvalid;
reg alpha_u_col_tlast;

// 输出信号
wire F_value_tvalid;
wire [63:0] F_value;

// 实例化被测模块
M_gen_case2 #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .H_row(H_row),
    .H_row_tvalid(H_row_tvalid),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast),
    .F_value_tvalid(F_value_tvalid),
    .F_value(F_value)
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
    H_row = 0;
    H_row_tvalid = 0;
    alpha_u_col = 0;
    alpha_u_col_tvalid = 0;
    alpha_u_col_tlast = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置H_row输入（示例值）
    H_row = {
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        {(J-7)*64{1'b0}}      // 其余位置
    };
    H_row_tvalid = 1;
    
    // 设置alpha_u_col输入
    alpha_u_col = {
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        64'h401C000000000000,  // 7.0
        {(J-7)*64{1'b0}}      // 其余位置
    };
    alpha_u_col_tvalid = 1;
    alpha_u_col_tlast = 0;
    
    @(posedge clk);
    H_row_tvalid = 0;
    alpha_u_col_tvalid = 0;
    
    // 等待几个时钟周期
    #30;
    
    // 发送最后一组数据
    @(posedge clk);
    alpha_u_col = {
        64'h401C000000000000,  // 7.0
        64'h4018000000000000,  // 6.0
        64'h4014000000000000,  // 5.0
        64'h4010000000000000,  // 4.0
        64'h4008000000000000,  // 3.0
        64'h4000000000000000,  // 2.0
        64'h3FF0000000000000,  // 1.0
        {(J-7)*64{1'b0}}      // 其余位置
    };
    alpha_u_col_tvalid = 1;
    alpha_u_col_tlast = 1;
    
    @(posedge clk);
    alpha_u_col_tvalid = 0;
    alpha_u_col_tlast = 0;
    
    // 等待结果
    #200;
    
    // 测试用例2：随机数据测试
    repeat(3) begin
        @(posedge clk);
        H_row = {$random, $random, $random, $random, $random, $random, $random, {(J-7)*64{1'b0}}};
        H_row_tvalid = 1;
        
        alpha_u_col = {$random, $random, $random, $random, $random, $random, $random, {(J-7)*64{1'b0}}};
        alpha_u_col_tvalid = 1;
        alpha_u_col_tlast = 0;
        
        @(posedge clk);
        H_row_tvalid = 0;
        alpha_u_col_tvalid = 0;
        
        #30;
        
        @(posedge clk);
        alpha_u_col = {$random, $random, $random, $random, $random, $random, $random, {(J-7)*64{1'b0}}};
        alpha_u_col_tvalid = 1;
        alpha_u_col_tlast = 1;
        
        @(posedge clk);
        alpha_u_col_tvalid = 0;
        alpha_u_col_tlast = 0;
        
        #200;
    end
    
    // 结束仿真
    #100;
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
    $dumpfile("M_gen_case2_tb.vcd");
    $dumpvars(0, M_gen_case2_tb);
end

endmodule 