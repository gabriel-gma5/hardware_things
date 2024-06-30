`timescale 1ns / 1ps

`include "parts_made/div.v"

module divider_tb;
   parameter n_bits = 32;
	
	// Inputs
	reg [n_bits-1:0] a_in;
	reg [n_bits-1:0] b_in;
	reg clk;
	reg start;
	reg reset;
    wire divZero;

	// Outputs
	wire [n_bits-1:0] hi;
	wire [n_bits-1:0] lo;

	// Instantiate the Unit Under Test (UUT)
	div uut (
		.srcA(a_in), 
		.srcB(b_in), 
		.clk(clk), 
		.divCtrl(start), 
		.reset(reset),
        .divZero(divZero), 
		.hi(hi), 
		.lo(lo)
	);

	initial
	begin
	forever 
		#50 clk= ~clk;
	end
	
	initial begin
        $dumpfile("test.vcd");
        $dumpvars(1, uut);
		// Initialize Inputs
		a_in = 0;
		b_in = 0;
		clk = 0;
		start = 0;
		reset = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		reset = 0;
        #100
        a_in = ~'d25+1;
		b_in = 'd6;
		start = 1;
		#100
		start = 0;
		#(100*n_bits)
        $display("hi = %b, lo = %b, a_in = %b, b_in = %b", hi, lo, a_in, b_in);
        #200
		a_in = 'd1 ;
		b_in = 'd1 ;
		start = 1;
		#100
		start = 0;
		#(100*n_bits)
        $display("hi = %d, lo = %d", hi, lo);
		$finish;
	end
      
endmodule