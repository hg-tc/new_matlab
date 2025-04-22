`timescale 1ns/1ps

module multi_divi_index_gen_tb;

// 参数定义
parameter J = 14;
parameter I = 7;
parameter A = 4;
localparam AWIDTH = $clog2(A)+1;
localparam J_WIDTH = $clog2(J)+1;

// 时钟和复位信号
reg clk;
reg rst_n;

// 输入信号
reg [J*AWIDTH-1:0] x_initial;
reg x_initial_tvalid;
reg start_gen;
reg [J_WIDTH-1:0] J_index;

// 输出信号
wire [J*64-1:0] candidate_row;
wire candidate_row_tvalid;
wire candidate_row_tlast;

// 实例化被测模块
multi_divi_index_gen #(
    .J(J),
    .I(I),
    .A(A)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .start_gen(start_gen),
    .J_index(J_index),
    .mutli_col_idx1(mutli_col_idx1),
    .mutli_col_idx2(mutli_col_idx2),
    .multi_row_idx(multi_row_idx),
    .multi_row_idx2(multi_row_idx2),
    .divi_col_idx1(divi_col_idx1),
    .divi_col_idx2(divi_col_idx2),
    .divi_row_idx(divi_row_idx),
    .divi_row_idx2(divi_row_idx2),
    .index_out_tvalid(index_out_tvalid)
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
    x_initial = 0;
    x_initial_tvalid = 0;
    start_gen = 0;
    J_index = 0;
    
    // 复位
    #20;
    rst_n = 1;
    #10;
    
    // 测试用例1：基本功能测试
    @(posedge clk);
    // 设置初始值
    x_initial = {
        {AWIDTH{1'b0}},  // 位置0
        {AWIDTH{1'b1}},  // 位置1
        {AWIDTH{1'b0}},  // 位置2
        {AWIDTH{1'b1}},  // 位置3
        {AWIDTH{1'b0}},  // 位置4
        {AWIDTH{1'b1}},  // 位置5
        {AWIDTH{1'b0}},  // 位置6
        {(J-7)*AWIDTH{1'b0}}  // 其余位置
    };
    x_initial_tvalid = 1;
    @(posedge clk);
    x_initial_tvalid = 0;
    
    // 等待几个时钟周期
    #30;
    
    // 开始生成候选序列
    @(posedge clk);
    start_gen = 1;
    J_index = 7;  // 测试前7个位置
    @(posedge clk);
    start_gen = 0;
    
    // 等待生成完成
    wait(candidate_row_tlast);
    #50;
    
    // 测试用例2：全0初始值
    @(posedge clk);
    x_initial = {(J*AWIDTH){1'b0}};
    x_initial_tvalid = 1;
    @(posedge clk);
    x_initial_tvalid = 0;
    
    #30;
    
    @(posedge clk);
    start_gen = 1;
    J_index = 7;
    @(posedge clk);
    start_gen = 0;
    
    wait(candidate_row_tlast);
    #50;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if (candidate_row_tvalid) begin
        $display("Time=%t: candidate_row=%h, tlast=%b", 
            $time, candidate_row, candidate_row_tlast);
    end
end

// 波形输出
initial begin
    $dumpfile("multi_divi_index_gen_tb.vcd");
    $dumpvars(0, multi_divi_index_gen_tb);
end

endmodule