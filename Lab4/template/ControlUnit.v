module ControlUnit(
    //input to ROM system
    input wire RSTn,
    input wire CLK,
    input wire [31:0] I_MEM_DI,
    input wire [1:0] br_control,

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
    output wire [2:0] stage
    );

    //명령어
    reg[6:0] opcode;
    reg[2:0] func3;
    reg[6:0] func7;

    // PC_WE 결정 관련 내부 레지스터
    reg is_branch;
    reg pcUpdate;
    reg BrEq;
    reg BrLt;
    reg br_result;
    always @(*) begin
        if(RSTn == 1) begin
            BrEq = br_control[1];
            BrLt = br_control[0];    
        end
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

    //stage
    reg[2:0] stage_IF;
    reg[2:0] stage_ID;
    reg[2:0] stage_EX;
    reg[2:0] stage_MEM;
    reg[2:0] stage_WB;

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
    reg [2:0] stage_reg;

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
    assign stage = stage_reg;


    //control signal 결정용 내부 레지스터
    reg[5:0] index;
    wire[27:0] control_signal;
    always @(*) begin
        if(RSTn == 1) begin
            imm_control_reg = 
            RF_WE_reg = 
            D_MEM_WEN_reg = 
            D_MEM_BE_reg = 
            is_sign_reg = 
            ASel_reg = 
            BSel_reg = 
            alu_control_reg = 
            wbSel_reg = 
            IR_WE_reg = 
            PC_WE_reg = 
            pcSel_reg = 
            stage_reg =
        end

    end

	MicroCode microCode(
		.RSTn					(RSTn),
        .index              (index)
		.imm					(imm)
	);


    initial begin
        //opcode
        op_LUI <= 7'b0110111;
        op_AUIPC <= 7'b0010111;
        op_JAL <= 7'b1101111;
        op_JALR <= 7'b1100111;
        op_Btype <= 7'b1100011;
        op_Ltype <= 7'b0000011;
        op_Stype <= 7'b0100011;
        op_Itype <= 7'b0010011;
        op_Rtype <= 7'b0110011;

        //stage
        stage_IF <= 3'b000;
        stage_ID <= 3'b001;
        stage_EX <= 3'b010;
        stage_MEM <= 3'b011;
        stage_WB <= 3'b100;

        //메모리 쓰기 관련 관련
        D_MEM_WEN_reg <= 1;
        RF_WE_reg <= 0;

        //pc 쓰기 관련
        is_branch <= 0;
        br_result <= 0;
        pcUpdate <= 1;
        pcSel_reg <= 0;
        stage_reg <= 3'b000;
    end

    // opcode, func3, func7, stage를 이용해서 index 생성
    always@(*) begin
        if(RSTn==1) begin
            opcode = I_MEM_DI[6:0];
            func3 = I_MEM_DI[14:12];
            func7 = I_MEM_DI[31:25];

            PC_WE_reg = pcUpdate | (is_branch & br_result);
            //index 생성

        end
    end

    always @(posedge CLK) begin
        if(RSTn == 1) begin
            if(opcode == op_LUI) begin
                stage_reg = (stage_reg == stage_IF) ? stage_WB:
                (stage_reg == stage_WB)? stage_IF : stage_IF;
            end
            if(opcode == op_AUIPC)begin
                stage_reg = (stage_reg == stage_IF) ? stage_EX:
                (stage_reg == stage_EX) ? stage_WB : 
                (stage_reg == stage_WB) ? stage_IF : stage_IF;
            end
            if(opcode == op_Rtype) begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_WB :
                (stage_reg == stage_WB) ? stage_IF : stage_IF;
            end
            if(opcode == op_Itype) begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_WB :
                (stage_reg == stage_WB) ? stage_IF : stage_IF;
            end
            if(opcode == op_Ltype) begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_MEM :
                (stage_reg == stage_MEM) ? stage_WB :
                (stage_reg == stage_WB) ? stage_IF : stage_IF;
            end
            if(opcode == op_Stype) begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_MEM :
                (stage_reg == stage_MEM) ? stage_IF : stage_IF;
            end
            if(opcode == op_Btype)begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_IF : stage_IF;        
            end
            if(opcode == op_JALR) begin
                stage_reg = (stage_reg == stage_IF) ? stage_ID:
                (stage_reg == stage_ID) ? stage_EX :
                (stage_reg == stage_EX) ? stage_WB :
                (stage_reg == stage_WB) ? stage_IF : stage_IF;           
            end
            if(opcode == op_JAL)begin
                stage_reg = (stage_reg == stage_IF) ? stage_EX:
                (stage_reg == stage_EX) ? stage_WB :
                (stage_reg == stage_WB) ? stage_IF : stage_IF;            
            end
        end
    end

endmodule