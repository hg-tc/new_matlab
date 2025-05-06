module adder_case2_fix (
    input clk,
    input rst_n,
    input [128-1:0] din,
    input din_tvalid,
    output [63:0] dout,
    output reg dout_tvalid
);

reg [63:0] dout_temp;
wire [63:0] a;
wire [63:0] b;
assign a = din[64-1:0];
assign b = din[128-1:64];
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dout_temp <= 0;
        dout_tvalid <= 0;
    end else begin
        if(din_tvalid) begin
            dout_temp <= a + b;
            dout_tvalid <= 1;
        end else begin
            dout_tvalid <= 0;
            dout_temp <= 0;
        end
    end
end

assign dout = dout_temp;

endmodule