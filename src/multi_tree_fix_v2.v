module multi_tree_fix_v2 #(
    parameter NUM = 8,                // 输入数量
    parameter DATA_WIDTH = 8         // 数据位宽
)(
    input wire clk,
    input wire rst_n,
    input wire [NUM*DATA_WIDTH-1:0] din,      // 输入数据
    input wire [NUM-1:0] din_tvalid,          // 输入有效信号
    output wire [31:0] dout,        // 输出数据
    output wire dout_tvalid                   // 输出有效信号
);

// 计算需要的级数
localparam LEVELS = $clog2(NUM);
localparam NUM_NODES = get_all_num(NUM, LEVELS);

// 节点数据和有效信号
wire [31:0] node_data [0:NUM_NODES-1];
wire [0:NUM_NODES-1] node_valid;

//生成乘法树结构
genvar i, j;
generate
    // 第一级：输入级
    for(i=0; i<(NUM+1)/2; i=i+1) begin : input_stage
        localparam add_one = ((NUM % 2) == 0 ? 0 : 1) && i == (NUM+1)/2 - 1;

        multiply_fix #(
            .DATAWIDTH_IN(DATA_WIDTH),
            .DATAWIDTH_OUT(32),
            .INVERSE(1),
            .OUTADDR(14)
        ) multiply_inst(
            .aclk(clk),
            .s_axis_a_tvalid(din_tvalid[2*i]),
            .s_axis_a_tdata(din[2*i*DATA_WIDTH +: DATA_WIDTH]),
            .s_axis_b_tvalid(add_one ? din_tvalid[2*i] : din_tvalid[2*i+1]),
            .s_axis_b_tdata(add_one ? 8'b10000000 : din[(2*i+1)*DATA_WIDTH +: DATA_WIDTH]),
            .m_axis_result_tvalid(node_valid[i]),
            .m_axis_result_tdata(node_data[i])
        );
    end

    // 中间级：乘法节点
    for(i=1; i<LEVELS; i=i+1) begin : mult_level
        localparam nodes_in_level = get_num(NUM, i);
        
        for(j=0; j<nodes_in_level; j=j+1) begin : mult_node
            localparam parent1_idx = 2*j + get_now_idx(i, j);
            localparam parent2_idx = 2*j + get_now_idx(i, j) + 1;
            localparam curr_idx = get_next_idx(i, j) + j;
            
            localparam add_one = ((get_num(NUM, i-1) % 2) == 0 ? 0 : 1) && j == nodes_in_level - 1;

            multiply_fix #(
                .DATAWIDTH_IN(32),
                .DATAWIDTH_OUT(32),
                .INVERSE(0),
                .OUTADDR(28)
            ) multiply_inst(
                .aclk(clk),
                .s_axis_a_tvalid(node_valid[parent1_idx]),
                .s_axis_a_tdata(node_data[parent1_idx]),
                .s_axis_b_tvalid(add_one ? node_valid[parent1_idx] : node_valid[parent2_idx]), 
                .s_axis_b_tdata(add_one ? 32'h10000000 : node_data[parent2_idx]),
                .m_axis_result_tvalid(node_valid[curr_idx]),
                .m_axis_result_tdata(node_data[curr_idx])
            );
        end
    end
endgenerate

// 输出赋值
assign dout = node_data[NUM_NODES-1];
assign dout_tvalid = node_valid[NUM_NODES-1];

function integer get_num;
    input integer NUM;
    input integer i;
    integer temp_num;
    integer k;
    begin
        temp_num = NUM;
        for(k=0; k<i+1; k=k+1) begin
            temp_num = (temp_num+1)/2;
        end
        get_num = temp_num;
    end
endfunction

function integer get_all_num;
    input integer NUM;
    input integer level;
    integer k;
    integer sum;
    begin
        sum = 0;
        for(k=0; k<level; k=k+1) begin
            sum = sum + get_num(NUM, k);
        end
        get_all_num = sum;
    end
endfunction

function integer get_now_idx;
    input integer i;
    input integer j;
    integer k;
    integer sum;
    begin
        sum = 0;
        for(k=0; k<i-1; k=k+1) begin
            sum = sum + get_num(NUM, k);
        end
        get_now_idx = sum;
    end
endfunction

function integer get_next_idx;
    input integer i;
    input integer j;
    integer k;
    integer sum;
    begin
        sum = 0;
        for(k=0; k<i; k=k+1) begin
            sum = sum + get_num(NUM, k);
        end
        get_next_idx = sum;
    end
endfunction

endmodule
