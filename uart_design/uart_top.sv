`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2023 05:37:50 PM
// Design Name: 
// Module Name: uart_top
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


module uart_top(
input clk,
input [16:0] baud,
input rst,
input tx_start,
input [7:0] tx_data,
input parity_en,
input parity_type,
input [3:0] data_len,
input stop2,
output reg tx_done,
output reg tx_err,
input rx_start,
output reg [7:0] rx_data,
output reg rx_done,
output reg rx_err

    );
    
  wire tx_clk,rx_clk;
  wire tx_rx;  
 clk_gen clk_gen_1 (.clk(clk),.rst(rst),.baud(baud),.tx_clk(tx_clk),.rx_clk(rx_clk));
 
uart_tx tx_1 (
.tx_clk(tx_clk),
.rst(rst),
.tx_start(tx_start),
.tx_data(tx_data),
.parity_en(parity_en),
.parity_type(parity_type),
.data_len(data_len),
.stop2(1'b0),
.tx_done(tx_done),
.tx(tx_rx),
.tx_err(tx_err)
 );  
 uart_rx rx_1(
.rx_clk(rx_clk),
.rst(rst),
.rx_start(rx_start),
.rx(tx_rx),
.parity_en(parity_en),
.parity_type(parity_type),
.data_len(data_len),
.stop2(stop2),
.rx_data(rx_data),
.rx_done(rx_done),
.rx_err(rx_err));
 
endmodule

//--------------------Interface-----------------------------------
interface uart_if ();

logic clk;
logic [16:0] baud;
logic rst;
logic tx_start;
logic [7:0] tx_data;
logic parity_en;
logic parity_type;
logic [3:0] data_len;
logic stop2;
logic tx_done;
logic tx_err;
logic rx_start;
logic [7:0] rx_data;
logic rx_done;
logic rx_err;

    
endinterface
