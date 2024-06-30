`timescale 1ns / 1ps

`include "parts_made/mult.v"

module multiplier_tb;
   parameter n_bits = 32;
	
	// Inputs
	reg [n_bits-1:0] a_in;
	reg [n_bits-1:0] b_in;
	reg clk;
	reg start;
	reg reset;

	// Outputs
	wire [n_bits-1:0] hi;
	wire [n_bits-1:0] lo;

	// Instantiate the Unit Under Test (UUT)
	mult uut (
		.srcA(a_in), 
		.srcB(b_in), 
		.clk(clk), 
		.multCtrl(start), 
		.reset(reset), 
		.hi(hi), 
		.lo(lo)
	);

   
	initial
	begin
	forever 
		#50 clk= ~clk;
	end
	
	initial begin
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
		a_in = 'd1878982656;
		b_in = 'd8 ;
		start = 1;
		#100
		start = 0;
		#(100*n_bits)
        $display("hi = %d, lo = %d", hi, lo);
		a_in = 'd1878982656;
		b_in = 'd8 ;
		start = 1;
		#100
		start = 0;
		#(100*n_bits)
        $display("%b%b", hi, lo);
		$finish;
	end
      
endmodule