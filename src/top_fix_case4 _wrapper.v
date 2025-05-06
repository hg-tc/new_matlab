module top_fix_case4_wrapper #(
    parameter J = 4,
    parameter I = 7,
    parameter A = 4,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1,
    localparam I_WIDTH = $clog2(I)+1
)(
    input clk,
    input rst_n,
    input start
);

// 内部信号定义
reg [J*64-1:0] H_row;
reg [128-1:0] y;
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
reg [1:0] alpha_cnt;

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
                    // H_row[0] = 0.9961, H_row[1] = 0.9962, H_row[2] = 0.6487, H_row[3] = -1.9791
                    H_row <= {64'hBFFE54E978512DEF, 64'h3FE4BF0A4395F979, 64'h3FEF6A0B2F3143F7, 64'h3FEF5F1F6D3F4D6D};
                    y <= {64'hBFE21B141554CC6F, 64'hC0042CAFE382D2CB};
                end
            end
            
        
            H_ROW_SEND: begin
                case(h_row_cnt)
                    // H_row[0] = -0.2654, H_row[1] = -1.1907, H_row[2] = -0.1708, H_row[3] = 0.4397
                    0: begin
                        H_row <= {64'h3FDC1D89D707C59B, 64'hBFC5115ED0A3D70A, 64'hBFF30F40474E6DEF, 64'hBFD0FD5F79F8D833};
                        y <= {64'hBFE317DDCF6D579A, 64'h3FF379058737F844};
                    end
                    // H_row[0] = -0.5449, H_row[1] = -0.4399, H_row[2] = 0.8123, H_row[3] = 0.4987
                    1: begin
                        H_row <= {64'h3FDFC9131ABF0B7D, 64'h3FE9F5C28F5C28F6, 64'hBFDC0A425ED17F0C, 64'hBFE18C5C37E9B7AE};
                        y <= {64'h4000D420EC64DB14, 64'hBFDD5A50254EF3FD};
                    end
                    // H_row[0] = -0.0965, H_row[1] = 1.3721, H_row[2] = 0.4073, H_row[3] = 0.6797
                    2: begin
                        H_row <= {64'h3FE5E9E4C12F8BC7, 64'h3FDA1740C3F6DEF9, 64'h3FF5DD3C0C1F67AF, 64'hBFB8A563AE853E19};
                        y <= {64'h3FE21B141554CC6F, 64'hC0042CAFE382D2CB};
                    end
                    // H_row[0] = -1.3858, H_row[1] = -0.8397, H_row[2] = -1.2901, H_row[3] = -0.3996
                    3: begin
                        H_row <= {64'hBFD95810624DD2F2, 64'hBFF4A3D70A3D70A4, 64'hBFEBE9E4C12F8BC7, 64'hBFF6274A1DAC6777};
                        y <= {64'hBFFB2DB0BB2BC3B4, 64'h40038A0CFABB192A};
                    end
                    // H_row[0] = -0.7183, H_row[1] = 0.0892, H_row[2] = 0.9651, H_row[3] = 0.0497
                    4: begin
                        H_row <= {64'h3FA91687A26C3207, 64'h3FEED916872B020C, 64'h3FB6E978D4FDF3B6, 64'hBFE74BC6A7EF9DB2};
                        y <= {64'h3FF57222CB9D877A, 64'hBFE815F9F9DFEBBA};
                    end
                    // H_row[0] = 1.9558, H_row[1] = 0.2468, H_row[2] = 0.6487, H_row[3] = -0.3714
                    5: begin
                        H_row <= {64'hBFD7CF3A1DC4673F, 64'h3FE4E147AE147AE1, 64'h3FCF9DB22D0E5604, 64'h3FFE2F112DF281DD};
                        y <= {64'hBFFBBFCEF1883FA6, 64'hC004B736E000F043};
                        H_row_tlast <= 1;
                    end
                    // H_row[0] = -2.0557, H_row[1] = 0.4123, H_row[2] = -0.4124, H_row[3] = 0.2558
                    6: begin
                        H_row <= {64'h3FD0718346A7EF9E, 64'hBFDA4DD2F1A9FBE8, 64'h3FD9FBE76C8B4396, 64'hC0037AE147AE147B};
                        y <= {64'h3FF80ADBAC00BEA0, 64'h400AE682B28C422A};
                        H_row_tvalid <= 0;
                        H_row_tlast <= 0;
                        state <= ALPHA_SEND;
                        alpha_u_col_tvalid <= 1;
                        // alpha[j=0] = [0.5534, 0.0043, 0.0056, 1.56e-12]
                        alpha_u_col <= {
                            8'h8D, 8'h01, 8'h01, 8'h00
                        };
                    end
                endcase
                h_row_cnt <= h_row_cnt + 1;
            end

            ALPHA_SEND: begin
                case(alpha_cnt)
                    2'b00: begin
                        // alpha[j=1] = [0.4369, 0.9915, 0.9738, 1.56e-5]
                        alpha_u_col <= {
                            8'h6F, 8'hF9, 8'hFD, 8'h00
                        };
                        alpha_cnt <= alpha_cnt + 1;
                    end
                    2'b01: begin
                        // alpha[j=2] = [0.0043, 0.0041, 0.0205, 0.9999]
                        alpha_u_col <= {
                            8'h01, 8'h05, 8'h01, 8'hFF
                        };
                        alpha_cnt <= alpha_cnt + 1;
                    end
                    2'b10: begin
                        // alpha[j=3] = [0.0054, 1.79e-5, 0.0001, 1.00e-7]
                        alpha_u_col <= {
                            8'h00, 8'h00, 8'h00, 8'h01
                        };
                        alpha_u_col_tlast <= 1;
                        alpha_cnt <= alpha_cnt + 1;
                    end
                    2'b11: begin
                        alpha_u_col_tvalid <= 0;
                        alpha_u_col_tlast <= 0;
                        state <= DONE;
                    end
                endcase
            end

            DONE: begin
                state <= IDLE;
            end
        endcase
    end
end

// 实例化内层模块
top_fix_case4 #(
    .J(J),
    .I(I),
    .A(A)
) top_fix_case4_inst (
    .clk(clk),
    .rst_n(rst_n),
    .H_row(H_row),
    .H_row_tvalid(H_row_tvalid),
    .H_row_tlast(H_row_tlast),
    .y(y),
    .alpha_u_col(alpha_u_col),
    .alpha_u_col_tvalid(alpha_u_col_tvalid),
    .alpha_u_col_tlast(alpha_u_col_tlast)
);

endmodule
