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
//#include "hls_math.h"
#include "math.h"

static int PC = 0;

int VPU_funcModel_v0p3(CMD *cmd_queue, MEM *mem) {

	  static float regfile[LANE][REGFILE_SIZE];
	  static bool mask[LANE];

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
	  PC++;

	  cmdDecode_v0p3(&cmd_queue[0], &op_type, &opcode, &silent_res, &mem_addr_src1, &mem_addr_src2, &mem_addr_dst,
			  &loopmax1, &total_n, &stride1, &stride2, &stride3, &immediate_scalor);
	  cout << "opcode funcModel: " << opcode << endl;
	  cout << "addr1: "<<mem_addr_src1<< ", addr2 = "<< mem_addr_src2 << endl;
	//  for (int i=0; i< LANE; i++){
	//  cout << "mem inside funcM begin: " << mem[0].BANK[i]<<","<< mem[2].BANK[i]<<","<< mem[3].BANK[i]<<","<< mem[5].BANK[i]<<","<<mem[16].BANK[i]<<","<< mem[18].BANK[i]<<endl;
	//  }

	  	cout << "func out finish loadcmd, opcode =  " << opcode << endl;
	  	cout << "func out finish loadcmd, mem_addr_src1 =  " << mem_addr_src1 << endl;
	  	cout << "func out finish loadcmd, mem_addr_src2 =  " << mem_addr_src2 << endl;
	  	cout << "func out finish loadcmd, mem_addr_dst =  " << mem_addr_dst << endl;
	  	cout << "func out finish loadcmd, loopmax1 =  " << loopmax1 << endl;
	    cout << "func out finish loadcmd, immediate_scalor: "<< immediate_scalor<<endl;

	  if (op_type == CFG_STD || op_type == CFG_LOOP) {
		  PC = 1;
		  return PC;
	  }

	  unsigned int mem_addr_temp = mem_addr_src1;
	  for (int i = 0; i < total_n*LANE; i++ ){
		int loopcount = i / LANE;
		int banknum = i % LANE;
		cout << "VPU func " << i << ",loopcount= " << loopcount << ",banknum =" << banknum << ":" << endl;

		switch(opcode) {
		case vvADD:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum] + mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum];
			cout << "VPU func result add: " << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum] << "+"
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << " end" << endl;
		    cout << "VPU func result: mem[16][banknum]= " << mem[16].BANK[banknum]<<endl;
		break;
		case vvSUB:
			mem[mem_addr_dst + stride3 *loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] - mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum];
			cout << "VPU func result sub" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "-"
					<< mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << " end" << endl;
		break;
		case vvMUL:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum] * mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum];
			cout << "VPU func result mul" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum] << "*"
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << " end" << endl;
		break;
		case vsADD:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] + mem[mem_addr_src1].BANK[0];
			cout << "VPU func result add" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "+"
					<< mem[mem_addr_src1].BANK[0] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vsSUB:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] - mem[mem_addr_src1].BANK[0];
			cout << "VPU func result sub" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "-"
					<< mem[mem_addr_src1].BANK[0] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vsMUL:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] * mem[mem_addr_src1].BANK[0];
			cout << "VPU func result mul" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "*"
					<< mem[mem_addr_src1].BANK[0] << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vsADDi:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] + immediate_scalor;
			cout << "VPU func result addi" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "+"
					<< immediate_scalor << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vsSUBi:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] - immediate_scalor;
			cout << "VPU func result subi" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "-"
					<< immediate_scalor << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vsMULi:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum]
			=  mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] * immediate_scalor;
			cout << "VPU func result muli" << mem_addr_dst + stride3 * loopcount << ","
					<< mem[mem_addr_src2 + stride2 * loopcount].BANK[banknum] << "*"
					<< immediate_scalor << "= "
					<< mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] << "end" << endl;
		break;
		case vMAX:
			if (loopcount == 0) {
				mem[mem_addr_dst].BANK[banknum] =  mem[mem_addr_src1].BANK[banknum];
			} else {
				mem[mem_addr_dst].BANK[banknum]
				= mem[mem_addr_dst].BANK[banknum] > mem[mem_addr_src1 + loopcount*stride1].BANK[banknum]?
				  mem[mem_addr_dst].BANK[banknum] : mem[mem_addr_src1 + loopcount*stride1].BANK[banknum];
			}
			//cout << "VPU func result max" << mem_addr_dst << "," << mem[mem_addr_dst].BANK[banknum] << " end" << endl;
		break;
		case vMIN:
			if (loopcount == 0) {
				mem[mem_addr_dst].BANK[banknum] =  mem[mem_addr_src1].BANK[banknum];
			} else {
				mem[mem_addr_dst].BANK[banknum]
				= mem[mem_addr_dst].BANK[banknum] < mem[mem_addr_src1 + loopcount*stride1].BANK[banknum]?
				  mem[mem_addr_dst].BANK[banknum] : mem[mem_addr_src1 + loopcount*stride1].BANK[banknum];
			}
			//cout << "VPU func result max" << mem_addr_dst << "," << mem[mem_addr_dst].BANK[banknum] << " end" << endl;
		break;
		case vMEAN:
		case vACCU:
			if (i >0 && i%LANE == 0){
				mem_addr_temp = mem_addr_temp + stride1;
				cout << "mem temp = " << mem_addr_temp <<endl;
				if (loopcount > 1 && loopcount%loopmax1 == 0) {
					mem_addr_temp = mem_addr_temp + stride2 -stride1;
					cout << "stride 2 mem temp = "<< mem_addr_temp <<endl;
				}
			}
			if (loopcount == 0) {
				mem[mem_addr_dst].BANK[banknum] =  mem[mem_addr_temp].BANK[banknum];
			} else {
				mem[mem_addr_dst].BANK[banknum] = mem[mem_addr_dst].BANK[banknum] + mem[mem_addr_temp].BANK[banknum];
			}
			if(opcode == vMEAN && (loopcount == total_n - 1)){
				cout<<"inside mean"<<endl;
				cout<<"before /"<<mem[mem_addr_dst].BANK[banknum]<<endl;
				mem[mem_addr_dst].BANK[banknum]
					= mem[mem_addr_dst].BANK[banknum] * immediate_scalor;
				cout<<"1/total n: "<<immediate_scalor<<", "<<mem[mem_addr_dst].BANK[banknum]<<endl;
			}

			cout << "VPU func result accu/mean bank: addr= " << mem_addr_dst << "," << mem[mem_addr_dst].BANK[banknum] << " end" << endl;

		break;
		/*case vTANH:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] =  tanh(mem[mem_addr_src1 + loopcount * stride1].BANK[banknum]);
			cout << "VPU func result exp addr: " << mem_addr_dst + loopcount << ", input= "
					<< mem[mem_addr_src1 + loopcount].BANK[banknum] << ", tan ="
					<< mem[mem_addr_dst + loopcount].BANK[banknum] << endl;
		break;
		case vSIN:
			mem[cmd_queue->mem_addr_dst + loopcount].BANK[banknum] =  sin(mem[cmd_queue->mem_addr_src1 + loopcount].BANK[banknum]);
			cout << "VPU func result sin" << cmd_queue->mem_addr_dst + loopcount << "," << mem[cmd_queue->mem_addr_src1 + loopcount].BANK[banknum] << "tan" << mem[cmd_queue->mem_addr_dst + loopcount].BANK[banknum] << "end" << endl;
		break;
		case vCOS:
			mem[cmd_queue->mem_addr_dst + loopcount].BANK[banknum] =  cos(mem[cmd_queue->mem_addr_src1 + loopcount].BANK[banknum]);
			cout << "VPU func result cos" << cmd_queue->mem_addr_dst + loopcount << "," << mem[cmd_queue->mem_addr_src1 + loopcount].BANK[banknum] << "tan" << mem[cmd_queue->mem_addr_dst + loopcount].BANK[banknum] << "end" << endl;
		break;*/
		case vEXP:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] =  exp(mem[mem_addr_src1 + loopcount * stride1].BANK[banknum]);
			cout << "VPU func result exp addr: " << mem_addr_dst + loopcount << ", input= "
					<< mem[mem_addr_src1 + loopcount].BANK[banknum] << ", exp ="
					<< mem[mem_addr_dst + loopcount].BANK[banknum] << endl;
		break;
		case sACCU:
			if (banknum == 0) {
				mem[mem_addr_dst + stride3 * loopcount].BANK[0] = mem[mem_addr_src1 + stride1 * loopcount].BANK[0];
			} else {
				if (banknum < loopmax1) {
				mem[mem_addr_dst + stride3 * loopcount].BANK[0] = mem[mem_addr_dst+ stride3 * loopcount].BANK[0] + mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum];
				}
			}
		break;
		case PADDING:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] = 0;
			cout << "VPU func result padding dst_addr: " << mem_addr_dst + loopcount<<endl;
		break;
		case RESHAPE:
			mem[mem_addr_dst + stride3 * loopcount].BANK[banknum] = mem[mem_addr_src1 + stride1 * loopcount].BANK[banknum];
			cout << "VPU func result padding dst_addr: " << mem_addr_dst + loopcount<<endl;
		break;
		default:
		      printf("Error! operator is not correct");
		}
	  }

	  for (int j= 0; j< MEM_COMP_RANGE; j++) {
		  for (int i=0; i< LANE; i++){
			  cout << "mem inside function model. Addr:"<<j<<", LANE:"<<i<<", mem data: "
				<< mem[j].BANK[i]<<", ";
	  }
		  cout<<endl;
	  }

  return PC;
}
