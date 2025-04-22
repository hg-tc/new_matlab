module backbone_initial2 #(
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


reg [LEVELS-1:0] multi_opa_tvalid;
reg [LEVELS-1:0] multi_opb_tvalid;
reg [LEVELS-1:0] multi_in_tlast;
wire [LEVELS-1:0] multi_result_tvalid;
reg [64-1:0] multi_opa_data [LEVELS-1:0];
reg [64-1:0] multi_opb_data [LEVELS-1:0];
wire [64-1:0] multi_result_data [LEVELS-1:0];
wire [LEVELS-1:0] pre_multi_out_tlast;
wire [LEVELS-1:0] multi_out_tlast;
wire [LEVELS-1:0] multi_out_tvalid;

genvar i;
generate
    for(i=0; i<LEVELS; i=i+1) begin
        multiply multiply_inst(
            .aclk(clk),
            .s_axis_a_tvalid(multi_opa_tvalid[i]),
            .s_axis_a_tdata(multi_opa_data[i]),
            .s_axis_b_tvalid(multi_opb_tvalid[i]),
            .s_axis_b_tdata(multi_opb_data[i]),
            .m_axis_result_tvalid(multi_result_tvalid[i]),
            .m_axis_result_tdata(multi_result_data[i])
        );

        
        easy_fifo #(
            .DATAWIDTH(1),
            .SIZE(64),
            .IN_SIZE(1),
            .OUT_SIZE(1)
        ) fifo_tlast (
            .clk(clk),
            .rst_n(rst_n),
            .din(i==0 ? multi_in_tlast[i] : multi_out_tlast[i-1]),
            .din_valid(multi_opb_tvalid[i]),
            .request(multi_result_tvalid[i]),
            .dout(pre_multi_out_tlast[i]),
            .out_valid(multi_out_tvalid[i]),
            .empty()
        );
        assign multi_out_tlast[i] = pre_multi_out_tlast[i] & multi_out_tvalid[i];
    end
endgenerate


// 状态定义
localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam CALC = 2'b10;

reg [1:0] state;
reg [J_WIDTH-1:0] cnt;
wire [A_WIDTH-1:0] alpha_u_index;
assign alpha_u_index = x_initial[cnt*A_WIDTH +: A_WIDTH];

integer j;
always @(posedge clk) begin
    if(!rst_n) begin
        state <= IDLE;
        cnt <= 0;
        for(j=0; j<LEVELS; j=j+1) begin
            multi_opa_tvalid[j] <= 0;
            multi_opb_tvalid[j] <= 0;
            multi_opa_data[j] <= 0;
            multi_opb_data[j] <= 0;
        end
        multi_in_tlast[0] <= 0;
    end
    else begin
        case(state)
            IDLE: begin
                if(alpha_u_tvalid) begin
                    state <= LOAD;
                    multi_in_tlast[0] <= 0;
                    // multi_opa_tvalid[0] <= 1;
                    // multi_opb_tvalid[0] <= 1;
                    // multi_opa_data[0] <= alpha_u[cnt*A*64 + alpha_u_index * 64 +: 64];
                    // multi_opb_data[0] <= alpha_u[(cnt+1)*A*64 + alpha_u_index * 64 +: 64];
                end
            end
            
            LOAD: begin
                
     
                if(cnt + 1 < J) begin
                    multi_opa_tvalid[0] <= 1;
                    multi_opb_tvalid[0] <= 1;
                    multi_opa_data[0] <= alpha_u[cnt*A*64 + alpha_u_index*64 +: 64];
                    multi_opb_data[0] <= alpha_u[(cnt+1)*A*64 + alpha_u_index*64 +: 64];
                    cnt <= cnt + 2;
                    if(cnt + 2 == J) begin
                        multi_in_tlast[0] <= 1;
                    end
                    else begin
                        multi_in_tlast[0] <= 0;
                    end
                end
                else if(cnt + 1 == J) begin
                    multi_opa_tvalid[0] <= 0;
                    multi_opb_tvalid[0] <= 0;
                    multi_opa_data[0] <= alpha_u[cnt*A*64 + alpha_u_index*64 +: 64];
                    multi_opb_data[0] <= 64'h3FF0000000000000;
                    state <= IDLE;
                    cnt <= 0;
                    multi_in_tlast[0] <= 1;
                end 
                else begin
                    multi_opa_tvalid[0] <= 0;
                    multi_opb_tvalid[0] <= 0;
                    multi_opa_data[0] <= 0;
                    multi_opb_data[0] <= 0;
                    state <= IDLE;
                    cnt <= 0;
                    multi_in_tlast[0] <= 0;
                end

            end
        
            default: state <= IDLE;
        endcase
    end
end

reg first_done = 0;
always @(posedge clk) begin
    if(!rst_n) begin
        for(j=0; j<LEVELS - 1; j=j+1) begin
            multi_in_tlast[j+1] <= 0;
        end
    end
    else begin
        for(j=0; j<LEVELS - 1; j=j+1) begin
            if(multi_result_tvalid[j]) begin
                if(!first_done) begin
                multi_opa_data[j+1] <= multi_result_data[j];
                multi_opb_data[j+1] <= multi_opb_data[j+1];// tlast 接入，控制tvalid
                multi_opa_tvalid[j+1] <= 1;
                multi_opb_tvalid[j+1] <= 0;
                first_done <= 1;
            end
            else begin
                multi_opb_data[j+1] <= multi_result_data[j];
                multi_opa_data[j+1] <= multi_opa_data[j+1];
                multi_opa_tvalid[j+1] <= 1;
                multi_opb_tvalid[j+1] <= 1;
                first_done <= 0;
                end
            end
            else begin
                if(first_done) begin
                    multi_opa_tvalid[j+1] <= 0;
                    multi_opb_tvalid[j+1] <= 0;
                    multi_opb_data[j+1] <=0;
                    multi_opa_data[j+1] <= 0;
                end
                else begin
                    multi_opa_tvalid[j+1] <= multi_opa_tvalid[j+1];
                    multi_opb_tvalid[j+1] <= multi_opb_tvalid[j+1];
                    multi_opb_data[j+1] <= multi_opb_data[j+1];
                    multi_opa_data[j+1] <= multi_opa_data[j+1];
                end
            end
        end
    end
end

endmodule