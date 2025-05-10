module backbone2vinput_fix #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [32-1:0] backbone,
    input backbone_tvalid,
    input first_backbone,

    input [J*A_WIDTH-1:0] x_initial,
    input x_initial_tvalid,

    // input [J_WIDTH-1:0] ind_j,
    // input ind_j_tvalid,

    input [J*A*8-1:0] alpha_u,
    input alpha_u_tvalid,
    
    output vinput_tvalid,
    output [31:0] vinput
);

wire [1:0] state_out;
wire backbone_now_empty;
wire backbone_now_tvalid;
wire multi_in_tvalid;
wire index_out_tvalid;
wire index_out_tlast;
reg new_backbone;
reg [2:0]pre_new_backbone;
reg pre_start_gen;
always @(posedge clk) begin
    if(!rst_n) begin
        new_backbone <= 0;
        pre_new_backbone <= 0;
        pre_start_gen <= 0;
    end else if(pre_new_backbone==1) begin
        new_backbone <= 1;
        pre_new_backbone <= 0;
        pre_start_gen <= 0;
    end else if(pre_new_backbone!=0) begin
        pre_new_backbone <= pre_new_backbone - 1;
        new_backbone <= 0;
        pre_start_gen <= 0;
    end else if(index_out_tlast && state_out==2'b00 && !backbone_now_empty) begin
        new_backbone <= 0;
        pre_new_backbone <= 4;
        pre_start_gen <= 1;
    end else begin
        new_backbone <= 0;
        pre_new_backbone <= 0;
        pre_start_gen <= 0;
    end
end
wire [31:0] backbone_now;
easy_fifo #(
    .DATAWIDTH(32),
    .SIZE(J+1),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_backbone (
    .clk(clk),
    .rst_n(rst_n),
    .din(backbone),
    .din_valid(backbone_tvalid && !first_backbone),
    .request(new_backbone),
    .dout(backbone_now),
    .out_valid(backbone_now_tvalid),
    .empty(backbone_now_empty)
);


reg [J_WIDTH-1:0] ind_j;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ind_j <= 0;
    end
    else if (new_backbone || first_backbone) begin
        ind_j <= ind_j + 1;
    end
    else begin
        ind_j <= ind_j;
    end
end

wire [A_WIDTH-1:0] mutli_col_idx1,mutli_col_idx2;
wire [J_WIDTH-1:0] multi_row_idx1,multi_row_idx2;
wire [A_WIDTH-1:0] divi_col_idx1,divi_col_idx2;
wire [J_WIDTH-1:0] divi_row_idx1,divi_row_idx2;


multi_divi_index_gen_v2 #(
    .J(J),
    .I(I),
    .A(A)
) multi_divi_index_gen_inst (
    .clk(clk),
    .rst_n(rst_n),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .start_gen(pre_start_gen || first_backbone),
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
    .index_out_tlast(index_out_tlast),
    .state_out(state_out)
);

wire [7:0] mutli_op1,mutli_op2,divi_op1,divi_op2;
assign mutli_op1 = alpha_u[(multi_row_idx1*A+mutli_col_idx1)*8 +: 8];
assign mutli_op2 = alpha_u[(multi_row_idx2*A+mutli_col_idx2)*8 +: 8];
assign divi_op1 = alpha_u[(divi_row_idx1*A+divi_col_idx1)*8 +: 8];
assign divi_op2 = alpha_u[(divi_row_idx2*A+divi_col_idx2)*8 +: 8];
assign multi_in_tvalid = index_out_tvalid;

// ---------------------------------------------------------------------------- //

wire multi_out_tvalid;
wire [31:0] multi_out;
multiply_fix #(
    .DATAWIDTH_IN(8),
    .DATAWIDTH_OUT(32),
    .INVERSE(1),
    .OUTADDR(12)
) multiply_inst1(
    .aclk(clk),
    .s_axis_a_tvalid(multi_in_tvalid),
    .s_axis_a_tdata(state_out!=2'b01 ? mutli_op1 : 8'b00010000),
    .s_axis_b_tvalid(multi_in_tvalid),
    .s_axis_b_tdata((state_out==2'b11) ? mutli_op2 : 8'b00010000),
    .m_axis_result_tvalid(multi_out_tvalid),
    .m_axis_result_tdata(multi_out)
);

wire divi_out_tvalid;
wire [31:0] divi_out;
multiply_fix #(
    .DATAWIDTH_IN(8),
    .DATAWIDTH_OUT(32),
    .INVERSE(1),
    .OUTADDR(12)
) multiply_inst2(
    .aclk(clk),
    .s_axis_a_tvalid(multi_in_tvalid),
    .s_axis_a_tdata(state_out!=2'b01 ? divi_op1 : 8'b00010000),
    .s_axis_b_tvalid(multi_in_tvalid),
    .s_axis_b_tdata((state_out==2'b11) ? divi_op2 : 8'b00010000),
    .m_axis_result_tvalid(divi_out_tvalid),
    .m_axis_result_tdata(divi_out)
);

// ---------------------------------------------------------------------------- //

reg [31:0] backbone_reg;
always @(posedge clk) begin
    if(!rst_n) begin
        backbone_reg <= 0;
    end
    else if(backbone_now_tvalid) begin 
        backbone_reg <= backbone_now;
    end else if(first_backbone) begin
        backbone_reg <= backbone;
    end
end

wire backbone_multied_tvalid;
wire [31:0] backbone_multied;
multiply_fix #(
    .DATAWIDTH_IN(32),
    .DATAWIDTH_OUT(32),
    .INVERSE(0),
    .OUTADDR(28)
) multiply_main(
    .aclk(clk),
    .s_axis_a_tvalid(multi_out_tvalid),
    .s_axis_a_tdata(multi_out),
    .s_axis_b_tvalid(multi_out_tvalid),
    .s_axis_b_tdata(backbone_reg),
    .m_axis_result_tvalid(backbone_multied_tvalid),
    .m_axis_result_tdata(backbone_multied)
);

wire divi_out_delayed_tvalid;
wire [31:0] divi_out_delayed;
easy_fifo #(
    .DATAWIDTH(32),
    .SIZE(32),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_divi (
    .clk(clk),
    .rst_n(rst_n),
    .din(divi_out),
    .din_valid(divi_out_tvalid),
    .request(backbone_multied_tvalid),
    .dout(divi_out_delayed),
    .out_valid(divi_out_delayed_tvalid),
    .empty()
);

divide_fix_wrapper divide_main(
    .aclk(clk),
    .s_axis_a_tvalid(backbone_multied_tvalid),
    .s_axis_a_tdata(backbone_multied),
    .s_axis_b_tvalid(divi_out_delayed_tvalid),
    .s_axis_b_tdata(divi_out_delayed),
    .m_axis_result_tvalid(vinput_tvalid),
    .m_axis_result_tdata(vinput)
);
endmodule