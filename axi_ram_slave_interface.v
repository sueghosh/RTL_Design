
`timescale 1ns / 1ps


/*
 * AXI4 RAM Slave Interface 
 */
module axi_ram (clk,rst,s_axi_awid,s_axi_awaddr,s_axi_awlen,
                s_axi_awsize, s_axi_awburst,s_axi_awlock,
                s_axi_awcache,s_axi_awprot, s_axi_awvalid,
                s_axi_awready,s_axi_wdata,s_axi_wstrb,s_axi_wlast,
                s_axi_wvalid,s_axi_wready,s_axi_bid,s_axi_bresp,
                s_axi_bvalid,s_axi_bready,s_axi_arid,s_axi_araddr,
                s_axi_arlen,s_axi_arsize,s_axi_arburst,s_axi_arlock,
                s_axi_arcache,s_axi_arprot,s_axi_arvalid,
                s_axi_arready,s_axi_rid,s_axi_rdata,s_axi_rresp,
                s_axi_rlast,s_axi_rvalid,s_axi_rready);

  // Width of data bus in bits
  parameter DATA_WIDTH = 32,
  // Width of address bus in bits
   ADDR_WIDTH = 16,
  // Width of wstrb (width of data bus in words)
  STRB_WIDTH = (DATA_WIDTH/8),
  // Width of ID signal
   ID_WIDTH = 8;
    


  input                    clk;
  input                    rst;
  //Write address channel
  input  [ID_WIDTH-1:0]    s_axi_awid;
  input   [ADDR_WIDTH-1:0]  s_axi_awaddr;
  input   [7:0]             s_axi_awlen;
  input   [2:0]             s_axi_awsize;
  input   [1:0]             s_axi_awburst;
  input                     s_axi_awlock;
  input   [3:0]             s_axi_awcache;
  input   [2:0]             s_axi_awprot;
  input                     s_axi_awvalid;
  output                    s_axi_awready;
  //write data channel
  input   [DATA_WIDTH-1:0]  s_axi_wdata;
  input   [STRB_WIDTH-1:0]  s_axi_wstrb;
  input                     s_axi_wlast;
  input                     s_axi_wvalid;
  output                    s_axi_wready;
  //write response channel
  output  [ID_WIDTH-1:0]    s_axi_bid;
  output  wire [1:0]             s_axi_bresp;
  output                    s_axi_bvalid;
  input                     s_axi_bready;
  //read address channel
  input   [ID_WIDTH-1:0]    s_axi_arid;
  input   [ADDR_WIDTH-1:0]  s_axi_araddr;
  input   [7:0]             s_axi_arlen;
  input   [2:0]             s_axi_arsize;
  input   [1:0]             s_axi_arburst;
  input                     s_axi_arlock;
  input   [3:0]             s_axi_arcache;
  input   [2:0]             s_axi_arprot;
  input                     s_axi_arvalid;
  output                    s_axi_arready;
  //Read response channel
  output  [ID_WIDTH-1:0]    s_axi_rid;
  output  [DATA_WIDTH-1:0]  s_axi_rdata;
  output  [1:0]             s_axi_rresp;
  output                    s_axi_rlast;
  output                    s_axi_rvalid;
  input                     s_axi_rready;



parameter READ_IDLE = 1'd0,READ_BURST = 1'd1;
parameter WRITE_IDLE = 2'd0, WRITE_BURST = 2'd1,WRITE_RESP = 2'd2;
 

reg  read_cs, read_ns;
reg [1:0] write_ns , write_cs;

reg mem_wr_en;
reg mem_rd_en;

reg [ID_WIDTH-1:0] read_id , read_id_next;
reg [ADDR_WIDTH-1:0] read_addr , read_addr_next;
  reg [7:0] read_len , read_len_next;
reg [2:0] read_size , read_size_next;
reg [1:0] read_burst, read_burst_next;
reg [ID_WIDTH-1:0] write_id , write_id_next;
reg [ADDR_WIDTH-1:0] write_addr , write_addr_next;
  reg [7:0] write_len , write_len_next;
reg [2:0] write_size , write_size_next;
reg [1:0] write_burst , write_burst_next;

reg s_axi_awready, s_axi_awready_next;
reg s_axi_wready, s_axi_wready_next;
reg [ID_WIDTH-1:0] s_axi_bid, s_axi_bid_next;
reg s_axi_bvalid, s_axi_bvalid_next;
reg s_axi_arready, s_axi_arready_next;
reg [ID_WIDTH-1:0] s_axi_rid , s_axi_rid_next;
reg [DATA_WIDTH-1:0] s_axi_rdata, s_axi_rdata_next;
reg s_axi_rlast, s_axi_rlast_next;
reg s_axi_rvalid, s_axi_rvalid_next;

// define actual memory addr range keeping lsb bits for writing each strobe
// for data width = 32 , 4 bytes of data can be written and strobe width is 4
parameter MEM_ADDR_WIDTH = ADDR_WIDTH - $clog2(STRB_WIDTH);
// declare RAM memory of size MEM_ADDR_WIDTH by DATA_WIDTH

reg [DATA_WIDTH-1:0] mem[(2**MEM_ADDR_WIDTH)-1:0];
  
  //actual mem addr will exclude LSB bits for each byte addr

wire [MEM_ADDR_WIDTH-1:0] write_addr_range = write_addr >> (ADDR_WIDTH - MEM_ADDR_WIDTH);
  
  wire [MEM_ADDR_WIDTH-1:0] read_addr_range = read_addr >> (ADDR_WIDTH - MEM_ADDR_WIDTH);
  

assign s_axi_bresp = 2'b00;

assign s_axi_rresp = 2'b00;
  
integer i;

// Initializing mem with known value to verify
initial begin
    
  for (i = 0; i < 2**MEM_ADDR_WIDTH; i = i + 1) 
         begin
           mem[i] = 3419064776+i;
        end
    
end 
  
  //Read FSM
always @* begin
    read_ns = READ_IDLE;
    mem_rd_en = 1'b0;
    s_axi_rid_next = s_axi_rid;
    s_axi_rlast_next = s_axi_rlast;
    s_axi_rvalid_next =0;
    read_id_next = read_id;
    read_addr_next = read_addr;
    read_len_next = read_len;
    read_size_next = read_size;
    read_burst_next = read_burst;

    s_axi_arready_next = 1'b0;

  case (read_cs)
    READ_IDLE: begin
      s_axi_arready_next = 1'b1;
      s_axi_rlast_next = 1'b0;

      if (s_axi_arready && s_axi_arvalid) begin
        read_id_next = s_axi_arid;
        read_addr_next = s_axi_araddr;
        read_len_next = s_axi_arlen  ;
        read_size_next = s_axi_arsize < $clog2(STRB_WIDTH) ? s_axi_arsize : $clog2(STRB_WIDTH);
        read_burst_next = s_axi_arburst;
        //s_axi_rvalid_next = 1'b0;
        s_axi_arready_next = 1'b0;
        read_ns = READ_BURST;
      end else begin
        read_ns = READ_IDLE;
      end
    end
    READ_BURST: begin
      if (s_axi_rready ) begin
        mem_rd_en = 1'b1;
        s_axi_rvalid_next = 1'b1;
        s_axi_rid_next = read_id;
        s_axi_rlast_next = read_len == 0;
        if (read_burst != 2'b00) begin
          read_addr_next = read_addr + (1 << read_size);
        end
        read_len_next = read_len - 1;
        if (read_len > 0) begin
          read_ns = READ_BURST;
        end else begin
          s_axi_arready_next = 1'b1;
          read_addr_next = 0; //reset the read counter if all data is read
          //s_axi_rvalid_next = 1'b0;
          read_ns = READ_IDLE;
        end
      end else begin
        read_ns = READ_BURST;
      end
    end
  endcase
end
// Output reg for Read channel
always @(posedge clk or negedge rst)begin
  if (!rst) begin
    read_cs <= READ_IDLE;

    s_axi_arready <= 1'b0;
    s_axi_rvalid<= 1'b0;
    read_id <= 0;
    read_addr <= 0;
    read_len <= 0;
    read_size <= 0;
    read_burst <= 0;
    s_axi_rid <= 0;
    s_axi_rlast <= 0;
    s_axi_rvalid <= 0;
    s_axi_rdata <=0;
    end
  else begin
    read_cs <= read_ns;

    read_id <= read_id_next;
    read_addr <= read_addr_next;
    read_len <= read_len_next;
    read_size <= read_size_next;
    read_burst <= read_burst_next;

    s_axi_arready <= s_axi_arready_next;
    s_axi_rid <= s_axi_rid_next;
    s_axi_rlast <= s_axi_rlast_next;
    s_axi_rvalid <= s_axi_rvalid_next;

    if (mem_rd_en) begin
      s_axi_rdata<= mem[read_addr_range];
      //s_axi_rdata <= mem[read_addr_reg];
    end
  end
end
  
  // Write FSM

 always @* begin
    write_ns = WRITE_IDLE;

    mem_wr_en = 1'b0;

    write_id_next = write_id;
    write_addr_next = write_addr;
    write_len_next = write_len;
    write_size_next = write_size;
    write_burst_next = write_burst;

    s_axi_awready_next = 1'b0;
    s_axi_wready_next = 1'b0;
    s_axi_bid_next = s_axi_bid;
    s_axi_bvalid_next = 1'b0;
    //s_axi_bvalid_next = s_axi_bvalid_reg && !s_axi_bready;

  case (write_cs)
    WRITE_IDLE: begin
      s_axi_awready_next = 1'b1;
      s_axi_bvalid_next = 1'b0;
      if (s_axi_awready && s_axi_awvalid) begin
        write_id_next = s_axi_awid; //store the wid to send along with response
        write_addr_next = s_axi_awaddr;
        write_len_next = s_axi_awlen ; //+1 is not assigned as addr_reg gets updated 1 cycle later
        write_size_next = s_axi_awsize < $clog2(STRB_WIDTH) ? s_axi_awsize : $clog2(STRB_WIDTH);
        write_burst_next = s_axi_awburst;

        s_axi_awready_next = 1'b0;
        s_axi_wready_next = 1'b1;
        write_ns = WRITE_BURST;
      end else begin
        write_ns = WRITE_IDLE;
      end
    end
    WRITE_BURST: begin
      s_axi_wready_next = 1'b1;
      if (s_axi_wready && s_axi_wvalid) begin
        mem_wr_en = 1'b1;
        if (write_burst != 2'b00) begin
          write_addr_next = write_addr + (1 << write_size);
        end
        // add else for fixed burst
        write_len_next = write_len - 1; 
        if (write_len > 0) begin
          write_ns = WRITE_BURST;
        end else begin // last write
          s_axi_wready_next = 1'b0; //deassert wready while last data is written
          s_axi_bid_next = write_id;
          s_axi_bvalid_next = 1'b1; 
          s_axi_awready_next = 1'b0;
          write_addr_next = 0; //reset the addr pointer
          write_ns = WRITE_RESP;
        end
      end else write_ns = WRITE_BURST; // wait for wvalid to be asserted
     
    end
    WRITE_RESP: begin
      
      if (s_axi_bready) begin
        s_axi_bvalid_next = 1'b0;
        s_axi_awready_next = 1'b1;
        s_axi_bid_next = write_id;
        write_addr_next = 0; //reset the addr pointer
        write_ns = WRITE_IDLE;
      end else begin
        s_axi_bvalid_next = 1'b1;
        write_ns = WRITE_RESP;
      end
    end
  endcase
end 


always @(posedge clk or negedge rst) begin
   if (!rst) begin
      write_cs <= WRITE_IDLE;
      s_axi_awready <= 1'b0;
      s_axi_wready <= 1'b0;
      s_axi_bvalid <= 1'b0;
      write_id <= 0;
      write_addr <= 0;
      write_len <=0;
      write_size <= 0;
      write_burst <= 0;
      s_axi_bid <= 0;
    end
    else begin
      write_cs <= write_ns;
      write_id <= write_id_next;
      write_addr <= write_addr_next;
      write_len <= write_len_next;
      write_size <= write_size_next;
      write_burst <= write_burst_next;
      s_axi_awready <= s_axi_awready_next;
      s_axi_wready <= s_axi_wready_next;
      s_axi_bid <= s_axi_bid_next;
      s_axi_bvalid <= s_axi_bvalid_next;

      for (i = 0; i < STRB_WIDTH; i = i + 1) begin // write byte masked with strobe
        if (mem_wr_en & s_axi_wstrb[i]) begin
          mem[write_addr_range][8*i +: 8] <= s_axi_wdata[8*i +: 8];
        end
    end
    end

    
end

endmodule
