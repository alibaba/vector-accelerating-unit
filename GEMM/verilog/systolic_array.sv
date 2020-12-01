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

module systolic_array #(
	parameter MAC_PRECISION			=	4,	// 1: INT8; 2: FP16; 3: BF16; 4: FP32
	parameter SYS_ARRAY_HEIGHT 	= 16,	// Systolic Array Height = 32            
	parameter SYS_ARRAY_WIDTH		= 16,	// Systolic Array Width  = 32    
	parameter ACT_WIDTH       	= 32,	// Activation Data Width
	parameter WT_WIDTH        	= 32,	// Weight     Data Width        
	parameter ACC_WIDTH       	= 32,
	parameter ADDER_LATENCY 		= 2,
	parameter MULT_LATENCY 			= 1,
	parameter MAC_LATENCY 			= ADDER_LATENCY+MULT_LATENCY+1
)(
	input	clk,
	input	reset,
	input	sys2d_en,
	input	wt_sel_bit,
	input [SYS_ARRAY_HEIGHT-1:0] act_data_sel,
	input [SYS_ARRAY_WIDTH-1:0] wt_load_en, 
	input logic signed [SYS_ARRAY_WIDTH-1:0][WT_WIDTH-1:0] wt_data_in,   
	input logic signed [SYS_ARRAY_HEIGHT-1:0][ACT_WIDTH-1:0] act_data_in,  
	output logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] acc_data_out
);

	logic [SYS_ARRAY_WIDTH-2:0] wt_sel; 
	logic signed [SYS_ARRAY_WIDTH-1:0][WT_WIDTH-1:0] wt_data_shift_in; 
	logic signed [SYS_ARRAY_HEIGHT-1:0][ACT_WIDTH-1:0] act_data_shift_in;

	always@(posedge clk) begin
		if (!reset)
			wt_sel <= 'b0;
		else    
			wt_sel <= {wt_sel[SYS_ARRAY_WIDTH-3:0], wt_sel_bit};
	end

	genvar gv_i;
	generate 
		for (gv_i=1; gv_i < SYS_ARRAY_WIDTH; gv_i=gv_i+1)
		begin: act_staging_int
			data_shift_reg # (
				.ARRAY_DEPTH ((MAC_LATENCY+1)*gv_i),  
				.ARRAY_WIDTH (ACT_WIDTH)
			) u_act_staging_reg (
				.clk (clk),
				.reset (reset),
				.en (sys2d_en),
				.data_i (act_data_in[gv_i][ACT_WIDTH-1:0]),
				.data_o (act_data_shift_in[gv_i][ACT_WIDTH-1:0])
			);
		end
	endgenerate
	
	assign act_data_shift_in[0] = act_data_in[0];
	
	genvar gv_j;
	generate 
		for (gv_j=1; gv_j < SYS_ARRAY_WIDTH ; gv_j = gv_j + 1)
		begin: weight_staging_int
			data_shift_reg # (
				.ARRAY_DEPTH (gv_j),  
				.ARRAY_WIDTH (WT_WIDTH)
			) u_weight_staging_reg (
				.clk (clk),
				.reset (reset),
				.en (sys2d_en),
				.data_i (wt_data_in[gv_j][WT_WIDTH-1:0]),
				.data_o (wt_data_shift_in[gv_j][WT_WIDTH-1:0])
			);
		end
	endgenerate
	
	assign wt_data_shift_in[0] = wt_data_in[0];

	SYS2D # (
		.MAC_PRECISION		(MAC_PRECISION),	// 1: INT8; 2: FP16; 3: BF16; 4: FP32
		.SYS_ARRAY_HEIGHT (SYS_ARRAY_HEIGHT),
		.SYS_ARRAY_WIDTH  (SYS_ARRAY_WIDTH),
		.NUM_ACT_CH    		(1),
		.ACT_WIDTH     		(ACT_WIDTH),
		.NUM_WT_ENT    		(2),
		.WT_WIDTH      		(WT_WIDTH),
		.ACC_WIDTH     		(ACC_WIDTH),
		.ADDER_LATENCY		(ADDER_LATENCY),
		.MULT_LATENCY			(MULT_LATENCY)
	) u_SYS2D (
		.clk (clk),
		.reset (reset),
		.sys2d_en (sys2d_en),
		.act_data_sel(act_data_sel), 
		.act_data_in (act_data_shift_in), 
		.wt_data_in  (wt_data_shift_in), 
		.wt_load_en  (wt_load_en), 
		.wt_sel      ({wt_sel,wt_sel_bit}), 
		.acc_data_out(acc_data_out)  
	);

endmodule
