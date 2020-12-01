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

RES_STATUS vpu_PADDING_v0p3(int vnum, int stride3, int mem_addr_dst, MEM_hw *mem_out_axi){
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct

RES_STATUS temp_status = NORMAL;

static MEM_hw zeropad;
zeropad.BANK0  = 0 ;
zeropad.BANK1  = 0 ;
zeropad.BANK2  = 0 ;
zeropad.BANK3  = 0 ;
zeropad.BANK4  = 0 ;
zeropad.BANK5  = 0 ;
zeropad.BANK6  = 0 ;
zeropad.BANK7  = 0 ;
zeropad.BANK8  = 0 ;
zeropad.BANK9  = 0 ;
zeropad.BANK10 = 0 ;
zeropad.BANK11 = 0 ;
zeropad.BANK12 = 0 ;
zeropad.BANK13 = 0 ;
zeropad.BANK14 = 0 ;
zeropad.BANK15 = 0 ;

//cout<<"inside exp"<<endl;
//cout<<"mem addr1 = "<<mem_addr1<<", mem_addr2 = "<<mem_addr2<<", mem_dst"<<mem_addr_dst<<endl;

pad_loop: for (int j = 0; j < vnum; j++){

#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=32

	memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&zeropad, sizeof(MEM_hw));
	mem_addr_dst = mem_addr_dst + stride3;

}

if (mem_addr_dst > RAM_SIZE + stride3)
{
	temp_status = MEM_OUT_BOUND;
}else {
	temp_status = PADDING_DONE;
}
  return temp_status;
}

RES_STATUS vpu_ReShape_v0p3(int vnum, int stride1, int stride3, int mem_addr1, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi){
#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
RES_STATUS temp_status = NORMAL;

static MEM_hw buff[REGFILE_SIZE];

reshape_loop: for (int j = 0; j < vnum; j++){
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=32

	memcpy(&buff[j], (const MEM_hw*)(mem_axi + mem_addr1), sizeof(MEM_hw));
	mem_addr1 = mem_addr1+ stride1;

	memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&buff[j], sizeof(MEM_hw));
	mem_addr_dst = mem_addr_dst + stride3;

}

if (mem_addr_dst > RAM_SIZE + stride3 || mem_addr1 > RAM_SIZE + stride1)
{
	temp_status = MEM_OUT_BOUND;
}else {
	temp_status = RESHAPE_DONE;
}
  return temp_status;
}
