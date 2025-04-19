module flow_max(clk,din,din_tvalid,din_tlast,dout,dout_tvalid);

parameter DATAWIDTH = 64;

input clk;
input [ DATAWIDTH - 1 : 0 ] din;
input din_tvalid,din_tlast;

output reg [DATAWIDTH-1 : 0] dout=0;
output reg dout_tvalid=0;


reg [DATAWIDTH-1:0] din_max_reg = 0;

wire change;
less_than less_than (
  .s_axis_a_tvalid(1),
  .s_axis_a_tdata(din_max_reg),
  .s_axis_b_tvalid(1),
  .s_axis_b_tdata(din),
  .m_axis_result_tvalid(),
  .m_axis_result_tdata(change)
);


always @(posedge clk) begin
    if(din_tlast)begin
        dout <= change ? din : din_max_reg;
        dout_tvalid <= 1;

        din_max_reg <= 0;

    end else if (din_tvalid)begin
        din_max_reg <= change ? din : din_max_reg;
        
        dout <= 0;
        dout_tvalid <= 0;
    end else begin
        din_max_reg <= din_max_reg;
        dout <= 0;
        dout_tvalid <= 0;
    end
end





endmodule