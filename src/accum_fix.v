module accum_fix #(
    parameter DATAWIDTH_IN = 32,
    parameter DATAWIDTH_OUT = 8
)(
    input clk,
    input rst_n,

    input [DATAWIDTH_IN-1:0] din,
    input din_tvalid,
    input din_tlast,
    output [DATAWIDTH_OUT-1:0] dout,
    output dout_tvalid,
    output dout_tlast
);

reg [DATAWIDTH_IN-1:0] accum_reg;
reg accum_valid;
reg accum_last;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        accum_reg <= 0;
        accum_valid <= 0;
        accum_last <= 0;
    end else begin
        if(din_tvalid) begin
            if(din_tlast) begin
                accum_reg <= din;
                accum_valid <= 1;
                accum_last <= 1;
            end else begin
                accum_reg <= accum_reg + din;
                accum_valid <= 1;
                accum_last <= 0;
            end
        end else begin
            accum_valid <= 0;
            accum_last <= 0;
        end
    end
end

assign dout = accum_reg[28:21]  == 0 ? 1 : accum_reg[28:21];
assign dout_tvalid = accum_valid;
assign dout_tlast = accum_last;

endmodule