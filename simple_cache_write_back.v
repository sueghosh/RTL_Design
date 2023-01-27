//cache block for a direct mapped cache
// WB + write allocate
//Block size = 4 words (128 bits)
// cache size 16kb -- index = 10 bits addr[13:4]
//Address =32 bits, tagsize = 18 bits addr [31:14]
// cache wrap contains the actual cache data block and cache controller

 `timescale 1 ns / 1 ps

module cache_wrap (clk,rst,cpu_req_wen,cpu_req_vld,cpu_addr,cpu_wr_data,cpu_rd_data,cpu_done,mem_req_wen,mem_req_vld,mem_addr,mem_wr_data,mem_rd_data,mem_req_done);
  
  parameter BLOCKSIZE = 128, INDEXSIZE = 10, TAGLSB = 14, TAGMSB = 31, WORDMSB = 3, WORDLSB = 2, ADDRSIZE =32, TAGSIZE =18;
  
 
  input clk, rst, cpu_req_wen, cpu_req_vld, mem_req_done;
  input [ADDRSIZE-1:0] cpu_addr;
  input [ADDRSIZE-1:0] cpu_wr_data;
  input [BLOCKSIZE-1:0] mem_rd_data;
  output cpu_done,mem_req_vld,mem_req_wen;
  output [ADDRSIZE-1:0] cpu_rd_data;
  output [ADDRSIZE-1:0] mem_addr;
  output [BLOCKSIZE-1:0] mem_wr_data;
  
  reg cpu_done,mem_req_vld,mem_req_wen;
  reg [BLOCKSIZE-1:0] cache_data [1023:0]; 
  reg [TAGSIZE+1:0] cache_tag [1023:0]; // valid,dirty, cache_tag
  wire [31:0] mem_addr;
  reg [31:0] cpu_rd_data;
  reg [BLOCKSIZE-1:0] mem_wr_data;
  //reg [127:0] mem_rd_data_new;
  wire [TAGSIZE-1:0]  cpu_tag;
  wire tag_match, valid_bit,dirty_bit;
  wire[INDEXSIZE-1:0] index;
  reg [TAGSIZE+1:0] cache_tag_cur,new_cache_tag;
  reg update_tag;
  //reg wb_en;
  integer i;
  parameter IDLE =2'b00, CMP_TAG = 2'b01, ALLOC = 2'b10, WB = 2'b11;
  
  assign index = cpu_addr[TAGLSB-1:WORDMSB+1];
  assign cpu_tag = cpu_addr[TAGMSB:TAGLSB];
  assign mem_addr = cpu_addr;
  assign tag_match = (cpu_tag == cache_tag_cur[TAGSIZE-1:0])? 1:0;
  assign valid_bit = cache_tag_cur[19];
  assign dirty_bit =  cache_tag_cur[18];
  
  //assign cache_tag_cur = cache_tag[index]; //current cache line tag
  reg cache_wen;
  reg [1:0] cs,ns;
  
  always @(*)
    begin
      mem_wr_data = cache_data[index];
      cache_tag_cur = cache_tag[index];//current cache line tag
      case(cpu_addr[WORDMSB:WORDLSB])
        2'b00: cpu_rd_data = mem_wr_data[31:0];
        2'b01: cpu_rd_data = mem_wr_data[63:32];
        2'b10: cpu_rd_data = mem_wr_data[95:64];
        2'b11: cpu_rd_data = mem_wr_data[127:96];
       endcase
    end
  
 
  always @ (posedge clk or negedge rst)
   begin
    if (!rst)
      begin
        
      //initialize cache with 0
        for (i=0;i< 1024;i=i+1)
        begin
          cache_data[i] <= 128'b0;
          cache_tag [i]<= 128'b0;
        end
      end 
     else if (cache_wen || update_tag)
       begin
         if(cache_wen)
           begin
             if (cpu_req_wen) //cache write only update the specific word
               case(cpu_addr[WORDMSB:WORDLSB])
                 2'b00: cache_data[index] <= {mem_rd_data[127:32],cpu_wr_data};
                 2'b01: cache_data[index] <= {mem_rd_data[127:64],cpu_wr_data,mem_rd_data[31:0]};
                 2'b10: cache_data[index] <= {mem_rd_data[127:96],cpu_wr_data,mem_rd_data[63:0]};
                 2'b11: cache_data[index] <= {cpu_wr_data,mem_rd_data[95:0]};
        	   endcase
              else //cache read and alloc
           	 	cache_data[index] <= mem_rd_data;
           end
           cache_tag [index] <= new_cache_tag;
       end
     
     end
  
  //Control logic
  always @ (posedge clk or negedge rst)
    begin
    	if(!rst)
      		cs <= IDLE;
    	else
      		cs <= ns;
    end
    
  //FSM next state and output
  
  always @(*)
    begin
      
      ns = IDLE;
      
      case(cs)
       IDLE:
         if (!cpu_req_vld)
           
            ns = IDLE;
            
          else
       
             ns = CMP_TAG;
             
       CMP_TAG:
          //cache hit
         if (valid_bit && tag_match)
                 
             ns = IDLE;
                   
        // (compulsory miss) or (miss and dirty is not set)
        else if ((!valid_bit) || (valid_bit && (~tag_match) & (!dirty_bit)))
         		
             ns = ALLOC;
                   
        // miss with dirty bit set
        else if ((valid_bit) && (dirty_bit) && (!(tag_match)))
                 
             ns = WB;
        
        else 
             ns = CMP_TAG;
        
       ALLOC:
         if (mem_req_done)
             ns = CMP_TAG;
          else 
             ns = ALLOC;
            
       WB:
         if (mem_req_done) ns = ALLOC;
           
         else ns = WB;
        
          
      endcase
      
    end
   
  // output register
  always @ (posedge clk or negedge rst)
    if (!rst)
      begin
        cache_wen <= 1'b0; 
      	update_tag <= 1'b0;
      	mem_req_vld <=0;
      	mem_req_wen <= 0;
      	cpu_done <= 0;
      	new_cache_tag <= 20'b0;
      end
  else
    begin
      if ((cs == IDLE) && (ns == CMP_TAG))
          begin
            cache_wen <= 1'b0; 
      		update_tag <= 1'b0;
      		mem_req_vld <=0;
      		mem_req_wen <= 0;
      		cpu_done <= 0;
      		new_cache_tag <= 20'b0;
          end
      else if ((cs == CMP_TAG) && (ns == ALLOC))
          begin
            cache_wen <= 1'b0; 
      		update_tag <= 1'b1;
      		mem_req_vld <=1;
      		mem_req_wen <= 0;
      		cpu_done <= 0;
            new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[17:0]};
          end
      else if ((cs == CMP_TAG) && (ns == IDLE))
        begin
            cache_wen <= cpu_req_wen; //hit case --> update data only if write
      		update_tag <= 1'b1;
      		mem_req_vld <=0;
      		mem_req_wen <= 0;
      		cpu_done <= 1;
          new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[TAGSIZE-1:0]};
          end
      else if ((cs == CMP_TAG) && (ns == WB))
        begin
            cache_wen <= 1'b0; 
      		update_tag <= 1'b1;
      		mem_req_vld <=1;
      		mem_req_wen <= 1;
      		cpu_done <= 0;
      		new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[TAGSIZE-1:0]};
          end
      else if ((cs == ALLOC) && (ns == CMP_TAG))
        begin
            cache_wen <= 1'b1; //write new block from memory to cache line
      		update_tag <= 1'b0;
      		mem_req_vld <=0;
      		mem_req_wen <= 0;
      		cpu_done <= 0;
      		new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[TAGSIZE-1:0]};
          end
      else if ((cs == WB) && (ns == ALLOC))
        begin
            cache_wen <= 1'b0; 
      		update_tag <= 1'b0;
      		mem_req_vld <=1;
      		mem_req_wen <= 0;
      		cpu_done <= 0;
      		new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[TAGSIZE-1:0]};
          end
      else
        begin
            cache_wen <= 1'b0; 
      		update_tag <= 1'b0;
      		mem_req_vld <=0;
      		mem_req_wen <= 0;
      		cpu_done <= 0;
      		new_cache_tag <= {1'b1,cpu_req_wen,cpu_tag[TAGSIZE-1:0]};
        end
    end
  
  
endmodule
