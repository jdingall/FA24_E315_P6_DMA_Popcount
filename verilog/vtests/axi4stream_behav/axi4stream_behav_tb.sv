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

import axi4stream_vip_pkg::*;
import bd_axi4stream_behav_axi4stream_vip_0_0_pkg::*;

import axi_vip_pkg::*;
import bd_axi4stream_behav_axi_vip_0_0_pkg::*;

module axi4stream_behav_tb();

    // Clock signal
    logic               clk;
    // Reset signal
    logic               rst;

    //master agents
    bd_axi4stream_behav_axi4stream_vip_0_0_mst_t  mst_agent;
    bd_axi4stream_behav_axi_vip_0_0_mst_t      master_agent;

    
    logic [31:0]                          test_write_data;
    logic [31:0]                          test_read_data;
 

    // instantiate bd
    bd_axi4stream_behav_wrapper DUT(
      .aclk_0(clk),
      .aresetn_0(~rst)
    );

    
    always #10 clk <= ~clk;
     
  
    task send_data (
        input bit[31:0] data
    );
        axi4stream_transaction                  wr_transaction; 
        axi4stream_transaction               resp_transaction; 

        wr_transaction = mst_agent.driver.create_transaction("Master VIP write transaction");
        resp_transaction = mst_agent.driver.create_transaction("Master VIP write response");
        SEND_PACKET_FAILURE: assert(wr_transaction.randomize());
        wr_transaction.set_data( {data[7:0], data[15:8], data[23:16],data[31:24] } );
        mst_agent.driver.send(wr_transaction);
    endtask

    
    task setup ();

        axi4stream_ready_gen                           ready_gen;

        mst_agent = new("master vip agent",DUT.bd_axi4stream_behav_i.axi4stream_vip_0.inst.IF);
        
        master_agent = new("master lite vip agent", DUT.bd_axi4stream_behav_i.axi_vip_0.inst.IF);

        
        /***************************************************************************************************
        * When bus is in idle, it must drive everything to 0.otherwise it will 
        * trigger false assertion failure from axi_protocol_chekcer
        ***************************************************************************************************/

        mst_agent.vif_proxy.set_dummy_drive_type(XIL_AXI4STREAM_VIF_DRIVE_NONE);

        /***************************************************************************************************
        * Set tag for agents for easy debug,if not set here, it will be hard to tell which driver is filing 
        * if multiple agents are called in one testbench
        ***************************************************************************************************/

        mst_agent.set_agent_tag("Master VIP");
        
        master_agent.set_agent_tag("Master lite VIP");
        
        // set print out verbosity level.
        mst_agent.set_verbosity(400);

        master_agent.set_verbosity(400);


        /***************************************************************************************************
        * Master,slave agents start to run 
        * Turn on passthrough agent monitor 
        ***************************************************************************************************/

        mst_agent.start_master();
        
        master_agent.start_master();
        
    endtask


    //MMIO Address - Should match Address Editor
    xil_axi_ulong mmio_addr=32'h44A00000;
    xil_axi_prot_t  prot = 0;
    bit [31:0] write_data1=32'h00000001;
    bit [31:0] read_data1 = 32'h0;
    xil_axi_resp_t resp;

    //Main process
    initial begin
        $timeformat (-12, 1, " ps", 1);
        


        clk <= 0;
        rst <= 1;     //rst for bd, bitcount rst controlled by a register 
        
        $display("Simulation Setup");
        setup();             
        
        $display("Holding Reset");
        for (int i = 0; i < 20; i++) 
        @(negedge clk);

        rst <= 0;

        @(negedge clk);
        @(negedge clk);

        $display("Starting Simulation");   
        
        //reset bitcount
        master_agent.AXI4LITE_WRITE_BURST(mmio_addr,prot,32'h1,resp);  
        
        for ( int i = 32'h0; i < 32'h5; i++) begin
            test_write_data = i;
            #1
            $display("Writing Data: %h", test_write_data);
            send_data(test_write_data);
            @(negedge clk);
        end
        
        //wait until the AXI-Stream transactions are all done
        while( !mst_agent.driver.is_driver_idle())
            @(negedge clk);
        
        //read output from register
        master_agent.AXI4LITE_READ_BURST(mmio_addr+32'h4, prot, test_read_data, resp);      
        $display( "Read Data: %h", test_read_data );
        assert( test_read_data == 5) else $fatal(1, "Bad Test Response: %d != %d", test_read_data, 5);
        
        //reset bitcount
        master_agent.AXI4LITE_WRITE_BURST(mmio_addr,prot,32'h1,resp);  
        
        for ( int i = 32'h0; i < 32'h6; i++) begin
            test_write_data = i;
            #1
            $display("Writing Data: %h", test_write_data);
            send_data(test_write_data);
            @(negedge clk);
        end
        
        //wait until the AXI-Stream transactions are all done
        while( !mst_agent.driver.is_driver_idle())
            @(negedge clk);
        
        //read output from register
        master_agent.AXI4LITE_READ_BURST(mmio_addr+32'h4, prot, test_read_data, resp);      
        $display( "Read Data: %h", test_read_data );
        assert( test_read_data == 7) else $fatal(1, "Bad Test Response: %d != %d", test_read_data, 7);
        
        
        // Now switch to MMIO writes
        //reset bitcount
        master_agent.AXI4LITE_WRITE_BURST(mmio_addr,prot,32'h1,resp);
        
        for ( int i = 32'h0; i < 32'h6; i++) begin
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
