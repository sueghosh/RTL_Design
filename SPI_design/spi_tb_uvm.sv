`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/19/2023 02:34:00 PM
// Design Name: 
// Module Name: spi_tb_uvm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: SPI TB using UVM
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "uvm_macros.svh"
import uvm_pkg::*;
//////////////////////////////////////////////////////////////
// config of active or passive agent
//////////////////////////////////////////////////////
class spi_config extends uvm_object;
`uvm_object_utils(spi_config)

function new (string path = "spi_config");
    super.new(path);
endfunction

uvm_active_passive_enum is_active = UVM_ACTIVE;

endclass :spi_config  

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
 
typedef enum logic [2:0]   {read = 0, write = 1, rstdut = 2, writeerr = 3, readerr = 4} oper_mode;
// Transaction class
/////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
`uvm_object_utils(transaction)

function new (string path = "transaction");
    super.new(path);
endfunction

rand oper_mode op;
logic rst_n;
randc logic[7:0] addr;
rand logic [7:0] data_in;
logic wr; // wr =0 --> read wr =1 --> write 
logic [7:0] data_out;
logic ready;
logic done;
logic spi_err;

constraint addr_c { addr <=10; }
constraint addr_err_c {addr >= 32;}


endclass :transaction

////////////////////////////////////////////////////////////////
// sequence : read_after_write, 
//////////////////////////////////////
class read_after_write extends uvm_sequence#(transaction);
`uvm_object_utils(read_after_write)
function new (string path = "read_after_write");
    super.new(path);
endfunction

transaction tr;

task body ();
    repeat(10) begin
    tr=transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);
    start_item(tr);
    assert(tr.randomize);
    tr.op = write;
    finish_item(tr);
    end
    
    repeat(10) begin
    tr=transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    tr.addr_err_c.constraint_mode(0);
    start_item(tr);
    assert(tr.randomize);
    tr.op = read;
    finish_item(tr);
    end
    
endtask
endclass

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)

function new (string path = "driver", uvm_component parent = null);
    super.new(path,parent);
endfunction

transaction tr;
virtual spi_mem_if sif;
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual spi_mem_if)::get(this,"","sif",sif))
        `uvm_error("DRV","Unable to access Interface");
endfunction

task reset_dut();
    repeat(5)begin
        sif.rst_n <= 1'b0;
        sif.addr <= 0;
        sif.data_in <= 0;
        sif.wr <= 0;
        `uvm_info("DRV","System Reset: Start of Simulation",UVM_NONE);
        @(posedge sif.clk);
    end
endtask

task drive();
    reset_dut();
    forever begin 
        seq_item_port.get_next_item(tr);
        if(tr.op == rstdut)
            begin
                sif.rst_n <= 1'b0;
                @(posedge sif.clk);
            end
         else if (tr.op == write)
            begin
                sif.rst_n <= 1'b1;
                sif.wr <= 1'b1;
                sif.addr <= tr.addr;
                sif.data_in <= tr.data_in;
                sif.ready <= 1'b1;
                @(posedge sif.clk);
                `uvm_info("DRV", $sformatf("mode :%d  Write addr:%0d din: %d Ready:%0d",sif.wr, sif.addr, sif.data_in,sif.ready), UVM_NONE);
                @(posedge sif.clk);
                sif.ready <= 1'b0;
                @(posedge sif.clk);
                `uvm_info("DRV", $sformatf("Ready deasserted and value of Ready:%0d", sif.ready), UVM_NONE);
                @(posedge sif.done);
            end
            else if (tr.op == read)
            begin
                sif.rst_n <= 1'b1;
                sif.wr <= 1'b0;
                sif.addr <= tr.addr;
                sif.data_in <= 0;
                //sif.data_in <= tr.data_in;
                sif.ready <= 1'b1;
                @(posedge sif.clk);
                `uvm_info("DRV", $sformatf("mode :%d  Write addr:%0d din: %d Ready:%0d", sif.wr,sif.addr, sif.data_in,sif.ready), UVM_NONE);
                @(posedge sif.clk);
                sif.ready <= 1'b0;
                @(posedge sif.clk);
                `uvm_info("DRV", $sformatf("Ready deasserted and value of Ready:%0d", sif.ready), UVM_NONE);
                @(posedge sif.done);  
            end
            seq_item_port.item_done();
       end  
endtask

 virtual task run_phase(uvm_phase phase);
    drive();
 endtask
endclass:driver
///////////////////////////////////////////////////////////////
// monitor
//////////////////////////////////////////////////////////////
class monitor extends uvm_monitor;
`uvm_component_utils(monitor)
function new (string path = "monitor", uvm_component parent = null);
    super.new(path,parent);
endfunction

uvm_analysis_port #(transaction) send_port;
transaction tr;
virtual spi_mem_if sif;
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send_port= new("send_port",this);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual spi_mem_if)::get(this,"","sif",sif))
        `uvm_error("DRV","Unable to access Interface");
endfunction

virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge sif.clk);
      if(!sif.rst_n)
        begin
        tr.op      = rstdut; 
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send_port.write(tr);
        end
      else if (sif.rst_n && sif.wr)
         begin
          @(posedge sif.done);
          tr.op     = write;
          tr.data_in    = sif.data_in;
          tr.addr   = sif.addr;
          tr.spi_err    = sif.spi_err;
          tr.wr = sif.wr;
          `uvm_info("MON", $sformatf("MODE: %d DATA WRITE addr:%0d data:%0d err:%0d",tr.wr,tr.addr,tr.data_in,tr.spi_err), UVM_NONE); 
          send_port.write(tr);
         end
      else if (sif.rst_n && !sif.wr)
         begin
          @(posedge sif.done);
          tr.op     = read; 
          tr.addr   = sif.addr;
          tr.spi_err    = sif.spi_err;
          tr.data_out   = sif.data_out; 
          tr.wr = sif.wr;
          `uvm_info("MON", $sformatf("MODE:%d DATA READ addr:%0d data_out:%0d slverr:%0d",tr.wr,tr.addr,tr.data_out,tr.spi_err), UVM_NONE); 
          send_port.write(tr);
         end
    
    end
   endtask 
 


endclass:monitor

////////////////////////////////////////////////////////////////
//scoreboard
///////////////////////////////////////////////////////////////
class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)
function new (string path = "scoreboard", uvm_component parent = null);
    super.new(path,parent);
endfunction

uvm_analysis_imp #(transaction,scoreboard) recv_port;


bit [7:0] arr[32] = '{default:0};
bit [31:0] addr =0;
bit [7:0] data_rd =0;

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv_port = new("recv_port", this);
    endfunction
    
    
  virtual function void write(transaction tr);
    
    if(tr.rst_n == 1'b0)
      `uvm_info("SCO", "System Reset", UVM_NONE) 
    else if (tr.op == 1)begin
       arr[tr.addr]=tr.data_in; 
       `uvm_info("SCO", $sformatf("DATA Write-> addr:%0d data:%0d slverr:%0d",tr.addr,tr.data_in,tr.spi_err), UVM_NONE);
    end
    else if (tr.op == read) begin
        data_rd = arr[tr.addr];
        if(data_rd == tr.data_out)
            `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
            `uvm_info("SCO", "Test Failed", UVM_NONE)    
    end
    // TO DO : error
    $display("----------------------------------------------------------------");     
  endfunction 
endclass : scoreboard
//////////////////////////////////////////////////////////////
//agent
////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
`uvm_component_utils(agent)


function new(input string path = "agent", uvm_component parent = null);
    super.new(path,parent);
endfunction
uvm_sequencer#(transaction) seqr;
driver drv;
monitor mon;
spi_config cfg;    
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = spi_config :: type_id::create("cfg");
    mon = monitor:: type_id::create("mon",this);
//Check if active agent , if not active then only monitor is present otherwise driver and sequencer is present
    if(cfg.is_active == UVM_ACTIVE)begin
        seqr = uvm_sequencer#(transaction)::type_id::create("seqr",this);
        drv = driver::type_id::create("drv",this);
    end
endfunction 
//connection
virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(cfg.is_active == UVM_ACTIVE) begin
        drv.seq_item_port.connect(seqr.seq_item_export);
    end    
endfunction
endclass:agent
/////////////////////////////////////////////////////////////
// environment
/////////////////////////////////////////////////////////////
class env extends uvm_env;
`uvm_component_utils(env)
function new(input string path = "env", uvm_component parent = null);
    super.new(path,parent);
endfunction

agent a;
scoreboard sco;
virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    a = agent::type_id::create("a",this);
    sco = scoreboard::type_id::create("sco",this);
endfunction
virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send_port.connect(sco.recv_port);
endfunction

endclass :env 
/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Test
/////////////////////////////////////////////////////
class test extends uvm_test;
`uvm_component_utils(test)
function new(input string path = "test", uvm_component parent = null);
    super.new(path,parent);
endfunction

env e;  
read_after_write raw;
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e= env::type_id::create("e",this);  
    raw = read_after_write :: type_id::create("raw");
endfunction 

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
raw.start(e.a.seqr);
#20
phase.drop_objection(this);
endtask 
endclass:test
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//---------------------TB TOP -----------------------------------------
///////////////////////////////////////////////////////////////
module spi_tb_uvm(

    );
    
spi_mem_if sif();
    
 spi_top dut(
.clk(sif.clk),
.rst_n(sif.rst_n),
.addr(sif.addr),
.data_in(sif.data_in),
.wr(sif.wr), // wr =0 --> read wr =1 --> write 
.data_out(sif.data_out),
.ready(sif.ready),
.done(sif.done),
.spi_err(sif.spi_err)
    );   
    
    initial begin
        sif.clk =0;
    end
    always #10 sif.clk =~sif.clk;
    
    initial begin
        uvm_config_db#(virtual spi_mem_if)::set(null,"*","sif",sif);
        run_test("test");
    end    
endmodule
