`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2023 06:27:05 PM
// Design Name: 
// Module Name: i2c_top
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


module i2c_top(
input clk,
 input rst_n,
 input newd,
 //input ack,
 input wr,   // wr =1 -> write wr=0 -> read
 input [7:0] wdata, // 8 bit data
 input [6:0] addr, /////  7-bit : addr 
 output reg [7:0] rdata,
 output reg done,
 output wire i2c_err
    );
 
 wire scl,sda,err_slave,err_master;   
 assign i2c_err = err_slave | err_master;
 i2c_master mem_cntrl
  (
 .clk(clk),
 .rst_n(rst_n),
 .newd(newd),
 //input ack,
 .wr(wr),   // wr =1 -> write wr=0 -> read
 .scl(scl),
 .sda(sda),
 .wdata(wdata), // 8 bit data
 .addr(addr), /////  7-bit : addr 
 .rdata(rdata),
 .done(done),
 .err(err_master));
 
 i2c_slave i2c_mem(
 .rst_n(rst_n),
 .scl(scl),
 .sda(sda),
 .err(err_slave)
    );
endmodule

interface i2c_if();
 logic clk;
 logic rst_n;
 logic newd;
 //logic ack,
 logic wr;   // wr =1 -> write wr=0 -> read
 logic [7:0] wdata;// 8 bit data
 logic [6:0] addr; /////  7-bit : addr 
 logic [7:0] rdata;
 logic done;
 logic i2c_err;
endinterface
