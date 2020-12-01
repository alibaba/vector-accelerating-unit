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

module accumulator # (
	parameter MAC_PRECISION    	= 4,       // 1: INT8; 2: FP16; 3: BF16; 4: FP32
	parameter SYS_ARRAY_HEIGHT 	= 16,     // Systolic Array Height = 32            
	parameter SYS_ARRAY_WIDTH  	= 16,     // Systolic Array Width  = 32    
	parameter ACC_WIDTH       	= 32,
	parameter ACC_LATENCY 			= 2,
	parameter SYS_ARRAY_NUM 		= 2
) (
	input clk,
	input reset,
	input sys2d_en,
	input acc_en,
	input acc_data_oen,
	input acc_clear_en,
	input bias_load_en,
	input relu_en,
	input acc_buffer_sel,	//for 16x32
	input write_back,
	input clear_buffer,
	input done,
	input signed [SYS_ARRAY_NUM*SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]	acc_data_in,
	input signed [SYS_ARRAY_NUM*SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]	bias_data_in,
	output signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]     					fact_data_out
);

	logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]     						fact_data_shift_out;
	logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]     						pacc_data_in;
	logic signed [SYS_ARRAY_NUM*SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]		bias_data_shift_out;
	logic bias_load_valid;
	logic bias_load_en_ff;

`ifdef SYS_ARRAY_NUM_2 
	genvar ai;
	generate for(ai=0;ai<SYS_ARRAY_WIDTH;ai=ai+1) begin: add_multiple_sys2d
		if (MAC_PRECISION == 4) begin 
			fp32_adder_xilinx u_fp32_acc(
				.aclk (clk),
				.s_axis_a_tvalid (1'b1),            
				.s_axis_a_tdata (acc_data_in[ai]), 
				.s_axis_b_tvalid (1'b1),            
				.s_axis_b_tdata (acc_data_in[ai+SYS_ARRAY_WIDTH]),
				.m_axis_result_tvalid (),  
				.m_axis_result_tdata (pacc_data_in[ai])   
			);
		end else if (MAC_PRECISION == 1) begin
			int8_adder_1  u_int8_acc(
				.clk (clk),
				.rst (reset),
				.a (acc_data_in[ai]),  
				.b (acc_data_in[ai+SYS_ARRAY_WIDTH]),             
				.z (pacc_data_in[ai])    
			);
		end
	end endgenerate
`else
	assign pacc_data_in = acc_data_in;
`endif

	ACC # (
		.MAC_PRECISION (MAC_PRECISION),   // 1: INT8; 2: FP16; 3: BF16; 4: FP32
		.SYS_ARRAY_HEIGHT (SYS_ARRAY_HEIGHT),
		.SYS_ARRAY_WIDTH (SYS_ARRAY_WIDTH),
		.SYS_ARRAY_NUM (SYS_ARRAY_NUM),
		.ACC_LATENCY (ACC_LATENCY),
		.ACC_WIDTH (ACC_WIDTH)
	) u_ACC (
		.clk (clk),
		.reset (reset),
		.acc_en (acc_en),
		.acc_data_oen (acc_data_oen),
		.acc_clear_en (acc_clear_en),
		.bias_load_en (bias_load_valid),
		.relu_en (relu_en),
		.acc_buffer_sel (acc_buffer_sel),
		.write_back (write_back),
		.clear_buffer (clear_buffer),
		.done (done),
		.pacc_data_in (pacc_data_in),
		.bias_data_in (bias_data_shift_out),
		.fact_data_out (fact_data_shift_out)
	);

	genvar gv_k;
	generate 
		for (gv_k=0; gv_k < SYS_ARRAY_WIDTH; gv_k=gv_k+1) begin: acc_staging_int
			data_shift_reg # (
				.ARRAY_DEPTH (SYS_ARRAY_WIDTH-1 - gv_k + 1),	//additional one cycle delay for axi write timing  
				.ARRAY_WIDTH (ACC_WIDTH)
			) u_acc_staging_reg (
				.clk (clk),
				.reset (reset),
				.en (sys2d_en),
				.data_i (fact_data_shift_out[gv_k][ACC_WIDTH-1:0]),
				.data_o (fact_data_out[gv_k][ACC_WIDTH-1:0])
			);
		end
	endgenerate
	
	genvar gv_b;
	generate 
		for (gv_b=1; gv_b < SYS_ARRAY_WIDTH; gv_b=gv_b+1) begin: bias_staging_int
			data_shift_reg # (
				.ARRAY_DEPTH (gv_b),  
				.ARRAY_WIDTH (ACC_WIDTH)
			) u_bias_staging_reg (
				.clk (clk),
				.reset (reset),
				.en (sys2d_en),
				.data_i (bias_data_in[gv_b][ACC_WIDTH-1:0]),
				.data_o (bias_data_shift_out[gv_b][ACC_WIDTH-1:0])
			);
		end
	endgenerate

	data_shift_reg # (
		.ARRAY_DEPTH (SYS_ARRAY_WIDTH-1),  
		.ARRAY_WIDTH (1)
	) u_bias_load_enstaging_reg (
		.clk (clk),
		.reset (reset),
		.en (sys2d_en),
		.data_i (bias_load_en),
		.data_o (bias_load_en_ff)
	);

	assign bias_data_shift_out[0] = bias_data_in[0];
	assign bias_load_valid = bias_load_en | bias_load_en_ff;
endmodule
