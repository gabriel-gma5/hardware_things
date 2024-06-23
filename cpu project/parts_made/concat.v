module Concat_OFFSET (
    input  [15:0] data_in_A, // pos immediate instruction[15:0]
    input  [4:0] data_in_B, // pos rd instruction[20:16]
    input  [4:0] data_in_C, // pos rs instruction[25:21]
    output [26:0] data_out
);
    assign data_out = {data_in_C, data_in_B, data_in_A}; // offset -> rd | rs | immediate
endmodule

module Concat_JumpPC (
    input  [27:0] data_in_OFFSET,
    input  [3:0] data_in_PC, // PC[31:38]
    output [31:0] data_out
);
    assign data_out = {data_in_PC, data_in_OFFSET}; // offset -> rd | rs | immediate
endmodule
