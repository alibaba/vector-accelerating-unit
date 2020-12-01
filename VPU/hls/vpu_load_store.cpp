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

void vpu_load_reg16_v0p3(int opcode, int vnum, int stride,
		  int mem_addr, MEM_hw *mem_axi,float imme_scalor,
          float din0 [REGFILE_SIZE],float din1 [REGFILE_SIZE],float din2 [REGFILE_SIZE],float din3 [REGFILE_SIZE],
		  float din4 [REGFILE_SIZE],float din5 [REGFILE_SIZE],float din6 [REGFILE_SIZE],float din7 [REGFILE_SIZE],
		  float din8 [REGFILE_SIZE],float din9 [REGFILE_SIZE],float din10[REGFILE_SIZE],float din11[REGFILE_SIZE],
		  float din12[REGFILE_SIZE],float din13[REGFILE_SIZE],float din14[REGFILE_SIZE],float din15[REGFILE_SIZE]){
	static MEM_hw buff;
	static float scalor_load;

	if(opcode == vsADD || opcode == vsSUB || opcode == vsMUL) {
		memcpy(&buff, (const MEM_hw*)(mem_axi + mem_addr), sizeof(MEM_hw));
		scalor_load = buff.BANK0;
	} else {
		scalor_load = imme_scalor;
	}
	if(opcode == vsSUB || opcode == vsSUBi) {
		scalor_load = -scalor_load;
	}

	if(opcode == vvADD || opcode == vvMUL) {
	loop_load_first: for (int i = 0; i<vnum; i++) {
#pragma HLS PIPELINE II=1
#pragma HLS LOOP_TRIPCOUNT min=1 max=32
		memcpy(&buff, (const MEM_hw*)(mem_axi + mem_addr), sizeof(MEM_hw));
		din0 [i] = buff.BANK0;
		din1 [i] = buff.BANK1;
		din2 [i] = buff.BANK2;
		din3 [i] = buff.BANK3;
		din4 [i] = buff.BANK4;
		din5 [i] = buff.BANK5;
		din6 [i] = buff.BANK6;
		din7 [i] = buff.BANK7;
		din8 [i] = buff.BANK8;
		din9 [i] = buff.BANK9;
		din10[i] = buff.BANK10;
		din11[i] = buff.BANK11;
		din12[i] = buff.BANK12;
		din13[i] = buff.BANK13;
		din14[i] = buff.BANK14;
		din15[i] = buff.BANK15;
	    mem_addr = mem_addr + stride;
		//cout << "in load first i="<<i<<", din0[i]="<<din0[i]<<endl;
		//cout << "i: "<<i<<", din0 = "<<din0[i] << endl;
		}
	} else if(opcode == vvSUB) {
		loop_loadsub_first: for (int i = 0; i<vnum; i++) {
#pragma HLS PIPELINE II=1
#pragma HLS LOOP_TRIPCOUNT min=1 max=32
			memcpy(&buff, (const MEM_hw*)(mem_axi + mem_addr), sizeof(MEM_hw));
			din0 [i] = - buff.BANK0;
			din1 [i] = - buff.BANK1;
			din2 [i] = - buff.BANK2;
			din3 [i] = - buff.BANK3;
			din4 [i] = - buff.BANK4;
			din5 [i] = - buff.BANK5;
			din6 [i] = - buff.BANK6;
			din7 [i] = - buff.BANK7;
			din8 [i] = - buff.BANK8;
			din9 [i] = - buff.BANK9;
			din10[i] = - buff.BANK10;
			din11[i] = - buff.BANK11;
			din12[i] = - buff.BANK12;
			din13[i] = - buff.BANK13;
			din14[i] = - buff.BANK14;
			din15[i] = - buff.BANK15;
		    mem_addr = mem_addr + stride;
			//cout << "in load first i="<<i<<", din0[i]="<<din0[i]<<endl;
			//cout << "i: "<<i<<", din0 = "<<din0[i] << endl;
			}
	}
	else {
		din0[0] =  scalor_load;
		din1[0] =  scalor_load;
		din2[0] =  scalor_load;
		din3[0] =  scalor_load;
		din4[0] =  scalor_load;
		din5[0] =  scalor_load;
		din6[0] =  scalor_load;
		din7[0] =  scalor_load;
		din8[0] =  scalor_load;
		din9[0] =  scalor_load;
		din10[0] = scalor_load;
		din11[0] = scalor_load;
		din12[0] = scalor_load;
		din13[0] = scalor_load;
		din14[0] = scalor_load;
		din15[0] = scalor_load;
	}
}
