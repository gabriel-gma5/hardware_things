module mux_Mem_WD (
    input wire          sel,
    input wire  [31:0] data_0,
    input wire  [31:0] data_1,
    output wire [31:0] data_out
);
    always @(sel) begin
        case (sel)
            1'd0: data_out = data_0;
            1'd1: data_out = data_1;
        endcase 
    end 

endmodule