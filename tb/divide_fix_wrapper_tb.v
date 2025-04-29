`timescale 1ns/1ps

module divide_fix_wrapper_tb;

// 参数定义
localparam DATAWIDTH_IN = 32;
localparam DATAWIDTH_OUT = 32;

// 时钟信号
reg aclk;

// 输入信号
reg s_axis_a_tvalid;
reg [DATAWIDTH_IN-1:0] s_axis_a_tdata;
reg s_axis_b_tvalid;
reg [7:0] s_axis_b_tdata;

// 输出信号
wire m_axis_result_tvalid;
wire [DATAWIDTH_OUT-1:0] m_axis_result_tdata;

// 实例化被测模块
divide_fix_wrapper_32_8 dut (
    .aclk(aclk),
    .s_axis_a_tvalid(s_axis_a_tvalid),
    .s_axis_a_tdata(s_axis_a_tdata),
    .s_axis_b_tvalid(s_axis_b_tvalid),
    .s_axis_b_tdata(s_axis_b_tdata),
    .m_axis_result_tvalid(m_axis_result_tvalid),
    .m_axis_result_tdata(m_axis_result_tdata)
);

// 时钟生成
initial begin
    aclk = 0;
    forever #5 aclk = ~aclk;  // 100MHz时钟
end

// 测试过程
initial begin
    // 初始化
    s_axis_a_tvalid = 0;
    s_axis_a_tdata = 0;
    s_axis_b_tvalid = 0;
    s_axis_b_tdata = 0;
    
    // 等待几个时钟周期
    #20;
    
    // 测试用例1：基本除法测试
    @(posedge aclk);
    s_axis_a_tdata = 32'h10000000;  // 10
    s_axis_b_tdata = 8'b10000000;  // 2
    s_axis_a_tvalid = 1;
    s_axis_b_tvalid = 1;
    
    @(posedge aclk);
    s_axis_a_tvalid = 0;
    s_axis_b_tvalid = 0;
    
    // 等待结果

    
    // 等待结果
    #50;
    
    // 结束仿真
    $finish;
end

// 监控输出
always @(posedge aclk) begin
    if (m_axis_result_tvalid) begin
        $display("Time=%t: Dividend=%h, Divisor=%h, Result=%h", 
                 $time, s_axis_a_tdata, s_axis_b_tdata, m_axis_result_tdata);
    end
end


endmodule 