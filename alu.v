`timescale 1ns/100ps

module alu(DATA1,DATA2,RESULT,ZERO,SELECT); //tested and works!
//define inputs
	input signed [7:0]DATA1,DATA2;
	input [2:0]SELECT;
//define output 
	output ZERO;
	output[7:0]RESULT;
	reg [7:0] temp;
	wire andOut;
	reg signed RESULT;
	wire zero_wire;
	reg ZERO;
	
	
	nor nor1(zero_wire,temp[7],temp[6],temp[5],temp[4],temp[3],temp[2],temp[1],temp[0]);
	always @ (DATA2,SELECT) //this part is alone otherwise it is waiting for data1.
	begin
		if (SELECT == 3'b000)
			#1 RESULT = DATA2;
	end
	always @(*)
	begin
		case(SELECT)
	/*	3'b000:
			//forward data2 to result
			//latency = 1
			#1 RESULT =  DATA2;*/
		
		3'b001:
			//ADD data1,data2
			//latency = 2
			#2 RESULT =  DATA1 + DATA2;
		3'b010:
			//AND
			//latency = 1
			#1 RESULT =  DATA1 & DATA2;
		3'b011:
			//OR
			//latency = 1
			#1 RESULT =  DATA1 | DATA2;
		
		/*default:
			//This is reserved
			#1 RESULT = 8'b00000000;*/	
		endcase
	end
	
	/*check inputs are same*/
	always @(*)begin
		temp <=  DATA1 ^ DATA2;//xor
		ZERO = zero_wire;
		
	end
	
	
	
endmodule