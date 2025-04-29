`timescale 1ns/1ps

module top_fix_case2_tb;

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
reg [J-1:0] H_row;
reg H_row_tvalid;
reg H_row_tlast;
reg [J*8-1:0] alpha_u_col;
reg alpha_u_col_tvalid;
reg alpha_u_col_tlast;

// 实例化被测模块
top_fix_case2 #(
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
    H_row_tlast <= 0;
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
    H_row <= 14'b01100010100011;  // 第1行
    H_row_tvalid <= 1;
    H_row_tlast <= 0;
    @(posedge clk);
    H_row <= 14'b00110101001010;  // 第2行
    
    @(posedge clk);
    H_row <= 14'b01010011000101;  // 第3行
    
    @(posedge clk);
    H_row <= 14'b10001100001011;  // 第4行
    
    @(posedge clk);
    H_row <= 14'b10001010110100;  // 第5行
    
    @(posedge clk);
    H_row <= 14'b10010100111000;  // 第6行
    
    @(posedge clk);
    H_row <= 14'b01101001010100;  // 第7行
    H_row_tlast <= 1;

    @(posedge clk);
    H_row_tlast <= 0;
    H_row_tvalid <= 0;
    
    // 设置alpha_u_col值 - 第一周期
    alpha_u_col <= {
        8'h74,  // 0.456227533519268 -> 0.4531
        8'hCE,  // 0.805731095373631 -> 0.8047
        8'hB3,  // 0.701058834791184 -> 0.7031
        8'hE7,  // 0.903139885514975 -> 0.9023
        8'hBF,  // 0.747154954820871 -> 0.7461
        8'hCE,  // 0.806031234562397 -> 0.8047
        8'h16,  // 0.0870468914508820 -> 0.0859
        8'h1B,  // 0.106564138084650 -> 0.1055
        8'h51,  // 0.317370291799307 -> 0.3164
        8'h05,  // 0.0192187093198299 -> 0.0195
        8'h33,  // 0.200912635773420 -> 0.1992
        8'hF9,  // 0.975526563823223 -> 0.9766
        8'hA6,  // 0.648862030357122 -> 0.6484
        8'hFF   // 0.997891668230295 -> 0.9961
    };
    alpha_u_col_tvalid <= 1;
    alpha_u_col_tlast <= 0;
    
    @(posedge clk);
    // 设置alpha_u_col值 - 第二周期
    alpha_u_col <= {
        8'h8B,  // 0.543772466480732 -> 0.5430
        8'h32,  // 0.194268904626369 -> 0.1953
        8'h4D,  // 0.298941165208817 -> 0.3008
        8'h19,  // 0.0968601144850254 -> 0.0977
        8'h41,  // 0.252845045179129 -> 0.2539
        8'h32,  // 0.193968765437603 -> 0.1953
        8'hE9,  // 0.912953108549118 -> 0.9141
        8'hE5,  // 0.893435861915350 -> 0.8945
        8'hAE,  // 0.682629708200693 -> 0.6836
        8'hFB,  // 0.980781290680170 -> 0.9844
        8'hCD,  // 0.799087364226580 -> 0.8008
        8'h06,  // 0.0244734361767769 -> 0.0234
        8'h5A,  // 0.351137969642878 -> 0.3516
        //8'h00,  // 0.00210833176970482 -> 0.0000
        8'h01   // 0.00210833176970482 -> 0.0039
    };
    alpha_u_col_tvalid <= 1;
    alpha_u_col_tlast <= 1;

    
    @(posedge clk);
    H_row_tvalid <= 0;
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

endmodule 