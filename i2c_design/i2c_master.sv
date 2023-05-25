`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2023 05:31:55 PM
// Design Name: 
// Module Name: i2c_master
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


module i2c_master
  (
 input clk,
 input rst_n,
 input newd,
 //input ack,
 input wr,   // wr =1 -> write wr=0 -> read
 output scl,
 inout sda,
 input [7:0] wdata, // 8 bit data
 input [6:0] addr, /////  7-bit : addr 
 output reg [7:0] rdata,
 output reg done,
 output reg err
 //output reg sclk_ref //slower clk generated from original system_clk clk
  );
  
 reg sda_en = 0;
 reg ack;
 reg sclt, sdat, donet; 
 reg [7:0] rdatat; 
 reg [7:0] addrt;
 
  
parameter idle = 0,  start = 1,check_wr = 2, wsend_addr = 3, waddr_ack = 4, 
                wsend_data = 5, wdata_ack = 6, wstop = 7, rsend_addr = 8, 
                raddr_ack = 9, rcv_data = 10,
                 rstop = 11 ;
  
  
  
  
  reg [3:0] state;
  //reg sclk_ref = 0;
  integer count = 0;
  integer i = 0;
  reg sclk_ref;
  ////100 M / 400 K = N
  ///N/2
  
  
  always@(posedge clk or negedge rst_n)
  if(!rst_n)
  begin
    count <= 0;
    sclk_ref <=0;
  end
  else
    begin
      if(count <= 9) 
        begin
           count <= count + 1;     
        end
      else
         begin
           count     <= 0; 
           sclk_ref  <= ~sclk_ref;
         end	      
    end
  // Using the negedge of sclk_ref to read the ack from sda 
  always@(negedge sclk_ref, negedge rst_n)
  begin
    if(!rst_n)
        ack <= 1'b1;
    else if ((state == wdata_ack)||(state == waddr_ack)||(state == raddr_ack))
        ack <= sda;
    else if (state == rcv_data) 
        rdata [i] <= sda;    
  end
  // All sda and scl are driven at posedge of sclk_ref
   always@(posedge sclk_ref, posedge rst_n)
    begin 
      if(rst_n == 1'b0)
         begin
           sclt  <= 1'b0;
           sdat  <= 1'b0;
           donet <= 1'b0;
           state <=idle;
           sda_en <=1;
         end
       else begin
         case(state)
           idle : 
           begin
              
              done <= 1'b0;
              sda_en  <= 1'b1;
              sclt <= 1'b1;
              sdat <= 1'b1;
              err <=0;
             if(newd == 1'b1) 
                state  <= start;
             else 
                 state <= idle;         
           end
         
            start: 
            begin
              sdat  <= 1'b0;
              sclt  <= 1'b1;
              state <= check_wr;
              addrt <= {wr,addr};
            end
            check_wr: begin
                ///addr remain same for both write and read
              if(wr == 1'b1) 
                 begin
                 state <= wsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
               else 
                 begin
                 state <= rsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
            end
         
            wsend_addr : begin                
                      if(i <= 7) begin
                      sdat  <= addrt[i];
                      i <= i + 1;
                      end
                      else
                        begin
                          i <= 0;
                          state <= waddr_ack; 
                          sda_en  <= 1'b0;
                        end   
                    end
         
         
           waddr_ack : begin
             if(ack == 1'b0) begin
               state <= wsend_data;
               sda_en  <= 1'b1;
               //sdat  <= wdata[0];
               //i <= i + 1;
               end
             else
                state <= idle; //abort communication if ack is not received
               //state <= waddr_ack;
           end
         
         wsend_data : begin
           if(i <= 7) begin
              i     <= i + 1;
              sdat  <= wdata[i]; 
           end
           else begin
              i     <= 0;
              state <= wdata_ack;
              sda_en  <= 1'b0;
           end
         end
         
          wdata_ack : begin
             if(ack == 1'b0) begin
               state <= wstop;
               sda_en  <= 1'b1;
               sdat <= 1'b0;
               sclt <= 1'b1;
               end
             else begin
                state <= idle; //abort communication if ack is not received
               //state <= wdata_ack;
             end 
            end
         
              
         
         wstop: begin
              sdat  <=  1'b1;
              state <=  idle;
              done  <=  1'b1;  
         end
         
         ///////////////////////read state
         
         
          rsend_addr : begin
                     if(i <= 7) begin
                      sdat  <= addrt[i];
                      i <= i + 1;
                      end
                      else
                        begin
                          i <= 0;
                          state <= raddr_ack; 
                          sda_en  <= 1'b0;
                        end   
                    end
         
         
           raddr_ack : begin
             if(ack == 1'b0) begin
               state  <= rcv_data;
               sda_en <= 1'b0;
             end
             else
               state <= rstop; //abort communication if ack is not received
           end
         
         rcv_data : begin
                   if(i < 7) begin
                         i <= i + 1;
                         state <= rcv_data;
                         //rdata[i] <= sda;
                      end
                      else
                        begin
                          i <= 0;
                          state <= rstop;
                          sda_en <=1;
                          sclt <= 1'b1;
                          sdat <= 1'b0;  
                        end         
         end
          
        
         
         
         rstop: begin
              sdat  <=  1'b1;
              state <=  idle;
              done  <=  1'b1;  
              end
         
         
         default : state <= idle;
         
          	 endcase
          end
  end
  /*
  always@(posedge sclk_ref, negedge rst_n)
    begin 
      if(!rst_n == 1'b1)
         begin
           sclt  <= 1'b0;
           sdat  <= 1'b0;
           donet <= 1'b0;
           err <= 1'b0;
           sda_en <=1'b1;
           state <= idle;
         end
       else begin
         case(state)
           idle : 
           begin
              sdat <= 1'b0;
              done <= 1'b0;
              sda_en  <= 1'b1;
              sclt <= 1'b1;
              sdat <= 1'b1;
              err <= 1'b0;
             if(newd == 1'b1) begin
                state  <= start;
                sdat  <= 1'b0;
                sclt  <= 1'b1;
                sda_en <= 1'b1;
                addrt <= {wr,addr};
             end   
             else 
                 state <= idle;         
           end
         
            start: 
            begin
              if(wr == 1'b1) 
                 begin
                 state <= wsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
               else 
                 begin
                 state <= rsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
              
              
            end */
           /* check_wr: begin
                ///addr remain same for both write and read
              if(wr == 1'b1) 
                 begin
                 state <= wsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
               else 
                 begin
                 state <= rsend_addr;
                 sdat <= addrt[0];
                 i <= 1;
                 end
            end*/
 /*        
            wsend_addr : begin                
                      if(i < 8) begin
                        sdat  <= addrt[i];
                        if(i==7) begin
                          i <= 0;
                          state <= waddr_ack; 
                          sda_en  <= 1'b0;
                        end
                        else
                            i <= i + 1;
                      end
                    end
         
           waddr_ack : begin
             if(ack == 1'b0) begin
               state <= wsend_data;
               sda_en  <= 1'b1;
               sdat  <= wdata[0];
               i <= 1;
               end
             else
                state <= wstop; //abort communication if ack is not received
                err <= 1'b1;
               //state <= waddr_ack;
           end
         
         wsend_data : begin
           if(i < 8) begin
              i     <= i + 1;
              sdat  <= wdata[i]; 
           end
           else begin
              //sdat  <= wdata[i];  
              i     <= 0;
              state <= wdata_ack;
              sda_en  <= 1'b0;
           end
         end
         
          wdata_ack : begin
             if(ack == 1'b0) begin
               state <= wstop;
               sda_en  <= 1'b1;
               sdat <= 1'b0;
               sclt <= 1'b1;
               end
             else begin
                state <= idle; //abort communication if ack is not receive
                err <= 1'b1;
               //state <= wdata_ack;
             end 
            end
         
              
         
         wstop: begin
              sdat  <=  1'b1;
              state <=  idle;
              done  <=  1'b1;  
         end
         
         ///////////////////////read state
         
         
          rsend_addr : begin                
                      if(i < 8) begin
                      sdat  <= addrt[i];
                      i <= i + 1;
                      
                      end
                      else
                        begin
                          //sdat  <= addrt[i];  
                          i <= 0;
                          state <= raddr_ack; 
                          sda_en  <= 1'b0;
                        end   
                    end
         
           raddr_ack :begin
             if(ack == 1'b0) begin
               state <= rcv_data;
               sda_en  <= 1'b0;
               end
             else
                state <= rstop; //abort communication if ack is not received
                err <= 1'b1;
           end
         
         rcv_data : begin     
                   if(i <= 7) begin
                         i <= i + 1;
                         state <= rcv_data;
                         //rdata[i] <= sda; // data is received at negedge 
                      end
                      else
                        begin
                          i <= 0;
                          state <= rstop;
                          sclt <= 1'b1;
                          sdat <= 1'b0; 
                          sda_en <=1'b1; 
                        end         
         end
          
        
         
         
         rstop: begin
              sdat  <=  1'b1;
              state <=  idle;
              done  <=  1'b1;  
              end
         
         
         default : state <= idle;
         
          	 endcase
          end
  end
  */
 assign scl = (( state == start) ) ? sclt : sclk_ref;
 assign sda = (sda_en == 1'b1) ? sdat : 1'bz;
endmodule
