module ControlUnit(
    input wire RSTn,
    input wire [31:0] I_MEM_DI,
    input wire BrEq, // 아직 처리 X
    input wire BrLt, // 아직 처리 X
    output wire [2:0] imm_control, // 처리 O
    output wire RF_WE, // 처리 O
    output wire D_MEM_WEN, // 처리 O
    output wire [3:0] D_MEM_BE, // 처리 O
    output wire is_sign, // 처리 O
    output wire ASel, // 처리 O // 1이면 pc 0이면 RF_RD1
    output wire BSel, // 처리 O // 1이면 imm 0이면 RF_RD2
    output wire [4:0] alu_control, // 처리 O
    output wire [1:0] wb_control, // 처리 O
    output wire pcSel
);

reg[6:0] opcode;
reg[2:0] func3;
reg[6:0] func7;

// reg RF_WE_Reg;
// reg D_MEM_WEN_Reg;
// reg [3:0] D_MEM_BE_Reg;

// assign RF_WE = RF_WE_Reg;
// assign D_MEM_WEN = D_MEM_WEN_Reg;

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

    RF_WE <= 0;
    D_MEM_WEN <= 1;
    pcSel <= 0;
end


always@(*) begin
    if(RSTn==1) begin
        opcode = I_MEM_DI[6:0];
        func3 = I_MEM_DI[14:12];
        func7 = I_MEM_DI[31:25];

        if(opcode == op_Btype) begin
            //beq
            if(func3 = 3'b000) begin
                if(BrEq == 1) begin
                    pcSel = 1;
                end
                else begin
                    pcSel = 0;
                end
            end
            //bne
            else if(func3 == 3'b001) begin
                if(BrEq == 0) begin
                    pcSel = 1;
                end
                else begin
                    pcSel = 0;
                end
            end
            //blt
            else if(func3 == 3'b100 || func3 == 3'b110) begin
                if(BrEq == 0 && BrLt == 1) begin
                    pcSel = 1;
                end
                else begin
                    pcSel = 0;
                end
            end
            //bge
            else if(func3 == 3'b101 || func3 == 3'b111) begin
                if(BrEq == 0 && BrLt == 0 )begin
                    pcSel = 1;
                end
                else begin
                    pcSel = 0;
                end
            end
        end
        else if(opcode == op_JAL || opcode == op_JALR) begin
            pcSel = 1;
        end
        else begin
            pcSel = 0;
        end


        if(opcode == op_LUI) begin
            imm_control = 3'b000; // U-type imm 처리
            RF_WE = 1; // imm을 rd에 써야함
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU연산 필요 없음
            //rd = imm
            wb_control = 2'b11;
        end
        if(opcode == op_AUIPC) begin
            imm_control = 3'b000; // U-type imm 처리, 20비트 읽기
            RF_WE = 1;  // 연산결과 rd에 써야함
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: pc + imm
            ASel = 1;
            BSel = 1;
            //alu: 덧셈
            alu_control = 4'b0000;
            //rd = alu_result
            wb_control = 2'b00;
        end
        if(opcode == op_Rtype) begin
            // imm이 없음
            RF_WE = 1; // 연산결과 rd에 써야함
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: rd1 + rd2
            ASel = 0;
            BSel = 0;
            //unsigned 의 경우 
            if(func3 == 3'b011) begin
                is_sign = 0;
            end
            else begin
                is_sign = 1;
            end
            //alu
            if(func3 == 3'b000) begin
                //add
                if(func7 = 7'b0000000) begin
                    alu_control = 4'b0000;
                end
                //sub
                else if(func7 = 7'b0100000) begin
                    alu_control = 4'b0001;
                end
            end
            //slt and sltu
            else if(func3 == 3'b010 || func3 == 3'b011) begin 
                alu_control = 4'b1000;
            end
            //xor
            else if(func3 == 3'b100) begin
                alu_control = 4'b0100;
            end
            //or
            else if(func3 == 3'b110) begin
                alu_control = 4'b0011;
            end
            //and
            else if(func3 == 3'b111) begin
                alu_control = 4'b0010;
            end
            //sll
            else if(func3 == 3'b001) begin
                alu_control = 4'b0101;
            end
            //srl, sra
            else if(func3 == 3'b101) begin
                //srl
                if(func7 == 7'b0000000) begin
                    alu_control = 4'b0110;
                end
                //sra
                else if(func 7 == 7'b0100000) begin
                    alu_control = 4'b0111;
                end
            end
            //rd = alu_result
            wb_control = 2'b00;
        end
        if(opcode == op_Itype) begin
            RF_WE = 1; // 연산결과 rd에 써야함
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: rd1 + imm
            ASel = 0;
            BSel = 1;
            if(func3 == 3'b101 || func3 == 3'b001) begin
                imm_control = 3'b101; // shift 연산시 imm은 shamt
            end
            else begin
                imm_control = 3'b010; // 그 외에는 12비트 읽기
            end
            
            if(func == 3'b011) begin
                is_sign = 0;
            end
            else begin
                is_sign = 1;
            end

            //alu
            if(func3 == 3'b000) begin
                //add
                if(func7 = 7'b0000000) begin
                    alu_control = 4'b0000;
                end
            end
            //slt and sltu
            else if(func3 == 3'b010 || func3 == 3'b011) begin 
                alu_control = 4'b1000;
            end
            //xor
            else if(func3 == 3'b100) begin
                alu_control = 4'b0100;
            end
            //or
            else if(func3 == 3'b110) begin
                alu_control = 4'b0011;
            end
            //and
            else if(func3 == 3'b111) begin
                alu_control = 4'b0010;
            end
            //sll
            else if(func3 == 3'b001) begin
                alu_control = 4'b0101;
            end
            //srl, sra
            else if(func3 == 3'b101) begin
                //srl
                if(func7 == 7'b0000000) begin
                    alu_control = 4'b0110;
                end
                //sra
                else if(func 7 == 7'b0100000) begin
                    alu_control = 4'b0111;
                end
            end
            //rd = alu_result
            wb_control = 2'b00;
        end

        if(opcode == op_Ltype) begin
            imm_control = 3'b010; // 상위 12비트 그냥 읽기
            RF_WE = 1; // 연산결과 rd에 써야함
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: rd1 + imm
            ASel = 0;
            BSel = 1;
            if(func == 3'b100 || func == 3'b101) begin
                is_sign = 0;
            end
            else begin
                is_sign = 1;
            end

            //D_MEM_BE
            if(func == 3'b000 || func == 3'b100) begin
                D_MEM_BE = 3'b0001;
            end
            else if(func == 3'b001 || func == 3'b101) begin
                D_MEM_BE = 3'b0011;
            end
            else begin
                D_MEM_BE = 3'b1111;
            end
            //alu: 덧셈
            alu_control = 4'b0000;
            //rd = 메모리에서 읽은 값
            wb_control = 2'b01;
        end

        if(opcode == op_Stype) begin
            imm_control = 3'b100; // S-type, 잘라서 12비트 만들기
            RF_WE = 0; // 연산결과 rd에 안써도 됨.
            D_MEM_WEN = 0; // 메모리에 데이터 써야함.
            //ALU: rd1 + imm
            ASel = 0;
            BSel = 1;

            //D_MEM_BE
            if(func == 3'b000) begin
                D_MEM_BE = 3'b0001;
            end
            else if(func == 3'b001) begin
                D_MEM_BE = 3'b0011;
            end
            else begin
                D_MEM_BE = 3'b1111;
            end

             //alu: 덧셈
             alu_control = 4'b0000;
             //wb과정이 없다.
        end

        if(opcode == op_Btype) begin
            imm_control = 3'b011; // B-type 잘라서 13비트 만들기
            RF_WE = 0; // 연산결과 rd에 안써도 됨.
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: pc + imm;
            ASel = 1;
            BSel = 1;
            if(func == 3'b110 || func == 3'b111) begin
                is_sign = 0;
            end
            else begin
                is_sign = 1;
            end
             //alu: 덧셈
             alu_control = 4'b0000;
             //wb과정이 없다.
        end
        if(opcode == op_JALR) begin
            imm_control = 3'b010; // 상위 12비트 읽기
            RF_WE = 1; // pc+4를 rd에 저장
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: rd1 + imm
            ASel = 0;
            BSel = 1;
            
            //alu: 덧셈
            alu_control = 4'b0000;
            //rd = pc + 4;
            wb_control = 2'b10;
        end
        if(opcode == op_JAL) begin
            imm_control = 3'001; // 잘라서 21비트 읽기
            RF_WE = 1; // pc+4를 rd에 저장
            D_MEM_WEN = 1; // 메모리에 쓸 필요 없음
            //ALU: pc + imm
            ASel = 1;
            BSel = 1;

            //alu:덧셈
            alu_control = 4'b0000;

            //rd = pc + 4;
            wb_control = 2'b10;
        end
    end
end

endmodule