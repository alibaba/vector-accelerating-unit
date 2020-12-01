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

`include "shared_library.sv"
module mac_fp(clk, rst, a, b, c, z);
  parameter integer sig_width = 23;      // RANGE 2 TO 253
  parameter integer exp_width = 8;       // RANGE 3 TO 31
  parameter integer ieee_compliance = 0; // RANGE 0 TO 1
  parameter MULT_LATENCY = 1;

  input clk, rst;
  input  [exp_width + sig_width:0] a;
  input  [exp_width + sig_width:0] b;
  input  [exp_width + sig_width:0] c;
  output [exp_width + sig_width:0] z;
	
  wire   [exp_width + sig_width:0] mult_out;
  reg    [exp_width + sig_width:0] mult_reg;
  wire   [exp_width + sig_width:0] c_reg;

  fp32_mult_xilinx u_fp32_mult (
    .aclk(clk),
    .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
    .s_axis_a_tdata(a),              // input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid(1'b1),            // input wire s_axis_b_tvalid
    .s_axis_b_tdata(b),              // input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
    .m_axis_result_tdata(mult_out)    // output wire [31 : 0] m_axis_result_tdata
  );

  `DFF_RST(mult_reg, mult_out, rst, clk)
  data_shift_reg # (
    .ARRAY_DEPTH (MULT_LATENCY+1),  
    .ARRAY_WIDTH (exp_width + sig_width+1)
  ) u_c_staging_reg (
    .clk (clk),
    .reset (rst),
    .en (1'b1),
    .data_i (c),
    .data_o (c_reg)
  );

  fp32_adder_xilinx u_fp32_add (
    .aclk(clk),
    .s_axis_a_tvalid(1'b1),            // input wire s_axis_a_tvalid
    .s_axis_a_tdata(mult_reg),              // input wire [31 : 0] s_axis_a_tdata
    .s_axis_b_tvalid(1'b1),            // input wire s_axis_b_tvalid
    .s_axis_b_tdata(c_reg),              // input wire [31 : 0] s_axis_b_tdata
    .m_axis_result_tvalid(),  // output wire m_axis_result_tvalid
    .m_axis_result_tdata(z)    // output wire [31 : 0] m_axis_result_tdata
  );

endmodule
