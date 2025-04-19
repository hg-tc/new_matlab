module top #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2
)(
    input clk,
    input rst_n,
    input [J*64-1:0] H_row,
    input H_row_tvalid,
    input [J*64-1:0] y,
    input y_tvalid,
    input [J*64-1:0] alpha_u_col,
    input alpha_u_col_tvalid,
    input alpha_u_col_tlast
);

// M initialization
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



wire [J*AWIDTH-1:0] candidate_row;
wire candidate_row_tvalid;
wire candidate_row_tlast;
candidategen candidategen(
    .clk(clk),
    .rst_n(rst_n),
    .x_initial(x_initial),
    .x_initial_tvalid(x_initial_tvalid),
    .start_gen(start_gen),
    .J_index(J_index),
    .candidate_row(candidate_row),
    .candidate_row_tvalid(candidate_row_tvalid),
    .candidate_row_tlast(candidate_row_tlast)
);

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

