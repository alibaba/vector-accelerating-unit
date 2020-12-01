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

`include "shared_library.sv"

module gemm_core_top # (
	parameter integer BURST_LENGTH_WIDTH  = 8,		//width of AXI burst length
	parameter integer BURST_SIZE_WIDTH  = 3,		//width of AXI burst size
	parameter BLOCK_SIZE_WIDTH = 6,			//width of block size
	parameter CMD_WORD_WIDTH = 32,			//width of cmd word
	parameter CMD_WORD_NUM = 3,				//number of cmd input word
	parameter RSP_WORD_NUM = 1,				//number of response output word
	parameter XOCC_REG_NUM = 2,				//number of register between gemm and xocc cmd_fifo
	parameter ADDRESS_WIDTH = 32,			//width of address in xocc command
	parameter MAC_PRECISION    = 4,       // 1: INT8; 2: FP16; 3: BF16; 4: FP32
	parameter SYS_ARRAY_NUM    = 1,    		//number of systolic array
	parameter SYS_ARRAY_HEIGHT = 16,     // Systolic Array Height = 32            
	parameter SYS_ARRAY_WIDTH  = 16,     // Systolic Array Width  = 32    
	parameter ACT_WIDTH       = 32,       // Activation Data Width
	parameter WT_WIDTH        = 32,       // Weight     Data Width        
	parameter ACC_WIDTH       = 32,      // Accumulation Data Width
	parameter WEIGHT_READ_STRIDE = 0,	
	parameter ADDER_LATENCY = 2,		//latency of adder in mac
	parameter MULT_LATENCY = 1,			//latency of multiplier in mac, mac latency is ADDER_LATENCY+MULT_LATENCY+1, 1 refers to a register between multiplier and adder
	parameter ACC_LATENCY = 2,			//latency of adder in accumulator

	// Parameters of Axi Master Bus Interface M00_AXI
	parameter integer C_M00_AXI_ID_WIDTH	= 1,
	parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
	parameter integer C_M00_AXI_DATA_WIDTH	= SYS_ARRAY_NUM*SYS_ARRAY_WIDTH*ACT_WIDTH,
	// Parameters of Axi Master Bus Interface M01_AXI
	parameter integer C_M01_AXI_ID_WIDTH	= 1,
	parameter integer C_M01_AXI_ADDR_WIDTH	= 32,
	parameter integer C_M01_AXI_DATA_WIDTH	= SYS_ARRAY_NUM*SYS_ARRAY_WIDTH*ACT_WIDTH
) (
	input wire  axi_aclk,
	input wire  axi_aresetn,
	input  wire [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_in,
	input  wire dsa_clk,
	input  wire cmd_fifo_empty,
	input  wire rsp_fifo_full,
	output reg  cmd_fifo_rd_en,
	output reg  rsp_fifo_wr_en,
	output reg [RSP_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_out,


	// Ports of Axi Master Bus Interface M00_AXI
	output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
	output wire [7 : 0] m00_axi_awlen,
	output wire [2 : 0] m00_axi_awsize,
	output wire [1 : 0] m00_axi_awburst,
	output wire  m00_axi_awlock,
	output wire [3 : 0] m00_axi_awcache,
	output wire [2 : 0] m00_axi_awprot,
	output wire [3 : 0] m00_axi_awqos,
	output wire  m00_axi_awvalid,
	input wire  m00_axi_awready,
	output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
	output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
	output wire  m00_axi_wlast,
	output wire  m00_axi_wvalid,
	input wire  m00_axi_wready,
	input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
	input wire [1 : 0] m00_axi_bresp,
	input wire  m00_axi_bvalid,
	output wire  m00_axi_bready,
	output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
	output wire [7 : 0] m00_axi_arlen,
	output wire [2 : 0] m00_axi_arsize,
	output wire [1 : 0] m00_axi_arburst,
	output wire  m00_axi_arlock,
	output wire [3 : 0] m00_axi_arcache,
	output wire [2 : 0] m00_axi_arprot,
	output wire [3 : 0] m00_axi_arqos,
	output wire  m00_axi_arvalid,
	input wire  m00_axi_arready,
	input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
	input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
	input wire [1 : 0] m00_axi_rresp,
	input wire  m00_axi_rlast,
	input wire  m00_axi_rvalid,
	output wire  m00_axi_rready,

	// Ports of Axi Master Bus Interface M01_AXI
	output wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_awid,
	output wire [C_M01_AXI_ADDR_WIDTH-1 : 0] m01_axi_awaddr,
	output wire [7 : 0] m01_axi_awlen,
	output wire [2 : 0] m01_axi_awsize,
	output wire [1 : 0] m01_axi_awburst,
	output wire  m01_axi_awlock,
	output wire [3 : 0] m01_axi_awcache,
	output wire [2 : 0] m01_axi_awprot,
	output wire [3 : 0] m01_axi_awqos,
	output wire  m01_axi_awvalid,
	input wire  m01_axi_awready,
	output wire [C_M01_AXI_DATA_WIDTH-1 : 0] m01_axi_wdata,
	output wire [C_M01_AXI_DATA_WIDTH/8-1 : 0] m01_axi_wstrb,
	output wire  m01_axi_wlast,
	output wire  m01_axi_wvalid,
	input wire  m01_axi_wready,
	input wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_bid,
	input wire [1 : 0] m01_axi_bresp,
	input wire  m01_axi_bvalid,
	output wire  m01_axi_bready,
	output wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_arid,
	output wire [C_M01_AXI_ADDR_WIDTH-1 : 0] m01_axi_araddr,
	output wire [7 : 0] m01_axi_arlen,
	output wire [2 : 0] m01_axi_arsize,
	output wire [1 : 0] m01_axi_arburst,
	output wire  m01_axi_arlock,
	output wire [3 : 0] m01_axi_arcache,
	output wire [2 : 0] m01_axi_arprot,
	output wire [3 : 0] m01_axi_arqos,
	output wire  m01_axi_arvalid,
	input wire  m01_axi_arready,
	input wire [C_M01_AXI_ID_WIDTH-1 : 0] m01_axi_rid,
	input wire [C_M01_AXI_DATA_WIDTH-1 : 0] m01_axi_rdata,
	input wire [1 : 0] m01_axi_rresp,
	input wire  m01_axi_rlast,
	input wire  m01_axi_rvalid,
	output wire  m01_axi_rready
);

	wire [BURST_LENGTH_WIDTH-1:0] m00_write_burst_length;
	wire [BURST_LENGTH_WIDTH-1:0] m00_read_burst_length;
	wire [BURST_SIZE_WIDTH-1:0]   m00_write_burst_size;
	wire [BURST_SIZE_WIDTH-1:0]   m00_read_burst_size;
	wire m00_init_write;
	wire m00_init_read;
	wire [ADDRESS_WIDTH-1:0] axi0_read_start_address;
	wire [ADDRESS_WIDTH-1:0] axi1_read_start_address;
	wire [ADDRESS_WIDTH-1:0] axi0_write_start_address;
	wire [ADDRESS_WIDTH-1:0] axi1_write_start_address;
	wire [C_M00_AXI_ADDR_WIDTH-1:0] m00_write_start_address;
	wire [C_M00_AXI_ADDR_WIDTH-1:0] m00_read_start_address;
	wire [BURST_LENGTH_WIDTH-1:0] m01_write_burst_length;
	wire [BURST_LENGTH_WIDTH-1:0] m01_read_burst_length;
	wire [BURST_SIZE_WIDTH-1:0]   m01_write_burst_size;
	wire [BURST_SIZE_WIDTH-1:0]   m01_read_burst_size;
	wire m01_init_write;
	wire m01_init_read;
	wire [C_M01_AXI_ADDR_WIDTH-1:0] m01_write_start_address;
	wire [C_M01_AXI_ADDR_WIDTH-1:0] m01_read_start_address;
	wire [C_M01_AXI_DATA_WIDTH-1:0] gemm_write_data;
	wire  m01_axi_error, m00_axi_error;

	assign m00_write_start_address = {{(C_M00_AXI_ADDR_WIDTH-ADDRESS_WIDTH){1'b0}}, axi0_write_start_address};
	assign m01_write_start_address = {{(C_M01_AXI_ADDR_WIDTH-ADDRESS_WIDTH){1'b0}}, axi1_write_start_address};
	assign m00_read_start_address = {{(C_M00_AXI_ADDR_WIDTH-ADDRESS_WIDTH){1'b0}}, axi0_read_start_address};
	assign m01_read_start_address = {{(C_M01_AXI_ADDR_WIDTH-ADDRESS_WIDTH){1'b0}}, axi1_read_start_address};

	reg rst_axi0, rst_axi1, rst_dpe, rst_xocc;
	`DFF(rst_axi0, axi_aresetn, axi_aclk)
	`DFF(rst_axi1, axi_aresetn, axi_aclk)
	`DFF(rst_dpe, axi_aresetn, axi_aclk)
	`DFF(rst_xocc, axi_aresetn, axi_aclk)

// Instantiation of Axi Bus Interface M00_AXI
	gemm_axim_top # ( 
		.BURST_LENGTH_WIDTH(BURST_LENGTH_WIDTH), 
		.BURST_SIZE_WIDTH(BURST_SIZE_WIDTH), 
		.C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH)
	) gemm_axim_M00_AXI_inst (
		.write_burst_length(m00_write_burst_length),
		.write_burst_size(m00_write_burst_size),
		.read_burst_length(m00_read_burst_length),
		.read_burst_size(m00_read_burst_size),
		.write_start_address(m00_write_start_address),
		.read_start_address(m00_read_start_address),
		.write_data({C_M00_AXI_DATA_WIDTH{1'b0}}),
		.init_write(m00_init_write),
		.init_read(m00_init_read),
		.read_enable(axi0_read_enable),
		.write_enable(1'b1),
		.TX_DONE(axi0_tx_done),
		.RX_DONE(axi0_rx_done),
		.ERROR(m00_axi_error),
		.M_AXI_ACLK(axi_aclk),
		.M_AXI_ARESETN(rst_axi0),
		.M_AXI_AWID(m00_axi_awid),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWLEN(m00_axi_awlen),
		.M_AXI_AWSIZE(m00_axi_awsize),
		.M_AXI_AWBURST(m00_axi_awburst),
		.M_AXI_AWLOCK(m00_axi_awlock),
		.M_AXI_AWCACHE(m00_axi_awcache),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWQOS(m00_axi_awqos),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WLAST(m00_axi_wlast),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BID(m00_axi_bid),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARID(m00_axi_arid),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARLEN(m00_axi_arlen),
		.M_AXI_ARSIZE(m00_axi_arsize),
		.M_AXI_ARBURST(m00_axi_arburst),
		.M_AXI_ARLOCK(m00_axi_arlock),
		.M_AXI_ARCACHE(m00_axi_arcache),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARQOS(m00_axi_arqos),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RID(m00_axi_rid),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RLAST(m00_axi_rlast),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);

// Instantiation of Axi Bus Interface M01_AXI
	gemm_axim_top # ( 
		.BURST_LENGTH_WIDTH(BURST_LENGTH_WIDTH), 
		.BURST_SIZE_WIDTH(BURST_SIZE_WIDTH), 
		.C_M_AXI_ID_WIDTH(C_M01_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M01_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M01_AXI_DATA_WIDTH)
	) gemm_axim_M01_AXI_inst (
		.write_burst_length(m01_write_burst_length),
		.write_burst_size(m01_write_burst_size),
		.read_burst_length(m01_read_burst_length),
		.read_burst_size(m01_read_burst_size),
		.write_start_address(m01_write_start_address),
		.read_start_address(m01_read_start_address),
		.write_data(gemm_write_data),
		.init_write(m01_init_write),
		.init_read(m01_init_read),
		.read_enable(axi1_read_enable),
		.write_enable(axi1_write_enable),
		.TX_DONE(axi1_tx_done),
		.RX_DONE(axi1_rx_done),
		.ERROR(m01_axi_error),
		.M_AXI_ACLK(axi_aclk),
		.M_AXI_ARESETN(rst_axi1),
		.M_AXI_AWID(m01_axi_awid),
		.M_AXI_AWADDR(m01_axi_awaddr),
		.M_AXI_AWLEN(m01_axi_awlen),
		.M_AXI_AWSIZE(m01_axi_awsize),
		.M_AXI_AWBURST(m01_axi_awburst),
		.M_AXI_AWLOCK(m01_axi_awlock),
		.M_AXI_AWCACHE(m01_axi_awcache),
		.M_AXI_AWPROT(m01_axi_awprot),
		.M_AXI_AWQOS(m01_axi_awqos),
		.M_AXI_AWVALID(m01_axi_awvalid),
		.M_AXI_AWREADY(m01_axi_awready),
		.M_AXI_WDATA(m01_axi_wdata),
		.M_AXI_WSTRB(),
		.M_AXI_WLAST(m01_axi_wlast),
		.M_AXI_WVALID(m01_axi_wvalid),
		.M_AXI_WREADY(m01_axi_wready),
		.M_AXI_BID(m01_axi_bid),
		.M_AXI_BRESP(m01_axi_bresp),
		.M_AXI_BVALID(m01_axi_bvalid),
		.M_AXI_BREADY(m01_axi_bready),
		.M_AXI_ARID(m01_axi_arid),
		.M_AXI_ARADDR(m01_axi_araddr),
		.M_AXI_ARLEN(m01_axi_arlen),
		.M_AXI_ARSIZE(m01_axi_arsize),
		.M_AXI_ARBURST(m01_axi_arburst),
		.M_AXI_ARLOCK(m01_axi_arlock),
		.M_AXI_ARCACHE(m01_axi_arcache),
		.M_AXI_ARPROT(m01_axi_arprot),
		.M_AXI_ARQOS(m01_axi_arqos),
		.M_AXI_ARVALID(m01_axi_arvalid),
		.M_AXI_ARREADY(m01_axi_arready),
		.M_AXI_RID(m01_axi_rid),
		.M_AXI_RDATA(m01_axi_rdata),
		.M_AXI_RRESP(m01_axi_rresp),
		.M_AXI_RLAST(m01_axi_rlast),
		.M_AXI_RVALID(m01_axi_rvalid),
		.M_AXI_RREADY(m01_axi_rready)
	);

	wire [BLOCK_SIZE_WIDTH-1:0] block_size;
	reg [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_in_reg;
	reg cmd_fifo_empty_reg;
	reg rsp_fifo_full_reg;
	wire cmd_fifo_rd_en_reg;
	wire rsp_fifo_wr_en_reg;
	wire [RSP_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_out_reg;

	`DFF_RST(xocc_cmd_in_reg, xocc_cmd_in, axi_aresetn, axi_aclk)
	`DFF_RST(cmd_fifo_empty_reg, cmd_fifo_empty, axi_aresetn, axi_aclk)
	`DFF_RST(rsp_fifo_full_reg, rsp_fifo_full, axi_aresetn, axi_aclk)
	`DFF_RST(cmd_fifo_rd_en, cmd_fifo_rd_en_reg, axi_aresetn, axi_aclk)
	`DFF_RST(rsp_fifo_wr_en, rsp_fifo_wr_en_reg, axi_aresetn, axi_aclk)
	`DFF_RST(xocc_cmd_out, xocc_cmd_out_reg, axi_aresetn, axi_aclk)

	xocc_interface # (
		.CMD_WORD_WIDTH(CMD_WORD_WIDTH),
		.CMD_WORD_NUM(CMD_WORD_NUM),
		.RSP_WORD_NUM(RSP_WORD_NUM),
		.XOCC_REG_NUM(XOCC_REG_NUM),
		.BURST_LENGTH_WIDTH(BURST_LENGTH_WIDTH),
		.BURST_SIZE_WIDTH(BURST_SIZE_WIDTH),
		.BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH),
		.SYS_ARRAY_SIZE(SYS_ARRAY_WIDTH),
		.WEIGHT_READ_STRIDE(WEIGHT_READ_STRIDE),
		.ADDRESS_WIDTH(ADDRESS_WIDTH)
	) U_xocc_interface (
		.xocc_cmd_in			(xocc_cmd_in_reg),
		.clk							(dsa_clk),
		.rst							(rst_xocc),
		.cmd_fifo_rd_en		(cmd_fifo_rd_en_reg),
		.rsp_fifo_wr_en		(rsp_fifo_wr_en_reg),
		.cmd_fifo_empty		(cmd_fifo_empty_reg),
		.rsp_fifo_full		(rsp_fifo_full_reg),
		.xocc_cmd_out			(xocc_cmd_out_reg),
		.axi0_rvalid			(m00_axi_rvalid),
		.axi1_rvalid			(m01_axi_rvalid),
		.axi1_wready			(m01_axi_wready),
		.axi1_wvalid			(m01_axi_wvalid),
		.axi0_read_enable	(axi0_read_enable),
		.axi1_read_enable	(axi1_read_enable),
		.axi1_write_enable(axi1_write_enable),
		.clk_gate_en			(clk_gate_en),
		.axi0_rx_done			(axi0_rx_done),
		.axi0_tx_done			(axi0_tx_done),
		.axi1_rx_done			(axi1_rx_done),
		.axi1_tx_done			(axi1_tx_done),
		.axi0_read_burst_length		(m00_read_burst_length),
		.axi0_write_burst_length	(m00_write_burst_length),
		.axi0_read_burst_size			(m00_read_burst_size),
		.axi0_write_burst_size		(m00_write_burst_size),
		.axi0_read_start_address	(axi0_read_start_address),
		.axi0_write_start_address	(axi0_write_start_address),
		.axi0_init_read						(m00_init_read),
		.axi0_init_write					(m00_init_write),
		.axi1_read_burst_length		(m01_read_burst_length),
		.axi1_write_burst_length	(m01_write_burst_length),
		.axi1_read_burst_size			(m01_read_burst_size),
		.axi1_write_burst_size		(m01_write_burst_size),
		.axi1_read_start_address	(axi1_read_start_address),
		.axi1_write_start_address	(axi1_write_start_address),
		.axi1_init_read			(m01_init_read),
		.axi1_init_write		(m01_init_write),
		.gemm_done					(gemm_done),
		.output_valid				(output_valid),
		.block_size					(block_size),
		.bias_load_en				(bias_load_en),
		.relu_en						(relu_en),
		.start_op						(start_op),
		.write_back					(write_back),
		.clear_buffer				(clear_buffer),
		.auto_re_req				(auto_re_req),
		.invalid_command		(invalid_command)
	);
	
	wire [SYS_ARRAY_WIDTH*ACC_WIDTH-1:0] acc_mem_wrdata;
`ifdef SYS_ARRAY_NUM_2
	assign m01_axi_wstrb = {{(C_M01_AXI_DATA_WIDTH/16){auto_re_req}}, {(C_M01_AXI_DATA_WIDTH/16){~auto_re_req}}};
	assign gemm_write_data[C_M01_AXI_DATA_WIDTH-1:C_M01_AXI_DATA_WIDTH/2] = {(C_M01_AXI_DATA_WIDTH/2){~auto_re_req}} & acc_mem_wrdata;
	assign gemm_write_data[C_M01_AXI_DATA_WIDTH/2-1:0] = {(C_M01_AXI_DATA_WIDTH/2){auto_re_req}} & acc_mem_wrdata;
`else
	assign m01_axi_wstrb = {{(C_M01_AXI_DATA_WIDTH/8){1'b1}}};
	assign gemm_write_data[C_M01_AXI_DATA_WIDTH-1:0] = acc_mem_wrdata;
`endif

	wire axi_aclk_gt;
	reg [C_M00_AXI_DATA_WIDTH-1:0] bias_wt_mem_rdata_ff;
	wire [C_M00_AXI_DATA_WIDTH-1:0] bias_wt_mem_rdata;
	reg [C_M01_AXI_DATA_WIDTH-1:0] act_mem_rdata;

	wl_clkgate # (
		.CLK_NUM (1)
	) u_wl_clkgate0 (
		.clk_i (axi_aclk)
		,.dft_se (1'b0)
		,.en (~clk_gate_en)
		,.clk_o (axi_aclk_gt)
	);

	`DFF_RST(bias_wt_mem_rdata_ff, m00_axi_rdata, axi_aresetn, axi_aclk_gt)
	`DFF_RST(act_mem_rdata, m01_axi_rdata, axi_aresetn, axi_aclk_gt)
	assign bias_wt_mem_rdata = bias_load_en ? m00_axi_rdata : bias_wt_mem_rdata_ff;

	DPE #(
		.MAC_PRECISION(MAC_PRECISION),
		.SYS_ARRAY_HEIGHT(SYS_ARRAY_HEIGHT),
		.SYS_ARRAY_WIDTH(SYS_ARRAY_WIDTH),
		.SYS_ARRAY_NUM(SYS_ARRAY_NUM),
		.BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH),
		.ADDER_LATENCY(ADDER_LATENCY),
		.MULT_LATENCY(MULT_LATENCY),
		.ACC_LATENCY(ACC_LATENCY),
		.ACT_WIDTH(ACT_WIDTH), 
		.WT_WIDTH(WT_WIDTH),
		.ACC_WIDTH(ACC_WIDTH)
	) U_dpe (
		//Inputs
		.clk            	(axi_aclk_gt),
		.reset          	(rst_dpe),
		.start_op 				(start_op),
		.block_size     	(block_size),
		.bias_load_en			(bias_load_en & m00_axi_rready),
		.relu_en					(relu_en),
		.acc_buffer_sel		(auto_re_req),
		.bias_wt_mem_rdata(bias_wt_mem_rdata),
		.act_mem_rdata  	(act_mem_rdata),
		//Outputs,
		.acc_mem_wrdata 	(acc_mem_wrdata),
		.r_depend       	(r_depend),
		.w_depend       	(w_depend),
		.write_back				(write_back),
		.done           	(gemm_done),
		.output_valid			(output_valid),
		.clear_buffer			(clear_buffer)
	);

endmodule
