module top_double_case2_wrapper #(
    parameter J = 14,
    parameter I = 2,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1,
    localparam I_WIDTH = $clog2(I)+1
)(
    input clk,
    input rst_n,
    input start
);

// 内部信号定义
reg [J-1:0] H_row;
reg H_row_tvalid;
reg H_row_tlast;
reg [J*64-1:0] alpha_u_col;
reg alpha_u_col_tvalid;
reg alpha_u_col_tlast;

// 状态机定义
reg [3:0] state;
localparam IDLE = 4'd0;
localparam H_ROW_SEND = 4'd1; 
localparam ALPHA_SEND = 4'd2;
localparam DONE = 4'd3;

reg [2:0] h_row_cnt;
reg alpha_cnt;

// 状态机
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        h_row_cnt <= 0;
        alpha_cnt <= 0;
        H_row <= 0;
        H_row_tvalid <= 0;
        H_row_tlast <= 0;
        alpha_u_col <= 0;
        alpha_u_col_tvalid <= 0;
        alpha_u_col_tlast <= 0;
    end else begin
        case(state)
            IDLE: begin
                if(start) begin
                    state <= H_ROW_SEND;
                    H_row_tvalid <= 1;
                    H_row <= 14'b01100010100011;
                end
            end
            
            H_ROW_SEND: begin
                case(h_row_cnt)
                    0: H_row <= 14'b00110101001010;
                    1: H_row <= 14'b01010011000101;
                    2: H_row <= 14'b10001100001011;
                    3: H_row <= 14'b10001010110100;
                    4: H_row <= 14'b10010100111000;
                    5: begin
                        H_row <= 14'b01101001010100;
                        H_row_tlast <= 1;
                    end
                    6: begin
                        H_row_tvalid <= 0;
                        H_row_tlast <= 0;
                        state <= ALPHA_SEND;
                        alpha_u_col_tvalid <= 1;
                        alpha_u_col <= {
                            64'h3FDD851EB851EB85, // 0.456
                            64'h3FE9EB851EB851EC, // 0.81
                            64'h3FE6666666666666, // 0.7
                            64'h3FED1EB851EB851F, // 0.91
                            64'h3FE3D70A3D70A3D7, // 0.62
                            64'h3FE9EB851EB851EC, // 0.81
                            64'h3FB47AE147AE147B, // 0.08
                            64'h3FB999999999999A, // 0.1
                            64'h3FE051EB851EB852, // 0.51
                            64'h3FA47AE147AE147B, // 0.04
                            64'h3FD47AE147AE147B, // 0.33
                            64'h3FEF5C28F5C28F5C, // 0.98
                            64'h3FE51EB851EB851F, // 0.66
                            64'h3FF0000000000000  // 1.0
                        };
                    end
                endcase
                h_row_cnt <= h_row_cnt + 1;
            end

            ALPHA_SEND: begin
                if(alpha_cnt == 0) begin
                    alpha_cnt <= 1;
                    alpha_u_col <= {
                        64'h3FE3D70A3D70A3D7, // 0.62
                        64'h3FD47AE147AE147B, // 0.33
                        64'h3FDF5C28F5C28F5C, // 0.49
                        64'h3FB999999999999A, // 0.1
                        64'h3FDD70A3D70A3D71, // 0.46
                        64'h3FD47AE147AE147B, // 0.33
                        64'h3FE7AE147AE147AE, // 0.74
                        64'h3FE7333333333333, // 0.73
                        64'h3FE5C28F5C28F5C3, // 0.68
                        64'h3FEF5C28F5C28F5C, // 0.98
                        64'h3FE9EB851EB851EC, // 0.81
                        64'h3FA47AE147AE147B, // 0.04
                        64'h3FE051EB851EB852, // 0.51
                        64'h3F847AE147AE147B  // 0.01
                    };
                    alpha_u_col_tlast <= 1;
                end else begin
                    alpha_u_col_tvalid <= 0;
                    alpha_u_col_tlast <= 0;
                    state <= DONE;
                end
            end

            DONE: begin
                state <= IDLE;
            end
        endcase
    end
end

// 实例化内层模块
top_double_case2 #(
    .J(J),
    .I(I),
    .A(A)
) top_double_case2_inst (
    .clk(clk),
    .rst_n(rst_n),
    .H_row(H_row),
    .H_row_tvalid(H_row_tvalid),
    .H_row_tlast(H_row_tlast),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast)
);

endmodule
