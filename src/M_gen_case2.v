module M_gen_case2 #(
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
F_case2 #(.J(J), .I(I), .A(A)) F_case2(
    .clk(clk),
    .rst_n(rst_n),
    .H(H_row),
    .H_tvalid(H_row_tvalid),
    .x(candidate_row),
    .x_tvalid(candidate_row_tvalid),
    .F_value(F_value),
    .F_value_tvalid(F_value_tvalid)
);
endmodule

