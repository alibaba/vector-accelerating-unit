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

module xocc_interface #(
	parameter CMD_WORD_WIDTH = 32,
	parameter CMD_WORD_NUM = 3,
	parameter CMD_FIFO_DEPTH = 16,
	parameter RSP_WORD_NUM = 1,
	parameter XOCC_REG_NUM = 2,
	parameter BURST_LENGTH_WIDTH = 8,
	parameter BURST_SIZE_WIDTH = 3,
	parameter BLOCK_SIZE_WIDTH = 6,
	parameter ADDRESS_WIDTH = 19,
	parameter SYS_ARRAY_SIZE = 16,
	parameter WEIGHT_READ_STRIDE = 0
)(
	input clk,rst,
	input  wire [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_in,
	input  wire cmd_fifo_empty,
	input  wire rsp_fifo_full,
	output wire cmd_fifo_rd_en,
	output wire rsp_fifo_wr_en,
	output wire [RSP_WORD_NUM*CMD_WORD_WIDTH-1:0] xocc_cmd_out,

	input  wire gemm_done,
	input  wire output_valid,
	output wire [BLOCK_SIZE_WIDTH-1:0] block_size,
	output wire bias_load_en,			
	output wire relu_en,				
	output wire start_op,				
	output wire write_back,				
	output wire clear_buffer,
	output wire invalid_command,

	input  wire axi0_rx_done,
	input  wire axi0_tx_done,
	input  wire axi1_rx_done,
	input  wire axi1_tx_done,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi0_read_burst_length,
	output wire [BURST_SIZE_WIDTH-1:0]	  axi0_read_burst_size,
	output wire [ADDRESS_WIDTH-1:0]       axi0_read_start_address,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi0_write_burst_length,
	output wire [BURST_SIZE_WIDTH-1:0]	  axi0_write_burst_size,
	output wire [ADDRESS_WIDTH-1:0]       axi0_write_start_address,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi1_read_burst_length,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi1_write_burst_length,
	output wire [BURST_SIZE_WIDTH-1:0]	  axi1_read_burst_size,
	output wire [BURST_SIZE_WIDTH-1:0]	  axi1_write_burst_size,
	output wire [ADDRESS_WIDTH-1:0]       axi1_read_start_address,
	output wire [ADDRESS_WIDTH-1:0]       axi1_write_start_address,
	output wire axi0_init_read,
	output wire axi0_init_write,
	output wire axi1_init_read,
	output wire axi1_init_write,
	input axi0_rvalid,
	input axi1_rvalid,
	input axi1_wready,
	input axi1_wvalid,
	output wire axi0_read_enable,
	output wire axi1_read_enable,
	output wire axi1_write_enable,
	output wire clk_gate_en,
	output wire auto_re_req
);

	wire [4:0][31:0] group_data;
	wire [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] fifo_dec_cmd_out;

  xocc_decoder # (
    .CMD_WORD_WIDTH(CMD_WORD_WIDTH),
    .CMD_WORD_NUM(CMD_WORD_NUM),
    .RSP_WORD_NUM(RSP_WORD_NUM),
    .XOCC_REG_NUM(XOCC_REG_NUM),
    .BURST_LENGTH_WIDTH(BURST_LENGTH_WIDTH),
    .BURST_SIZE_WIDTH(BURST_SIZE_WIDTH),
    .ADDRESS_WIDTH(ADDRESS_WIDTH),
    .BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH),
    .SYS_ARRAY_SIZE(SYS_ARRAY_SIZE)
	) u_xocc_decoder (
		.i_cmd          (fifo_dec_cmd_out),
		.clk            (clk),
		.reset_n				(rst),
		.cmd_fifo_rd_en (cmd_fifo_rd_en),
		.rsp_fifo_wr_en (rsp_fifo_wr_en),
		.cmd_fifo_empty (cmd_fifo_empty),
		.rsp_fifo_full  (rsp_fifo_full),
		.gemm_cmd_fifo_empty      (gemm_cmd_fifo_empty),
		.gemm_cmd_fifo_almost_full(gemm_cmd_fifo_almost_full),
		.gemm_cmd_fifo_pop_en	    (gemm_cmd_fifo_pop_en),
		.gemm_cmd_fifo_push_en	  (gemm_cmd_fifo_push_en),
		.cmd_o            (xocc_cmd_out),
		.gemm_done				(gemm_done),
		.gemm_idle				(gemm_idle),
		.output_valid			(output_valid),
		.group_data				(group_data),
		.group_push       (group_push),
		.invalid_command  ()
	);

	group_dispatch #(
		.BLOCK_SIZE_WIDTH(BLOCK_SIZE_WIDTH),
		.ADDRESS_WIDTH(ADDRESS_WIDTH),
		.BURST_SIZE_WIDTH(BURST_SIZE_WIDTH),
		.BURST_LENGTH_WIDTH(BURST_LENGTH_WIDTH),
		.SYS_ARRAY_SIZE(SYS_ARRAY_SIZE),
		.WEIGHT_READ_STRIDE(WEIGHT_READ_STRIDE)
	) u_group_dispatch(
		.clk (clk),
		.reset (rst),
		.group_data				(group_data),
		.group_push				(group_push),
		.gemm_done				(gemm_done),
		.output_valid			(output_valid),
		.axi0_rvalid			(axi0_rvalid),
		.axi1_rvalid			(axi1_rvalid),
		.axi1_wready			(axi1_wready),
		.axi1_wvalid			(axi1_wvalid),
		.block_size				(block_size),
		.bias_read_valid  (bias_load_en),
		.relu_en				  (relu_en),
		.start_op				  (start_op),
		.write_back				(write_back),
		.clear_buffer			(clear_buffer),
		.axi0_rx_done			(axi0_rx_done),
		.axi0_tx_done			(axi0_tx_done),
		.axi1_rx_done			(axi1_rx_done),
		.axi1_tx_done			(axi1_tx_done),
		.axi0_init_read   (axi0_init_read),
		.axi0_init_write  (axi0_init_write),
		.axi1_init_read   (axi1_init_read),
		.axi1_init_write  (axi1_init_write),
		.axi0_read_enable (axi0_read_enable),
		.axi1_read_enable (axi1_read_enable),
		.axi1_write_enable(axi1_write_enable),
		.clk_gate_en			(clk_gate_en),
		.auto_re_req			(auto_re_req),
		.gemm_idle				(gemm_idle),
		.axi0_read_burst_length	  (axi0_read_burst_length),
		.axi0_read_burst_size	    (axi0_read_burst_size),
		.axi0_read_start_address  (axi0_read_start_address),
		.axi0_write_burst_length  (axi0_write_burst_length),
		.axi0_write_burst_size	  (axi0_write_burst_size),
		.axi0_write_start_address (axi0_write_start_address),
		.axi1_read_burst_length	  (axi1_read_burst_length),
		.axi1_read_burst_size	    (axi1_read_burst_size),
		.axi1_read_start_address  (axi1_read_start_address),
		.axi1_write_burst_length  (axi1_write_burst_length),
		.axi1_write_burst_size	  (axi1_write_burst_size),
		.axi1_write_start_address (axi1_write_start_address)
	);

	fifo_16x96 U_gemm_cmd_fifo (
	  .srst(~rst),                    // input wire rst
	  .clk(clk),              // input wire wr_clk
	  //.rd_clk(clk),              // input wire rd_clk
	  .din(xocc_cmd_in),                    // input wire [95 : 0] din
	  .wr_en(gemm_cmd_fifo_push_en),                // input wire wr_en
	  .rd_en(gemm_cmd_fifo_pop_en),                // input wire rd_en
	  .dout(fifo_dec_cmd_out),                  // output wire [95 : 0] dout
	  .full(),                  // output wire full
	  .prog_empty_thresh_assert(1),  // input wire [3 : 0] prog_empty_thresh_assert
    .prog_empty_thresh_negate(1),  // input wire [3 : 0] prog_empty_thresh_negate
	  .almost_full(gemm_cmd_fifo_almost_full),    // output wire almost_full
	  .empty(gemm_cmd_fifo_empty),                // output wire empty
	  .almost_empty(),  // output wire almost_empty
	  .wr_rst_busy(),    // output wire wr_rst_busy
	  .rd_rst_busy()    // output wire rd_rst_busy
  );

endmodule
