module mux_opt_flag (
    input wire sel,
    input wire  data_0, // flag GT 
    input wire  data_1, // flag 0 
    output reg data_out
);
    always @(*) begin
        case (sel)
            1'd0: data_out = data_0;
            1'd1: data_out = data_1;
            default: data_out = data_0;
        endcase 
    end 

endmodule