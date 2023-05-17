`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2023 06:29:06 PM
// Design Name: 
// Module Name: uart_tb_uvm
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
`include "uvm_macros.svh"
import uvm_pkg::*;
//----------env config_db--------------
////////////////////////////////////////////////////////////////////////////////////
class uart_config extends uvm_object; /////configuration of env
  `uvm_object_utils(uart_config)
  
  function new( string name = "uart_config");
    super.new(name);
  endfunction
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
endclass

typedef enum bit [3:0] {rand_baud_1_stop = 0, rand_length_1_stop = 1,
 length5wp = 2, length6wp = 3, length7wp = 4, length8wp = 5, length5wop = 6, 
 length6wop = 7, length7wop = 8, length8wop = 9,rand_baud_2_stop = 11, 
 rand_length_2_stop = 12} oper_mode;
//----------------------transaction-------------------------------
class transaction extends uvm_sequence_item;
 `uvm_object_utils(transaction)
rand oper_mode op;
rand logic [16:0] baud;
logic rst;
logic tx_start;
rand logic [7:0] tx_data;
rand logic parity_en;
rand logic parity_type;
rand logic [3:0] data_len;
logic stop2;
logic tx_done;
logic tx_err;
logic rx_start;
logic [7:0] rx_data;
logic rx_done;
logic rx_err;
 
 function new( string name = "transaction");
    super.new(name);
  endfunction
  constraint baud_c {baud inside {4800,9600,14400,19200,38400,57600};}  
  constraint data_len_c {data_len inside {5,6,7,8};} 
    
endclass : transaction

/////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------sequence-------------------------------------------------------//
//---------Generate all the different sequences--------------------------------------------//
/////////////////////////////////////////////////////////////////////////////////////////////
//----------1. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_1 extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_1)

transaction tr; 

 function new( string name = "rand_baud_1");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = rand_baud_1_stop;
    tr.data_len = 8;
    //tr.baud   = 9600;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b1;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_1
//----------2. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 2 stop

class rand_baud_2 extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_2)

transaction tr; 

 function new( string name = "rand_baud_2");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = rand_baud_2_stop;
    tr.data_len = 8;
    //tr.baud   = 9600;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b1;
    tr.stop2     = 1'b1;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_2

//-------------------------------------------------------
//----------3. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_5wp extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_5wp)

transaction tr; 

 function new( string name = "rand_baud_5wp");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length5wp;
    tr.data_len = 5;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {3'b000, tr.tx_data[7:3]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b1;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_5wp

//-----------------------------------------------------
//----------3. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_6wp extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_6wp)

transaction tr; 

 function new( string name = "rand_baud_6wp");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length6wp;
    tr.data_len = 6;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {2'b00, tr.tx_data[7:2]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b1;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_6wp

//-----------------------------------------------------
//----------4. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_7wp extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_7wp)

transaction tr; 

 function new( string name = "rand_baud_7wp");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length7wp;
    tr.data_len = 7;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {1'b0, tr.tx_data[7:1]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b1;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_7wp

//-----------------------------------------------------

//----------5. random baud,fixed length data_len = 5, parity_en = 0, random parity_type, 1 stop

class rand_baud_5wop extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_5wop)

transaction tr; 

 function new( string name = "rand_baud_5wop");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length5wop;
    tr.data_len = 5;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {3'b000, tr.tx_data[7:3]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b0;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_5wop

//----------6. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_6wop extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_6wop)

transaction tr; 

 function new( string name = "rand_baud_6wop");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length6wop;
    tr.data_len = 6;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {2'b00, tr.tx_data[7:2]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b0;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_6wop

//----------7. random baud,fixed length data_len = 8, parity_en = 1, random parity_type, 1 stop

class rand_baud_7wop extends uvm_sequence#(transaction);
`uvm_object_utils(rand_baud_7wop)

transaction tr; 

 function new( string name = "rand_baud_7wop");
    super.new(name);
 endfunction
 virtual task body();
 repeat(5) begin
    tr=transaction::type_id::create("tr");
    start_item(tr); 
    assert(tr.randomize);
    tr.op = length7wop;
    tr.data_len = 7;
    tr.rst       = 1'b1;
    tr.tx_start  = 1'b1;
    tr.tx_data   = {1'b0, tr.tx_data[7:1]};
    tr.rx_start  = 1'b1;
    tr.parity_en = 1'b0;
    tr.stop2     = 1'b0;
    finish_item(tr);
 end
 endtask 
  
endclass: rand_baud_7wop

/////////////////////////////////////////////////////////////////////////////////////
//-----------------------------Driver ---------------------------------------------//
////////////////////////////////////////////////////////////////////////////////////
class driver extends uvm_driver#(transaction);
`uvm_component_utils(driver)
 function new(input string path = "DRV", uvm_component parent = null);
    super.new(path,parent);
 endfunction
 
 transaction tr; 
 virtual uart_if uif;
 
 virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tr= transaction::type_id::create("tr"); 
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
        `uvm_error("DRV","Unable to access Interface");  
 endfunction
 
 //Reset dut
 task reset_dut();
    repeat(5) begin
    uif.rst <=1'b0; //active low reset
    uif.tx_start <= 1'b0;
    uif.rx_start <= 1'b0;
    uif.baud <= 17'h0;
    uif.data_len <= 4'h0;
    uif.tx_data <=8'h0;
    uif.parity_en <= 1'b0;
    uif.parity_type <=1'b0;
    uif.stop2 <=1'b0;
    `uvm_info("DRV","System reset Asserted: Start of simulation",UVM_NONE);
    @(posedge uif.clk);
    end
 endtask
 
 task drive();
    reset_dut();
    forever begin
        seq_item_port.get_next_item(tr);
        uif.rst         <= 1'b1;
        uif.tx_start    <= tr.tx_start;
        uif.rx_start    <= tr.rx_start;
        uif.tx_data     <= tr.tx_data;
        uif.baud        <= tr.baud;
        uif.data_len    <= tr.data_len;
        uif.parity_type <= tr.parity_type;
        uif.parity_en   <= tr.parity_en;
        uif.stop2       <= tr.stop2;
       `uvm_info("DRV", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d", tr.baud, tr.data_len, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data), UVM_NONE);
       @(posedge uif.tx_done);
       `uvm_info("DRV","TX DONE received",UVM_NONE);
       @(negedge uif.rx_done);
       seq_item_port.item_done();
    end
 endtask
 
 virtual task run_phase(uvm_phase phase);
    drive();
 endtask

endclass: driver
//////////////////////////////////////////////////////////////////////////////////////////////////
//------------------------- Monitor---------------------------------------------------------//
////////////////////////////////////////////////////////////////////////////////////////////
class monitor extends uvm_monitor;
`uvm_component_utils(monitor)
function new(input string path = "MON", uvm_component parent = null);
    super.new(path,parent);
 endfunction
 uvm_analysis_port #(transaction) send_port;
 transaction tr; 
 virtual uart_if uif;
 
 virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    tr= transaction::type_id::create("tr"); 
    send_port = new("send_port",this);
    if(!uvm_config_db#(virtual uart_if)::get(this,"","uif",uif))
        `uvm_error("MON","Unable to access Interface");
 endfunction
 
 virtual task run_phase (uvm_phase phase);
    forever begin  
        @(posedge uif.clk);
        if(!uif.rst)
            begin
                tr.rst = 1'b0;
                `uvm_info("MON", "SYSTEM RESET DETECTED", UVM_NONE);
                send_port.write(tr);
            end
         else begin
            @(posedge uif.tx_done);
            tr.rst         = 1'b1;
            tr.tx_start    = uif.tx_start;
            tr.rx_start    = uif.rx_start;
            tr.tx_data     = uif.tx_data;
            tr.baud        = uif.baud;
            tr.data_len    = uif.data_len;
            tr.parity_type = uif.parity_type;
            tr.parity_en   = uif.parity_en;
            tr.stop2       = uif.stop2;
           @(negedge uif.rx_done);
            tr.rx_data     = uif.rx_data;
           `uvm_info("MON", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d", tr.baud, tr.data_len, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_data), UVM_NONE);
          send_port.write(tr);
         end
    
    end
   endtask 

endclass : monitor

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------- scoreboard--------------------------------------------------------------------------------//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class scoreboard extends uvm_scoreboard;
`uvm_component_utils(scoreboard)
 
  uvm_analysis_imp#(transaction,scoreboard) recv_port;
  
 
 
 
    function new(input string path = "scoreboard", uvm_component parent = null);
    super.new(path,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    recv_port = new("recv_port", this);
    endfunction
    
    
  virtual function void write(transaction tr);
    `uvm_info("SCO", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d", tr.baud, tr.data_len, tr.parity_type, tr.parity_en, tr.stop2, tr.tx_data, tr.rx_data), UVM_NONE);
    if(tr.rst == 1'b0)
      `uvm_info("SCO", "System Reset", UVM_NONE)
    else if(tr.tx_data == tr.rx_data)
      `uvm_info("SCO", "Test Passed", UVM_NONE)
    else
      `uvm_info("SCO", "Test Failed", UVM_NONE)
    $display("----------------------------------------------------------------");
    endfunction
 
endclass :scoreboard

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------Agent--------------------------------------------------------------------------------//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
`uvm_component_utils(agent)


function new(input string path = "agent", uvm_component parent = null);
    super.new(path,parent);
endfunction
uvm_sequencer#(transaction) seqr;
driver drv;
monitor mon;
uart_config cfg;    
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = uart_config :: type_id::create("cfg");
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

endclass : agent
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------Environment------------------------------------------------------------------------------//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//----------------------------------------TEST------------------------------------------------------------------------------//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class test extends uvm_test;
`uvm_component_utils(test)
function new(input string path = "test", uvm_component parent = null);
    super.new(path,parent);
endfunction

env e;  
rand_baud_1 rb1;    //random baud fix len =8 1 stop
rand_baud_2 rb2;    //random baud fix len =8 2 stop
rand_baud_5wp rb5wp;// random baud len = 5 with par
rand_baud_6wp rb6wp;
rand_baud_7wp rb7wp;
rand_baud_5wop rb5wop;
rand_baud_6wop rb6wop;
rand_baud_7wop rb7wop;


virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e= env::type_id::create("e",this);  
rb1 = rand_baud_1 :: type_id::create("rb1");
 rb2 =rand_baud_2 :: type_id::create("rb2");  
 rb5wp = rand_baud_5wp:: type_id::create("rb5wp");  
rb6wp = rand_baud_6wp ::type_id::create(" rb6wp");
rb7wp = rand_baud_7wp ::type_id::create(" rb7wp");
rb5wop = rand_baud_5wop:: type_id::create("rb5wop");  
rb6wop = rand_baud_6wop ::type_id::create(" rb6wop");
rb7wop = rand_baud_7wop ::type_id::create(" rb7wop");

endfunction

virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
rb1.start(e.a.seqr);
#20
phase.drop_objection(this);
endtask 

endclass : test
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////
//---------------------TB TOP -----------------------------------------
///////////////////////////////////////////////////////////////
module uart_tb_uvm(

    );
 uart_if uif();
    
 uart_top dut(
.clk(uif.clk),
.baud(uif.baud),
.rst(uif.rst),
.tx_start(uif.tx_start),
.tx_data(uif.tx_data),
.parity_en(uif.parity_en),
.parity_type(uif.parity_type),
.data_len(uif.data_len),
.stop2(uif.stop2),
.tx_done(uif.tx_done),
.tx_err(uif.tx_err),
.rx_start(uif.rx_start),
.rx_data(uif.rx_data),
.rx_done(uif.rx_done),
.rx_err(uif.rx_err)

    );   
    
    initial begin
        uif.clk =0;
    end
    always #10 uif.clk =~uif.clk;
    
    initial begin
        uvm_config_db#(virtual uart_if)::set(null,"*","uif",uif);
        run_test("test");
    end
endmodule
