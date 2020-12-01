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

#ifndef _VPU_PARAM_H_
#define _VPU_PARAM_H_

//constant definition for HW setting
#define LANE 16
#define CMD_QUEUE_DPETH 16
#define ACCU_BUFF_S 31 //load in1 depth for pipeline
#define FADD_LAT 11 //used in ACCU adder stage
#define ADDER_DEP 10 //used in alu vvADD/vvSUB depth to load in2
#define REGFILE_SIZE 32 //number of regfile per lane 2 input where in2 can do immediate and scalar
#define TREE_DEP 9 // used in ACCU adder tree depth
#define RAM_SIZE 67108864 //system addressing 0x300_0000 to 0x3FF_FFFF
#define BYTETOVECWORD_ADR 6 //system memory byte addressing, VPU HLS vector word addressing 512bit/8 = 64
#define MEM_COMP_RANGE 128

//constant for testing
//#define MEM_ADR 1024 // if 16 lane then 16 mem bank, with same address table
//#define S_REGFILE_SIZE 3 //scalar registers
//#define DST_REGFILE 0 //regfile to save result
//#define IN1_REGFILE 1 //first input vector
//#define IN2_REGFILE 2 //second input vector
//#define S_DST_REGFILE 0 //regfile to save result
//#define S_IN1_REGFILE 1 //first input vector
//#define S_IN2_REGFILE 2 //second input vector
//#define VLEN 32 //just for calculate loop and testing, should change back to vlen
//#define VNUM 2 //just for calculate loop and testing, should change back to vnum
//#define LOOPMAX 32//just for calculate loop and testing, should change back to vnum
//#define REMAIN 0 //just for calculate loop and testing, should change back to vnum
//#define ADD_LAT 16 //alu add latency
//#define FT float
//#define CMDQ_W 32*7
//#define RESQ_W 32*1
//#define MEM_W 32*32
//#define RAM_SIZE 1048576
//#define FLT_MAX 3402823466
//#define RAM_SIZE 3

#endif
