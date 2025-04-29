module flow_max_index_fix(clk,din,din_tvalid,din_tlast,dout,dout_tvalid);

parameter DATAWIDTH = 16; // 改为16bit定点数
parameter AWIDTH = 8;

input clk;
input [ DATAWIDTH - 1 : 0 ] din;
input din_tvalid,din_tlast;

output reg [AWIDTH-1:0] dout=0; // 改为32位即可存储序号
output reg dout_tvalid=0;

reg [DATAWIDTH-1:0] din_max_reg = 0;
reg [AWIDTH-1:0] index_reg = 0; // 记录当前序号
reg [AWIDTH-1:0] max_index_reg = 0; // 记录最大值对应序号

wire change;
// less_than less_than (
//   .s_axis_a_tvalid(1),
//   .s_axis_a_tdata(din_max_reg),
//   .s_axis_b_tvalid(1),
//   .s_axis_b_tdata(din),
//   .m_axis_result_tvalid(),
//   .m_axis_result_tdata(change)
// );

assign change = din_max_reg < din;

always @(posedge clk) begin
    if(din_tlast)begin
        dout <= change ? index_reg : max_index_reg; // 输出最大值对应的序号
        dout_tvalid <= 1;

        din_max_reg <= 0;
        index_reg <= 0;
        max_index_reg <= 0;
    end else if (din_tvalid)begin
        din_max_reg <= change ? din : din_max_reg;
        max_index_reg <= change ? index_reg : max_index_reg; // 更新最大值序号
        index_reg <= index_reg + 1; // 序号加1
        
        dout <= 0;
        dout_tvalid <= 0;
    end else begin
        din_max_reg <= din_max_reg;
        max_index_reg <= max_index_reg;
        index_reg <= index_reg;
        dout <= 0;
        dout_tvalid <= 0;
    end
end

endmodule