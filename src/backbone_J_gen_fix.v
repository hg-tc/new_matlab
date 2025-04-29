module backbone_J_gen_fix #(
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

    input [J*A_WIDTH-1:0] x_initial,
    input x_initial_tvalid,

    input [J*A*8-1:0] alpha_u,
    input alpha_u_tvalid,
    
    output backbone_J_tvalid,
    output [31:0] backbone_J
);

reg [J_WIDTH-1:0] J_index_reg;
reg index_tvalid;
reg [1:0] state;
localparam IDLE = 2'b00;
localparam COUNT = 2'b01;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        J_index_reg <= 0;
        index_tvalid <= 0;
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                if(backbone_tvalid) begin
                    state <= COUNT;
                    J_index_reg <= 0;
                    index_tvalid <= 1;
                end
            end
            COUNT: begin
                if(J_index_reg < J-2) begin
                    J_index_reg <= J_index_reg + 1;
                    index_tvalid <= 1;
                end
                else begin
                    state <= IDLE;
                    index_tvalid <= 0;
                end
            end
            default: state <= IDLE;
        endcase
    end
end

wire [31:0] multi_index;
assign multi_index = J_index_reg*A + x_initial[J_index_reg*A_WIDTH +: A_WIDTH];

wire [31:0] divi_index;
assign divi_index = (J_index_reg+1)*A + x_initial[(J_index_reg+1)*A_WIDTH +: A_WIDTH];

// assign mutli_op1 = alpha_u[(multi_row_idx1*A+mutli_col_idx1)*8 +: 8];
// assign mutli_op2 = alpha_u[(multi_row_idx2*A+mutli_col_idx2)*8 +: 8];
// assign divi_op1 = alpha_u[(divi_row_idx1*A+divi_col_idx1)*8 +: 8];
// assign divi_op2 = alpha_u[(divi_row_idx2*A+divi_col_idx2)*8 +: 8];


reg [7:0] multi_op;
reg [7:0] divi_op;
reg multi_in_tvalid;
always @(posedge clk) begin
    if(index_tvalid) begin
        multi_op <= alpha_u[multi_index*8 +: 8];
        divi_op <= alpha_u[divi_index*8 +: 8];
        multi_in_tvalid <= 1;
    end else begin
        multi_in_tvalid <= 0;
        multi_op <= 0;
        divi_op <= 0;
    end
end



reg [31:0] backbone_reg;
always @(posedge clk) begin
    if(!rst_n) begin
        backbone_reg <= 0;
    end
    else if(backbone_tvalid) begin 
        backbone_reg <= backbone;
    end
end

wire backbone_multied_tvalid;
wire [31:0] backbone_multied;
multiply_fix_v2 #(
    .DATAWIDTH_IN_A(8),
    .DATAWIDTH_IN_B(32),
    .DATAWIDTH_OUT(32),
    .INVERSE(0),
    .OUTADDR(8)
) multiply_main(
    .aclk(clk),
    .s_axis_a_tvalid(multi_in_tvalid),
    .s_axis_a_tdata(multi_op),
    .s_axis_b_tvalid(multi_in_tvalid),
    .s_axis_b_tdata(backbone_reg),
    .m_axis_result_tvalid(backbone_multied_tvalid),
    .m_axis_result_tdata(backbone_multied)
);

wire divi_out_delayed_tvalid;
wire [7:0] divi_out_delayed;
easy_fifo #(
    .DATAWIDTH(8),
    .SIZE(32),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_backbone (
    .clk(clk),
    .rst_n(rst_n),
    .din(divi_op),
    .din_valid(multi_in_tvalid),
    .request(backbone_multied_tvalid),
    .dout(divi_out_delayed),
    .out_valid(divi_out_delayed_tvalid),
    .empty()
);

divide_fix_wrapper_32_8 divide_main(
    .aclk(clk),
    .s_axis_a_tvalid(backbone_multied_tvalid),
    .s_axis_a_tdata(backbone_multied),
    .s_axis_b_tvalid(divi_out_delayed_tvalid),
    .s_axis_b_tdata(divi_out_delayed),
    .m_axis_result_tvalid(backbone_J_tvalid),
    .m_axis_result_tdata(backbone_J)
);
endmodule