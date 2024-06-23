module memAddr (
    input wire [2:0] sel,
    input wire [31:0] data_0,
    input wire [31:0] data_1,
    input wire [31:0] data_5,
    input wire [31:0] data_6,
    output wire [31:0] data_out
);
    always @(sel) begin
        case (sel)
            3'd0: data_out = data_0;
            3'd1: data_out = data_1;
            3'd2: data_out = 32'd253
            3'd3: data_out = 32'd254
            3'd4: data_out = 32'd255
            3'd5: data_out = data_5;
            3'd6: data_out = data_6;
        endcase 
    end 

endmodule