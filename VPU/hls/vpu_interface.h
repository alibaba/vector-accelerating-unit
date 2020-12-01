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

#ifndef _VPU_INTERFACE_H_
#define _VPU_INTERFACE_H_


#include "ap_int.h"
/// error type ////
enum RES_STATUS {
    // normal status
	NORMAL,
	CFG_DONE,
	EXC_DONE,
	ACCU_DONE,
	MAXMIN_DONE,
	ADD_DONE,
	MUL_DONE,
	EXP_DONE,
	sACCU_DONE,
	PADDING_DONE,
	RESHAPE_DONE,
	// error status
	NO_OPTYPE,
	NO_OPCODE,
	MEM_OUT_BOUND
};

///   ISA definition ///
enum OPTYPE {
	CFG_STD,
	CFG_LOOP,
	EXC
};

enum OPCODE {
  // vector-vector operation
  vvADD,
  vvSUB,
  vvMUL,
  //vFMA [maybe]
  //n number of vector-vector operation
  vMAX,
  vMIN,
  vMEAN,
  vACCU,
   // vector sin/cos/tanh
  //vTANH,
  //vSIN,
  //vCOS,
  //vector exp
  vEXP,
  //vEXPACCU,
  //vSigmoid,
  //vSoftmax
  // vector-scalar operation
  vsADD,
  vsSUB,
  vsMUL,
  vsADDi,
  vsSUBi,
  vsMULi,
  //element accu
  sACCU,
  //vector structure reshape
  PADDING,
  RESHAPE
};


struct CMD{
  //first word
 // ap_uint<2> op_type;
 // ap_uint<6> opcode;
 // ap_uint<1> silent_res;

  // words
  ap_uint<32> word0; //for op_type, opcode, silendt_res;
  ap_uint<32> word1; //in cfg_stride: stride1; cfg_loop: loopmax1;         exc: mem_addr_src1
  ap_uint<32> word2; //in cfg_stride: stride2; cfg_loop: total_n;          exc: mem_addr_src2
  ap_uint<32> word3; //in cfg_stride: stride3; cfg_loop: immediate_scalor; exc: mem_addr_dst
  float scalor;
};


struct MEM {
  float BANK[LANE];
};

struct MEM_hw {
  float BANK0;
  float BANK1;
  float BANK2;
  float BANK3;
  float BANK4;
  float BANK5;
  float BANK6;
  float BANK7;
  float BANK8;
  float BANK9;
  float BANK10;
  float BANK11;
  float BANK12;
  float BANK13;
  float BANK14;
  float BANK15;
};

#endif
