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

void alu_tree_v0p3 (float *sum_p0, float *sum_p1, float *sum_p2, float *sum_p3,
				  float *sum_p4, float *sum_p5, float *sum_p6, float *sum_p7,
				  float *sum_p8, float *sum_p9, float *sum_p10, float *sum_p11,
				  float *sum_p12, float *sum_p13, float *sum_p14, float *sum_p15,
				  float *sum0, float *sum1, float *sum2, float *sum3,
				  float *sum4, float *sum5, float *sum6, float *sum7,
				  float *sum8, float *sum9, float *sum10, float *sum11,
				  float *sum12, float *sum13, float *sum14, float *sum15,
				  MEM_hw *result) {

	loop_init: for(int i=0;i<TREE_DEP-1;i++) {
#pragma HLS UNROLL
					sum0[i] = 0;
					sum1[i] = 0;
					sum2[i] = 0;
					sum3[i] = 0;
					sum4[i] = 0;
					sum5[i] = 0;
					sum6[i] = 0;
					sum7[i] = 0;
					sum8[i] = 0;
					sum9[i] = 0;
					sum10[i] = 0;
					sum11[i] = 0;
					sum12[i] = 0;
					sum13[i] = 0;
					sum14[i] = 0;
					sum15[i] = 0;
				}

	My_region_tree_1: {
	loop_sum_l0: for (int k=0; k<TREE_DEP; k = k+2)
	 {
#pragma HLS PIPELINE
#pragma HLS UNROLL
		sum0[k/2] = sum_p0[k]+sum_p0[k+1];
		sum1[k/2] = sum_p1[k]+sum_p1[k+1];
		sum2[k/2] = sum_p2[k]+sum_p2[k+1];
		sum3[k/2] = sum_p3[k]+sum_p3[k+1];
		sum4[k/2] = sum_p4[k]+sum_p4[k+1];
		sum5[k/2] = sum_p5[k]+sum_p5[k+1];
		sum6[k/2] = sum_p6[k]+sum_p6[k+1];
		sum7[k/2] = sum_p7[k]+sum_p7[k+1];
		sum8[k/2] = sum_p8[k]+sum_p8[k+1];
		sum9[k/2] = sum_p9[k]+sum_p9[k+1];
		sum10[k/2] = sum_p10[k]+sum_p10[k+1];
		sum11[k/2] = sum_p11[k]+sum_p11[k+1];
		sum12[k/2] = sum_p12[k]+sum_p12[k+1];
		sum13[k/2] = sum_p13[k]+sum_p13[k+1];
		sum14[k/2] = sum_p14[k]+sum_p14[k+1];
		sum15[k/2] = sum_p15[k]+sum_p15[k+1];
	 }

	 loop_sum_l1: for (int k=0; k<TREE_DEP/2-1; k = k+2)
	 {
#pragma HLS PIPELINE
#pragma HLS UNROLL
		 sum0[5+k/2] = sum0[k]+sum0[k+1];
		 sum1[5+k/2] = sum1[k]+sum1[k+1];
		 sum2[5+k/2] = sum2[k]+sum2[k+1];
		 sum3[5+k/2] = sum3[k]+sum3[k+1];
	 	 sum4[5+k/2] = sum4[k]+sum4[k+1];
	 	 sum5[5+k/2] = sum5[k]+sum5[k+1];
	 	 sum6[5+k/2] = sum6[k]+sum6[k+1];
	 	 sum7[5+k/2] = sum7[k]+sum7[k+1];
	 	 sum8[5+k/2] = sum8[k]+sum8[k+1];
	 	 sum9[5+k/2] = sum9[k]+sum9[k+1];
	 	 sum10[5+k/2] = sum10[k]+sum10[k+1];
	 	 sum11[5+k/2] = sum11[k]+sum11[k+1];
	 	 sum12[5+k/2] = sum12[k]+sum12[k+1];
	 	 sum13[5+k/2] = sum13[k]+sum13[k+1];
	 	 sum14[5+k/2] = sum14[k]+sum14[k+1];
	 	 sum15[5+k/2] = sum15[k]+sum15[k+1];
	 }

	 sum0[7] = sum0[4]+sum_p0[10];
	 sum1[7] = sum1[4]+sum_p1[10];
	 sum2[7] = sum2[4]+sum_p2[10];
	 sum3[7] = sum3[4]+sum_p3[10];
	 sum4[7] = sum4[4]+sum_p4[10];
	 sum5[7] = sum5[4]+sum_p5[10];
	 sum6[7] = sum6[4]+sum_p6[10];
	 sum7[7] = sum7[4]+sum_p7[10];
	 sum8[7] = sum8[4]+sum_p8[10];
	 sum9[7] = sum9[4]+sum_p9[10];
	 sum10[7] = sum10[4]+sum_p10[10];
	 sum11[7] = sum11[4]+sum_p11[10];
	 sum12[7] = sum12[4]+sum_p12[10];
	 sum13[7] = sum13[4]+sum_p13[10];
	 sum14[7] = sum14[4]+sum_p14[10];
	 sum15[7] = sum15[4]+sum_p15[10];

	 sum0[8] = sum0[5]+sum0[6];
	 sum1[8] = sum1[5]+sum1[6];
	 sum2[8] = sum2[5]+sum2[6];
	 sum3[8] = sum3[5]+sum3[6];
	 sum4[8] = sum4[5]+sum4[6];
	 sum5[8] = sum5[5]+sum5[6];
	 sum6[8] = sum6[5]+sum6[6];
	 sum7[8] = sum7[5]+sum7[6];
	 sum8[8] = sum8[5]+sum8[6];
	 sum9[8] = sum9[5]+sum9[6];
	 sum10[8] = sum10[5]+sum10[6];
	 sum11[8] = sum11[5]+sum11[6];
	 sum12[8] = sum12[5]+sum12[6];
	 sum13[8] = sum13[5]+sum13[6];
	 sum14[8] = sum14[5]+sum14[6];
	 sum15[8] = sum15[5]+sum15[6];

	 result->BANK0 = sum0[7]+sum0[8];
	 result->BANK1  = sum1[7]+sum1[8];
	 result->BANK2  = sum2[7]+sum2[8];
	 result->BANK3  = sum3[7]+sum3[8];
	 result->BANK4  = sum4[7]+sum4[8];
	 result->BANK5  = sum5[7]+sum5[8];
	 result->BANK6  = sum6[7]+sum6[8];
	 result->BANK7  = sum7[7]+sum7[8];
	 result->BANK8  = sum8[7]+sum8[8];
	 result->BANK9  = sum9[7]+sum9[8];
	 result->BANK10  = sum10[7]+sum10[8];
	 result->BANK11  = sum11[7]+sum11[8];
	 result->BANK12  = sum12[7]+sum12[8];
	 result->BANK13  = sum13[7]+sum13[8];
	 result->BANK14  = sum14[7]+sum14[8];
	 result->BANK15  = sum15[7]+sum15[8];
	}
	//cout<<"inside tree: sum0[9]"<<sum0[8]<<endl;
}


float adder_tree_16to1_v0p3 (MEM_hw buff) {
	static float sum_l0[8], sum_l1[4], sum_l2[2], sum_l3;

//initial
	for (int i = 0; i < 8 ; i++)
	{
		sum_l0[i] = 0;
	}
	for (int i = 0; i < 4 ; i++)
	{
		sum_l1[i] = 0;
	}
	for (int i = 0; i < 2 ; i++)
	{
		sum_l2[i] = 0;
	}
	sum_l3 = 0;

// adder level 0
	sum_l0[0 ] = buff.BANK0   + buff.BANK1 ;
	sum_l0[1 ] = buff.BANK2   + buff.BANK3 ;
	sum_l0[2 ] = buff.BANK4   + buff.BANK5 ;
	sum_l0[3 ] = buff.BANK6   + buff.BANK7 ;
	sum_l0[4 ] = buff.BANK8   + buff.BANK9 ;
	sum_l0[5 ] = buff.BANK10  + buff.BANK11;
	sum_l0[6 ] = buff.BANK12  + buff.BANK13;
	sum_l0[7 ] = buff.BANK14  + buff.BANK15;

// adder level 1
	sum_l1[0] = sum_l0[0 ] + sum_l0[1 ];
	sum_l1[1] = sum_l0[2 ] + sum_l0[3 ];
	sum_l1[2] = sum_l0[4 ] + sum_l0[5 ];
	sum_l1[3] = sum_l0[6 ] + sum_l0[7 ];

// adder level 2
    sum_l2[0] = sum_l1[0 ] + sum_l1[1 ];
	sum_l2[1] = sum_l1[2 ] + sum_l1[3 ];

// adder level 3
	sum_l3 = sum_l2[0 ] + sum_l2[1 ];

	return sum_l3;
}
