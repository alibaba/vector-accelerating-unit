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

module group_dispatch #(
	parameter BURST_LENGTH_WIDTH = 8,
	parameter BURST_SIZE_WIDTH = 3,
	parameter ADDRESS_WIDTH = 19,
	parameter BLOCK_SIZE_WIDTH = 6,
	parameter SYS_ARRAY_SIZE = 16,
	parameter WEIGHT_READ_STRIDE = 0,
	parameter FIFO_WIDTH = 32,
	parameter FIFO_NUM   = 5,
	parameter FIFO_DEPTH = 16
)(
	input	clk,
	input	reset,
	input	group_push,			//push group_data
	input [FIFO_NUM-1:0][FIFO_WIDTH-1:0]	group_data,			//include all information to initiate a gemm operation
	input	gemm_done,
	input	output_valid,
	input	axi0_rvalid,
	input	axi1_rvalid,
	input	axi1_wready,
	input	axi1_wvalid,
	output wire [BLOCK_SIZE_WIDTH-1:0]	block_size,
	output wire	bias_read_valid,			//load bias
	output reg	relu_en,				//enable ReLU operation
	output reg	start_op,				//gemm start
	output wire	write_back,				//write output of accumulator to memory
	output reg	clear_buffer,		    //clear acc_buffer in accumulator
	input  wire	axi0_rx_done,
	input  wire	axi0_tx_done,
	input  wire	axi1_rx_done,
	input  wire	axi1_tx_done,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi0_read_burst_length,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi0_write_burst_length,
	output wire [BURST_SIZE_WIDTH-1:0]		axi0_read_burst_size,
	output wire [BURST_SIZE_WIDTH-1:0]		axi0_write_burst_size,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi1_read_burst_length,
	output wire [BURST_LENGTH_WIDTH-1:0]	axi1_write_burst_length,
	output wire [BURST_SIZE_WIDTH-1:0]		axi1_read_burst_size,
	output wire [BURST_SIZE_WIDTH-1:0]		axi1_write_burst_size,
	output wire [ADDRESS_WIDTH-1:0]     	axi0_read_start_address,
	output wire [ADDRESS_WIDTH-1:0]     	axi0_write_start_address,
	output wire [ADDRESS_WIDTH-1:0]     	axi1_read_start_address,
	output wire [ADDRESS_WIDTH-1:0]     	axi1_write_start_address,
	output wire	axi0_init_read,
	output wire	axi0_read_enable,
	output wire	axi0_init_write,
	output wire	axi1_init_read,
	output wire	axi1_read_enable,
	output wire	axi1_init_write,
	output wire	axi1_write_enable,
	output wire	clk_gate_en,
	output wire	gemm_idle,
	output wire	auto_re_req
);

	localparam BURST_SIZE_VALUE = $clog2(SYS_ARRAY_SIZE*4);
	localparam MAX_SINGLE_BLOCK_SIZE = (256/SYS_ARRAY_SIZE);
	localparam BLOCK_SIZE_CNT_WIDTH = $clog2(MAX_SINGLE_BLOCK_SIZE);

	assign axi0_write_start_address = 'b0;
	assign axi0_write_burst_size = 'b0;
	assign axi0_write_burst_length = 'b0;
	assign axi0_init_write = 1'b0;

	reg [ADDRESS_WIDTH-1:0]	bias_read_start_address;
	reg [ADDRESS_WIDTH-1:0]	weight_read_start_address;
	reg [ADDRESS_WIDTH-1:0]	attribute_read_start_address;
	reg [ADDRESS_WIDTH-1:0]	acc_write_start_address;
	reg bias_load_en;
	reg write_back_en;

	reg auto_request;	//automaticaly initiate two consecutive gemm operation to get output with size of 16x32
	reg auto_req_valid;
	wire retry=1'b0;			//retry due to axi error, TODO

	reg read_weight, read_bias, read_attribute, write_back_result;
	reg weight_read_done, attribute_read_done, write_back_done, bias_read_done;
	wire wait_attribute_valid;
	reg wait_attribute_valid_ff;
	reg start_operation;

	reg [8:0] cycle_cnt;
	
	reg axi0_rx_done_detec_valid;
	reg axi0_rx_done_ff;
	wire axi0_rx_done_pos;
	wire axi0_rx_done_neg;
	reg axi1_rx_done_detec_valid;
	reg axi1_rx_done_ff;
	wire axi1_rx_done_pos;
	wire axi1_rx_done_neg;

	reg group_push_dff;		
	`DFF_RST(group_push_dff, group_push, reset, clk)
	`DFF_RST(wait_attribute_valid_ff, wait_attribute_valid, reset, clk)

	reg [BLOCK_SIZE_WIDTH-1:0] k_blocks;
	reg [BLOCK_SIZE_WIDTH-BLOCK_SIZE_CNT_WIDTH:0] block_size_split_cnt;
	reg [ADDRESS_WIDTH-1:0] w_a_read_address_offset;

	always @(posedge clk) begin
		if(!reset) begin
			k_blocks <= 'b0;
			bias_load_en <= 'b0;
			relu_en <= 'b0;
			write_back_en <= 'b0;
			clear_buffer <= 'b0;
			bias_read_start_address <= 'b0;
			attribute_read_start_address <= 'b0;
			weight_read_start_address <= 'b0;
			acc_write_start_address <= 'b0;
		end else if(group_push) begin
			k_blocks <= group_data[0][BLOCK_SIZE_WIDTH-1:0];
			bias_load_en <= group_data[0][BLOCK_SIZE_WIDTH+3:BLOCK_SIZE_WIDTH+3];
			relu_en <= group_data[0][BLOCK_SIZE_WIDTH+2:BLOCK_SIZE_WIDTH+2];
			write_back_en <= ~group_data[0][BLOCK_SIZE_WIDTH:BLOCK_SIZE_WIDTH];
			clear_buffer <= group_data[0][BLOCK_SIZE_WIDTH+1:BLOCK_SIZE_WIDTH+1];
			weight_read_start_address <= group_data[4][ADDRESS_WIDTH-1:0];
			attribute_read_start_address <= group_data[3][ADDRESS_WIDTH-1:0];
			bias_read_start_address <= group_data[2][ADDRESS_WIDTH-1:0];
			acc_write_start_address <= group_data[1][ADDRESS_WIDTH-1:0];
		end else begin
			clear_buffer <= 'b0;
		end
	end

//---------------------------------------FSM for AXI operation--------------------------------------------------
	localparam IDLE = 3'b000,
	READ_BIAS 	= 3'b001,
	READ_W_A		= 3'b010,
	ACCUMULATE	= 3'b011,
	WRITE_BACK	= 3'b100;

	reg [2:0] cur_state, next_state;

	always @(posedge clk) begin
		if(!reset) begin
			cur_state <= 3'b0;
		end
		else begin
			cur_state <= next_state;
		end
	end

	always @(*) begin
		if(!reset) begin
			next_state <= IDLE;
		end else begin
			case(cur_state)
				IDLE: begin
					if(group_push_dff&gemm_done) begin
						if(bias_load_en) begin
							next_state <= READ_BIAS;
						end else begin
							next_state <= READ_W_A;
						end
					end else if((block_size_split_cnt > 0) && gemm_done) begin
						next_state <= READ_W_A;
					end else begin
						next_state <= IDLE;
					end
				end
				READ_BIAS: begin
					if(bias_read_done) begin
						next_state <= READ_W_A;
					end else begin
						next_state <= READ_BIAS;
					end
				end
				READ_W_A: begin
					if(weight_read_done & attribute_read_done) begin
						next_state <= ACCUMULATE;
					end else begin
						next_state <= READ_W_A;
					end
				end
				ACCUMULATE: begin
					if(output_valid) begin
						next_state <= WRITE_BACK;
					end else begin
						next_state <= ACCUMULATE;
					end
				end
				WRITE_BACK: begin
					if(write_back_done || ~write_back_en || (block_size_split_cnt > 1)) begin
						next_state <= IDLE;
					end else begin
						next_state <= WRITE_BACK;
					end
				end
				default:
					next_state <= IDLE;
			endcase
		end
	end

	always @(posedge clk) begin
		if(!reset) begin
			read_bias <= 1'b0;
			read_weight <= 1'b0;
			read_attribute <= 1'b0;
			write_back_result <= 1'b0;
			block_size_split_cnt <= 'd0;
			w_a_read_address_offset <= 'd0;
		end else begin
			case(cur_state)
				IDLE: begin
					if(group_push_dff) begin
						if(k_blocks > MAX_SINGLE_BLOCK_SIZE) begin
							block_size_split_cnt <= group_data[0][BLOCK_SIZE_WIDTH-1:BLOCK_SIZE_CNT_WIDTH] + |group_data[0][BLOCK_SIZE_CNT_WIDTH-1:0];
						end else begin
							block_size_split_cnt <= 'd0;
						end
						w_a_read_address_offset <= 'd0;
					end
				end//IDLE
				READ_BIAS: begin
					if(!read_bias) begin
						read_bias <= 1'b1;
					end else if(bias_read_done & read_bias) begin
						read_bias <= 1'b0;
					end else begin
						read_bias <= read_bias;
					end
				end//READ_BIAS
				READ_W_A: begin
					if(~read_weight & ~weight_read_done) begin
						read_weight <= 1'b1;
					end else if(weight_read_done & read_weight) begin
						read_weight <= 1'b0;
					end else begin
						read_weight <= read_weight;
					end

					if(!read_attribute & ~attribute_read_done) begin
						read_attribute <= 1'b1;
					end else if(attribute_read_done & read_attribute) begin
						read_attribute <= 1'b0;
					end else begin
						read_attribute <= read_attribute;
					end
				end//READ_W_A
				ACCUMULATE: begin
				end//ACCUMULATE
				WRITE_BACK: begin
					if(!write_back_result & write_back_en & (block_size_split_cnt <= 'd1)) begin
						write_back_result <= 1'b1;
					end else if(write_back_done & write_back_result) begin
						write_back_result <= 1'b0;
					end else begin
						write_back_result <= write_back_result;
					end

					if(block_size_split_cnt > 'd0) begin
						block_size_split_cnt <= block_size_split_cnt - 1'b1;
						w_a_read_address_offset <= w_a_read_address_offset + 256*SYS_ARRAY_SIZE*4;
					end
				end//WRITE_BACK
				default: begin
				end//default
			endcase
		end//else
	end//always
//---------------------------------------end of FSM--------------------------------------------------
//---------------------------------------operation split---------------------------------------------
	assign block_size = (k_blocks > MAX_SINGLE_BLOCK_SIZE) ? ((block_size_split_cnt <= 'd1) ? k_blocks[BLOCK_SIZE_CNT_WIDTH-1:0] : 'd16) : k_blocks;
//---------------------------------------------------------------------------------------------------

	assign gemm_idle = (cur_state == IDLE) && !(group_push_dff | group_push);

	always @(posedge clk) begin
		if(!reset) begin
			cycle_cnt <= 'd0;
		end else if(attribute_read_done) begin
			cycle_cnt <= 'b0;
		end else if(axi0_read_enable & read_weight) begin
			cycle_cnt <= cycle_cnt + 1'b1;
		end else begin
			cycle_cnt <= cycle_cnt;
		end
	end

	assign auto_req_valid = 1'b1;
	assign auto_request = 1'b0;
	assign auto_re_req = auto_req_valid;
	`POS_CHECK(axi0_rx_done_pos, axi0_rx_done, axi0_rx_done_ff, reset, clk)
	assign axi0_rx_done_neg = ~axi0_rx_done & axi0_rx_done_ff;

	always@(posedge clk) begin
		if(!reset) begin
			axi0_rx_done_detec_valid <= 1'b1;
		end else if(axi0_rx_done_pos) begin
			axi0_rx_done_detec_valid <= 1'b0;
		end else if(axi0_rx_done_neg) begin
			axi0_rx_done_detec_valid <= 1'b1;
		end
	end

	`POS_CHECK(axi1_rx_done_pos, axi1_rx_done, axi1_rx_done_ff, reset, clk)
	assign axi1_rx_done_neg = ~axi1_rx_done & axi1_rx_done_ff;

	always @(posedge clk) begin
		if(!reset) begin
			axi1_rx_done_detec_valid <= 1'b1;
		end else if(axi1_rx_done_pos) begin
			axi1_rx_done_detec_valid <= 1'b0;
		end else if(axi1_rx_done_neg) begin
			axi1_rx_done_detec_valid <= 1'b1;
		end
	end

	always @(posedge clk) begin
		if(!reset) begin
			bias_read_done <= 1'b0;
		end else if(gemm_idle) begin
			bias_read_done <= 1'b0;
		end else if(read_bias & axi0_rx_done & axi0_rx_done_detec_valid) begin
			bias_read_done <= 1'b1;
		end else begin
			bias_read_done <= bias_read_done;
		end
	end

	always @(posedge clk) begin
		if(!reset) begin
			weight_read_done <= 1'b0;
		end else if(gemm_idle) begin
			weight_read_done <= 1'b0;
		end else if(read_weight & axi0_rx_done & axi0_rx_done_detec_valid) begin
			weight_read_done <= 1'b1;
		end else begin
			weight_read_done <= weight_read_done;
		end
	end

	always @(posedge clk) begin
		if(!reset) begin
			attribute_read_done <= 1'b0;
		end else if(gemm_idle) begin
			attribute_read_done <= 1'b0;
		end else if(read_attribute & axi1_rx_done & axi1_rx_done_detec_valid) begin
			attribute_read_done <= 1'b1;
		end else begin
			attribute_read_done <= attribute_read_done;
		end
	end

	always@(posedge clk) begin
		if(!reset) begin
			write_back_done <= 1'b0;
		end else if(gemm_idle)begin
			write_back_done <= 1'b0;
		end else if(write_back_result & axi1_tx_done) begin
			write_back_done <= 1'b1;
		end else begin
			write_back_done <= write_back_done;
		end
	end

	always @(posedge clk) begin
		if(!reset) begin
			start_operation <= 1'b0;
		end else if(gemm_idle) begin
			start_operation <= 1'b0;
		end else if(read_weight & axi0_read_enable) begin
			start_operation <= 1'b1;
		end else begin
			start_operation <= start_operation;
		end
	end

	assign bias_read_valid = (cur_state == READ_BIAS);

	assign axi0_read_burst_length 	= (cur_state == READ_BIAS) ? (SYS_ARRAY_SIZE-1) : ({block_size[BLOCK_SIZE_WIDTH-1:0], {BLOCK_SIZE_CNT_WIDTH{1'b0}}} - 1'b1);
	assign axi0_read_burst_size 	= BURST_SIZE_VALUE;
	assign axi0_read_start_address 	= (cur_state == READ_BIAS) ? bias_read_start_address : ((k_blocks <= MAX_SINGLE_BLOCK_SIZE) ? weight_read_start_address : (weight_read_start_address+w_a_read_address_offset));
	assign axi1_read_burst_length 	= ({block_size[BURST_LENGTH_WIDTH-5:0], {BLOCK_SIZE_CNT_WIDTH{1'b0}}} - 1'b1);
	assign axi1_read_burst_size 	= BURST_SIZE_VALUE;
	assign axi1_read_start_address 	= (k_blocks <= MAX_SINGLE_BLOCK_SIZE) ? attribute_read_start_address : (attribute_read_start_address+w_a_read_address_offset);
	assign axi1_write_burst_length 	= SYS_ARRAY_SIZE-1;
	assign axi1_write_burst_size 	= BURST_SIZE_VALUE;
	assign axi1_write_start_address = acc_write_start_address;

	assign write_back = write_back_en && (block_size_split_cnt == 0);

	reg read_bias_pos, read_bias_ff;
	reg read_weight_pos, read_weight_ff;
	reg read_attribute_pos, read_attribute_ff;
	reg start_op_ff;
	`POS_CHECK(read_bias_pos, read_bias, read_bias_ff, reset, clk)
	`POS_CHECK(read_weight_pos, read_weight, read_weight_ff, reset, clk)
	`POS_CHECK(read_attribute_pos, read_attribute, read_attribute_ff, reset, clk)
	`POS_CHECK(start_op, start_operation, start_op_ff, reset, clk)
	
	assign axi0_init_read = read_bias_pos | read_weight_pos;
	assign axi1_init_read = read_attribute_pos;
	assign axi1_init_write = write_back_result;
	
	assign axi0_read_enable = ((read_weight & ~wait_attribute_valid) | read_bias) & axi0_rvalid; //load weight when data ready
	assign axi1_read_enable = read_attribute && axi1_rvalid && (cycle_cnt >= (SYS_ARRAY_SIZE)); //load activation after one block delay of weight
	assign axi1_write_enable = write_back_result & axi1_wready & axi1_wvalid;

	assign wait_attribute_valid = ((cur_state == READ_W_A) && (cycle_cnt == (SYS_ARRAY_SIZE)) && ~axi1_rvalid && read_attribute);
	assign clk_gate_en = (wait_attribute_valid_ff) || ((cur_state == WRITE_BACK) & ~axi1_write_enable & write_back_en) ;
	
endmodule
