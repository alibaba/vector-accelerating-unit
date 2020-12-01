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
/*
void vpu_vTANH_v0p2(int vnum, int stride1, int stride3,
		  int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi){
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=512 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=512 port=mem_axi //offset=direct

static MEM_hw buff[32], result[32];

//cout<<"inside exp"<<endl;
//cout<<"mem addr1 = "<<mem_addr1<<", mem_addr2 = "<<mem_addr2<<", mem_dst"<<mem_addr_dst<<endl;

exp_loop: for (int j = 0; j < vnum; j++){
//#pragma HLS DATAFLOW
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=32

memcpy(&buff[j], (const MEM_hw*)(mem_axi + mem_addr1), sizeof(MEM_hw));
mem_addr1 = mem_addr1+ stride1;

		result[j].BANK0  = tanh(buff[j].BANK0);
		result[j].BANK1  = tanh(buff[j].BANK1);
		result[j].BANK2  = tanh(buff[j].BANK2);
		result[j].BANK3  = tanh(buff[j].BANK3);
		result[j].BANK4  = tanh(buff[j].BANK4);
		result[j].BANK5  = tanh(buff[j].BANK5);
		result[j].BANK6  = tanh(buff[j].BANK6);
		result[j].BANK7  = tanh(buff[j].BANK7);
		result[j].BANK8  = tanh(buff[j].BANK8);
		result[j].BANK9  = tanh(buff[j].BANK9);
		result[j].BANK10 = tanh(buff[j].BANK10);
		result[j].BANK11 = tanh(buff[j].BANK11);
		result[j].BANK12 = tanh(buff[j].BANK12);
		result[j].BANK13 = tanh(buff[j].BANK13);
		result[j].BANK14 = tanh(buff[j].BANK14);
		result[j].BANK15 = tanh(buff[j].BANK15);
		result[j].BANK16 = tanh(buff[j].BANK16);
		result[j].BANK17 = tanh(buff[j].BANK17);
		result[j].BANK18 = tanh(buff[j].BANK18);
		result[j].BANK19 = tanh(buff[j].BANK19);
		result[j].BANK20 = tanh(buff[j].BANK20);
		result[j].BANK21 = tanh(buff[j].BANK21);
		result[j].BANK22 = tanh(buff[j].BANK22);
		result[j].BANK23 = tanh(buff[j].BANK23);
		result[j].BANK24 = tanh(buff[j].BANK24);
		result[j].BANK25 = tanh(buff[j].BANK25);
		result[j].BANK26 = tanh(buff[j].BANK26);
		result[j].BANK27 = tanh(buff[j].BANK27);
		result[j].BANK28 = tanh(buff[j].BANK28);
		result[j].BANK29 = tanh(buff[j].BANK29);
		result[j].BANK30 = tanh(buff[j].BANK30);
		result[j].BANK31 = tanh(buff[j].BANK31);
	//	cout<<"j ="<<j<<", bank0= "<<buff[j].BANK0<<", bank1 = "
	//			<<buff[j].BANK1<<", bank15 = "<<buff[j].BANK15<<endl;
	//	cout<<"j ="<<j<<", result,bank0 = "<<result[j].BANK0<<", result.bank1 = "
	//			<<result[j].BANK1<<", result,bank15 = "<<result[j].BANK15<<endl;

memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result[j], sizeof(MEM_hw));
mem_addr_dst = mem_addr_dst + stride3;

}
}*/
