`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2023 06:52:46 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
input rx_clk,
input rst,
input rx_start,
input rx,
input parity_en,
input parity_type,
input [3:0] data_len,
input stop2,
output reg [7:0] rx_data,
output reg rx_done,
output reg rx_err

    );   
    
 reg parity = 0;
 parameter idle =0, start=1,rcv_data =2,chk_par = 3,rcv_stop1=4,rcv_stop2=5 , done =6;
 reg [2:0] state;  
 reg [7:0] temp_data;   // shift reg to store incoming bit stream
 reg [3:0] count;
 reg [3:0] bit_count; // bit count can 5,6,7 or 8 max depending on data_len value
 reg parity_calc;
 //Rx clk is 16 times faster than Tx clk and we are sampling the data at the middle of data transmission
 // keeping a counter which will count 0 to 15 within each tx data rcvd. when count is 7 we are sampling the data
 // Each state transition happens when counter reaches to 15
 
 always @(posedge rx_clk or negedge rst)begin
 if(!rst) begin
    state <= idle;
    temp_data <=0;
    rx_done<=1'b0;
    rx_err <=1'b0;
    count <= 16'd0;
    bit_count <= 16'd0;
    parity_calc <= 0;
end
else begin
    case(state)
        idle: begin
        rx_done <=0;
        if(rx_start && !rx) begin
            state <= start;
            count <=1; //by the time start bit is detected 1 count had already elapsed
            end
        else begin
            state <= idle;
            count <=0;
            end
        end
        start:begin
            rx_done <=0;
            if (count == 7 && rx) begin
                rx_err <= 1'b1; //start bit should be low ,if not flag error
                count <= count +1;
                state <= idle;
                end
            else if  (count == 15)begin
                state <= rcv_data;
                count <= 0;
            end   
            else begin
                count <= count +1;
            end
        end
        rcv_data:begin
            if (count == 7 && (bit_count <= data_len))begin
                temp_data <= {rx,temp_data[7:1]};
                count <= count+1;
                bit_count <= bit_count+1;
            end
            else if (count == 15 && (bit_count == data_len))begin
                case(data_len) 
                4'd5: rx_data <= {3'b0,temp_data[7:3]};
                4'd6: rx_data <= {2'b0,temp_data[7:2]};
                4'd7: rx_data <= {1'b0,temp_data[7:1]};
                4'd8: rx_data <= temp_data;
                endcase
                bit_count <= 0;
                if (parity_en) begin
                    state <= chk_par;
                    if(parity_type)
                        parity_calc <= ^temp_data;
                    else
                        parity_calc <= ~(^temp_data);    
                end
                else begin
                    state <= rcv_stop1;
                    count <= 0;
                    //bit_count <=0;
                end
            end
            else if (count == 15 && (bit_count < data_len))begin
                state <= rcv_data;
                count <= 0;
            end
            else begin 
                count <= count+1;
            end
                
                
        end
        chk_par:begin
            if (count == 7 &&(rx != parity_calc))begin
                rx_err <= 1'b1;
                count <= count +1;
                end
            else if (count == 15 )begin
                state <= rcv_stop1;
                count <= 0;
            end   
            else begin
                count <= count+1;
            end 
        end
        rcv_stop1:begin
            if (count == 7 &&(!rx))begin
                rx_err <= 1'b1;
                count <= count +1;
                end
            else if (count == 15 && rx)begin
                if(stop2)
                    state <= rcv_stop2;
                else begin
                    state <= done;
                    rx_done <=1'b1;
                    end
                count <= 0;
            end   
            else begin
                count <= count+1;
            end 
        end
        rcv_stop2:if (count == 7 &&(!rx))begin
                rx_err <= 1'b1;
                count <= count +1;
            end
            else if (count == 15 )begin
                state <= done;
                count <= 0;
                rx_done <=1'b1; //assert rx_done when transitioning to done state
            end   
            else begin
                count <= count+1;
            end 
        
        done:begin
            
            count <= count+1;
            if (count == 15 )begin
            state <= idle;
            rx_done <=0; //deassert rx_done when transitioning to idle
            count <= 0;
            end
        end
        default: begin
        state <= idle;
        temp_data <=0;
        rx_done<=1'b0;
        rx_err <=1'b0;
        count <= 16'd0;
        bit_count <= 16'd0;
        parity_calc <= 0; 
        end
        
    endcase
 end
 end
endmodule
