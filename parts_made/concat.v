module Concat_OFFSET (
    input  [15:0] data_in_A, // pos immediate instruction[15:0]
    input  [4:0] data_in_B, // pos rt instruction[20:16]
    input  [4:0] data_in_C, // pos rs instruction[25:21]
    output [25:0] data_out
);
    assign data_out = {data_in_C, data_in_B, data_in_A}; // offset -> rd | rs | immediate
endmodule

module Concat_JumpPC (
    input  [27:0] data_in_SL_2628_out,
    input  [31:0] data_in_PC, // PC_out[31:28]
    output [31:0] data_out
);
    assign data_out = {data_in_PC[31:28], data_in_SL_2628_out}; // SL_2628_out -> data_out_offset<<2 & fill with zeros 
endmodule
