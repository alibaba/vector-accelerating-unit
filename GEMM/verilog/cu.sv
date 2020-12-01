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
//  CU: Computation Unit
// ----------------------------------------------------------------------
//
//                    Accumulation 
//                               |
//                    Weight     | 
//                         |     |                 
//                    _____V_____V____
//                   |                |
//                   |                |
//     Activation -->|       CU       |---> Activation to CU (i, j+1)   
//                   |                |
//                   |________________| 
//                         |     |    
//                         |     V
//                         |     Weight to CU (i+1, j)
//                         V
//                         Accumulation to CU (i+1, j)
//
//
//

`include "shared_library.sv"

module CU # (
  parameter MAC_PRECISION =  4,       // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter CU_NUM_CH     =  2,       // Number of Channel
  parameter NUM_ACT_CH    =  1,       // Number of Activation Channel
  parameter ACT_WIDTH     =  8,       // Input Activation Data Width
  parameter NUM_WT_ENT    =  2,       // Number of Weight Entries Stored in CU
  parameter WT_WIDTH      =  8,       // Input Weight Width
  parameter ACC_WIDTH     =  32,      // Accumlation Data Width
  parameter ADDER_LATENCY =  2,
  parameter MULT_LATENCY  =  1
) (

  input clk,
  input reset, 
  input cu_en,

  //input precision_mode,    //INT8 or FP16

  input [CU_NUM_CH-1:0][NUM_ACT_CH-1:0] act_data_sel,               // Activation Data Selection
  input logic signed [CU_NUM_CH-1:0][ACT_WIDTH-1:0] act_data_in,    // Activation Data
  input logic signed [CU_NUM_CH-1:0][WT_WIDTH-1:0] wt_data_in,      // Weight Data
  input [CU_NUM_CH-1:0] wt_load_en,                                 // Weight Loading Enable
  input [CU_NUM_CH-1:0] wt_sel,                                     // Weight Entry Selected for Computing, the other one will be used for loading new weights 
  input logic signed [CU_NUM_CH-1:0][ACC_WIDTH-1:0] acc_data_in,    // Accumulation Data

  output logic signed [CU_NUM_CH-1:0][WT_WIDTH-1:0] wt_data_out,    // Weight Data to next CU Vertically
  output logic [CU_NUM_CH-1:0] wt_sel_out,                          // Weight Entry Selection to next CU Vertically
  output logic signed [CU_NUM_CH-1:0][ACT_WIDTH-1:0] act_data_out,  // Activation Data to next CU horizontally
  output logic signed [CU_NUM_CH-1:0][ACC_WIDTH-1:0] acc_data_out   // Computed Accumulation Data  to next CU Vertically
  );

  genvar gi;
  genvar col_idx, row_idx;

  logic [CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0] pe_act_data_sel;
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0][ACT_WIDTH-1:0] pe_act_data_in; 
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][WT_WIDTH-1:0] pe_wt_data_in;  
  logic [CU_NUM_CH-1:0][CU_NUM_CH-1:0] pe_wt_load_en;  
  logic [CU_NUM_CH-1:0][CU_NUM_CH-1:0] pe_wt_sel;      
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][ACC_WIDTH-1:0] pe_acc_data_in; 
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][WT_WIDTH-1:0] pe_wt_data_out; 
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][WT_WIDTH-1:0] pe_wt_data_comp;
  logic [CU_NUM_CH-1:0][CU_NUM_CH-1:0] pe_wt_sel_out;  
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][NUM_ACT_CH-1:0][ACT_WIDTH-1:0] pe_act_data_out;
  logic signed [CU_NUM_CH-1:0][CU_NUM_CH-1:0][ACC_WIDTH-1:0] pe_acc_data_out;   


  // Generate 2x2 PE Sub Array for each CU
  generate for (col_idx=0; col_idx<CU_NUM_CH; col_idx++) begin: gen_cu_col
    for (row_idx=0; row_idx<CU_NUM_CH; row_idx++) begin: gen_cu_row
      // Globally connected: Weight Load Enable, Activation Data Mux Selection - FIXME
      assign pe_act_data_sel[col_idx][row_idx][NUM_ACT_CH-1:0] = act_data_sel[row_idx][NUM_ACT_CH-1:0];
      assign pe_wt_load_en  [col_idx][row_idx]                 = wt_load_en  [col_idx];

      // Vertically Connection - Activation
      if(col_idx == 0) begin
        assign pe_act_data_in[col_idx][row_idx] = act_data_in[row_idx];
      end else begin
        assign pe_act_data_in[col_idx][row_idx] = pe_act_data_out[col_idx-1][row_idx];
      end 

      //Horizontally Connection - Accumulation, Weight
      if(row_idx == 0) begin
        assign pe_acc_data_in[col_idx][row_idx][ACC_WIDTH-1:0] = acc_data_in[col_idx][ACC_WIDTH-1:0]; 
        assign pe_wt_data_in [col_idx][row_idx][WT_WIDTH-1:0]  = wt_data_in [col_idx][WT_WIDTH-1:0];
        assign pe_wt_sel     [col_idx][row_idx]                = wt_sel     [col_idx];
      end else begin
      // assign pe_acc_data_in[col_idx][row_idx][ACC_WIDTH-1:0] = pe_acc_data_out[col_idx][row_idx-1][ACC_WIDTH-1:0]; 
        `DFF_EN_RST(pe_acc_data_in[col_idx][row_idx][ACC_WIDTH-1:0], pe_acc_data_out[col_idx][row_idx-1][ACC_WIDTH-1:0], cu_en, reset, clk)
        assign pe_wt_data_in [col_idx][row_idx][WT_WIDTH-1:0]  = pe_wt_data_out [col_idx][row_idx-1][WT_WIDTH-1:0];
        assign pe_wt_sel     [col_idx][row_idx]                = pe_wt_sel_out  [col_idx][row_idx-1];
      end

      PE # (
        .MAC_PRECISION (MAC_PRECISION), // 1: INT8; 2: FP16; 3: BF16; 4: FP32
        .NUM_ACT_CH (NUM_ACT_CH),
        .ACT_WIDTH (ACT_WIDTH),
        .NUM_WT_ENT (NUM_WT_ENT),
        .WT_WIDTH (WT_WIDTH),
        .ACC_WIDTH (ACC_WIDTH),
        .ADDER_LATENCY (ADDER_LATENCY),
        .MULT_LATENCY (MULT_LATENCY)
      ) u_PE (
        .clk (clk),
        .reset (reset),
        .pe_en (cu_en),
        .act_data_sel(pe_act_data_sel[col_idx][row_idx]),
        .act_data_in (pe_act_data_in [col_idx][row_idx]),
        .wt_data_in  (pe_wt_data_in  [col_idx][row_idx]),
        .wt_load_en  (pe_wt_load_en  [col_idx][row_idx]),
        .wt_sel      (pe_wt_sel      [col_idx][row_idx]),
        .acc_data_in (pe_acc_data_in [col_idx][row_idx]),
        .wt_data_out (pe_wt_data_out [col_idx][row_idx]),
        .wt_sel_out  (pe_wt_sel_out  [col_idx][row_idx]),
        .wt_data_comp(pe_wt_data_comp[col_idx][row_idx]),
        .act_data_out(pe_act_data_out[col_idx][row_idx]),
        .acc_data_out(pe_acc_data_out[col_idx][row_idx])
      );
    end
  end endgenerate

  //Instantiate FP16 MAC
  //logic signed [(WT_WIDTH *2)-1:0] fp_wt_data;
  //logic signed [(ACT_WIDTH*2)-1:0] fp_act_data;
  //logic signed [(ACC_WIDTH/2)-1:0] fp_acc_data_in;
  //logic signed [(ACC_WIDTH/2)-1:0] fp_acc_data_out;

  //assign fp_wt_data [(WT_WIDTH *2)-1:0]     = {pe_wt_data_comp[0][0][WT_WIDTH-1:0], pe_wt_data_comp[0][1][WT_WIDTH-1:0]};
  //assign fp_act_data[(ACT_WIDTH*2)-1:0]     = {pe_act_data_in[0][0][0], pe_act_data_in[1][0][0]};
  //assign fp_acc_data_in[(ACC_WIDTH/2)-1:0]  = pe_acc_data_in[0][1][(ACC_WIDTH/2)-1:0];

  //MAC # (
  //   .MAC_PRECISION   (3           ),     // 1: INT8; 2: FP16; 3: BF16
  //   .MAC_INPUT_WIDTH (ACT_WIDTH*2),   // MAC Input  Data Width
  //   .MAC_ACC_WIDTH   (ACC_WIDTH/2),   // MAC Accumulation Width
  //   .MAC_OUTPUT_WIDTH(ACC_WIDTH/2)    // MAC Output Data Width   
  //) u_FP16_MAC (
  //   .op_A (fp_wt_data     [(WT_WIDTH *2)-1:0]),
  //   .op_B (fp_act_data    [(ACT_WIDTH*2)-1:0]),
  //   .op_C (fp_acc_data_in [(ACC_WIDTH/2)-1:0]),
  //   .res_Z(fp_acc_data_out[(ACC_WIDTH/2)-1:0])
  //);

  // Output stage
  // logic precision_mode_sel;
  logic signed [CU_NUM_CH-1:0][ACC_WIDTH-1:0] cu_acc_data_out;
  // `DFF(precision_mode_sel, precision_mode, clk)
  // logic [(ACC_WIDTH/2)-1:0] fp_acc_data_out_reg;
  // `DFF_EN(fp_acc_data_out_reg[(ACC_WIDTH/2)-1:0], fp_acc_data_out[(ACC_WIDTH/2)-1:0], precision_mode_sel, clk)
  generate for (col_idx=0; col_idx<CU_NUM_CH; col_idx++) begin: gen_cu_col_data_out
    if (col_idx == CU_NUM_CH-1) begin
      // assign cu_acc_data_out[col_idx][ACC_WIDTH-1:0] = precision_mode_sel ? {16'b0, fp_acc_data_out[(ACC_WIDTH/2)-1:0]} : pe_acc_data_out[col_idx][CU_NUM_CH-1][ACC_WIDTH-1:0];
      assign cu_acc_data_out[col_idx][ACC_WIDTH-1:0] = pe_acc_data_out[col_idx][CU_NUM_CH-1][ACC_WIDTH-1:0];
    end else begin
      assign cu_acc_data_out[col_idx][ACC_WIDTH-1:0] = pe_acc_data_out[col_idx][CU_NUM_CH-1][ACC_WIDTH-1:0];
    end
    `DFF_EN_RST(acc_data_out[col_idx][ACC_WIDTH-1:0], cu_acc_data_out[col_idx][ACC_WIDTH-1:0], cu_en, reset, clk)
    // assign acc_data_out[col_idx][ACC_WIDTH-1:0] = cu_acc_data_out[col_idx][ACC_WIDTH-1:0];
    assign wt_data_out[col_idx] = pe_wt_data_out [col_idx][CU_NUM_CH-1]; 
    assign wt_sel_out[col_idx] = pe_wt_sel_out [col_idx][CU_NUM_CH-1];
  end endgenerate

  generate for (row_idx=0; row_idx<CU_NUM_CH; row_idx++) begin: gen_cu_row_data_out
    assign act_data_out[row_idx] = pe_act_data_out[CU_NUM_CH-1][row_idx];
  end endgenerate

endmodule //endmodule CU
