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


// ----------------------------------------------------------------------
//  Top Moudle of DPE (DRAM Process Engine)
// ----------------------------------------------------------------------

`include "shared_library.sv"

module DPE # (
  parameter MAC_PRECISION     = 4,  // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter SYS_ARRAY_HEIGHT  = 16, // Systolic Array Height = 32            
  parameter SYS_ARRAY_WIDTH   = 16, // Systolic Array Width  = 32    
  parameter SYS_ARRAY_NUM     = 1,  // Number of Systolic Array    
  parameter BLOCK_SIZE_WIDTH  = 6,
  parameter ADDER_LATENCY     = 2,
  parameter MULT_LATENCY      = 1,
  parameter ACC_LATENCY       = 2,
  parameter MAC_LATENCY       = ADDER_LATENCY+MULT_LATENCY+1,
  parameter ACT_WIDTH         = 32, // Activation Data Width
  parameter WT_WIDTH          = 32, // Weight     Data Width        
  parameter WMEM_DWIDTH       = SYS_ARRAY_NUM*SYS_ARRAY_HEIGHT*WT_WIDTH,  // Weight Memory Data Bus Width
  parameter WMEM_AWIDTH       = 28, // Weight Memory Addr Bus Width
  parameter AMEM_DWIDTH       = SYS_ARRAY_NUM*SYS_ARRAY_HEIGHT*ACT_WIDTH, // Activation Memory Data Bus Width
  parameter AMEM_AWIDTH       = 28, // Activation Memory Addr Bus Width
  parameter ACC_WIDTH         = 32, // Accumulation Data Width
  parameter OMEM_DWIDTH       = SYS_ARRAY_HEIGHT*ACC_WIDTH
) (

  input clk,
  input reset,
  input start_op,
  input bias_load_en,
  input relu_en,
  input acc_buffer_sel,	//for 16x32
  input write_back,
  input logic signed [WMEM_DWIDTH-1:0] bias_wt_mem_rdata, //Weight data from Main Weight Memory
  input logic signed [AMEM_DWIDTH-1:0] act_mem_rdata, //Activation Data from Main Activation Memory
  output logic signed [OMEM_DWIDTH-1:0] acc_mem_wrdata, //Accumulation Data to Main Activation Memory
  input wire [BLOCK_SIZE_WIDTH-1:0] block_size,
  input wire clear_buffer,
  output wire r_depend,
  output wire w_depend,
  output wire output_valid,
  output wire done
);

  wire [WMEM_DWIDTH-1:0] wt_mem_rdata, bias_mem_rdata;
  assign wt_mem_rdata = !bias_load_en ? bias_wt_mem_rdata : 'b0;
  assign bias_mem_rdata = bias_load_en ? bias_wt_mem_rdata : 'b0;

  genvar gi;
  logic [SYS_ARRAY_HEIGHT-1:0] act_data_sel;
  logic signed [SYS_ARRAY_HEIGHT*SYS_ARRAY_NUM-1:0][ACT_WIDTH-1:0] act_data_in;
  logic signed [SYS_ARRAY_WIDTH*SYS_ARRAY_NUM-1:0] [WT_WIDTH-1:0] wt_data_in;
  logic signed [SYS_ARRAY_WIDTH*SYS_ARRAY_NUM-1:0] [ACC_WIDTH-1:0] bias_data_in;
  logic signed [SYS_ARRAY_WIDTH*SYS_ARRAY_NUM-1:0] [ACC_WIDTH-1:0] pacc_data_out;
  logic [SYS_ARRAY_WIDTH-1:0] wt_load_en; 
  logic wt_sel_bit; 
  logic signed [SYS_ARRAY_WIDTH-1:0] [ACC_WIDTH-1:0] acc_data_out;
  logic signed [SYS_ARRAY_WIDTH-1:0] [ACC_WIDTH-1:0] fact_data_out;
  logic sys2d_en;
  assign sys2d_en = 1'b1;

  wire load_act, load_wt;

  generate for (gi=0; gi<SYS_ARRAY_NUM*SYS_ARRAY_WIDTH; gi++) begin: decompose_wt_bias
    assign wt_data_in[gi] = load_wt ? wt_mem_rdata[(gi+1)*WT_WIDTH-1:gi*WT_WIDTH] : 'b0;
    assign bias_data_in[gi] = bias_mem_rdata[(gi+1)*WT_WIDTH-1:gi*WT_WIDTH];
  end endgenerate

  generate for (gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: compose_acc
    assign acc_mem_wrdata[(gi+1)*ACC_WIDTH-1:gi*ACC_WIDTH] = fact_data_out[gi]; 
  end endgenerate

  generate for (gi=0; gi<SYS_ARRAY_NUM*SYS_ARRAY_HEIGHT; gi++) begin: decompose_act
    assign act_data_in[gi]  = load_act ? act_mem_rdata[(gi+1)*ACT_WIDTH-1:gi*ACT_WIDTH] : 'b0;
    //assign act_data_in[gi]  = act_mem_rdata[(gi+1)*ACT_WIDTH-1:gi*ACT_WIDTH];
  end endgenerate

  assign wt_load_en = {SYS_ARRAY_WIDTH{1'b1}};
  assign act_data_sel = {SYS_ARRAY_HEIGHT{1'b1}};

  systolic_array #(
    .MAC_PRECISION    (MAC_PRECISION),   
    .SYS_ARRAY_HEIGHT (SYS_ARRAY_HEIGHT),
    .SYS_ARRAY_WIDTH  (SYS_ARRAY_WIDTH),
    .ADDER_LATENCY    (ADDER_LATENCY),
    .MULT_LATENCY     (MULT_LATENCY),
    .ACT_WIDTH        (ACT_WIDTH),
    .WT_WIDTH         (WT_WIDTH),
    .ACC_WIDTH        (ACC_WIDTH)
  ) u0_systolic_array(
    .clk(clk),
    .reset(reset),
    .sys2d_en(sys2d_en),
    .wt_sel_bit(wt_sel_bit),
    .act_data_sel(act_data_sel),
    .wt_load_en(wt_load_en),
    .wt_data_in(wt_data_in[SYS_ARRAY_WIDTH-1:0]),
    .act_data_in(act_data_in[SYS_ARRAY_HEIGHT-1:0]),
    .acc_data_out(pacc_data_out[SYS_ARRAY_WIDTH-1:0])
  );

`ifdef SYS_ARRAY_NUM_2
  systolic_array #(
    .MAC_PRECISION    (MAC_PRECISION),   
    .SYS_ARRAY_HEIGHT (SYS_ARRAY_HEIGHT),
    .SYS_ARRAY_WIDTH  (SYS_ARRAY_WIDTH),
    .ADDER_LATENCY    (ADDER_LATENCY),
    .MULT_LATENCY     (MULT_LATENCY),
    .ACT_WIDTH        (ACT_WIDTH),
    .WT_WIDTH         (WT_WIDTH),
    .ACC_WIDTH        (ACC_WIDTH)
  ) u1_systolic_array (
    .clk(clk),
    .reset(reset),
    .sys2d_en(sys2d_en),
    .wt_sel_bit(wt_sel_bit),
    .act_data_sel(act_data_sel),
    .wt_load_en(wt_load_en),
    .wt_data_in(wt_data_in[2*SYS_ARRAY_WIDTH-1:SYS_ARRAY_WIDTH]),
    .act_data_in(act_data_in[2*SYS_ARRAY_HEIGHT-1:SYS_ARRAY_HEIGHT]),
    .acc_data_out(pacc_data_out[2*SYS_ARRAY_WIDTH-1:SYS_ARRAY_WIDTH])
  );
`endif

  accumulator #(
    .MAC_PRECISION    (MAC_PRECISION),   
    .SYS_ARRAY_HEIGHT (SYS_ARRAY_HEIGHT),
    .SYS_ARRAY_WIDTH  (SYS_ARRAY_WIDTH),
    .SYS_ARRAY_NUM    (SYS_ARRAY_NUM),
    .ACC_LATENCY      (ACC_LATENCY),
    .ACC_WIDTH        (ACC_WIDTH)
  ) u_accumulator (
    .clk(clk),
    .reset(reset),
    .sys2d_en(sys2d_en),
    .acc_en(acc_en),
    .acc_clear_en(acc_clear_en),
    .acc_data_oen(acc_data_oen),
    .bias_load_en(bias_load_en),
    .relu_en(relu_en),
    .acc_buffer_sel(acc_buffer_sel),
    .write_back(write_back),
    .clear_buffer(clear_buffer),
    .done(done),
    .acc_data_in(pacc_data_out),
    .bias_data_in(bias_data_in),
    .fact_data_out(fact_data_out)
  );

  gemm_ctrl #(
    .BLOCK_SIZE_WIDTH	(BLOCK_SIZE_WIDTH),
    .SYS_ARRAY_SIZE		(SYS_ARRAY_HEIGHT),
    .SYS_ARRAY_NUM		(SYS_ARRAY_NUM),
    .MAC_LATENCY		  (ADDER_LATENCY+MULT_LATENCY+1),
    .ACC_LATENCY		  (ACC_LATENCY)
  ) u_gemm_ctrl(
    .clk(clk),
    .reset(reset),
    .block_size(block_size),
    .start_op(start_op),
    .wt_sel(wt_sel_bit),
    .acc_en(acc_en),
    .acc_oen(acc_data_oen),
    .done(done),
    .r_depend(r_depend),
    .w_depend(w_depend),
    .output_valid(output_valid),
    .load_wt(load_wt),
    .load_act(load_act),
    .acc_clear_en(acc_clear_en)
  );

endmodule //endmodule DPE
