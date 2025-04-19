module backbone_initial #(
    parameter J = 14,
    parameter I = 7,
    parameter A = 2,
    localparam J_WIDTH = $clog2(J)+1,
    localparam A_WIDTH = $clog2(A)+1
)(
    input clk,
    input rst_n,
    input [J*A*64-1:0] alpha_u,
    input alpha_u_tvalid,

    input [J*A_WIDTH-1:0] x_initial,
    input x_initial_tvalid,

    input [J_WIDTH-1:0] ind_j,
    input ind_j_tvalid,
    
    output backbone_initial_tvalid,
    output [63:0] backbone_initial
);



localparam LEVELS = $clog2(J);


reg [LEVELS-1:0] multi_opa_valid;
reg [LEVELS-1:0] multi_opb_valid;
wire [LEVELS-1:0] multi_result_valid;
reg [64-1:0] multi_opa_data [LEVELS-1:0];
reg [64-1:0] multi_opb_data [LEVELS-1:0];
wire [64-1:0] multi_result_data [LEVELS-1:0];

genvar i;
generate
    for(i=0; i<LEVELS; i=i+1) begin
        multiply multiply_inst(
            .aclk(clk),
            .s_axis_a_tvalid(multi_opa_valid[i]),
            .s_axis_a_tdata(multi_opa_data[i]),
            .s_axis_b_tvalid(multi_opb_valid[i]),
            .s_axis_b_tdata(multi_opb_data[i]),
            .m_axis_result_tvalid(multi_result_valid[i]),
            .m_axis_result_tdata(multi_result_data[i])
        );
    end
endgenerate


// 状态定义
localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam CALC = 2'b10;

reg [1:0] state;
reg [J_WIDTH-1:0] cnt;

integer j;
always @(posedge clk) begin
    if(!rst_n) begin
        state <= IDLE;
        cnt <= 0;
        for(j=0; j<LEVELS; j=j+1) begin
            multi_opa_valid[j] <= 0;
            multi_opb_valid[j] <= 0;
            multi_opa_data[j] <= 0;
            multi_opb_data[j] <= 0;
        end
    end
    else begin
        case(state)
            IDLE: begin
                if(alpha_u_tvalid) begin
                    state <= LOAD;
                    multi_opa_valid[0] <= 1;
                    multi_opb_valid[0] <= 1;
                    multi_opa_data[0] <= alpha_u[cnt*A*64 + A_WIDTH * 64 +: 64];
                    multi_opb_data[0] <= alpha_u[(cnt+1)*A*64 + A_WIDTH * 64 +: 64];
                end
            end
            
            LOAD: begin
                cnt <= cnt + 1;
                if(cnt >= J-1) begin
                    cnt <= 0;
                    state <= IDLE;
                end
                else begin
                    cnt <= cnt + 1;
                end
            end
        
            default: state <= IDLE;
        endcase
    end
end

reg first_done;
always @(posedge clk) begin
    for(j=0; j<LEVELS - 1; j=j+1) begin
        if(multi_result_valid[j]) begin
            if(!first_done) begin
                multi_opa_valid[j+1] <= multi_result_data[j];
                multi_opb_valid[j+1] <= multi_opb_data[j+1];
                first_done <= 1;
            end
            else begin
                multi_opb_valid[j+1] <= multi_result_data[j];
                multi_opa_valid[j+1] <= multi_opa_data[j+1];
                first_done <= 0;
            end
        end
    end
end

endmodule