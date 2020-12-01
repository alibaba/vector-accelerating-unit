/* MIT License

Copyright (c) 2020 T-head-Semi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. */

module gemm_axim_top # (
	parameter integer BURST_LENGTH_WIDTH  = 5,
	parameter integer BURST_SIZE_WIDTH  	= 3,
	// Thread ID Width
	parameter integer C_M_AXI_ID_WIDTH		= 1,
	// Width of Address Bus
	parameter integer C_M_AXI_ADDR_WIDTH	= 32,
	// Width of Data Bus
	parameter integer C_M_AXI_DATA_WIDTH	= 1024
) (
	input  wire [BURST_LENGTH_WIDTH-1:0] write_burst_length,
	input  wire [BURST_LENGTH_WIDTH-1:0] read_burst_length,
	input  wire [BURST_SIZE_WIDTH-1:0]   write_burst_size,
	input  wire [BURST_SIZE_WIDTH-1:0]   read_burst_size,
	input  wire read_enable,
	input  wire write_enable,
	//initiate write transfer
	input  wire init_write,
	//initiate read transfer
	input  wire init_read,
	input  wire [C_M_AXI_ADDR_WIDTH-1:0] write_start_address,
	input  wire [C_M_AXI_ADDR_WIDTH-1:0] read_start_address,
	input  [C_M_AXI_DATA_WIDTH-1:0] write_data,
	// Asserts when transaction is complete
	output wire  TX_DONE,
	output wire  RX_DONE,
	// Asserts when ERROR is detected
	output wire  ERROR,
	// Global Clock Signal.
	input  wire  M_AXI_ACLK,
	// Global Reset Singal. This Signal is Active Low
	input  wire  M_AXI_ARESETN,
	// Master Interface Write Address ID
	output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_AWID,
	// Master Interface Write Address
	output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
	// Burst length. The burst length gives the exact number of transfers in a burst
	output wire [7 : 0] M_AXI_AWLEN,
	// Burst size. This signal indicates the size of each transfer in the burst
	output wire [2 : 0] M_AXI_AWSIZE,
	// Burst type. The burst type and the size information, 
	// determine how the address for each transfer within the burst is calculated.
	output wire [1 : 0] M_AXI_AWBURST,
	// Lock type. Provides additional information about the
	// atomic characteristics of the transfer.
	output wire  M_AXI_AWLOCK,
	// Memory type. This signal indicates how transactions
	// are required to progress through a system.
	output wire [3 : 0] M_AXI_AWCACHE,
	// Protection type. This signal indicates the privilege
	// and security level of the transaction, and whether
	// the transaction is a data access or an instruction access.
	output wire [2 : 0] M_AXI_AWPROT,
	// Quality of Service, QoS identifier sent for each write transaction.
	output wire [3 : 0] M_AXI_AWQOS,
	// Optional User-defined signal in the write address channel.
	//output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
	// Write address valid. This signal indicates that
	// the channel is signaling valid write address and control information.
	output wire  M_AXI_AWVALID,
	// Write address ready. This signal indicates that
	// the slave is ready to accept an address and associated control signals
	input  wire  M_AXI_AWREADY,
	// Master Interface Write Data.
	output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
	// Write strobes. This signal indicates which byte
	// lanes hold valid data. There is one write strobe
	// bit for each eight bits of the write data bus.
	output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
	// Write last. This signal indicates the last transfer in a write burst.
	output wire  M_AXI_WLAST,
	// Optional User-defined signal in the write data channel.
	//output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
	// Write valid. This signal indicates that valid write
	// data and strobes are available
	output wire  M_AXI_WVALID,
	// Write ready. This signal indicates that the slave
	// can accept the write data.
	input  wire  M_AXI_WREADY,
	// Master Interface Write Response.
	input  wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
	// Write response. This signal indicates the status of the write transaction.
	input  wire [1 : 0] M_AXI_BRESP,
	// Optional User-defined signal in the write response channel
	//input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
	// Write response valid. This signal indicates that the
	// channel is signaling a valid write response.
	input  wire  M_AXI_BVALID,
	// Response ready. This signal indicates that the master
	// can accept a write response.
	output wire  M_AXI_BREADY,
	// Master Interface Read Address.
	output wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_ARID,
	// Read address. This signal indicates the initial
	// address of a read burst transaction.
	output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
	// Burst length. The burst length gives the exact number of transfers in a burst
	output wire [7 : 0] M_AXI_ARLEN,
	// Burst size. This signal indicates the size of each transfer in the burst
	output wire [2 : 0] M_AXI_ARSIZE,
	// Burst type. The burst type and the size information, 
	// determine how the address for each transfer within the burst is calculated.
	output wire [1 : 0] M_AXI_ARBURST,
	// Lock type. Provides additional information about the
	// atomic characteristics of the transfer.
	output wire  M_AXI_ARLOCK,
	// Memory type. This signal indicates how transactions
	// are required to progress through a system.
	output wire [3 : 0] M_AXI_ARCACHE,
	// Protection type. This signal indicates the privilege
	// and security level of the transaction, and whether
	// the transaction is a data access or an instruction access.
	output wire [2 : 0] M_AXI_ARPROT,
	// Quality of Service, QoS identifier sent for each read transaction
	output wire [3 : 0] M_AXI_ARQOS,
	// Optional User-defined signal in the read address channel.
	//output wire [C_M_AXI_ARUSER_WIDTH-1 : 0] M_AXI_ARUSER,
	// Write address valid. This signal indicates that
	// the channel is signaling valid read address and control information
	output wire  M_AXI_ARVALID,
	// Read address ready. This signal indicates that
	// the slave is ready to accept an address and associated control signals
	input  wire  M_AXI_ARREADY,
	// Read ID tag. This signal is the identification tag
	// for the read data group of signals generated by the slave.
	input  wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_RID,
	// Master Read Data
	input  wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
	// Read response. This signal indicates the status of the read transfer
	input  wire [1 : 0] M_AXI_RRESP,
	// Read last. This signal indicates the last transfer in a read burst
	input  wire  M_AXI_RLAST,
	// Optional User-defined signal in the read address channel.
	//input wire [C_M_AXI_RUSER_WIDTH-1 : 0] M_AXI_RUSER,
	// Read valid. This signal indicates that the channel
	// is signaling the required read data.
	input  wire  M_AXI_RVALID,
	// Read ready. This signal indicates that the master can
	// accept the read data and response information.
	output wire  M_AXI_RREADY
);


	// function called clogb2 that returns an integer which has the
	//value of the ceiling of the log base 2

	// function called clogb2 that returns an integer which has the 
	// value of the ceiling of the log base 2.                      
	function integer clogb2 (input integer bit_depth);              
		begin                                                           
			for(clogb2=0; bit_depth>0; clogb2=clogb2+1)                   
				bit_depth = bit_depth >> 1;                                 
		end                                                           
	endfunction                                                     

	// C_TRANSACTIONS_NUM is the width of the index counter for 
	// number of write or read transaction.
	//localparam integer C_TRANSACTIONS_NUM = clogb2(C_M_AXI_BURST_LEN-1);
	localparam integer C_TRANSACTIONS_NUM = BURST_LENGTH_WIDTH;

	// Burst length for transactions, in C_M_AXI_DATA_WIDTH s.
	// Non-2^n lengths will eventually cause bursts across 4K address boundaries.
	localparam integer C_MASTER_LENGTH	= 12;	
	// total number of burst transfers is master length divided by burst length and burst size
	//localparam integer C_NO_BURSTS_REQ = C_MASTER_LENGTH-clogb2((C_M_AXI_BURST_LEN*C_M_AXI_DATA_WIDTH/8)-1);
	localparam integer C_NO_BURSTS_REQ = 0;	
	localparam integer C_DATA_BYTE_WIDTH = C_TRANSACTIONS_NUM+clogb2(C_M_AXI_DATA_WIDTH/8);


	localparam [1:0] IDLE = 2'b00;
	localparam [1:0] INIT_XFER = 2'b01;


	// AXI4LITE signals
	//AXI4 internal temp signals
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg axi_awvalid;
	reg axi_wlast;
	reg axi_wvalid;
	reg axi_bready;
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg axi_arvalid;
	reg axi_rready;
	//write beat count in a burst
	reg [C_TRANSACTIONS_NUM : 0] 	write_index;
	//read beat count in a burst
	reg [C_TRANSACTIONS_NUM : 0] 	read_index;
	//size of C_M_AXI_BURST_LEN length burst in bytes
	//wire [C_TRANSACTIONS_NUM+2 : 0] 	burst_size_bytes;
	wire [C_DATA_BYTE_WIDTH : 0] 	wburst_size_bytes;
	wire [C_DATA_BYTE_WIDTH : 0] 	rburst_size_bytes;
	//The burst counters are used to track the number of burst transfers of C_M_AXI_BURST_LEN burst length needed to transfer 2^C_MASTER_LENGTH bytes of data.
	reg [C_NO_BURSTS_REQ : 0] 	write_burst_counter;
	reg [C_NO_BURSTS_REQ : 0] 	read_burst_counter;
	reg start_single_burst_write;
	reg start_single_burst_read;
	reg writes_done;
	reg reads_done;
	reg error_reg;
	reg burst_write_active;
	reg burst_read_active;
	//Interface response error flags
	wire write_resp_error;
	wire read_resp_error;
	wire wnext;
	wire rnext;
	reg init_tx_ff;
	wire init_tx_pulse;
	reg init_rx_ff;
	wire init_rx_pulse;
	wire init_tx_rx_pulse = init_rx_pulse | init_tx_pulse;


	// I/O Connections assignments

	//I/O Connections. Write Address (AW)
	assign M_AXI_AWID	= 'b0;
	//The AXI address is a concatenation of the target base address + active offset range
	assign M_AXI_AWADDR	= write_start_address/* + axi_awaddr*/;
	//Burst LENgth is number of transaction beats, minus 1
	assign M_AXI_AWLEN	= write_burst_length;
	//Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
	assign M_AXI_AWSIZE	= write_burst_size;
	//INCR burst type is usually used, except for keyhole bursts
	assign M_AXI_AWBURST	= 2'b01;
	assign M_AXI_AWLOCK	= 1'b0;
	assign M_AXI_AWCACHE	= 4'b0010;
	assign M_AXI_AWPROT	= 3'h0;
	assign M_AXI_AWQOS	= 4'h0;
	//assign M_AXI_AWUSER	= 'b1;
	assign M_AXI_AWVALID	= axi_awvalid;
	//Write Data(W)
	assign M_AXI_WDATA	= write_data;
	assign M_AXI_WSTRB	= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
	assign M_AXI_WLAST	= axi_wlast;
	//assign M_AXI_WUSER	= 'b0;
	assign M_AXI_WVALID	= axi_wvalid;
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;
	//Read Address (AR)
	assign M_AXI_ARID	= 'b0;
	assign M_AXI_ARADDR	= read_start_address/* + axi_araddr*/;
	//Burst LENgth is number of transaction beats, minus 1
	assign M_AXI_ARLEN	= read_burst_length;
	//Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes, otherwise narrow bursts are used
	assign M_AXI_ARSIZE	= read_burst_size;
	//INCR burst type is usually used, except for keyhole bursts
	assign M_AXI_ARBURST	= 2'b01;
	assign M_AXI_ARLOCK	= 1'b0;
	assign M_AXI_ARCACHE	= 4'b0010;
	assign M_AXI_ARPROT	= 3'h0;
	assign M_AXI_ARQOS	= 4'h0;
	//assign M_AXI_ARUSER	= 'b1;
	assign M_AXI_ARVALID	= axi_arvalid;
	//Read and Read Response (R)
	assign M_AXI_RREADY	= axi_rready;
	//Example design I/O
	assign TX_DONE	= writes_done;
	assign RX_DONE	= reads_done;
	//Burst size in bytes
	assign wburst_size_bytes	= ({1'b0,write_burst_length}+1) * (9'b1 << write_burst_size);
	assign rburst_size_bytes	= ({1'b0,read_burst_length}+1) * (9'b1 << read_burst_size);
	assign init_tx_pulse	= (!init_tx_ff) && init_write;
	assign init_rx_pulse	= (!init_rx_ff) && init_read;



	//Generate a pulse to initiate AXI transaction.
	always @(posedge M_AXI_ACLK) begin                                                                        
		// Initiates AXI transaction delay    
		if (M_AXI_ARESETN == 0 ) begin                                                                    
			init_tx_ff <= 1'b0;                                                   
			init_rx_ff <= 1'b0;                                                   
		end else begin  
			init_tx_ff <= init_write;
			init_rx_ff <= init_read;
		end                                                                      
	end     


	//--------------------
	//Write Address Channel
	//--------------------

	// The purpose of the write address channel is to request the address and 
	// command information for the entire transaction.  It is a single beat
	// of information.

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin                                                            
				axi_awvalid <= 1'b0;                                           
		end else if(init_tx_pulse == 1'b1)
			axi_awvalid <= 1'b0;                                           
		// If previously not valid , start next transaction                
		else if (~axi_awvalid && start_single_burst_write) begin                                                            
			axi_awvalid <= 1'b1;                                           
		end                                                              
		/* Once asserted, VALIDs cannot be deasserted, so axi_awvalid must wait until transaction is accepted */                         
		else if (M_AXI_AWREADY && axi_awvalid) begin                                                            
			axi_awvalid <= 1'b0;                                           
		end else begin                                                            
			axi_awvalid <= axi_awvalid;
		end                                   
	end                                                                
	                                                                       
	                                                                       
	// Next address after AWREADY indicates previous address acceptance    
	always @(posedge M_AXI_ACLK) begin                                                                
		if (M_AXI_ARESETN == 0) begin                                                            
				axi_awaddr <= 'b0;                                             
		end else if(init_tx_pulse == 1'b1) begin
				axi_awaddr <= 'b0;                                             
		end else if (M_AXI_AWREADY && axi_awvalid) begin                                                            
				axi_awaddr <= axi_awaddr + wburst_size_bytes;                   
		end else begin                                                        
			axi_awaddr <= axi_awaddr; 
		end
	end                                                                


	//--------------------
	//Write Data Channel
	//--------------------

	assign wnext = M_AXI_WREADY & axi_wvalid & write_enable;                                   
	                                                                                    
	// WVALID logic, similar to the axi_awvalid always block above                      
	always @(posedge M_AXI_ACLK) begin                                                                             
		if (M_AXI_ARESETN == 0) begin                                                                         
			axi_wvalid <= 1'b0;                                                         
		end else if(init_tx_rx_pulse == 1'b1)
			axi_wvalid <= 1'b0;                                                         
		// If previously not valid, start next transaction                              
		else if (~axi_wvalid && start_single_burst_write) begin                                                                         
			axi_wvalid <= 1'b1;                                                         
		end                                                                           
		/* If WREADY and too many writes, throttle WVALID                               
		Once asserted, VALIDs cannot be deasserted, so WVALID                           
		must wait until burst is complete with WLAST */                                 
		else if (wnext && axi_wlast)                                                    
			axi_wvalid <= 1'b0;                                                           
		else                                                                            
			axi_wvalid <= axi_wvalid;                                                     
	end                                                                               
	                                                                                    
	                                                                                    
	//WLAST generation on the MSB of a counter underflow                                
	// WVALID logic, similar to the axi_awvalid always block above                      
	always @(posedge M_AXI_ACLK) begin                                                                             
		if (M_AXI_ARESETN == 0) begin                                                                         
			axi_wlast <= 1'b0;                                                          
		end else if(init_tx_pulse == 1'b1)
			axi_wlast <= 1'b0;                                                          
			// axi_wlast is asserted when the write index                                   
			// count reaches the penultimate count to synchronize                           
			// with the last write data when write_index is b1111                           
			// else if (&(write_index[C_TRANSACTIONS_NUM-1:1])&& ~write_index[0] && wnext)  
		else if (((write_index == write_burst_length-1 && write_burst_length >= 2) && wnext) || (write_burst_length == 1)) begin                                                                         
			axi_wlast <= 1'b1;                                                          
		end                                                                           
		// Deassrt axi_wlast when the last write data has been                          
		// accepted by the slave with a valid response                                  
		else if (wnext)                                                                 
			axi_wlast <= 1'b0;                                                            
		else if (axi_wlast && write_burst_length == 1)                                   
			axi_wlast <= 1'b0;                                                            
		else                                                                            
			axi_wlast <= axi_wlast;                                                       
	end                                                                               
	                                                                                    
	                                                                                    
	/* Burst length counter. Uses extra counter register bit to indicate terminal       
	 count to reduce decode logic */                                                    
	always @(posedge M_AXI_ACLK) begin                                                                             
		if (M_AXI_ARESETN == 0) begin                                                                         
			write_index <= 0;                                                           
		end else if(init_tx_pulse == 1'b1 || start_single_burst_write == 1'b1)
			write_index <= 0;                                                           
		else if (wnext && (write_index != write_burst_length)) begin                                                                         
			write_index <= write_index + 1;                                             
		end else begin                                                                         
			write_index <= write_index; 
		end																									
	end                                                                               
	                                                                                    
	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	//The write response channel provides feedback that the write has committed
	//to memory. BREADY will occur when all of the data and the write address
	//has arrived and been accepted by the slave.

	//The write issuance (number of outstanding write addresses) is started by 
	//the Address Write transfer, and is completed by a BREADY/BRESP.

	//While negating BREADY will eventually throttle the AWREADY signal, 
	//it is best not to throttle the whole data channel this way.

	//The BRESP bit [1] is used indicate any errors from the interconnect or
	//slave for the entire write burst. This example will capture the error 
	//into the ERROR output. 

	always @(posedge M_AXI_ACLK) begin                                                                 
		if (M_AXI_ARESETN == 0) begin                                                             
			axi_bready <= 1'b0;                                             
		end else if(init_tx_rx_pulse == 1'b1)
			axi_bready <= 1'b0;                                             
			// accept/acknowledge bresp with axi_bready by the master           
			// when M_AXI_BVALID is asserted by slave                           
		else if (M_AXI_BVALID && ~axi_bready) begin                                                             
			axi_bready <= 1'b1;                 
			// deassert after one clock cycle                            
		end else if (axi_bready) begin                                                             
			axi_bready <= 1'b0;                                             
		end else begin// retain the previous value
			axi_bready <= axi_bready;     
		end
	end                                                                   
	                                                                        
	                                                                        
	//Flag any write response errors                                        
	assign write_resp_error = axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]; 


	//----------------------------
	//Read Address Channel
	//----------------------------

	//The Read Address Channel (AW) provides a similar function to the
	//Write Address channel- to provide the tranfer qualifiers for the burst.

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin                                                          
			axi_arvalid <= 1'b0;                                         
		end else if(init_rx_pulse == 1'b1 )
				axi_arvalid <= 1'b0;                                         
		// If previously not valid , start next transaction              
		else if (~axi_arvalid && start_single_burst_read) begin                                                          
			axi_arvalid <= 1'b1;                                         
		end else if (M_AXI_ARREADY && axi_arvalid) begin                                                          
			axi_arvalid <= 1'b0;                                         
		end else begin                                                      
			axi_arvalid <= axi_arvalid;      
		end                              
	end                                                                
	                                                                     
	                                                                     
	// Next address after ARREADY indicates previous address acceptance  
	always @(posedge M_AXI_ACLK) begin                                                              
		if (M_AXI_ARESETN == 0) begin                                                          
			axi_araddr <= 'b0;                                           
		end else if(init_rx_pulse == 1'b1)
			axi_araddr <= 'b0;                                           
		else if (M_AXI_ARREADY && axi_arvalid) begin                                                          
			axi_araddr <= axi_araddr + rburst_size_bytes;                 
		end else begin                                                           
			axi_araddr <= axi_araddr;   
		end                                   
	end                                                                


	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------

	// Forward movement occurs when the channel is valid and ready   
	assign rnext = M_AXI_RVALID && axi_rready;                            
	                                                                        
	                                                                        
	// Burst length counter. Uses extra counter register bit to indicate    
	// terminal count to reduce decode logic                                
	always @(posedge M_AXI_ACLK) begin                                                                 
		if (M_AXI_ARESETN == 0) begin                                                             
			read_index <= 0;                                                
		end else if (init_rx_pulse == 1'b1 || start_single_burst_read)
			read_index <= 0;                                                
		else if (rnext && (read_index != read_burst_length)) begin                                                             
			read_index <= read_index + 1;                                   
		end else begin
			read_index <= read_index;
		end
	end                                                                   
	                                                                        
	                                                                        
	/*                                                                      
	 The Read Data channel returns the results of the read request          
	*/                                                                     
	always @(posedge M_AXI_ACLK) begin                                                                 
		if (M_AXI_ARESETN == 0) begin                                                             
			axi_rready <= 1'b0;                                             
		end else if(init_rx_pulse == 1'b1)
			axi_rready <= 1'b0;                                             
		// accept/acknowledge rdata/rresp with axi_rready by the master     
		// when M_AXI_RVALID is asserted by slave                           
		else if (M_AXI_RVALID) begin                                      
			if(read_enable) begin
				if (M_AXI_RLAST && axi_rready) begin                                  
					axi_rready <= 1'b0;                  
				end else begin                                 
					axi_rready <= 1'b1;                 
				end                                   
			end else begin
				axi_rready <= 1'b0;                  
			end
		end                                        
		// retain the previous value                 
	end                                            
	                                                                        
	                                                                        
	//Flag any read response errors                                         
	assign read_resp_error = axi_rready & M_AXI_RVALID & M_AXI_RRESP[1];  

	//----------------------------------
	//Example design error register
	//----------------------------------

	//Register and hold any data mismatches, or read/write interface errors 

	always @(posedge M_AXI_ACLK) begin                                                              
		if (M_AXI_ARESETN == 0) begin                                                          
			error_reg <= 1'b0;                                           
		end else if(init_tx_rx_pulse == 1'b1)
			error_reg <= 1'b0;                                           
		else if (write_resp_error || read_resp_error) begin                                                          
			error_reg <= 1'b1;                                           
		end else begin                                                            
			error_reg <= error_reg;
		end
	end                                                                


	 // write_burst_counter counter keeps track with the number of burst transaction initiated            
	 // against the number of burst transactions the master needs to initiate                                   
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0) begin                                                                                                 
			write_burst_counter <= 'b0;                                                                         
		end else if(init_tx_pulse == 1'b1) begin
			write_burst_counter <= 'b0;                                                                         
		end else if (M_AXI_AWREADY && axi_awvalid) begin                                                                                                 
			if (write_burst_counter[C_NO_BURSTS_REQ] == 1'b0) begin                                                                                             
				write_burst_counter <= write_burst_counter + 1'b1;                                              
				//write_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                 
			end                                                                                               
		end else begin                                                                                                    
			write_burst_counter <= write_burst_counter;     
		end                                                      
	end                                                                                                       
																																																						
	// read_burst_counter counter keeps track with the number of burst transaction initiated                   
	// against the number of burst transactions the master needs to initiate                                   
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0) begin                                                                                                 
			read_burst_counter <= 'b0;                                                                          
		end else if(init_rx_pulse == 1'b1)
				read_burst_counter <= 'b0;                                                                          
		else if (M_AXI_ARREADY && axi_arvalid) begin                                                                                                 
			if (read_burst_counter[C_NO_BURSTS_REQ] == 1'b0) begin                                                                                             
				read_burst_counter <= read_burst_counter + 1'b1;                                                
				//read_burst_counter[C_NO_BURSTS_REQ] <= 1'b1;                                                  
			end                                                                                               
		end else begin
			read_burst_counter <= read_burst_counter;
		end                                                            
	end                                                                                                       
	                                                                                                            
	                                                                                                            
	  //implement master command interface state machine                                                        
	  //different state machine for read and write
	reg [1:0] mst_exec_read_cur_state, mst_exec_read_next_state;
	reg reads_error;
	                                                                                                            
	always @(posedge M_AXI_ACLK) begin    
		if (M_AXI_ARESETN == 0) begin
			mst_exec_read_cur_state <= IDLE;                                                                          
		end else begin
			mst_exec_read_cur_state <= mst_exec_read_next_state;
		end
	end

	always @(*) begin
		case(mst_exec_read_cur_state)
			IDLE: begin
				if(init_rx_pulse) begin
					mst_exec_read_next_state = INIT_XFER;
				end else begin
					mst_exec_read_next_state = IDLE;
				end
			end
			INIT_XFER: begin
				if(reads_done)  
					mst_exec_read_next_state = IDLE;                                                            
				else                                                                                            
						mst_exec_read_next_state = INIT_XFER;      
			end
			default:
				mst_exec_read_next_state = IDLE;
		endcase
	end //always


	always @(posedge M_AXI_ACLK) begin                                                                                                     
	  if (M_AXI_ARESETN == 1'b0) begin                                                                                                  
			// reset condition                                                                                  
			// All the signals are assigned default values under reset condition                                
			start_single_burst_read  <= 1'b0;                                                                   
			reads_error <= 1'b0;   
		end else begin                                                                                                 
			case (mst_exec_read_cur_state)                                                                               
				IDLE:                                                                                     
					reads_error <= 1'b0;
				INIT_XFER: begin                                                                                      
					reads_error <= error_reg;
					if (~axi_arvalid && ~burst_read_active && ~start_single_burst_read && ~reads_done) begin                                                                                     
						start_single_burst_read <= 1'b1;                                                        
					end else begin                                                                                      
						start_single_burst_read <= 1'b0; //Negate to generate a pulse                            
					end                                                                                        
				end
				default : begin                                                                                           
						start_single_burst_read  <= 1'b0;                                                                   
						reads_error <= 1'b0;   
				end                                                                                             
			endcase                                                                                             
		end                                                                                                   
	end //MASTER_EXECUTION_PROC                                                                               
	                                                                                                            
	reg [1:0] mst_exec_write_cur_state, mst_exec_write_next_state;
	reg writes_error;
	                                                                                                            
	always @(posedge M_AXI_ACLK) begin    
		if (M_AXI_ARESETN == 0) begin
			mst_exec_write_cur_state <= IDLE;                                                                          
		end else begin
			mst_exec_write_cur_state <= mst_exec_write_next_state;
		end 
	end

	always @(*) begin
		case(mst_exec_write_cur_state)
			IDLE: begin
				if(init_tx_pulse) begin
					mst_exec_write_next_state = INIT_XFER;
				end else begin
					mst_exec_write_next_state = IDLE;
				end
			end
			INIT_XFER: begin
				if(writes_done)  
					mst_exec_write_next_state = IDLE;                                                            
				else                                                                                            
						mst_exec_write_next_state = INIT_XFER;      
			end
			default:
				mst_exec_write_next_state = IDLE;
		endcase
	end//always


	always @(posedge M_AXI_ACLK) begin                                                                                                     
	  if (M_AXI_ARESETN == 1'b0) begin                                                                                                 
			// reset condition                                                                                  
			// All the signals are assigned default values under reset condition                                
			start_single_burst_write  <= 1'b0;                                                                   
			writes_error <= 1'b0;   
		end else begin                                                                                                 
			case (mst_exec_write_cur_state)                                                                               
				IDLE:                                                                                     
					writes_error <= 1'b0;
				INIT_XFER: begin                                                                                      
					writes_error <= error_reg;
					if (~axi_arvalid && ~burst_write_active && ~start_single_burst_write && ~writes_done) begin                                                                                     
						start_single_burst_write <= 1'b1;                                                        
					end else begin                                                                                      
						start_single_burst_write <= 1'b0; //Negate to generate a pulse                            
					end                                                                                        
				end  
				default:                                                                                         
					begin                                                                                           
						start_single_burst_write  <= 1'b0;                                                                   
						writes_error <= 1'b0;   
					end                                                                                             
			endcase                                                                                             
		end                                                                                                   
	end //MASTER_EXECUTION_PROC                                                                               
	                                                                                                            
	                                                                                                            
	assign ERROR = reads_error | writes_error;
	                                                                                                            
	  // burst_write_active signal is asserted when there is a burst write transaction                          
	  // is initiated by the assertion of start_single_burst_write. burst_write_active                          
	  // signal remains asserted until the burst write is accepted by the slave                                 
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0)
			burst_write_active <= 1'b0;                                                                           
		else if(init_tx_pulse == 1'b1)
			burst_write_active <= 1'b0;                                                                           
		//The burst_write_active is asserted when a write burst transaction is initiated                        
		else if (start_single_burst_write)                                                                      
			burst_write_active <= 1'b1;                                                                           
		else if (M_AXI_BVALID && axi_bready)                                                                    
			burst_write_active <= 0;                                                                              
	end                                                                                                       
	                                                                                                            
	 // Check for last write completion.                                                                        
	                                                                                                            
	 // This logic is to qualify the last write count with the final write                                      
	 // response. This demonstrates how to confirm that a write has been                                        
	 // committed.                                                                                              
	                                                                                                            
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0)
			writes_done <= 1'b0;                                                                                   
		else if(init_rx_pulse == 1'b1)
			writes_done <= 1'b0;                                                                                   
		//The writes_done should be associated with a bready response                                           
		//else if (M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
		else if (M_AXI_BVALID && (write_burst_counter[C_NO_BURSTS_REQ]) && axi_bready)                          
			writes_done <= 1'b1;                                                                                  
		else                                                                                                    
			writes_done <= writes_done;                                                                           
	end                                                                                                     
																																																						
	// burst_read_active signal is asserted when there is a burst write transaction                           
	// is initiated by the assertion of start_single_burst_write. start_single_burst_read                     
	// signal remains asserted until the burst read is accepted by the master                                 
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0)
			burst_read_active <= 1'b0;                                                                            
		else if (init_rx_pulse == 1'b1)
			burst_read_active <= 1'b0;                                                                            
		//The burst_write_active is asserted when a write burst transaction is initiated                        
		else if (start_single_burst_read)                                                                       
			burst_read_active <= 1'b1;                                                                            
		else if (M_AXI_RVALID && axi_rready && M_AXI_RLAST)                                                     
			burst_read_active <= 0;                                                                               
	end                                                                                                     
	                                                                                                            
	                                                                                                            
	 // Check for last read completion.                                                                         
	                                                                                                            
	 // This logic is to qualify the last read count with the final read                                        
	 // response. This demonstrates how to confirm that a read has been                                         
	 // committed.                                                                                              
	                                                                                                            
	always @(posedge M_AXI_ACLK) begin                                                                                                     
		if (M_AXI_ARESETN == 0)
			reads_done <= 1'b0;                                                                                   
		else if(init_rx_pulse == 1'b1)
			reads_done <= 1'b0;                                                                                   
		//The reads_done should be associated with a rready response                                            
		//else if (M_AXI_BVALID && axi_bready && (write_burst_counter == {(C_NO_BURSTS_REQ-1){1}}) && axi_wlast)
		else if (M_AXI_RVALID && axi_rready && (read_index == read_burst_length) && (read_burst_counter[C_NO_BURSTS_REQ]))
			reads_done <= 1'b1;                                                                                   
		else                                                                                                    
			reads_done <= reads_done;                                                                             
	end                                                                                                     

	// Add user logic here

	// User logic ends

endmodule
