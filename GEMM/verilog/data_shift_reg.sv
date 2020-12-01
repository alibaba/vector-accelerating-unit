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

/*
Module: data_shift_reg 
functionality: parameterized shift registers 
*/

module data_shift_reg # (
	parameter ARRAY_DEPTH = 32,
	parameter ARRAY_WIDTH = 8
) (
	input  logic clk, 
	input  logic reset, 
	input  logic en,
	input  logic [ARRAY_WIDTH-1:0] data_i,
	output logic [ARRAY_WIDTH-1:0] data_o
);
   
	logic [ARRAY_WIDTH*ARRAY_DEPTH-1:0] shift_reg;

	generate 
		if (ARRAY_DEPTH==1) begin
			always_ff @(posedge clk) begin
				if (!reset)
					shift_reg <= 'b0;
				else if (en)
					shift_reg <= data_i;
			end		
			assign data_o = shift_reg;
		end
		else begin
			always_ff @(posedge clk) begin
				if (!reset)
					shift_reg <= 'b0;
				else if(en)
					shift_reg <= {shift_reg[0+:ARRAY_WIDTH*(ARRAY_DEPTH-1)], data_i};
			end
			assign data_o = shift_reg[ARRAY_WIDTH*ARRAY_DEPTH-1-:ARRAY_WIDTH];
		end
	endgenerate

endmodule
