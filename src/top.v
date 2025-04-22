module top #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1,
    localparam I_WIDTH = $clog2(I)+1
)(
    input clk,
    input rst_n,
    input [J*64-1:0] H_row,
    input H_row_tvalid,
    input [J*64-1:0] y,
    input y_tvalid,

    input [64-1:0] sigma,
    input sigma_tvalid,

    input [J*64-1:0] alpha_u_col,
    input alpha_u_col_tvalid,
    input alpha_u_col_tlast
);

// -------------------------------------------------- initial set generate x_initial and sigma_reg --------------------------------------------------
localparam number = J * (J - 1) / 2 + 1;
localparam AWIDTH = $clog2(A)+1;

reg [A * number * 64 - 1:0] M [I * J - 1 : 0];

wire [J*AWIDTH-1:0] x_initial;
wire x_initial_tvalid;
alpha2xinitial #(.J(J), .I(I), .A(A)) alpha2xinitial(
    .clk(clk),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid)
);
reg [63:0] sigma_reg;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sigma_reg <= 0;
    end
    else begin
        if (sigma_tvalid) begin
            sigma_reg <= sigma;
        end
    end
end

// -------------------------------------------------- M generation --------------------------------------------------
reg [I_WIDTH-1:0] I_idx;
reg [J_WIDTH-1:0] J_idx;
reg [A_WIDTH-1:0] A_value;
reg start_gen;


wire [J*AWIDTH-1:0] candidate_row;
wire candidate_row_tvalid;
wire candidate_row_tlast;


reg [1:0] state;
localparam IDLE = 2'b00;
localparam GEN = 2'b01;
localparam DONE = 2'b10;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        I_idx <= 0;
        J_idx <= 0;
        A_value <= 0;
        start_gen <= 0;
    end
    else begin
        case (state)
            IDLE: begin
                if (x_initial_tvalid) begin
                    state <= GEN;
                    start_gen <= 1;
                end
            end
            GEN: begin
                if (candidate_row_tlast && candidate_row_tvalid && A_value < A-1) begin
                    A_value <= A_value + 1;
                    start_gen <= 1;
                end
                else if (candidate_row_tlast && candidate_row_tvalid && A_value == A-1) begin
                    A_value <= 0;
                    start_gen <= 0;
                    state <= IDLE;
                end
                else begin
                    start_gen <= 0;
                end
            end

            default: begin
                state <= IDLE;
            end
        endcase
    end
end


candidategen_setA #(.J(J), .I(I), .A(A)) candidategen_setA(
    .clk(clk),
    .rst_n(rst_n),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .start_gen(start_gen),
    .J_index(J_idx),
    .A_value(A_value),
    .candidate_row(candidate_row),
    .candidate_row_tvalid(candidate_row_tvalid),
    .candidate_row_tlast(candidate_row_tlast)
);

// -------------------------------------------------- F generation --------------------------------------------------
// J parallel F generation
wire [63:0] F_value;
wire F_value_tvalid;

reg [J_WIDTH-1:0] J_cnt;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        J_cnt <= 0;
    end
    else begin
        if (candidate_row_tvalid) begin
            if (J_cnt < J-1) begin
                J_cnt <= J_cnt + 1;
            end
            else begin
                J_cnt <= 0;
            end
        end
    end
end

wire [63:0] F_value_J [J-1:0];
wire [J-1:0] F_value_tvalid_J;

genvar j;
generate
    for (j = 0; j < J; j = j + 1) begin : F_case
        F_case2 #(.J(J), .I(I), .A(A)) F_case2(
            .clk(clk),
            .rst_n(rst_n),
            .H(H_row),
            .H_tvalid(H_row_tvalid),
            .x(candidate_row),
            .x_tvalid((j==J_cnt) ? candidate_row_tvalid : 0),
            .F_value(F_value_J[j]),
            .F_value_tvalid(F_value_tvalid_J[j])
        );
    end
endgenerate
reg [J_WIDTH-1:0] J_cnt2;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        J_cnt2 <= 0;
    end
    else begin
        if (F_value_tvalid_J) begin
            if (J_cnt2 < J-1) begin
                J_cnt2 <= J_cnt2 + 1;
            end
            else begin
                J_cnt2 <= 0;
            end
        end
    end
end
assign F_value = F_value_J[J_cnt2];
assign F_value_tvalid = F_value_tvalid_J[J_cnt2];

// -------------------------------------------------- backbone initialization --------------------------------------------------
reg [A_WIDTH-1:0] alpha_cnt;
reg [J*A*64-1:0] alpha_u_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alpha_u_reg <= 0;
        alpha_cnt <= 0;
    end
    else begin
        if (alpha_u_col_tvalid) begin
            for (integer i = 0; i < J; i = i + 1) begin
                alpha_u_reg[i*A*64 + alpha_cnt*64 +: 64] <= alpha_u_col[i*64 +: 64];
            end
            alpha_cnt <= alpha_cnt + 1;
        end
    end
end


wire [63:0] vinput_0;
wire vinput_0_tvalid;
backbone_initial #(.J(J), .I(I), .A(A)) backbone_initial(
    .clk(clk),
    .rst_n(rst_n),
    .alpha_u(alpha_u_reg),
    .x_initial(x_initial),
    .ind_j(J_idx),
    .din_tvalid(x_initial_tvalid),
    .backbone_initial(vinput_0),
    .backbone_initial_tvalid(vinput_0_tvalid)
);  

wire [63:0] vinput_other;
wire vinput_other_tvalid;
backbone2vinput_v2 #(.J(J), .I(I), .A(A)) backbone2vinput(
    .clk(clk),
    .rst_n(rst_n),
    .backbone(vinput_0),
    .backbone_tvalid(vinput_0_tvalid),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .ind_j(J_idx),
    .ind_j_tvalid(J_idx_tvalid),
    .alpha_u(alpha_u_reg),
    .alpha_u_tvalid(x_initial_tvalid),
    .vinput(vinput_other),
    .vinput_tvalid(vinput_other_tvalid)
);  

// -------------------------------------------------- MAC --------------------------------------------------

wire F_value_tlast;
easy_fifo #(
    .DATAWIDTH(1),
    .SIZE(512),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_Ftlast (
    .clk(clk),
    .rst_n(rst_n),
    .din(candidate_row_tlast),
    .din_valid(candidate_row_tvalid),
    .request(F_value_tvalid),
    .dout(F_value_tlast),
    .out_valid(),
    .empty(),
    .full(),
    .almost_full()
);



reg [A_WIDTH-1:0] A_cnt;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        A_cnt <= 0;
    end
    else begin
        if (F_value_tlast) begin
            if (A_cnt < A-1) begin
                A_cnt <= A_cnt + 1;
            end
            else begin
                A_cnt <= 0;
            end
        end
    end
end
wire vinput_ready, M_row_ready;
wire vinput_empty;
wire [64-1:0] vinput;
wire vinput_tvalid;
easy_fifo #(
    .DATAWIDTH(64),
    .SIZE(512),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_vinput (
    .clk(clk),
    .rst_n(rst_n),
    .din(vinput_other),
    .din_valid(vinput_other_tvalid),
    .request(vinput_ready & M_row_ready),
    .dout(vinput),
    .out_valid(vinput_tvalid),
    .empty(vinput_empty),
    .full(),
    .almost_full()
);
assign vinput_ready = ~vinput_empty;

wire [63:0] M_row_single [A-1:0];
wire [A-1:0] M_row_single_tvalid;
wire [64*A-1:0] M_row;
wire M_row_tvalid;
wire [A-1:0] M_row_empty;
genvar a;
generate
    for (a = 0; a < A; a = a + 1) begin : MAC_case
        easy_fifo #(
            .DATAWIDTH(64),
            .SIZE(512),
            .IN_SIZE(1),
            .OUT_SIZE(1)
        ) fifo_M_row (
            .clk(clk),
            .rst_n(rst_n),
            .din(F_value),
            .din_valid(F_value_tvalid & (a==A_cnt)),
            .request(vinput_ready & M_row_ready),
            .dout(M_row_single[a]),
            .out_valid(M_row_single_tvalid[a]),
            .empty(M_row_empty[a]),
            .full(),
            .almost_full()
        );
        assign M_row[a*64 +: 64] = M_row_single[a];

    end
    assign M_row_ready = M_row_empty == 0;
    assign M_row_tvalid = M_row_single_tvalid[0];
    
endgenerate

wire MAC_tlast;
easy_fifo #(
    .DATAWIDTH(1),
    .SIZE(512),
    .IN_SIZE(1),
    .OUT_SIZE(1)
) fifo_MACtlast (
    .clk(clk),
    .rst_n(rst_n),
    .din(F_value_tlast),
    .din_valid(F_value_tvalid & (A_cnt == 0)),
    .request(vinput_ready & M_row_ready),
    .dout(MAC_tlast),
    .out_valid(),
    .empty(),
    .full(),
    .almost_full()
);

wire beta_tvalid;
wire [64-1:0] beta;
MAC #(.J(J), .I(I), .A(A)) MAC(
    .clk(clk),
    .rst_n(rst_n),
    .vinput(vinput),
    .vinput_tvalid(vinput_tvalid),
    .vinput_tlast(MAC_tlast),
    .M_row(M_row),
    .M_row_tvalid(M_row_tvalid),
    .M_row_tlast(MAC_tlast),
    .beta_tvalid(beta_tvalid),
    .beta(beta)
);
endmodule

