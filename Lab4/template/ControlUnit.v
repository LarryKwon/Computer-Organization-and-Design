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
    reg ALU_REG_WE_reg;

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
    assign ALU_REG_WE = ALU_REG_WE_reg;


    //control signal 결정용 내부 레지스터
    reg[4:0] index;
    wire[25:0] control_signal;

	MicroCode microCode(
		.RSTn				(RSTn),
        .inst              (index),
        .stage              (stage_reg),
		.constrol_signal	(control_signal)
	);

    always @(*) begin
        if(RSTn == 1) begin
            PC_WE_reg = control_signal[24];
            IR_WE_reg = control_signal[23];
            RF_WE_reg = control_signal[22];
            ASel_reg = control_signal[21:20];
            BSel_reg = control_signal[19:18];
            ALU_REG_WE_reg = control_signal[17];
            is_sign_reg = control_signal[16];
            pcSel_reg = control_signal[15];
            wbSel_reg = control_signal[14:13];
            D_MEM_WEN_reg = control_signal[12];

            D_MEM_BE_reg = control_signal[11:8];
            alu_control_reg = control_signal[7:3];
            imm_control_reg = control_signal[2:0];
        end

    end

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

            if(opcode == op_Rtype) begin
                if(func3 == 3'b000) begin
                    //add
                    if(func7 == 7'b0000000) begin
                        index = 5'b00000;
                    end
                    //sub
                    else if(func7 == 7'b0100000) begin
                        index = 5'b00001;
                    end
                end
                //slt and sltu
                else if(func3 == 3'b010 || func3 == 3'b011) begin 
                    if(func3 == 3'b010) begin
                        index = 5'b00010;
                    end
                    else begin
                        index = 5'b00011;
                    end
                end
                //xor
                else if(func3 == 3'b100) begin
                    index = 5'b00100;
                end
                //or
                else if(func3 == 3'b110) begin
                    index = 5'b00101;
                end
                //and
                else if(func3 == 3'b111) begin
                    index = 5'b00110;
                end
                //sll
                else if(func3 == 3'b001) begin
                    index = 5'b00111;
                end
                //srl, sra
                else if(func3 == 3'b101) begin
                    //srl
                    if(func7 == 7'b0000000) begin
                        index = 5'b01000;    
                    end
                    //sra
                    else if(func7 == 7'b0100000) begin
                        index = 5'b01001;
                    end
                end
            end
            if(opcode == op_Itype) begin
                if(func3 == 3'b000) begin
                    //add
                    if(func7 == 7'b0000000) begin
                        index = 5'b01010;
                    end
                    //sub
                    else if(func7 == 7'b0100000) begin
                        index = 5'b01011;
                    end
                end
                //slt and sltu
                else if(func3 == 3'b010 || func3 == 3'b011) begin 
                    if(func3 == 3'b010) begin
                        index = 5'b01100;
                    end
                    else begin
                        index = 5'b01101;
                    end
                end
                //xor
                else if(func3 == 3'b100) begin
                    index = 5'b01110;
                end
                //or
                else if(func3 == 3'b110) begin
                    index = 5'b01111;
                end
                //and
                else if(func3 == 3'b111) begin
                    index = 5'b10000;
                end
                //sll
                else if(func3 == 3'b001) begin
                    index = 5'b10001;
                end
                //srl, sra
                else if(func3 == 3'b101) begin
                    //srl
                    if(func7 == 7'b0000000) begin
                        index = 5'b10010;    
                    end
                    //sra
                    else if(func7 == 7'b0100000) begin
                        index = 5'b10011;
                    end
                end
            end
            if(opcode == op_Ltype) begin
                index = 5'b10100;
            end
            if(opcode == op_Stype) begin
                index = 5'b10101;
            end
            if(opcode == op_JALR) begin
                index = 5'b10110;
            end
            if(opcode == op_JAL)begin
                index = 5'b10111;
            end
            if(opcode == op_Btype)begin
                if(func3 == 3'b110 || func3 == 3'b111) begin
                    index = 5'b11000;
                end
                else begin
                    index = 5'b11001;
                end
            end
            if(opcode == op_LUI) begin
                index = 5'b11010;
            end
            if(opcode == op_AUIPC)begin
                index = 5'b11011;
            end
        end
    end

    // is_branch & branch_result 값 설정
    always@(*) begin
        if(RSTn == 1) begin
            if(opcode == op_Btype) begin
                is_branch = 1;
                //beq
                if(func3 == 3'b000) begin
                    if(BrEq == 1) begin
                        br_result= 1;
                    end
                    else begin
                        br_result = 0;
                    end
                end
                //bne
                else if(func3 == 3'b001) begin
                    if(BrEq == 0) begin
                        br_result = 1;
                    end
                    else begin
                        br_result = 0;
                    end
                end
                //blt
                else if(func3 == 3'b100 || func3 == 3'b110) begin
                    if(BrEq == 0 && BrLt == 1) begin
                        br_result = 1;
                    end
                    else begin
                        br_result = 0;
                    end
                end
                //bge
                else if(func3 == 3'b101 || func3 == 3'b111) begin
                    if(BrLt == 0 )begin
                        br_result = 1;
                    end
                    else begin
                        br_result = 0;
                    end
                end
            end
            else begin
                is_branch = 0;
            end
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