`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Created for Indiana University's E315 Class
//
// 
// Andrew Lukefahr
// lukefahr@iu.edu
//
// Ethan Japundza
// ejapundz@iu.edu
//
// 2021-02-23
// 2020-02-25
//
//////////////////////////////////////////////////////////////////////////////////


module popcount(

        //AXI4-Stream SIGNALS
        input               S_AXIS_ACLK,
        input               S_AXIS_ARESETN,
		input [31:0]        S_AXIS_TDATA,
        input [3:0]         S_AXIS_TKEEP,
        input               S_AXIS_TLAST, //TLAST represents end of DMA transfer
        input               S_AXIS_TVALID,
        output              S_AXIS_TREADY,

        //MMIO Inputs
        input [31:0]        WRITE_DATA,
        input               WRITE_VALID,
        
        // Count signals
        output reg [31:0]   COUNT,
        input               COUNT_RST,
        output reg          COUNT_BUSY //busy = 1 when counting is happening, busy=0 at idle 
        
    );
   
integer i,j;

reg [5:0] stream_input_ones;
reg [5:0] mmio_input_ones;


assign S_AXIS_TREADY = 1'h1;

assign COUNT_BUSY = S_AXIS_TVALID;


//count is the only thing that needs FF's
always_ff@(posedge S_AXIS_ACLK) begin
    if (~S_AXIS_ARESETN) begin
        COUNT <= 32'h0;
    end else if (COUNT_RST) begin
        COUNT <= 32'h0;
    end else begin
        COUNT <= (S_AXIS_TVALID ? COUNT + stream_input_ones : 
                  (WRITE_VALID ? COUNT + mmio_input_ones :
                  COUNT));
    end
end


//count the immediate ones
always_comb begin
    stream_input_ones = 0;
    for (i = 0; i < 32; ++i) 
        stream_input_ones = stream_input_ones + S_AXIS_TDATA[i];
end

//count the immediate ones
always_comb begin
    mmio_input_ones = 0;
    for (j = 0; j < 32; ++j) 
        mmio_input_ones = mmio_input_ones + WRITE_DATA[j];
end

endmodule
