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
//  MAC: Multiplier and Accumulation
// ----------------------------------------------------------------------

`include "shared_library.sv"

module MAC # (
  parameter MAC_PRECISION    =     4,       // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter MAC_INPUT_WIDTH  =     32,       // MAC Input  Data Width
  parameter MAC_ACC_WIDTH    =     32,      // MAC Accumulation Width
  parameter MAC_OUTPUT_WIDTH =     32,       // MAC Output Data Width
  parameter ADDER_LATENCY    = 1,
  parameter MULT_LATENCY     = 1,
  parameter MAC_LATENCY      = ADDER_LATENCY+MULT_LATENCY+1
) (
  input clk, rst,
  input  signed [MAC_INPUT_WIDTH -1:0]  op_A,
  input  signed [MAC_INPUT_WIDTH -1:0]  op_B,
  input  signed [MAC_ACC_WIDTH   -1:0]  op_C,
  output signed [MAC_OUTPUT_WIDTH-1:0]  res_Z
);


  //Begin Parameter Check
  initial begin : parameter_check
    integer param_err_flg;
    param_err_flg = 0;
    //    if ((MAC_PRECISION == 1) && (MAC_INPUT_WIDTH != 8) && (MAC_ACC_WIDTH <= MAC_OUTPUT_WIDTH) ) begin
    //      param_err_flg = 1;
    //      $display( "ERROR: %m :\n  Invalid configuration for INT8 MAC (MAC_INPUT_WIDTH=8, MAC_ACC_WIDTH <= MAC_OUTPUT_WIDTH)");
    //    end
    //
    //    if ( ( (MAC_PRECISION == 2) || (MAC_PRECISION == 3) ) && ~( (MAC_INPUT_WIDTH == 16) && (MAC_ACC_WIDTH == 16) && (MAC_OUTPUT_WIDTH == 16) ) ) begin
    //      param_err_flg = 1;
    //      $display( "ERROR: %m :\n  Invalid configuration for FP16/BP16 MAC (MAC_INPUT_WIDTH=16 = MAC_ACC_WIDTH = MAC_OUTPUT_WIDTH)");
    //    end

    if ((MAC_PRECISION == 4) && (MAC_INPUT_WIDTH != 32) && (MAC_ACC_WIDTH <= MAC_OUTPUT_WIDTH) ) begin
      param_err_flg = 1;
      $display( "ERROR: %m :\n  Invalid configuration for FP32 MAC (MAC_INPUT_WIDTH=32, MAC_ACC_WIDTH <= MAC_OUTPUT_WIDTH)");
    end

    if ( (MAC_PRECISION < 1) || (MAC_PRECISION > 4) ) begin
      param_err_flg = 1;
      $display( "ERROR: %m :\n  Invalid Precision: MAC_PRECISION = (1: INT8; 2: FP16; 3: BF16; 4: FP32)");
    end

    if ( param_err_flg == 1) begin
      $display(
      "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end
  end // parameter_check

  if (MAC_PRECISION == 1) begin 
    mac_int #(
      .A_width(MAC_INPUT_WIDTH),
      .B_width(MAC_INPUT_WIDTH),
      .SUM_width(MAC_OUTPUT_WIDTH),
      .ADDER_LATENCY(ADDER_LATENCY),
      .MULT_LATENCY(MULT_LATENCY)
    ) u_INT8_MAC (
      .clk(clk),
      .rst(rst),
      .a(op_A[MAC_INPUT_WIDTH-1:0]), 
      .b(op_B[MAC_INPUT_WIDTH-1:0]), 
      .c(op_C[MAC_ACC_WIDTH-1:0]), 
      .z(res_Z[MAC_OUTPUT_WIDTH-1:0]) 
    );
  end else if (MAC_PRECISION == 4) begin
    (*use_dsp="yes"*) mac_fp # (
      .sig_width(23),
      .exp_width(8),
      .ieee_compliance(0),	
      .MULT_LATENCY(MULT_LATENCY)
    ) u_FP32_MAC (
      .clk(clk),
      .rst(rst),
      .a(op_A[MAC_INPUT_WIDTH-1:0]),
      .b(op_B[MAC_INPUT_WIDTH-1:0]),
      .c(op_C[MAC_ACC_WIDTH-1:0]),
      .z(res_Z[MAC_OUTPUT_WIDTH-1:0])
    );
  end

endmodule //endmoudle MAC
