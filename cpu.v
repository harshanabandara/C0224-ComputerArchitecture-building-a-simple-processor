`include "alu.v"
`include "other.v"
`include "reg_file.v"
`timescale 1ns/100ps

/*
E16049
Lab 5- part 3
module cpu
*/
/*
	LOADI	0000 0000 0x00
	MOV		0000 0001 0x01	
	ADD		0000 0010 0x02
	SUB		0000 0011 0x03
	AND		0000 0100 0x04
	OR		0000 0101 0x05
	JUMP 	0000 0110 0x06
	BEQ 	0000 0111 0x07
	BNE 	0000 1000 0x08
	LWD		0001 0000 0x10
	LWI		0001 0001 0x11
	SWD		0001 0010 0x12
	SWI		0001 0011 0x13
		
*/

module cpu(PC,INSTRUCTION,CLK,RESET,BUSYWAIT,IMREAD,DM_WRITE,DM_READ,DM_WRITEDATA,DM_READDATA,alu_out_wire);
	
	
	input [31:0] INSTRUCTION ;
	input CLK;
	input RESET;
	output [31:0]PC;
	reg signed PC;
	
	//Data memory signals
	input [7:0] DM_READDATA;
	input BUSYWAIT;
	 
	output DM_READ;
	output DM_WRITE;
	output [7:0] DM_WRITEDATA;
	output [7:0] alu_out_wire;
	output reg IMREAD;
	
	reg DM_WRITEDATA;
	reg DM_READ;
	reg DM_WRITE;
	
	
	
	
	wire signed [31:0] nextPC;
	reg [7:0] opcode;
	reg [7:0] r_in;
	reg [7:0] r_out1;
	reg [7:0] r_out2;
	reg [7:0]immediateVal;
	reg [7:0] jumpTo;
	reg [2:0] source1;
	reg [2:0] source2;
	reg [2:0] destination;
	wire [7:0] alu_out;
	wire [7:0] alu_op_2;	
	wire [7:0] reg_in;
	//control signals
	reg writeenable;
	reg isImmediate;
	reg isMinus;
	reg isJump;
	reg isBEQ;
	reg isBNE;
	reg  isFromMem;
	
	reg [2:0] aluOp;
	wire [7:0]alu_out_wire;
	wire [7:0] r_out1_wire;
	wire [7:0] r_out2_wire;
	wire [7:0] twos_complement_out;
	wire [7:0] mux_1_out;
	wire [7:0] mux_2_out;
	wire isZero_wire;
	wire inverted_zero;
	wire pcMuxSelectOut;
	wire beq_and_out;
	wire bne_and_out;
	wire signed [31:0]extendedPC;
	wire [31:0] pcADD;
	wire [31:0] pcADD1;
	wire [31:0] pcADD0;
	
	//for flow control instructions

	//address should be alu output
	//assign DM_ADDRESS <= alu_out_wire;  

	
	always @ (*)begin
		DM_WRITEDATA <= r_out1_wire;
	end
/////Setting and resetting pc values 
	always @ (*)begin //stays same
		if(RESET==1)begin
			PC = -4;
			isJump = 0;
			isBEQ = 0;
			isBNE = 0;
			IMREAD = 0;

		
			
		end
			//pctemp = -4;
	end
	 	
	//when clk begins pc should update and read write to registers
	always @(posedge CLK) //update pc
	
	begin//if busywait is 0
		
		 if(!BUSYWAIT)begin
			DM_READ = 0;//everytime at posedge of a clock,read,write should be zero;
			DM_WRITE = 0;
			#1 IMREAD = 0;
			PC = nextPC;
			#1 IMREAD = 1;


		end
	end 
	/*
	always @(*)begin
		//$display("%d",PC);
		nextPC  <= pcADD;//this part is changing
//pctemp <= PC + pcADD;
	end
//////
/* 
	in mov,loadi loading source is alu   2 
*/
	always @(INSTRUCTION)begin //instruction decode when instruction is changed
		opcode 		<= INSTRUCTION[31:24];
		destination <= INSTRUCTION[18:16]; //only 3 bit addresses
		jumpTo 		<= INSTRUCTION[23:16];//for jump  
		source1 	<= INSTRUCTION[10:8]; //3bit
		source2 	<= INSTRUCTION[2:0]; //3bit
		immediateVal<= INSTRUCTION[7:0]; //3bit
		#1 
		case(opcode)  
			8'b00000000:begin //loadi
				aluOp =  3'b000;
				writeenable = 1;
				isImmediate = 1; 
				isMinus = 0;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;

			end
			8'b00000001:begin //mov
				aluOp = 3'b000;
				writeenable = 1;
				isImmediate = 0;
				isMinus = 1'b0;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;
			end	
			8'b00000010:begin//add
				aluOp = 3'b001;
				writeenable = 1;
				isImmediate = 0;
				isMinus = 0;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;
			end
			8'b00000011:begin//sub
				aluOp = 3'b001;
				writeenable = 1;
				isImmediate = 0;
				isMinus 	= 1;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;
			end
			8'b00000100:begin//and
				aluOp = 3'b010;
				writeenable = 1;
				isImmediate = 0;
				isMinus = 0;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;
			end
			8'b00000101:begin //or
				aluOp = 3'b011;
				writeenable = 1;
				isImmediate = 0;
				isMinus 	= 0;
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;				
			end
			8'b00000110:begin // jump
				aluOp = 3'b100;
				writeenable = 0;
				isJump = 1;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;				
			end	
			8'b00000111:begin//beq
				writeenable = 0;
				aluOp = 3'b???;//does not matter
				isMinus = 0;
				isImmediate = 0;
				isBEQ = 1;
				isJump = 0;
				isBNE =0;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;				
			end
			8'b00001000:begin//bne
				writeenable = 0;
				aluOp = 3'b???;
				isMinus = 0;
				isImmediate = 0;
				isBEQ = 0;
				isJump = 0;
				isBNE = 1;
				DM_READ = 0;
				DM_WRITE = 0;
				isFromMem = 0;
			end
			8'b00010000:begin //lwd
				writeenable = 1; //we write output to register
				aluOp = 3'b000; //forward address on destination register
				isMinus = 0;
				isImmediate = 0;
				isBEQ = 0;
				isJump = 0;
				isBNE = 0;
				DM_READ = 1;
				DM_WRITE = 0;
				isFromMem = 1;

			end
			8'b00010001:begin//lwi
				writeenable = 1;// write out put to to reg
				aluOp = 3'b000;//forward
				isMinus = 0;
				isImmediate = 1;//immedeate value is the reg address
				isBEQ = 0;
				isJump = 0;
				isBNE = 0;
				DM_READ = 1;
				DM_WRITE = 0;
				isFromMem = 1;
			end
			8'b00010010:begin //swd
				writeenable = 0;	//dont write in reg
				aluOp = 3'b000;		//address should 4wd
				isMinus = 0;		
				isImmediate = 0;	
				isBEQ = 0;
				isJump = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 1;	//write to given address
				isFromMem = 0;
			end
			8'b00010011:begin//swi
				writeenable = 0;
				aluOp = 3'b000;
				isMinus = 0;
				isImmediate = 1;
				isBEQ = 0;
				isJump = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 1;//write
				isFromMem = 0;
			end
			default:begin//xxxxxxxx
				writeenable =0;//to avoid writing
				isJump = 0;
				isBEQ = 0;
				isBNE = 0;
				DM_READ = 0;
				DM_WRITE = 0;
			end
			endcase
			
	end
	//alu calling
	
	twos twos_complement(r_out2_wire,twos_complement_out);//calculate 2's complement of reg2 out
	mux_8_1 mux_negative(r_out2_wire,twos_complement_out,isMinus,mux_1_out);//select either original value or its complement
	mux_8_1 mux_immediate(mux_1_out,immediateVal,isImmediate ,mux_2_out);//select reg2 value or an immediate value
	//mux_8_1 mux_alu_in(mux_2_out,DM_READDATA,DM_READ,alu_op_2);//select either data from memory or prev mux.

	mux_8_1 mux_reg_in(alu_out_wire,DM_READDATA,isFromMem,reg_in);//select which result to select to write the register
	

	alu alu_1(r_out1_wire,mux_2_out,alu_out_wire,isZero_wire,aluOp);
	not _not(inverted_zero,isZero_wire);
	and _and1(beq_and_out,isBEQ,isZero_wire);
	and _and2(bne_and_out,isBNE,inverted_zero);
	or _or(pcMuxSelectOut,beq_and_out,bne_and_out,isJump);
	//pcMuxSelect _pcMuxSelect(isJump,isZero_wire,isBEQ,pcMuxSelectOut );
	
//extending destination 
	signEx _signEx(jumpTo,extendedPC);//extendedPC is 32 bit offset value
	pcMux _pcMux(pcADD0,extendedPC,pcMuxSelectOut,nextPC);
	pcPlus4Adder _pcPlus4(PC,pcADD0);
	//pcFinalAdder _finalAdder(pcADD0,pcADD1,pcADD);

	//reg_file calling
	reg_file register(reg_in,r_out1_wire,r_out2_wire,
				destination,source1,source2,
				writeenable & !BUSYWAIT ,CLK,RESET);
	
	
	

	//read from register and give input
	 
	//get results from alu
	
	
	//write values to register
	//rest is combinational
	
	
endmodule