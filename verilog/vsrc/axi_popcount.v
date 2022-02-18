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


module axi_popcount 
	(
		// AXI4-Stream Interface
		input                           S_AXIS_ACLK,
		input                           S_AXIS_ARESETN,
		input [31:0]                    S_AXIS_TDATA,
        input [3:0]                     S_AXIS_TKEEP,
        input                           S_AXIS_TLAST,
        input                           S_AXIS_TVALID,
        output                          S_AXIS_TREADY,

        // AXI4-Lite Interface
        // (Some signals are unused in our implimentation)
		input                           S_AXI_LITE_ACLK,
		input                           S_AXI_LITE_ARESETN,
		input [31: 0]                   S_AXI_LITE_AWADDR,
		input [2 : 0]                   S_AXI_LITE_AWPROT, 
		input                           S_AXI_LITE_AWVALID,
		output                          S_AXI_LITE_AWREADY,
		input [31:0]                    S_AXI_LITE_WDATA,
		input [3: 0]                    S_AXI_LITE_WSTRB,
		input                           S_AXI_LITE_WVALID,
		output                          S_AXI_LITE_WREADY,
		output [1 : 0]                  S_AXI_LITE_BRESP,
		output                          S_AXI_LITE_BVALID,
		input                           S_AXI_LITE_BREADY,
		input [31: 0]                   S_AXI_LITE_ARADDR,
		input [2 : 0]                   S_AXI_LITE_ARPROT,
		input                           S_AXI_LITE_ARVALID,
		output                          S_AXI_LITE_ARREADY,
		output [31: 0]                  S_AXI_LITE_RDATA,
		output [1 : 0]                  S_AXI_LITE_RRESP,
		output                          S_AXI_LITE_RVALID,
		input                           S_AXI_LITE_RREADY
		
	);

    // How many memory-mapped addresses do you want?  
   	localparam integer AW = 2; 
   	genvar ii;

    wire [31:0]	    READ_MEM	[0:AW-1];
	wire [AW-1:0]   READ_MEM_VALID;

	wire [31:0]	    WRITE_MEM   [0:AW-1];
	wire [AW-1:0]   WRITE_MEM_VALID; 
	
	
	assign READ_MEM[0][31:1] = 31'h0;


    popcount popcnt0(
          .S_AXIS_ACLK(S_AXIS_ACLK),
          .S_AXIS_ARESETN(S_AXIS_ARESETN),
          .S_AXIS_TDATA(S_AXIS_TDATA),
          .S_AXIS_TKEEP(S_AXIS_TKEEP),
          .S_AXIS_TLAST(S_AXIS_TLAST),
          .S_AXIS_TVALID(S_AXIS_TVALID),
          .S_AXIS_TREADY(S_AXIS_TREADY),
          
          .WRITE_DATA(WRITE_MEM[1]),
          .WRITE_VALID(WRITE_MEM_VALID[1]),

          .COUNT(READ_MEM[1]),
          .COUNT_RST(WRITE_MEM[0][0] && WRITE_MEM_VALID[0]),
          .COUNT_BUSY(READ_MEM[0][0])
    );
    
    
    

    // Annoying Verilog sillyness 
    // We have to flatten a 2D array into a 1D array to pass it between modules
    wire [32* AW -1 : 0] WRITE_MEM_FLAT;
    wire [32* AW -1 : 0] READ_MEM_FLAT;
    
    for (ii=0;ii<AW;ii=ii+1) begin assign WRITE_MEM[ii] = WRITE_MEM_FLAT[32*ii+31:32*ii]; end
    for (ii=0; ii<AW; ii=ii+1) begin assign READ_MEM_FLAT [32*ii+31:32*ii] = READ_MEM[ii]; end	


    // Instantiation of Axi Bus Interface S00_AXI
    axi4lite_interface # ( 
        .C_S_AXI_DATA_WIDTH(32), //32-bit data bus
        .C_S_AXI_ADDR_WIDTH(32), //32-bit address bus
        .ADDR_LSB(2), //32-bit registers
        .AW(AW)
    ) axi4lite0 (

        //Local Signals
        .READ_MEM_FLAT( READ_MEM_FLAT),
        .READ_MEM_VALID(READ_MEM_VALID),
        .WRITE_MEM_FLAT( WRITE_MEM_FLAT),
        .WRITE_MEM_VALID(WRITE_MEM_VALID),
       
        //AXI4LITE Signals
        .S_AXI_ACLK(S_AXI_LITE_ACLK),
        .S_AXI_ARESETN(S_AXI_LITE_ARESETN),
        .S_AXI_AWADDR(S_AXI_LITE_AWADDR),
        .S_AXI_AWPROT(S_AXI_LITE_AWPROT),
        .S_AXI_AWVALID(S_AXI_LITE_AWVALID),
        .S_AXI_AWREADY(S_AXI_LITE_AWREADY),
        .S_AXI_WDATA(S_AXI_LITE_WDATA),
        .S_AXI_WSTRB(S_AXI_LITE_WSTRB),
        .S_AXI_WVALID(S_AXI_LITE_WVALID),
        .S_AXI_WREADY(S_AXI_LITE_WREADY),
        .S_AXI_BRESP(S_AXI_LITE_BRESP),
        .S_AXI_BVALID(S_AXI_LITE_BVALID),
        .S_AXI_BREADY(S_AXI_LITE_BREADY),
        .S_AXI_ARADDR(S_AXI_LITE_ARADDR),
        .S_AXI_ARPROT(S_AXI_LITE_ARPROT),
        .S_AXI_ARVALID(S_AXI_LITE_ARVALID),
        .S_AXI_ARREADY(S_AXI_LITE_ARREADY),
        .S_AXI_RDATA(S_AXI_LITE_RDATA),
        .S_AXI_RRESP(S_AXI_LITE_RRESP),
        .S_AXI_RVALID(S_AXI_LITE_RVALID),
        .S_AXI_RREADY(S_AXI_LITE_RREADY)
    );

endmodule
