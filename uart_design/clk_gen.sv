`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2023 06:51:43 PM
// Design Name: 
// Module Name: clk_gen
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


module clk_gen(
input clk,
input rst,
input [16:0] baud,
output reg tx_clk,
output reg rx_clk

    );
    
    
//Assuming system clk is 50 Mhz calcuting tx_count,rx_count to generate slower clk
//Supporte Baud 4800,9600,14400,19200,38400,57600,115200,128000

//Calculate max tx_count and rx_count for each baud 
//Assuming Rx_clk is 16 times faster than tx_clk
integer tx_cnt_max,rx_cnt_max;
always @(*) begin
case(baud)
    4800:begin 
            tx_cnt_max = 10416;
            rx_cnt_max = 651; 
         end
    9600:begin 
            tx_cnt_max = 5208;
            rx_cnt_max = 326; 
         end
    14400:begin 
            tx_cnt_max = 3472;
            rx_cnt_max = 216; 
         end
    19200:begin 
            tx_cnt_max = 2604;
            rx_cnt_max = 162; 
         end
    38400:begin 
            tx_cnt_max = 1302;
            rx_cnt_max = 80; 
         end
    57600:begin 
            tx_cnt_max = 868;
            rx_cnt_max = 54; 
         end
    115200:begin 
            tx_cnt_max = 434;
            rx_cnt_max = 27; 
         end
    128000:begin 
            tx_cnt_max = 390;
            rx_cnt_max = 24; 
         end
    default:begin 
            tx_cnt_max = 5208;
            rx_cnt_max = 326; 
         end    
    
endcase
end  
reg [13:0] tx_cnt,rx_cnt;
//Generate tx_clk 
always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        tx_cnt <= 0;
        tx_clk <=0;
    end
    else if(tx_cnt < tx_cnt_max/2)
    begin
        tx_cnt <= tx_cnt +1;
    end
    else begin
        tx_cnt <=0;
        tx_clk = ~tx_clk;
    end
end
 //Generate rx_clk 
 always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        rx_cnt <= 0;
        rx_clk <=0;
    end
    else if(rx_cnt < rx_cnt_max/2)
    begin
        rx_cnt <= rx_cnt +1;
    end
    else begin
        rx_cnt <=0;
        rx_clk = ~rx_clk;
    end
end
endmodule
