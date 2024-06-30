module mult (
    input wire [31:0] srcA,
    input wire [31:0] srcB,
    input wire clk,
    input wire reset,
    input wire multCtrl,
    output wire [31:0] hi,
    output wire [31:0] lo
);
    reg [63:0] a_in;
    reg [63:0] b_in;
    reg signal;
    reg signalA;
    reg signalB;    
    reg [63:0] result;
    wire [63:0] out;

    assign out = signal ? ~result + 1 : result;
    assign hi = out[63:32];
	assign lo = out[31:0];


    always @ (posedge clk) begin
        case(multCtrl)
			1'b1: begin
                signalA = srcA[31];
                signalB = srcB[31];
				a_in = signalA? ~srcA + 1 :    srcA;
				b_in = signalB? ~srcB + 1 :    srcB;
				result = 0;
                signal = srcA[31] ^ srcB[31];
			end
			
			1'b0: begin
                if(b_in[0]==1)
                begin
                    result = (result + a_in);
                end
                a_in = a_in<<1;
                b_in = b_in>>1;	
			end
		endcase
    end

    always @(negedge reset)begin
        result = 0;
        a_in = 0;
        b_in = 0;
    end

endmodule