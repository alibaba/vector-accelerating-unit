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

RES_STATUS vpu_MAX_MIN_v0p3(int opcode, int vnum, int stride1, int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi){
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct

static MEM_hw buff, result_max , result_min;
//#pragma HLS ARRAY_PARTITION variable=buff complete dim=1
RES_STATUS temp_status = NORMAL;

cout<< "in max min"<<endl;
	result_min.BANK0  = FLT_MAX;
	result_min.BANK1  = FLT_MAX;
	result_min.BANK2  = FLT_MAX;
	result_min.BANK3  = FLT_MAX;
	result_min.BANK4  = FLT_MAX;
	result_min.BANK5  = FLT_MAX;
	result_min.BANK6  = FLT_MAX;
	result_min.BANK7  = FLT_MAX;
	result_min.BANK8  = FLT_MAX;
	result_min.BANK9  = FLT_MAX;
	result_min.BANK10 = FLT_MAX;
	result_min.BANK11 = FLT_MAX;
	result_min.BANK12 = FLT_MAX;
	result_min.BANK13 = FLT_MAX;
	result_min.BANK14 = FLT_MAX;
	result_min.BANK15 = FLT_MAX;

	result_max.BANK0  = -FLT_MAX;
	result_max.BANK1  = -FLT_MAX;
	result_max.BANK2  = -FLT_MAX;
	result_max.BANK3  = -FLT_MAX;
	result_max.BANK4  = -FLT_MAX;
	result_max.BANK5  = -FLT_MAX;
	result_max.BANK6  = -FLT_MAX;
	result_max.BANK7  = -FLT_MAX;
	result_max.BANK8  = -FLT_MAX;
	result_max.BANK9  = -FLT_MAX;
	result_max.BANK10 = -FLT_MAX;
	result_max.BANK11 = -FLT_MAX;
	result_max.BANK12 = -FLT_MAX;
	result_max.BANK13 = -FLT_MAX;
	result_max.BANK14 = -FLT_MAX;
	result_max.BANK15 = -FLT_MAX;

//	cout<<"result max:"<<result_max.BANK0<<endl;

max_loop: for (int j = 0; j < vnum; j++){
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=32

	memcpy(&buff, (const MEM_hw*)(mem_axi + mem_addr1), sizeof(MEM_hw));
	mem_addr1 = mem_addr1+ stride1;
//	cout <<"opcode: "<<opcode<<endl;
	if (opcode == vMAX) {
		if ( buff.BANK0  > result_max.BANK0)  result_max.BANK0  = buff.BANK0;
		if ( buff.BANK1  > result_max.BANK1)  result_max.BANK1  = buff.BANK1;
		if ( buff.BANK2  > result_max.BANK2)  result_max.BANK2  = buff.BANK2;
		if ( buff.BANK3  > result_max.BANK3)  result_max.BANK3  = buff.BANK3;
		if ( buff.BANK4  > result_max.BANK4)  result_max.BANK4  = buff.BANK4;
		if ( buff.BANK5  > result_max.BANK5)  result_max.BANK5  = buff.BANK5;
		if ( buff.BANK6  > result_max.BANK6)  result_max.BANK6  = buff.BANK6;
		if ( buff.BANK7  > result_max.BANK7)  result_max.BANK7  = buff.BANK7;
		if ( buff.BANK8  > result_max.BANK8)  result_max.BANK8  = buff.BANK8;
		if ( buff.BANK9  > result_max.BANK9)  result_max.BANK9  = buff.BANK9;
		if ( buff.BANK10 > result_max.BANK10) result_max.BANK10 = buff.BANK10;
		if ( buff.BANK11 > result_max.BANK11) result_max.BANK11 = buff.BANK11;
		if ( buff.BANK12 > result_max.BANK12) result_max.BANK12 = buff.BANK12;
		if ( buff.BANK13 > result_max.BANK13) result_max.BANK13 = buff.BANK13;
		if ( buff.BANK14 > result_max.BANK14) result_max.BANK14 = buff.BANK14;
		if ( buff.BANK15 > result_max.BANK15) result_max.BANK15 = buff.BANK15;
	} else {
		if ( buff.BANK0  < result_min.BANK0)  result_min.BANK0  = buff.BANK0;
		if ( buff.BANK1  < result_min.BANK1)  result_min.BANK1  = buff.BANK1;
		if ( buff.BANK2  < result_min.BANK2)  result_min.BANK2  = buff.BANK2;
		if ( buff.BANK3  < result_min.BANK3)  result_min.BANK3  = buff.BANK3;
		if ( buff.BANK4  < result_min.BANK4)  result_min.BANK4  = buff.BANK4;
		if ( buff.BANK5  < result_min.BANK5)  result_min.BANK5  = buff.BANK5;
		if ( buff.BANK6  < result_min.BANK6)  result_min.BANK6  = buff.BANK6;
		if ( buff.BANK7  < result_min.BANK7)  result_min.BANK7  = buff.BANK7;
		if ( buff.BANK8  < result_min.BANK8)  result_min.BANK8  = buff.BANK8;
		if ( buff.BANK9  < result_min.BANK9)  result_min.BANK9  = buff.BANK9;
		if ( buff.BANK10 < result_min.BANK10) result_min.BANK10 = buff.BANK10;
		if ( buff.BANK11 < result_min.BANK11) result_min.BANK11 = buff.BANK11;
		if ( buff.BANK12 < result_min.BANK12) result_min.BANK12 = buff.BANK12;
		if ( buff.BANK13 < result_min.BANK13) result_min.BANK13 = buff.BANK13;
		if ( buff.BANK14 < result_min.BANK14) result_min.BANK14 = buff.BANK14;
		if ( buff.BANK15 < result_min.BANK15) result_min.BANK15 = buff.BANK15;
		}
	}

	if(opcode == vMAX) {
		//cout<<"insude result max"<<endl;
		memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result_max, sizeof(MEM_hw));
	} else {
		//cout<<"inside result min"<<endl;
		memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result_min, sizeof(MEM_hw));
	}

	if (mem_addr1 > RAM_SIZE + stride1)
	{
		temp_status = MEM_OUT_BOUND;
	}else {
		temp_status = MAXMIN_DONE;
	}
	return temp_status;
}
