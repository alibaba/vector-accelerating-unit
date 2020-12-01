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
//  2D Systolic Array
// ----------------------------------------------------------------------
//
//

`include "shared_library.sv"

module SYS2D # (
  parameter MAC_PRECISION    = 4, // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter SYS_ARRAY_HEIGHT = 4, // Systolic Array Height = 32            
  parameter SYS_ARRAY_WIDTH  = 4, // Systolic Array Width  = 32
  parameter CU_NUM_CH        = 2, // NUmber of PE Channel in each CU
  parameter NUM_ACT_CH       = 1, // Number of Input Activation Channel
  parameter ACT_WIDTH        = 8, // Input Activation Data Width
  parameter NUM_WT_ENT       = 2, // Number of Weight Entries Stored in PE
  parameter WT_WIDTH         = 8, // Input Weight Width
  parameter ACC_WIDTH        = 32,  // Accumlation Data Width
  parameter ADDER_LATENCY    = 2,
  parameter MULT_LATENCY     = 1
) (
  input clk,
  input reset,
  input sys2d_en,

  input [SYS_ARRAY_HEIGHT-1:0][NUM_ACT_CH-1:0] act_data_sel,  //Activation Data Selection  //FIXME: this should not be propagated in systolic way
  input signed [SYS_ARRAY_HEIGHT-1:0][NUM_ACT_CH-1:0][ACT_WIDTH-1:0] act_data_in, //Activation Data
  input signed [SYS_ARRAY_WIDTH-1:0] [WT_WIDTH-1:0] wt_data_in, //Weight Data
  input [SYS_ARRAY_WIDTH-1:0] wt_load_en, //Weight Loading Enable
  input [SYS_ARRAY_WIDTH-1:0] wt_sel, //Weight Entry Selected for Computing, the other one will be used for loading new weights 
  output logic signed [SYS_ARRAY_WIDTH-1:0] [ACC_WIDTH-1:0] acc_data_out  //Computed Accumulation Data  to next PE Vertically
);

  genvar col_idx, row_idx, cu_ch_idx;

  logic [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0]                 cu_act_data_sel;
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0][ACT_WIDTH-1:0]  cu_act_data_in; 
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][WT_WIDTH-1:0]                   cu_wt_data_in;  
  logic [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0]                                 cu_wt_load_en;  
  logic [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0]                                 cu_wt_sel;      
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][ACC_WIDTH-1:0]                  cu_acc_data_in; 
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][WT_WIDTH-1:0]                   cu_wt_data_out; 
  logic [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0]                                 cu_wt_sel_out;  
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0][ACT_WIDTH-1:0]  cu_act_data_out;
  logic signed [SYS_ARRAY_HEIGHT/CU_NUM_CH-1:0][SYS_ARRAY_WIDTH/CU_NUM_CH-1:0][CU_NUM_CH-1:0][ACC_WIDTH-1:0]                  cu_acc_data_out;

  generate for (col_idx=0; col_idx<SYS_ARRAY_WIDTH/CU_NUM_CH; col_idx++) begin: gen_sys_col
    for (row_idx=0; row_idx<SYS_ARRAY_HEIGHT/CU_NUM_CH; row_idx++) begin: gen_sys_row
      for (cu_ch_idx=0; cu_ch_idx<CU_NUM_CH; cu_ch_idx++) begin
        // Globally connected: Weight Load Enable, Activation Data Mux Selection - FIXME
        assign cu_act_data_sel[col_idx][row_idx][cu_ch_idx][NUM_ACT_CH-1:0] = act_data_sel[cu_ch_idx+row_idx*CU_NUM_CH][NUM_ACT_CH-1:0];
        assign cu_wt_load_en  [col_idx][row_idx][cu_ch_idx]                 = wt_load_en  [cu_ch_idx+col_idx*CU_NUM_CH];

        // Vertically Connection - Activation
        if(col_idx == 0) begin
          assign cu_act_data_in[col_idx][row_idx][cu_ch_idx] = act_data_in[cu_ch_idx+row_idx*CU_NUM_CH];
        end else begin
          assign cu_act_data_in[col_idx][row_idx][cu_ch_idx] = cu_act_data_out[col_idx-1][row_idx][cu_ch_idx];
        end 

        // Horizontally Connection - Accumulation, Weight
        if(row_idx == 0) begin
          assign cu_acc_data_in[col_idx][row_idx][cu_ch_idx][ACC_WIDTH-1:0] = 'b0; 
          assign cu_wt_data_in [col_idx][row_idx][cu_ch_idx][WT_WIDTH-1:0]  = wt_data_in[cu_ch_idx+col_idx*CU_NUM_CH][WT_WIDTH-1:0];
          assign cu_wt_sel     [col_idx][row_idx][cu_ch_idx]                = wt_sel    [cu_ch_idx+col_idx*CU_NUM_CH];
        end else begin
          assign cu_acc_data_in[col_idx][row_idx][cu_ch_idx][ACC_WIDTH-1:0] = cu_acc_data_out[col_idx][row_idx-1][cu_ch_idx][ACC_WIDTH-1:0]; 
          assign cu_wt_data_in [col_idx][row_idx][cu_ch_idx][WT_WIDTH-1:0]  = cu_wt_data_out [col_idx][row_idx-1][cu_ch_idx][WT_WIDTH-1:0];
          assign cu_wt_sel     [col_idx][row_idx][cu_ch_idx]                = cu_wt_sel_out  [col_idx][row_idx-1][cu_ch_idx];
        end
      end

    CU #(
      .MAC_PRECISION   (MAC_PRECISION),   // 1: INT8; 2: FP16; 3: BF16; 4: FP32
      .CU_NUM_CH  (CU_NUM_CH),
      .NUM_ACT_CH (NUM_ACT_CH),
      .ACT_WIDTH  (ACT_WIDTH),
      .NUM_WT_ENT (NUM_WT_ENT),
      .WT_WIDTH   (WT_WIDTH),
      .ACC_WIDTH  (ACC_WIDTH),
      .ADDER_LATENCY (ADDER_LATENCY),
      .MULT_LATENCY		(MULT_LATENCY)
    ) u_CU (
      .clk(clk),
      .reset(reset),
      .cu_en(sys2d_en),
      .act_data_sel(cu_act_data_sel[col_idx][row_idx]),
      .act_data_in (cu_act_data_in [col_idx][row_idx]),
      .wt_data_in  (cu_wt_data_in  [col_idx][row_idx]),
      .wt_load_en  (cu_wt_load_en  [col_idx][row_idx]),
      .wt_sel      (cu_wt_sel      [col_idx][row_idx]),
      .acc_data_in (cu_acc_data_in [col_idx][row_idx]),
      .wt_data_out (cu_wt_data_out [col_idx][row_idx]),
      .wt_sel_out  (cu_wt_sel_out  [col_idx][row_idx]),
      .act_data_out(cu_act_data_out[col_idx][row_idx]),
      .acc_data_out(cu_acc_data_out[col_idx][row_idx])
    );

    end
  end endgenerate

  //Output stage
  generate for (col_idx=0; col_idx<SYS_ARRAY_WIDTH/CU_NUM_CH; col_idx++) begin: gen_sys_acc_data_out
    for (cu_ch_idx=0; cu_ch_idx<CU_NUM_CH; cu_ch_idx++) begin
      assign acc_data_out[cu_ch_idx + col_idx*CU_NUM_CH][ACC_WIDTH-1:0] = cu_acc_data_out[col_idx][(SYS_ARRAY_HEIGHT/CU_NUM_CH)-1][cu_ch_idx][ACC_WIDTH-1:0];
    end
  end endgenerate

endmodule // endmodule SYS2D
