module mux_PC (
    input wire  [1:0]  sel,
    input wire  [31:0] data_0,
    input wire  [31:0] data_1,
    input wire  [31:0] data_2,
    input wire  [31:0] data_3,
    output reg [31:0] data_out
);
    always @(*) begin
        case (sel)
            2'd0: data_out = data_0;
            2'd1: data_out = data_1;
            2'd2: data_out = data_2;
            2'd3: data_out = data_3;
        endcase 
    end 

endmodule