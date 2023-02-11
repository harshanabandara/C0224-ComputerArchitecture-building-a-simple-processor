`timescale 1ns/100ps

/*module ex_tb;
	reg signed [7:0] in;
	wire [31:0] out;
	signEx my_signEx(in,out);
	initial begin
		in = 8'h00;
		#2
		in = 8'hff;
		#2
		in = 8'he1;
		
		
	end
	always @ (out)
		begin
			$display("in:%b out:%b",in,out);
		end

endmodule
*/
module pcPlus4Adder(PC,OUT);
	input [31:0] IN,PC;
	output [31:0] OUT;
	reg OUT;
	always @(*) begin
		#1 OUT = PC + 4;
	end

endmodule

//	  module  
/*
module pcFinalAdder(IN0,IN1,OUT,SEL);
//no latency
	input [31:0] IN0,IN1;
	output [31:0] OUT;
	reg OUT;
	always @ (*) begin
		OUT = IN0 + IN1;
	end
endmodule
*/


module pcMux(IN0,IN1,SEL,OUT);//#4 is hardcoded
//combinational device
	input [31:0] IN0,IN1;
	input SEL;
	output [31:0] OUT;
	reg OUT;
	always @ (*)begin
		 case(SEL)
			1'b0:
				 OUT <= IN0;//normal pc adder this is already calculated.. no need for delay
			1'b1:
				#2 OUT <= IN0+IN1;//target pc adder 
		endcase
	end
endmodule

module signEx(bit8,bit32); //tested & works
	input [7:0] bit8;
	output[31:0] bit32;
	
	reg bit32;
	always @(bit8)begin
		bit32 <= {{22{bit8[7]}},bit8[7:0],2'b0};
	end
endmodule

/*
calculate and return 2's complement negative value
*/


 module twos(in,out);
	input [7:0] in;
	output [7:0] out;
	//wire [7:0] temp;
	reg [7:0]temp;
	reg out;
	always @ (*) begin //this is combinational
		//if in value is negative
			if(in[7] == 1)begin
				//substract 1
				temp = in -1;
				//then inverse
				#1 out <= ~temp;
			end
			else begin
				#1 out <= ~in + 1;
			end
	end
 endmodule

 
 module mux_8_1(INPUT1,INPUT2,SEL,OUT);//if 0 ->first argument
	input [7:0] INPUT1,INPUT2;
	input SEL;
	output [7:0] OUT;
	reg OUT;
//combinational 
	always @(*)begin
		if(SEL == 1'b0)
			OUT = INPUT1;
		else
			OUT = INPUT2;
	end
endmodule

module pcMuxSelect(IN0,IN1,SEL,OUT); //not used
	//in0 is isJump
	//in1 is ZERO from alu
	input IN0,IN1,SEL;
	output reg OUT;
	always @(IN0,IN1,SEL)//combinational.
	begin
		if(SEL == 1'b0)
			OUT = IN0;
		else
			OUT = IN1;
	end
	

endmodule
