module top_fix_case2_badflow_wrapper #(
    parameter J = 14,
    parameter I = 7,
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
reg [J*8-1:0] alpha_u_col;
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
                            8'h74, 8'hCE, 8'hB3, 8'hE7, 8'hBF, 8'hCE, 8'h16,
                            8'h1B, 8'h51, 8'h05, 8'h33, 8'hF9, 8'hA6, 8'hFF
                        };
                    end
                endcase
                h_row_cnt <= h_row_cnt + 1;
            end

            ALPHA_SEND: begin
                if(alpha_cnt == 0) begin
                    alpha_cnt <= 1;
                    alpha_u_col <= {
                        8'h8B, 8'h32, 8'h4D, 8'h19, 8'h41, 8'h32, 8'hE9,
                        8'hE5, 8'hAE, 8'hFB, 8'hCD, 8'h06, 8'h5A, 8'h01
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
top_fix_case2_badflow #(
    .J(J),
    .I(I),
    .A(A)
) top_fix_case2_badflow_inst (
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
