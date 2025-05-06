
module signal_delay(clk,pre_signal,signal);

parameter DATAWIDTH = 32;
parameter DELAY_CYCLE = 2;


input                                   clk;
input    [ DATAWIDTH - 1 : 0 ]          pre_signal;

output   [ DATAWIDTH - 1 : 0  ]         signal;


reg [ (DELAY_CYCLE+1) * DATAWIDTH - 1 : 0 ] signal_Buffer = 0;

always @(posedge clk) begin

    signal_Buffer <= {signal_Buffer[ 0 +: DELAY_CYCLE * DATAWIDTH ], pre_signal};

end

assign signal = signal_Buffer[ (DELAY_CYCLE-1) * DATAWIDTH +: DATAWIDTH ];

// get valid data

endmodule