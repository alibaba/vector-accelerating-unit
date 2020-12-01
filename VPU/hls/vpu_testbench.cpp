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

#include <iostream>
#include <fstream>
#include <cstring>
#include "vpu_hw.h"
#include "math.h"
using namespace std;

#define MEM_ADR 131072
//To test system mem mapping
//#define MEM_ADR RAM_SIZE

//#define MEM_SIZE MEM_ADR * LANE
#define MEM_SIZE_hw MEM_ADR
#define TEST_NUM 32

int testCode(CMD *temp, int *mem_adr) {
  //[TODO]: add a sccript to generate testcode
  //CMD temp[TEST_NUM];
  int testID = 0;
  int resultID = 0;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 5;//loopmax1
  temp[testID].word2 = 5;//total_n
  temp[testID].scalor = 1.0/5;//immediate number

  testID++;

  resultID = 64;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;

  //To test system mem mapping
  /*int in1_addr = 0x03000000;
  int in2_addr = 0x03040000;
  int out_addr = in1_addr + 2048;
  temp[testID].word1 = in1_addr;//mem_addr_src1
  temp[testID].word2 = in2_addr;//mem_addr_src2
  temp[testID].word3 = out_addr;//mem_addr_dst
  */

  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 10;//loopmax1
  temp[testID].word2 = 10;//total_n
  temp[testID].scalor = 1.0/10;//immediate number

  testID++;

  resultID = 65;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;


  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst


  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 15;//loopmax1
  temp[testID].word2 = 15;//total_n
  temp[testID].scalor = 1.0/15;//immediate number

  testID++;

  resultID = 66;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;

  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 20;//loopmax1
  temp[testID].word2 = 20;//total_n
  temp[testID].scalor = 1.0/20;//immediate number

  testID++;

  resultID = 67;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;


  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 25;//loopmax1
  temp[testID].word2 = 25;//total_n
  temp[testID].scalor = 1.0/25;//immediate number

  testID++;

  resultID = 68;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;

  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst


  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvADD;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 30;//loopmax1
  temp[testID].word2 = 30;//total_n
  temp[testID].scalor = 1.0/30;//immediate number

  testID++;

  resultID = 69;
  cout << "mem results addr " << resultID << endl;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMEAN;
  temp[testID].word0(8,8) = 0;


  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst
/*

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vMIN;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vMIN;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 3;//loopmax1
  temp[testID].word2 = 3;//total_n
  temp[testID].scalor = 0.5;

  testID++;

  resultID = 33;
  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vMIN;
  temp[testID].word0(8,8) = 0;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[testID - 3]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID + 10*64];//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1;//loopmax1
  temp[testID].word2 = 1;//total_n
  temp[testID].scalor = 0.5;

  testID++;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  resultID = 32 + 10;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[0]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID + 16]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;
  //temp[testID].op_type = CFG_STD;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = vvMUL;
  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vvMUL;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 2*64;//stride2
  temp[testID].word3 = 1*64;//stride3
  testID++;
  //temp[testID].op_type = CFG_LOOP;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = 32;
  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vvMUL;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 3;//loopmax1
  temp[testID].word2 = 3;//total_n
  temp[testID].scalor = 0.5;
  //float x = 0.5;
  //temp[testID].word3 = *(int *)&x;;//immediate_scalor
  testID++;
  //temp[testID].op_type = EXC;
  //temp[testID].silent_res = 0;
  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vvMUL;
  temp[testID].word0(8,8) = 0;
  resultID = 32 + 10 + 1;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID + 10]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;

  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vsADDi;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 3*64;//stride3

  testID++;

  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 4;//loopmax1
  temp[testID].word2 = 4;//total_n
  temp[testID].scalor = -8.5;

  testID++;

  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vsADDi;
  temp[testID].word0(8,8) = 0;
  resultID = 32 + 10 + 1 + 3;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID + 10]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  /*
  testID++;
  //temp[testID].op_type = CFG_STD;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = vsMULi;
  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vsMULi;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 2*64;//stride2
  temp[testID].word3 = 4*64;//stride3
  testID++;
  //temp[testID].op_type = CFG_LOOP;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = 32;
  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 2;//loopmax1
  temp[testID].word2 = 2;//total_n
  temp[testID].scalor = 0.001;
  //float x = 0.5;
  //temp[testID].word3 = *(int *)&x;;//immediate_scalor
  testID++;
  //temp[testID].op_type = EXC;
  //temp[testID].silent_res = 0;
  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vACCU;
  temp[testID].word0(8,8) = 0;
  resultID = 32 + 10 + 1 + 3 + 6;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID + 10]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst

  testID++;
  //temp[testID].op_type = CFG_STD;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = vEXP;
  temp[testID].word0(1,0) = (int)CFG_STD;
  //temp[testID].word0(7,2) = (int)vEXP;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 1*64;//stride1
  temp[testID].word2 = 1*64;//stride2
  temp[testID].word3 = 1*64;//stride3
  testID++;
  //temp[testID].op_type = CFG_LOOP;
  //temp[testID].silent_res = 0;
  //temp[testID].opcode = 32;
  temp[testID].word0(1,0) = (int)CFG_LOOP;
  //temp[testID].word0(7,2) = (int)vEXP;
  temp[testID].word0(8,8) = 0;
  temp[testID].word1 = 5;//loopmax1
  temp[testID].word2 = 5;//total_n
  temp[testID].scalor = -8.5;
  //float x = 0.5;
  //temp[testID].word3 = *(int *)&x;;//immediate_scalor
  testID++;
  //temp[testID].op_type = EXC;
  //temp[testID].silent_res = 0;
  temp[testID].word0(1,0) = (int)EXC;
  temp[testID].word0(7,2) = (int)vsMULi;
  temp[testID].word0(8,8) = 0;
  //temp[testID].opcode = 33;
  resultID = 47;
  cout << "mem results addr " << resultID << endl;
  temp[testID].word1 = mem_adr[testID]*64;//mem_addr_src1
  temp[testID].word2 = mem_adr[testID]*64;//mem_addr_src2
  temp[testID].word3 = mem_adr[resultID]*64;//mem_addr_dst
*/
  cout << "test cmd generation done" << endl;
  return testID;
}


int main () {
  MEM *mem;
  MEM_hw *mem_hw, *mem_out_hw;
  MEM *golden_r;
  CMD *cmd;

  int *mem_addr;
  int *response;

  mem = new MEM[MEM_ADR];
  memset(mem, 0, sizeof(MEM) * MEM_ADR);

  mem_hw = new MEM_hw[MEM_SIZE_hw];
  memset(mem_hw, 0, sizeof(MEM_hw) * MEM_SIZE_hw);

  mem_out_hw = new MEM_hw[MEM_SIZE_hw];
  memset(mem_out_hw, 0, sizeof(MEM_hw) * MEM_SIZE_hw);

  golden_r = new MEM[MEM_ADR/2];
  memset(golden_r, 0, sizeof(MEM) * MEM_ADR/2);

  cmd = new CMD[TEST_NUM];
  memset(cmd, 0, sizeof(CMD)*TEST_NUM);

  response = new int[TEST_NUM];
  memset(response, 0, TEST_NUM);

  mem_addr = new int[MEM_ADR];
  memset(mem_addr, 0, MEM_ADR);
  cout << "Done malloc" << endl;

  // input pre-store in first half of the memory, read in test randomly
  ifstream fpmem("mem.dat");
  if(fpmem.is_open() && 0) {
    for(int i = 0; i < MEM_ADR/2; i++) {
      for(int j = 0; j < LANE; j++) {
    	  fpmem >> mem[i].BANK[j];
      }
    }
    fpmem.close();
    cout << "Read existing memory content." << endl;
  }
  else {
    ofstream fpmem("mem.dat");
    for(int i = 0; i < MEM_COMP_RANGE/2; i++) {
   // for(int i = 0; i < MEM_ADR/2; i++) {
      for(int j = 0; j < LANE; j++) {
        //mem[i].BANK[j] = rand();
    	mem[i].BANK[j] = (i + j)*0.1;
    	if(j==0){
    		mem_hw[i].BANK0 = (i + j)*0.1;
    	}
    	else if(j==1){
    		mem_hw[i].BANK1 = (i + j)*0.1;
    	}
    	else if(j==2){
    		mem_hw[i].BANK2 = (i + j)*0.1;
    	}
    	else if(j==3){
    		mem_hw[i].BANK3 = (i + j)*0.1;
    	}
    	else if(j==4){
    		mem_hw[i].BANK4 = (i + j)*0.1;
    	}
    	else if(j==5){
    		mem_hw[i].BANK5 = (i + j)*0.1;
    	}
    	else if(j==6){
    		mem_hw[i].BANK6 = (i + j)*0.1;
    	}
    	else if(j==7){
    		mem_hw[i].BANK7 = (i + j)*0.1;
    	}
    	else if(j==8){
    		mem_hw[i].BANK8 = (i + j)*0.1;
    	}
    	else if(j==9){
    		mem_hw[i].BANK9 = (i + j)*0.1;
    	}
    	else if(j==10){
    		mem_hw[i].BANK10 = (i + j)*0.1;
    	}
    	else if(j==11){
    		mem_hw[i].BANK11 = (i + j)*0.1;
    	}
    	else if(j==12){
    		mem_hw[i].BANK12 = (i + j)*0.1;
    	}
    	else if(j==13){
    		mem_hw[i].BANK13 = (i + j)*0.1;
    	}
    	else if(j==14){
    		mem_hw[i].BANK14 = (i + j)*0.1;
    	}
    	else if(j==15){
    		mem_hw[i].BANK15 = (i + j)*0.1;
    	}
    	//mem_out[i].BANK[j] = i+j;
        fpmem << mem[i].BANK[j] << endl;
      }
    }
    fpmem.close();
    cout << "Create new mem content." << endl;
  }

  for (int j= 0; j< MEM_COMP_RANGE; j++) {
	  for (int i=0; i< LANE; i++){
		  cout << "mem post create. Addr:"<<j<<", LANE:"<<i<<", mem data: "
			<< mem[j].BANK[i]<<", ";
  }
	  cout<<endl;
  }

  for (int j=0; j< MEM_COMP_RANGE; j++) {
	  cout << "mem_hw post create. Addr:"<<j<<", mem_hw data"
			  <<mem_hw[j].BANK0<<", "
			  <<mem_hw[j].BANK1<<", "
			  <<mem_hw[j].BANK2<<", "
			  <<mem_hw[j].BANK3<<", "
			  <<mem_hw[j].BANK4<<", "
			  <<mem_hw[j].BANK5<<", "
			  <<mem_hw[j].BANK6<<", "
			  <<mem_hw[j].BANK7<<", "
			  <<mem_hw[j].BANK8<<", "
			  <<mem_hw[j].BANK9<<", "
			  <<mem_hw[j].BANK10<<", "
			  <<mem_hw[j].BANK11<<", "
			  <<mem_hw[j].BANK12<<", "
			  <<mem_hw[j].BANK13<<", "
			  <<mem_hw[j].BANK14<<", "
			  <<mem_hw[j].BANK15<<", "

			  <<endl;
  }


  // input random mem_addr
  ifstream fpaddr("mem_addr.dat");
  if(fpaddr.is_open() && 0) {
    for(int i = 0; i < TEST_NUM; i++) {
    	fpaddr >> mem_addr[i];
    }
    fpaddr.close();
    cout << "Read existing memory addr." << endl;
  }
  else {
    ofstream fpaddr("mem_addr.dat");
    for(int i = 0; i <  MEM_ADR; i++) {
      //mem_addr[i] = rand() % (MEM_SIZE/2);
      mem_addr[i] = i;
      fpaddr << mem_addr[i] << endl;
    }
    fpaddr.close();
    cout << "Create new mem_addr." << endl;
  }

  cout << "======   Generating golden model ==========" << endl;
  int cmd_num = testCode(cmd, mem_addr);
  cout<< "total test number: "<<cmd_num<<endl;
  // for (int i=0; i< LANE; i++){
  // cout << "mem right before funcM: " << mem[0].BANK[i]<<","<< mem[1].BANK[i]<<","<< mem[2].BANK[i]<<","<< mem[3].BANK[i]<<","<<mem[16].BANK[i]<<","<< mem[17].BANK[i]<<endl;
  // }
  // function model results
  for(int i = 0; i < cmd_num + 1; i++) {
	cout<< "function model loop: "<<i<<endl;
    VPU_funcModel_v0p3(&cmd[i], mem);
  }

  for(int i = MEM_COMP_RANGE/2; i < MEM_COMP_RANGE; i++) {
    for(int j = 0; j < LANE; j++) {
      //ofpp << mem[i].BANK[j] << endl;
      golden_r[i-MEM_COMP_RANGE/2].BANK[j] = mem[i].BANK[j];
      cout << "gold addr = " << i-MEM_COMP_RANGE/2 <<",bank =" << j << ","
    		  << "result = " << golden_r[i-MEM_COMP_RANGE/2].BANK[j] << ", ";
      mem[i].BANK[j] = 0.0;
    }
    cout<<endl;
  }

 /* for (int j= 0; j< MEM_ADR; j++) {
	  for (int i=0; i< LANE; i++){
		  cout << "mem post golden model. Addr:"<<j<<", LANE:"<<i<<", mem data: "
			<< mem[j].BANK[i]<<endl;
  }
  }*/


  cout << "======   Generating hw test ==========" << endl;
  // hw results
  for(int i = 0; i < cmd_num + 1; i++) {
	cout << "CMD id: " << i << " input hw." << endl;
    vpu_hw(&cmd[i],mem_hw, mem_out_hw, &response[i]);
    cout << "CMD " << i << " hw done." << endl;
  }

  for (int j=0; j<cmd_num + 1; j++){
	  cout<< "hw response queue i: "<<j<<", res:"<<response[j]<<endl;
  }

  for (int j=0; j< MEM_COMP_RANGE; j++) {
	  cout << "mem_hw post hw test. Addr:"<<j<<", mem_hw data  "
			  <<mem_out_hw[j].BANK0<<", "
			  <<mem_out_hw[j].BANK1<<", "
			  <<mem_out_hw[j].BANK2<<", "
			  <<mem_out_hw[j].BANK3<<", "
			  <<mem_out_hw[j].BANK4<<", "
			  <<mem_out_hw[j].BANK5<<", "
			  <<mem_out_hw[j].BANK6<<", "
			  <<mem_out_hw[j].BANK7<<", "
			  <<mem_out_hw[j].BANK8<<", "
			  <<mem_out_hw[j].BANK9<<", "
			  <<mem_out_hw[j].BANK10<<", "
			  <<mem_out_hw[j].BANK11<<", "
			  <<mem_out_hw[j].BANK12<<", "
			  <<mem_out_hw[j].BANK13<<", "
			  <<mem_out_hw[j].BANK14<<", "
			  <<mem_out_hw[j].BANK15<<", "
			  <<endl;
  }

  cout << "======   comparing test ==========" << endl;
	// Compare the results file with the golden results
	int retval = 0;
	for(int i = MEM_COMP_RANGE/2; i < MEM_COMP_RANGE; i++) {
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[0] - mem_out_hw[i].BANK0) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 0 << ": " << mem_out_hw[i].BANK0 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[0] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[0] - mem_out_hw[i].BANK0<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[1] - mem_out_hw[i].BANK1) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 2 << ": " << mem_out_hw[i].BANK1 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[1] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[1] - mem_out_hw[i].BANK1<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[2] - mem_out_hw[i].BANK2) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 4 << ": " << mem_out_hw[i].BANK2 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[2] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[2] - mem_out_hw[i].BANK2<<endl;
			    }
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[3] - mem_out_hw[i].BANK3) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 8 << ": " << mem_out_hw[i].BANK3 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[3] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[3] - mem_out_hw[i].BANK3<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[4] - mem_out_hw[i].BANK4) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 0 << ": " << mem_out_hw[i].BANK4 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[0] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[4] - mem_out_hw[i].BANK4<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[5] - mem_out_hw[i].BANK5) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 2 << ": " << mem_out_hw[i].BANK5 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[1] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[5] - mem_out_hw[i].BANK5<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[6] - mem_out_hw[i].BANK6) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 4 << ": " << mem_out_hw[i].BANK6 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[2] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[6] - mem_out_hw[i].BANK6<<endl;
			    }
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[7] - mem_out_hw[i].BANK7) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 8 << ": " << mem_out_hw[i].BANK7 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[3] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[7] - mem_out_hw[i].BANK7<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[8] - mem_out_hw[i].BANK8) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 0 << ": " << mem_out_hw[i].BANK8 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[0] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[8] - mem_out_hw[i].BANK8<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[9] - mem_out_hw[i].BANK9) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 2 << ": " << mem_out_hw[i].BANK9 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[1] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[9] - mem_out_hw[i].BANK9<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[10] - mem_out_hw[i].BANK10) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 4 << ": " << mem_out_hw[i].BANK10 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[2] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[10] - mem_out_hw[i].BANK10<<endl;
			    }
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[11] - mem_out_hw[i].BANK11) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 8 << ": " << mem_out_hw[i].BANK11 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[3] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[11] - mem_out_hw[i].BANK11<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[12] - mem_out_hw[i].BANK12) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 0 << ": " << mem_out_hw[i].BANK12 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[0] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[12] - mem_out_hw[i].BANK12<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[13] - mem_out_hw[i].BANK13) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 2 << ": " << mem_out_hw[i].BANK13 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[1] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[13] - mem_out_hw[i].BANK13<<endl;
		}
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[14] - mem_out_hw[i].BANK14) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 4 << ": " << mem_out_hw[i].BANK14 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[2] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[14] - mem_out_hw[i].BANK14<<endl;
			    }
		if(fabs(golden_r[i-MEM_COMP_RANGE/2].BANK[15] - mem_out_hw[i].BANK15) > 1e-5) {
			    	retval++;
			    	cout << i << ", " << 8 << ": " << mem_out_hw[i].BANK15 << " is not " << golden_r[i-MEM_COMP_RANGE/2].BANK[3] << endl;
			    	cout <<"diff: "<<golden_r[i-MEM_COMP_RANGE/2].BANK[15] - mem_out_hw[i].BANK15<<endl;
		}
	}
	if (retval != 0) {
		printf("Test failed  !!!\n");
		retval=1;
	} else {
		printf("Test passed !\n");
  }

  // Return 0 if the test passes
  return retval;

  }
