module mux_RegSrc (
    input wire [2:0] sel,
    input wire [31:0] data_1,
    input wire [31:0] data_2,
    input wire [31:0] data_3,
    input wire [31:0] data_4,
    input wire [31:0] data_5,
    input wire [31:0] data_6,
    input wire [31:0] data_7,
    output wire [31:0] data_out
);

    always @(sel) begin
        case (sel)
            3'd0: data_out = 32'd227;
            3'd1: data_out = data_1;
            3'd2: data_out = data_2;
            3'd3: data_out = data_3;
            3'd4: data_out = data_4;
            3'd5: data_out = data_5;
            3'd6: data_out = data_6;
            3'd7: data_out = data_7; 
            default: data_out = 32'd227;
        endcase 
    end 

endmodule