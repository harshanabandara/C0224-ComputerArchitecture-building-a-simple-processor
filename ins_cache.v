`include "instruction_mem.v"
`timescale 1ns/100ps

module instruction_cache_memory( clk, reset, read, pc, instruction, busywait);
//inputs and outputs
input clk, reset, read;
input [9:0] pc;

output reg [31:0]  instruction;
output reg busywait;


reg writeCheck;                 //to indicate writing

//cache memory block is separated into 4 words
reg [127:0] cache_word_0 [0:7]; 
reg [127:0] cache_word_1 [0:7];
reg [127:0] cache_word_2 [0:7];
reg [127:0] cache_word_3 [0:7];
//tag,valid bits are seperated
reg [2:0] tag_array [0:7];
reg valid_bit_array [0:7];

//valid,hit indicators
reg valid,hit;

//decoding from pc
reg [1:0] offset;
reg [2:0] index,tag,tag_in_cache;



always @(pc)
begin
//assign tag,index,offset values
    tag = pc[9:7];
    index = pc[6:4];
    offset = pc[3:2];

end
//hit deciding
always @(*)
begin
    #1
    valid = valid_bit_array[index];
    tag_in_cache = tag_array[index];

    #0.9
    if (tag == tag_in_cache && valid ) 
        hit = 1;
    else 
        hit = 0;
end


reg mem_read;
reg [0:5] mem_address;
wire mem_busywait;
wire [127:0] mem_readdata;


ins_memory mydmem(clk, mem_read, mem_address, mem_readdata, mem_busywait);

reg readaccess;
always @(read)
begin
    busywait = read ? 1 : 0;
    readaccess = read ? 1 : 0;
end

always @(*)
begin
    if (readaccess && !hit) 
    begin
        busywait = 1'b1;
        mem_read = 1'b1;
        mem_address = pc[9:4];
        writeCheck = 1'b1;
 
    end
end

//write into cache
always @ (posedge clk)
begin
    if (!mem_busywait &&  writeCheck == 1'b1)
    begin
        busywait = 1'b0;
        mem_read = 1'b0;
        #1

       
        cache_word_0[index]    = mem_readdata[31:0];
        cache_word_1[index]    = mem_readdata[63:32];
        cache_word_2[index]    = mem_readdata[95:64];
        cache_word_3[index]    = mem_readdata[127:96];

        
        valid_bit_array[index] = 1;
        tag_array[index] = tag;
        writeCheck = 1'b0;
    end
end

//send the instruction based on offset
always @(*)
begin
    if (readaccess && !mem_busywait)
    begin
        case (offset)
            2'b00 : #1 instruction = cache_word_0[index];
            2'b01 : #1 instruction = cache_word_1[index];
            2'b10 : #1 instruction = cache_word_2[index];
            2'b11 : #1 instruction = cache_word_3[index]; 
        endcase
        
    end
end

//set busywait low if it is a it
always @(posedge clk)
begin
    if (hit)
        busywait = 1'b0;
end

//when reset every thing is set to zero
integer i;
always @(posedge reset)
begin
    if(reset)
    begin
        busywait = 0;
        writeCheck = 1'b0;
        for(i=0;i<8;i=i+1) begin
            
            cache_word_0[i] = 32'd0;
            cache_word_1[i] = 32'd0;
            cache_word_2[i] = 32'd0;
            cache_word_3[i] = 32'd0;
            valid_bit_array[i] = 0;
            tag_array[i] = 0;

        end
    end
end

endmodule