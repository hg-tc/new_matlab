module alpha2xinitial_fix #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    parameter DATAWIDTH = 16,
    localparam AWIDTH = $clog2(A)+1
)(
    input clk,
    input [J*DATAWIDTH-1:0] alpha_u_col,
    input alpha_u_col_tvalid,
    input alpha_u_col_tlast,
    output [J*AWIDTH-1:0] x_initial,
    output x_initial_tvalid
);

wire [AWIDTH-1:0] x_value [J-1:0];
wire x_value_tvalid [J-1:0];
genvar j;
generate
    for (j = 0; j < J; j = j + 1) begin : alpha_compare_loop
        flow_max_index_fix #(.AWIDTH(AWIDTH),.DATAWIDTH(DATAWIDTH)) flow_max_index_fix(
            .clk(clk),
            .din(alpha_u_col[j*DATAWIDTH+:DATAWIDTH]),
            .din_tvalid(alpha_u_col_tvalid),
            .din_tlast(alpha_u_col_tlast),
            .dout(x_value[j]),
            .dout_tvalid(x_value_tvalid[j])
        );
        
    end
endgenerate

generate
    for (j = 0; j < J; j = j + 1) begin : xinitial_loop
        assign x_initial[j*AWIDTH+:AWIDTH] = x_value[j];
    end
endgenerate

assign x_initial_tvalid = x_value_tvalid[0];


endmodule
