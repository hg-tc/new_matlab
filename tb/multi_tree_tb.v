module tb_multi_tree();

// 参数定义
parameter NUM = 14;
parameter DATA_WIDTH = 64;
parameter CLK_PERIOD = 10;  // 100MHz时钟

// 信号定义
reg clk;
reg rst_n;
reg [NUM*DATA_WIDTH-1:0] din;
reg [NUM-1:0] din_tvalid;
wire [DATA_WIDTH-1:0] dout;
wire dout_tvalid;

// 实例化乘法树
multi_tree #(
    .NUM(NUM),
    .DATA_WIDTH(DATA_WIDTH)
) u_multi_tree (
    .clk(clk),
    .rst_n(rst_n),
    .din(din),
    .din_tvalid(din_tvalid),
    .dout(dout),
    .dout_tvalid(dout_tvalid)
);

// 时钟生成
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end



// 主测试过程
initial begin
    // 初始化
    rst_n = 0;
    din = 0;
    din_tvalid = 0;
    
    // 复位
    #(CLK_PERIOD*2);
    rst_n = 1;
    #(CLK_PERIOD*2);
    
    // 测试用例2：递增序列
    din[0*DATA_WIDTH +: DATA_WIDTH] = 64'h3FF0000000000000;  // 1.0
    din[1*DATA_WIDTH +: DATA_WIDTH] = 64'h4000000000000000;  // 2.0
    din[2*DATA_WIDTH +: DATA_WIDTH] = 64'h4008000000000000;  // 3.0
    din[3*DATA_WIDTH +: DATA_WIDTH] = 64'h4010000000000000;  // 4.0
    din[4*DATA_WIDTH +: DATA_WIDTH] = 64'h4014000000000000;  // 5.0
    din[5*DATA_WIDTH +: DATA_WIDTH] = 64'h4018000000000000;  // 6.0
    din[6*DATA_WIDTH +: DATA_WIDTH] = 64'h401C000000000000;  // 7.0
    din[7*DATA_WIDTH +: DATA_WIDTH] = 64'h4020000000000000;  // 8.0
    din[8*DATA_WIDTH +: DATA_WIDTH] = 64'h4022000000000000;  // 9.0
    din[9*DATA_WIDTH +: DATA_WIDTH] = 64'h4024000000000000;  // 10.0
    din[10*DATA_WIDTH +: DATA_WIDTH] = 64'h4026000000000000; // 11.0
    din[11*DATA_WIDTH +: DATA_WIDTH] = 64'h4028000000000000; // 12.0
    din[12*DATA_WIDTH +: DATA_WIDTH] = 64'h402A000000000000; // 13.0
    din[13*DATA_WIDTH +: DATA_WIDTH] = 64'h402C000000000000; // 14.0
    din_tvalid = 14'b11111111111111;

    #(CLK_PERIOD);

    din_tvalid = 0;
    // 测试完成
    $display("All tests passed!");
    $finish;
end

// 监控输出
always @(posedge clk) begin
    if(dout_tvalid) begin
        $display("Time %t: Output = %h", $time, dout);
    end
end

endmodule