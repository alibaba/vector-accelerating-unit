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

RES_STATUS vpu_vvADD_vvSUB_v0p3(int opcode, int vnum, int stride1, int stride2, int stride3,
		  int mem_addr1, int mem_addr2, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi,float imme_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE],
          float inload0[ADDER_DEP],float inload1[ADDER_DEP],float inload2[ADDER_DEP],float inload3[ADDER_DEP],
		  float inload4[ADDER_DEP],float inload5[ADDER_DEP],float inload6[ADDER_DEP],float inload7[ADDER_DEP],
		  float inload8[ADDER_DEP],float inload9[ADDER_DEP],float inload10[ADDER_DEP],float inload11[ADDER_DEP],
		  float inload12[ADDER_DEP],float inload13[ADDER_DEP],float inload14[ADDER_DEP],float inload15[ADDER_DEP]){

#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct

bool mask1 = (opcode ==vvADD||opcode == vvSUB)? true:false;
bool mask2 = true;
static MEM_hw buff2, result[ADDER_DEP];
RES_STATUS temp_status = NORMAL;

vpu_load_reg16_v0p3(opcode, vnum, stride1, mem_addr1, mem_axi, imme_scalor,
			din0, din1, din2, din3, din4, din5, din6, din7,
			din8, din9, din10, din11, din12, din13, din14, din15);
	for (int i = 0; i<vnum; i = i+10) {
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=4
		for (int j=0; j<10; j++) {
#pragma HLS PIPELINE II=1
//pipeline set to be 10 due to HLS syn, which depends on frequency adder stage is different.
//Pipeline setting need to be adjusted accordingly at different frequency.
		memcpy(&buff2, (const MEM_hw*)(mem_axi + mem_addr2), sizeof(MEM_hw));
		if (i+j >= vnum ) mask2 = false;
		inload0[j] = mask2? buff2.BANK0: 0.0;
		inload1[j] = mask2? buff2.BANK1: 0.0;
		inload2[j] = mask2? buff2.BANK2: 0.0;
		inload3[j] = mask2? buff2.BANK3: 0.0;
		inload4[j] = mask2? buff2.BANK4: 0.0;
		inload5[j] = mask2? buff2.BANK5: 0.0;
		inload6[j] = mask2? buff2.BANK6: 0.0;
		inload7[j] = mask2? buff2.BANK7: 0.0;
		inload8[j] = mask2? buff2.BANK8: 0.0;
		inload9[j] = mask2? buff2.BANK9: 0.0;
		inload10[j] = mask2? buff2.BANK10: 0.0;
		inload11[j] = mask2? buff2.BANK11: 0.0;
		inload12[j] = mask2? buff2.BANK12: 0.0;
		inload13[j] = mask2? buff2.BANK13: 0.0;
		inload14[j] = mask2? buff2.BANK14: 0.0;
		inload15[j] = mask2? buff2.BANK15: 0.0;
		mem_addr2 = mem_addr2 + stride2;
	}

		My_region_add: {
#pragma HLS PIPELINE II=10 rewind
		for(int k=0; k<10;k++) {
			result[k].BANK0  = inload0 [k] + ( mask1? din0[i+k]  : din0 [0] );
			result[k].BANK1  = inload1 [k] + ( mask1? din1[i+k]  : din1 [0] );
			result[k].BANK2  = inload2 [k] + ( mask1? din2[i+k]  : din2 [0] );
			result[k].BANK3  = inload3 [k] + ( mask1? din3[i+k]  : din3 [0] );
			result[k].BANK4  = inload4 [k] + ( mask1? din4[i+k]  : din4 [0] );
			result[k].BANK5  = inload5 [k] + ( mask1? din5[i+k]  : din5 [0] );
			result[k].BANK6  = inload6 [k] + ( mask1? din6[i+k]  : din6 [0] );
			result[k].BANK7  = inload7 [k] + ( mask1? din7[i+k]  : din7 [0] );
			result[k].BANK8  = inload8 [k] + ( mask1? din8[i+k]  : din8 [0] );
			result[k].BANK9  = inload9 [k] + ( mask1? din9[i+k]  : din9 [0] );
			result[k].BANK10 = inload10[k] + ( mask1? din10[i+k] : din10[0] );
			result[k].BANK11 = inload11[k] + ( mask1? din11[i+k] : din11[0] );
			result[k].BANK12 = inload12[k] + ( mask1? din12[i+k] : din12[0] );
			result[k].BANK13 = inload13[k] + ( mask1? din13[i+k] : din13[0] );
			result[k].BANK14 = inload14[k] + ( mask1? din14[i+k] : din14[0] );
			result[k].BANK15 = inload15[k] + ( mask1? din15[i+k] : din15[0] );

			//	cout<<"mask1: "<<mask1<<endl;
			//	cout<<"inside +, k= "<<k<<",lane0 in1= "<< inload0[k]<< ", in2 ="<< din0[0]<<endl;
			//	cout<<"inside +, k= "<<k<<",lane1 in1= "<< inload1[k]<< ", in2 ="<< din1[0]<<endl;
		}
	}

loop_store:	for (int k = 0; k <10; k++) {
//#pragma HLS PIPELINE II=1
				if(i+k<vnum) {
				memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result[k], sizeof(MEM_hw));
				mem_addr_dst = mem_addr_dst + stride3;
			}
		}
	}
	if (mem_addr1 > RAM_SIZE + stride1 || mem_addr_dst > RAM_SIZE + stride3 || mem_addr2 > RAM_SIZE + stride2)
	{
		temp_status = MEM_OUT_BOUND;
	}else {
		temp_status = ADD_DONE;
	}
	  return temp_status;
}

RES_STATUS vpu_vvMUL_v0p3(int opcode, int vnum, int stride1, int stride2, int stride3,
		  int mem_addr1, int mem_addr2, MEM_hw *mem_axi,
		  int mem_addr_dst, MEM_hw *mem_out_axi,float imme_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE],
          float inload0[ADDER_DEP],float inload1[ADDER_DEP],float inload2[ADDER_DEP],float inload3[ADDER_DEP],
		  float inload4[ADDER_DEP],float inload5[ADDER_DEP],float inload6[ADDER_DEP],float inload7[ADDER_DEP],
		  float inload8[ADDER_DEP],float inload9[ADDER_DEP],float inload10[ADDER_DEP],float inload11[ADDER_DEP],
		  float inload12[ADDER_DEP],float inload13[ADDER_DEP],float inload14[ADDER_DEP],float inload15[ADDER_DEP]){

#pragma HLS DATA_PACK variable=mem_out_axi
#pragma HLS DATA_PACK variable=mem_axi
#pragma HLS INTERFACE m_axi depth=131072 port=mem_out_axi //offset=direct
#pragma HLS INTERFACE m_axi depth=131072 port=mem_axi //offset=direct

bool mask1 = opcode ==vvMUL? true:false;
bool mask2 = true;
static MEM_hw buff2, result[ADDER_DEP];
RES_STATUS temp_status = NORMAL;

vpu_load_reg16_v0p3(opcode, vnum, stride1, mem_addr1, mem_axi, imme_scalor,
			din0, din1, din2, din3, din4, din5, din6, din7,
			din8, din9, din10, din11, din12, din13, din14, din15);

for (int i = 0; i<vnum; i = i+10) {
	My_region_vv_mul: {
#pragma HLS PIPELINE
#pragma HLS LOOP_TRIPCOUNT min=1 max=4
	for (int j=0; j<10; j++) {
#pragma HLS PIPELINE II=1
//pipeline set to be 10 due to HLS syn, which depends on frequency adder stage is different.
//Pipeline setting need to be adjusted accordingly at different frequency.
		memcpy(&buff2, (const MEM_hw*)(mem_axi + mem_addr2), sizeof(MEM_hw));
		if (i+j >= vnum ) mask2 = false;
		inload0[j] = mask2? buff2.BANK0: 0.0;
		inload1[j] = mask2? buff2.BANK1: 0.0;
		inload2[j] = mask2? buff2.BANK2: 0.0;
		inload3[j] = mask2? buff2.BANK3: 0.0;
		inload4[j] = mask2? buff2.BANK4: 0.0;
		inload5[j] = mask2? buff2.BANK5: 0.0;
		inload6[j] = mask2? buff2.BANK6: 0.0;
		inload7[j] = mask2? buff2.BANK7: 0.0;
		inload8[j] = mask2? buff2.BANK8: 0.0;
		inload9[j] = mask2? buff2.BANK9: 0.0;
		inload10[j] = mask2? buff2.BANK10: 0.0;
		inload11[j] = mask2? buff2.BANK11: 0.0;
		inload12[j] = mask2? buff2.BANK12: 0.0;
		inload13[j] = mask2? buff2.BANK13: 0.0;
		inload14[j] = mask2? buff2.BANK14: 0.0;
		inload15[j] = mask2? buff2.BANK15: 0.0;
		mem_addr2 = mem_addr2 + stride2;
		//cout <<"j = "<<j<<", mem_addr2:"<< mem_addr2<<", inload ="<<inload0[j]<<endl;
		//cout <<"j = "<<j<<", mem_addr2:"<< mem_addr2<<", inload ="<<inload1[j]<<endl;
		}

		My_region_mul: {
#pragma HLS PIPELINE II=10 rewind
		for(int k=0; k<10;k++) {
			result[k].BANK0  =  inload0 [k] * ( mask1? din0[i+k]  : din0 [0] );
			result[k].BANK1  =  inload1 [k] * ( mask1? din1[i+k]  : din1 [0] );
			result[k].BANK2  =  inload2 [k] * ( mask1? din2[i+k]  : din2 [0] );
			result[k].BANK3  =  inload3 [k] * ( mask1? din3[i+k]  : din3 [0] );
			result[k].BANK4  =  inload4 [k] * ( mask1? din4[i+k]  : din4 [0] );
			result[k].BANK5  =  inload5 [k] * ( mask1? din5[i+k]  : din5 [0] );
			result[k].BANK6  =  inload6 [k] * ( mask1? din6[i+k]  : din6 [0] );
			result[k].BANK7  =  inload7 [k] * ( mask1? din7[i+k]  : din7 [0] );
			result[k].BANK8  =  inload8 [k] * ( mask1? din8[i+k]  : din8 [0] );
			result[k].BANK9  =  inload9 [k] * ( mask1? din9[i+k]  : din9 [0] );
			result[k].BANK10 =  inload10[k] * ( mask1? din10[i+k] : din10[0] );
			result[k].BANK11 =  inload11[k] * ( mask1? din11[i+k] : din11[0] );
			result[k].BANK12 =  inload12[k] * ( mask1? din12[i+k] : din12[0] );
			result[k].BANK13 =  inload13[k] * ( mask1? din13[i+k] : din13[0] );
			result[k].BANK14 =  inload14[k] * ( mask1? din14[i+k] : din14[0] );
			result[k].BANK15 =  inload15[k] * ( mask1? din15[i+k] : din15[0] );
			//cout<< "mask1 "<<mask1<<endl;
			//cout<<"inside *, k= "<<k<<",lane0 in1= "<< inload0[k]<< ", in2 ="<< din0[0]<<endl;
			//cout<<"inside *, k= "<<k<<",lane1 in1= "<< inload1[k]<< ", in2 ="<< din1[0]<<endl;
		}
	}
}

loop_store:	for (int k = 0; k <10; k++) {
//#pragma HLS PIPELINE II=1
	if(i+k<vnum) {
		memcpy(mem_out_axi+mem_addr_dst, (const MEM_hw*)&result[k], sizeof(MEM_hw));
	 	mem_addr_dst = mem_addr_dst + stride3;
		}
	}
}
	if (mem_addr1 > RAM_SIZE + stride1 || mem_addr_dst > RAM_SIZE + stride3 || mem_addr2 > RAM_SIZE + stride2)
	{
		temp_status = MEM_OUT_BOUND;
	}else {
		temp_status = MUL_DONE;
	}
	  return temp_status;
}
