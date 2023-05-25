`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2023 04:10:00 PM
// Design Name: 
// Module Name: i2c_tb_uvm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
`include "uvm_macros.svh"
import uvm_pkg::*;
//////////////////////////////////////////////////////////////
// config of active or passive agent
//////////////////////////////////////////////////////
class i2c_config extends uvm_object;
`uvm_object_utils(i2c_config)

function new (string path = "i2c_config");
    super.new(path);
endfunction

uvm_active_passive_enum is_active = UVM_ACTIVE;

endclass :i2c_config  

//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////
 
typedef enum logic [2:0]   {readd = 0, writed = 1, rstdut = 2} oper_mode;
// Transaction class
/////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
`uvm_object_utils(transaction)

function new (string path = "transaction");
    super.new(path);
endfunction

rand oper_mode op;
logic rst_n;
randc logic[6:0] addr;
rand logic [7:0] wdata;
logic wr; // wr =0 --> read wr =1 --> write 
logic [7:0] rdata;
logic newd;
logic done;
logic i2c_err;

constraint addr_c { addr <=5; }
//constraint addr_err_c {addr >= 32;}


endclass :transaction
////////////////////////////////////////////////////////////////
// sequence : write data 
//////////////////////////////////////
class write_data extends uvm_sequence#(transaction);
`uvm_object_utils(write_data)
function new (string path = "write_data");
    super.new(path);
endfunction

transaction tr;

task body ();
    repeat(10) begin
    tr=transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    start_item(tr);
    assert(tr.randomize);
    tr.op = writed;
    `uvm_info("SEQ", $sformatf("MODE : WRITE DIN : %0d ADDR : %0d ", tr.op, tr.wdata, tr.addr), UVM_NONE);
    finish_item(tr);
    end
    
endtask
endclass: write_data
////////////////////////////////////////////////////////////////
// sequence : Read data 
//////////////////////////////////////
class read_data extends uvm_sequence#(transaction);
`uvm_object_utils(read_data)
function new (string path = "read_data");
    super.new(path);
endfunction

transaction tr;

task body ();
repeat(10) begin
    tr=transaction::type_id::create("tr");
    tr.addr_c.constraint_mode(1);
    //tr.addr_err_c.constraint_mode(0);
    start_item(tr);
    assert(tr.randomize);
    tr.op = readd;
    `uvm_info("SEQ", $sformatf("MODE :  %0d ADDR : %0d ", tr.op, tr.addr), UVM_NONE);
    finish_item(tr);
    end
endtask
endclass:read_data 

////////////////////////////////////////////////////////////////////////////////////////////
// Reset DUT
////////////////////////////////////////////////////////////////////////////////////////////
class reset_dut extends uvm_sequence#(transaction);
  `uvm_object_utils(reset_dut)
  
  transaction tr;
 
  function new(string name = "reset_dut");
    super.new(name);
  endfunction
  
  virtual task body();
    repeat(15)
      begin
        tr = transaction::type_id::create("tr");
        start_item(tr);
        assert(tr.randomize);
        tr.op = rstdut;
        `uvm_info("SEQ", "MODE : RESET", UVM_NONE);
        finish_item(tr);
      end
  endtask
  
 
endclass:reset_dut

class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)

function new (string path = "driver", uvm_component parent = null);
    super.new(path,parent);
endfunction

transaction tr;
virtual i2c_if vif;
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual i2c_if)::get(this,"","vif",vif))
        `uvm_error("DRV","Unable to access Interface");
endfunction

task reset_dut();
    begin
        vif.rst_n <= 1'b0;
        vif.addr <= 0;
        vif.wdata <= 0;
        vif.wr <= 0;
        `uvm_info("DRV","System Reset: Start of Simulation",UVM_NONE);
        @(posedge vif.clk);
    end
endtask

task write_d();
    `uvm_info("DRV", $sformatf("mode : WRITE addr : %0d  din : %0d", tr.addr, tr.wdata), UVM_NONE);
    vif.rst_n <= 1'b1;
    vif.wr <= 1'b1;
    vif.addr <= tr.addr;
    vif.wdata <= tr.wdata;
    vif.newd <= 1'b1;
    @(posedge vif.clk);
    `uvm_info("DRV", $sformatf("mode :%d  Write addr:%0d din: %d newd:%0d",vif.wr, vif.addr, vif.wdata,vif.newd), UVM_NONE);
    @(posedge vif.clk);
    //vif.newd <= 1'b0;
    @(posedge vif.clk);
    `uvm_info("DRV", $sformatf("newd deasserted and value of newd:%0d", vif.newd), UVM_NONE);
    @(posedge vif.done);
endtask

task read_d();
    vif.rst_n <= 1'b1;
    vif.wr <= 1'b0;
    vif.addr <= tr.addr;
    vif.wdata <= 0;
    //vif.data_in <= tr.data_in;
    vif.newd <= 1'b1;
    @(posedge vif.clk);
    `uvm_info("DRV", $sformatf("mode :%d  Write addr:%0d din: %d newd:%0d", vif.wr,vif.addr, vif.wdata,vif.newd), UVM_NONE);
    @(posedge vif.clk);
    //vif.newd <= 1'b0;
    @(posedge vif.clk);
    `uvm_info("DRV", $sformatf("newd deasserted and value of newd:%0d", vif.newd), UVM_NONE);
    @(posedge vif.done);  
endtask

task drive();
    
    forever begin 
        seq_item_port.get_next_item(tr);
        if(tr.op ==  rstdut)
                  begin
          reset_dut();
          end
        else if(tr.op == writed)
          begin
          write_d();
          end
        else if(tr.op ==  readd)
          begin
          read_d();
          end
        seq_item_port.item_done();
       end  
endtask

 virtual task run_phase(uvm_phase phase);
    drive();
 endtask
endclass:driver
////////////////////////////////////////////////////////////
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
virtual i2c_if vif;

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    send_port= new("send_port",this);
    tr=transaction::type_id::create("tr");
    if(!uvm_config_db#(virtual i2c_if)::get(this,"","vif",vif))
        `uvm_error("DRV","Unable to access Interface");
endfunction

virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if(!vif.rst_n)
        begin
        tr.op      = rstdut; 
        `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
        send_port.write(tr);
        end
      else if (vif.rst_n && vif.wr)
         begin
          @(posedge vif.done);
          tr.op     = writed;
          tr.wdata    = vif.wdata;
          tr.addr   = vif.addr;
          tr.i2c_err    = vif.i2c_err;
          tr.wr = vif.wr;
          `uvm_info("MON", $sformatf("MODE: %d DATA WRITE addr:%0d data:%0d err:%0d",tr.wr,tr.addr,tr.wdata,tr.i2c_err), UVM_NONE); 
          send_port.write(tr);
         end
      else if (vif.rst_n && !vif.wr) //read
         begin
          @(posedge vif.done);
          tr.op     = readd; 
          tr.addr   = vif.addr;
          tr.i2c_err    = vif.i2c_err;
          tr.rdata   = vif.rdata; 
          tr.wr = vif.wr;
          `uvm_info("MON", $sformatf("MODE:%d DATA READ addr:%0d data_out:%0d slverr:%0d",tr.wr,tr.addr,tr.rdata,tr.i2c_err), UVM_NONE); 
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


bit [7:0] arr[128] = '{default:0};
bit [31:0] addr =0;
bit [7:0] data_rd =0;

virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv_port = new("recv_port", this);
    endfunction
    
    
  virtual function void write(transaction tr);
    
    if(tr.rst_n == 1'b0)
      `uvm_info("SCO", "System Reset", UVM_NONE) 
    else if (tr.op == writed)begin
       arr[tr.addr]=tr.wdata; 
       `uvm_info("SCO", $sformatf("DATA Write-> addr:%0d data:%0d slverr:%0d",tr.addr,tr.wdata,tr.i2c_err), UVM_NONE);
    end
    else if (tr.op == readd) begin
        data_rd = arr[tr.addr];
        if(data_rd == tr.rdata)
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
i2c_config cfg;    
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = i2c_config :: type_id::create("cfg");
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
read_data rd;
write_data wrd;
reset_dut rst_d;
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e= env::type_id::create("e",this);  
    rd = read_data :: type_id::create("rd");
    rst_d = reset_dut::type_id::create("rst_d");
    wrd = write_data::type_id::create("wrd");
endfunction 

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
rst_d.start(e.a.seqr);
wrd.start(e.a.seqr);
rd.start(e.a.seqr);

phase.drop_objection(this);
endtask 
endclass:test
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//---------------------TB TOP -----------------------------------------
///////////////////////////////////////////////////////////////
module i2c_tb_uvm(

    );
 i2c_if vif();   
 
i2c_top dut(
.clk(vif.clk),
.rst_n(vif.rst_n),
.newd(vif.newd),
 //input ack,
 .wr(vif.wr),   // wr =1 -> write wr=0 -> read
 .wdata(vif.wdata), // 8 bit data
 .addr(vif.addr), /////  7-bit : addr 
 .rdata(vif.rdata),
 .done(vif.done),
 .i2c_err(vif.i2c_err)
    ); 
    
    
 
 initial begin
    vif.clk =0;
 end
 
 always #10 vif.clk =~vif.clk;
 
 initial begin
        uvm_config_db#(virtual i2c_if)::set(null,"*","vif",vif);
        run_test("test");
end    
 /*
 repeat (10) @(posedge clk);
 rst_n = 1;
 @(posedge dut.mem_cntrl.sclk_ref);
 newd = 1; addr = 7'd9; wdata = 8'hab;
 @(posedge dut.mem_cntrl.sclk_ref);
 @(posedge clk);
 newd = 0;
 @(posedge done);
 @(posedge dut.mem_cntrl.sclk_ref);
 
 newd = 1; addr = 7'd9; wr=0;
 @(posedge dut.mem_cntrl.sclk_ref);
 @(posedge clk);
 newd = 0;
 @(posedge done);
  @(posedge clk);
 newd = 1; addr = 7'd2; wdata = 8'hcd; wr=1;
 @(posedge dut.mem_cntrl.sclk_ref);
 @(posedge clk);
 newd = 0;
 @(posedge done);
  @(posedge clk);
 newd = 1; addr = 7'd2;  wr=0;
 @(posedge dut.mem_cntrl.sclk_ref);
 @(posedge clk);
 newd = 0;
 @(posedge done);
 end      */
endmodule
