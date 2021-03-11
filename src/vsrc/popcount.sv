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
   
    assign S_AXIS_TREADY = 1'h0;
   
    // update me!
    assign COUNT = 32'h0;
    assign COUNT_BUSY = 1'h0;

endmodule
