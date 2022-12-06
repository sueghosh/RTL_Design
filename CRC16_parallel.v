//parallel CRC 16 
// polynomial : x^16 + x^12 + x^5 +1
//initial seed is FFFF
module crc16_parallel (in,clk,rst,crc);
  parameter DATAWIDTH = 8;
  input [DATAWIDTH-1:0]in;
  input clk,rst;
  output [15:0] crc;
  
  
  reg [15:0] lfsr;
  assign crc = lfsr;
  
  always @(posedge clk or negedge rst)
    begin
      if(!rst)
        lfsr <= 16'hFFFF;
      else
        begin
          lfsr <= calc_crc(in,crc);
          
        end
    end
  
  function [15:0]calc_crc;
    input [DATAWIDTH-1:0] data;
    input [15:0] crc;
    integer i;
    begin
      calc_crc = crc;
      for (i=0; i< DATAWIDTH; i=i+1)
        begin
          calc_crc = serial_crc16(data[DATAWIDTH-1-i],calc_crc);
        end
      
    end
  endfunction
  
  function [15:0] serial_crc16;
    input  in;
    input [15:0] lfsr;
    
    	begin
      	  serial_crc16[0] = in ^ lfsr[15];
          serial_crc16[1] = lfsr[0];
          serial_crc16[2] = lfsr[1];
          serial_crc16[3] = lfsr[2];
          serial_crc16[4] = lfsr[3];
          serial_crc16[5] = lfsr[4] ^ in ^ lfsr[15];
          serial_crc16[6] = lfsr[5];
          serial_crc16[7] = lfsr[6];
          serial_crc16[8] = lfsr[6];
          serial_crc16[9] = lfsr[8];
          serial_crc16[10] = lfsr[9];
          serial_crc16[11] = lfsr[10];
          serial_crc16[12] = lfsr[11] ^ in ^ lfsr[15];
          serial_crc16[13] = lfsr[12];
          serial_crc16[14] = lfsr[13];
          serial_crc16[15] = lfsr[14];
    end
    
  endfunction
  
endmodule
