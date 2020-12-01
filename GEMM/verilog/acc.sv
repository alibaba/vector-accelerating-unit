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

// ----------------------------------------------------------------------
//  Accumulator
// ----------------------------------------------------------------------

`include "shared_library.sv"

module ACC # (
  parameter MAC_PRECISION    	= 4,  // 1: INT8; 2: FP16; 3: BF16; 4: FP32
  parameter SYS_ARRAY_HEIGHT 	= 8,  // Systolic Array Height = 32            
  parameter SYS_ARRAY_WIDTH  	= 8,  // Systolic Array Width  = 32
  parameter ACT_WIDTH        	= 8,  // Activation Data Width
  parameter ACC_WIDTH        	= 32, // Accumlation Data Width
  parameter ACC_LATENCY 	    = 2,
  parameter SYS_ARRAY_NUM 	  = 2
) (
  input clk,
  input reset,
  input acc_en,
  input acc_data_oen,  //Accumulation Data Output Enable
  input acc_clear_en,
  input bias_load_en,
  input relu_en,
  input acc_buffer_sel,
  input logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] pacc_data_in,   // Partial Accumulation Data
  input signed [SYS_ARRAY_NUM*SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] bias_data_in,
  input logic write_back, //write back result and clear buffer
  input logic clear_buffer,  //clear accumulator registers
  input done,
  output logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] fact_data_out  // Full Activation Data Out
);

  genvar gi, gj;

  localparam ACC_BUF_ADDR_WIDTH = $clog2(SYS_ARRAY_HEIGHT);
  `ifdef SYS_ARRAY_NUM_2
  logic signed [SYS_ARRAY_HEIGHT-1:0][SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] acc_buffer_0;
  `endif
  logic signed [SYS_ARRAY_HEIGHT-1:0][SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] acc_buffer_1;	   // store 16x32 partual result
  logic signed [SYS_ARRAY_HEIGHT-1:0][SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] acc_buffer_din;
  logic [SYS_ARRAY_HEIGHT-1:0]                                            acc_buffer_wren;
  logic [SYS_ARRAY_HEIGHT-1:0]                                            acc_buffer_wren_ff;
  logic [SYS_ARRAY_HEIGHT-1:0][SYS_ARRAY_WIDTH-1:0]                       acc_buffer_rden;
  logic [SYS_ARRAY_WIDTH -1:0]                                            acc_data_col_oen;  
  logic [SYS_ARRAY_WIDTH -2:0]                                            acc_data_col_en;

  logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]  facc_data_out_din;
  logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0]  facc_data_out;

  logic [ACC_BUF_ADDR_WIDTH-1:0]  acc_buffer_waddr_din, acc_buffer_waddr;
  logic [ACC_BUF_ADDR_WIDTH-1:0]  acc_buffer_raddr_din, acc_buffer_raddr;
  logic                           acc_buffer_raddr_en;

  reg bias_load_en_ff;
  wire bias_load_done;
  `DFF_RST(bias_load_en_ff, bias_load_en, reset, clk)
  assign bias_load_done = ~bias_load_en & bias_load_en_ff;

  //Address Generator
  assign acc_buffer_waddr_din[ACC_BUF_ADDR_WIDTH-1:0] = acc_buffer_waddr[ACC_BUF_ADDR_WIDTH-1:0] +  { {(ACC_BUF_ADDR_WIDTH-1){1'b0}}, (acc_en | bias_load_en)};
  `DFF_EN_RST_DONE(acc_buffer_waddr[ACC_BUF_ADDR_WIDTH-1:0], acc_buffer_waddr_din[ACC_BUF_ADDR_WIDTH-1:0], (acc_en | bias_load_en), reset, ((done & ~bias_load_en) | bias_load_done), clk)

  assign acc_buffer_raddr_din[ACC_BUF_ADDR_WIDTH-1:0] = acc_buffer_raddr[ACC_BUF_ADDR_WIDTH-1:0] +  { {(ACC_BUF_ADDR_WIDTH-1){1'b0}}, 1'b1};
  assign acc_buffer_raddr_en = |acc_data_col_oen[SYS_ARRAY_WIDTH -1:0];
  `DFF_EN_RST_DONE(acc_buffer_raddr[ACC_BUF_ADDR_WIDTH-1:0], acc_buffer_raddr_din[ACC_BUF_ADDR_WIDTH-1:0], acc_buffer_raddr_en, reset, done, clk)

  generate for(gi=0; gi<SYS_ARRAY_HEIGHT; gi++) begin: gen_acc_buffer_wren
    assign acc_buffer_wren[gi] = (acc_buffer_waddr[ACC_BUF_ADDR_WIDTH-1:0] == gi[ACC_BUF_ADDR_WIDTH-1:0]) & (acc_en | bias_load_en);
  end endgenerate

  data_shift_reg # (
    .ARRAY_DEPTH (ACC_LATENCY),  
    .ARRAY_WIDTH (SYS_ARRAY_HEIGHT)
  ) u_wren_staging_reg (
    .clk (clk),
    .reset (reset),
    .en (1'b1),
    .data_i (acc_buffer_wren),
    .data_o (acc_buffer_wren_ff)
  );


  //write strobe for bias
  logic [SYS_ARRAY_HEIGHT-1:0] bias_strb;
  logic bias_sel;
  always @(posedge clk) begin
    if(!reset) begin
      bias_strb <= 'b1;
    end else if(bias_load_done) begin
      bias_strb <= 'b1;
    end else if(bias_load_en & ~bias_sel) begin
      bias_strb <= {bias_strb[SYS_ARRAY_HEIGHT-2:0], 1'b1};
    end else if(bias_load_en & bias_sel) begin
      bias_strb <= {bias_strb[SYS_ARRAY_HEIGHT-2:0], 1'b0};
    end else begin
      bias_strb <= bias_strb;
    end
  end

  always@(posedge clk) begin
    if(!reset) begin
      bias_sel <= 'b0;
    end else if(bias_load_done) begin
      bias_sel <= 'b0;
    end else if(bias_load_en & (acc_buffer_waddr == 'he)) begin
      bias_sel <= ~bias_sel;
    end else begin
      bias_sel <= bias_sel;
    end
  end

  //2D Buffer

  //accumulate
  logic signed [SYS_ARRAY_WIDTH-1:0][ACC_WIDTH-1:0] acc_buffer_sum;
  logic [ACC_BUF_ADDR_WIDTH-1:0] acc_buffer_row_sel;   

  always_comb begin
    integer i;
    for(i=0; i<SYS_ARRAY_HEIGHT; i++) begin
      if(acc_buffer_wren[i] == 1) begin
        acc_buffer_row_sel = i;
        break;
      end else
      acc_buffer_row_sel = 0;
    end
  end

  generate for(gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: gen_adder
    if (MAC_PRECISION == 4) begin 
      fp32_acc_xilinx u_fp32_acc(
        .aclk(clk),
        .s_axis_a_tvalid(1'b1), // input wire s_axis_a_tvalid
        .s_axis_a_tdata(
      `ifdef SYS_ARRAY_NUM_2
        ({ACC_WIDTH{~acc_buffer_sel}} & acc_buffer_0[gi][acc_buffer_row_sel]) | 
      `endif	
        ({ACC_WIDTH{acc_buffer_sel}} & acc_buffer_1[gi][acc_buffer_row_sel])), // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(1'b1), // input wire s_axis_b_tvalid
        .s_axis_b_tdata(pacc_data_in[gi]), // input wire [31 : 0] s_axis_b_tdata
        .m_axis_result_tvalid(), // output wire m_axis_result_tvalid
        .m_axis_result_tdata(acc_buffer_sum[gi]) // output wire [31 : 0] m_axis_result_tdata
      );
    end else if (MAC_PRECISION == 1) begin
      int8_adder #(
        .ACC_WIDTH(ACC_WIDTH),
        .LATENCY(ACC_LATENCY)
      ) u_int8_acc (
        .clk(clk),
        .rst(reset),
        .a(
      `ifdef SYS_ARRAY_NUM_2
        ({ACC_WIDTH{~acc_buffer_sel}} & acc_buffer_0[gi][acc_buffer_row_sel]) | 
      `endif	
        ({ACC_WIDTH{acc_buffer_sel}} & acc_buffer_1[gi][acc_buffer_row_sel])), // input wire [31 : 0] s_axis_a_tdata
        .b(pacc_data_in[gi]), // input wire [31 : 0] s_axis_b_tdata
        .z(acc_buffer_sum[gi]) // output wire [31 : 0] m_axis_result_tdata
      );
    end
  end endgenerate

  generate for(gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: gen_acc_buffer_din_col
    for(gj=0; gj<SYS_ARRAY_HEIGHT; gj++) begin: gen_acc_buffer_din_row
      if(gj<ACC_LATENCY) begin
        assign acc_buffer_din[gi][SYS_ARRAY_HEIGHT-ACC_LATENCY+gj] = acc_buffer_rden[gi][SYS_ARRAY_HEIGHT-ACC_LATENCY+gj] ? 'b0 : // Read Clear to 0
        acc_buffer_wren[gj] ? acc_buffer_sum[gi] : // Write Accumulate
      `ifdef SYS_ARRAY_NUM_2
        ~acc_buffer_sel ? acc_buffer_0[gi][SYS_ARRAY_HEIGHT-ACC_LATENCY+gj] :
      `endif
        acc_buffer_1[gi][SYS_ARRAY_HEIGHT-ACC_LATENCY+gj]; // Otherwise 
      end else begin
        assign acc_buffer_din[gi][gj-ACC_LATENCY] =  acc_buffer_rden[gi][gj-ACC_LATENCY] ? 'b0 : // Read Clear to 0
        acc_buffer_wren[gj] ? acc_buffer_sum[gi] : // Write Accumulate
      `ifdef SYS_ARRAY_NUM_2
        ~acc_buffer_sel ? acc_buffer_0[gi][gj-ACC_LATENCY] :
      `endif
        acc_buffer_1[gi][gj-ACC_LATENCY]; // Otherwise 
      end
      `DFF_EN_RST_DONE_LOAD(acc_buffer_1[gi][gj], acc_buffer_din[gi][gj], bias_data_in[gi], (acc_buffer_wren_ff[gj] & acc_buffer_sel & ~bias_load_en), reset, (((write_back & done & acc_clear_en) | clear_buffer) & acc_buffer_sel), (bias_load_en & bias_strb[gi] & acc_buffer_wren[gj]), clk)
    end
  end endgenerate

  //Generate entry read enable
  generate for(gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: gen_acc_data_col_oen
    if (gi == 0) begin
      assign acc_data_col_oen[gi] = acc_data_oen;
    end else begin
      `DFF_RST(acc_data_col_oen[gi], acc_data_col_oen[gi-1], reset, clk)
    end
  end endgenerate

  generate for(gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: gen_acc_buffer_rden_col
    for(gj=0; gj<SYS_ARRAY_HEIGHT; gj++) begin: gen_acc_buffer_rden_row
      assign acc_buffer_rden[gi][gj] = acc_data_col_oen[gi] & (acc_buffer_raddr[ACC_BUF_ADDR_WIDTH-1:0] == gj[ACC_BUF_ADDR_WIDTH-1:0]);
    end
  end endgenerate   


  //Generate Accumulation Data
  always_comb begin
    for (int i=0; i<SYS_ARRAY_WIDTH; i++) begin
      facc_data_out_din[i] = 'b0;
      for (int j=0; j<SYS_ARRAY_HEIGHT; j++) begin
        facc_data_out_din[i] |= 
      `ifdef SYS_ARRAY_NUM_2
        ~acc_buffer_sel ? ({(ACC_WIDTH){acc_buffer_rden[i][j]}} & acc_buffer_0[i][j]) : 
      `endif
        ({(ACC_WIDTH){acc_buffer_rden[i][j]}} & acc_buffer_1[i][j]);
      end
    end
  end

  generate for(gi=0; gi<SYS_ARRAY_WIDTH; gi++) begin: gen_acc_data_out
  `DFF_EN_RST(facc_data_out[gi], facc_data_out_din[gi], acc_data_col_oen[gi], reset, clk)
  assign fact_data_out[gi] =  relu_en ? (facc_data_out[gi][ACC_WIDTH-1] ? 'd0 : facc_data_out[gi][ACC_WIDTH-1:0]) : facc_data_out[gi][ACC_WIDTH-1:0];
  end endgenerate

endmodule //endmodule ACC

