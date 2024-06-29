module mux_divSrcA (
    input wire sel,
    input wire [31:0] data_0, // from A
    input wire [31:0] data_1, // from MDR
    output reg [31:0] data_out
);
    always @(*) begin
        case (sel)
            1'd0: data_out = data_0;
            1'd1: data_out = data_1;
            default: data_out = data_0;
        endcase 
    end 

endmodule