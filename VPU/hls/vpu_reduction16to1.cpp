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

RES_STATUS vpu_reduction16to1_v0p3(int vnum, int vlen, int mem_addr1, int stride1, MEM_hw *mem_axi,
		int mem_addr_dst, int stride3, MEM_hw *mem_out_axi){
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct

static MEM_hw buff[REGFILE_SIZE];
static MEM_hw result[REGFILE_SIZE];
static bool mask[LANE];
#pragma HLS ARRAY_PARTITION variable=mask complete dim=1
RES_STATUS temp_status = NORMAL;

for (int i = 0; i < LANE; i++) {
#pragma HLS unroll
	mask[i] = (i < vlen)? true:false;
}

for (int j = 0; j < 32; j++) {
	result[j].BANK0 = 0.0;
	result[j].BANK1 = 0.0;
	result[j].BANK2 = 0.0;
	result[j].BANK3 = 0.0;
	result[j].BANK4 = 0.0;
	result[j].BANK5 = 0.0;
	result[j].BANK6 = 0.0;
	result[j].BANK7 = 0.0;
	result[j].BANK8 = 0.0;
	result[j].BANK9 = 0.0;
	result[j].BANK10 = 0.0;
	result[j].BANK11 = 0.0;
	result[j].BANK12 = 0.0;
	result[j].BANK13 = 0.0;
	result[j].BANK14 = 0.0;
	result[j].BANK15 = 0.0;
}
//cout<<"inside exp"<<endl;
//cout<<"mem addr1 = "<<mem_addr1<<", mem_addr2 = "<<mem_addr2<<", mem_dst"<<mem_addr_dst<<endl;

reduction_loop: for (int j = 0; j < vnum; j++){
//#pragma HLS DATAFLOW
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=32

	memcpy(&buff[j], (const MEM_hw*)(mem_axi + mem_addr1), sizeof(MEM_hw));
	mem_addr1 = mem_addr1+ stride1;
	buff[j].BANK0  =  mask[0 ] ? buff[j].BANK0  : 0.0 ;
	buff[j].BANK1  =  mask[1 ] ? buff[j].BANK1  : 0.0 ;
	buff[j].BANK2  =  mask[2 ] ? buff[j].BANK2  : 0.0 ;
	buff[j].BANK3  =  mask[3 ] ? buff[j].BANK3  : 0.0 ;
	buff[j].BANK4  =  mask[4 ] ? buff[j].BANK4  : 0.0 ;
	buff[j].BANK5  =  mask[5 ] ? buff[j].BANK5  : 0.0 ;
	buff[j].BANK6  =  mask[6 ] ? buff[j].BANK6  : 0.0 ;
	buff[j].BANK7  =  mask[7 ] ? buff[j].BANK7  : 0.0 ;
	buff[j].BANK8  =  mask[8 ] ? buff[j].BANK8  : 0.0 ;
	buff[j].BANK9  =  mask[9 ] ? buff[j].BANK9  : 0.0 ;
	buff[j].BANK10 =  mask[10] ? buff[j].BANK10 : 0.0 ;
	buff[j].BANK11 =  mask[11] ? buff[j].BANK11 : 0.0 ;
	buff[j].BANK12 =  mask[12] ? buff[j].BANK12 : 0.0 ;
	buff[j].BANK13 =  mask[13] ? buff[j].BANK13 : 0.0 ;
	buff[j].BANK14 =  mask[14] ? buff[j].BANK14 : 0.0 ;
	buff[j].BANK15 =  mask[15] ? buff[j].BANK15 : 0.0 ;

	result[j].BANK0 = adder_tree_16to1_v0p3(buff[j]);

	memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result[j], sizeof(MEM_hw));
	mem_addr_dst = mem_addr_dst + stride3;
}
if (mem_addr_dst > RAM_SIZE + stride3 || mem_addr1 + stride1)
{
	temp_status = MEM_OUT_BOUND;
}else {
	temp_status = sACCU_DONE;
}
return temp_status;
}
