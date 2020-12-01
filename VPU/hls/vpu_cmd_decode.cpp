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

RES_STATUS cmdDecode_v0p3(CMD *cmd, int *op_type, int *opcode, bool *silent_res, int *mem_addr_src1, int *mem_addr_src2,
		int *mem_addr_dst, int *loopmax1, int *total_n,
		int *stride1, int *stride2, int*stride3, float *immediate_scalor){
//#pragma HLS PIPELINE II=1
	RES_STATUS temp_status = NORMAL;
	*op_type = int(cmd->word0(1,0));
	*silent_res = bool(cmd->word0(8,8));
	//cout<<"op_type = "<<*op_type<<endl;
	//cout<<"silent_res = "<<*silent_res<<endl;
	if (*op_type == CFG_STD) {
	*stride1 = int(cmd->word1) >> BYTETOVECWORD_ADR;
	*stride2 = int(cmd->word2) >> BYTETOVECWORD_ADR;
	*stride3 = int(cmd->word3) >> BYTETOVECWORD_ADR;
	//cout << "in decode cfg_std."<<endl;
	//cout << "stride1 = "<<stride1<<endl;
	//cout << "stride2 = "<<stride2<<endl;
	//cout << "stride3 = "<<stride3<<endl;
	}
	else if (*op_type == CFG_LOOP){
	*loopmax1 = int(cmd->word1);
	*total_n  = int(cmd->word2);
	*immediate_scalor = cmd ->scalor;
	//cout<<"in decode cfg_loop."<<endl;
	}
	else if (*op_type == EXC) {
	*opcode = int(cmd->word0(7,2));
	*mem_addr_src1 = cmd->word1 >> BYTETOVECWORD_ADR;
	*mem_addr_src2 = cmd->word2 >> BYTETOVECWORD_ADR;
	*mem_addr_dst  = cmd->word3 >> BYTETOVECWORD_ADR;
 	if (*mem_addr_src1 > RAM_SIZE || *mem_addr_src2 > RAM_SIZE || *mem_addr_dst > RAM_SIZE)
 	{
 		temp_status = MEM_OUT_BOUND;
 		return temp_status;
 	}
	//cout<<"in decode exc."<<endl;
	}
	else {
		temp_status = NO_OPTYPE;
		//cout<<"cmd op_type wrong."<<endl;
	}
	return temp_status;
}

