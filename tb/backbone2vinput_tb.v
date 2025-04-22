`timescale 1ns/1ps

module backbone2vinput_tb;

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
reg [63:0] backbone;
reg backbone_tvalid;
reg [J*A_WIDTH-1:0] x_initial;
reg x_initial_tvalid;
reg [J_WIDTH-1:0] ind_j;
reg ind_j_tvalid;
reg [J*A*64-1:0] alpha_u;
reg alpha_u_tvalid;

// 输出信号
wire vinput_tvalid;
wire [63:0] vinput;

// 实例化被测模块
backbone2vinput #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .backbone(backbone),
    .backbone_tvalid(backbone_tvalid),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .ind_j(ind_j),
    .ind_j_tvalid(ind_j_tvalid),
    .alpha_u(alpha_u),
    .alpha_u_tvalid(alpha_u_tvalid),
    .vinput_tvalid(vinput_tvalid),
    .vinput(vinput)
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
    backbone = 0;
    backbone_tvalid = 0;
    x_initial = 0;
    x_initial_tvalid = 0;
    ind_j = 0;
    ind_j_tvalid = 0;
    alpha_u = 0;
    alpha_u_tvalid = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置初始值
    x_initial = {
        {2'b01},  // 位置13
        {2'b00},  // 位置12
        {2'b01},  // 位置11
        {2'b00},  // 位置10
        {2'b01},  // 位置9
        {2'b00},  // 位置8
        {2'b01},  // 位置7
        {2'b00},  // 位置6
        {2'b01},  // 位置5
        {2'b00},  // 位置4
        {2'b01},  // 位置3
        {2'b00},  // 位置2
        {2'b01},  // 位置1
        {2'b00}   // 位置0
    };
    x_initial_tvalid = 1;
    
    // 设置alpha_u值
    alpha_u = {
        // 第14行
        64'h3FF0000000000000,  // alpha_u[13][0] = 1.0
        64'h4000000000000000,  // alpha_u[13][1] = 2.0
        // 第13行
        64'h4008000000000000,  // alpha_u[12][0] = 3.0
        64'h4010000000000000,  // alpha_u[12][1] = 4.0
        // 第12行
        64'h4014000000000000,  // alpha_u[11][0] = 5.0
        64'h4018000000000000,  // alpha_u[11][1] = 6.0
        // 第11行
        64'h401C000000000000,  // alpha_u[10][0] = 7.0
        64'h4020000000000000,  // alpha_u[10][1] = 8.0
        // 第10行
        64'h4022000000000000,  // alpha_u[9][0] = 9.0
        64'h4024000000000000,  // alpha_u[9][1] = 10.0
        // 第9行
        64'h4026000000000000,  // alpha_u[8][0] = 11.0
        64'h4028000000000000,  // alpha_u[8][1] = 12.0
        // 第8行
        64'h402A000000000000,  // alpha_u[7][0] = 13.0
        64'h402C000000000000,  // alpha_u[7][1] = 14.0
        // 第7行
        64'h402E000000000000,  // alpha_u[6][0] = 15.0
        64'h4030000000000000,  // alpha_u[6][1] = 16.0
        // 第6行
        64'h4031000000000000,  // alpha_u[5][0] = 17.0
        64'h4032000000000000,  // alpha_u[5][1] = 18.0
        // 第5行
        64'h4033000000000000,  // alpha_u[4][0] = 19.0
        64'h4034000000000000,  // alpha_u[4][1] = 20.0
        // 第4行
        64'h4035000000000000,  // alpha_u[3][0] = 21.0
        64'h4036000000000000,  // alpha_u[3][1] = 22.0
        // 第3行
        64'h4037000000000000,  // alpha_u[2][0] = 23.0
        64'h4038000000000000,  // alpha_u[2][1] = 24.0
        // 第2行
        64'h4039000000000000,  // alpha_u[1][0] = 25.0
        64'h403A000000000000,  // alpha_u[1][1] = 26.0
        // 第1行
        64'h403B000000000000,  // alpha_u[0][0] = 27.0
        64'h403C000000000000   // alpha_u[0][1] = 28.0
    };
    alpha_u_tvalid = 1;
    
    // 设置ind_j
    ind_j = 7;
    ind_j_tvalid = 1;
    
    // 设置backbone
    backbone = 64'h3FF0000000000000;  // 1.0
    backbone_tvalid = 1;
    
    @(posedge clk);
    x_initial_tvalid = 0;
    alpha_u_tvalid = 0;
    ind_j_tvalid = 0;
    backbone_tvalid = 0;
    
    // 等待计算完成
    wait(vinput_tvalid);
    #50;
    
    // // 测试用例2：不同的输入值
    // @(posedge clk);
    // // 设置新的初始值
    // x_initial = {(J*A_WIDTH){1'b1}};  // 所有位置为1
    // x_initial_tvalid = 1;
    
    // // 设置新的alpha_u值
    // alpha_u = {
    //     // 第一行
    //     64'h4010000000000000,  // alpha_u[0][0] = 4.0
    //     64'h4014000000000000,  // alpha_u[0][1] = 5.0
    //     // 第二行
    //     64'h4018000000000000,  // alpha_u[1][0] = 6.0
    //     64'h401C000000000000,  // alpha_u[1][1] = 7.0
    //     // 其余位置填充0
    //     {(J*A-4)*64{1'b0}}
    // };
    // alpha_u_tvalid = 1;
    
    // // 设置新的backbone
    // backbone = 64'h4000000000000000;  // 2.0
    // backbone_tvalid = 1;
    
    // @(posedge clk);
    // x_initial_tvalid = 0;
    // alpha_u_tvalid = 0;
    // backbone_tvalid = 0;
    
    // 等待计算完成
    wait(vinput_tvalid);
    #50;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (vinput_tvalid) begin
        $display("Time=%t: vinput=%h", $time, vinput);
    end
end

// 波形输出
initial begin
    $dumpfile("backbone2vinput_tb.vcd");
    $dumpvars(0, backbone2vinput_tb);
end

endmodule