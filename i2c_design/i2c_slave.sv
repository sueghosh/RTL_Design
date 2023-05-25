`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2023 06:26:15 PM
// Design Name: 
// Module Name: i2c_slave
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


module i2c_slave(
 input rst_n,
 input scl,
 inout sda,
 output reg err
    );
    
reg [7:0] mem [127:0];
reg [3:0] state;
reg [6:0] addr;
reg [7:0] rd_data;
reg [7:0] wr_data;
reg wr;
reg [3:0] bit_cnt;
reg sda_en =0;
wire start;
reg sdat;
//ideally if stop not detected i2c slave can keep accepting more transaction but here for simplicity 
// it transitions to error state if stop bit not detected

parameter idle=0,start_tr=1,store_addr=2,send_ack=3,store_data=4,wait_data = 5,wr_ack=6,
send_data=7,wait_stop =8,det_stop=9,err_state=10;

assign start = (state == idle) & scl &(!sda);
assign sda = (sda_en == 1'b1) ? sdat : 1'bz;


always @(negedge scl or negedge rst_n )
begin
    if(!rst_n) begin
       state <= idle; 
       addr <=0;
       rd_data <=0;
       wr <=0;
       bit_cnt <=0;
       err <=0;
       for(integer i=0;i<128;i=i+1)
        mem[i]<=8'd0;
       //sda_en <= 0; 
    end
    else begin
        case(state)
        idle:begin
            if(sda)
                state <=idle;
            else if(!sda)begin
                    state <= start_tr;
                    bit_cnt <= 0;
                    //sda_en <=0;
                end
        end
        start_tr:begin
            addr[bit_cnt]<=sda;
            state <= store_addr;
            //sda_en <=1'b0;
            bit_cnt <= 1;
        end
        store_addr:begin
            if(bit_cnt < 7)begin
                addr[bit_cnt]<=sda;
                bit_cnt <= bit_cnt +1;
            end  
            else begin
                wr <= sda;
                state <= send_ack;
                bit_cnt <= 0;
                //sda_en <= 1'b1; //enable sda to drive ack
                //if(!sda) rd_data <= mem[addr];
                end
                   
            end 
        send_ack:begin
            //sda_en <= 0; 
            rd_data <= mem[addr];
            if(wr) begin 
                state <= wait_data;
                //sda_en <=0;
             end   
            else state <= send_data;
        end
        wait_data:begin
            state <= store_data;
        end
        store_data:begin
            if(bit_cnt < 7)begin
                wr_data[bit_cnt]<=sda;
                bit_cnt <= bit_cnt +1;
            end  
            else begin
               wr_data[bit_cnt]<=sda;
                bit_cnt <= 0;
                state <= wr_ack;
                //sda_en <=1; //to drive ack in sda bus 
            end
        end
        wr_ack:begin
            mem[addr] <= wr_data;
            state <= wait_stop;
           // sda_en <= 0;
        end
        wait_stop: begin
            state <= det_stop;
        end
        send_data:begin
            if(bit_cnt<7) begin
                bit_cnt <= bit_cnt +1;
                //sda_en <=1;
             end 
             else begin
                //sda_en <=0;
                bit_cnt <=0;
                state <= det_stop;
                //sda_en <=0;
             end
                  
        end
        det_stop:begin
            if(sda)
                state <= idle;
            else
                state <= err_state;    
        end
        err_state: begin
            err <= 1'b1;
            state <= idle;
        end
        default : begin
        end
        endcase
    end
end    
 

always @(posedge scl or negedge rst_n)
begin
    if(!rst_n)begin
        sdat <= 0;
        sda_en <=0;
    end    
    else if ((state == send_ack) || (state == wr_ack) )begin
        sdat <= 0;
        sda_en <=1;
    end    
    else if (state == send_data)begin
        sdat <= rd_data[bit_cnt];  
        sda_en <= 1;
    end  
    else
        sda_en <=0;
          
end    
endmodule
