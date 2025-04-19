//

module easy_fifo(clk,rst_n,din,din_valid,request,dout,out_valid,empty,count_num,full,almost_full);

parameter DATAWIDTH = 32*6;
parameter SIZE = 6;
parameter IN_SIZE = 3'd6; // >0
parameter OUT_SIZE = 3'd1;

parameter MODEWIDTH = 9;

localparam DEPTH_WIDTH = $clog2(SIZE);
localparam COUNT_WIDTH = DEPTH_WIDTH + 1;

input                                               clk,rst_n;
input    [ DATAWIDTH * IN_SIZE - 1 : 0 ]            din;
input                                               din_valid;
input                                               request;
output   [ DATAWIDTH * OUT_SIZE - 1 : 0 ]           dout;
output                                              out_valid;//"ready" for getting data, "out_valid" for output valid
output                                              empty;
output                                              full;
output                                              almost_full;
output reg   [DEPTH_WIDTH - 1:0]                                      count_num;

reg      [ DATAWIDTH * SIZE - 1 : 0 ]               Buffer = 0;
reg      [DEPTH_WIDTH-1:0]                                      w_addr = 0;
reg      [DEPTH_WIDTH-1:0]                                      r_addr = 0;
// reg      [ DATAWIDTH * OUT_SIZE - 1 : 0 ]           dout = 0;
// reg                                                 out_valid = 0;

//assign dout = Buffer[DATAWIDTH * r_addr +: DATAWIDTH * OUT_SIZE];

// assign count_num = w_addr-r_addr;

wire [DEPTH_WIDTH-1:0]  next_w_addr = w_addr + IN_SIZE;
wire [DEPTH_WIDTH-1:0]  next_r_addr = r_addr + OUT_SIZE;
always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        w_addr <= {DEPTH_WIDTH{1'b0}};
    end
    else if((din_valid == 1'b1) && (full != 1'b1)) begin
        if(next_w_addr!=SIZE)begin
            w_addr <= next_w_addr;
        end else begin w_addr <= 0; end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        r_addr <= {DEPTH_WIDTH{1'b0}};
    end
    else if((request == 1'b1) && (empty != 1'b1)) begin
        if(next_r_addr!=SIZE)begin
        r_addr <= next_r_addr;
        end else begin r_addr <= 0; end
    end
end 

always @(posedge clk) begin
    if((din_valid == 1'b1) && (full != 1'b1)) begin
        Buffer[DATAWIDTH * w_addr +: DATAWIDTH * IN_SIZE] <= din;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        count_num <= 0;
    end
    else if((din_valid == 1'b1) && (request == 1'b0) && (full != 1'b1)) begin
        count_num <= count_num + IN_SIZE;
    end
    else if((request == 1'b1) && (din_valid == 1'b0) && (empty != 1'b1)) begin
        count_num <= count_num - OUT_SIZE;
    end
    else if((request == 1'b1) && (din_valid == 1'b1)) begin
        count_num <= count_num + ((full != 1'b1) ? IN_SIZE : 0) - ((empty != 1'b1) ? OUT_SIZE : 0);
    end
end
assign empty = count_num < OUT_SIZE;
assign full = count_num > (SIZE - IN_SIZE);
assign almost_full = count_num >= (SIZE - IN_SIZE);


// assign dout = (request && out_valid) ? Buffer[DATAWIDTH * r_addr +: DATAWIDTH * OUT_SIZE] : 0;
assign dout = Buffer[DATAWIDTH * r_addr +: DATAWIDTH * OUT_SIZE];

assign out_valid = request && !empty;
endmodule