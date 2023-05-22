`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2023 02:25:54 PM
// Design Name: 
// Module Name: spi_mem_ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Master
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_mem_ctrl(
input clk,
input rst_n,
input [7:0] addr,
input [7:0] wr_data,
input tr_start, //ready to start memory transaction
input wr, //wr =0 --> read wr =1 --> write 
output reg tr_done, //asserted when one mem transaction is done
output reg [7:0] read_data,
// SPI interface to mem
output wire sclk,
output reg mosi,
input miso,
output reg cs,
// Additional control signal added for better handshake 
input mem_ready,
input mem_done,
output reg spi_err

    );
    
parameter idle = 0,check_op =1, send_wr=2, rd_addr=3, rcv_data=4,done=5;
reg [2:0] state;
reg [4:0] bit_cnt;
reg [16:0] data_reg; // stores the {data,addr,rw} once the tr_start is detected
reg [7:0] mem_data;
reg sclk_t;
assign sclk = (state == idle)? sclk_t:clk;
// FSM
always @(posedge clk or negedge rst_n)  begin
    if(!rst_n)begin
        state <= idle;
        cs <= 1'b1;
        sclk_t <= 1'b0;
        mosi <= 1'b0;
        spi_err <= 1'b0;
        tr_done <= 1'b0;
        data_reg <= 17'd0;
        mem_data <= 8'd0;
        bit_cnt <= 5'd0;
        read_data <= 8'd0;
        
    end
    else begin
    case(state)
    idle:begin
        tr_done <= 1'b0;
        mem_data <= 8'd0;
        bit_cnt <= 5'd0;
        read_data <= 8'd0;
        if(tr_start) begin
        state <= check_op;
        cs <= 1'b0;
        //sclk <= clk;
        data_reg <= {wr_data,addr,wr};
    end
        else begin
        state <=idle;
        data_reg <= 17'd0;
        end
    end
    check_op: begin
        if(data_reg[8:1] < 8'd32) begin
            cs <= 1'b0;
            bit_cnt <= bit_cnt+1;
            mosi <= data_reg[bit_cnt];
            if (data_reg[0])  //wr op
                state <= send_wr;
            else
                state <=rd_addr;
         end  
         else begin
            spi_err <=1'b1;
            tr_done <=1'b1;
            state <= idle;
         end     
    end
    send_wr: if(bit_cnt < 17 ) begin
                mosi <= data_reg[bit_cnt];
                bit_cnt <= bit_cnt +1;
            end    
            else begin
                if(mem_done) begin
                    tr_done <= 1'b0;
                    state <= done;
                    bit_cnt <= 0;
                    cs <= 1'b1;
                end 
                else begin
                    state <= send_wr;
                    bit_cnt <= bit_cnt;
                end
            end 
    rd_addr:
            if(bit_cnt < 8 ) begin
                mosi <= data_reg[bit_cnt]; // send addr + rw
                bit_cnt <= bit_cnt +1;
            end    
            else begin
                if(mem_ready) begin
                    state <= rcv_data;
                    bit_cnt <=0;
                    end
                else
                    state <= rd_addr;    
            end 
        
    rcv_data:if(bit_cnt < 8) begin
                mem_data[bit_cnt] <= miso; // ideally it should be sampled at negedge of clk -- need to enhance
                bit_cnt <= bit_cnt +1;
            end    
            else begin
                tr_done <= 1'b0;
                state <= done;
                bit_cnt <= 0;
                cs <= 1'b1;
                read_data <=mem_data;
            end 
    done: begin
        state <= idle;
        tr_done <=1'b1;
    end        
    default: begin
        state <= idle;
        cs <= 1'b1;
        sclk_t <= 1'b0;
        mosi <= 1'b0;
        spi_err <= 1'b0;
        tr_done <= 1'b0;
        data_reg <= 17'd0;
        mem_data <= 8'd0;
        bit_cnt <= 5'd0;
        read_data <= 8'd0;
    end        
    endcase
    end
        
end
  
endmodule
