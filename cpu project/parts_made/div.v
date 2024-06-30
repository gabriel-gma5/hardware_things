module div (
    input wire [31:0] srcA, // numerator 
    input wire [31:0] srcB, // denominator
    input wire clk,
    input wire reset,
    input wire divCtrl, // DivInit 
    output reg divZero,
    output reg [31:0] hi,
    output reg [31:0] lo
);

/*
- DivInit = 1 -> Load srcs and set divRun=1
- DivInit = 0 -> Do 1 operation; 32 cycles to finish 
    -- On cycle 32 set divRun=0
*Steps:
    1. quotient and remainder starts with zero; currDigit (of numerator) starts with 31
    2. shift remainder left and fill with the currDigit, then compare it with denominator
    3.  if denominator>remainder: shift left with 0 as the new LSB of the quotient 
        else: subtract to get new remainder and shift left with 1 as the new LSB of the quotient
    4.  if currDigit>0: do currDigit-=1 then goto 2.
        else: divRun = 0
*/	
    reg divRun, signalA, signalB, signalQuot;
    reg [31:0] numerator, quotient; // intermediates for srcA and lo
    reg [31:0] denominator, remainder; // intermediates for srcB and hi
    reg [5:0] cycleCount, currDigit;

    always @ (posedge clk) begin
        divZero = 1'b1;
		if (reset) begin
			numerator=32'b0; denominator=32'b0;
			quotient=32'b0; remainder=32'b0;

			currDigit=5'd31; cycleCount=5'd0;
            hi=32'b0; lo=32'b0;

			divRun = 0; 
		end
        else if(divCtrl) begin
            if(srcB == 32'b0) begin
                divZero = 0;
            end 
            else begin
                signalA = srcA[31];
                signalB = srcB[31];
                signalQuot = signalA ^ signalB; 
                numerator = signalA ? ~srcA + 1 : srcA;
                denominator = signalB ? ~srcB + 1 : srcB;  

                quotient = 31'b0; remainder = 31'b0;
                divRun = 1'b1; divZero = 1'b1;
                currDigit = 5'd31; cycleCount = 5'd0;

                hi=32'b0; lo=32'b0;
                
                remainder = {remainder[29:0],numerator[currDigit]};
                if(denominator>remainder) begin
                    quotient = {quotient[29:0], 1'b0};
                end
                else begin
                    remainder = remainder - denominator;
                    quotient = {quotient[29:0],1'b1};  
                end
                cycleCount <= cycleCount+1'b1;
                currDigit = currDigit-1'b1;
            end
        end
        
        if(!divCtrl & divRun) begin 
            remainder = {remainder[29:0],numerator[currDigit]};
            if(denominator>remainder) begin
                quotient = {quotient[29:0], 1'b0};
            end
            else begin
                remainder = remainder - denominator;
                quotient = {quotient[29:0],1'b1};  
            end
            cycleCount <= cycleCount+1'b1;
            if(cycleCount==5'b11111) begin  // stop div
                divRun=0;
                hi = signalA ? ~remainder + 1 : remainder;
                lo = signalQuot ? ~quotient + 1 : quotient;
            end
            else begin //-1
                currDigit = currDigit-1'b1;
            end
        end
    end
endmodule