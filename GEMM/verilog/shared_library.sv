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
// Shared Library 
// ----------------------------------------------------------------------

//D-Flipflop
`define DFF(Q, D, CLK)  \
always @(posedge CLK) begin \
  Q <= (D); \
end

//D-Flipflop with Enable
`define DFF_EN(Q, D, EN, CLK) \
always @(posedge CLK) begin \
  Q <= (EN ? D : Q) ; \
end

//D-Fliflop with Enable and Reset
`define DFF_RST(Q, D, RST, CLK) \
always @(posedge CLK) begin \
  Q <= (!RST ? 'b0 : D);  \
end

//D-Fliflop with Enable and Reset
`define DFF_EN_RST(Q, D, EN, RST, CLK)  \
always @(posedge CLK) begin \
//always @(posedge CLK) begin \
  Q <= (!RST ? 'b0 : (EN ? D : Q)); \
end

//D-Flipflop with Enable, Reset and Reset Value
`define DFF_EN_RST_VAL(Q, D, RST_VAL, EN, RST, CLK) \
always @(posedge CLK) begin \
  Q <= (!RST ? RST_VAL : (EN ? D : Q)); \
end

//MUX 2-1
`define MUX21(Dout, Din, Sel) \
   assign Dout = Sel ? Din[1] : Din[0]; 

//D-Fliflop with Enable and Reset_n
`define DFF_RSTn(Q, D, RSTn, CLK) \
always @(posedge CLK) begin \
  Q <= (RSTn ? D : 'b0);  \
end

//D-Fliflop with Enable and Reset_n
`define DFF_EN_RSTn(Q, D, EN, RSTn, CLK)  \
always @(posedge CLK) begin \
  Q <= (RSTn ? (EN ? D : Q): 'b0);  \
end

//D-Flipflop with Enable, Reset and Reset Value
`define DFF_EN_RST_VALn(Q, D, RST_VAL, EN, RST, CLK)  \
always @(posedge CLK) begin \
  Q <= (RST ? (EN ? D : Q) : RST_VAL);  \
end

//D-Flipflop with Enable, Reset, select, pre-load and Done
`define DFF_EN_RST_DONE_LOAD_SEL(Q0, Q1, D, P0, P1, SEL, EN, RST, LOAD, DONE, CLK)  \
always @(posedge CLK) begin \
  Q1 <= (!RST ? 'b0 : (DONE & SEL ? 'b0 : (LOAD ? P1 : (EN & SEL ? D : Q1))));  \
  Q0 <= (!RST ? 'b0 : (DONE & ~SEL ? 'b0 : (LOAD ? P0 : (EN & ~SEL ? D : Q0))));  \
end
		
//D-Flipflop with Enable, Reset, pre-load and Done
`define DFF_EN_RST_DONE_LOAD(Q, D, P, EN, RST, DONE, LOAD, CLK) \
always @(posedge CLK) begin \
  Q <= (!RST ? 'b0 : (DONE ? 'b0 : (LOAD ? P : (EN ? D : Q)))); \
end
		
//D-Flipflop with Enable, Reset and Done
`define DFF_EN_RST_DONE(Q, D, EN, RST, DONE, CLK) \
always @(posedge CLK) begin \
  Q <= (!RST ? 'b0 : (DONE ? 'b0 : (EN ? D : Q)));  \
end
		
//posedge detect
`define POS_CHECK(EG, D, FF, RST, CLK)  \
always@(posedge CLK) begin  \
	if(!RST)  \
		FF <= 1'b0;	\
	else	\
		FF <= D;	\
end	\
assign EG = D & ~FF;

//posedge detect
`define NEG_CHECK(EG, D, FF, RST, CLK)	\
always@(posedge CLK) begin \
	if(!RST)	\
		FF <= 1'b0;	\
	else	\
		FF <= D;	\
end	\
assign EG = ~D & FF;
