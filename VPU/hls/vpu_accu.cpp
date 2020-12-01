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
		  float sum_p12[FADD_LAT], float sum_p13[FADD_LAT], float sum_p14[FADD_LAT], float sum_p15[FADD_LAT] ){
	
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct
	RES_STATUS temp_status = NORMAL;

	static MEM_hw buff, result;

	int mem_addr = mem_addr_start;
	bool mask = true;
	int stridecount = 0;
	static float re_vnum;
	re_vnum= immediate_scalor;
	//cout << "immediate: "<< immediate_scalor<<endl;
	//cout << "re_vnum: "<< re_vnum<<endl;

loop_init: for(int i=0;i<FADD_LAT;i++) {
#pragma HLS UNROLL
				sum_p0[i] = 0;
				sum_p1[i] = 0;
				sum_p2[i] = 0;
				sum_p3[i] = 0;
				sum_p4[i] = 0;
				sum_p5[i] = 0;
				sum_p6[i] = 0;
				sum_p7[i] = 0;
				sum_p8[i] = 0;
				sum_p9[i] = 0;
				sum_p10[i] = 0;
				sum_p11[i] = 0;
				sum_p12[i] = 0;
				sum_p13[i] = 0;
				sum_p14[i] = 0;
				sum_p15[i] = 0;
			}

loop_out: for (int k = 0; k<vnum; k=k+22) {
My_region: {
#pragma HLS PIPELINE
loop_load: for (int i = 0;i < 22; i++) {
#pragma HLS PIPELINE II=1
//Pipeline set to be II=22 due to HLS syn, which depends on frequency adder stage is different.
//Pipeline setting need to be adjusted accordingly at different frequency
	if (k+i >= vnum ) mask = false;
				if(mask) memcpy(&buff, (const MEM_hw*)(mem_axi + mem_addr), sizeof(MEM_hw));
				din0[i] = mask ? buff.BANK0:0.0;
				din1[i] = mask ? buff.BANK1:0.0;
				din2[i] = mask ? buff.BANK2:0.0;
				din3[i] = mask ? buff.BANK3:0.0;
				din4[i] = mask ? buff.BANK4:0.0;
				din5[i] = mask ? buff.BANK5:0.0;
				din6[i] = mask ? buff.BANK6:0.0;
				din7[i] = mask ? buff.BANK7:0.0;
				din8[i] = mask ? buff.BANK8:0.0;
				din9[i] = mask ? buff.BANK9:0.0;
				din10[i] = mask ? buff.BANK10:0.0;
				din11[i] = mask ? buff.BANK11:0.0;
				din12[i] = mask ? buff.BANK12:0.0;
				din13[i] = mask ? buff.BANK13:0.0;
				din14[i] = mask ? buff.BANK14:0.0;
				din15[i] = mask ? buff.BANK15:0.0;
				stridecount ++;
				if (stridecount == loopmax1) {
					mem_addr = mem_addr + stride2; stridecount = 0;
				}else {
					mem_addr = mem_addr + stride1;
				}
				//cout << "k="<<k<<", k+i="<<k+i<<", mask="<<mask<<endl;
				//cout << "i: "<<i<<", din0 = "<<din0[i] << endl;
			}

LOOP_main:for(int i=0;i<22;i+=11){
#pragma HLS PIPELINE II=11 rewind
			for (int j=0; j<11; j++) {
				sum_p0[j]+=din0[j+i];
				sum_p1[j]+=din1[j+i];
				sum_p2[j]+=din2[j+i];
				sum_p3[j]+=din3[j+i];
				sum_p4[j]+=din4[j+i];
				sum_p5[j]+=din5[j+i];
				sum_p6[j]+=din6[j+i];
				sum_p7[j]+=din7[j+i];
				sum_p8[j]+=din8[j+i];
				sum_p9[j]+=din9[j+i];
				sum_p10[j]+=din10[j+i];
				sum_p11[j]+=din11[j+i];
				sum_p12[j]+=din12[j+i];
				sum_p13[j]+=din13[j+i];
				sum_p14[j]+=din14[j+i];
				sum_p15[j]+=din15[j+i];
				//cout << "j: "<<j<<", sum_p0 = "<<sum_p0[j] << endl;
			}
		}
	}
}

	alu_tree_v0p3(sum_p0, sum_p1, sum_p2, sum_p3,
		    sum_p4, sum_p5, sum_p6, sum_p7,
			sum_p8, sum_p9, sum_p10, sum_p11,
			sum_p12, sum_p13, sum_p14, sum_p15,
			&din0 [22], &din1 [22], &din2 [22], &din3 [22],
			&din4 [22], &din5 [22], &din6 [22], &din7 [22],
			&din8 [22], &din9 [22], &din10[22], &din11[22],
			&din12[22], &din13[22], &din14[22], &din15[22],
			&result);

	//cout<<"accu result: "<<*sum0<<","<<*sum1<<","<<*sum2<<","<<*sum3<<endl;
	if (opcode == vMEAN) {
		//cout<< "inside mean result: "<<endl;
		result.BANK0 = result.BANK0 * re_vnum;
		result.BANK1 = result.BANK1 * re_vnum;
		result.BANK2 = result.BANK2 * re_vnum;
		result.BANK3 = result.BANK3 * re_vnum;
		result.BANK4 = result.BANK4 * re_vnum;
		result.BANK5 = result.BANK5 * re_vnum;
		result.BANK6 = result.BANK6 * re_vnum;
		result.BANK7 = result.BANK7 * re_vnum;
		result.BANK8 = result.BANK8 * re_vnum;
		result.BANK9 = result.BANK9 * re_vnum;
		result.BANK10 = result.BANK10 * re_vnum;
		result.BANK11 = result.BANK11 * re_vnum;
		result.BANK12 = result.BANK12 * re_vnum;
		result.BANK13 = result.BANK13 * re_vnum;
		result.BANK14 = result.BANK14 * re_vnum;
		result.BANK15 = result.BANK15 * re_vnum;
	}

	memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result, sizeof(MEM_hw));

	if (mem_addr > RAM_SIZE + stride1){
		temp_status = MEM_OUT_BOUND;
	}else {
		temp_status = ACCU_DONE;
	}
	return temp_status;
}
