`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/18/2023 02:26:26 PM
// Design Name: 
// Module Name: spi_mem
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// SPI slave : memory 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_mem(
input sclk,
input rst_n,
input mosi,
input cs,
output reg miso,
output reg mem_ready,
output reg mem_done

    );
    
 parameter idle =0,check_op=1,addr_dec=2,wr_mem=3,rd_mem=4,done=5;  
 reg [2:0] state;
 reg [7:0] mem[31:0];
 reg [7:0] data_wr;
 reg [7:0] data_rd;
 reg [7:0] mem_addr;
 reg [3:0] bit_cnt;
 reg wr;
 always @(posedge sclk or negedge rst_n )
 if (!rst_n) begin
    state <=idle;
    miso <= 1'bz;
    for (integer i =0; i <32; i=i+1) begin
        mem[i] <= 8'd0;
    end
    data_rd <= 8'd0;
    data_wr <= 8'd0;
    mem_addr <=8'd0;
    bit_cnt <=0;
    mem_ready <=0;
    mem_done <=0;
 end 
 else begin
    case(state)
        idle: 
            begin
            data_rd <= 8'd0;
            data_wr <= 8'd0;
            mem_addr <=8'd0;
            bit_cnt <=0;
            mem_ready <=0;
            mem_done <=0;
            miso <= 1'bz;
            if (!cs) begin 
                state <= check_op;
                
            end   
            else state <= idle; 
            end
        check_op:
            begin 
                wr <= mosi;
                state <= addr_dec;
                bit_cnt <= 4'd0;
            end
        addr_dec:
            if (bit_cnt < 7) begin
                mem_addr[ bit_cnt] <= mosi;
                bit_cnt <= bit_cnt +1;
            end
            else begin
                if (!wr)begin
                    mem_ready <= 1'b1;
                    mem_addr[bit_cnt] <= mosi; // store the last bit of addr while decoding read or write
                    bit_cnt <=0;
                    state <= rd_mem;
                    data_rd <= mem[mem_addr];
                 end  
                 else begin
                    state <= wr_mem;
                    mem_addr[bit_cnt] <= mosi; // store the last bit of addr while decoding read or write
                    bit_cnt <=0;
                 end 
            end
        wr_mem:
            if (bit_cnt < 8) begin
                data_wr[ bit_cnt] <= mosi;
                bit_cnt <= bit_cnt +1;
            end
            else begin
                mem_done<= 1'b1;
                mem[mem_addr] <= data_wr;
                state <= done;
                bit_cnt <= 0;
                mem_ready <= 1'b0;
            end
        rd_mem:
            if (bit_cnt < 8) begin
                miso <= data_rd[bit_cnt];
                bit_cnt <= bit_cnt +1;
            end
            else begin
                mem_done<= 1'b1;
                state <= done;
                bit_cnt <= 0;
                mem_ready <= 1'b0;
            end
        done: begin
            state <= idle;
            mem_done <= 1'b0;
            
        end    
        default:
            begin
                data_rd <= 8'd0;
                data_wr <= 8'd0;
                mem_addr <=8'd0;
                bit_cnt <=0;
                mem_ready <=0;
                mem_done <=0;
                state <= idle;
                miso <= 1'bz;
            end
    endcase
 end
endmodule
