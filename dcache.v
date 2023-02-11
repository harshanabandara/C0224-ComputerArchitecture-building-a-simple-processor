
`timescale 1ns/100ps
 module dcache (clk,
                reset,
                busywait,
                mem_busywait,
                write,
                mem_write,
                read,
                mem_read,
                writedata,
                mem_writedata,
                readdata,
                mem_readdata,
                address,
                mem_address);
    //inputs and outputs
    input clk,reset,read,write,mem_busywait;
    output reg mem_read,mem_write,busywait; 

    input [7:0] writedata;
    output reg [31:0] mem_writedata;

    input [31:0] mem_readdata;
    output reg [7:0] readdata;

    input [7:0] address;
    output reg [5:0] mem_address;

    integer i;//for for loop

    reg write_from_cpu,write_from_mem;
    
    /*length of a row is 37 bit :   block   =32 bit 
                                    tag     = 3 bit
                                    dirty   = 1 bit
                                    valid   = 1 bit
                                  _________________
                                    total   =37 bit
    */
    //block array
    reg [7:0] cache_word_31_24  [0:7] ;
    reg [7:0] cache_word_23_16  [0:7] ;
    reg [7:0] cache_word_15_08  [0:7] ;
    reg [7:0] cache_word_07_00  [0:7] ;


    //tag array
    reg [2:0]  cache_tag_array [0:7];
    //valid array
    reg valid_bit_array [0:7];
    //dirty array
    reg dirty_bit_array [0:7];

    wire hit,comparator_out;//to hold tag comparison and hit (and with valid bit)
    wire [2:0]tag;//tag from address
    wire [2:0] index;//index from address
    wire [1:0] offset;//offset from address

    //values from cache
    wire [2:0] tag_in_cache;//
    wire valid,dirty;

    //busywait assign
    always @(*) begin
        if (read||write) 
            busywait = 1;
        else
            busywait = 0;
    end

    assign index = address[4:2];
    assign tag = address[7:5];
    assign offset = address[1:0];

    //if hit is high busywait should be low
    always @ (posedge clk)begin
        if(hit)
            busywait = 0;
    end

    assign #1 dirty = dirty_bit_array[index];
    assign #1 valid = valid_bit_array[index];
    assign #1 tag_in_cache = cache_tag_array[index];

   // comparator mycomparator(tag,tag_in_cache,comparator_out);//has 0.9 buitltin delay
    assign #0.9 comparator_out = tag[2]~^tag_in_cache[2] && tag[1]~^tag_in_cache[1] && tag[0]~^tag_in_cache[0];
    //hit deciding
    assign hit = comparator_out & valid;

    //read output is asynchronus and only when read signal is high
    always @ (*) begin
        if (read) begin
            case (offset)
                2'b00:  #1 readdata <= cache_word_07_00[index];
                2'b01:  #1 readdata <= cache_word_15_08[index];
                2'b10:  #1 readdata <= cache_word_23_16[index];
                2'b11:  #1 readdata <= cache_word_31_24[index]; 
            endcase
        end
    end
    



    //write to cache from cpu
    always @(posedge clk ) begin
        if(write_from_cpu && write )begin
            write_from_cpu = 1'b0;
            #1; 
            case ( offset )
                2'b00: cache_word_07_00[index] <= writedata;
                2'b01: cache_word_15_08[index] <= writedata;
                2'b10: cache_word_23_16[index] <= writedata;
                2'b11: cache_word_31_24[index] <= writedata; 
                 
            endcase
            //set dirty bit
            dirty_bit_array[index] = 1;

        end

    end


    //write to cache from memory
    always @(posedge clk ) begin
        if ( write_from_mem ) begin
            if (!mem_busywait ) begin
                #1;
                cache_tag_array[index] = tag;
                {cache_word_31_24[index],cache_word_23_16[index],cache_word_15_08[index],cache_word_07_00[index]} =mem_readdata;
                dirty_bit_array[index] = 0;
                valid_bit_array[index] = 1;           
            end
        end
        
    end



    /* Cache Controller FSM Start */

    parameter IDLE = 3'b000, MEM_READ = 3'b001,MEM_WRITE = 3'b010;
    reg [2:0] state, next_state;

    // combinational next state logic
    always @(*)
    begin
        case (state)
            IDLE:
                if ((read || write) && !dirty && !hit)  
                    next_state = MEM_READ;
                else if ((read || write) && dirty && ! hit)
                    next_state = MEM_WRITE;
                else
                    next_state = IDLE;
            
            MEM_READ:
                if (!mem_busywait)
                    next_state = IDLE;
                else    
                    next_state = MEM_READ;
            MEM_WRITE:
                if (!mem_busywait) 
                    next_state = MEM_READ;
                else 
                    next_state = MEM_WRITE;    
                  
           

            
        endcase
    end 
    
 
    // combinational output logic
    always @(*)
    begin
        case(state)
            IDLE:
            begin
                mem_read = 0;
                mem_write = 0;
                mem_address = 8'dx;
                mem_writedata = 8'dx;
                write_from_mem = 0;
                if (write & hit) begin
                    write_from_cpu = 1; 
                end
                    
            end
         
            MEM_READ: 
            begin
                mem_read = 1;
                mem_write = 0;
                mem_address = {tag, index};
                mem_writedata = 32'dx;
                write_from_mem = 1;
            end
            MEM_WRITE:
            begin
                mem_write = 1;
                mem_read = 0;
                mem_address = {tag_in_cache,index};
                mem_writedata = {cache_word_31_24[index],cache_word_23_16 [index],cache_word_15_08[index] ,cache_word_07_00[index]};
                
            end
            
        endcase
    end

    // sequential logic for state transitioning 
    always @(posedge clk, reset)
    begin
        if(reset)begin
            state = IDLE;
            busywait = 0;
    
            for (i = 0 ; i<7 ;i++ ) begin
                
                cache_word_31_24[i] = 0;
                cache_word_23_16[i] = 0;
                cache_word_15_08[i] = 0;
                cache_word_07_00[i] = 0;
                
                cache_tag_array[i]  = 0;
                valid_bit_array[i] =  0;
                dirty_bit_array[i]  = 0;
            end
        end  
        else
            state = next_state;
    end

    /* Cache Controller FSM End */

endmodule

