module ShiftLeft_16to32 (
    input [15:0] data_in,
    output [31:0] data_out
);
    assign data_out = {data_in, 16'b0};
endmodule

module ShiftLeft_26to28 (
    input [25:0] data_in,
    output [27:0] data_out
);
    assign data_out = {data_in, 2'b0};
endmodule

module ShiftLeft_32to32 (
    input [31:0] data_in,
    output [31:0] data_out
);
    assign data_out = data_in << 2;
endmodule