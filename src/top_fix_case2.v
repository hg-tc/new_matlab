module top_fix_case2 #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1,
    localparam I_WIDTH = $clog2(I)+1
)(
    input clk,
    input rst_n,
    input [J-1:0] H_row,
    input H_row_tvalid,
    input H_row_tlast,

    input [J*8-1:0] alpha_u_col,
    input alpha_u_col_tvalid,
    input alpha_u_col_tlast
);
// -------------------------------------------------- H_row --------------------------------------------------
reg [J-1:0] H_row_reg [I-1:0];
reg [I_WIDTH-1:0] H_load_cnt;

reg H_ready;
integer i;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_load_cnt <= 0;
        H_ready <= 0;
        for (i = 0; i < I; i = i + 1) begin
            H_row_reg[i] <= 0;
        end
    end
    else begin
        if (H_row_tvalid) begin
            if (H_load_cnt < I-1) begin
                H_load_cnt <= H_load_cnt + 1;
            end
            else begin
                H_load_cnt <= 0;
                H_ready <= 1;
            end
            H_row_reg[H_load_cnt] <= H_row;
        end
        else begin
            for (i = 0; i < I; i = i + 1) begin
                H_row_reg[i] <= H_row_reg[i];
            end
        end
    end
end

reg [A_WIDTH-1:0] alpha_cnt;
reg [J*A*8-1:0] alpha_initial_reg;

wire new_alpha_u_col_tlast;
wire new_alpha_u_col_tvalid;
wire [J*8-1:0] new_alpha_u_col [I-1:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alpha_initial_reg <= 0;
        alpha_cnt <= 0;
    end
    else begin
        if (alpha_u_col_tvalid) begin
            for (i = 0; i < J; i = i + 1) begin
                alpha_initial_reg[i*A*8 + alpha_cnt*8 +: 8] <= alpha_u_col[i*8 +: 8];
            end
            alpha_cnt <= alpha_cnt + 1;
        end
    end
end
wire [7:0] alpha_debug;
assign alpha_debug = alpha_u_col[7:0];

reg new_iteration;
wire [A*8-1:0] beta [I-1:0];
wire [I-1:0] beta_tvalid;
genvar gi;
generate
    for (gi = 0; gi < I; gi = gi + 1) begin : gen_cal_core
        cal_core_fix_case2 #(
            .J(J),
            .I(I),
            .A(A)
        ) cal_core_fix_case2 (
            .clk(clk),
            .rst_n(rst_n && !new_iteration),
            .H_row(H_row_reg[gi]),
            .H_row_tvalid(H_ready),
            .alpha_u_col(alpha_u_col | new_alpha_u_col[gi]),
            .alpha_u_col_tvalid(alpha_u_col_tvalid | new_alpha_u_col_tvalid),
            .alpha_u_col_tlast(alpha_u_col_tlast | new_alpha_u_col_tlast),
            .beta(beta[gi]),
            .beta_tvalid(beta_tvalid[gi])
        );
    end
endgenerate

wire [I*8-1:0] beta_merge [A-1 : 0];
genvar a, gi2;
generate
    for (a = 0; a < A; a = a + 1) begin : gen_beta_merge
        for (gi2 = 0; gi2 < I; gi2 = gi2 + 1) begin : gen_beta_merge_inner
            assign beta_merge[a][gi2*8 +: 8] = beta[gi2][a*8 +: 8];
        end
    end
endgenerate

reg [A*8-1:0] beta_reg [I-1:0];
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < I; i = i + 1) begin
            beta_reg[i] <= 0;
        end
    end
    else if (|beta_tvalid) begin
        for (i = 0; i < I; i = i + 1) begin
            beta_reg[i] <= beta[i];
        end
    end
end


reg [J_WIDTH-1:0] J_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n || new_iteration) begin
        J_cnt <= 0;
    end
    else if (alpha_temp_col2_tvalid[0]==1) begin
        J_cnt <= J_cnt + 1;
    end
end


wire [I-1:0] beta_merge_tvalid;
assign beta_merge_tvalid = beta_tvalid;

wire [32-1:0] alpha_temp_col [A-1 : 0];
wire alpha_temp_col_tvalid [A-1 : 0];
wire [40-1:0] alpha_temp_col2 [A-1 : 0];
wire alpha_temp_col2_tvalid [A-1 : 0];
wire [A*64-1:0] alpha_temp_col3 [I-1 : 0];
wire [A-1:0] alpha_temp_col3_tvalid [I-1 : 0];
genvar gi3, gi4;
generate
    for (a = 0; a < A; a = a + 1) begin : gen_new_alpha_u_col
        multi_tree_fix_v2 #(
            .NUM(I),
            .DATA_WIDTH(8)
        ) multi_tree_inst(
            .clk(clk),
            .rst_n(rst_n),
            .din(beta_merge[a]),
            .din_tvalid(beta_merge_tvalid),
            .dout(alpha_temp_col[a]), 
            .dout_tvalid(alpha_temp_col_tvalid[a])
        );

        multiply_fix_v2 #(
            .DATAWIDTH_IN_A(32),
            .DATAWIDTH_IN_B(8),
            .DATAWIDTH_OUT(40),
            .INVERSE(0),
            .OUTADDR(0)
        ) multiply_inst(
            .aclk(clk),
            .s_axis_a_tvalid(alpha_temp_col_tvalid[a]),
            .s_axis_a_tdata(alpha_temp_col[a]),
            .s_axis_b_tvalid(alpha_temp_col_tvalid[a]),
            .s_axis_b_tdata(alpha_initial_reg[(J_cnt*A+a)*8 +: 8]),
            .m_axis_result_tvalid(alpha_temp_col2_tvalid[a]),
            .m_axis_result_tdata(alpha_temp_col2[a])
        );
        for (gi3 = 0; gi3 < I; gi3 = gi3 + 1) begin : gen_alpha_new_2_col
            divide_fix_wrapper_40_8 divide_inst(
                .aclk(clk),
                .s_axis_a_tvalid(alpha_temp_col2_tvalid[a]),
                .s_axis_a_tdata(alpha_temp_col2[a]),
                .s_axis_b_tvalid(alpha_temp_col2_tvalid[a]),
                .s_axis_b_tdata(beta_reg[gi3][a*8 +: 8]),
                .m_axis_result_tvalid(alpha_temp_col3_tvalid[gi3][a]),
                .m_axis_result_tdata(alpha_temp_col3[gi3][a*64 +: 64])
            );
        end
    end
endgenerate
//debug
wire [64-1:0] alpha_temp_col3_debug[A-1:0];
genvar a_debug;
generate
    for (a_debug = 0; a_debug < A; a_debug = a_debug + 1) begin : gen_alpha_temp_col3_debug
        assign alpha_temp_col3_debug[a_debug] = alpha_temp_col3[0][a_debug*64 +: 64];
    end
endgenerate


wire [A*8-1:0] alpha_final [I-1 : 0];
wire [A-1:0] alpha_final_tvalid [I-1 : 0];
generate
    for (gi4 = 0; gi4 < I; gi4 = gi4 + 1) begin : gen_alpha_new_col
        wire [63:0] alpha_sum;
        wire alpha_sum_tvalid;

        adder_case2_fix  adder_inst(
            .clk(clk),
            .rst_n(rst_n),
            .din(alpha_temp_col3[gi4]),
            .din_tvalid(alpha_temp_col3_tvalid[gi4][0]),
            .dout(alpha_sum),
            .dout_tvalid(alpha_sum_tvalid)
        );
        wire [64 * A - 1 : 0] alpha_temp_col3_delay;
        signal_delay #(
            .DATAWIDTH(64 * A),
            .DELAY_CYCLE(1)
        ) signal_delay_inst(
            .clk(clk),
            .pre_signal(alpha_temp_col3[gi4]),
            .signal(alpha_temp_col3_delay)
        );

        
        for (a = 0; a < A; a = a + 1) begin : gen_alpha_new_col_inner
            wire pre_alpha_final_tvalid;
            wire [7:0] pre_alpha_final;
            divide_fix_wrapper_64_64 divider_inst(
                .aclk(clk),
                .s_axis_a_tvalid(alpha_sum_tvalid),
                .s_axis_a_tdata(alpha_temp_col3_delay[a*64 +: 64]),
                .s_axis_b_tvalid(alpha_sum_tvalid),
                .s_axis_b_tdata(alpha_sum),
                .m_axis_result_tvalid(pre_alpha_final_tvalid),
                .m_axis_result_tdata(pre_alpha_final)
            );
            assign alpha_final[gi4][a*8 +: 8] = pre_alpha_final != 0 ? pre_alpha_final : 8'b00000001;
            assign alpha_final_tvalid[gi4][a] = pre_alpha_final_tvalid;
        end
    end
endgenerate

reg [J*A*8-1:0] alpha_reg [I-1 : 0];
reg [J_WIDTH-1:0] alpha_J_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alpha_J_cnt <= 0;
        new_iteration <= 0;
        for (i = 0; i < I; i = i + 1) begin
            alpha_reg[i] <= 0;
        end
    end
    else if (alpha_final_tvalid[0][0] & alpha_J_cnt < J-1) begin
        for (i = 0; i < I; i = i + 1) begin
            alpha_reg[i][alpha_J_cnt*A*8 +: A*8] <= alpha_final[i];
        end
        alpha_J_cnt <= alpha_J_cnt + 1;
        new_iteration <= 0;
    end
    else if (alpha_final_tvalid[0][0] & alpha_J_cnt == J-1) begin
        alpha_J_cnt <= 0;
        new_iteration <= 1;
        for (i = 0; i < I; i = i + 1) begin
            alpha_reg[i] <= alpha_reg[i];
        end
    end else begin
        new_iteration <= 0;
    end
end

reg [A_WIDTH-1:0] alpha_A_cnt_inverse;
reg [A_WIDTH-1:0] alpha_A_cnt;
reg alpha_tvalid;
reg alpha_tlast;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alpha_A_cnt_inverse <= 0;
        alpha_A_cnt <= 0;
        alpha_tvalid <= 0;
        alpha_tlast <= 0;
    end
    else if (new_iteration) begin
        alpha_A_cnt_inverse <= A-1;
        alpha_A_cnt <= 0;
        alpha_tlast <= 0;
        alpha_tvalid <= 1;
    end
    else if (alpha_A_cnt_inverse > 1) begin
        alpha_A_cnt <= alpha_A_cnt + 1;
        alpha_A_cnt_inverse <= alpha_A_cnt_inverse - 1;
        alpha_tlast <= 0;
        alpha_tvalid <= 1;
    end 
    else if (alpha_A_cnt_inverse == 1) begin
        alpha_A_cnt <= alpha_A_cnt + 1;
        alpha_A_cnt_inverse <= 0;
        alpha_tlast <= 1;
        alpha_tvalid <= 1;
    end
    else begin
        alpha_A_cnt <= 0;
        alpha_A_cnt_inverse <= 0;
        alpha_tlast <= 0;
        alpha_tvalid <= 0;
    end
end

assign new_alpha_u_col_tlast = alpha_tlast;
assign new_alpha_u_col_tvalid = alpha_tvalid;


genvar gi5,gi6;
generate
    for (gi5 = 0; gi5 < J; gi5 = gi5 + 1) begin : gen_alpha_u_col
        for (gi6 = 0; gi6 < I; gi6 = gi6 + 1) begin : gen_alpha_u_col_inner
            assign new_alpha_u_col[gi6][gi5*8 +: 8] = alpha_reg[gi6][gi5*A*8+alpha_A_cnt*8 +: 8];
        end
    end
endgenerate


endmodule
