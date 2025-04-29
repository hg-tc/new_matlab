module multiply_fix_v2 #(
    parameter DATAWIDTH_IN_A = 32,         // 数据位宽
    parameter DATAWIDTH_IN_B = 32,         // 数据位宽
    parameter DATAWIDTH_OUT = 60,         // 数据位宽
    parameter INVERSE = 0,
    parameter OUTADDR = 4    // 数据位宽
)(
    input wire aclk,
    input wire s_axis_a_tvalid,
    input wire [DATAWIDTH_IN_A-1:0] s_axis_a_tdata,
    input wire s_axis_b_tvalid,
    input wire [DATAWIDTH_IN_B-1:0] s_axis_b_tdata,
    output reg m_axis_result_tvalid,
    output wire [DATAWIDTH_OUT-1:0] m_axis_result_tdata
);

wire [DATAWIDTH_IN_A+DATAWIDTH_IN_B-1:0] temp_result_tdata;
assign temp_result_tdata = s_axis_a_tdata * s_axis_b_tdata;

reg [DATAWIDTH_OUT-1:0] pre_result;
always @(posedge aclk) begin
    if(s_axis_a_tvalid & s_axis_b_tvalid) begin
        if(!INVERSE && OUTADDR+DATAWIDTH_OUT > DATAWIDTH_IN_A+DATAWIDTH_IN_B) begin
            pre_result <= {0,temp_result_tdata[DATAWIDTH_IN_A+DATAWIDTH_IN_B-1 : OUTADDR]};
        end else if(INVERSE && DATAWIDTH_OUT-OUTADDR > DATAWIDTH_IN_A+DATAWIDTH_IN_B) begin
            pre_result <= {0,temp_result_tdata[DATAWIDTH_IN_A+DATAWIDTH_IN_B-1 : 0],{OUTADDR{1'b0}}};
        end else begin
            if(!INVERSE) begin
                pre_result <= temp_result_tdata[OUTADDR +: DATAWIDTH_OUT];
            end else begin
                pre_result <= {temp_result_tdata[DATAWIDTH_OUT - OUTADDR - 1 : 0],{OUTADDR{1'b0}}};
            end
        end
        m_axis_result_tvalid <= 1;
    end else begin
        m_axis_result_tvalid <= 0;
        pre_result <= 0;
    end
end

assign m_axis_result_tdata = pre_result==0 ? 1 : pre_result;
endmodule