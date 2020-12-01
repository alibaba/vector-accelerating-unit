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

module xocc_decoder #(
  parameter CMD_WORD_WIDTH = 32,
  parameter CMD_WORD_NUM = 3,
  parameter RSP_WORD_NUM = 1,
  parameter XOCC_REG_NUM = 2,
  parameter BURST_LENGTH_WIDTH = 5,
  parameter BURST_SIZE_WIDTH = 3,
  parameter ADDRESS_WIDTH = 32,
  parameter BLOCK_SIZE_WIDTH = 6,
  parameter SYS_ARRAY_SIZE = 16
)(
  input  wire [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] i_cmd,
  input  wire clk,
  input  wire reset_n,
  input  wire cmd_fifo_empty,
  input  wire gemm_cmd_fifo_empty,
  input  wire gemm_cmd_fifo_almost_full,
  input  wire rsp_fifo_full,
  output reg  cmd_fifo_rd_en,
  output reg  gemm_cmd_fifo_pop_en,
  output reg  gemm_cmd_fifo_push_en,
  output reg  rsp_fifo_wr_en,
  output reg [RSP_WORD_NUM*CMD_WORD_WIDTH-1:0] cmd_o,

  input  gemm_done,
  input  gemm_idle,
  input  output_valid,
  output reg [4:0][31:0] group_data,
  output reg group_push,
  output reg invalid_command
);

	localparam BURST_SIZE_VALUE = $clog2(SYS_ARRAY_SIZE*4);

	reg [CMD_WORD_NUM*CMD_WORD_WIDTH-1:0] command_in;
	reg rd_en, wr_en;
	reg rd_en_dly;
	reg [RSP_WORD_NUM*CMD_WORD_WIDTH-1:0] command_out;
	reg silent_mode;
	wire detect_start;

	assign detect_start = i_cmd[5];

	`DFF_EN_RST(command_in, i_cmd, gemm_cmd_fifo_push_en, reset_n, clk)

	reg first_operation;//first operation after reset
    always@(posedge clk) begin
		if(!reset_n)
			first_operation <= 'b1;
		else if(~gemm_done)
			first_operation <= 'b0;
		else 
			first_operation <= first_operation;
	end

	//initial write when gemm complete and rsp_fifo not full
  always@(posedge clk) begin
		if(!reset_n) begin
      wr_en <= 'b0;
			command_out <= 'b0;
		end
		else if(!rsp_fifo_full & gemm_idle & (~first_operation) & (~silent_mode)) begin
      wr_en <= 1'b1;
			command_out <= 'b1;		//finish
		end else begin
      wr_en <= 'b0;
			command_out <= 'b0;
		end
	end

  always@(posedge clk) begin
		if(!reset_n) begin
      rd_en <= 'b0;
		end
		//else if((detect_start & gemm_idle & rd_en) || ~gemm_idle) begin
		//	rd_en <= 1'b0;
		//end
		else if(~cmd_fifo_empty) begin
      rd_en <= 1'b1;
		end else begin
			rd_en <= 'b0;
		end
	end

	always@(posedge clk) begin
		if(!reset_n) begin
		    gemm_cmd_fifo_pop_en <= 'b0;
		end else if((detect_start & gemm_idle & gemm_cmd_fifo_pop_en) || ~gemm_idle) begin
			gemm_cmd_fifo_pop_en <= 1'b0;
		end else if(~gemm_cmd_fifo_empty && (gemm_idle & gemm_done | first_operation)) begin
		    gemm_cmd_fifo_pop_en <= 1'b1;
		end else begin
			gemm_cmd_fifo_pop_en <= 'b0;
		end
	end

	data_shift_reg # (
		.ARRAY_DEPTH (XOCC_REG_NUM*2),  
		.ARRAY_WIDTH (1)
	) u_rd_en_staging_reg (
		.clk (clk),
		.reset (reset_n),
		.en (1'b1),
		.data_i (rd_en),
		.data_o (rd_en_dly)
	);

	assign gemm_cmd_fifo_push_en = rd_en & rd_en_dly & ~cmd_fifo_empty;
  assign cmd_fifo_rd_en = rd_en;
	assign cmd_o = command_out;
	assign rsp_fifo_wr_en = wr_en;

	wire [5:0] operation = i_cmd[5:0];

	localparam GEMM_READ_WEIGHT     = 6'b000100;
	localparam GEMM_READ_ATTRIBUTE 	= 6'b000101;
	localparam GEMM_READ_BIAS	   	  = 6'b000110;
	localparam GEMM_START		   	    = 6'b1xxxxx;

  reg [ADDRESS_WIDTH-1:0] bias_read_start_address;
  reg [ADDRESS_WIDTH-1:0] weight_read_start_address;
  reg [ADDRESS_WIDTH-1:0] attribute_read_start_address;
  reg [ADDRESS_WIDTH-1:0] acc_write_start_address;

	reg bias, relu, clear, partial;
	reg [BLOCK_SIZE_WIDTH-1:0] block_size;

	always@(posedge clk) begin
		if(!reset_n) begin
			group_push <= 'b0;
			bias_read_start_address <= 'b0;
			attribute_read_start_address <= 'b0;
			weight_read_start_address <= 'b0;
			acc_write_start_address <= 'b0;
			invalid_command <= 'b0;
			bias <= 1'b0;
			relu <= 1'b0;
			clear <= 1'b0;
			partial <= 1'b0;
			block_size <= 'b0;
			silent_mode <= 1'b0;
			invalid_command <= 1'b0;
    end else begin
			if(gemm_cmd_fifo_pop_en) begin
				group_push <= 'b0;
				casex(operation)
          GEMM_READ_WEIGHT:	begin
            weight_read_start_address <= i_cmd[ADDRESS_WIDTH-1+CMD_WORD_WIDTH*2:CMD_WORD_WIDTH*2];
          end
          GEMM_READ_ATTRIBUTE: begin
            attribute_read_start_address <= i_cmd[ADDRESS_WIDTH-1+CMD_WORD_WIDTH*2:CMD_WORD_WIDTH*2];
          end
          GEMM_READ_BIAS:	begin
            bias_read_start_address <= i_cmd[ADDRESS_WIDTH-1+CMD_WORD_WIDTH*2:CMD_WORD_WIDTH*2];
          end
          GEMM_START:	begin
            group_push <= 1'b1;
            silent_mode <= operation[4];
            bias <= operation[3];
            relu <= operation[2];
            clear <= operation[1];
            partial <= operation[0];
            block_size <= i_cmd[BLOCK_SIZE_WIDTH-1+CMD_WORD_WIDTH:CMD_WORD_WIDTH];
            acc_write_start_address <= i_cmd[ADDRESS_WIDTH-1+CMD_WORD_WIDTH*2:CMD_WORD_WIDTH*2];
          end
          default: begin
              invalid_command <= 1'b1;
          end
				endcase
			end else begin
				group_push <= 'b0;
			end
		end
	end

	assign group_data[0][BLOCK_SIZE_WIDTH-1:0] = block_size;
	assign group_data[0][BLOCK_SIZE_WIDTH:BLOCK_SIZE_WIDTH] = partial;
	assign group_data[0][BLOCK_SIZE_WIDTH+1:BLOCK_SIZE_WIDTH+1] = clear;
	assign group_data[0][BLOCK_SIZE_WIDTH+2:BLOCK_SIZE_WIDTH+2] = relu;
	assign group_data[0][BLOCK_SIZE_WIDTH+3:BLOCK_SIZE_WIDTH+3] = bias;
	assign group_data[1][ADDRESS_WIDTH-1:0] = acc_write_start_address;
	assign group_data[2][ADDRESS_WIDTH-1:0] = bias_read_start_address;
	assign group_data[3][ADDRESS_WIDTH-1:0] = attribute_read_start_address;
	assign group_data[4][ADDRESS_WIDTH-1:0] = weight_read_start_address;

endmodule
