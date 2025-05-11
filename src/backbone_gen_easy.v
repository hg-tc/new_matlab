module backbone_initial_fix #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [J*A*8-1:0] alpha_u,
    input [J*A_WIDTH-1:0] x_initial,
    input [J_WIDTH-1:0] ind_j,
    input din_tvalid,
    
    output backbone_initial_tvalid,
    output [31:0] backbone_initial
);



wire [(J-1)*8-1:0] multi_tree_din;
wire [(J-1)-1:0] multi_tree_din_tvalid;
wire [31:0] multi_tree_dout;
wire multi_tree_dout_tvalid;

wire [7:0] multi_tree_din_element [J-1-1:0];//debug

genvar i;
generate
    for(i=0; i<J-1; i=i+1) begin : multi_tree_input_gen
        assign multi_tree_din[i*8 +: 8] = (i < ind_j) ? alpha_u[i*A*8 + x_initial[i*A_WIDTH +: A_WIDTH]*8 +: 8] : 
            alpha_u[(i+1)*A*8 + x_initial[(i+1)*A_WIDTH +: A_WIDTH]*8 +: 8];
        assign multi_tree_din_tvalid[i] = din_tvalid;
        assign multi_tree_din_element[i] = multi_tree_din[i*8 +: 8];
    end
endgenerate

reg [31:0] multi_op1;
reg [7:0] multi_op2;
reg multi_tvalid;
wire multi_out_tvalid;
wire [31:0] multi_out;

localparam IDLE = 2'b00;
localparam MULTIPLY = 2'b01;
localparam DONE = 2'b10;

reg [1:0] state;
reg [7:0] multiply_cnt;
reg [16:0] multiply_result_temp0_16bit;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
        multiply_cnt <= 0;
        multiply_result_temp <= 1;
    end
    else begin
        case(state)
            IDLE: begin
                if(din_tvalid) begin
                    state <= MULTIPLY;
                    multiply_cnt <= 0;
                    multiply_result_temp <= multi_tree_din[0 +: 8];
                end
            end
            
            MULTIPLY: begin
                if(multiply_cnt < J-2) begin
                    multiply_cnt <= multiply_cnt + 1;
                    multiply_result_temp <= multiply_result_temp * multi_tree_din[(multiply_cnt+1)*8 +: 8];
                end
                else begin
                    state <= DONE;
                end
            end
            
            DONE: begin
                state <= IDLE;
            end
            
            default: state <= IDLE;
        endcase
    end
end


multiply_fix_v2 #(
        .DATAWIDTH_IN_A(32),
        .DATAWIDTH_IN_B(8),
        .DATAWIDTH_OUT(32),
        .INVERSE(0),
        .OUTADDR(28)
    ) multiply_inst(
        .aclk(clk),
        .s_axis_a_tvalid(multi_tvalid),
        .s_axis_a_tdata(multi_op1),
        .s_axis_b_tvalid(multi_tvalid), 
        .s_axis_b_tdata(multi_op2),
        .m_axis_result_tvalid(multi_out_tvalid),
        .m_axis_result_tdata(multi_out)
    );


assign backbone_initial = multi_tree_dout;
assign backbone_initial_tvalid = multi_tree_dout_tvalid;    


endmodule