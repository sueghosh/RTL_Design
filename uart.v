`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/20/2023 11:08:41 AM
// Design Name: 
// Module Name: uart
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


module uart(
input clk,
    input start,
    input [7:0] txin,
    output reg tx, 
    input rx,
    output [7:0] rxout,
    output reg rxdone, 
    output reg txdone
    );

parameter clk_rate = 100000;
parameter baud_rate = 9600; 
parameter wait_count = clk_rate/baud_rate;
parameter half_wait_count = wait_count/2;
reg baud_pulse=0,baud_pulse_mid=0; //generating trigger at the end of baud and at the middle
integer count=0;
reg [1:0] tx_state;

parameter idle =0,send = 1,wait_baud =2;
//Generate pulse for baud rate

always @(posedge clk)
begin
if( tx_state == idle)begin
    baud_pulse <=0;
    count <=0;
    end
else if (count == wait_count)begin
    baud_pulse <=1;
    count <=0;
    end
else begin
    baud_pulse <=0;
    count <= count+1;
    end    
end
always @(posedge clk)
begin
if( tx_state == idle)
    baud_pulse_mid <=0;
else if (count == half_wait_count)
    baud_pulse_mid <=1;
else baud_pulse_mid <=0;    
end

 // TX fsm
 reg [9:0] txData; //contains {stop,data[7:0],start} bits
 reg [3:0] bitIndex;
 //reg tx_done;
 always @(posedge clk)
 begin
 case (tx_state)
    idle: begin
        tx       <= 1'b1;
        txData   <= 0;
        bitIndex <= 0;
        txdone <=0;
        if(start) begin
            txData <= {1'b1,txin,1'b0};
            tx_state <= send;
        end 
        else
            tx_state <= idle;
    end
    send: begin
        tx <= txData[bitIndex];
        bitIndex <= bitIndex+1;
        tx_state <= wait_baud;
    end
    wait_baud:begin
        if(baud_pulse)begin
            if(bitIndex < 10)
                tx_state <= send;
            else begin
                bitIndex <= 0;
                tx_state <= idle;
                tx <= 1'b1;
                txdone <= 1;
            end
        end
        else begin
            tx_state <= wait_baud;
        end
    end
    default: begin
        tx       <= 1'b1;
        txData   <= 0;
        bitIndex <= 0;
        tx_state <= idle;
        txdone <=0;
    end
 endcase
 end
 
 //assign txdone = (bitIndex == 9 && baud_pulse == 1'b1) ? 1'b1 : 1'b0;
 //Rx fsm : receives data at the middle of baud rate
 ////////////////////////////////RX Logic
 integer rcount = 0;
 integer rindex = 0;
 parameter ridle = 0, rwait = 1, recv = 2;
 reg [1:0] rxstate;
 reg [9:0] rxdata;
 always@(posedge clk)
 begin
 case(rxstate)
 ridle : 
     begin
      rxdata <= 0;
      rindex <= 0;
      rcount <= 0;
      rxdone <=0;
      if(rx == 1'b0)
      begin
        rxstate <= rwait;
      end
      else
      begin
        rxstate <= ridle;
      end
     end
     
rwait : 
begin
      if(!baud_pulse_mid)
         begin
          rcount <= rcount + 1;
          rxstate <= rwait;
         end
     else
       begin
          rcount <= 0;
          rxstate <= recv;
          rxdata <= {rx,rxdata[9:1]}; 
          rindex <= rindex+1;
       end
end
 
 
recv : 
begin
     
     if(baud_pulse == 1'b1) begin
       if(rindex < 10)
         rxstate <= rwait;
       else
        begin
         rxstate <= ridle;
         rindex <= 0;
         rxdone <=1;
        end 
      end
     else 
        begin
         rxstate <= recv; //wait for baud_pulse
        end
end
 
 
default : rxstate <= ridle;
 
 
 endcase
 end
 
 
assign rxout = rxdata[8:1]; 
//assign rxdone = (rindex == 9 && baud_pulse == 1'b1) ? 1'b1 : 1'b0;
 
endmodule
