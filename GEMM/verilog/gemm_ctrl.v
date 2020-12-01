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

module gemm_ctrl #
(
  parameter BLOCK_SIZE_WIDTH = 6,
  parameter SYS_ARRAY_SIZE = 32,
  parameter SYS_ARRAY_NUM = 1,
	parameter MAC_LATENCY = 3,
	parameter ACC_LATENCY = 2
)(
  input  wire   clk,
  input  wire   reset,
  input  wire[BLOCK_SIZE_WIDTH-1:0] block_size,
  input  wire   start_op,
  output reg    wt_sel,
  output reg    acc_en,
  output reg    acc_oen,
  output reg    done,
  output reg    r_depend,
  output wire   w_depend,
  output reg    output_valid,
  output wire   load_wt,
  output wire   load_act,
  output reg    acc_clear_en	//clear acc buffer after one successful gemm computation
);

  localparam N_ARRAY = $clog2(SYS_ARRAY_SIZE);//6
  //define wire/reg varibes
  reg [18:0] total_cnt,ws_cnt;
  wire [18:0] num, num2;
  reg total_flg,ws_flg,start_op_dly1,done_dly1;
  wire wc_cnt_less_32,wc_cnt_less_64,acc_en_less_kn,acc_oen_less_kn, acc_en_begin, output_en;
  reg acc_oen_dly1,output_valid_dly1,total_flg_dly1,total_flg_dly2;

  wire  [13:0] num_tmp;
  wire  [13:0] num_tmp2;

  reg [BLOCK_SIZE_WIDTH-1:0] k_blocks;
  `DFF_EN_RST(k_blocks, block_size, start_op, reset, clk)

  assign num_tmp = {{(19-BLOCK_SIZE_WIDTH){1'b0}},k_blocks}+'d1+(MAC_LATENCY); 
  assign num_tmp2 = {{(19-BLOCK_SIZE_WIDTH){1'b0}},k_blocks}+'d3+(MAC_LATENCY); 
  assign num = {num_tmp, {N_ARRAY{1'b0}}};
  assign num2 = {num_tmp2, {N_ARRAY{1'b0}}};

  assign wc_cnt_less_32 = (ws_cnt <= (SYS_ARRAY_SIZE-1'b1));
  assign wc_cnt_less_64 = (ws_cnt < ({SYS_ARRAY_SIZE,1'b0}-1'b1));
  assign acc_en_less_kn = (total_cnt < (num2+(SYS_ARRAY_SIZE-1)+(ACC_LATENCY)));
  assign acc_en_begin = (total_cnt>=({SYS_ARRAY_SIZE,1'b0}+SYS_ARRAY_SIZE*MAC_LATENCY+SYS_ARRAY_NUM-1'b1+1'b1));
  assign acc_oen_more_kn = (total_cnt >= (num + 'd3+SYS_ARRAY_NUM-1+ACC_LATENCY)); 
  assign acc_oen_less_kn = (total_cnt<=({(num_tmp+1),{N_ARRAY{1'b0}}}+'d2+SYS_ARRAY_NUM-1+ACC_LATENCY));
  assign cnt_last = (total_cnt<=(num2+2'd2+SYS_ARRAY_NUM-1+ACC_LATENCY));
  assign output_en = (total_cnt==({(num_tmp+1),{N_ARRAY{1'b0}}}+2'd3+SYS_ARRAY_NUM-1+ACC_LATENCY));

  assign load_wt = ((total_cnt > 0) && (total_cnt <= {k_blocks,{N_ARRAY{1'b0}}}));
  assign load_act = ((total_cnt > SYS_ARRAY_SIZE) && (total_cnt <= {{{4'b0,k_blocks}+'d1},{N_ARRAY{1'b0}}}));

  always @(posedge clk) begin
    if(!reset)
      total_flg <= 1'b0;
    else if(start_op)
      total_flg <= 1'b1;
    else if(!cnt_last)
      total_flg <= 1'b0;
  end

  //generate start flag
  always @(posedge clk) begin
    if(!reset)
      done_dly1 <= 1'b0;
    else
      done_dly1 <= done;
  end

  always @(posedge clk) begin
    if(!reset)
      ws_flg <= 1'b0;
    else if(start_op)
      ws_flg <= 1'b1;
    else if(done&(!done_dly1)) // (!wc_cnt_less_64)
      ws_flg <= 1'b0;
  end

  // the total_cnt is used by all output signals but ws_sel
  always @(posedge clk) begin
    if(!reset)
      total_cnt <= 19'd0;
    else if((start_op | total_flg) & cnt_last)
      total_cnt <= total_cnt + 1'b1;
    else if(!cnt_last)
      total_cnt <= 19'd0;
  end

  //the ws_cnt is used  only by  ws_sel
  always @(posedge clk) begin
    if(!reset)
      ws_cnt <= 19'd0;
    else if((start_op | ws_flg) & wc_cnt_less_64)
      ws_cnt <= ws_cnt + 1'b1;
    else //if(!wc_cnt_less_64)
      ws_cnt <= 19'd0;
  end

  //generate wt_sel
  always @(posedge clk) begin
    if(!reset)
      wt_sel <= 1'b0;
    else if(wc_cnt_less_32 & (ws_flg | start_op))
      wt_sel <= 1'b1;
    else if(wc_cnt_less_64 & ws_flg)
      wt_sel <= 1'b0;
  end

  //generate acc_en
  always @(posedge clk) begin
    if(!reset)
      acc_en <= 1'b0;
    else if(acc_en_begin & acc_en_less_kn & (total_flg | start_op))
      acc_en <= 1'b1;
    else
      acc_en <= 1'b0;
  end

  //generate acc_oen
  always @(posedge clk) begin
    if(!reset)
      acc_oen <= 1'b0;
    else if(acc_oen_more_kn & acc_oen_less_kn & (total_flg | start_op))
      acc_oen <= 1'b1;
    else
      acc_oen <= 1'b0;
  end

  always @(posedge clk) begin
    if(!reset) begin
      acc_oen_dly1      <= 1'b0;
      output_valid_dly1 <= 1'b0;
      total_flg_dly1    <= 1'b0;
      total_flg_dly2    <= 1'b0;
    end else begin
      acc_oen_dly1      <= acc_oen;
      output_valid_dly1 <= output_valid;
      total_flg_dly1    <= total_flg;
      total_flg_dly2    <= total_flg_dly1;
    end
  end

  wire acc_clear_en_wire;
  assign acc_clear_en_wire = total_flg_dly1 | total_flg_dly2;
  `DFF_RST(acc_clear_en, acc_clear_en_wire, reset, clk)

  //generate r_depend
  always @(posedge clk) begin
    if(!reset)
      r_depend <= 1'b0;
    else if(start_op)
      r_depend <= 1'b1;
    else if((total_cnt >= (num - 1'b1)) & (total_flg | start_op))
      r_depend <= 1'b0;
  end

  //generate output_valid
  always @(posedge clk) begin
    if(!reset)
      output_valid <= 1'b0;
    else if(acc_oen_more_kn & output_en & (total_flg | start_op))
      output_valid <= 1'b1;
    else if(!cnt_last)
      output_valid <= 1'b0;
  end

  //generate w_depend
  assign w_depend = output_valid;

  //generate done
  always @(posedge clk) begin
    if(!reset)
      done <= 1'b1;
    else if(start_op)
      done <= 1'b0;
    else if(total_flg_dly1 & (!output_valid) & output_valid_dly1)
      done <= 1'b1;
  end

endmodule
