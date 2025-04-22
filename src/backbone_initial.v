module backbone_initial #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [J*A*64-1:0] alpha_u,
    input [J*A_WIDTH-1:0] x_initial,
    input [J_WIDTH-1:0] ind_j,
    input din_tvalid,
    
    output backbone_initial_tvalid,
    output [63:0] backbone_initial
);



wire [(J-1)*64-1:0] multi_tree_din;
wire [(J-1)-1:0] multi_tree_din_tvalid;
wire [63:0] multi_tree_dout;
wire multi_tree_dout_tvalid;

wire [63:0] multi_tree_din_element [J-1-1:0];//debug

genvar i;
generate
    for(i=0; i<J-1; i=i+1) begin : multi_tree_input_gen
        assign multi_tree_din[i*64 +: 64] = (i < ind_j-1) ? alpha_u[i*A*64 + x_initial[i*A_WIDTH +: A_WIDTH]*64 +: 64] : 
            alpha_u[(i+1)*A*64 + x_initial[(i+1)*A_WIDTH +: A_WIDTH]*64 +: 64];
        assign multi_tree_din_tvalid[i] = din_tvalid;
        assign multi_tree_din_element[i] = multi_tree_din[i*64 +: 64];
    end
endgenerate

multi_tree #(
    .NUM(J-1),
    .DATA_WIDTH(64)
) multi_tree_inst(
    .clk(clk),
    .rst_n(rst_n),
    .din(multi_tree_din),
    .din_tvalid(multi_tree_din_tvalid),
    .dout(multi_tree_dout), 
    .dout_tvalid(multi_tree_dout_tvalid)
);

assign backbone_initial = multi_tree_dout;
assign backbone_initial_tvalid = multi_tree_dout_tvalid;    


endmodule