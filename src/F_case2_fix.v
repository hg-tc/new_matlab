module F_case2_fix #(
    parameter J = 14,
    parameter I = 7, 
    parameter A = 2,
    localparam AWIDTH = $clog2(A)+1,
    localparam J_WIDTH = $clog2(J)+1
)(
    input clk,
    input rst_n,

    input [J-1:0] H,
    input H_tvalid,

    input [J*AWIDTH-1:0] x,
    input x_tvalid,

    output F_value,
    output F_value_tvalid
);

reg [J-1:0] H_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_reg <= 0;
    end
    else begin
        if (H_tvalid) begin
            H_reg <= H;
        end
    end
end


wire [AWIDTH-1:0] x_fifo_out;
wire x_fifo_out_tvalid;
wire x_empty;

wire [64-1:0] x_double;
wire x_double_tvalid;


easy_fifo #(
    .DATAWIDTH(AWIDTH),
    .SIZE(32),
    .IN_SIZE(J),
    .OUT_SIZE(1)
) fifo_x ( 
    .clk(clk),
    .rst_n(rst_n),
    .din(x),
    .din_valid(x_tvalid),
    .request(!x_empty),
    .dout(x_fifo_out),
    .out_valid(x_fifo_out_tvalid),
    .empty(x_empty)
);



reg [J_WIDTH-1:0] H_cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        H_cnt <= 0;
    end
    else begin
        if(x_fifo_out_tvalid) begin
            if(H_cnt < J-1) begin
                H_cnt <= H_cnt + 1;
            end
            else begin
                H_cnt <= 0;
            end
        end
    end
end

wire F_element;
wire F_element_tvalid;

assign F_element = H_reg[H_cnt] * x_fifo_out;
assign F_element_tvalid = x_fifo_out_tvalid;

wire F_element_tlast;
reg [J_WIDTH-1:0] cnt = 0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cnt <= 0;
    end else if(F_element_tvalid)begin
        if(cnt < J-1)begin
            cnt <= cnt + 1;
        end else begin
            cnt <= 0;
        end
    end
end
assign F_element_tlast = (cnt == J-1);

wire pre_F_value_tvalid;
wire pre_F_value_tlast;
reg [7:0] acc_sum = 0;
reg [7:0] acc_result = 0;
reg acc_valid = 0;
reg acc_last = 0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        acc_sum <= 0;
        acc_valid <= 0;
        acc_last <= 0;
        acc_result <= 0;
    end else begin
        if(F_element_tvalid) begin
            if(F_element_tlast) begin
                acc_sum <= F_element;
                acc_result <= acc_sum + F_element;
                acc_valid <= 1;
                acc_last <= 1;
            end else begin
                acc_sum <= acc_sum + F_element;
                acc_valid <= 1;
                acc_last <= 0;
            end
        end else begin
            acc_valid <= 0;
            acc_last <= 0;
        end
    end
end

assign pre_F_value_tvalid = acc_valid;
assign pre_F_value_tlast = acc_last;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         F_value <= 0;
//     end else begin
//         F_value <= acc_sum[0] == 0;
//     end
// end
assign F_value = acc_result[0] == 0;
assign F_value_tvalid = pre_F_value_tvalid & pre_F_value_tlast;
endmodule
