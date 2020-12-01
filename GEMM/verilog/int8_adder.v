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

module int8_adder # (
  parameter ACC_WIDTH = 32,       // Accumlation Data Width
  parameter LATENCY = 0
) (
  input clk, rst,
  input [ACC_WIDTH-1:0] a,
  input [ACC_WIDTH-1:0] b,
  output [ACC_WIDTH-1:0] z
);

  wire [ACC_WIDTH-1:0] sum = a + b;

	data_shift_reg # (
		.ARRAY_DEPTH (LATENCY),  
		.ARRAY_WIDTH (ACC_WIDTH)
	) u_int8_adder_staging_reg (
		.clk (clk),
		.reset (rst),
		.en (1'b1),
		.data_i (sum),
		.data_o (z)
	);

endmodule

