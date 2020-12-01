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

module wl_clkgate (
  clk_i,
  dft_se,
  en,
  clk_o      
);
//---------------------------------------------------------------------------------------
//defines / params
//---------------------------------------------------------------------------------------
parameter CLK_NUM = 1;

//---------------------------------------------------------------------------------------
//port list
//---------------------------------------------------------------------------------------
input [CLK_NUM-1:0] clk_i;  //clk in
input dft_se; //dft enable
input [CLK_NUM-1:0] en; //enable high active
output [CLK_NUM-1:0] clk_o; //clk out

//---------------------------------------------------------------------------------------
//process signal
//---------------------------------------------------------------------------------------
reg [CLK_NUM-1:0] en_latch;
genvar i;

//---------------------------------------------------------------------------------------
//code start
//---------------------------------------------------------------------------------------
//`ifdef FPGA

//generate
//    for(i = 0; i < CLK_NUM; i = i + 1)
//        begin:ICG_RTL
//            always @ (*)
//                if(~clk_i[i])
//                    en_latch[i] = en[i] | dft_se;
//            
//            assign  clk_o[i] = en_latch[i] && clk_i[i];//latch output and clock input
//        end
//endgenerate
generate
  for(i = 0; i < CLK_NUM; i = i + 1)
  begin: ICG_CELL
    BUFGCE # (
      .CE_TYPE("SYNC"),       // ASYNC, HARDSYNC, SYNC   
      .IS_CE_INVERTED(1'b0),  // Programmable inversion on CE   
      .IS_I_INVERTED(1'b0)    // Programmable inversion on I
    ) BUFGCE_inst (
      .O(clk_o[i]),           // 1-bit output: Buffer   
      .CE(en[i]),             // 1-bit input: Buffer enable   
      .I(clk_i[i]));          // 1-bit input: Buffer);// End of BUFGCE_inst instantiat
  end
endgenerate

//---------------------------------------------------------------------------------------
//code end
//---------------------------------------------------------------------------------------
endmodule
