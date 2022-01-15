module ControlUnit(
    //input to ROM system
    input wire RSTn,
    input wire [31:0] I_MEM_DI,
    input wire [1:0] br_control,
    input wire [2:0] stage,

    //output of control signal
    output wire [2:0] imm_control, // immediate 생성 관련
    output wire RF_WE, // regWrite
    output wire D_MEM_WEN, // mem_write
    output wire [3:0] D_MEM_BE, // mem read,write 시 바이트 조절
    output wire is_sign, // sign 명령어인지 아닌지
    output wire [1:0] ASel, // RF_RD1, pc, oldPc
    output wire [1:0] BSel, // RF_RD2, imm, 4
    output wire [4:0] alu_control, //alu control decoder
    output wire [1:0] wbSel,   //wbSel
                                    // - 00: Alu_out
                                    // - 01: D_MEM_OUT
                                    // - 10: AluResult
                                    // - 11: Imm
    output wire ALU_REG_WE,
    output wire IR_WE, // IrWrite
    output wire PC_WE, // pcWrite
    output wire pcSel,   // pcSel
                        // - 0: alu_result(즉시 계산값)
                        // - 1: alu_out(저장값)
);

//명령어
reg[6:0] opcode;
reg[2:0] func3;
reg[6:0] func7;

// PC_WE 결정 관련
reg is_branch;
reg pcUpdate;
reg BrEq;
reg BrLt;
reg br_result;
always @(*) begin
    BrEq = br_control[1];
    BrLt = br_control[0];
end

//control
reg[6:0] op_LUI;
reg[6:0] op_AUIPC;
reg[6:0] op_JAL;
reg[6:0] op_JALR;
reg[6:0] op_Btype;
reg[6:0] op_Ltype;
reg[6:0] op_Stype;
reg[6:0] op_Itype;
reg[6:0] op_Rtype;

//output
reg[2:0] imm_control_reg;
reg RF_WE_reg;
reg D_MEM_WEN_reg;
reg[3:0] D_MEM_BE_reg;
reg is_sign_reg;
reg ASel_reg;
reg BSel_reg;
reg[4:0] alu_control_reg;
reg[1:0] wbSel_reg;
reg IR_WE_reg;
reg PC_WE_reg;
reg pcSel_reg;

assign imm_control = imm_control_reg;
assign RF_WE = RF_WE_reg;
assign D_MEM_WEN = D_MEM_WEN_reg;
assign D_MEM_BE = D_MEM_BE_reg;
assign is_sign = is_sign_reg;
assign ASel = ASel_reg;
assign BSel = BSel_reg;
assign alu_control = alu_control_reg;
assign wbSel = wbSel_reg;
assign IR_WE = IR_WE_reg;
assign PC_WE = PC_WE_reg;
assign pcSel = pcSel_reg;
 

initial begin
    op_LUI <= 7'b0110111;
    op_AUIPC <= 7'b0010111;
    op_JAL <= 7'b1101111;
    op_JALR <= 7'b1100111;
    op_Btype <= 7'b1100011;
    op_Ltype <= 7'b0000011;
    op_Stype <= 7'b0100011;
    op_Itype <= 7'b0010011;
    op_Rtype <= 7'b0110011;

    //메모리 쓰기 관련 관련
    D_MEM_WEN_reg <= 1;
    RF_WE_reg <= 0;

    //pc 쓰기 관련
    is_branch <= 0;
    br_result <= 0;
    pcUpdate <= 1;
    pcSel_reg <= 0;
    
end


always@(*) begin
    if(RSTn==1) begin
        opcode = I_MEM_DI[6:0];
        func3 = I_MEM_DI[14:12];
        func7 = I_MEM_DI[31:25];

        PC_WE_reg = pcUpdate | (is_branch & br_result);
    end
end

endmodule