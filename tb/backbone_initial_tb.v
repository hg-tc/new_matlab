`timescale 1ns/1ps

module backbone_initial_tb;

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
reg [J*A*64-1:0] alpha_u;
reg alpha_u_tvalid;
reg [J*A_WIDTH-1:0] x_initial;
reg x_initial_tvalid;
reg [J_WIDTH-1:0] ind_j;
reg ind_j_tvalid;

// 输出信号
wire backbone_initial_tvalid;
wire [63:0] backbone_initial;

// 实例化被测模块
backbone_initial #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .alpha_u(alpha_u),
    .alpha_u_tvalid(alpha_u_tvalid),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .ind_j(ind_j),
    .ind_j_tvalid(ind_j_tvalid),
    .backbone_initial_tvalid(backbone_initial_tvalid),
    .backbone_initial(backbone_initial)
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
    alpha_u = 0;
    alpha_u_tvalid = 0;
    x_initial = 0;
    x_initial_tvalid = 0;
    ind_j = 0;
    ind_j_tvalid = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置alpha_u输入（示例值）
    alpha_u = {
        // 第一组A个值
        64'h3FF0000000000000,  // 1.0
        64'h4000000000000000,  // 2.0
        // 第二组A个值
        64'h4008000000000000,  // 3.0
        64'h4010000000000000,  // 4.0
        // 第三组A个值
        64'h4014000000000000,  // 5.0
        64'h4018000000000000,  // 6.0
        // 第四组A个值
        64'h401C000000000000,  // 7.0
        64'h4020000000000000,  // 8.0
        // 第五组A个值
        64'h4022000000000000,  // 9.0
        64'h4024000000000000,  // 10.0
        // 第六组A个值
        64'h4026000000000000,  // 11.0
        64'h4028000000000000,  // 12.0
        // 第七组A个值
        64'h402A000000000000,  // 13.0
        64'h402C000000000000,  // 14.0
        // 第八组A个值
        64'h402E000000000000,  // 15.0
        64'h4030000000000000,  // 16.0
        // 第九组A个值
        64'h4031000000000000,  // 17.0
        64'h4032000000000000,  // 18.0
        // 第十组A个值
        64'h4033000000000000,  // 19.0
        64'h4034000000000000,  // 20.0
        // 第十一组A个值
        64'h4035000000000000,  // 21.0
        64'h4036000000000000,  // 22.0
        // 第十二组A个值
        64'h4037000000000000,  // 23.0
        64'h4038000000000000,  // 24.0
        // 第十三组A个值
        64'h4039000000000000,  // 25.0
        64'h403A000000000000,  // 26.0
        // 第十四组A个值
        64'h403B000000000000,  // 27.0
        64'h403C000000000000   // 28.0
    };
    alpha_u_tvalid = 1;
    
    // 设置x_initial输入
    x_initial = {
        2'b0,  // 位置0
        2'b1,  // 位置1 
        2'b0,  // 位置2
        2'b1,  // 位置3
        2'b0,  // 位置4
        2'b1,  // 位置5
        2'b0,  // 位置6
        2'b1,  // 位置7
        2'b0,  // 位置8
        2'b1,  // 位置9
        2'b0,  // 位置10
        2'b1,  // 位置11
        2'b0,  // 位置12
        2'b1   // 位置13
    };
    x_initial_tvalid = 1;
    
    // 设置ind_j输入
    ind_j = 7;  // 测试前7个位置
    ind_j_tvalid = 1;
    
    @(posedge clk);
    alpha_u_tvalid = 0;
    x_initial_tvalid = 0;
    ind_j_tvalid = 0;
    
    // 等待结果
    #200;
    
    
    // 结束仿真
    #100;
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (backbone_initial_tvalid) begin
        $display("Time=%t: backbone_initial=%h", $time, backbone_initial);
    end
end

// 波形输出
initial begin
    $dumpfile("backbone_initial_tb.vcd");
    $dumpvars(0, backbone_initial_tb);
end

endmodule 