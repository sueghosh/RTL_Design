`timescale 1ns / 1ps


 
module pwm_updown(
input clk, rst, 
output reg dout
);
 
parameter period = 100;
integer count = 0;
integer ton   = 0;
reg ncyc      = 1'b0;
reg flag     = 1'b0;
 
always@(posedge clk)
begin
     if(rst == 1'b1)
        begin
         count <= 0;
         ton   <= 0;
         ncyc  <= 1'b0;
        end   
     else 
       begin
            if(count <= ton) 
              begin
              count <= count + 1;
              dout  <= 1'b1;
              ncyc  <= 1'b0;
              end
            else if (count < period)
              begin
              count <= count + 1;
              dout <= 1'b0;
              ncyc <= 1'b0;
              end
            else
               begin
               ncyc  <= 1'b1;
               count <= 0;
               end
       end
end
 
always @ (posedge clk)
begin
    if(ton == 0)
        flag <= 0;
    else if (ton == period)  
        flag <= 1; 
    else
        flag <= flag;    
end
 
always@(posedge clk)
begin
     if(rst == 1'b0) 
     begin 
             if(ncyc == 1'b1)
                begin
                    if(ton < period && (!flag))
                       ton <= ton + 5;
                     else if (ton < period && (flag))
                       ton <= ton - 5;
                     else begin
                       ton <= ton-5;
                     end //case when ton == period  
                      
                end
     end   
end
 
 
 
endmodule
