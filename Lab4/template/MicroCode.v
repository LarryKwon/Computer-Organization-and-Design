module MicroCode #(
	parameter IWIDTH = 24, // control_signal 자리수
	parameter NDEPTH = 256, // control_signal의 가짓수
	parameter AWIDTH = 8 // control_signal의 가짓수를 나타낼 수 있는 index 자리수
) (	
    input wire RSTn,
    input wire[4:0] inst,
    input wire[2:0] stage,
    output wire [IWIDTH-1:0] control_signal // 26자리 배출
);
	//Declare the microcode that will store the control signal
    reg [IWIDTH -1:0] MC [NDEPTH-1:0];

	//Define asynchronous read
    reg [AWIDTH-1:0] index;
    always@(*) begin
        index = {inst[4:0],stage[2:0]};    
    end
	assign control_signal = MC[index];

    initial begin
        //표 작성
        // PC_WE_reg, IR_WE_reg, RF_WE_reg, ASel_reg, BSel_reg, ALU_REG_WE_reg, is_sign_reg, pcSel_reg, wbSel_reg, D_MEM_WEN_reg
        // D_MEM_BE_reg == 1111, alu_control_reg, imm_control_reg
        //R-type
        //add
        MC[8'b00000000] <= 24'b110011000000111110000111;// add IF
        MC[8'b00000001] <= 24'b000000000000111110000111;// add ID
        MC[8'b00000010] <= 24'b000000011000111110000111;// add EX
        MC[8'b00000100] <= 24'b001000000000111110000111;// add WB

        //sub
        MC[8'b00001000] <= 24'b110011000000111110000111;// sub IF
        MC[8'b00001001] <= 24'b000000000000111110000111;// sub ID
        MC[8'b00001010] <= 24'b000000011000111110001111;// sub EX
        MC[8'b00001100] <= 24'b001000000000111110001111;// sub WB

        //slt
        MC[8'b00010000] <= 24'b110011000000111110000111;// slt IF
        MC[8'b00010001] <= 24'b000000000000111110000111;// slt ID
        MC[8'b00010010] <= 24'b000000011000111111000111;// slt EX
        MC[8'b00010100] <= 24'b001000000000111111000111;// slt WB

        //sltu
        MC[8'b00011000] <= 24'b110011000000111110000111;// sltu IF
        MC[8'b00011001] <= 24'b000000000000111110000111;// sltu ID
        MC[8'b00011010] <= 24'b000000010000111111000111;// sltu EX
        MC[8'b00011100] <= 24'b001000000000111111000111;// sltu WB

        //xor
        MC[8'b00100000] <= 24'b110011000000111110000111;// xor IF 
        MC[8'b00100001] <= 24'b000000000000111110000111;// xor ID
        MC[8'b00100010] <= 24'b000000011000111110100111;// xor EX
        MC[8'b00100100] <= 24'b001000000000111110100111;// xor WB

        // or
        MC[8'b00101000] <= 24'b110011000000111110000111;// or IF
        MC[8'b00101001] <= 24'b000000000000111110000111;// or ID
        MC[8'b00101010] <= 24'b000000011000111110011111;// or EX
        MC[8'b00101100] <= 24'b001000000000111110011111;// or WB

        //and
        MC[8'b00110000] <= 24'b110011000000111110000111;// and IF
        MC[8'b00110001] <= 24'b000000000000111110000111;// and ID
        MC[8'b00110010] <= 24'b000000011000111110010111;// and EX
        MC[8'b00110100] <= 24'b001000000000111110010111;// and WB

        //sll
        MC[8'b00111000] <= 24'b110011000000111110000111;// sll IF
        MC[8'b00111001] <= 24'b000000000000111110000111;// sll ID
        MC[8'b00111010] <= 24'b000000011000111110101111;// sll EX
        MC[8'b00111100] <= 24'b001000000000111110101111;// sll WB

        //srl
        MC[8'b01000000] <= 24'b110011000000111110000111;// srl IF
        MC[8'b01000001] <= 24'b000000000000111110000111;// srl ID
        MC[8'b01000010] <= 24'b000000011000111110110111;// srl EX
        MC[8'b01000100] <= 24'b001000000000111110110111;// srl WB

        //sra
        MC[8'b01001000] <= 24'b110011000000111110000111;// sra IF
        MC[8'b01001001] <= 24'b000000000000111110000111;// sra ID
        MC[8'b01001010] <= 24'b000000011000111110111111;// sra EX
        MC[8'b01001100] <= 24'b001000000000111110111111;// sra WB

        //I-type
        //add
        MC[8'b01010000] <= 24'b110011000000111110000010;// add IF
        MC[8'b01010001] <= 24'b000000100000111110000010;// add ID
        MC[8'b01010010] <= 24'b000000111000111110000010;// add EX
        MC[8'b01010100] <= 24'b001000100000111110000010;// add WB

        // //sub
        // MC[8'b01011000] <= 1100110000000 1111 0000// sub IF
        // MC[8'b01011001] <= 0000001000000 1111 0000// sub ID
        // MC[8'b01011010] <= 0000001110000 1111 00// sub EX
        // MC[8'b01011100] <= 0010001000000 1111// sub WB

        //slt
        MC[8'b01100000] <= 24'b110011000000111110000010;// slt IF
        MC[8'b01100001] <= 24'b000000100000111110000010;// slt ID
        MC[8'b01100010] <= 24'b000000111000111111000010;// slt EX
        MC[8'b01100100] <= 24'b001000100000111111000010;// slt WB

        //sltu
        MC[8'b01101000] <= 24'b110011000000111110000010;// sltu IF
        MC[8'b01101001] <= 24'b000000100000111110000010;// sltu ID
        MC[8'b01101010] <= 24'b000000110000111111000010;// sltu EX
        MC[8'b01101100] <= 24'b001000100000111111000010;// sltu WB

        //xor
        MC[8'b01110000] <= 24'b110011000000111110000010;// xor IF
        MC[8'b01110001] <= 24'b000000100000111110000010;// xor ID
        MC[8'b01110010] <= 24'b000000111000111110100010;// xor EX
        MC[8'b01110100] <= 24'b001000100000111110100010;// xor WB

        //or
        MC[8'b01111000] <= 24'b110011000000111110000010;// or IF
        MC[8'b01111001] <= 24'b000000100000111110000010;// or ID
        MC[8'b01111010] <= 24'b000000111000111110011010;// or EX
        MC[8'b01111100] <= 24'b001000100000111110011010;// or WB

        //and
        MC[8'b10000000] <= 24'b110011000000111110000010;// and IF
        MC[8'b10000001] <= 24'b000000100000111110000010;// and ID
        MC[8'b10000010] <= 24'b000000111000111110010010;// and EX
        MC[8'b10000100] <= 24'b001000100000111110010010;// and WB

        //sll
        MC[8'b10001000] <= 24'b110011000000111110000101;// sll IF
        MC[8'b10001001] <= 24'b000000100000111110000101;// sll ID
        MC[8'b10001010] <= 24'b000000111000111110101101;// sll EX
        MC[8'b10001100] <= 24'b001000100000111110101101;// sll WB

        //srl
        MC[8'b10010000] <= 24'b110011000000111110000101;// srl IF
        MC[8'b10010001] <= 24'b000000100000111110000101;// srl ID
        MC[8'b10010010] <= 24'b000000111000111110110101;// srl EX
        MC[8'b10010100] <= 24'b001000100000111110110101;// srl WB

        //sra
        MC[8'b10011000] <= 24'b110011000000111110000101;// sra IF
        MC[8'b10011001] <= 24'b000000100000111110000101;// sra ID
        MC[8'b10011010] <= 24'b000000111000111110111101;// sra EX
        MC[8'b10011100] <= 24'b001000100000111110111101;// sra WB

        //L-type
        //LW
        MC[8'b10100000] <= 24'b110011000000111110000010;// LW IF
        MC[8'b10100001] <= 24'b000000100001111110000010;// LW ID
        MC[8'b10100010] <= 24'b000000111001111110000010;// LW EX
        MC[8'b10100011] <= 24'b000000100001111110000010;// LW MEM
        MC[8'b10100100] <= 24'b001000100001111110000010;// LW WB

        //S-type
        //SW
        MC[8'b10101000] <= 24'b110011000000111110000100;// SW IF
        MC[8'b10101001] <= 24'b000000100000111110000100;// SW ID
        MC[8'b10101010] <= 24'b000000111000111110000100;// SW EX
        MC[8'b10101011] <= 24'b000000100000011110000100;// SW MEM
        
        //JALR
        MC[8'b10110000] <= 24'b010000100110111110000010;// JALR IF
        MC[8'b10110001] <= 24'b000000100110111110000010;// JALR ID
        MC[8'b10110010] <= 24'b100000110110111110000010;// JALR EX
        MC[8'b10110100] <= 24'b001101000110111110000010;// JALR WB
        
        //JAL
        MC[8'b10111000] <= 24'b010010100000111110000001;// JAL IF
        MC[8'b10111000] <= 24'b010010100000111110000001;// JAL ID
        MC[8'b10111010] <= 24'b100010110100111110000001;// JAL EX
        MC[8'b10111100] <= 24'b001101000110111110000001;// JAL WB
            
        //B-type
        //BEQ, BNE, BLT, BGE
        MC[8'b11000000] <= 24'b110011000000111110000011;// BXX IF
        MC[8'b11000001] <= 24'b000100111000111110000011;// BXX ID
        MC[8'b11000010] <= 24'b000000001100111110000011;// BXX EX

        //BLTU,BGEU
        MC[8'b11001000] <= 24'b110011000000111110000011;// BXXU IF
        MC[8'b11001001] <= 24'b000100111000111110000011;// BXXU ID
        MC[8'b11001010] <= 24'b000000000100111110000011;// BXXU EX

        //LUI
        MC[8'b11010000] <= 24'b110011000000111110000000;// LUI IF
        MC[8'b11010100] <= 24'b001011000011111110000000;// LUI WB

        //AUIPC
        MC[8'b11011000] <= 24'b110011000000111110000000;// AUIPC IF
        MC[8'b10011010] <= 24'b000010110000111110000000;// AUIPC EX
        MC[8'b10011100] <= 24'b001010100000111110000000;// AUIPC WB

        //???
        MC[8'b11100000] <= 24'b010011000000111110000000;
        // PC_WE_reg, IR_WE_reg, RF_WE_reg, ASel_reg, BSel_reg, ALU_REG_WE_reg, is_sign_reg, pcSel_reg, wbSel_reg, D_MEM_WEN_reg
        // D_MEM_BE_reg == 1111, alu_control_reg, imm_control_reg
    end

endmodule