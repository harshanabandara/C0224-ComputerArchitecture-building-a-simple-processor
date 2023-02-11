`include "cpu.v"
`include "datamem.v"
`include "dcache.v"
`include "ins_cache.v"

`timescale 1ns/100ps

module cpu_tb();

    reg [31:0] INSTRUCTION_MEM [0:1023];

    wire [31:0] INSTRUCTION;
    wire [31:0] PC;
    reg CLK, RESET;
    wire BUSYWAIT,DM_WRITE,DM_READ,IREAD;
    wire [7:0] DM_WRITEDATA,DM_READDATA,DM_ADDRESS;
	integer i;
	integer j;

    //signals between cpu and cache
    wire cache_busy,cache_read,cache_write;
    wire [7:0] cache_writedata,cache_readdata,cache_address;

    //between cpu and icache and imem
    wire [127:0] ins_mem_readdata;
    wire ins_mem_busywait,ins_cache_busy,ins_mem_read,IMREAD;
    wire [5:0]ins_mem_address;

    //signals between cache and memory
    wire mem_busy,mem_read,mem_write;
    wire [31:0] mem_readdata,mem_writedata;
    wire [5:0] mem_address;
    cpu mycpu(PC, INSTRUCTION, CLK, RESET,(ins_cache_busy | cache_busy),IMREAD,cache_write,cache_read,cache_writedata,cache_readdata,cache_address);
    dcache mycache(CLK,RESET,cache_busy,mem_busy,cache_write,mem_write,cache_read,mem_read,cache_writedata,mem_writedata,cache_readdata,mem_readdata,cache_address,mem_address);
    data_memory mydatamem(CLK,RESET,mem_read,mem_write,mem_address, mem_writedata, mem_readdata, mem_busy);


    //instruction memory
    instruction_cache_memory icache(CLK,RESET,IMREAD,PC[9:0],INSTRUCTION,ins_cache_busy);

    //ins_memory myinsmem(CLK,ins_mem_read,ins_mem_address,ins_mem_readdata,ins_mem_busywait);
    //icache myicache(CLK,RESET,PC[9:0],INSTRUCTION,IMREAD,ins_cache_busy,ins_mem_busywait,mem_read,ins_mem_readdata,ins_mem_address);
/*
																							LOADI	0000 0000 0x00
																							MOV		0000 0001 0x01	
																							ADD		0000 0010 0x02
																							SUB		0000 0011 0x03
																							AND		0000 0100 0x04
																							OR		0000 0101 0x05
                                                                                            JUMP    0000 0110 0x06
                                                                                            BEQ     0000 0111 0x07
                                                                                            BNE     0000 1000 0x08
                                                                                            LWD     0001 0000 0x10
                                                                                            LWI     0001 0001 0x11
                                                                                            SWD     0001 0010 0x12 
                                                                                            SWI     0001 0011 0x13
*/
    initial begin
       /* 
        {INSTRUCTION_MEM[0],INSTRUCTION_MEM[1],INSTRUCTION_MEM[2],INSTRUCTION_MEM[3]} 	  = 32'h00000009;//LOADI 0 0x09 (9)
        {INSTRUCTION_MEM[4],INSTRUCTION_MEM[5],INSTRUCTION_MEM[6],INSTRUCTION_MEM[7]} 	  = 32'h00010023;//LOADI 1 0x23 (35)
        {INSTRUCTION_MEM[8],INSTRUCTION_MEM[9],INSTRUCTION_MEM[10],INSTRUCTION_MEM[11]}   = 32'h13000100;//SWI 1 0x00 
        {INSTRUCTION_MEM[12],INSTRUCTION_MEM[13],INSTRUCTION_MEM[14],INSTRUCTION_MEM[15]} = 32'h12000100;//SWD 1 0  
        {INSTRUCTION_MEM[16],INSTRUCTION_MEM[17],INSTRUCTION_MEM[18],INSTRUCTION_MEM[19]} = 32'h13000000;//SWI 0 0X00
        {INSTRUCTION_MEM[20],INSTRUCTION_MEM[21],INSTRUCTION_MEM[22],INSTRUCTION_MEM[23]} = 32'h11030000;//LWI 3 0X00
        {INSTRUCTION_MEM[24],INSTRUCTION_MEM[25],INSTRUCTION_MEM[26],INSTRUCTION_MEM[27]} = 32'h10020000;//LWD 2 0
		{INSTRUCTION_MEM[28],INSTRUCTION_MEM[29],INSTRUCTION_MEM[30],INSTRUCTION_MEM[31]} = 32'h13000002;//SWI 0 0X02
		{INSTRUCTION_MEM[32],INSTRUCTION_MEM[33],INSTRUCTION_MEM[34],INSTRUCTION_MEM[35]} = 32'h10070000;//LWD 7 0X00
		/*{INSTRUCTION_MEM[32],INSTRUCTION_MEM[33],INSTRUCTION_MEM[34],INSTRUCTION_MEM[35]} = 32'h06ff0000;//JUMP -1
        {INSTRUCTION_MEM[36],INSTRUCTION_MEM[37],INSTRUCTION_MEM[38],INSTRUCTION_MEM[39]} = 32'h06ff0000;//JUMP -1S
        {INSTRUCTION_MEM[40],INSTRUCTION_MEM[41],INSTRUCTION_MEM[42],INSTRUCTION_MEM[43]} = 32'h00060004;
        {INSTRUCTION_MEM[44],INSTRUCTION_MEM[45],INSTRUCTION_MEM[46],INSTRUCTION_MEM[47]} = 32'h00060004;
        {INSTRUCTION_MEM[48],INSTRUCTION_MEM[49],INSTRUCTION_MEM[50],INSTRUCTION_MEM[51]} = 32'h00060004;
        {INSTRUCTION_MEM[52],INSTRUCTION_MEM[53],INSTRUCTION_MEM[54],INSTRUCTION_MEM[55]} = 32'h00060004;
        {INSTRUCTION_MEM[56],INSTRUCTION_MEM[57],INSTRUCTION_MEM[58],INSTRUCTION_MEM[59]} = 32'h00060004;
        {INSTRUCTION_MEM[60],INSTRUCTION_MEM[61],INSTRUCTION_MEM[62],INSTRUCTION_MEM[63]} = 32'h00060004;

       /* 
        // Uncomment this for run instruction set without data memory
        {INSTRUCTION_MEM[0],INSTRUCTION_MEM[1],INSTRUCTION_MEM[2],INSTRUCTION_MEM[3]} 	  = 32'h00010009;//LOADI 1 0x09 (9)
        {INSTRUCTION_MEM[4],INSTRUCTION_MEM[5],INSTRUCTION_MEM[6],INSTRUCTION_MEM[7]} 	  = 32'h00000023;//LOADI 0 0x23 (35)
        {INSTRUCTION_MEM[8],INSTRUCTION_MEM[9],INSTRUCTION_MEM[10],INSTRUCTION_MEM[11]}   = 32'h01020001;//MOV 2 1  
        {INSTRUCTION_MEM[12],INSTRUCTION_MEM[13],INSTRUCTION_MEM[14],INSTRUCTION_MEM[15]} = 32'h03030201;//SUB 3 2 1  
        {INSTRUCTION_MEM[16],INSTRUCTION_MEM[17],INSTRUCTION_MEM[18],INSTRUCTION_MEM[19]} = 32'h02040100;//ADD 4 1 0
        {INSTRUCTION_MEM[20],INSTRUCTION_MEM[21],INSTRUCTION_MEM[22],INSTRUCTION_MEM[23]} = 32'h04050100;//AND 5 1 0
        {INSTRUCTION_MEM[24],INSTRUCTION_MEM[25],INSTRUCTION_MEM[26],INSTRUCTION_MEM[27]} = 32'h05060100;//OR 6 1 0
		{INSTRUCTION_MEM[28],INSTRUCTION_MEM[29],INSTRUCTION_MEM[30],INSTRUCTION_MEM[31]} = 32'h07010201;//BEQ 0X01 2 1
		{INSTRUCTION_MEM[32],INSTRUCTION_MEM[33],INSTRUCTION_MEM[34],INSTRUCTION_MEM[35]} = 32'h01030000;//MOV 3 0
        {INSTRUCTION_MEM[36],INSTRUCTION_MEM[37],INSTRUCTION_MEM[38],INSTRUCTION_MEM[39]} = 32'h08fe0003;//BNE 0Xfe 0 3
        {INSTRUCTION_MEM[40],INSTRUCTION_MEM[41],INSTRUCTION_MEM[42],INSTRUCTION_MEM[43]} = 32'h06ff0000;//JUMP OXff 
        */
        $dumpfile("cpu_wavedata.vcd");
		$dumpvars(0, cpu_tb);
		
		for(i = 0;i<8;i=i+1) $dumpvars(0,mycpu.register.register[i]);
		for(j = 0;j<256;j=j+1) $dumpvars(0,mydatamem.memory_array[j]);
		for(j = 0;j<8;j=j+1) $dumpvars(0,mycache.cache_word_31_24[j]);
		for(j = 0;j<8;j=j+1) $dumpvars(0,mycache.cache_word_23_16[j]);
		for(j = 0;j<8;j=j+1) $dumpvars(0,mycache.cache_word_15_08[j]);
		for(j = 0;j<8;j=j+1) $dumpvars(0,mycache.cache_word_07_00[j]);
		

        CLK = 1'b1;

        RESET = 1'b0;

        #3
        RESET = 1'b1;

        #5
        RESET = 1'b0;


        #2000
        $finish;
    end
    
    always//make clk cycle 8 units
        #4 CLK = ~CLK;

endmodule