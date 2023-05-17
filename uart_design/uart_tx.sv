`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2023 06:52:18 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx(
input tx_clk,
input rst,
input tx_start,
input [7:0] tx_data,
input parity_en,
input parity_type,
input [3:0] data_len,
input stop2,
output reg tx_done,
output reg tx,
output reg tx_err

    );
    
parameter idle =0,start =1,send_data=2,send_par=3,send_stop1=4,send_stop2=5,done=6;  

reg [2:0] state;

reg [3:0] count=0;

reg parity_bit =0;

// -------------------Parity Gen---------------------------------------------------
always@(*)
    begin
       if(parity_type == 1'b1) ///odd
         begin
            case(data_len)
              4'd5 : parity_bit = ^(tx_data[4:0]); //xor
              4'd6 : parity_bit = ^(tx_data[5:0]); 
              4'd7 : parity_bit = ^(tx_data[6:0]);
              4'd8 : parity_bit = ^(tx_data[7:0]);
              default : parity_bit = 1'b0; 
              endcase
         end
        else
         begin
            case(data_len)
              4'd5 : parity_bit = ~^(tx_data[4:0]);//xnor
              4'd6 : parity_bit = ~^(tx_data[5:0]); 
              4'd7 : parity_bit = ~^(tx_data[6:0]);
              4'd8 : parity_bit = ~^(tx_data[7:0]);
              default : parity_bit = 1'b0; 
              endcase
         end 
    end
    
    
//--------------------------------------TX FSM---------------------------------------------------    
always@(posedge tx_clk or negedge rst) begin
if(!rst) begin
    state <= idle;
    tx_done <=0;
    tx<=1'b1;
    tx_err <=1'b0;
end
else begin
    case(state)
     idle: begin
        if(tx_start)begin
            state <= start;
            tx<=1'b0;
            end
        else 
            state <= idle; 
         
     end
     start:begin
            tx_done <= 1'b0;
            state <= send_data;
            tx <= tx_data[count];
            count <= count+1;
            
     end
     send_data:begin
     tx_done <= 1'b0;
     if (count < data_len) begin
            state <= send_data;
            tx <= tx_data[count];
            count <= count+1;
     end
     else if (parity_en) begin
            state <= send_par;
            tx <= parity_bit;
            count <= 0; 
     end
     else begin
            state <= send_stop1;
            tx <= 1'b1;
            count <= 0; 
     end
     end
     send_par:begin
            state <= send_stop1;
            tx <= 1'b1;
     end
     send_stop1:
     if(stop2)  begin
            state <= send_stop2;
            tx <= 1'b1;  
               
     end
     else begin
            state <= done;
            tx_done <= 1'b1;
     end
     send_stop2:begin
            state <= done;
            tx_done <= 1'b1;
     end
     done:
     if(tx_start)begin
            state <= start;
            tx<=1'b0;
            tx_done <= 1'b0;
            end
     else begin
            state <= idle; 
            tx<=1'b1;
            tx_done <= 1'b0;
          end
     default : begin
         state <= idle;
         tx_done <=0;
         tx<=1'b1;
         tx_err <=1'b0;
     end
 
 
endcase
    
end

end
    
endmodule
