module LSByte_reader (
    input  [31:0] data_in,
    output [31:0] data_out
);
    assign data_out = {24'b0, data_in[7:0]};
endmodule

module ShiftRightLogical_1to32 (
    input data_in,
    output [31:0] data_out
);
    assign data_out = {31'b0, data_in};
endmodule
