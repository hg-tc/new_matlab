module multi_divi_index_gen_v2 #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1,
    localparam J_WIDTH = $clog2(J)+1
)(
    input clk,
    input rst_n,
    input [J*AWIDTH-1:0] x_initial,
    input x_initial_tvalid,
    input start_gen,
    input [J_WIDTH-1:0] J_index,

    output [AWIDTH-1:0] mutli_col_idx1,
    output [AWIDTH-1:0] mutli_col_idx2,
    output [J_WIDTH-1:0] multi_row_idx,
    output [J_WIDTH-1:0] multi_row_idx2,
    output [AWIDTH-1:0] divi_col_idx1,
    output [AWIDTH-1:0] divi_col_idx2,
    output [J_WIDTH-1:0] divi_row_idx,
    output [J_WIDTH-1:0] divi_row_idx2,
    output reg [1:0] state_out,
    output index_out_tvalid,
    output index_out_tlast
);


reg [AWIDTH-1:0] mutli_col_idx1_reg;
reg [J_WIDTH-1:0] multi_row_idx_reg;
reg [AWIDTH-1:0] divi_col_idx1_reg;
reg [J_WIDTH-1:0] divi_row_idx_reg;

reg [J*AWIDTH-1:0] x_initial_reg;

always @(posedge clk) begin
    if (!rst_n) begin
        x_initial_reg <= 0;
    end
    else if (x_initial_tvalid) begin
        x_initial_reg <= x_initial;
    end
end

// 状态定义
localparam IDLE = 2'b00;
localparam GEN = 2'b01;
localparam GEN2 = 2'b10;
localparam DONE = 2'b11;

reg [1:0] state;
reg [AWIDTH-1:0] x_current [J-1:0]; // 改为二维数组
reg [$clog2(J):0] bit_cnt;
reg [$clog2(J):0] bit_cnt2;
reg [J_WIDTH-1:0] J_index_reg;
reg [AWIDTH-1:0] A_cnt;
reg [AWIDTH-1:0] A_cnt2;
// 输出寄存器
reg [J*64-1:0] candidate_row_reg;
reg candidate_row_tvalid_reg;

wire [AWIDTH-1:0] x_current_next [J-1:0];
wire [AWIDTH-1:0] x_initial_next [J-1:0];
wire [$clog2(J)-1:0] next_bit_cnt,next_bit_cnt2,prev_bit_cnt,prev_bit_cnt2,next_next_bit_cnt;
genvar i;
generate
    for(i=0; i<J; i=i+1) begin
        assign x_current_next[i] = (x_current[i] < A-1) ? x_current[i] + 1 : 0;
        assign x_initial_next[i] = (x_initial_reg[i*AWIDTH +: AWIDTH] < A-1) ? x_initial_reg[i*AWIDTH +: AWIDTH] + 1 : 0;
        assign next_bit_cnt = bit_cnt == J_index_reg-1 ? bit_cnt + 2 : bit_cnt + 1;
        assign next_next_bit_cnt = next_bit_cnt == J_index_reg-1 ? next_bit_cnt + 2 : next_bit_cnt + 1;
        assign next_bit_cnt2 = bit_cnt2 == J_index_reg-1 ? bit_cnt2 + 2 : bit_cnt2 + 1;
        assign prev_bit_cnt = bit_cnt == J_index_reg+1 ? bit_cnt - 2 : bit_cnt - 1;
        assign prev_bit_cnt2 = bit_cnt2 == J_index_reg+1 ? bit_cnt2 - 2 : bit_cnt2 - 1;
    end
endgenerate

wire [J_WIDTH-1:0] next_bit_cnt_end;
assign next_bit_cnt_end = (J_index_reg==0) ? 1 : 0;
wire [J_WIDTH-1:0] next_bit_cnt2_end;
assign next_bit_cnt2_end = (J_index_reg<=1) ? 2 : 1;


wire final_done;
assign final_done = (bit_cnt2 == J-1 || (J_index_reg == J-1 && bit_cnt2 == J-2) ) && (bit_cnt == J-2 || (J_index_reg >= J-2 && bit_cnt == J-3)) && A_cnt2 == A-2 && A_cnt == A-2;
// 状态机
always @(posedge clk) begin
    if (!rst_n) begin
        state <= IDLE;
        for(integer i=0; i<J; i=i+1) begin
            x_current[i] <= 0;
        end
        bit_cnt <= 0;
        bit_cnt2 <= 0;
        candidate_row_reg <= 0;
        candidate_row_tvalid_reg <= 0;
        J_index_reg <= 0;
        A_cnt <= 0;
        A_cnt2 <= 0;
        mutli_col_idx1_reg <= 0;
        divi_col_idx1_reg <= 0;
        multi_row_idx_reg <= 0;
        divi_row_idx_reg <= 0;
        state_out <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (start_gen) begin
                    state <= GEN;
                    for(integer i=0; i<J; i=i+1) begin
                        x_current[i] <= x_initial_reg[i*AWIDTH +: AWIDTH];
                    end
                    bit_cnt <= (J_index==0) ? 1 : 0;
                    candidate_row_tvalid_reg <= 1;
                    J_index_reg <= J_index;
                    A_cnt <= 0;

                    mutli_col_idx1_reg <= 0;
                    multi_row_idx_reg <= 0;
                    divi_col_idx1_reg <= 0;
                    divi_row_idx_reg <= 0;
                    state_out <= 1;
                end
                else begin
                    state_out <= 0;
                end
            end
            
            GEN: begin
                // 跳出循环
                if (bit_cnt == J || (bit_cnt == J-1 && J_index_reg==J-1)) begin
                    state <= GEN2;
                    state_out <= 3;
                    candidate_row_tvalid_reg <= 1;
                    bit_cnt <= (J_index_reg==0) ? 1 : 0;
                    bit_cnt2 <= (J_index_reg<=1) ? 2 : 1;
                    for(integer i=0; i<J; i=i+1) begin
                        x_current[i] <= ((i == next_bit_cnt_end) || (i == next_bit_cnt2_end)) ? x_initial_next[i] : x_initial_reg[i*AWIDTH +: AWIDTH];
                    end
                end else begin
                    // 计数器
                    state_out <= 2;
                    mutli_col_idx1_reg <= x_current_next[bit_cnt];
                    multi_row_idx_reg <= bit_cnt;
                    divi_col_idx1_reg <= x_initial_reg[(bit_cnt)*AWIDTH +: AWIDTH];
                    divi_row_idx_reg <= bit_cnt;
                    
                    if(A_cnt == 0 && bit_cnt != 0) begin
                        if(A!=2) begin
                            A_cnt <= A_cnt + 1;
                            x_current[prev_bit_cnt] <= x_initial_reg[(prev_bit_cnt)*AWIDTH +: AWIDTH];
                            x_current[bit_cnt] <= x_current_next[bit_cnt];
                            
                        end
                        else begin
                            x_current[prev_bit_cnt] <= x_initial_reg[(prev_bit_cnt)*AWIDTH +: AWIDTH];
                            x_current[bit_cnt] <= x_current_next[bit_cnt];

                            bit_cnt <= next_bit_cnt;
                        end
                    end
                    else if(A_cnt < A-2) begin
                        A_cnt <= A_cnt + 1;
                        x_current[bit_cnt] <= x_current_next[bit_cnt];

                    end
                    else begin
                        A_cnt <= 0;
                        bit_cnt <= next_bit_cnt;
                        x_current[bit_cnt] <= x_current_next[bit_cnt];
                    end
                    // 生成candidate_col
                    candidate_row_tvalid_reg <= 1;
                    bit_cnt2 <= 0;
                end
            end
            
            GEN2: begin
                
                
                
                if(final_done) begin
                    state <= IDLE;
                    candidate_row_tvalid_reg <= 0;
                    state_out <= 0;
                end else begin
                    state_out <= 3;

                    candidate_row_tvalid_reg <= 1;
                    if(A_cnt2 < A-2) begin
                        A_cnt2 <= A_cnt2 + 1;
                        if(x_current[bit_cnt2] < A-1) begin
                            x_current[bit_cnt2] <= x_current_next[bit_cnt2];
                        end
                        else begin
                            x_current[bit_cnt2] <= 0;
                        end
                    end else if(A_cnt < A-2) begin
                        A_cnt2 <= 0;
                        A_cnt <= A_cnt + 1;   
                        if(x_current[bit_cnt] < A-1) begin
                            x_current[bit_cnt] <= x_current_next[bit_cnt];
                        end
                        else begin
                            x_current[bit_cnt] <= 0;
                        end
                        x_current[bit_cnt2] <= x_initial_next[bit_cnt2];

                    end
                    else begin
                        A_cnt2 <= 0;
                        A_cnt <= 0;
                        if(bit_cnt2 < J-1) begin
                            bit_cnt2 <= next_bit_cnt2;
                            x_current[bit_cnt] <= x_initial_next[bit_cnt];
                            x_current[bit_cnt2] <= x_initial_reg[bit_cnt2*AWIDTH +: AWIDTH];
                            x_current[next_bit_cnt2] <= x_initial_next[next_bit_cnt2];


                        end else begin
                            bit_cnt <= next_bit_cnt;
                            bit_cnt2 <= next_next_bit_cnt;
                            x_current[bit_cnt] <= x_initial_reg[bit_cnt*AWIDTH +: AWIDTH];
                            x_current[bit_cnt2] <= x_initial_reg[bit_cnt2*AWIDTH +: AWIDTH];
                            x_current[next_bit_cnt] <= x_initial_next[next_bit_cnt];
                            x_current[next_next_bit_cnt] <= x_initial_next[next_next_bit_cnt];

                        end
                    end
                end

                
            end

            
            default: state <= IDLE;
        endcase
    end
end



//new output
// wire [1:0] state_out;
// assign state_out = state;

assign mutli_col_idx1 = state == GEN2 ? x_current[bit_cnt] : mutli_col_idx1_reg;
assign mutli_col_idx2 = x_current[bit_cnt2];
assign multi_row_idx = state == GEN2 ? bit_cnt : multi_row_idx_reg;
assign multi_row_idx2 = bit_cnt2;

assign divi_col_idx1 = state == GEN2 ? x_initial_reg[bit_cnt*AWIDTH +: AWIDTH] : divi_col_idx1_reg;
assign divi_col_idx2 = x_initial_reg[bit_cnt2*AWIDTH +: AWIDTH];
assign divi_row_idx = state == GEN2 ? bit_cnt : divi_row_idx_reg;
assign divi_row_idx2 = bit_cnt2;

assign index_out_tvalid = candidate_row_tvalid_reg;
assign index_out_tlast = final_done;

endmodule
