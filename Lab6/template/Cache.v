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
    output wire D_MEM_ADDR,
    output wire[31:0] R_DATA
);

    //실제 table
    reg [133:0] cache [7:0];
    reg [11:0] cache_addr_reg;
    reg [4:0] i;

    reg [31:0] W_DATA;

    reg hit_reg;
    reg IF_ID_WE_reg;
    reg ID_EX_WE_reg;
    reg EX_MEM_WE_reg;
    reg pc_ID_EX_WE_reg;
    reg pc_EX_MEM_WE_reg;
    reg isNop_MEM_WB_reg;
    reg memWrite_EX_MEM_reg;
    reg D_MEM_ADDR_reg;
    reg[31:0] R_DATA_reg;


    assign hit = hit_reg;
    assign  IF_ID_WE = IF_ID_WE_reg;
    assign  ID_EX_WE = ID_EX_WE_reg;
    assign  EX_MEM_WE = EX_MEM_WE_reg;
    assign  pc_ID_EX_WE = pc_ID_EX_WE_reg;
    assign  pc_EX_MEM_WE = pc_EX_MEM_WE_reg;
    assign  isNop_MEM_WB = isNop_MEM_WB_reg;
    assign  memWrite_EX_MEM = memWrite_EX_MEM_reg;
    assign  D_MEM_ADDR = D_MEM_ADDR_reg;
    assign  R_DATA = R_DATA_reg;

    initial begin
        for(i=0; i<8; i=i+1) begin
           cache[i] <= 0; 
        end
    end

    always @(*) begin
        //write Data 설정
        
        //hit 결정 부분

        // hit 결정에 따른 IF_ID_WE, ID_EX_WE, EX_MEM_WE 결정
            //miss 면 0

        //hit 결정에 따른 pc_ID_EX_WE, pc_EX_MEM_WE 결정
            //miss면 0
        
        //hit 결정에 따른 isNop_MEM_WB
            //miss면 1
        
        //hit 결정에 따른 memWrite_EX_MEM
            //??
        
        //load hit

        //load miss

        //write hit

        //write miss
    end
endmodule