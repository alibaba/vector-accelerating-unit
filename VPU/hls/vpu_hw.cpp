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


#include "vpu_hw.h"


//#include "math.h"

void vpu_hw(CMD cmd_fifo[CMD_QUEUE_DPETH], MEM_hw *mem_axi, MEM_hw *mem_out_axi, int response_fifo[CMD_QUEUE_DPETH]) {
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS DATA_PACK variable=cmd_fifo
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct
#pragma HLS INTERFACE ap_fifo port=cmd_fifo
#pragma HLS INTERFACE ap_fifo port=response_fifo

  static int status = NORMAL;
  static int op_type;
  static int opcode;
  static bool silent_res;
  static int mem_addr_src1;
  static int mem_addr_src2; // if vs operation, used as scalar addr
  static int mem_addr_dst;
  static int loopmax1;
  static int total_n;
  static int stride1;
  static int stride2;
  static int stride3;
  static float immediate_scalor;
  static int loopcount = 0;

  static float din0 [REGFILE_SIZE];
  static float din1 [REGFILE_SIZE];
  static float din2 [REGFILE_SIZE];
  static float din3 [REGFILE_SIZE];
  static float din4 [REGFILE_SIZE];
  static float din5 [REGFILE_SIZE];
  static float din6 [REGFILE_SIZE];
  static float din7 [REGFILE_SIZE];
  static float din8 [REGFILE_SIZE];
  static float din9 [REGFILE_SIZE];
  static float din10[REGFILE_SIZE];
  static float din11[REGFILE_SIZE];
  static float din12[REGFILE_SIZE];
  static float din13[REGFILE_SIZE];
  static float din14[REGFILE_SIZE];
  static float din15[REGFILE_SIZE];

  static float sum_p0[FADD_LAT];
  static float sum_p1[FADD_LAT];
  static float sum_p2[FADD_LAT];
  static float sum_p3[FADD_LAT];
  static float sum_p4[FADD_LAT];
  static float sum_p5[FADD_LAT];
  static float sum_p6[FADD_LAT];
  static float sum_p7[FADD_LAT];
  static float sum_p8[FADD_LAT];
  static float sum_p9[FADD_LAT];
  static float sum_p10[FADD_LAT];
  static float sum_p11[FADD_LAT];
  static float sum_p12[FADD_LAT];
  static float sum_p13[FADD_LAT];
  static float sum_p14[FADD_LAT];
  static float sum_p15[FADD_LAT];

#pragma HLS ARRAY_PARTITION variable=sum_p0 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p1 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p2 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p3 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p4 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p5 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p6 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p7 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p8 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p9 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p10 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p11 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p12 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p13 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p14 complete dim=1
#pragma HLS ARRAY_PARTITION variable=sum_p15 complete dim=1

/*
  //init registers
  for (int i = 0; i < REGFILE_SIZE; i++)
  {
#pragma HLS UNROLL
	  din0[i] = 0;
	  din1[i] = 0;
	  din2[i] = 0;
	  din3[i] = 0;
	  din4[i] = 0;
	  din5[i] = 0;
	  din6[i] = 0;
	  din7[i] = 0;
	  din8[i] = 0;
	  din9[i] = 0;
	  din10[i] = 0;
	  din11[i] = 0;
	  din12[i] = 0;
	  din13[i] = 0;
	  din14[i] = 0;
	  din15[i] = 0;
  }
  */

  //cout << "vpu hw start. " << endl;

  CMD cmd_reg;

  cmd_reg = cmd_fifo[0];
  status = cmdDecode_v0p3(&cmd_reg, &op_type, &opcode, &silent_res, &mem_addr_src1, &mem_addr_src2, &mem_addr_dst,
		  &loopmax1, &total_n, &stride1, &stride2, &stride3, &immediate_scalor);
  if(status != NORMAL) {
	  if (silent_res != true) {
		  response_fifo[0] = status;
	  }
	  //cout<<"post decode status not normal = "<<status<<endl;
	  return;
  }
	//cout << "out finish loadcmd, opcode =  " << opcode << endl;
	//cout << "out finish loadcmd, mem_addr_src1 =  " << mem_addr_src1 << endl;
	//cout << "out finish loadcmd, mem_addr_src2 =  " << mem_addr_src2 << endl;
	//cout << "out finish loadcmd, mem_addr_dst =  " << mem_addr_dst << endl;
	//cout << "out finish loadcmd, loopmax1 =  " << loopmax1 << endl;
	//cout << "out finish loadcmd, total_n =  " << total_n << endl;
	//cout << "out finish loadcmd, stride1 =  " << stride1 << endl;
	//cout << "out finish loadcmd, stride2 =  " << stride2 << endl;
	//cout << "out finish loadcmd, stride3 =  " << stride3 << endl;
	//cout<< "finish loadcmd, immediate_scalor: "<< immediate_scalor<<endl;

  if(op_type == CFG_STD || op_type == CFG_LOOP) {
	//  cout<<"configure"<<endl;
	  status = CFG_DONE;
	  if (silent_res != true) {
		  //cout<<"inside CFG not silent"<<endl;
		  response_fifo[0] = status;
	  }
	//  cout<< "end configure. res="<<response_fifo[0] <<endl;
	  return;
  }

  switch (opcode){
  case vACCU:
  case vMEAN:
	  //cout << "inside accu. " << endl;
	  status = vpu_vACCU_v0p3(opcode, total_n, loopmax1, stride1, stride2,
			  mem_addr_src1, mem_axi, mem_addr_dst, mem_out_axi, immediate_scalor,
			  din0, din1, din2, din3, din4, din5, din6, din7,
			  din8, din9, din10, din11, din12, din13, din14, din15,
			  sum_p0, sum_p1, sum_p2, sum_p3, sum_p4, sum_p5, sum_p6, sum_p7,
			  sum_p8, sum_p9, sum_p10, sum_p11, sum_p12, sum_p13, sum_p14, sum_p15);
	  break;
  case vMAX:
  case vMIN:
	  //cout<< "inside max min." <<endl;
	  status = vpu_MAX_MIN_v0p3(opcode, total_n, stride1, mem_addr_src1, mem_axi, mem_addr_dst, mem_out_axi);
	  break;
  case vvADD:
  case vsADD:
  case vsADDi:
  case vvSUB:
  case vsSUB:
  case vsSUBi:
	  //cout << "inside vv/vsADD." << endl;
	  status = vpu_vvADD_vvSUB_v0p3(opcode, total_n, stride1, stride2, stride3, mem_addr_src1, mem_addr_src2, mem_axi,
			  	mem_addr_dst, mem_out_axi, immediate_scalor,
				din0, din1, din2, din3, din4, din5, din6, din7,
				din8, din9, din10, din11, din12, din13, din14, din15,
				sum_p0, sum_p1, sum_p2, sum_p3, sum_p4, sum_p5, sum_p6, sum_p7,
				sum_p8, sum_p9, sum_p10, sum_p11, sum_p12, sum_p13, sum_p14, sum_p15);
	  break;
  case vvMUL:
  case vsMUL:
  case vsMULi:
	  //cout << "inside vv/vsMUL." <<endl;
	  status = vpu_vvMUL_v0p3(opcode, total_n, stride1, stride2, stride3, mem_addr_src1, mem_addr_src2, mem_axi,
			   mem_addr_dst, mem_out_axi, immediate_scalor,
			   din0, din1, din2, din3, din4, din5, din6, din7,
			   din8, din9, din10, din11, din12, din13, din14, din15,
			   sum_p0, sum_p1, sum_p2, sum_p3, sum_p4, sum_p5, sum_p6, sum_p7,
			   sum_p8, sum_p9, sum_p10, sum_p11, sum_p12, sum_p13, sum_p14, sum_p15);
	  break;
  case vEXP:
	  //cout << "inside vEXP. " <<endl;
	  status = vpu_vEXP_v0p3(total_n, stride1, stride3, mem_addr_src1,
			  mem_axi, mem_addr_dst, mem_out_axi);
	  break;
  case sACCU:
	  //cout << "inside sACCU. "<<endl;
	  status = vpu_reduction16to1_v0p3(total_n, loopmax1, mem_addr_src1, stride1, mem_axi,
	  		mem_addr_dst, stride3, mem_out_axi);
	  break;
  case PADDING:
	  //cout << "inside Padding. " <<endl;
	  status = vpu_PADDING_v0p3(total_n, stride3, mem_addr_dst, mem_out_axi);
	  break;
  case RESHAPE:
	  //cout << "inside reshape. " <<endl;
	  status = vpu_ReShape_v0p3(total_n, stride1, stride3, mem_addr_src1, mem_axi, mem_addr_dst, mem_out_axi);
	  break;

	default:
		status = NO_OPCODE;
		printf("Err! main optype: no such optype!");
  }

  //cout<<"out compute"<<endl;
  if (silent_res != true) {
	  response_fifo[0] = status;
  }
  //cout<< "end response = "<<response_fifo[0] <<endl;
  return;
}


