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

#ifndef _VPU_HW_H_
#define _VPU_HW_H_

#include <iostream>
#include <fstream>
#include <cstring>

#include <stdio.h>
#include <cstdlib>
#include <iostream>
#include "hls_math.h"
#include <hls_stream.h>
#include "float.h"
using namespace std;

#include "vpu_param.h"
#include "vpu_interface.h"


void vpu_hw(CMD cmd_fifo[CMD_QUEUE_DPETH],
				MEM_hw *mem_axi, MEM_hw *mem_out_axi, int response_fifo[CMD_QUEUE_DPETH]);

int VPU_funcModel_v0p3(CMD *cmd_queue, MEM *mem);

RES_STATUS cmdDecode_v0p3(CMD *cmd, int *op_type, int *opcode, bool *silent_res, int *mem_addr_src1, int *mem_addr_src2, int *mem_addr_dst,
		       int *loopmax1, int *total_n, int *stride1, int *stride2, int *stride3, float *immediate_scalor);

void alu_tree_v0p3 (float *sum_p0, float *sum_p1, float *sum_p2, float *sum_p3,
				  float *sum_p4, float *sum_p5, float *sum_p6, float *sum_p7,
				  float *sum_p8, float *sum_p9, float *sum_p10, float *sum_p11,
				  float *sum_p12, float *sum_p13, float *sum_p14, float *sum_p15,
				  float *sum0, float *sum1, float *sum2, float *sum3,
				  float *sum4, float *sum5, float *sum6, float *sum7,
				  float *sum8, float *sum9, float *sum10, float *sum11,
				  float *sum12, float *sum13, float *sum14, float *sum15,
				  MEM_hw *result);

float adder_tree_16to1_v0p3 (MEM_hw buff);

RES_STATUS vpu_reduction16to1_v0p3(int vnum, int vlen, int mem_addr1, int stride1, MEM_hw *mem_axi,
		int mem_addr_dst, int stride3, MEM_hw *mem_out_axi);

RES_STATUS vpu_vACCU_v0p3(int opcode, int vnum, int loopmax1, int stride1,  int stride2,
		  int mem_addr_start, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi, float immediate_scalor,
          float din0 [ACCU_BUFF_S], float din1 [ACCU_BUFF_S], float din2 [ACCU_BUFF_S], float din3 [ACCU_BUFF_S],
		  float din4 [ACCU_BUFF_S], float din5 [ACCU_BUFF_S], float din6 [ACCU_BUFF_S], float din7 [ACCU_BUFF_S],
		  float din8 [ACCU_BUFF_S], float din9 [ACCU_BUFF_S], float din10[ACCU_BUFF_S], float din11[ACCU_BUFF_S],
		  float din12[ACCU_BUFF_S], float din13[ACCU_BUFF_S], float din14[ACCU_BUFF_S], float din15[ACCU_BUFF_S],
		  float sum_p0 [FADD_LAT], float sum_p1 [FADD_LAT], float sum_p2 [FADD_LAT], float sum_p3 [FADD_LAT],
		  float sum_p4 [FADD_LAT], float sum_p5 [FADD_LAT], float sum_p6 [FADD_LAT], float sum_p7 [FADD_LAT],
		  float sum_p8 [FADD_LAT], float sum_p9 [FADD_LAT], float sum_p10[FADD_LAT], float sum_p11[FADD_LAT],
		  float sum_p12[FADD_LAT], float sum_p13[FADD_LAT], float sum_p14[FADD_LAT], float sum_p15[FADD_LAT]);

RES_STATUS vpu_vvADD_vvSUB_v0p3(int opcode, int vnum, int stride1, int stride2, int stride3,
		  int mem_addr1, int mem_addr2, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi, float immediate_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE],
          float inload0 [ADDER_DEP],float inload1 [ADDER_DEP],float inload2 [ADDER_DEP],float inload3 [ADDER_DEP],
		  float inload4 [ADDER_DEP],float inload5 [ADDER_DEP],float inload6 [ADDER_DEP],float inload7 [ADDER_DEP],
		  float inload8 [ADDER_DEP],float inload9 [ADDER_DEP],float inload10[ADDER_DEP],float inload11[ADDER_DEP],
		  float inload12[ADDER_DEP],float inload13[ADDER_DEP],float inload14[ADDER_DEP],float inload15[ADDER_DEP]);

RES_STATUS vpu_vvMUL_v0p3(int opcode, int vnum, int stride1, int stride2, int stride3,
		  int mem_addr1, int mem_addr2, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi, float immediate_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE],
          float inload0 [ADDER_DEP],float inload1 [ADDER_DEP],float inload2 [ADDER_DEP],float inload3 [ADDER_DEP],
		  float inload4 [ADDER_DEP],float inload5 [ADDER_DEP],float inload6 [ADDER_DEP],float inload7 [ADDER_DEP],
		  float inload8 [ADDER_DEP],float inload9 [ADDER_DEP],float inload10[ADDER_DEP],float inload11[ADDER_DEP],
		  float inload12[ADDER_DEP],float inload13[ADDER_DEP],float inload14[ADDER_DEP],float inload15[ADDER_DEP]);

RES_STATUS vpu_vEXP_v0p3(int vnum, int stride1, int stride3,
		  int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi);

RES_STATUS vpu_MAX_MIN_v0p3(int opcode, int vnum, int stride1, int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi);

void vpu_load_reg16_v0p3(int opcode, int vnum, int stride,
		  int mem_addr, MEM_hw *mem_axi,float imme_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE]);

RES_STATUS vpu_PADDING_v0p3(int vnum, int stride3, int mem_addr_dst, MEM_hw *mem_out_axi);

RES_STATUS vpu_ReShape_v0p3(int vnum, int stride1, int stride3, int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi);

#endif
