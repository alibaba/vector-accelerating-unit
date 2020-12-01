# VPU submodule
The vector accelerating unit support basic vector operations. This unit receives commands through command fifo; load/store data from/to shared memory; push response to response fifo. 

This vector accelerating unit supports the following SIMD operations (vector accelerator lane number can be configured by user): 

- Vector – vector: vvADD, vvSUB, vvMUL
- N number of vector: vACCU, vMEAN, vMAX, vMIN
- Vector –scalar: vsADD, vsSUB, vsMUL, vsADDi, vsSUBi, vsMULi
- Vector element : vEXP
- Within Vector: sACCU
- Matrix reshape: Padding, Reshape 

Operations details:

- Vector – vector operations: vvADD, vvSUB, vvMUL
  - vvADD: Load (with stride) two input vectors from mem_addr_src1 and mem_addr_src2, do element add operation, write vector results back to mem_addr_dst
  - vvSUB: Load (with stride) two input vectors from mem_addr_src1 and mem_addr_src2, do element sub operation, write vector results back to mem_addr_dst
  - vvMUL: Load (with stride) two input vectors from mem_addr_src1 and mem_addr_src2, do element mul operation, write vector results back to mem_addr_dst
- N number of vector operations: vACCU, vMEAN, vMAX, vMIN
  - vACCU: Load (with stride) n input vectors from mem_addr_src1, do accumulation, write results back to mem_addr_dst
  - vMEAN: Load (with stride) n input vectors from mem_addr_src1, do accumulation, then multiple by 1/n to get mean value, write results back to mem_addr_dst 
  - vMAX: Load (with stride) n input vectors from mem_addr_src1, find max of all input, write results back to mem_addr_dst
  - vMIN: Load (with stride) n input vectors from mem_addr_src1, find min of all input, write results back to mem_addr_dst
- Vector –scalar operations and Vector – immediate number operations : vsADD, vsSUB, vsMUL, vsADDi, vsSUBi, vsMULi
  - vsADD/vsADDi: load scalar from input1 or directly from cmd, load vector from mem_addr_src2 (with stride), do element add operation, write vector results back to mem_addr_dst (with stride) 
  - sSUB/vsSUBi: load scalar from input1 or directly from cmd, load vector from mem_addr_src2 (with stride), do element sub operation, write vector results back to mem_addr_dst (with stride) 
  - vsMUL/vsMULi: load scalar from input1 or directly from cmd, load vector from mem_addr_src2 (with stride), do element mul operation, write vector results back to mem_addr_dst (with stride) 
- Vector element operations: vEXP, sACCU
  - vEXP: Load (with stride) n input vectors from mem_addr_src1, do element exp, write n results back to mem_addr_dst (with stride)
  - sACCU: Load (with stride) n input vectors from mem_addr_src1, for each vector do element accumulation (vlen set by loopmax1), write n scalar results back to mem_addr_dst (with stride), for each result written back, first element is the sum, rest are 0s.
- Padding and vector reshape: PADDING, RESHAPE
  - PADDING: writing zeros at mem_addr_dst(with stride)
  - RESHAPE: read vectors from mem_addr_src1 (with stride1), write to mem_addr_dst (with stride3)

VPU modules:
- cmd register: to save cmd from cmd_fifo
- decoder: to decode incoming cmd
- addr generator/loop control: to calculation load/store address
- load/store: burst load/store 32/16 lane data parallelly to registers/shared memory
- register files to store temp data from computation unit
- computation unit: include add, sub, mul, exp, accu units. 

Typical dataflow is as follows:
- VPU instructions are stored in order in cmd_fifo, cmd_fifo_empty = 0；
- When VPU is ready/idle, enable cmd_fifo_rd and get one vpu instruction;
- Instruction loaded in cmd register and send to decode unit;
- Decode detect optype and opcode to design which computation unit to select;
- Enable load unit to load data from shared memory to register files from mem_addr1 and mem_addr2;
- Calculate input registers at each PU under selected computation unit (ADD, SUB, MUL, EXP, ACCU);
- Put result back to registers or store back to shared memory;
- When finish this cmd, send status done to rsp_fifo to indicate vpu cmd completion. 



