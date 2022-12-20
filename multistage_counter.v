//Multistage counter for improved timing
// 5 bit counter - using 1-2-2 bit counters
module multistage_counter_5bit(clk,reset,cnt);
  input clk,reset;
  output [4:0] cnt;
  reg [1:0] cnt_stage1;
  reg [1:0] cnt_stage2;
  reg cnt_stage3;
  wire stage2_cntrl, stage3_cntrl;
  assign stage2_cntrl =  (&cnt_stage1[1:0]);
  assign stage3_cntrl = (&cnt[3:0]);
 
  
  always @(posedge clk or negedge reset)
    begin
      if (!reset)
        begin
          cnt_stage1 <= 2'b00;
          cnt_stage2 <= 2'b00;
          cnt_stage3 <= 1'b0;
        
        end
      else
        begin
          cnt_stage1 <= cnt_stage1 + 1;
          cnt_stage2 <= stage2_cntrl ? cnt_stage2 + 1 : cnt_stage2;
          cnt_stage3 <= stage3_cntrl ? cnt_stage3 + 1 : cnt_stage3;
         
        end
    end
  assign cnt = {cnt_stage3,cnt_stage2,cnt_stage1};
  
endmodule
