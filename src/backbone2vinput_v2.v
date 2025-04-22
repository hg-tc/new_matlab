module backbone2vinput_v2 #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [64-1:0] backbone,
    input backbone_tvalid,

    input [J*A_WIDTH-1:0] x_initial,
    input x_initial_tvalid,

    input [J_WIDTH-1:0] ind_j,
    input ind_j_tvalid,

    input [J*A*64-1:0] alpha_u,
    input alpha_u_tvalid,
    
    output vinput_tvalid,
    output [63:0] vinput
);


wire [A_WIDTH-1:0] mutli_col_idx1,mutli_col_idx2;
wire [J_WIDTH-1:0] multi_row_idx1,multi_row_idx2;
wire [A_WIDTH-1:0] divi_col_idx1,divi_col_idx2;
wire [J_WIDTH-1:0] divi_row_idx1,divi_row_idx2;
wire index_out_tvalid;
wire [1:0] state_out;
multi_divi_index_gen_v2 #(
    .J(J),
    .I(I),
    .A(A)
) multi_divi_index_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .start_gen(backbone_tvalid),
    .J_index(ind_j),
    .mutli_col_idx1(mutli_col_idx1),
    .mutli_col_idx2(mutli_col_idx2),
    .multi_row_idx(multi_row_idx1),
    .multi_row_idx2(multi_row_idx2),
    .divi_col_idx1(divi_col_idx1),
    .divi_col_idx2(divi_col_idx2),
    .divi_row_idx(divi_row_idx1),
    .divi_row_idx2(divi_row_idx2),
    .index_out_tvalid(index_out_tvalid),
    .state_out(state_out)
);

wire [63:0] mutli_op1,mutli_op2,divi_op1,divi_op2;
assign mutli_op1 = alpha_u[(multi_row_idx1*A+mutli_col_idx1)*64 +: 64];
assign mutli_op2 = alpha_u[(multi_row_idx2*A+mutli_col_idx2)*64 +: 64];
assign divi_op1 = alpha_u[(divi_row_idx1*A+divi_col_idx1)*64 +: 64];
assign divi_op2 = alpha_u[(divi_row_idx2*A+divi_col_idx2)*64 +: 64];
assign multi_in_tvalid = index_out_tvalid;

// ---------------------------------------------------------------------------- //

wire multi_out_tvalid;
wire [63:0] multi_out;
multiply multiply_inst1(
    .aclk(clk),
    .s_axis_a_tvalid(multi_in_tvalid),
    .s_axis_a_tdata(state_out!=2'b01 ? mutli_op1 : 64'h3FF0000000000000),
    .s_axis_b_tvalid(multi_in_tvalid),
    .s_axis_b_tdata((state_out==2'b11) ? mutli_op2 : 64'h3FF0000000000000),
    .m_axis_result_tvalid(multi_out_tvalid),
    .m_axis_result_tdata(multi_out)
);

wire divi_out_tvalid;
wire [63:0] divi_out;
multiply multiply_inst2(
    .aclk(clk),
    .s_axis_a_tvalid(multi_in_tvalid),
    .s_axis_a_tdata(state_out!=2'b01 ? divi_op1 : 64'h3FF0000000000000),
    .s_axis_b_tvalid(multi_in_tvalid),
    .s_axis_b_tdata((state_out==2'b11) ? divi_op2 : 64'h3FF0000000000000),
    .m_axis_result_tvalid(divi_out_tvalid),
    .m_axis_result_tdata(divi_out)
);

// ---------------------------------------------------------------------------- //

reg [63:0] backbone_reg;
always @(posedge clk) begin
    if(!rst_n) begin
        backbone_reg <= 0;
    end
    else if(backbone_tvalid) begin 
        backbone_reg <= backbone;
    end
end

wire backbone_multied_tvalid;
wire [63:0] backbone_multied;
multiply multiply_main(
    .aclk(clk),
    .s_axis_a_tvalid(multi_out_tvalid),
    .s_axis_a_tdata(multi_out),
    .s_axis_b_tvalid(multi_out_tvalid),
    .s_axis_b_tdata(backbone_reg),
    .m_axis_result_tvalid(backbone_multied_tvalid),
    .m_axis_result_tdata(backbone_multied)
);

wire divi_out_delayed_tvalid;
wire [63:0] divi_out_delayed;
easy_fifo #(
    .DATAWIDTH(64),
    .SIZE(64),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_backbone (
    .clk(clk),
    .rst_n(rst_n),
    .din(divi_out),
    .din_valid(divi_out_tvalid),
    .request(backbone_multied_tvalid),
    .dout(divi_out_delayed),
    .out_valid(divi_out_delayed_tvalid),
    .empty()
);

divide divide_main(
    .aclk(clk),
    .s_axis_a_tvalid(backbone_multied_tvalid),
    .s_axis_a_tdata(backbone_multied),
    .s_axis_b_tvalid(divi_out_delayed_tvalid),
    .s_axis_b_tdata(divi_out_delayed),
    .m_axis_result_tvalid(vinput_tvalid),
    .m_axis_result_tdata(vinput)
);
endmodule