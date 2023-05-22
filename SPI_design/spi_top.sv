`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2023 02:27:16 PM
// Design Name: 
// Module Name: spi_top
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


module spi_top(
input clk,
input rst_n,
input [7:0] addr,
input [7:0] data_in,
input wr, // wr =0 --> read wr =1 --> write 
output [7:0] data_out,
input ready,
output done,
output spi_err

    );
   
  wire mem_done,mem_ready,mosi,miso,sclk,cs;
    
 spi_mem_ctrl master (
.clk(clk),
.rst_n(rst_n),
.addr(addr),
.wr_data(data_in),
.tr_start(ready),
.wr(wr), 
.tr_done(done), //asserted when one mem transaction is done
.read_data(data_out),
// SPI interface to mem
.sclk(sclk),
.mosi(mosi),
 .miso(miso),
.cs(cs),
// Additional control signal added for better handshake 
.mem_done(mem_done),
.mem_ready(mem_ready),
.spi_err(spi_err) );
 
spi_mem slave(
.sclk(sclk),
.rst_n(rst_n),
.mosi(mosi),
.cs(cs),
.miso(miso),
.mem_ready(mem_ready),
.mem_done(mem_done)

    );  
    
endmodule

//Interface
interface spi_mem_if();

logic clk;
logic rst_n;
logic [7:0] addr;
logic [7:0] data_in;
logic wr; // wr =0 --> read wr =1 --> write 
logic [7:0] data_out;
logic ready;
logic done;
logic spi_err;

endinterface
