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
//  PE: Processor Element
// ----------------------------------------------------------------------
//
//                    Accumulation 
//                               |
//                    Weight     | 
//                         |     |                 
//                    _____V_____V____
//                   |                |
//                   |                |
//     Activation -->|       PE       |---> Activation to PE (i, j+1)   
//                   |                |
//                   |________________| 
//                         |     |    
//                         |     V
//                         |     Weight to PE (i+1, j)
//                         V
//                         Accumulation to PE (i+1, j)
//
//
//

`include "shared_library.sv"

module PE # (
  parameter MAC_PRECISION = 4, // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter NUM_ACT_CH =  1, // Number of Input Activation Channel
  parameter ACT_WIDTH  =  8, // Input Activation Data Width
  parameter NUM_WT_ENT =  2, // Number of Weight Entries Stored in PE
  parameter WT_WIDTH   =  8, // Input Weight Width
  parameter ACC_WIDTH  =  32, // Accumlation Data Width
  parameter ADDER_LATENCY = 2,
  parameter MULT_LATENCY = 1,
  parameter MAC_LATENCY = ADDER_LATENCY+MULT_LATENCY+1
) (

  input clk,
  input reset, 
  input pe_en,

  input [NUM_ACT_CH-1:0] act_data_sel,  //Activation Data Selection
  input signed [NUM_ACT_CH-1:0][ACT_WIDTH-1:0] act_data_in, //Activation Data
  input signed [WT_WIDTH-1:0] wt_data_in, //Weight Data
  input wt_load_en, //Weight Loading Enable
  input wt_sel, //Weight Entry Selected for Computing, the other one will be used for loading new weights 
  input signed [ACC_WIDTH-1:0] acc_data_in, //Accumulation Data

  output logic signed [WT_WIDTH-1:0] wt_data_out, //Weight Data to next PE Vertically
  output logic wt_sel_out,  //Weight Entry Selection to next PE Vertically
  output logic [WT_WIDTH-1:0] wt_data_comp, //Weight Used for Current computation
  output logic signed [NUM_ACT_CH-1:0][ACT_WIDTH-1:0] act_data_out, //Activation Data to next PE horizontally
  output logic signed [ACC_WIDTH-1:0] acc_data_out  //Computed Accumulation Data  to next PE Vertically
);

  genvar gi;
  logic signed [NUM_WT_ENT-1:0] [WT_WIDTH-1:0]     weight_ent;
  logic signed [ACC_WIDTH-1:0]                     acc_data, acc_data_reg;
  logic signed [WT_WIDTH-1:0]                      weight_data_prop;
  logic signed [ACT_WIDTH-1:0]                     act_data;
  logic signed [NUM_ACT_CH-1:0][ACT_WIDTH-1:0]     act_data_reg; 
  logic signed [ACC_WIDTH-1:0]                     mul_data;

  //Prepare the weight data for MAC operation
  logic wt_sel_dff, wt_sel_ff;
  `DFF_RST(wt_sel_ff, wt_sel, reset, clk)
  data_shift_reg # (
    .ARRAY_DEPTH (MAC_LATENCY),  
    .ARRAY_WIDTH (1)
  ) u_wt_sel_staging_reg (
    .clk (clk),
    .reset (reset),
    .en (1'b1),
    .data_i (wt_sel),
    .data_o (wt_sel_dff)
  );

  assign wt_data_comp[WT_WIDTH-1:0] = wt_sel_ff ? weight_ent[1][WT_WIDTH-1:0] : weight_ent[0][WT_WIDTH-1:0];

  //Prepare the activation data for MAC operation - Muxing the Activation Data 
  always_comb begin
    act_data[ACT_WIDTH-1:0] = 'b0;
    for (int i=0; i<NUM_ACT_CH; i++) begin
      act_data[ACT_WIDTH-1:0] |= act_data_reg[i][ACT_WIDTH-1:0] & {(ACT_WIDTH){act_data_sel[i]}};  //FIXME: act_data_sel needs to be flopped
    end  //for
  end  //always_comb   

  //MAC

`ifdef USE_DW
  logic signed [(ACC_WIDTH/2)-1:0] A_weight, B_act;
  assign A_weight[(ACC_WIDTH/2)-1:0] = { {((ACC_WIDTH/2)-WT_WIDTH ){1'b0}}, wt_data_comp[WT_WIDTH-1:0] };
  assign B_act   [(ACC_WIDTH/2)-1:0] = { {((ACC_WIDTH/2)-ACT_WIDTH){1'b0}}, act_data        [ACT_WIDTH-1:0]};

  DW02_prod_sum1 # (
    .A_width(WT_WIDTH), 
    .B_width(ACT_WIDTH),
    .SUM_width(ACC_WIDTH)
  ) u_MAC ( 
    .A(wt_data_comp    [WT_WIDTH -1:0]), 
    .B(act_data        [ACT_WIDTH-1:0]), 
    .C(acc_data_in     [ACC_WIDTH-1:0]), 
    .TC(1'b0), 
    .SUM(acc_data      [ACC_WIDTH-1:0]) 
  );
`else   
  MAC # (
    .MAC_PRECISION   (MAC_PRECISION),   // 1: INT8; 2: FP16; 3: BF16; 4: FP32
    .MAC_INPUT_WIDTH (ACT_WIDTH),   // MAC Input  Data Width
    .MAC_ACC_WIDTH   (ACC_WIDTH),   // MAC Accumulation Width
    .MAC_OUTPUT_WIDTH(ACC_WIDTH),    // MAC Output Data Width   
    .ADDER_LATENCY	(ADDER_LATENCY),
    .MULT_LATENCY		(MULT_LATENCY)
  ) u_MAC (
    .clk(clk),
    .rst(reset),
    .op_A (wt_data_comp    [WT_WIDTH -1:0]),
    .op_B (act_data        [ACT_WIDTH-1:0]),
    .op_C (acc_data_in     [ACC_WIDTH-1:0]),
    .res_Z(acc_data        [ACC_WIDTH-1:0])
  );
`endif

  //Flop the accumulation data
  //`DFF_EN_RST(acc_data_reg[ACC_WIDTH-1:0], acc_data[ACC_WIDTH-1:0], pe_en, reset, clk)

  //Store Weight data
  //PING - PING entry is written when PONG entry is selected for Read (wt_sel == 1'b1)
  `DFF_EN_RST(weight_ent[0][WT_WIDTH-1:0], wt_data_in[WT_WIDTH-1:0], (wt_load_en &  wt_sel & pe_en), reset, clk)
  //PONG - PONG entry is written when PING entry is selected for Read (wt_sel == 1'b0)
  `DFF_EN_RST(weight_ent[1][WT_WIDTH-1:0], wt_data_in[WT_WIDTH-1:0], (wt_load_en & ~wt_sel & pe_en), reset, clk)


  //Propogation to Next PE
  //Accumulation data
  //assign acc_data_out[ACC_WIDTH-1:0] = acc_data_reg[ACC_WIDTH-1:0];
  assign acc_data_out[ACC_WIDTH-1:0] = acc_data[ACC_WIDTH-1:0];

  //Activation data
  generate for (gi=0; gi<NUM_ACT_CH; gi++) begin: gen_act_data_out
    `DFF_EN_RST(act_data_reg[gi][ACT_WIDTH-1:0], act_data_in[gi][ACT_WIDTH-1:0], pe_en, reset, clk)
    assign act_data_out[gi][ACT_WIDTH-1:0] = act_data_reg[gi][ACT_WIDTH-1:0];
  end endgenerate

  //Weight data
  logic signed [WT_WIDTH-1:0] wt_data_out_dff;
  assign weight_data_prop[WT_WIDTH-1:0] = wt_sel ? weight_ent[0][WT_WIDTH-1:0] : weight_ent[1][WT_WIDTH-1:0];
  `DFF_EN_RST(wt_data_out[WT_WIDTH-1:0], wt_data_out_dff[WT_WIDTH-1:0], pe_en, reset, clk)
  data_shift_reg # (
    .ARRAY_DEPTH (MAC_LATENCY),  
    .ARRAY_WIDTH (WT_WIDTH)
  ) u_wt_out_staging_reg (
    .clk (clk),
    .reset (reset),
    .en (pe_en),
    .data_i (weight_data_prop),
    .data_o (wt_data_out_dff)
  );

  //wieght select 
  `DFF_RST(wt_sel_out, wt_sel_dff, reset, clk)

endmodule //endmodule PE
