module async_fifo (wrclk,wrrst,push,datain,full, rdclk,rdrst,pop,dataout,empty);
parameter WIDTH = 8, DEPTH = 16;
localparam AWIDTH = $clog2(DEPTH);
input wrclk,wrrst,push,rdclk,rdrst,pop;
input [WIDTH-1:0] datain;
output reg full,empty;
output [WIDTH-1:0] dataout;
reg [AWIDTH:0] wrptr,rdptr; // keeping one extra bit to distinguish between empty and full condition
reg [AWIDTH:0] wrptr_sync1,rdptr_sync1,wrptr_sync2,rdptr_sync2;
reg [WIDTH-1:0] mem [DEPTH-1:0];
wire [AWIDTH:0] rdptr_gray_next, wrptr_gray_next;
  
  
integer i;
//initialize mem
initial begin
  for(i=0; i<DEPTH; i=i+1)
    mem[i] = 0;
end
  
//Push the data in FIFO
  always@(posedge wrclk) begin
  if(push && ~full) mem[wrptr]<=datain;
end
  
//wrprt logic
  always @(posedge wrclk or negedge wrrst) begin
  if(!wrrst)
    wrptr <=0;
  else if (push && !full)
    wrptr <= wrptr +1;
end
assign rdptr_gray_next = rdptr ^ (rdptr>>1);
assign wrptr_gray_next = wrptr ^ (wrptr>>1);
  
//full logic : Have to compare rdptr in wr clk domain
// so used 2 sync flops and converted binary rdptr to gray to minimize //metastability condition and false full flag
always @ (posedge wrclk or negedge wrrst) begin
  if(!wrrst) begin
    rdptr_sync1 <= 0;
    rdptr_sync2 <= 0;
  end
  else begin
    rdptr_sync1 <= rdptr_gray_next; //convert rdptr to gray 
    rdptr_sync2 <= rdptr_sync1;
  end
end
  
  // Full signal 
always@(posedge wrclk or negedge wrrst) begin
  if(!wrrst) full <= 1'b0;
  else if ((wrptr_gray_next[AWIDTH:AWIDTH-1] != rdptr_sync2[AWIDTH:AWIDTH-1]) && (wrptr_gray_next[AWIDTH-2:0] ==rdptr_sync2[AWIDTH-2:0]) )
          full <= 1'b1;
  else full <= 1'b0;
end

// READ logic
  
      
// memory read out
assign dataout = mem[rdptr];   
 
//Read pointer logic
always @(posedge rdclk or negedge rdrst) begin
  if(!rdrst)
    rdptr <=0;
  else if (pop && !empty)
    rdptr <= rdptr +1;
end
//Sync wrptr into read domain  
always @ (posedge rdclk or negedge rdrst) begin
  if(!wrrst) begin
    wrptr_sync1 <= 0;
    wrptr_sync2 <= 0;
  end
  else begin
    wrptr_sync1 <= wrptr_gray_next; //convert rdptr to gray 
    wrptr_sync2 <= wrptr_sync1;
  end
end
// Generate empty signal
  always@(posedge rdclk or negedge rdrst) begin
    if(!rdrst) empty <= 1'b0;
    else if ( (rdptr_gray_next == wrptr_sync2) )
          empty <= 1'b1;
  else empty <= 1'b0;
end  
  
endmodule
