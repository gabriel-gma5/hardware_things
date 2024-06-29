module mux_ALU_B (
    input wire [2:0] sel,
    input wire [31:0] data_0,
    input wire [31:0] data_2,
    input wire [31:0] data_3,
    output reg [31:0] data_out
);
    wire [31:0] notB = ~data_0;
    always @(*) begin
        case (sel)
            3'd0: data_out = data_0;
            3'd1: data_out = 32'd4;
            3'd2: data_out = data_2;
            3'd3: data_out = data_3;
            3'd4: data_out = notB; 
            default: data_out = 32'd4;
        endcase 
    end 

endmodule