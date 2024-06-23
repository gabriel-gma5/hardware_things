module mux_Shift_Src (
    input wire         sel,
    input wire  [31:0] data_0, //vem do A 
    input wire  [31:0] data_1, // vem do B 
    output wire [31:0] data_out
);
    always @(sel) begin
        case (sel)
            1'd0: data_out = data_0;
            1'd1: data_out = data_1;
        endcase 
    end 

endmodule