//serial CRC 16 
// polynomial : x^16 + x^12 + x^5 +1
//initial seed is FFFF
module crc16_serial (in,clk,rst,crc);
  input in;
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
          lfsr[0] <= in ^ lfsr[15];
          lfsr[1] <= lfsr[0];
          lfsr[2] <= lfsr[1];
          lfsr[3] <= lfsr[2];
          lfsr[4] <= lfsr[3];
          lfsr[5] <= lfsr[4] ^ in ^ lfsr[15];
          lfsr[6] <= lfsr[5];
          lfsr[7] <= lfsr[6];
          lfsr[8] <= lfsr[6];
          lfsr[9] <= lfsr[8];
          lfsr[10] <= lfsr[9];
          lfsr[11] <= lfsr[10];
          lfsr[12] <= lfsr[11] ^ in ^ lfsr[15];
          lfsr[13] <= lfsr[12];
          lfsr[14] <= lfsr[13];
          lfsr[15] <= lfsr[14];
        end
    end
  
endmodule
