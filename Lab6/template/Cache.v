module Cache(
    input wire RSTn,
    input wire CLK,
    input wire[31:0] INST_EX_MEM,
    input wire[31:0] ADDR,
    input wire[31:0] D_MEM_DI,
    input wire[31:0] W_DATA,

    output wire hit,
    output wire IF_ID_WE,
    output wire ID_EX_WE,
    output wire EX_MEM_WE,
    output wire pc_ID_EX_WE,
    output wire pc_EX_MEM_WE,
    output wire isNop_MEM_WB,
    output wire memWrite_EX_MEM,
    output wire[11:0] D_MEM_ADDR,
    output wire[31:0] R_DATA
);

    //실제 table
    reg [133:0] cache [7:0];
    reg [11:0] cache_addr_reg;
    reg [4:0] i;

    //input
    reg [31:0] INST_reg;
    reg [31:0] ADDR_reg;
    reg [31:0] W_DATA_reg;

    always@(*) begin
        INST_reg = INST_EX_MEM;
        ADDR_reg = ADDR;
        W_DATA_reg = W_DATA;
        opcode = INST_EX_MEM[6:0];
    end

    //output
    reg hit_reg;
    reg IF_ID_WE_reg;
    reg ID_EX_WE_reg;
    reg EX_MEM_WE_reg;
    reg pc_ID_EX_WE_reg;
    reg pc_EX_MEM_WE_reg;
    reg isNop_MEM_WB_reg;
    reg memWrite_EX_MEM_reg;
    reg[11:0] D_MEM_ADDR_reg;
    reg[31:0] R_DATA_reg;

    assign  hit = hit_reg;
    assign  IF_ID_WE = IF_ID_WE_reg;
    assign  ID_EX_WE = ID_EX_WE_reg;
    assign  EX_MEM_WE = EX_MEM_WE_reg;
    assign  pc_ID_EX_WE = pc_ID_EX_WE_reg;
    assign  pc_EX_MEM_WE = pc_EX_MEM_WE_reg;
    assign  isNop_MEM_WB = isNop_MEM_WB_reg;
    assign  memWrite_EX_MEM = memWrite_EX_MEM_reg;
    assign  D_MEM_ADDR = D_MEM_ADDR_reg;
    assign  R_DATA = R_DATA_reg;

    //계산을 위한 register
    reg [2:0] idx;
    reg valid;
    reg [4:0] tag;
    reg [1:0] block_offset;
    reg [1:0] block_offset_temp;
    reg[6:0] op_Ltype;
    reg[6:0] op_Stype;
    reg[6:0] opcode;

    initial begin
        for(i=0; i<8; i=i+1) begin
           cache[i] <= 0; 
        end
        op_Ltype <= 7'b0000011;
        op_Stype <= 7'b0100011;
        block_offset_temp <= 2'b00;
        IF_ID_WE_reg <= 1;
        ID_EX_WE_reg <= 1;
        EX_MEM_WE_reg <= 1;
        pc_ID_EX_WE_reg <= 1;
        pc_EX_MEM_WE_reg <= 1;
        isNop_MEM_WB_reg <= 0;
        memWrite_EX_MEM_reg <= 0;
    end


    always @(*) begin
        tag = ADDR_reg[11:7];
        idx = ADDR_reg[6:4];
        block_offset = ADDR_reg[3:2];
        valid = cache[idx][128];
        
        //hit 결정 부분
        if(opcode ==  op_Ltype | opcode == op_Stype) begin
            if(tag != cache[idx][133:129] | valid == 0) begin
                hit = 0;
            end
            else begin
                hit = 1;
            end
        end
        else begin
            hit = 1;
        end
    end
    
    //load hit
    always @(*) begin    
        if(opcode == op_Ltype & hit == 1) begin
            //R_DATA
            if(block_offset == 2'b00) begin
                R_DATA_reg = Cache[idx][31:0];
            end
            else if(block_offset == 2'b01) begin
                R_DATA_reg = Cache[idx][63:32];
            end
            else if(block_offset == 2'b10) begin
                R_DATA_reg = Cache[idx][95:64];
            end
            else begin
                R_DATA_reg = Cache[idx][127:96];
            end

            //control signal
            IF_ID_WE_reg = 1;
            ID_EX_WE_reg = 1;
            EX_MEM_WE_reg = 1;
            pc_ID_EX_WE_reg = 1;
            pc_EX_MEM_WE_reg = 1;
            isNop_MEM_WB_reg = 0;
            memWrite_EX_MEM_reg = 0;
        end
    end

    //load miss
    always @(*) begin
        if(opcode == op_Ltype & hit == 0) begin
            // D_MEM_ADDR 설정
            D_MEM_ADDR_reg = {ADDR_reg[11:4], block_offset_temp, ADDR_reg[1:0]};
            
            //control signal
            IF_ID_WE_reg = 0; // stall
            ID_EX_WE_reg = 0; // stall
            EX_MEM_WE_reg = 0; // stall
            pc_ID_EX_WE_reg = 0; // stall
            pc_EX_MEM_WE_reg = 0; // stall
            isNop_MEM_WB_reg = 1; // WB 단계 bubble
            memWrite_EX_MEM_reg = 0; // 쓰지 않기
        end
    end

    always @(negedge CLK) begin
        if(opcode == op_Ltype & hit == 0) begin
            //update 하기
            if(block_offset_temp == 2'b00) begin
                cache[idx][31:0] <= D_MEM_DI;
            end
            else if(block_offset_temp == 2'b01) begin
                cache[idx][63:32] <= D_MEM_DI;
            end 
            else if(block_offset_temp == 2'b10) begin
                cache[idx][95:64] <= D_MEM_DI;
            end
            else begin
                cache[idx][127:96] <= D_MEM_DI;
                cache[idx][133:129] <= tag;
                cache[idx][128] <= 1;
            end
            temp_BO <= temp_BO + 1;
        end
    end
            
    
    //store hit
    always @(*) begin
        // update 하기
        if(opcode == op_Stype & hit == 1) begin
            if(block_offset == 2'b00) begin
                cache[idx][31:0] = W_DATA;
            end
            else if(block_offset == 2'b01) begin
                cache[idx][63:32] = W_DATA;
            end
            else if(block_offset == 2'b10) begin
                cache[idx][95:64] = W_DATA;
            end
            else begin
                cache[idx][127:96] = W_DATA;
            end
            //D_MEM에 쓰기
            D_MEM_ADDR_reg = ADDR_reg;
        
            //control signal
            IF_ID_WE_reg = 1;
            ID_EX_WE_reg = 1;
            EX_MEM_WE_reg = 1;
            pc_ID_EX_WE_reg = 1;
            pc_EX_MEM_WE_reg = 1;
            isNop_MEM_WB_reg = 0;
            memWrite_EX_MEM_reg = 1; // 쓰기
        end
    end

    //store miss
    always @(*) begin
        if(opcode == op_Stype & hit == 0) begin
            //control signal
            //memWrite
            if(block_offset_temp == block_offset) begin
                memWrite_EX_MEM_reg = 1;
            end
            //다른 블럭들은 덮어써지면 안된다.
            else begin
                memWrite_EX_MEM_reg = 0;
            end
            IF_ID_WE_reg = 0; // stall
            ID_EX_WE_reg = 0; // stall
            EX_MEM_WE_reg = 0; // stall
            pc_ID_EX_WE_reg = 0; // stall
            pc_EX_MEM_WE_reg = 0; // stall
            isNop_MEM_WB_reg = 1; // WB 단계 bubble

            //D_MEM_ADDR 설정
            D_MEM_ADDR_reg = {ADDR_reg[11:4], block_offset_temp, ADDR_reg[1:0]};
        end
    end

    always @(posedge CLK) begin
        if(opcode == op_Stype & hit == 0) begin
            //돌면서 캐시 업데이트
            if(block_offset_temp == 2'b00 & block_offset_temp != block_offset) begin
                cache[idx][31:0] <= D_MEM_DI;
            end
            else if(block_offset_temp == 2'b01 & block_offset_temp != block_offset) begin
                cache[idx][63:32] <= D_MEM_DI;
            end 
            else if(block_offset_temp == 2'b10 & block_offset_temp != block_offset) begin
                cache[idx][95:64] <= D_MEM_DI;
            end
            else if(block_offset_temp == 2'b11) begin
                if(block_offset_temp != block_offset) begin
                    cache[idx][127:96] <= D_MEM_DI;
                end
                cache[idx][133:129] <= tag;
                cache[idx][128] <= 1;
            end
            block_offset_temp <= block_offset_temp + 1;
        end
    end

    //else
    always @(*) begin
        if(opcode != op_Ltype | opcode != op_Stype) begin
            D_MEM_ADDR_reg = ADDR_reg;
            R_DATA_reg = D_MEM_DI;

            IF_ID_WE_reg = 1;
            ID_EX_WE_reg = 1;
            EX_MEM_WE_reg = 1;
            pc_ID_EX_WE_reg = 1;
            pc_EX_MEM_WE_reg = 1;
            isNop_MEM_WB_reg = 0;
            memWrite_EX_MEM_reg = 0; 
        end
    end

endmodule