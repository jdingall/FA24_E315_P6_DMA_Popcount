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

// Based on a Xilinx testbench detailed here:
// https://www.xilinx.com/support/documentation/ip_documentation/axi4stream_vip/v1_1/pg277-axi4stream-vip.pdf

//import axi4stream_vip_pkg::*;
//import bd_axi4lite_behav_axi4stream_vip_0_0_pkg::*;

import axi_vip_pkg::*;
import bd_axi4lite_behav_axi_vip_0_0_pkg::*;

module axi4lite_behav_tb();

    // Clock signal
    logic               clk;
    // Reset signal
    logic               rst;

    //master agents
    //bd_axi4lite_behav_axi4stream_vip_0_0_mst_t  mst_agent;
    bd_axi4lite_behav_axi_vip_0_0_mst_t      master_agent;

    logic [31:0]                          test_write_data;
    logic [31:0]                          test_read_data;
 

    // instantiate bd
    bd_axi4lite_behav_wrapper DUT(
      .aclk_0(clk),
      .aresetn_0(~rst)
    );

    
    always #10 clk <= ~clk;
     
    task setup ();

        master_agent = new("master lite vip agent", DUT.bd_axi4lite_behav_i.axi_vip_0.inst.IF);

        master_agent.set_agent_tag("Master lite VIP");
        
        // set print out verbosity level.
        master_agent.set_verbosity(400);

        master_agent.start_master();
        
    endtask


    //MMIO Address - Should match Address Editor
    xil_axi_ulong mmio_addr=32'h40000000;
    xil_axi_prot_t  prot = 0;
    xil_axi_resp_t resp;

    //Main process
    initial begin
        $timeformat (-12, 1, " ps", 1);
        
        clk = 0;
        rst = 1;     //rst for bd, bitcount rst controlled by a register 
        
        $display("Simulation Setup");
        setup();             
        
        $display("Holding Reset");
        for (int i = 0; i < 20; i++) 
            @(negedge clk);

        rst <= 0;

        for (int i = 0; i < 4; ++i)
            @(negedge clk);

        $display("Starting Simulation");   
        
        // Use MMIO writes

        //reset bitcount
        master_agent.AXI4LITE_WRITE_BURST(mmio_addr,prot,32'h1,resp);
        
        for ( i = 32'h0; i < 32'h6; i++) begin
            test_write_data = i;
            #1
            $display("Writing Data: %h", test_write_data);
            master_agent.AXI4LITE_WRITE_BURST(mmio_addr + 32'h4 ,prot,test_write_data, resp);
            @(negedge clk);
        end
        
        @(negedge clk);

        //read output from register
        master_agent.AXI4LITE_READ_BURST(mmio_addr+32'h4, prot, test_read_data, resp);      
        $display( "Read Data: %h", test_read_data );
        assert( test_read_data == 7) else $fatal(1, "Bad Test Response: %d != %d", test_read_data, 7);
        
        $display("@@@Passed");
        
        $finish;

    end

endmodule
