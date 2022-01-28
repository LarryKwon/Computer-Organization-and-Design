module ControlUnit(
    input wire RSTn,
    input wire[31:0] INST_IF_ID,
    input wire[31:0] INST_ID_EX,    
    input wire BrEq,
    input wire BrLt,
    output wire[2:0] imm_control,	
    output wire regWrite,
    output wire memWrite,
    output wire[3:0] memByte,
    output wire is_sign,
    output wire ASel,
    output wire BSel,
    output wire [4:0] alu_control,
    output wire[1:0] wbSel,
    input wire misPredict,
    output wire isTaken,
    output wire isNop_IF_ID,
    output wire isNop_ID_EX
);

    reg[6:0] opcode_EX;
    reg[2:0] func3_EX;
    reg[2:0] func7_EX;

    reg[6:0] opcode_ID;
    reg[2:0] func3_ID;
    reg[2:0] func7_ID;

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
    reg regWrite_reg;
    reg memWrite_reg;
    reg memByte_reg;
    reg is_sign_reg;
    reg ASel_reg;
    reg BSel_reg;
    reg[4:0] alu_control_reg;
    reg[1:0] wbSel_reg;
    reg isTaken_reg;
    reg isNop_IF_ID_reg;
    reg isNop_ID_EX_reg;

    assign imm_control = imm_control_reg;
    assign regWrite = regWrite_reg;
    assign memWrite = memWrite_reg;
    assign memByte = memByte_reg;
    assign is_sign = is_sign_reg;
    assign ASel = ASel_reg;
    assign BSel = BSel_reg;
    assign alu_control = alu_control_reg;
    assign wbSel = wbSel_reg;
    assign isTaken = isTaken_reg;
    assign isNop_IF_ID = isNop_IF_ID_reg;
    assign isNop_ID_EX = isNop_ID_EX_reg;

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

        regWrite_reg <= 0;
        memWrite_reg <= 0;
        memByte_reg <= 4'b1111;
    end

    always @(*) begin
        if(RSTn == 1) begin
            //INST_IF_ID 꺼 decode
            opcode_ID = INST_IF_ID[6:0];
            func3_ID = INST_IF_ID[14:12];
            fucn7_ID = INST_IF_ID[31:25];

            if(opcode_ID == op_Rtype) begin
                // imm이 없음
                regWrite_reg = 1; // 연산결과 rd에 써야함
                memWrite_reg = 0; // 메모리에 쓸 필요 없음
                //ALU: rd1 + rd2
                ASel_reg = 0;
                BSel_reg = 0;
                //unsigned 의 경우 
                if(func3_ID == 3'b011) begin
                    is_sign_reg = 0;
                end
                else begin
                    is_sign_reg = 1;
                end
                //alu
                if(func3_ID == 3'b000) begin
                    //add
                    if(func7_ID == 7'b0000000) begin
                        alu_control_reg = 4'b0000;
                    end
                    //sub
                    else if(func7_ID == 7'b0100000) begin
                        alu_control_reg = 4'b0001;
                    end
                end
                //slt and sltu
                else if(func3_ID == 3'b010 || func3_ID == 3'b011) begin 
                    alu_control_reg = 4'b1000;
                end
                //xor
                else if(func3_ID == 3'b100) begin
                    alu_control_reg = 4'b0100;
                end
                //or
                else if(func3_ID == 3'b110) begin
                    alu_control_reg = 4'b0011;
                end
                //and
                else if(func3_ID == 3'b111) begin
                    alu_control_reg = 4'b0010;
                end
                //sll
                else if(func3_ID == 3'b001) begin
                    alu_control_reg = 4'b0101;
                end
                //srl, sra
                else if(func3_ID == 3'b101) begin
                    //srl
                    if(func7_ID == 7'b0000000) begin
                        alu_control_reg = 4'b0110;
                    end
                    //sra
                    else if(func7_ID == 7'b0100000) begin
                        alu_control_reg = 4'b0111;
                    end
                end
                //rd = alu_result
                wbSel_reg = 2'b00;
            end
            else if(opcode_ID == op_Itype) begin
                regWrite_reg = 1; // 연산결과 rd에 써야함
                memWrite_reg = 0; // 메모리에 쓸 필요 없음
                //ALU: rd1 + imm
                ASel_reg = 0;
                BSel_reg = 1;
                if(func3_ID == 3'b101 || func3_ID == 3'b001) begin
                    imm_control_reg = 3'b101; // shift 연산시 imm은 shamt
                end
                else begin
                    imm_control_reg = 3'b010; // 그 외에는 12비트 읽기
                end
                
                if(func3_ID == 3'b011) begin
                    is_sign_reg = 0;
                end
                else begin
                    is_sign_reg = 1;
                end

                //alu
                if(func3_ID == 3'b000) begin
                    //add
                    alu_control_reg = 4'b0000;
                end
                //slt and sltu
                else if(func3_ID == 3'b010 || func3_ID == 3'b011) begin 
                    alu_control_reg = 4'b1000;
                end
                //xor
                else if(func3_ID == 3'b100) begin
                    alu_control_reg = 4'b0100;
                end
                //or
                else if(func3_ID == 3'b110) begin
                    alu_control_reg = 4'b0011;
                end
                //and
                else if(func3_ID == 3'b111) begin
                    alu_control_reg = 4'b0010;
                end
                //sll
                else if(func3_ID == 3'b001) begin
                    alu_control_reg = 4'b0101;
                end
                //srl, sra
                else if(func3_ID == 3'b101) begin
                    //srl
                    if(func7_ID == 7'b0000000) begin
                        alu_control_reg = 4'b0110;
                    end
                    //sra
                    else if(func7_ID == 7'b0100000) begin
                        alu_control_reg = 4'b0111;
                    end
                end
                //rd = alu_result
                wbSel_reg = 2'b00;
            end
            else if(opcode_ID == op_Ltype) begin
                imm_control_reg = 3'b010; // 상위 12비트 그냥 읽기
                regWrite_reg = 1; // 연산결과 rd에 써야함
                memWrite_reg = 0; // 메모리에 쓸 필요 없음
                //ALU: rd1 + imm
                ASel_reg = 0;
                BSel_reg = 1;
                if(func3_ID == 3'b100 || func3_ID == 3'b101) begin
                    is_sign_reg = 0;
                end
                else begin
                    is_sign_reg = 1;
                end
                //alu: 덧셈
                alu_control_reg = 4'b0000;
                //rd = 메모리에서 읽은 값
                wbSel_reg = 2'b01;
            end
            else if(opcode_ID == op_Stype) begin
                imm_control_reg = 3'b100; // S-type, 잘라서 12비트 만들기
                regWrite_reg = 0; // 연산결과 rd에 안써도 됨.
                memWrite_reg = 1; // 메모리에 데이터 써야함.
                //ALU: rd1 + imm
                ASel_reg = 0;
                BSel_reg = 1;
                //alu: 덧셈
                alu_control_reg = 4'b0000;
                wbSel_reg = 2'b00;
                //wb과정이 없다.
            end
            else if(opcode_ID == op_Btype) begin
                imm_control_reg = 3'b011; // B-type 잘라서 13비트 만들기
                regWrite_reg = 0; // 연산결과 rd에 안써도 됨.
                memWrite_reg = 0; // 메모리에 쓸 필요 없음
                //ALU: pc + imm;
                ASel_reg = 1;
                BSel_reg = 1;
                if(func3_ID == 3'b110 || func3_ID == 3'b111) begin
                    is_sign_reg = 0;
                end
                else begin
                    is_sign_reg = 1;
                end
                //alu: 덧셈
                alu_control_reg = 4'b0000;
                //wb과정이 없다.
            end
            else if(opcode_ID == op_JALR) begin
                imm_control_reg = 3'b010; // 상위 12비트 읽기
                regWrite_reg = 1; // pc+4를 rd에 저장
                memWrite_reg = 0; // 메모리에 쓸 필요 없음
                //ALU: rd1 + imm
                ASel_reg = 0;
                BSel_reg = 1;
                //alu: 덧셈
                alu_control_reg = 4'b0000;
                //rd = pc + 4;
                wbSel_reg = 2'b10;
            end
            else if(opcode_ID == op_JAL) begin
                imm_control_reg = 3'b001; // 잘라서 21비트 읽기
                regWrite_reg = 1; // pc+4를 rd에 저장
                memWrite_reg = 1; // 메모리에 쓸 필요 없음
                //ALU: pc + imm
                ASel_reg = 1;
                BSel_reg = 1;
                //alu:덧셈
                alu_control_reg = 4'b0000;
                //rd = pc + 4;
                wbSel_reg = 2'b10;
            end

            
            opcode_EX = INST_ID_EX[6:0];
            func3_EX = INST_ID_EX[14:12];
            func7_EX = INST_ID_EX[31:25];

            //isTaken 결정
            if(opcode_EX == op_JAL) begin
                isTaken_reg = 1;
            end
            else if(opcode_EX == op_JALR) begin
                isTaken_reg = 1;
            end
            else if(opcode_EX == op_Btype) begin
                //beq
                if(func3_EX == 3'b000) begin
                    if(BrEq == 1) begin
                        isTaken_reg = 1;
                    end
                    else begin
                        isTaken_reg = 0;
                    end
                end
                //bne
                else if(func3_EX == 3'b001) begin
                    if(BrEq == 0) begin
                        isTaken_reg = 1;
                    end
                    else begin
                        isTaken_reg = 0;
                    end
                end
                //blt
                else if(func3_EX == 3'b100 || func3_EX == 3'b110) begin
                    if(BrEq == 0 && BrLt == 1) begin
                        isTaken_reg = 1;
                    end
                    else begin
                        isTaken_reg = 0;
                    end
                end
                //bge
                else if(func3_X == 3'b101 || func3_EX == 3'b111) begin
                    if(BrLt == 0 )begin
                        isTaken_reg = 1;
                    end
                    else begin
                        isTaken_reg = 0;
                    end
                end
            end
            else begin
                isTaken_reg = 0;
            end

            //isNop 설정
            if(opcode_EX == op_JAL | opcode_EX == op_JALR | opcode_EX == op_Btype) begin
                if(misPredict) begin
                    isNop_IF_ID_reg = 1;
                    isNop_ID_EX_reg = 1;
                end
                else begin
                   isNop_IF_ID_reg = 0;
                   isNop_ID_EX_reg = 0;
                end    
            end
            else begin
                isNop_IF_ID_reg = 0;
                isNop_ID_EX_reg = 0;
            end
        end
    end

endmodule