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

module mac_int  # (
  parameter integer A_width = 8,
  parameter integer B_width = 8,
  parameter integer SUM_width = 16,
  parameter ADDER_LATENCY = 1,
  parameter MULT_LATENCY = 1
) (
  input clk, rst,
  input signed  [A_width-1:0]  a,
  input signed  [B_width-1:0]  b,
  input signed  [SUM_width-1:0]  c,
  output signed [SUM_width-1:0] z
);

  // Declare registers for intermediate values
  wire signed [SUM_width-1:0] mult_out = a*b;
  wire signed [SUM_width-1:0] mult_reg;
  wire signed [SUM_width-1:0] c_reg;
  wire signed [SUM_width-1:0] sum = mult_reg+c_reg;

  data_shift_reg # (
    .ARRAY_DEPTH (MULT_LATENCY+1),  
    .ARRAY_WIDTH (SUM_width)
  ) u_c_staging_reg (
    .clk (clk),
    .reset (rst),
    .en (1'b1),
    .data_i (c),
    .data_o (c_reg)
  );

  data_shift_reg # (
    .ARRAY_DEPTH (MULT_LATENCY+1),  
    .ARRAY_WIDTH (SUM_width)
  ) u_mult_staging_reg (
    .clk (clk),
    .reset (rst),
    .en (1'b1),
    .data_i (mult_out),
    .data_o (mult_reg)
  );

  data_shift_reg # (
    .ARRAY_DEPTH (ADDER_LATENCY),  
    .ARRAY_WIDTH (SUM_width)
  ) u_adder_staging_reg (
    .clk (clk),
    .reset (rst),
    .en (1'b1),
    .data_i (sum),
    .data_o (z)
  );

endmodule // macc
